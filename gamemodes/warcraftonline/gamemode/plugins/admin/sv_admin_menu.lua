--[[ Warcraft Online — сервер формирует только разрешённые команды меню. ]]

function WO.Admin.SendMenuData(ply)
    if not IsValid(ply) then return false end

    local permissions = {}
    local allowed = false

    for permission in pairs(WO.Admin.Permissions or {}) do
        local can = WO.Admin.Can(ply, permission) == true
        permissions[permission] = can
        allowed = allowed or can
    end

    local commands = {}

    if allowed then
        for _, definition in ipairs(WO.Admin.CommandCatalog or {}) do
            if permissions[definition.permission] == true then
                local args = {}
                for _, argument in ipairs(definition.args or {}) do
                    args[#args + 1] = {
                        name = tostring(argument.name or "Аргумент"),
                        placeholder = tostring(argument.placeholder or ""),
                    }
                end

                commands[#commands + 1] = {
                    id = definition.id,
                    title = definition.title,
                    description = definition.description,
                    permission = definition.permission,
                    args = args,
                }
            end
        end
    end

    WO.Net.Send("Admin.MenuData", ply, {
        isAdmin = allowed,
        permissions = permissions,
        commands = commands,
    })

    return allowed
end
