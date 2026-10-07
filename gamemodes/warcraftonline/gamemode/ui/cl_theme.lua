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
    accent = Color(212, 175, 55),
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
    radius = 10,
    radiusSmall = 7,
    padding = 12,
    slotSize = 48,
    slotGap = 4,
    borderSize = 1,
}

---------------------------------------------------------------------------
-- Общая типографика: подгонка текста под размеры контролов
---------------------------------------------------------------------------

local FONT_FALLBACKS = {
    ["WO.Title"] = { "WO.Title", "WO.Subtitle", "WO.Body", "WO.Small", "WO.Tiny" },
    ["WO.Subtitle"] = { "WO.Subtitle", "WO.Body", "WO.Small", "WO.Tiny" },
    ["WO.MenuButton"] = { "WO.MenuButton", "WO.Body", "WO.Small", "WO.Tiny" },
    ["WO.Body"] = { "WO.Body", "WO.Small", "WO.Tiny" },
    ["WO.Small"] = { "WO.Small", "WO.Tiny" },
    ["WO.Tiny"] = { "WO.Tiny" },
    ["WO.HUD"] = { "WO.HUD", "WO.Body", "WO.Small", "WO.Tiny" },
    ["WO.HUDName"] = { "WO.HUDName", "WO.Subtitle", "WO.Body", "WO.Small" },
    ["WO.Number"] = { "WO.Number", "WO.Small", "WO.Tiny" },
}

local function UTF8Characters(text)
    local characters = {}
    local index = 1

    while index <= #text do
        local firstByte = string.byte(text, index)
        local length = 1

        if firstByte >= 240 then
            length = 4
        elseif firstByte >= 224 then
            length = 3
        elseif firstByte >= 192 then
            length = 2
        end

        length = math.min(length, #text - index + 1)
        characters[#characters + 1] = string.sub(text, index, index + length - 1)
        index = index + length
    end

    return characters
end

local function TextSize(text, font)
    surface.SetFont(font)

    return surface.GetTextSize(text)
end

--- Возвращает текст/шрифт, которые гарантированно помещаются в заданный прямоугольник.
function WO.UI.FitText(text, font, maxWidth, maxHeight)
    text = tostring(text or "")
    font = font or "WO.Body"
    maxWidth = math.max(0, tonumber(maxWidth) or 0)
    maxHeight = math.max(0, tonumber(maxHeight) or math.huge)

    local candidates = FONT_FALLBACKS[font] or { font, "WO.Body", "WO.Small", "WO.Tiny" }
    local lastFont = candidates[#candidates] or font

    for _, candidate in ipairs(candidates) do
        local width, height = TextSize(text, candidate)

        if width <= maxWidth and height <= maxHeight then
            return text, candidate
        end

        lastFont = candidate
    end

    if text == "" or maxWidth <= 0 then
        return "", lastFont
    end

    local characters = UTF8Characters(text)
    local suffix = "…"
    local suffixWidth = TextSize(suffix, lastFont)

    if suffixWidth > maxWidth then
        suffix = "..."
        suffixWidth = TextSize(suffix, lastFont)
    end

    if suffixWidth > maxWidth then
        return "", lastFont
    end

    local low, high, best = 0, #characters, 0

    while low <= high do
        local middle = math.floor((low + high) / 2)
        local candidate = table.concat(characters, "", 1, middle) .. suffix
        local width = TextSize(candidate, lastFont)

        if width <= maxWidth then
            best = middle
            low = middle + 1
        else
            high = middle - 1
        end
    end

    return table.concat(characters, "", 1, best) .. suffix, lastFont
end

--- Рисует однострочный текст с автоматическим уменьшением/сокращением.
function WO.UI.DrawTextFit(text, font, x, y, color, alignX, alignY, maxWidth, maxHeight)
    local fittedText, fittedFont = WO.UI.FitText(text, font, maxWidth, maxHeight)

    if fittedText ~= "" then
        draw.SimpleText(fittedText, fittedFont, x, y, color or WO.UI.Colors.text,
            alignX or TEXT_ALIGN_LEFT, alignY or TEXT_ALIGN_TOP)
    end

    return fittedText, fittedFont
end

---------------------------------------------------------------------------
-- Отрисовка
---------------------------------------------------------------------------

--- Стилизованная закруглённая панель.
function WO.UI.DrawPanel(x, y, w, h, color, radius)
    draw.RoundedBox(radius or WO.UI.Metrics.radius, x, y, w, h,
        color or WO.UI.Colors.panel)
end

--- Панель с округлой рамкой, общая для всех окон и панелей.
function WO.UI.DrawPanelOutlined(x, y, w, h, color, borderColor, radius)
    local border = math.max(1, WO.UI.Metrics.borderSize or 1)
    radius = radius or WO.UI.Metrics.radius

    draw.RoundedBox(radius, x, y, w, h, borderColor or WO.UI.Colors.border)

    if w > border * 2 and h > border * 2 then
        draw.RoundedBox(math.max(0, radius - border), x + border, y + border,
            w - border * 2, h - border * 2, color or WO.UI.Colors.panel)
    end
end

--- Заголовок с золотой линией-акцентом и резервом под кнопку закрытия.
function WO.UI.DrawTitleBar(x, y, w, h, text)
    draw.RoundedBoxEx(WO.UI.Metrics.radius, x, y, w, h,
        WO.UI.Colors.panelDark, true, true, false, false)

    surface.SetDrawColor(WO.UI.Colors.accent)
    surface.DrawRect(x + 8, y + h - 2, math.max(0, w - 16), 2)

    local padding = WO.UI.Metrics.padding
    local fittedText, fittedFont = WO.UI.FitText(text, "WO.Title",
        math.max(0, w - padding * 2 - 42), math.max(1, h - 6))

    if fittedText ~= "" then
        draw.SimpleText(fittedText, fittedFont, x + padding, y + h / 2,
            WO.UI.Colors.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
end

--- Полоса (HP/Mana/XP...).
function WO.UI.DrawBar(x, y, w, h, fraction, color, bgColor, text)
    fraction = math.Clamp(fraction or 0, 0, 1)

    draw.RoundedBox(4, x, y, w, h, bgColor or WO.UI.Colors.panelDark)

    if w > 2 and h > 2 then
        draw.RoundedBox(3, x + 1, y + 1, math.max(0, (w - 2) * fraction), h - 2,
            color or WO.UI.Colors.accent)
    end

    surface.SetDrawColor(0, 0, 0, 120)
    surface.DrawOutlinedRect(x, y, w, h, 1)

    if text then
        WO.UI.DrawTextFit(text, "WO.Small", x + w / 2, y + h / 2,
            color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, w - 8, h - 2)
    end
end

--- Возвращает цвет редкости.
function WO.UI.GetRarityColor(rarity)
    return WO.Enums.RarityColors[rarity] or WO.Enums.RarityColors.common
end
