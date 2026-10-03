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

    draw.SimpleText(self:GetText(), self.font or "WO.Body", w / 2, h / 2, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
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
    self.woCentered = false
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
                line = word
            else
                line = candidate
            end
        end

        if line ~= "" or #lines == 0 then
            lines[#lines + 1] = line
        end
    end

    return lines
end

function LABEL:Paint(w, h)
    -- Единственная точка отрисовки label: перенос по ширине и clip по высоте
    -- не дают длинным названиям/описаниям залезать на соседние элементы.
    local font = self.font or "WO.Body"
    local _, lineHeight = surface.GetTextSize("Ag")
    lineHeight = math.max(1, lineHeight)

    local lines = WrapLabelText(self:GetText() or "", font, w - 8)
    local x = self.woCentered and w / 2 or 0
    local align = self.woCentered and TEXT_ALIGN_CENTER or TEXT_ALIGN_LEFT
    local y = math.max(0, math.floor((h - math.min(h, #lines * lineHeight)) / 2))

    surface.SetFont(font)

    for _, line in ipairs(lines) do
        if y + lineHeight > h then break end

        draw.SimpleText(line, font, x, y, self.col or WO.UI.Colors.text,
            align, TEXT_ALIGN_TOP)
        y = y + lineHeight
    end
end

function LABEL:SetTextColor(col)
    self.col = col
end

function LABEL:SetCentered(centered)
    self.woCentered = centered == true
end

vgui.Register("WO_Label", LABEL, "DLabel")

---------------------------------------------------------------------------
-- WO.Window — окно с заголовком и перетаскиванием
---------------------------------------------------------------------------

local WINDOW = {}

AccessorFunc(WINDOW, "title", "Title")

function WINDOW:Init()
    self.title = "Window"
    self:SetDraggable(true)
    self:SetSizable(false)
    self:SetDeleteOnClose(true)
    self:SetTitle("")
    self:ShowCloseButton(false)

    self.closeButton = vgui.Create("WO_Button", self)
    self.closeButton:SetText("✕")
    self.closeButton:SetSize(28, 28)
    self.closeButton.DoClick = function()
        if WO.Sound and WO.Sound.PlayLocal then
            WO.Sound.PlayLocal("ui_close")
        end

        self:Close()
    end
end

function WINDOW:PerformLayout(w, h)
    self.closeButton:SetPos(w - 34, 6)
end

function WINDOW:Paint(w, h)
    draw.RoundedBox(WO.UI.Metrics.radius, 0, 0, w, h, WO.UI.Colors.bg)
    WO.UI.DrawTitleBar(0, 0, w, 38, self.title)

    surface.SetDrawColor(WO.UI.Colors.border)
    surface.DrawOutlinedRect(0, 0, w, h, 1)
end

function WINDOW:SetTitle2(title)
    self.title = title
end

vgui.Register("WO_Window", WINDOW, "DFrame")

---------------------------------------------------------------------------
-- Фабрики
---------------------------------------------------------------------------

--- Создаёт окно.
function WO.UI.Window(title, w, h)
    local frame = vgui.Create("WO_Window")

    frame:SetTitle(title or "")
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
