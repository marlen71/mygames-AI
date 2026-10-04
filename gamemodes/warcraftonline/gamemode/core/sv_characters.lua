--[[
    Warcraft Online — менеджер персонажей (server).
    Создание, загрузка, сохранение, удаление, выбор персонажа.

    Основное состояние персонажа НЕ хранится в Entity Player —
    player только ссылается на активного персонажа (ply:GetCharacter()).

    Персистентность инвентаря/экипировки/квестов выполняется плагинами через хуки:
        WO.Hook.Add("CharacterSave", "inventory", function(char) ... end)
        WO.Hook.Add("CharacterLoad", "inventory", function(char) ... end)
]]

---------------------------------------------------------------------------
-- Лимбо (игрок без персонажа не появляется в мире)
---------------------------------------------------------------------------

--- Игрок без активного персонажа: невидим, заблокирован, вне игры.
function WO.Character.EnterLimbo(ply)
    if not IsValid(ply) then return end

    ply:SetNoDraw(true)
    ply:Lock()
    ply:SetMoveType(MOVETYPE_NONE)
    ply:StripWeapons()
    ply:SetNW2Bool("wo_inmenu", true)
    ply:SetNW2Bool("wo_char_active", false)
    ply:SetNW2String("wo_character_id", "")
end

--- Возвращает игрока в мир после выбора персонажа.
function WO.Character.ExitLimbo(ply)
    if not IsValid(ply) then return end

    ply:SetNoDraw(false)
    ply:UnLock()
    ply:SetMoveType(MOVETYPE_WALK)
    ply:SetNW2Bool("wo_inmenu", false)
end

---------------------------------------------------------------------------
-- Сериализация
---------------------------------------------------------------------------

local function CharacterToRow(char)
    local player = char.player
    local pos = char.pos
    local ang = char.ang
    local map = char.map

    if IsValid(player) then
        pos = player:GetPos()
        ang = player:EyeAngles()
        map = game.GetMap()
    end

    local hasPosition = isvector(pos)

    if hasPosition then
        ang = ang or angle_zero
        map = map or game.GetMap()
    else
        pos = nil
        ang = nil
        map = nil
    end

    return {
        id = char.id,
        steamid = char.steamid,
        steamid64 = char.steamid64 or "",
        name = char.name,
        surname = char.surname,
        age = char.age,
        gender = char.gender,
        race = char.race,
        class = char.class,
        model = char.model,
        level = char.level or 1,
        experience = char.experience or 0,
        money = char.money or 0,
        map = map,
        position_saved = hasPosition and 1 or 0,
        pos_x = hasPosition and pos.x or nil,
        pos_y = hasPosition and pos.y or nil,
        pos_z = hasPosition and pos.z or nil,
        ang_p = hasPosition and ang.p or nil,
        ang_y = hasPosition and ang.y or nil,
        ang_r = hasPosition and ang.r or nil,
        customization = util.TableToJSON(char.customization or {}),
        created_at = char.createdAt or WO.Util.Time(),
        last_played = WO.Util.Time(),
    }
end

local function RowToCharacter(row)
    local customization = util.JSONToTable(row.customization or "")
    local positionSaved = tonumber(row.position_saved) == 1

    local data = {
        id = row.id,
        steamid = row.steamid,
        steamid64 = row.steamid64,
        name = row.name,
        surname = row.surname,
        age = tonumber(row.age) or 25,
        gender = row.gender,
        race = row.race,
        class = row.class,
        model = row.model,
        level = tonumber(row.level) or 1,
        experience = tonumber(row.experience) or 0,
        money = tonumber(row.money) or 0,
        map = positionSaved and row.map or nil,
        pos = positionSaved and Vector(tonumber(row.pos_x) or 0,
            tonumber(row.pos_y) or 0, tonumber(row.pos_z) or 0) or nil,
        ang = positionSaved and Angle(tonumber(row.ang_p) or 0,
            tonumber(row.ang_y) or 0, tonumber(row.ang_r) or 0) or nil,
        customization = istable(customization) and customization or { skin = 0, bodygroups = {} },
        createdAt = tonumber(row.created_at) or WO.Util.Time(),
        lastPlayed = tonumber(row.last_played) or WO.Util.Time(),
    }

    return WO.Character.New(data)
