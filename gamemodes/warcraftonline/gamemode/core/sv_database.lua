--[[
    Warcraft Online — абстракция базы данных (server).
    Драйвер: SQLite (встроенный GMod sql-модуль).
    Слой абстракции позволяет позже подключить MySQL без переписывания игры:
    достаточно реализовать тот же интерфейс в драйвере.

    Использование:
        WO.Database:Query("SELECT * FROM wo_characters WHERE steamid = ?", steamid)
        WO.Database:Insert("wo_characters", { id = "...", name = "..." })
        WO.Database:Update("wo_characters", { name = "X" }, "id = ?", id)
        WO.Database:Delete("wo_characters", "id = ?", id)
        WO.Database:Fetch(...)   -- алиас Query (массив строк)
        WO.Database:RegisterMigration(1, function() ... end)
]]

WO.Database = WO.Database or {}

WO.Database.Driver = "sqlite"
WO.Database.Migrations = WO.Database.Migrations or {}
WO.Database.Initialized = false

---------------------------------------------------------------------------
-- Драйвер SQLite
---------------------------------------------------------------------------

local driver = {}

--- Экранирует строку для вставки в SQL.
function driver.Escape(str)
    return sql.SQLStr(tostring(str), true)
end

--- Выполняет запрос. Возвращает результат (таблица строк | false) + ошибку.
function driver.Query(sqlText)
    local result = sql.Query(sqlText)

    if result == false then
        return false, sql.LastError()
    end

    return result
end

--- Выполняет запрос и возвращает одно скалярное значение.
function driver.QueryValue(sqlText)
    local value = sql.QueryValue(sqlText)

    if value == false then
        return nil, sql.LastError()
    end

    return value
end

-- Хелпер сериализации значений для INSERT/UPDATE
local function FormatValue(value)
    local t = type(value)

    if t == "string" then
        return "'" .. driver.Escape(value) .. "'"
    elseif t == "number" then
        return tostring(value)
    elseif t == "boolean" then
        return value and "1" or "0"
    elseif t == "table" then
        return "'" .. driver.Escape(util.TableToJSON(value)) .. "'"
    elseif value == nil then
        return "NULL"
    end

    return "'" .. driver.Escape(tostring(value)) .. "'"
end

---------------------------------------------------------------------------
-- Публичный API
---------------------------------------------------------------------------

