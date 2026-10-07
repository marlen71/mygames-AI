--[[
    Warcraft Online — уровни (shared): регистрация net-сообщений.
]]

WO.Net.Register("Leveling.Sync", {
    direction = "toclient",
    write = function(data)
        net.WriteUInt(data.level or 1, 16)
        net.WriteUInt(data.experience or 0, 32)
        net.WriteUInt(data.needed or 0, 32)
    end,
    read = function()
        return {
            level = net.ReadUInt(16),
            experience = net.ReadUInt(32),
            needed = net.ReadUInt(32),
        }
    end,
    handler = function(_, data)
        WO.Leveling.ClientData = data

        WO.Hook.Run("LevelingSynced", data)
    end,
})

if CLIENT then
    WO.Hook.Add("CharacterMenuOpening", "leveling_client_clear", function()
        WO.Leveling.ClientData = nil
    end)
end