end

---------------------------------------------------------------------------
-- Список персонажей игрока
---------------------------------------------------------------------------

--[[
    Загружает краткий список персонажей игрока (для UI выбора).

    @param ply Player
    @return table массив { id, name, surname, level, race, class, gender, model, lastPlayed }
]]
function WO.Character.LoadList(ply)
    local steamid = ply:SteamID()
    local rows = WO.Database:Fetch("SELECT * FROM wo_characters WHERE steamid = ? ORDER BY created_at ASC", steamid)
    local out = {}

    for _, row in ipairs(rows) do
        out[#out + 1] = {
            id = row.id,
            name = row.name or "",
            surname = row.surname or "",
            level = tonumber(row.level) or 1,
            race = row.race or "human",
            class = row.class or "warrior",
            gender = row.gender or "male",
            model = row.model or "",
            lastPlayed = tonumber(row.last_played) or 0,
        }
    end

    return out
end

---------------------------------------------------------------------------
-- Создание персонажа
---------------------------------------------------------------------------

--[[
    Создаёт нового персонажа. Все данные проходят серверную валидацию.

    @param ply Player
    @param data table { name, surname, age, gender, race, class, model, customization }
    @return boolean success, string|table reasonOrCharacter
]]
function WO.Character.Create(ply, data)
    if not IsValid(ply) then return false, "invalid_player" end

    local steamid = ply:SteamID()
    local maxChars = WO.Config.MaxCharacters or 5

    -- Ограничение количества персонажей
    local count = tonumber(WO.Database:FetchValue("SELECT COUNT(*) FROM wo_characters WHERE steamid = ?", steamid)) or 0

    if count >= maxChars then
        return false, "character_limit"
    end

    -- Строгая валидация (клиенту не доверяем)
    local valid, result = WO.Character.Validate(data, { strict = true })

    if not valid then
        WO.Warn("Character creation rejected for " .. ply:Nick() .. ": " .. tostring(result))
        return false, result
    end

    local char = WO.Character.New({
        id = WO.Util.UUID(),
        steamid = steamid,
        steamid64 = ply:SteamID64(),
        name = result.name,
        surname = result.surname,
        fullName = result.name .. " " .. result.surname,
        age = result.age,
        gender = result.gender,
        race = result.race,
        class = result.class,
        model = result.model,
        customization = result.customization,
        level = 1,
        experience = 0,
        money = WO.Config.StartingMoney or 0,
        map = game.GetMap(),
        pos = nil,
        ang = nil,
        createdAt = WO.Util.Time(),
        lastPlayed = WO.Util.Time(),
    })

    -- Сохраняем в БД
    local row = CharacterToRow(char)

    local saved = WO.Database:Transaction(function()
        if not WO.Database:Insert("wo_characters", row) then
            error("insert failed")
        end

        -- Плагины создают свои данные (инвентарь, экипировка и т.д.)
        WO.Hook.Run("CharacterCreate", char)
    end)

    if not saved then
        return false, "database_error"
    end

    WO.Log("Character created: " .. char:GetFullName() .. " [" .. char.id .. "] for " .. ply:Nick())

    -- Полная персистентность сразу: инвентарь/экипировка/данные плагинов
    -- пишутся через CharacterSave — иначе Select→Load терял бы стартовые предметы.
    WO.SaveQueue.SaveNow(char)
    WO.Hook.Run("CharacterCreated", char)

    return true, char
end

---------------------------------------------------------------------------
-- Загрузка персонажа
---------------------------------------------------------------------------

