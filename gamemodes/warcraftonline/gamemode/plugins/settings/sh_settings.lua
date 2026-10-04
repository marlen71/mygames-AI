--[[
    Warcraft Online — настройки игрока (shared): opt-in автосбор важных ресурсов.
    Значение лишь задаёт предпочтение игрока; подбор и права всегда проверяет сервер.
]]

WO.Settings = WO.Settings or {}
WO.Settings.ClientAutoCollectEnabled = WO.Settings.ClientAutoCollectEnabled == true
WO.Settings.ClientAutoCollectLoaded = WO.Settings.ClientAutoCollectLoaded == true
WO.Settings.AutoCollectRequestPending = false

--- Запрашивает серверное сохранённое значение для текущего игрока.
function WO.Settings.RequestAutoCollect(force)
    if not CLIENT then return false end
    if WO.Settings.AutoCollectRequestPending then return false end
    if WO.Settings.ClientAutoCollectLoaded and not force then return false end

    WO.Settings.AutoCollectRequestPending = true
    WO.Net.SendToServer("Settings.AutoCollectRequest")
    return true
end

--- Запрашивает включение/выключение; авторитетное значение вернёт сервер.
function WO.Settings.SetClientAutoCollectEnabled(enabled)
    if not CLIENT or not isbool(enabled) then return false end

    WO.Settings.ClientAutoCollectEnabled = enabled
    WO.Settings.AutoCollectRequestPending = true
    WO.Net.SendToServer("Settings.AutoCollectSet", enabled)
    WO.Hook.Run("AutoCollectSettingsUpdated", enabled)
    return true
end

WO.Net.Register("Settings.AutoCollectRequest", {
    direction = "toserver",
    rate = { max = 4, window = 2 },
    validate = function(ply)
        return IsValid(ply) and isfunction(ply.IsPlayer) and ply:IsPlayer()
    end,
    handler = function(ply)
        if SERVER and WO.Settings.SendAutoCollect then
            WO.Settings.SendAutoCollect(ply)
        end
    end,
})

WO.Net.Register("Settings.AutoCollectSet", {
    direction = "toserver",
    rate = { max = 4, window = 2 },
    write = function(enabled)
        net.WriteBool(enabled == true)
    end,
    read = function()
        return net.ReadBool()
    end,
    validate = function(ply, enabled)
        return IsValid(ply) and isfunction(ply.IsPlayer) and ply:IsPlayer() and isbool(enabled)
    end,
    handler = function(ply, enabled)
        if SERVER and WO.Settings.SetAutoCollect then
            WO.Settings.SetAutoCollect(ply, enabled)
        end
    end,
})

WO.Net.Register("Settings.AutoCollectSync", {
    direction = "toclient",
    write = function(enabled)
        net.WriteBool(enabled == true)
    end,
    read = function()
        return net.ReadBool()
    end,
    handler = function(_, enabled)
        if not CLIENT then return end

        WO.Settings.ClientAutoCollectEnabled = enabled == true
        WO.Settings.ClientAutoCollectLoaded = true
        WO.Settings.AutoCollectRequestPending = false
        WO.Hook.Run("AutoCollectSettingsUpdated", WO.Settings.ClientAutoCollectEnabled)
    end,
})
