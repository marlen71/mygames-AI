--[[
    Warcraft Online — сетевые сообщения персонажей (shared).
    Регистрация сообщений; сами обработчики вызывают серверную логику
    (core/sv_characters.lua) и клиентские события (через WO.Hook).

    Клиент НИКОГДА не присылает готовые данные персонажа «как есть»:
    сервер валидирует каждый запрос.
]]

---------------------------------------------------------------------------
-- Сервер → клиент
---------------------------------------------------------------------------

-- Краткий список персонажей (для экрана выбора)
WO.Net.Register("Character.List", {
    direction = "toclient",
    write = function(list)
        net.WriteUInt(#list, 8)

        for _, entry in ipairs(list) do
            net.WriteString(entry.id or "")
            net.WriteString(entry.name or "")
            net.WriteString(entry.surname or "")
            net.WriteUInt(entry.level or 1, 16)
            net.WriteString(entry.race or "")
            net.WriteString(entry.class or "")
            net.WriteString(entry.gender or "")
            net.WriteString(entry.model or "")
            net.WriteUInt(entry.lastPlayed or 0, 32)
        end
    end,
    read = function()
        local count = net.ReadUInt(8)
        local list = {}

        for i = 1, count do
            list[i] = {
                id = net.ReadString(),
                name = net.ReadString(),
                surname = net.ReadString(),
                level = net.ReadUInt(16),
                race = net.ReadString(),
                class = net.ReadString(),
                gender = net.ReadString(),
                model = net.ReadString(),
                lastPlayed = net.ReadUInt(32),
            }
        end

        return list
    end,
    handler = function(_, list)
        WO.Character.List = list
        WO.Hook.Run("CharacterListReceived", list)
    end,
})

-- Полная синхронизация активного персонажа
WO.Net.Register("Character.Sync", {
    direction = "toclient",
    write = function(data)
        net.WriteTable(data)
    end,
    read = function()
        return net.ReadTable()
    end,
    handler = function(_, data)
        WO.Character.Local = WO.Character.New(data)
        WO.Hook.Run("CharacterSynced", WO.Character.Local)
    end,
})

-- Открыть экран создания персонажа
WO.Net.Register("Character.OpenCreate", {
    direction = "toclient",
    handler = function()
        WO.Hook.Run("OpenCharacterCreate")
    end,
})

-- Открыть экран выбора персонажа
WO.Net.Register("Character.OpenSelect", {
    direction = "toclient",
    handler = function()
        WO.Hook.Run("OpenCharacterSelect")
    end,
})

-- Ответ на создание персонажа
WO.Net.Register("Character.CreateResult", {
    direction = "toclient",
    write = function(success, reason)
        net.WriteBool(success)
        net.WriteString(reason or "")
    end,
    read = function()
        return net.ReadBool(), net.ReadString()
    end,
    handler = function(_, success, reason)
        WO.Hook.Run("CharacterCreateResult", success, reason)
    end,
})

-- Death UI
WO.Net.Register("Character.Death", {
    direction = "toclient",
    write = function(data)
        net.WriteTable(data)
    end,
    read = function()
        return net.ReadTable()
    end,
    handler = function(_, data)
        WO.Hook.Run("CharacterDeath", data)
    end,
})

---------------------------------------------------------------------------
-- Клиент → сервер
---------------------------------------------------------------------------

-- Запрос на создание персонажа. Данные валидируются на сервере.
WO.Net.Register("Character.Create", {
    direction = "toserver",
    rate = { max = 3, window = 5 },
    write = function(data)
        net.WriteTable(data)
    end,
    read = function()
        return net.ReadTable()
    end,
    validate = function(ply, data)
        if not IsValid(ply) then return false, "invalid_player" end
        if ply:HasCharacter() then return false, "already_has_character" end
        if not istable(data) then return false, "invalid_data" end

        -- Быстрая проверка размера (подробная валидация — в WO.Character.Create)
        if table.Count(data) > 16 then return false, "too_many_fields" end

        return true
    end,
    handler = function(ply, data)
        local success, result = WO.Character.Create(ply, data)

        if success then
            WO.Net.Send("Character.CreateResult", ply, true, "")

            -- Автоматически выбираем созданного персонажа
            timer.Simple(0.5, function()
                if IsValid(ply) then
                    WO.Character.Select(ply, result.id)
                end
            end)
        else
            WO.Net.Send("Character.CreateResult", ply, false, tostring(result))
        end
    end,
})

-- Выбор персонажа
WO.Net.Register("Character.Select", {
    direction = "toserver",
    rate = { max = 5, window = 5 },
    write = function(charId)
        net.WriteString(charId or "")
    end,
    read = function()
        return net.ReadString()
    end,
    validate = function(ply, charId)
        if not IsValid(ply) then return false, "invalid_player" end
        if ply:HasCharacter() then return false, "already_selected" end
        if not isstring(charId) or charId == "" then return false, "invalid_id" end

        return true
    end,
    handler = function(ply, charId)
        WO.Character.Select(ply, charId)
    end,
})

-- Удаление персонажа
WO.Net.Register("Character.Delete", {
    direction = "toserver",
    rate = { max = 2, window = 5 },
    write = function(charId)
        net.WriteString(charId or "")
    end,
    read = function()
        return net.ReadString()
    end,
    validate = function(ply, charId)
        if not IsValid(ply) then return false, "invalid_player" end
        if not isstring(charId) or charId == "" then return false, "invalid_id" end

        return true
    end,
    handler = function(ply, charId)
        local success, reason = WO.Character.Delete(ply, charId)

        -- Обновляем список у клиента
        local list = WO.Character.LoadList(ply)

        WO.Net.Send("Character.List", ply, list)
        WO.Net.Send("Character.DeleteResult", ply, success, reason or "")
    end,
})

-- Результат удаления
WO.Net.Register("Character.DeleteResult", {
    direction = "toclient",
    write = function(success, reason)
        net.WriteBool(success)
        net.WriteString(reason or "")
    end,
    read = function()
        return net.ReadBool(), net.ReadString()
    end,
    handler = function(_, success, reason)
        WO.Hook.Run("CharacterDeleteResult", success, reason)
    end,
})

-- Результат выбора персонажа
WO.Net.Register("Character.SelectResult", {
    direction = "toclient",
    write = function(success, reason)
        net.WriteBool(success)
        net.WriteString(reason or "")
    end,
    read = function()
        return net.ReadBool(), net.ReadString()
    end,
    handler = function(_, success, reason)
        WO.Hook.Run("CharacterSelectResult", success, reason)
    end,
})

-- Выход из персонажа (в меню выбора)
WO.Net.Register("Character.Logout", {
    direction = "toserver",
    rate = { max = 2, window = 5 },
    handler = function(ply)
        if not IsValid(ply) or not ply:HasCharacter() then return end

        WO.Character.Unload(ply)
        WO.Character.EnterLimbo(ply)

        local list = WO.Character.LoadList(ply)

        WO.Net.Send("Character.List", ply, list)
        WO.Net.Send("Character.OpenSelect", ply)
    end,
})
