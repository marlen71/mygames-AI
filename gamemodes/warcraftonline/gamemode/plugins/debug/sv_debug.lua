--[[
    Warcraft Online — debug-команды (server, только администраторы).

    Команды:
        wo_debug                  — переключить debug-режим
        wo_giveitem <class> [n]   — выдать предмет себе
        wo_spawnitem <class>      — бросить предмет в мир
        wo_givexp <n>             — выдать опыт
        wo_setlevel <n>           — установить уровень
        wo_setmoney <n>           — установить деньги
        wo_setstat <stat> <n>     — установить модификатор стата (временно)
        wo_reloadconfig           — перезагрузить конфиги и схемы
        wo_reloadplugins          — перезагрузка контента (полная — через changelevel)
]]

local function CheckAdmin(ply, permission)
    if IsValid(ply) and not WO.Admin:Can(ply, permission) then
        ply:ChatPrint("[WO] Недостаточно прав.")
        return false
    end

    return true
end

local function Reply(ply, text)
    if IsValid(ply) then
        ply:ChatPrint("[WO] " .. text)
    else
        WO.Log(text)
    end
end

---------------------------------------------------------------------------
-- wo_debug
---------------------------------------------------------------------------

concommand.Add("wo_debug", function(ply)
    if not CheckAdmin(ply, "debug") then return end

    WO.Config.Debug = not WO.Config.Debug

    Reply(ply, "Debug mode: " .. (WO.Config.Debug and "ON" or "OFF"))
end)

---------------------------------------------------------------------------
-- wo_giveitem <class> [amount]
---------------------------------------------------------------------------

concommand.Add("wo_giveitem", function(ply, cmd, args)
    if not CheckAdmin(ply, "item.give") then return end

    local class = args[1]
    local amount = tonumber(args[2]) or 1

    if not class then
        Reply(ply, "Использование: wo_giveitem <class> [amount]")
        return
    end

    if not WO.Items.Get(class) then
        Reply(ply, "Неизвестный предмет: " .. class)
        return
    end

    local ok, reason = WO.Inventory.GiveItem(ply, class, amount)

    Reply(ply, ok and ("Выдано: " .. class .. " x" .. amount) or ("Ошибка: " .. tostring(reason)))
end)

---------------------------------------------------------------------------
-- wo_spawnitem <class> — физический предмет в мире
---------------------------------------------------------------------------

concommand.Add("wo_spawnitem", function(ply, cmd, args)
    if not CheckAdmin(ply, "item.give") then return end

    local class = args[1]

    if not class or not WO.Items.Get(class) then
        Reply(ply, "Использование: wo_spawnitem <class>")
        return
    end

    local instance = WO.Items.CreateInstance(class, 1)

    if not instance then
        Reply(ply, "Не удалось создать предмет")
        return
    end

    WO.Items.SetState(instance, WO.Items.State.INVENTORY)

    local ok, reason = WO.World.DropItem(ply, instance)

    if ok then
        WO.Items.SetState(instance, WO.Items.State.WORLD)
        Reply(ply, "Предмет брошен: " .. class)
    else
        Reply(ply, "Ошибка: " .. tostring(reason))
    end
end)

---------------------------------------------------------------------------
-- wo_givexp <amount>
---------------------------------------------------------------------------

concommand.Add("wo_givexp", function(ply, cmd, args)
    if not CheckAdmin(ply, "character.edit") then return end

    local amount = tonumber(args[1]) or 100

    WO.Leveling.AddXP(ply, amount, "debug")

    Reply(ply, "Выдано опыта: " .. amount)
end)

---------------------------------------------------------------------------
-- wo_setlevel <level>
---------------------------------------------------------------------------

concommand.Add("wo_setlevel", function(ply, cmd, args)
    if not CheckAdmin(ply, "character.edit") then return end

    local level = math.Clamp(tonumber(args[1]) or 1, 1, WO.Config.MaxLevel or 60)

    local char = ply:GetCharacter()

    if not char then
        Reply(ply, "Нет активного персонажа")
        return
    end

    char.level = level
    char.experience = 0

    ply:SetNW2Int("wo_level", level)

    WO.Stats.Refresh(ply, true)
    WO.Leveling.SyncXP(ply)
    WO.SaveQueue.SaveNow(char)

    Reply(ply, "Уровень установлен: " .. level)
end)

---------------------------------------------------------------------------
-- wo_setmoney <amount>
---------------------------------------------------------------------------

concommand.Add("wo_setmoney", function(ply, cmd, args)
    if not CheckAdmin(ply, "money.give") then return end

    local amount = math.max(0, math.floor(tonumber(args[1]) or 0))

    WO.Currency.Set(ply, amount)

    Reply(ply, "Деньги установлены: " .. amount)
end)

---------------------------------------------------------------------------
-- wo_setstat <stat> <value> — временный модификатор (до перезагрузки)
---------------------------------------------------------------------------

concommand.Add("wo_setstat", function(ply, cmd, args)
    if not CheckAdmin(ply, "debug") then return end

    local stat = args[1]
    local value = tonumber(args[2])

    if not stat or not value then
        Reply(ply, "Использование: wo_setstat <stat> <value>")
        return
    end

    local char = ply:GetCharacter()

    if not char then
        Reply(ply, "Нет активного персонажа")
        return
    end

    WO.Stats.Recalculate(char)

    char.stats:AddModifier("debug:" .. stat, stat, value, 0)
    char.stats:Recalculate()

    WO.Stats.ApplyVitals(ply)

    Reply(ply, "Стат " .. stat .. " +" .. value .. " (временно)")
end)

---------------------------------------------------------------------------
-- wo_reloadconfig — перезагрузка конфигов и схем (контент hot-reload)
---------------------------------------------------------------------------

concommand.Add("wo_reloadconfig", function(ply)
    if not CheckAdmin(ply, "debug") then return end

    WO.IncludeDir("config")

    -- Схемы: перезапись реестров в режиме hot-reload
    WO.HotReload = true
    WO.IncludeDir("schemas", true)
    WO.HotReload = false

    Reply(ply, "Конфиги и схемы перезагружены.")
end)

---------------------------------------------------------------------------
-- wo_reloadplugins — полная перезагрузка только через changelevel
---------------------------------------------------------------------------

concommand.Add("wo_reloadplugins", function(ply)
    if not CheckAdmin(ply, "debug") then return end

    Reply(ply, "Полная перезагрузка плагинов невозможна во время работы сервера. Используйте changelevel. Доступен wo_reloadconfig (конфиги + схемы).")
end)

---------------------------------------------------------------------------
-- Информация о загруженных системах
---------------------------------------------------------------------------

concommand.Add("wo_info", function(ply)
    if not CheckAdmin(ply, "debug") then return end

    local char = ply:GetCharacter()

    Reply(ply, "WO v" .. WO.Version .. " | plugins: " .. table.Count(WO.Plugins.GetAll()))
    Reply(ply, "Items: " .. WO.Items.Registry:Count() .. " | Races: " .. WO.Races.Registry:Count() ..
        " | Classes: " .. WO.Classes.Registry:Count())

    if char then
        Reply(ply, "Character: " .. char:GetFullName() .. " | level " .. char:GetLevel() ..
            " | money " .. char.money)
    end
end)
