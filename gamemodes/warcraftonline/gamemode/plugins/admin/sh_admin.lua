--[[
    Warcraft Online — администрирование (shared).

    Авторизация команд использует SAM, когда SAM загружен. WO регистрирует
    собственные SAM permissions с уровнем по умолчанию "admin"; ранги сервера
    могут переназначать их в конфигурации SAM.

    API:
        WO.Admin.IsAdmin(ply) → boolean
        WO.Admin.Can(ply, permission) → boolean

    Если SAM не установлен (локальная разработка/тесты), используется безопасный
    fallback на стандартные права GMod. Неизвестные WO-права всегда запрещены.
]]

WO.Admin = WO.Admin or {}

WO.Admin.Permissions = {
    ["character.edit"] = true,
    ["item.give"] = true,
    ["money.give"] = true,
    ["npc.spawn"] = true,
    ["quest.complete"] = true,
    ["teleport"] = true,
    ["debug"] = true,
    ["movement.noclip"] = true,
}

-- Публичные SAM permission IDs намеренно стабильны: их можно выдавать/снимать
-- через SAM и использовать в серверных конфигурациях без переименования команд.
WO.Admin.SAMPermissionNames = {
    ["character.edit"] = "wo_character_edit",
    ["item.give"] = "wo_item_give",
    ["money.give"] = "wo_money_give",
    ["npc.spawn"] = "wo_npc_spawn",
    ["quest.complete"] = "wo_quest_complete",
    ["teleport"] = "wo_teleport",
    ["debug"] = "wo_debug",
    ["movement.noclip"] = "wo_noclip",
}

WO.Admin.SAMPermissionDescriptions = {
    ["character.edit"] = "Warcraft Online: edit character progression",
    ["item.give"] = "Warcraft Online: give and spawn items",
    ["money.give"] = "Warcraft Online: change character currency",
    ["npc.spawn"] = "Warcraft Online: manage configured NPC spawns",
    ["quest.complete"] = "Warcraft Online: complete quests",
    ["teleport"] = "Warcraft Online: teleport players",
    ["debug"] = "Warcraft Online: use debug and configuration commands",
    ["movement.noclip"] = "Warcraft Online: use noclip movement",
}

local function GetSAM()
    local library = rawget(_G, "sam")

    return istable(library) and library or nil
end

--- Регистрирует отдельные WO permissions в SAM, если SAM уже загружен.
function WO.Admin.RegisterSAMPermissions()
    if not SERVER then return false end

    local library = GetSAM()

    if not library or not istable(library.permissions) or
        not isfunction(library.permissions.add) then
        return false
    end

    WO.Admin.RegisteredSAMPermissions = WO.Admin.RegisteredSAMPermissions or {}

    local allRegistered = true

    for permission, samPermission in pairs(WO.Admin.SAMPermissionNames) do
        if not WO.Admin.RegisteredSAMPermissions[samPermission] then
            local ok, err = pcall(
                library.permissions.add,
                samPermission,
                WO.Admin.SAMPermissionDescriptions[permission],
                "admin"
            )

            if ok then
                WO.Admin.RegisteredSAMPermissions[samPermission] = true
            else
                allRegistered = false
                WO.Warn("Could not register SAM permission '" .. samPermission .. "': " .. tostring(err))
            end
        end
    end

    for _, samPermission in pairs(WO.Admin.SAMPermissionNames) do
        if not WO.Admin.RegisteredSAMPermissions[samPermission] then
            allRegistered = false
            break
        end
    end

    WO.Admin.SAMReady = allRegistered

    if allRegistered then
        WO.Log("SAM permissions registered for Warcraft Online")
    end

    return allRegistered
end

local function CheckSAMPermission(ply, samPermission)
    if not IsValid(ply) or not isfunction(ply.HasPermission) then
        return false
    end

    local ok, allowed = pcall(ply.HasPermission, ply, samPermission)

    return ok and allowed == true
end

--- Совместимый admin-check: при SAM проверяет зарегистрированные WO-права.
function WO.Admin.IsAdmin(ply)
    if not IsValid(ply) then return false end

    if GetSAM() then
        for permission, samPermission in pairs(WO.Admin.SAMPermissionNames) do
            -- A movement-only grant must not confer broader character/admin access.
            if permission ~= "movement.noclip" and CheckSAMPermission(ply, samPermission) then
                return true
            end
        end

        return false
    end

    return (isfunction(ply.IsAdmin) and ply:IsAdmin()) or
        (isfunction(ply.IsSuperAdmin) and ply:IsSuperAdmin()) or false
end

--- Проверяет строго заданное право; unknown permission — fail-closed.
function WO.Admin.Can(ply, permission)
    if not IsValid(ply) or not isstring(permission) or WO.Admin.Permissions[permission] ~= true then
        return false
    end

    local samPermission = WO.Admin.SAMPermissionNames[permission]

    if GetSAM() then
        return samPermission ~= nil and CheckSAMPermission(ply, samPermission)
    end

    return WO.Admin.IsAdmin(ply)
end

if SERVER then
    WO.Admin.RegisterSAMPermissions()

    hook.Add("Initialize", "wo_admin_register_sam_permissions", function()
        WO.Admin.RegisterSAMPermissions()

        timer.Simple(1, function()
            WO.Admin.RegisterSAMPermissions()
        end)
    end)
end
