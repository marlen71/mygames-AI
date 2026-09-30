--[[
    Warcraft Online — администрирование (shared).

    API:
        WO.Admin:IsAdmin(ply) → boolean
        WO.Admin:Can(ply, permission) → boolean

    Права:
        character.edit, item.give, money.give, npc.spawn,
        quest.complete, teleport, debug

    Не строим собственную авторизацию поверх ULX/ServerGuard —
    WO.Admin.IsAdmin использует встроенные права GMod и может быть
    переопределён для интеграции с аддонами прав.
]]

WO.Admin.Permissions = {
    ["character.edit"] = true,
    ["item.give"] = true,
    ["money.give"] = true,
    ["npc.spawn"] = true,
    ["quest.complete"] = true,
    ["teleport"] = true,
    ["debug"] = true,
}

--[[
    Является ли игрок администратором.
    Переопределите WO.Admin.IsAdmin для интеграции с ULX/ServerGuard.
]]
function WO.Admin.IsAdmin(ply)
    if not IsValid(ply) then return false end

    return ply:IsAdmin() or ply:IsSuperAdmin()
end

--[[
    Проверяет право игрока.

    @param ply Player
    @param permission string например "item.give"
    @return boolean
]]
function WO.Admin.Can(ply, permission)
    if not WO.Admin.IsAdmin(ply) then
        return false
    end

    if not isstring(permission) then
        return true
    end

    -- Неизвестные права — запрещаем (fail-closed)
    return WO.Admin.Permissions[permission] == true
end