--[[
    Загружает персонажа по ID и делает его активным для игрока.

    @param ply Player
    @param charId string
    @return boolean success, string|table reasonOrCharacter
]]
function WO.Character.Load(ply, charId)
    if not IsValid(ply) then return false, "invalid_player" end

    if not WO.Util.IsUUID(charId) then
        return false, "invalid_id"
    end

    local steamid = ply:SteamID()
    local rows = WO.Database:Fetch("SELECT * FROM wo_characters WHERE id = ? AND steamid = ?", charId, steamid)

    if not rows or not rows[1] then
        return false, "not_found"
    end

    -- Не загружаем устаревшую DB-версию, если предыдущая запись этого ID
    -- ждёт retry после временной ошибки сохранения.
    if WO.SaveQueue and isfunction(WO.SaveQueue.SavePendingByID) then
        local pendingSaved, hadPending = WO.SaveQueue.SavePendingByID(charId)

        if not pendingSaved then
            return false, "database_error"
        end

        if hadPending then
            rows = WO.Database:Fetch("SELECT * FROM wo_characters WHERE id = ? AND steamid = ?", charId, steamid)

            if not rows or not rows[1] then
                return false, "not_found"
            end
        end
    end

    local char = RowToCharacter(rows[1])

    -- Валидируем сохранённые данные до привязки к игроку. Модель не подменяется
    -- гражданской: если раса/модель больше не доступна в Workshop, выбор безопасно
    -- отклоняется, чтобы администратор восстановил аддон или пересоздал персонажа.
    local clean, warnings = WO.Character.SanitizeLoaded(char)

    for _, warning in ipairs(warnings) do
        WO.Warn("Character load warning [" .. char.id .. "]: " .. warning)
    end

    if not clean then
        return false, "model_unavailable"
    end

    char = clean

    -- Плагины загружают свои данные (инвентарь, экипировка, квесты)
    WO.Hook.Run("CharacterLoad", char)

    ply:SetCharacter(char)
    char.player = ply

    WO.Log("Character loaded: " .. char:GetFullName() .. " [" .. char.id .. "] for " .. ply:Nick())

    WO.Hook.Run("CharacterLoaded", char, ply)

    return true, char
end

---------------------------------------------------------------------------
-- Сохранение персонажа
---------------------------------------------------------------------------

--[[
    Сохраняет персонажа в БД (core-поля + данные плагинов через хук CharacterSave).

    @param char table
    @return boolean success
]]
function WO.Character.Save(char)
    if not WO.Character.IsCharacter(char) then
        WO.Error("WO.Character.Save: invalid character")
        return false
    end

    local row = CharacterToRow(char)

    -- Keep an in-memory snapshot even if the database is temporarily
    -- unavailable, so SaveQueue can retry after the player entity disconnects.
    if row.position_saved == 1 then
        char.pos = Vector(row.pos_x, row.pos_y, row.pos_z)
        char.ang = Angle(row.ang_p, row.ang_y, row.ang_r)
        char.map = row.map
    else
        char.pos = nil
        char.ang = nil
        char.map = nil
    end

    local ok = WO.Database:Transaction(function()
        if not WO.Database:Update("wo_characters", {
            name = row.name,
            surname = row.surname,
            age = row.age,
            gender = row.gender,
            race = row.race,
            class = row.class,
            model = row.model,
            level = row.level,
            experience = row.experience,
            money = row.money,
            map = row.map,
            position_saved = row.position_saved,
            pos_x = row.pos_x,
            pos_y = row.pos_y,
            pos_z = row.pos_z,
            ang_p = row.ang_p,
            ang_y = row.ang_y,
            ang_r = row.ang_r,
            customization = row.customization,
            last_played = row.last_played,
        }, "id = ?", char.id) then
            error("update failed")
        end

        -- Плагины сохраняют свои данные
        WO.Hook.Run("CharacterSave", char)
    end)

    if ok then
        WO.Debug("Character saved: " .. char:GetFullName())
        WO.Hook.Run("CharacterSaved", char)
    end

    return ok
end

---------------------------------------------------------------------------
-- Выгрузка / удаление
---------------------------------------------------------------------------

--[[
    Выгружает персонажа игрока (сохраняет и отвязывает).
]]
function WO.Character.Unload(ply)
    if not IsValid(ply) then return end

    local char = ply:GetCharacter()

    if not char then return end

    WO.SaveQueue.SaveNow(char)

    ply:SetNW2Bool("wo_char_active", false)
    ply:SetNW2String("wo_character_id", "")
    ply:SetCharacter(nil)

    WO.Hook.Run("CharacterUnloaded", char, ply)
    char.player = nil

    WO.Log("Character unloaded: " .. char:GetFullName())
