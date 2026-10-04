--[[
    Warcraft Online — data-driven каталог админ-команд для игрового меню.
    Клиент передаёт только ID/аргументы из каталога. Сервер проверяет отдельное
    разрешение и повторно вызывает проверяемый concommand; произвольные действия
    и команды вне каталога через этот протокол недоступны.
]]

WO.Admin.CommandCatalog = {
    { id = "wo_debug", title = "Debug-режим", description = "Включить или выключить диагностические сообщения.", permission = "debug" },
    { id = "wo_giveitem", title = "Выдать предмет", description = "Добавить предмет в инвентарь активного персонажа.", permission = "item.give", args = {
        { name = "Класс предмета", placeholder = "health_potion" },
        { name = "Количество", placeholder = "1" },
    } },
    { id = "wo_spawnitem", title = "Создать предмет в мире", description = "Бросить физический предмет перед администратором.", permission = "item.give", args = {
        { name = "Класс предмета", placeholder = "bread" },
    } },
    { id = "wo_givexp", title = "Выдать опыт", description = "Выдать опыт активному персонажу (по умолчанию 100).", permission = "character.edit", args = {
        { name = "Опыт", placeholder = "100" },
    } },
    { id = "wo_setlevel", title = "Установить уровень", description = "Установить уровень активного персонажа.", permission = "character.edit", args = {
        { name = "Уровень", placeholder = "1" },
    } },
    { id = "wo_setmoney", title = "Установить валюту", description = "Задать баланс активного персонажа.", permission = "money.give", args = {
        { name = "Сумма", placeholder = "100" },
    } },
    { id = "wo_setstat", title = "Временный модификатор стата", description = "Добавить модификатор до перезапуска сервера.", permission = "debug", args = {
        { name = "Стат", placeholder = "strength" },
        { name = "Значение", placeholder = "10" },
    } },
    { id = "wo_reloadconfig", title = "Перезагрузить конфиги и схемы", description = "Выполнить безопасный hot-reload конфигурации и data-driven схем.", permission = "debug" },
    { id = "wo_reloadplugins", title = "Инструкция перезагрузки плагинов", description = "Сообщить способ полной перезагрузки через смену карты.", permission = "debug" },
    { id = "wo_info", title = "Информация о режиме", description = "Показать версию, загруженные плагины и реестры.", permission = "debug" },
    { id = "wo_models", title = "Каталог моделей", description = "Показать модели расы; аргументы необязательны.", permission = "debug", args = {
        { name = "ID расы (необязательно)", placeholder = "human" },
        { name = "Пол (необязательно)", placeholder = "male" },
    } },
    { id = "wo_npc_respawn", title = "Пересоздать NPC", description = "Пересоздать только NPC из подтверждённых точек текущей карты.", permission = "npc.spawn" },
    { id = "wo_npc_list", title = "Список NPC", description = "Вывести зарегистрированные определения и размещение NPC.", permission = "npc.spawn" },
    { id = "wo_workshop_assets", title = "Проверить Workshop", description = "Проверить смонтированные модели, SWEP и точные NPC-классы.", permission = "debug" },
}

-- Access is always fail-closed after client load/reload; only a fresh server
-- response may reveal the admin tab or its allowlisted commands.
function WO.Admin.GetMenuCommandDefinition(id)
    if not isstring(id) then return nil end

    for _, definition in ipairs(WO.Admin.CommandCatalog or {}) do
        if definition.id == id then return definition end
    end

    return nil
end

WO.Admin.ClientMenuPermissions = {}
WO.Admin.ClientMenuCommands = {}
WO.Admin.ClientMenuAccess = false
WO.Admin.ClientMenuLoaded = false
WO.Admin.MenuRequestPending = false

function WO.Admin.RequestMenuData(force)
    if not CLIENT then return end
    if WO.Admin.MenuRequestPending then return end
    if WO.Admin.ClientMenuLoaded and not force then return end

    WO.Admin.MenuRequestPending = true
    WO.Net.SendToServer("Admin.MenuRequest")
end

WO.Net.Register("Admin.MenuRequest", {
    direction = "toserver",
    rate = { max = 3, window = 10 },
    validate = function(ply)
        return IsValid(ply)
    end,
    handler = function(ply)
        if SERVER then WO.Admin.SendMenuData(ply) end
    end,
})

-- The menu may request only catalog IDs. The server still repeats permission
-- checks immediately before invoking the registered server concommand.
WO.Net.Register("Admin.CommandRun", {
    direction = "toserver",
    rate = { max = 5, window = 1 },
    write = function(id, args)
        args = istable(args) and args or {}
        local count = math.min(#args, 15)
        net.WriteString(id or "")
        net.WriteUInt(count, 4)

        for index = 1, count do
            net.WriteString(string.sub(tostring(args[index] or ""), 1, 128))
        end
    end,
    read = function()
        local id = net.ReadString()
        local count = net.ReadUInt(4)
        local args = {}

        for index = 1, count do
            args[index] = net.ReadString()
        end

        return id, args
    end,
    validate = function(ply, id, args)
        if not IsValid(ply) or not isfunction(ply.IsPlayer) or not ply:IsPlayer() or
            not isstring(id) or #id > 64 or not istable(args) then
            return false, "invalid_request"
        end

        local definition = WO.Admin.GetMenuCommandDefinition(id)

        if not definition or not WO.Admin.Can(ply, definition.permission) then
            return false, "permission_denied"
        end

        local maximum = #(definition.args or {})
        if #args > maximum then return false, "too_many_arguments" end

        for _, value in ipairs(args) do
            if not isstring(value) or #value > 128 then
                return false, "invalid_argument"
            end
        end

        return true
    end,
    handler = function(ply, id, args)
        if SERVER and WO.Admin.ExecuteMenuCommand then
            WO.Admin.ExecuteMenuCommand(ply, id, args)
        end
    end,
})

WO.Net.Register("Admin.MenuData", {
    direction = "toclient",
    write = function(data)
        net.WriteTable(data or {})
    end,
    read = function()
        return net.ReadTable()
    end,
    handler = function(_, data)
        if not CLIENT then return end

        data = istable(data) and data or {}
        WO.Admin.ClientMenuPermissions = istable(data.permissions) and data.permissions or {}
        WO.Admin.ClientMenuCommands = istable(data.commands) and data.commands or {}
        WO.Admin.ClientMenuAccess = data.isAdmin == true
        WO.Admin.ClientMenuLoaded = true
        WO.Admin.MenuRequestPending = false
        WO.Hook.Run("AdminMenuDataUpdated", WO.Admin.ClientMenuAccess)
    end,
})
