--[[
    Warcraft Online — дизайн-система (client).
    Единые цвета, метрики и хелперы отрисовки для ВСЕГО UI.
    Не создавать собственные стили в плагинах — используйте WO.UI.
]]

WO.UI = WO.UI or {}

---------------------------------------------------------------------------
-- Цвета
---------------------------------------------------------------------------

WO.UI.Colors = {
    -- Фоны
    bg = Color(16, 18, 26, 245),
    panel = Color(28, 32, 44, 245),
    panelLight = Color(38, 44, 60, 245),
    panelDark = Color(12, 14, 20, 250),

    -- Акценты
    accent = Color(212, 175, 55),      -- золото (MMORPG)
    accentDark = Color(150, 120, 35),
    accentBlue = Color(64, 156, 255),

    -- Текст
    text = Color(235, 235, 240),
    textDim = Color(190, 195, 207),
    textDark = Color(125, 130, 145),

    -- Рамки
    border = Color(58, 64, 82),
    borderLight = Color(90, 98, 120),

    -- Статусы
    good = Color(60, 200, 90),
    bad = Color(220, 70, 70),
    warn = Color(255, 180, 50),

    -- Vitals
    health = Color(190, 50, 50),
    healthBg = Color(70, 22, 22),
    mana = Color(55, 110, 230),
    manaBg = Color(20, 35, 80),
    stamina = Color(220, 180, 40),
    staminaBg = Color(80, 65, 18),
    xp = Color(170, 80, 255),
    xpBg = Color(55, 28, 85),
}

---------------------------------------------------------------------------
-- Метрики
---------------------------------------------------------------------------

WO.UI.Metrics = {
    radius = 6,
    radiusSmall = 3,
    padding = 10,
    slotSize = 48,
    slotGap = 4,
    borderSize = 1,
}

---------------------------------------------------------------------------
-- Отрисовка
---------------------------------------------------------------------------

--- Стилизованная закруглённая панель.
function WO.UI.DrawPanel(x, y, w, h, color, radius)
    draw.RoundedBox(radius or WO.UI.Metrics.radius, x, y, w, h, color or WO.UI.Colors.panel)
end

--- Панель с рамкой.
function WO.UI.DrawPanelOutlined(x, y, w, h, color, borderColor, radius)
    radius = radius or WO.UI.Metrics.radius

    draw.RoundedBox(radius, x, y, w, h, color or WO.UI.Colors.panel)

    -- Рамка
    surface.SetDrawColor(borderColor or WO.UI.Colors.border)
    surface.DrawOutlinedRect(x, y, w, h, WO.UI.Metrics.borderSize)
end

--- Заголовок с золотой линией-акцентом.
function WO.UI.DrawTitleBar(x, y, w, h, text)
    draw.RoundedBoxEx(WO.UI.Metrics.radius, x, y, w, h, WO.UI.Colors.panelDark, true, true, false, false)

    surface.SetDrawColor(WO.UI.Colors.accent)
    surface.DrawRect(x, y + h - 2, w, 2)

    draw.SimpleText(text, "WO.Title", x + WO.UI.Metrics.padding, y + h / 2, WO.UI.Colors.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

--- Полоса (HP/Mana/XP...).
function WO.UI.DrawBar(x, y, w, h, fraction, color, bgColor, text)
    fraction = math.Clamp(fraction or 0, 0, 1)

    draw.RoundedBox(2, x, y, w, h, bgColor or WO.UI.Colors.panelDark)
    draw.RoundedBox(2, x + 1, y + 1, math.max(0, (w - 2) * fraction), h - 2, color or WO.UI.Colors.accent)

    surface.SetDrawColor(0, 0, 0, 120)
    surface.DrawOutlinedRect(x, y, w, h, 1)

    if text then
        draw.SimpleText(text, "WO.Small", x + w / 2, y + h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

--- Возвращает цвет редкости.
function WO.UI.GetRarityColor(rarity)
    return WO.Enums.RarityColors[rarity] or WO.Enums.RarityColors.common
end
