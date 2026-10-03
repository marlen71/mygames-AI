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

    if IsValid(ent) and WO.Interaction.CanInteract(ent, ply) and
        ent:GetPos():Distance(ply:GetPos()) <= WO.Interaction.GetRange(ent) then
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

    local keyText = WO.Lang:Get("interact.key")
    local maxWidth = math.max(80, ScrW() - 48)
    surface.SetFont("WO.HUD")
    local keyWidth = select(1, surface.GetTextSize(keyText))
    local _, font = WO.UI.FitText(currentText, "WO.HUD", maxWidth - keyWidth - 54, 28)
    local text = WO.UI.FitText(currentText, font, maxWidth - keyWidth - 54, 28)
    local textWidth = select(1, surface.GetTextSize(text))
    local h = 42
    local w = math.min(maxWidth, keyWidth + textWidth + 50)
    local x = (ScrW() - w) / 2
    local y = math.Clamp(ScrH() * 0.62, 12, ScrH() - h - 12)

    draw.RoundedBox(WO.UI.Metrics.radiusSmall, x, y, w, h,
        Color(WO.UI.Colors.panelDark.r, WO.UI.Colors.panelDark.g,
            WO.UI.Colors.panelDark.b, 230))

    surface.SetDrawColor(WO.UI.Colors.accent)
    surface.DrawRect(x + 8, y + h - 2, w - 16, 2)

    WO.UI.DrawTextFit(keyText, "WO.HUD", x + 16, y + h / 2,
        WO.UI.Colors.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, keyWidth + 8, 28)
    WO.UI.DrawTextFit(text, font, x + 22 + keyWidth, y + h / 2,
        color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, maxWidth - keyWidth - 42, 28)
end)
