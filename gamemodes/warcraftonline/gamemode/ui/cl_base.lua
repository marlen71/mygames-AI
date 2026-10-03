--[[
    Warcraft Online — базовые UI-компоненты (client).
    WO.Panel / WO.Button / WO.Label / WO.Window / WO.ProgressBar / WO.Scroll
]]

---------------------------------------------------------------------------
-- WO.Panel — базовая стилизованная панель
---------------------------------------------------------------------------

local PANEL = {}

function PANEL:Init()
    self:SetPaintBackground(false)
end

function PANEL:Paint(w, h)
    WO.UI.DrawPanelOutlined(0, 0, w, h, WO.UI.Colors.panel, WO.UI.Colors.border)
end

vgui.Register("WO_Panel", PANEL, "DPanel")

---------------------------------------------------------------------------
-- WO.ProgressBar — полоса HP/Mana/XP
---------------------------------------------------------------------------

local PROGRESS = {}

AccessorFunc(PROGRESS, "fraction", "Fraction", FORCE_NUMBER)
AccessorFunc(PROGRESS, "barColor", "BarColor")
AccessorFunc(PROGRESS, "bgColor", "BGColor")
AccessorFunc(PROGRESS, "barText", "BarText")

function PROGRESS:Init()
    self.fraction = 1
    self.barColor = WO.UI.Colors.accent
    self.bgColor = WO.UI.Colors.panelDark
    self.barText = nil
end

function PROGRESS:Paint(w, h)
    WO.UI.DrawBar(0, 0, w, h, self.fraction, self.barColor, self.bgColor, self.barText)
end

vgui.Register("WO_ProgressBar", PROGRESS, "DPanel")

---------------------------------------------------------------------------
-- WO.Button — кнопка в стиле MMORPG
---------------------------------------------------------------------------

local BUTTON = {}

AccessorFunc(BUTTON, "accent", "Accent", FORCE_BOOL)
AccessorFunc(BUTTON, "font", "Font")

function BUTTON:Init()
    self:SetText("")
    self:SetTall(32)
    self.hovered = false
    self.accent = false
    self.font = "WO.Body"
end

function BUTTON:OnCursorEntered()
    self.hovered = true

    if WO.Sound and WO.Sound.PlayLocal then
        WO.Sound.PlayLocal("ui_hover")
    end
end

function BUTTON:OnCursorExited()
    self.hovered = false
end

function BUTTON:DoClick()
    if WO.Sound and WO.Sound.PlayLocal then
        WO.Sound.PlayLocal("ui_click")
    end
end

function BUTTON:Paint(w, h)
    local bg = WO.UI.Colors.panelLight

    if self.accent then
        bg = self.hovered and WO.UI.Colors.accent or WO.UI.Colors.accentDark
    elseif self.hovered then
        bg = WO.UI.Colors.border
    end

    if not self:IsEnabled() then
        bg = WO.UI.Colors.panelDark
    end

    WO.UI.DrawPanelOutlined(0, 0, w, h, bg, WO.UI.Colors.border, WO.UI.Metrics.radiusSmall)

    local textColor = WO.UI.Colors.text

    if self.accent and self.hovered then
        textColor = Color(30, 24, 8)
    elseif not self:IsEnabled() then
        textColor = WO.UI.Colors.textDark
    end

    WO.UI.DrawTextFit(self:GetText(), self.font or "WO.Body", w / 2, h / 2,
        textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, w - 16, h - 6)
end

vgui.Register("WO_Button", BUTTON, "DButton")

---------------------------------------------------------------------------
-- WO.Label — текст
---------------------------------------------------------------------------

local LABEL = {}

AccessorFunc(LABEL, "font", "Font")
AccessorFunc(LABEL, "col", "TextColor2")

function LABEL:Init()
    self:SetText("")
    self.font = "WO.Body"
    self.col = WO.UI.Colors.text
    self.woAlignment = 4 -- middle-left, matching the usual DLabel default
    self.woCentered = false
end