end

--[[
    Удаляет персонажа навсегда (с проверкой владельца).
    Удаление выполняется транзакцией по всем таблицам.

    @param ply Player
    @param charId string
    @return boolean success, string reason
]]
function WO.Character.Delete(ply, charId)
    if not IsValid(ply) then return false, "invalid_player" end

    if not WO.Util.IsUUID(charId) then
        return false, "invalid_id"
    end

    local steamid = ply:SteamID()
    local rows = WO.Database:Fetch("SELECT * FROM wo_characters WHERE id = ? AND steamid = ?", charId, steamid)

    if not rows or not rows[1] then
        return false, "not_found"
    end

    -- Нельзя удалить активного персонажа — сначала выгрузить
    local active = ply:GetCharacter()

    if active and active.id == charId then
        WO.Character.Unload(ply)
    end

    local ok = WO.Database:Transaction(function()
        WO.Database:Delete("wo_characters", "id = ?", charId)
        WO.Database:Delete("wo_inventories", "owner_id = ?", charId)
        WO.Database:Delete("wo_equipment", "owner_id = ?", charId)
        WO.Database:Delete("wo_quests", "owner_id = ?", charId)
        WO.Database:Delete("wo_skills", "owner_id = ?", charId)
        WO.Database:Delete("wo_abilities", "owner_id = ?", charId)
    end)

    if ok then
        WO.Log("Character deleted: [" .. charId .. "] by " .. ply:Nick())
        WO.Hook.Run("CharacterDeleted", charId, steamid)
    end

    return ok, ok and "ok" or "database_error"
end

---------------------------------------------------------------------------
-- Выбор персонажа (делает персонажа активным и вводит игрока в мир)
---------------------------------------------------------------------------

--[[
    Выбирает персонажа: загружает, применяет к игроку, синхронизирует клиент.

    @param ply Player
    @param charId string
    @return boolean success, string|table reasonOrCharacter
]]
function WO.Character.Select(ply, charId)
    local success, result = WO.Character.Load(ply, charId)

    if not success then
        WO.Net.Send("Character.SelectResult", ply, false, tostring(result))
        return false, result
    end

    local char = result

    WO.Character.ExitLimbo(ply)

    if WO.Character.ApplyToPlayer(ply) == false then
        WO.Character.Unload(ply)
        WO.Character.EnterLimbo(ply)
        WO.Net.Send("Character.SelectResult", ply, false, "model_unavailable")
        return false, "model_unavailable"
    end

    -- Восстанавливаем оружие из экипировки (если плагин загружен)
    if WO.Equipment and WO.Equipment.ApplyWeapons then
        WO.Equipment.ApplyWeapons(ply)
    end

    WO.Character.SyncToClient(ply)

    -- Синхронизация инвентаря/экипировки/статов — через хуки (плагины)
    WO.Hook.Run("CharacterSync", char, ply)

    WO.Net.Send("Character.SelectResult", ply, true, "")

    WO.Hook.Run("CharacterSelected", char, ply)

    return true, char
end

---------------------------------------------------------------------------
-- Применение персонажа к игроку
---------------------------------------------------------------------------

