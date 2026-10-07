--[[
    Warcraft Online — система плагинов.

    Каждый плагин — папка в gamemode/plugins/ с файлом sh_plugin.lua:

        return {
            name = "Inventory",
            id = "inventory",
            author = "Warcraft Online Team",
            version = "1.0.0",
            dependencies = { "character", "items" },
            priority = 50,
        }

    Загрузчик:
        1. находит плагины;
        2. читает metadata (sh_plugin.lua);
        3. проверяет зависимости;
        4. сортирует (зависимости → priority → имя);
        5. загружает sh_* → sv_*/cl_* файлы;
        6. выводит информацию в консоль.

    Отсутствующая зависимость — понятная ошибка, плагин пропускается.
]]

WO.Plugins = WO.Plugins or {}
WO.Plugins.Registry = WO.Plugins.Registry or {}
WO.Plugins.Order = WO.Plugins.Order or {}

---------------------------------------------------------------------------
-- Поиск и чтение metadata
---------------------------------------------------------------------------

local function ReadMetadata(folder)
    local path = "plugins/" .. folder .. "/sh_plugin.lua"
    local ok, meta = pcall(WO.Include, path, "shared")

    if not ok then
        WO.Error("Plugin '" .. folder .. "': failed to read metadata — " .. tostring(meta))
        return nil
    end

    if not istable(meta) or not isstring(meta.id) or meta.id == "" then
        WO.Error("Plugin '" .. folder .. "': sh_plugin.lua must return a metadata table with a non-empty id")
        return nil
    end

    meta.folder = folder
    meta.dependencies = meta.dependencies or {}
    meta.priority = tonumber(meta.priority) or 50

    return meta
end

---------------------------------------------------------------------------
-- Сортировка по зависимостям (topological) + priority
---------------------------------------------------------------------------

local function SortPlugins(metas)
    local byId = {}

    for _, meta in ipairs(metas) do
        byId[meta.id] = meta
    end

    local sorted = {}
    local state = {} -- id → "visiting" | "done"

    local function visit(meta)
        if state[meta.id] == "done" then return true end

        if state[meta.id] == "visiting" then
            WO.Error("Plugin dependency cycle involving '" .. meta.id .. "'")
            return false
        end

        state[meta.id] = "visiting"

        local deps = {}

        for _, depId in ipairs(meta.dependencies) do
            local dep = byId[depId]

            if not dep then
                WO.Error("Plugin '" .. meta.id .. "' requires missing plugin '" .. depId .. "' — plugin skipped")
                return false
            end

            deps[#deps + 1] = dep
        end

        table.sort(deps, function(a, b)
            if a.priority ~= b.priority then
                return a.priority < b.priority
            end

            return a.id < b.id
        end)

        for _, dep in ipairs(deps) do
            if not visit(dep) then
                return false
            end
        end

        state[meta.id] = "done"
        sorted[#sorted + 1] = meta

        return true
    end

    -- Готовые метаданные сортируем по priority/имени и обходим
    table.sort(metas, function(a, b)
        if a.priority ~= b.priority then
            return a.priority < b.priority
        end

        return a.id < b.id
    end)

    for _, meta in ipairs(metas) do
        if not state[meta.id] then
            visit(meta)
        end
    end

    return sorted
end

---------------------------------------------------------------------------
-- Загрузка файлов плагина
---------------------------------------------------------------------------

local function CollectFiles(folder)
    local shared, server, client = {}, {}, {}

    local function Walk(dir)
        local base = WO.GamemodeFolder .. "/plugins/" .. dir
        local files, folders = file.Find(base .. "/*", "GAME")

        table.sort(files, function(a, b)
            return string.lower(a) < string.lower(b)
        end)

        for _, fileName in ipairs(files) do
            if string.EndsWith(fileName, ".lua") and fileName ~= "sh_plugin.lua" then
                local path = "plugins/" .. dir .. "/" .. fileName
                local prefix = string.lower(string.sub(fileName, 1, 3))

                if prefix == "sv_" then
                    server[#server + 1] = path
                elseif prefix == "cl_" then
                    client[#client + 1] = path
                else
                    shared[#shared + 1] = path
                end
            end
        end

        table.sort(folders, function(a, b)
            return string.lower(a) < string.lower(b)
        end)

        for _, subFolder in ipairs(folders) do
            Walk(dir .. "/" .. subFolder)
        end
    end

    Walk(folder)

    return shared, server, client
end

local function LoadPluginFiles(meta)
    local shared, server, client = CollectFiles(meta.folder)

    for _, path in ipairs(shared) do
        WO.Include(path, "shared")
    end

    for _, path in ipairs(server) do
        WO.Include(path, "server")
    end

    for _, path in ipairs(client) do
        WO.Include(path, "client")
    end

    meta.loaded = true
    meta.fileCount = #shared + #server + #client
end

---------------------------------------------------------------------------
-- Публичный API
---------------------------------------------------------------------------

--- Получить плагин по id.
function WO.Plugins.Get(id)
    return WO.Plugins.Registry[id]
end

--- Все плагины.
function WO.Plugins.GetAll()
    return WO.Plugins.Registry
end

--- Загружен ли плагин.
function WO.Plugins.IsLoaded(id)
    local plugin = WO.Plugins.Registry[id]

    return plugin ~= nil and plugin.loaded == true
end

---------------------------------------------------------------------------
-- Загрузка
---------------------------------------------------------------------------

local function LoadAllPlugins()
    local base = WO.GamemodeFolder .. "/plugins"
    local _, folders = file.Find(base .. "/*", "GAME")

    table.sort(folders, function(a, b)
        return string.lower(a) < string.lower(b)
    end)

    if #folders == 0 then
        WO.Warn("No plugins found in gamemode/plugins/")
        return
    end

    -- Metadata
    local metas = {}

    for _, folder in ipairs(folders) do
        local meta = ReadMetadata(folder)

        if meta then
            if WO.Plugins.Registry[meta.id] then
                WO.Error("Duplicate plugin id '" .. meta.id .. "' (folder " .. folder .. ") — skipped")
            else
                WO.Plugins.Registry[meta.id] = meta
                metas[#metas + 1] = meta
            end
        end
    end

    -- Порядок загрузки
    local sorted = SortPlugins(metas)

    -- Загрузка файлов
    for _, meta in ipairs(sorted) do
        local ok, err = pcall(LoadPluginFiles, meta)

        if ok then
            WO.Plugins.Order[#WO.Plugins.Order + 1] = meta.id

            WO.Log("Plugin loaded: " .. (meta.name or meta.id) .. " v" .. (meta.version or "?") ..
                " (" .. meta.fileCount .. " files, priority " .. meta.priority .. ")")
        else
            WO.Error("Plugin '" .. meta.id .. "' failed to load: " .. tostring(err))
            meta.loaded = false
        end
    end

    WO.Hook.Run("PluginsLoaded", WO.Plugins.Order)
end

LoadAllPlugins()