local function SplitLongWord(word, font, maxWidth)
    local lines = {}
    local characters = {}
    local index = 1

    while index <= #word do
        local firstByte = string.byte(word, index)
        local length = firstByte >= 240 and 4 or (firstByte >= 224 and 3 or
            (firstByte >= 192 and 2 or 1))
        length = math.min(length, #word - index + 1)
        characters[#characters + 1] = string.sub(word, index, index + length - 1)
        index = index + length
    end

    surface.SetFont(font)

    local chunk = ""

    for _, character in ipairs(characters) do
        local candidate = chunk .. character
        local width = surface.GetTextSize(candidate)

        if chunk ~= "" and width > maxWidth then
            lines[#lines + 1] = chunk
            chunk = character
        else
            chunk = candidate
        end
    end

    if chunk ~= "" then
        lines[#lines + 1] = chunk
    end

    return lines
end

local function WrapLabelText(text, font, maxWidth)
    local lines = {}
    local limit = math.max(1, maxWidth)

    surface.SetFont(font)

    for paragraph in string.gmatch(tostring(text or "") .. "\n", "(.-)\n") do
        local line = ""

        for word in string.gmatch(paragraph, "%S+") do
            local candidate = line == "" and word or (line .. " " .. word)
            local width = surface.GetTextSize(candidate)

            if line ~= "" and width > limit then
                lines[#lines + 1] = line
                line = ""
            end

            if line == "" then
                local wordWidth = surface.GetTextSize(word)

                if wordWidth <= limit then
                    line = word
                else
                    local pieces = SplitLongWord(word, font, limit)

                    for index = 1, #pieces - 1 do
                        lines[#lines + 1] = pieces[index]
                    end

                    line = pieces[#pieces] or ""
                end
            else
                line = line .. " " .. word
            end
        end

        if line ~= "" or #lines == 0 then
            lines[#lines + 1] = line
        end
    end

    return lines
end

function LABEL:Paint(w, h)
    -- Один общий painter: поддерживает перенос длинных токенов и все 9 вариантов
    -- SetContentAlignment, поэтому выравнивание меток не игнорируется.
    local font = self.font or "WO.Body"
    local padding = 4

    surface.SetFont(font)
    local _, lineHeight = surface.GetTextSize("Ag")
    lineHeight = math.max(1, lineHeight)

    local lines = WrapLabelText(self:GetText() or "", font, w - padding * 2)
    local blockHeight = #lines * lineHeight
    local alignment = math.Clamp(math.floor(tonumber(self.woAlignment) or 4), 1, 9)
    local horizontal = (alignment - 1) % 3
    local vertical = math.floor((alignment - 1) / 3)
    local x, textAlign

    if horizontal == 1 then
        x = w / 2
        textAlign = TEXT_ALIGN_CENTER
    elseif horizontal == 2 then
        x = w - padding
        textAlign = TEXT_ALIGN_RIGHT
    else
        x = padding
        textAlign = TEXT_ALIGN_LEFT
    end

    local y

    if vertical == 0 then
        y = padding
    elseif vertical == 2 then
        y = math.max(0, h - blockHeight - padding)
    else
        y = math.max(0, math.floor((h - math.min(h, blockHeight)) / 2))
    end

    for _, line in ipairs(lines) do
        if y + lineHeight > h then break end

        draw.SimpleText(line, font, x, y, self.col or WO.UI.Colors.text,
            textAlign, TEXT_ALIGN_TOP)
        y = y + lineHeight
    end
end

function LABEL:SetTextColor(col)
    self.col = col
end

function LABEL:SetContentAlignment(alignment)
    self.woAlignment = math.Clamp(math.floor(tonumber(alignment) or 4), 1, 9)
    self.woCentered = self.woAlignment == 2 or self.woAlignment == 5 or self.woAlignment == 8
end

function LABEL:SetCentered(centered)
    self:SetContentAlignment(centered and 5 or 4)
end

vgui.Register("WO_Label", LABEL, "DLabel")

---------------------------------------------------------------------------
-- WO.Window — окно с заголовком и перетаскиванием
---------------------------------------------------------------------------

local WINDOW = {}

function WINDOW:Init()
    self.windowTitle = ""
    self:SetDraggable(true)
    self:SetSizable(false)
    self:SetDeleteOnClose(true)

    -- DFrame keeps its built-in caption empty; only the WO title bar is visible.
    if isfunction(self.SetTitle) then
        self:SetTitle("")
    end

    if IsValid(self.lblTitle) then
        self.lblTitle:SetVisible(false)
    end

    self:ShowCloseButton(false)

    self.closeButton = vgui.Create("WO_Button", self)
    self.closeButton:SetText("✕")
    self.closeButton:SetSize(30, 28)
    self.closeButton.DoClick = function()
        if WO.Sound and WO.Sound.PlayLocal then
            WO.Sound.PlayLocal("ui_close")
        end

        self:Close()
    end
end

function WINDOW:PerformLayout(w, h)
    if IsValid(self.closeButton) then
        self.closeButton:SetPos(w - 36, 6)
    end
end

function WINDOW:Paint(w, h)
    WO.UI.DrawPanelOutlined(0, 0, w, h, WO.UI.Colors.bg, WO.UI.Colors.border,
        WO.UI.Metrics.radius)
    WO.UI.DrawTitleBar(0, 0, w, 38, self.windowTitle)
end

function WINDOW:SetWindowTitle(title)
    self.windowTitle = tostring(title or "")
end

function WINDOW:GetWindowTitle()
    return self.windowTitle or ""
end

vgui.Register("WO_Window", WINDOW, "DFrame")

---------------------------------------------------------------------------
-- Фабрики
---------------------------------------------------------------------------

--- Создаёт окно.
function WO.UI.Window(title, w, h)
    local frame = vgui.Create("WO_Window")

    frame:SetWindowTitle(title or "")
    frame:SetSize(w or 600, h or 400)
    frame:Center()
    frame:MakePopup()

    if WO.Sound and WO.Sound.PlayLocal then
        WO.Sound.PlayLocal("ui_open")
    end

    return frame
end

--- Создаёт кнопку.
function WO.UI.Button(parent, text, onClick)
    local button = vgui.Create("WO_Button", parent)

    button:SetText(text or "")

    if isfunction(onClick) then
        button.DoClick = function()
            if WO.Sound and WO.Sound.PlayLocal then
                WO.Sound.PlayLocal("ui_click")
            end

            onClick(button)
        end
    end

    return button
end

--- Создаёт текстовую метку.
function WO.UI.Label(parent, text, font, col)
    local label = vgui.Create("WO_Label", parent)

    label:SetText(text or "")

    if font then
        label:SetFont(font)
    end

    if col then
        label:SetTextColor(col)
    end

    return label
end

--- Создаёт полосу прогресса.
function WO.UI.ProgressBar(parent, color, bgColor)
    local bar = vgui.Create("WO_ProgressBar", parent)

    if color then bar:SetBarColor(color) end
    if bgColor then bar:SetBGColor(bgColor) end

    return bar
end

--- Создаёт скролл-панель.
function WO.UI.Scroll(parent)
    local scroll = vgui.Create("DScrollPanel", parent)

    local sbar = scroll:GetVBar()

    if IsValid(sbar) then
        sbar:SetWide(6)

        function sbar:Paint(w, h)
            draw.RoundedBox(2, 0, 0, w, h, WO.UI.Colors.panelDark)
        end

        if IsValid(sbar.btnGrip) then
            function sbar.btnGrip:Paint(w, h)
                draw.RoundedBox(2, 0, 0, w, h, WO.UI.Colors.borderLight)
            end
        end

        if IsValid(sbar.btnUp) then
            function sbar.btnUp:Paint(w, h) end
        end

        if IsValid(sbar.btnDown) then
            function sbar.btnDown:Paint(w, h) end
        end
    end

    return scroll
end