--[[
    Применяет данные персонажа к Entity Player:
    модель, кастомизация, позиция, скорости, NW2-переменные.
]]
function WO.Character.ApplyToPlayer(ply)
    if not IsValid(ply) then return end

    if WO.Models and WO.Models.RefreshRaceLists then
        WO.Models.RefreshRaceLists()
    end

    local char = ply:GetCharacter()

    if not char then
        WO.Error("ApplyToPlayer: player has no character")
        return false
    end

    if not isstring(char.model) or char.model == "" or
        not WO.Races.IsModelAllowed(char.race, char.gender, char.model) or
        not WO.Models.Exists(char.model) or
        (util.IsValidModel and not util.IsValidModel(char.model)) then
        WO.Warn("ApplyToPlayer rejected unavailable race model for character " .. tostring(char.id))
        ply:SetNW2Bool("wo_char_active", false)
        ply:SetNW2String("wo_character_id", "")
        WO.Character.EnterLimbo(ply)
        return false
    end

    -- Only the server-validated, mounted race model can be applied.
    ply:SetModel(char.model)

    -- Кастомизация: skin, bodygroups, color
    local customization = char.customization or {}

    ply:SetSkin(math.max(0, WO.Util.ToInt(customization.skin, 0)))

    if istable(customization.bodygroups) then
        for bgId, value in pairs(customization.bodygroups) do
            local id = tonumber(bgId)

            if id then
                ply:SetBodygroup(id, math.max(0, WO.Util.ToInt(value, 0)))
            end
        end
    end

    if istable(customization.color) then
        local c = customization.color

        ply:SetColor(Color(tonumber(c.r) or 255, tonumber(c.g) or 255, tonumber(c.b) or 255, tonumber(c.a) or 255))
    end

    -- Масштаб модели (раса может задавать, например гномы меньше)
    local race = WO.Races.Registry and WO.Races.Registry:Get(char.race)
    local scale = (race and race.modelScale) or 1

    ply:SetModelScale(scale, 0)

    -- Скорости
    ply:SetWalkSpeed(WO.Config.DefaultWalkSpeed or 150)
    ply:SetRunSpeed(WO.Config.DefaultRunSpeed or 250)
    ply:SetJumpPower(WO.Config.DefaultJumpPower or 200)

    -- Позиция: сохранённая (если та же карта) или spawn point
    local pos = char.pos
    local ang = char.ang

    if char.map and char.map == game.GetMap() and isvector(pos) then
        ply:SetPos(pos)
    else
        local spawnPos, spawnAng = WO.FindSpawnPoint(ply)

        if isvector(spawnPos) then
            ply:SetPos(spawnPos)
            ang = spawnAng
        else
            WO.Warn("No standard map spawn point found while applying character " .. tostring(char.id) ..
                "; keeping the engine-selected player position")
        end
    end

    if ang then
        ply:SetEyeAngles(ang)
    end

    -- NW2-переменные (видны всем клиентам: HUD, target frame)
    ply:SetNW2String("wo_name", char:GetFullName())
    ply:SetNW2String("wo_character_id", char.id or "")
    ply:SetNW2String("wo_race", char.race or "")
    ply:SetNW2String("wo_class", char.class or "")
    ply:SetNW2Int("wo_level", char.level or 1)
    ply:SetNW2Bool("wo_char_active", true)

    -- Vitals: HP/Mana/Stamina рассчитывает Stats-система
    if WO.Stats and WO.Stats.ApplyVitals then
        WO.Stats.ApplyVitals(ply)
    else
        ply:SetMaxHealth(100)
        ply:SetHealth(100)
    end

    WO.Hook.Run("CharacterApplied", char, ply)

    return true
end

---------------------------------------------------------------------------
-- Синхронизация полного состояния клиенту
---------------------------------------------------------------------------

--[[
    Отправляет клиенту все данные активного персонажа.
]]
--[[--
    Отправляет клиенту состояние меню персонажей: список + какой экран открыть.
    Вызывается по готовности клиента (Client.Ready) и как фолбэк при входе.
]]
function WO.Character.SendState(ply)
    if not IsValid(ply) then return end

    local list = WO.Character.LoadList(ply)

    WO.Net.Send("Character.List", ply, list)

    if ply:HasCharacter() then
        return
    end

    -- Всегда открываем главное меню: игрок сам выбирает создать нового,
    -- загрузить сохранённого или отключиться. Список уже отправлен выше.
    WO.Net.Send("Character.OpenMenu", ply)
end

function WO.Character.SyncToClient(ply)
    if not IsValid(ply) then return end

    local char = ply:GetCharacter()

    if not char then return end

    WO.Net.Send("Character.Sync", ply, {
        id = char.id,
        name = char.name,
        surname = char.surname,
        age = char.age,
        gender = char.gender,
        race = char.race,
        class = char.class,
        model = char.model,
        customization = char.customization,
        level = char.level,
        experience = char.experience,
        money = char.money,
        stats = (char.stats and char.stats.GetNetworkTable and char.stats:GetNetworkTable()) or nil,
    })
end