--[[
    Выполняет SQL-запрос (параметры подставляются безопасно).

    @param sqlText string запрос с ?-плейсхолдерами
    @param ... значения для плейсхолдеров
    @return table|nil result, string|nil err
]]
function WO.Database:Query(sqlText, ...)
    if not self.Initialized and not string.find(sqlText, "^CREATE") then
        -- Разрешаем DDL до инициализации (сама инициализация)
    end

    local args = { ... }

    if #args > 0 then
        sqlText = string.gsub(sqlText, "%?", function()
            local value = table.remove(args, 1)
            return FormatValue(value)
        end, #args)
    end

    return driver.Query(sqlText)
end

--[[
    Выполняет запрос и возвращает массив строк (алиас Query).
]]
function WO.Database:Fetch(sqlText, ...)
    local result, err = self:Query(sqlText, ...)

    if result == false then
        WO.Error("SQL error: " .. tostring(err) .. " | " .. tostring(sqlText))
        return {}
    end

    return result or {}
end

--- Возвращает одно значение (первый столбец первой строки).
function WO.Database:FetchValue(sqlText, ...)
    local args = { ... }

    if #args > 0 then
        sqlText = string.gsub(sqlText, "%?", function()
            local value = table.remove(args, 1)
            return FormatValue(value)
        end, #args)
    end

    local value, err = driver.QueryValue(sqlText)

    if value == nil and err then
        WO.Error("SQL error: " .. tostring(err) .. " | " .. tostring(sqlText))
    end

    return value
end

--[[
    Вставляет строку в таблицу.

    @param tableName string
    @param data table столбец → значение (table сериализуется в JSON)
    @return boolean success
]]
function WO.Database:Insert(tableName, data)
    local columns = {}
    local values = {}

    for column, value in pairs(data) do
        columns[#columns + 1] = column
        values[#values + 1] = FormatValue(value)
    end

    local sqlText = string.format(
        "INSERT INTO %s (%s) VALUES (%s)",
        tableName,
        table.concat(columns, ", "),
        table.concat(values, ", ")
    )

    local result, err = driver.Query(sqlText)

    if result == false then
        WO.Error("SQL insert error: " .. tostring(err) .. " | " .. tableName)
        return false
    end

    return true
end

--[[
    Обновляет строки таблицы.

    @param tableName string
    @param data table столбец → значение
    @param where string условие с ?-плейсхолдерами
    @param ... значения для where
    @return boolean success
]]
function WO.Database:Update(tableName, data, where, ...)
    local sets = {}

    for column, value in pairs(data) do
        sets[#sets + 1] = column .. " = " .. FormatValue(value)
    end

    local sqlText = string.format("UPDATE %s SET %s", tableName, table.concat(sets, ", "))

    if where and where ~= "" then
        local args = { ... }

        where = string.gsub(where, "%?", function()
            local value = table.remove(args, 1)
            return FormatValue(value)
        end)

        sqlText = sqlText .. " WHERE " .. where
    end

    local result, err = driver.Query(sqlText)

    if result == false then
        WO.Error("SQL update error: " .. tostring(err) .. " | " .. tableName)
        return false
    end

    return true
end

--[[
    Удаляет строки таблицы.

    @param tableName string
    @param where string условие с ?-плейсхолдерами
    @param ... значения
    @return boolean success
]]
function WO.Database:Delete(tableName, where, ...)
    local sqlText = string.format("DELETE FROM %s", tableName)

    if where and where ~= "" then
        local args = { ... }

        where = string.gsub(where, "%?", function()
            local value = table.remove(args, 1)
            return FormatValue(value)
        end)

        sqlText = sqlText .. " WHERE " .. where
    end

    local result, err = driver.Query(sqlText)

    if result == false then
        WO.Error("SQL delete error: " .. tostring(err) .. " | " .. tableName)
        return false
    end

    return true
end

--[[
    Выполняет набор запросов в транзакции.
    При ошибке — ROLLBACK.

    @param fn function
    @return boolean success
]]
function WO.Database:Transaction(fn)
    driver.Query("BEGIN")

    local ok, err = pcall(fn)

    if not ok then
        driver.Query("ROLLBACK")
        WO.Error("SQL transaction rolled back: " .. tostring(err))
        return false
    end

    driver.Query("COMMIT")

    return true
end

---------------------------------------------------------------------------
-- Миграции
---------------------------------------------------------------------------

--[[
    Регистрирует миграцию схемы.

    @param version number монотонно растущий номер
    @param fn function выполняется один раз при обновлении
]]
function WO.Database:RegisterMigration(version, fn)
    if not isnumber(version) or not isfunction(fn) then
        WO.Error("WO.Database:RegisterMigration: invalid arguments")
        return
    end

    if self.Migrations[version] then
        WO.Error("WO.Database:RegisterMigration: duplicate version " .. version)
        return
    end

    self.Migrations[version] = fn
end

local function GetSchemaVersion()
    local value = driver.QueryValue("SELECT value FROM wo_meta WHERE key = 'schema_version'")

    return tonumber(value) or 0
end

local function SetSchemaVersion(version)
    driver.Query(string.format(
        "INSERT OR REPLACE INTO wo_meta (key, value) VALUES ('schema_version', '%s')",
        tostring(version)
    ))
end

---------------------------------------------------------------------------
-- Инициализация
---------------------------------------------------------------------------

local function RegisterBaseMigrations()
    -- v1: базовая схема
    WO.Database:RegisterMigration(1, function()
        driver.Query([[
            CREATE TABLE IF NOT EXISTS wo_meta (
                key TEXT PRIMARY KEY,
                value TEXT
            )
        ]])

        driver.Query([[
            CREATE TABLE IF NOT EXISTS wo_characters (
                id TEXT PRIMARY KEY,
                steamid TEXT NOT NULL,
                steamid64 TEXT,
                name TEXT,
                surname TEXT,
                age INTEGER,
                gender TEXT,
                race TEXT,
                class TEXT,
                model TEXT,
                level INTEGER DEFAULT 1,
                experience INTEGER DEFAULT 0,
                money INTEGER DEFAULT 0,
                map TEXT,
                pos_x REAL DEFAULT 0,
                pos_y REAL DEFAULT 0,
                pos_z REAL DEFAULT 0,
                ang_p REAL DEFAULT 0,
                ang_y REAL DEFAULT 0,
                ang_r REAL DEFAULT 0,
                customization TEXT,
                created_at INTEGER,
                last_played INTEGER
            )
        ]])

        driver.Query("CREATE INDEX IF NOT EXISTS idx_characters_steamid ON wo_characters (steamid)")

        driver.Query([[
            CREATE TABLE IF NOT EXISTS wo_inventories (
                owner_id TEXT NOT NULL,
                container TEXT NOT NULL,
                width INTEGER,
                height INTEGER,
                items TEXT,
                PRIMARY KEY (owner_id, container)
            )
        ]])

        driver.Query([[
            CREATE TABLE IF NOT EXISTS wo_equipment (
                owner_id TEXT PRIMARY KEY,
                slots TEXT
            )
        ]])

        -- Заглушки под будущие системы (архитектура позволяет расширять)
        driver.Query([[
            CREATE TABLE IF NOT EXISTS wo_quests (
                owner_id TEXT NOT NULL,
                quest_id TEXT NOT NULL,
                data TEXT,
                completed INTEGER DEFAULT 0,
                PRIMARY KEY (owner_id, quest_id)
            )
        ]])

        driver.Query([[
            CREATE TABLE IF NOT EXISTS wo_skills (
                owner_id TEXT NOT NULL,
                skill_id TEXT NOT NULL,
                level INTEGER DEFAULT 0,
                data TEXT,
                PRIMARY KEY (owner_id, skill_id)
            )
        ]])

        driver.Query([[
            CREATE TABLE IF NOT EXISTS wo_abilities (
                owner_id TEXT NOT NULL,
                ability_id TEXT NOT NULL,
                data TEXT,
                PRIMARY KEY (owner_id, ability_id)
            )
        ]])

        driver.Query([[
            CREATE TABLE IF NOT EXISTS wo_world_items (
                uid TEXT PRIMARY KEY,
                data TEXT,
                map TEXT,
                pos_x REAL,
                pos_y REAL,
                pos_z REAL,
                created_at INTEGER
            )
        ]])
    end)

    -- Будущие миграции:
    -- WO.Database:RegisterMigration(2, function() ... end)
end

--- Инициализирует БД: создаёт таблицы, применяет миграции.
function WO.Database.Initialize()
    if WO.Database.Initialized then return end

    RegisterBaseMigrations()

    -- Таблица мета-данных нужна до чтения версии
    driver.Query([[
        CREATE TABLE IF NOT EXISTS wo_meta (
            key TEXT PRIMARY KEY,
            value TEXT
        )
    ]])

    local current = GetSchemaVersion()
    local versions = {}

    for version in pairs(WO.Database.Migrations) do
        versions[#versions + 1] = version
    end

    table.sort(versions)

    for _, version in ipairs(versions) do
        if version > current then
            local ok, err = pcall(WO.Database.Migrations[version])

            if ok then
                SetSchemaVersion(version)
                WO.Log("Database migration applied: v" .. version)
            else
                WO.Error("Database migration v" .. version .. " failed: " .. tostring(err))
                return
            end
        end
    end

    WO.Database.Initialized = true
    WO.Log("Database initialized (driver: " .. WO.Database.Driver .. ", schema v" .. GetSchemaVersion() .. ")")

    WO.Hook.Run("DatabaseReady")
end
