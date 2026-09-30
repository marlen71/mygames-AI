--[[
    Warcraft Online — меню персонажа / статы (client).
    Клавиша C: лист персонажа (характеристики, уровень, опыт).
]]

WO.CharacterUI = WO.CharacterUI or {}

local sheetFrame = nil

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

    sheetFrame = WO.UI.Window(WO.Lang:Get("character_menu.title"), 380, 520)

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

    -- Статы
    local stats = WO.Stats.Networked or {}
    local y = 120

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

    logoutButton:SetPos(20, 470)
    logoutButton:SetSize(340, 32)

    sheetFrame.OnRemove = function()
        sheetFrame = nil
    end
end

WO.UI.BindKey(KEY_C, function()
    if WO.Character.GetLocal() then
        WO.CharacterUI.OpenSheet()
    end
end, "character_sheet")
