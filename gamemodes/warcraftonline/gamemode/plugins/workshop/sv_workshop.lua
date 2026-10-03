--[[
    Warcraft Online — серверная диагностика Workshop-ассетов.
    Команда только читает реестры/файлы; она не выдаёт оружие и не меняет данные.
]]

local function Reply(ply, text)
    if IsValid(ply) then
        ply:ChatPrint("[WO] " .. text)
    else
        WO.Log(text)
    end
end

concommand.Add("wo_workshop_assets", function(ply)
    if IsValid(ply) and not WO.Admin.Can(ply, "debug") then
        ply:ChatPrint("[WO] Недостаточно прав.")
        return
    end

    if not WO.Workshop or not WO.Workshop.GetDiagnostics then
        Reply(ply, "Workshop asset adapter не загружен.")
        return
    end

    local report, scanTruncated = WO.Workshop.GetDiagnostics()

    Reply(ply, "Проверка смонтированных Workshop-ассетов:")

    for _, asset in ipairs(report) do
        Reply(ply, asset.id .. " (Workshop " .. tostring(asset.workshopID) .. ") — " .. asset.title)

        if #asset.models == 0 and #asset.weapons == 0 then
            Reply(ply, "  модели/SWEP не обнаружены; используется безопасный fallback")
        end

        for index = 1, math.min(#asset.models, 4) do
            Reply(ply, "  model: " .. asset.models[index])
        end

        for index = 1, math.min(#asset.weapons, 4) do
            local weapon = asset.weapons[index]
            Reply(ply, "  установленный SWEP (только модель, не выдаётся): " ..
                weapon.class .. " | " .. weapon.name .. " | " ..
                tostring(weapon.worldModel or weapon.viewModel or "нет модели"))
        end
    end

    if scanTruncated then
        Reply(ply, "Сканирование моделей ограничено; увеличьте WO.Config.Workshop.ModelScanDirectoryLimit.")
    end
end)
