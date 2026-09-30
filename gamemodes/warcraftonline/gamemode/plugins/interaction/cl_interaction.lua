--[[
    Warcraft Online — взаимодействие (client): подсказка "[E] Поднять предмет".
    Периодический trace (не каждый кадр!) + отрисовка на HUD.
]]

local currentEnt = nil
local currentText = ""

-- Периодический поиск цели взаимодействия (4 раза в секунду — дёшево)
timer.Create("wo_interaction_trace", 0.25, 0, function()
    local ply = LocalPlayer()

    if not IsValid(ply) or not ply:HasCharacter() or not ply:Alive() then
        currentEnt = nil
        return
    end

    local ent = ply:GetEyeTrace().Entity

    if IsValid(ent) and WO.Interaction.CanInteract(ent, ply) and ent:GetPos():Distance(ply:GetPos()) <= (WO.Config.InteractDistance or 100) then
        if currentEnt ~= ent then
            currentEnt = ent
            currentText = WO.Interaction.GetText(ent, ply)
        end
    else
        currentEnt = nil
    end
end)

-- Отрисовка подсказки
hook.Add("HUDPaint", "wo_interaction_paint", function()
    if not IsValid(currentEnt) then return end

    local ply = LocalPlayer()

    if not IsValid(ply) or not ply:Alive() then return end

    local text = currentText
    local keyText = WO.Lang:Get("interact.key")

    local fullText = keyText .. "  " .. text

    surface.SetFont("WO.HUD")

    local tw, th = surface.GetTextSize(fullText)
    local w = tw + 36
    local h = th + 16
    local x = ScrW() / 2 - w / 2
    local y = ScrH() * 0.62

    draw.RoundedBox(8, x, y, w, h, Color(WO.UI.Colors.panelDark.r, WO.UI.Colors.panelDark.g, WO.UI.Colors.panelDark.b, 220))

    surface.SetDrawColor(WO.UI.Colors.accent)
    surface.DrawRect(x, y + h - 2, w, 2)

    -- Ключ золотом, текст белым
    surface.SetFont("WO.HUD")

    local keyW = surface.GetTextSize(keyText)

    draw.SimpleText(keyText, "WO.HUD", x + 14, y + h / 2, WO.UI.Colors.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(text, "WO.HUD", x + 18 + keyW, y + h / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end)
