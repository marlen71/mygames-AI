--[[
    Warcraft Online — характеристики персонажа (client).
    Все показатели находятся в обзоре игрового меню; отдельного окна листа нет.
]]

WO.CharacterUI = WO.CharacterUI or {}

local STAT_ORDER = {
    "strength", "agility", "intelligence", "stamina", "spirit",
    "maxHealth", "maxMana", "maxStamina",
    "attackPower", "spellPower", "armor", "magicResistance",
    "critChance", "critMultiplier", "attackSpeed",
}

local function GetStatsPanelSize(width)
    local columns = width >= 960 and 3 or (width >= 560 and 2 or 1)
    local rows = math.ceil(#STAT_ORDER / columns)

    return 52 + rows * 42 + 16, columns
end

--- Adds the complete character sheet as a responsive card in the menu overview.
function WO.CharacterUI.BuildOverviewStats(parent)
    if not IsValid(parent) or not (WO.Character and WO.Character.GetLocal and
        WO.Character.GetLocal()) then
        return nil
    end

    local panel = vgui.Create("DPanel", parent)
    panel.woCharacterStatsOverview = true
    panel:Dock(TOP)
    panel:DockMargin(0, 0, 0, 14)
    panel:SetPaintBackground(false)

    local panelHeight = GetStatsPanelSize(parent:GetWide())
    panel:SetTall(panelHeight)

    panel.PerformLayout = function(self, width)
        local nextHeight = GetStatsPanelSize(width)

        if self:GetTall() ~= nextHeight then
            self:SetTall(nextHeight)
        end
    end

    panel.Paint = function(_, width, height)
        WO.UI.DrawPanelOutlined(0, 0, width, height, WO.UI.Colors.panel,
            WO.UI.Colors.border, WO.UI.Metrics.radius)
        WO.UI.DrawTextFit(WO.Lang:Get("stats.overview_title"), "WO.Subtitle",
            16, 22, WO.UI.Colors.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER,
            width - 32, 28)

        local stats = WO.Stats and WO.Stats.Networked or {}
        local _, columns = GetStatsPanelSize(width)
        local gap = 8
        local cellWidth = math.max(1,
            math.floor((width - 32 - gap * (columns - 1)) / columns))
        local anyValue = false

        for index, stat in ipairs(STAT_ORDER) do
            local value = stats[stat]

            if value ~= nil then
                anyValue = true
                local row = math.floor((index - 1) / columns)
                local column = (index - 1) % columns
                local x = 16 + column * (cellWidth + gap)
                local y = 48 + row * 42

                WO.UI.DrawPanelOutlined(x, y, cellWidth, 36,
                    WO.UI.Colors.panelDark, WO.UI.Colors.border,
                    WO.UI.Metrics.radiusSmall)
                WO.UI.DrawTextFit(WO.Lang:Get("stats." .. stat), "WO.Tiny",
                    x + 8, y + 18, WO.UI.Colors.textDim,
                    TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER,
                    math.max(0, cellWidth - 68), 28)
                WO.UI.DrawTextFit(tostring(value), "WO.Small",
                    x + cellWidth - 10, y + 18, WO.UI.Colors.text,
                    TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, 58, 28)
            end
        end

        if not anyValue then
            WO.UI.DrawTextFit(WO.Lang:Get("stats.loading"), "WO.Small",
                16, math.max(54, height / 2), WO.UI.Colors.textDim,
                TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, width - 32, 26)
        end
    end

    return panel
end

--- Legacy entry point now opens the overview instead of a separate character window.
function WO.CharacterUI.OpenSheet()
    if not (WO.Character and WO.Character.GetLocal and WO.Character.GetLocal()) then return end

    if WO.MenuUI and WO.MenuUI.IsOpen and WO.MenuUI.IsOpen() then
        if WO.MenuUI.ActivatePage then
            WO.MenuUI.ActivatePage("overview")
        end
    elseif WO.MenuUI and WO.MenuUI.Show then
        WO.MenuUI.Show("overview")
    end
end

WO.UI.BindKey(KEY_C, function()
    WO.CharacterUI.OpenSheet()
end, "character_sheet", { allowWhenMenuOpen = true })
