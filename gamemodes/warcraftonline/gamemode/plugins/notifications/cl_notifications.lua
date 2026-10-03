--[[
    Warcraft Online — уведомления (client).
    Очередь уведомлений с плавным появлением/исчезанием.
]]

WO.Notify = WO.Notify or {}

local queue = {}
local MAX_VISIBLE = 6
local LIFETIME = 4

local TYPE_COLORS = {
    info = WO.UI.Colors.accentBlue,
    success = WO.UI.Colors.good,
    error = WO.UI.Colors.bad,
    xp = WO.UI.Colors.xp,
    item = WO.UI.Colors.accent,
    levelup = WO.UI.Colors.accent,
    combat = WO.UI.Colors.warn,
}

--[[
    Показывает уведомление (клиентская сторона).

    @param notifyType string
    @param text string
    @param sound string|nil
]]
function WO.Notify.Show(notifyType, text, sound)
    if not isstring(text) or text == "" then return end

    if WO.Config.Debug then
        WO.Debug("Notify:", notifyType, text)
    end

    if isstring(sound) and sound ~= "" then
        WO.Sound.PlayLocal(sound)
    else
        WO.Sound.PlayLocal("notify")
    end

    queue[#queue + 1] = {
        type = notifyType or "info",
        text = text,
        color = TYPE_COLORS[notifyType] or WO.UI.Colors.text,
        created = SysTime(),
    }

    while #queue > MAX_VISIBLE do
        table.remove(queue, 1)
    end
end

hook.Add("HUDPaint", "wo_notifications_paint", function()
    if #queue == 0 then return end

    local now = SysTime()
    local screenW, screenH = ScrW(), ScrH()
    local y = screenH * 0.22

    for i = #queue, 1, -1 do
        local note = queue[i]
        local age = now - note.created

        if age > LIFETIME then
            table.remove(queue, i)
        else
            -- Плавное появление/исчезание
            local alpha = 255

            if age < 0.25 then
                alpha = 255 * (age / 0.25)
            elseif age > LIFETIME - 0.6 then
                alpha = 255 * ((LIFETIME - age) / 0.6)
            end

            local maxWidth = math.max(120, screenW - 40)
            local fittedText, fittedFont = WO.UI.FitText(note.text, "WO.HUD", maxWidth - 32, 28)
            local tw, th = surface.GetTextSize(fittedText)
            local w = math.min(maxWidth, tw + 32)
            local h = math.max(40, th + 14)
            local x = screenW / 2 - w / 2

            draw.RoundedBox(WO.UI.Metrics.radiusSmall, x, y, w, h,
                Color(WO.UI.Colors.panelDark.r, WO.UI.Colors.panelDark.g,
                    WO.UI.Colors.panelDark.b, alpha * 0.92))

            surface.SetDrawColor(note.color.r, note.color.g, note.color.b, alpha)
            surface.DrawRect(x + 8, y + h - 2, w - 16, 2)

            WO.UI.DrawTextFit(fittedText, fittedFont, screenW / 2, y + h / 2,
                Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
                w - 16, h - 4)

            y = y + h + 6
        end
    end
end)
