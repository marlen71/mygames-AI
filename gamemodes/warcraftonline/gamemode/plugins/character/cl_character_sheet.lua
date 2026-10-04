--[[
    Warcraft Online — меню персонажа / статы (client).
    Клавиша C: лист персонажа (характеристики, уровень, опыт).
]]

WO.CharacterUI = WO.CharacterUI or {}

local sheetFrame = nil
local sheetSubtitle = nil
local sheetXPLabel = nil
local sheetXPBar = nil

local function RefreshSheetProgress(data)
    if not IsValid(sheetFrame) then return end

    local char = WO.Character.GetLocal()
    if not char then return end

    data = istable(data) and data or (WO.Leveling and WO.Leveling.ClientData) or {}
    local level = math.max(1, tonumber(data.level) or tonumber(char.level) or 1)
    local needed = math.max(1, tonumber(data.needed) or WO.Config.GetXPForLevel(level))
    local experience = math.max(0, tonumber(data.experience) or tonumber(char.experience) or 0)

    if IsValid(sheetSubtitle) then
        local race = WO.Races.Get(char.race)
        local class = WO.Classes.Get(char.class)
        sheetSubtitle:SetDisplayText(WO.Lang:Get("character.level") .. " " .. level .. " · " ..
            (race and race.name or char.race) .. " · " .. (class and class.name or char.class))
    end

    if IsValid(sheetXPLabel) then
        sheetXPLabel:SetDisplayText(WO.Lang:Get("xp.compact", experience, needed,
            math.max(0, needed - experience)))
    end

    if IsValid(sheetXPBar) then
        sheetXPBar:SetFraction(experience / needed)
    end
end

local STAT_ORDER = {
    "strength", "agility", "intelligence", "stamina", "spirit",
    "maxHealth", "maxMana", "maxStamina",
    "attackPower", "spellPower", "armor", "magicResistance",
    "critChance", "critMultiplier", "attackSpeed",
}

function WO.CharacterUI.OpenSheet()
    if IsValid(sheetFrame) then
        sheetFrame:Remove()
        sheetFrame = nil

        return
    end

    local char = WO.Character.GetLocal()

    if not char then return end

    sheetFrame = WO.UI.Window(WO.Lang:Get("character_menu.title"), 380, 570)

    -- Имя и уровень
    local header = WO.UI.Label(sheetFrame, char:GetFullName(), "WO.Title", WO.UI.Colors.accent)

    header:SetPos(20, 50)
    header:SetSize(340, 28)

    local level = (WO.Leveling.ClientData and WO.Leveling.ClientData.level) or char.level or 1
    local race = WO.Races.Get(char.race)
    local class = WO.Classes.Get(char.class)

    local subtitle = WO.UI.Label(sheetFrame,
        WO.Lang:Get("character.level") .. " " .. level .. " · " ..
        (race and race.name or char.race) .. " · " ..
        (class and class.name or char.class),
        "WO.Small", WO.UI.Colors.textDim)

    subtitle:SetPos(20, 82)
    subtitle:SetSize(340, 20)
    sheetSubtitle = subtitle

    local xp = WO.Leveling and WO.Leveling.ClientData or {}
    local xpNeeded = math.max(1, tonumber(xp.needed) or WO.Config.GetXPForLevel(level))
    local experience = math.max(0, tonumber(xp.experience) or tonumber(char.experience) or 0)
    local xpLabel = WO.UI.Label(sheetFrame,
        WO.Lang:Get("xp.compact", experience, xpNeeded,
            math.max(0, xpNeeded - experience)), "WO.Tiny", WO.UI.Colors.textDim)
    xpLabel:SetPos(20, 108)
    xpLabel:SetSize(340, 18)
    sheetXPLabel = xpLabel

    local xpBar = WO.UI.ProgressBar(sheetFrame, WO.UI.Colors.xp, WO.UI.Colors.xpBg)
    xpBar:SetPos(20, 130)
    xpBar:SetSize(340, 9)
    xpBar:SetFraction(experience / xpNeeded)
    sheetXPBar = xpBar

    -- Статы
    local stats = WO.Stats.Networked or {}
    local y = 154

    for _, stat in ipairs(STAT_ORDER) do
        local value = stats[stat]

        if value ~= nil then
            local nameLabel = WO.UI.Label(sheetFrame, WO.Lang:Get("stats." .. stat), "WO.Body")

            nameLabel:SetPos(24, y)
            nameLabel:SetSize(220, 20)

            local valueLabel = WO.UI.Label(sheetFrame, tostring(value), "WO.Body", WO.UI.Colors.accent)

            valueLabel:SetPos(250, y)
            valueLabel:SetSize(100, 20)

            y = y + 24
        end
    end

    -- Кнопка выхода из персонажа
    local logoutButton = WO.UI.Button(sheetFrame, WO.Lang:Get("character.logout"), function()
        sheetFrame:Close()
        sheetFrame = nil

        WO.Character.RequestLogout()
    end)

    logoutButton:SetPos(20, 526)
    logoutButton:SetSize(340, 32)

    sheetFrame.OnRemove = function()
        sheetFrame = nil
        sheetSubtitle = nil
        sheetXPLabel = nil
        sheetXPBar = nil
    end

    RefreshSheetProgress(WO.Leveling and WO.Leveling.ClientData)
end

WO.Hook.Add("LevelingSynced", "character_sheet_progress", RefreshSheetProgress)

WO.Hook.Add("CharacterMenuOpening", "character_sheet_close", function()
    if IsValid(sheetFrame) then
        sheetFrame:Remove()
        sheetFrame = nil
    end

    sheetSubtitle = nil
    sheetXPLabel = nil
    sheetXPBar = nil
end)

WO.UI.BindKey(KEY_C, function()
    if WO.Character.GetLocal() then
        WO.CharacterUI.OpenSheet()
    end
end, "character_sheet")
