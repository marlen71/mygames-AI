--[[
    Warcraft Online — серверное хранение настроек игрока.
    Автосбор выключен по умолчанию и сохраняется в PData на стороне сервера.
]]

local AUTO_COLLECT_PDATA_KEY = "wo_auto_collect_important"

local function ReadStoredAutoCollect(ply)
    if not isfunction(ply.GetPData) then return false end

    local ok, value = pcall(ply.GetPData, ply, AUTO_COLLECT_PDATA_KEY, "0")

    return ok and (value == "1" or value == "true") or false
end

function WO.Settings.IsAutoCollectEnabled(ply)
    if not IsValid(ply) or not isfunction(ply.IsPlayer) or not ply:IsPlayer() then
        return false
    end

    if ply.WOAutoCollectImportant == nil then
        ply.WOAutoCollectImportant = ReadStoredAutoCollect(ply)
    end

    return ply.WOAutoCollectImportant == true
end

function WO.Settings.SendAutoCollect(ply)
    if not IsValid(ply) then return false end

    WO.Net.Send("Settings.AutoCollectSync", ply,
        WO.Settings.IsAutoCollectEnabled(ply))
    return true
end

function WO.Settings.SetAutoCollect(ply, enabled)
    if not IsValid(ply) or not isfunction(ply.IsPlayer) or not ply:IsPlayer() or
        not isbool(enabled) then
        return false
    end

    ply.WOAutoCollectImportant = enabled

    if isfunction(ply.SetPData) then
        local ok, err = pcall(ply.SetPData, ply, AUTO_COLLECT_PDATA_KEY,
            enabled and "1" or "0")

        if not ok then
            WO.Warn("Could not persist auto-collect preference: " .. tostring(err))
        end
    end

    WO.Settings.SendAutoCollect(ply)
    return true
end

hook.Add("PlayerInitialSpawn", "wo_settings_auto_collect_sync", function(ply)
    timer.Simple(1, function()
        if IsValid(ply) then
            WO.Settings.SendAutoCollect(ply)
        end
    end)
end)
