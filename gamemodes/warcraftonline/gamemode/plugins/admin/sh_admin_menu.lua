--[[
    Warcraft Online — data-driven каталог админ-команд для игрового меню.
    Команды выполняются стандартным серверным concommand с его проверками прав;
    клиент никогда не отправляет произвольное сетевое действие администратора.
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

WO.Admin.ClientMenuPermissions = WO.Admin.ClientMenuPermissions or {}
WO.Admin.ClientMenuCommands = WO.Admin.ClientMenuCommands or {}
WO.Admin.ClientMenuAccess = WO.Admin.ClientMenuAccess == true
WO.Admin.ClientMenuLoaded = WO.Admin.ClientMenuLoaded == true
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
