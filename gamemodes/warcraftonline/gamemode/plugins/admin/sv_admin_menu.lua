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

--- Выполняет только команду из каталога после повторной серверной авторизации.
function WO.Admin.ExecuteMenuCommand(ply, id, args)
    if not IsValid(ply) or not isfunction(ply.IsPlayer) or not ply:IsPlayer() then
        return false, "invalid_player"
    end

    local definition = WO.Admin.GetMenuCommandDefinition(id)

    if not definition then return false, "unknown_command" end
    if not WO.Admin.Can(ply, definition.permission) then return false, "permission_denied" end
    if not istable(args) or #args > #(definition.args or {}) then
        return false, "invalid_arguments"
    end

    local cleanArgs = {}

    for index, value in ipairs(args) do
        if not isstring(value) or #value > 128 then
            return false, "invalid_argument"
        end

        cleanArgs[index] = string.Trim(value)
    end

    local commandTable = concommand and isfunction(concommand.GetTable) and
        concommand.GetTable() or nil
    local callback = commandTable and commandTable[id]

    if not isfunction(callback) then return false, "command_unavailable" end

    -- Each underlying server command also calls its own CheckAdmin/WO.Admin.Can.
    callback(ply, id, cleanArgs)
    return true
end
