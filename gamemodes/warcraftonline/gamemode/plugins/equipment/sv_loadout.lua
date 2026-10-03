--[[
    Warcraft Online — выдача стартовых SWEP (server).
    Это loadout игрока, НЕ инвентарные предметы и НЕ слоты экипировки.
    Точные классы и их доступность проверяются по runtime weapon registry.
]]

WO.Loadout = WO.Loadout or {}

local warnedMissing = {}

local function GetDesired(char)
    local configured = WO.Config.StartingWeaponClasses or {}
    local desired, seen = {}, {}

    local function add(class)
        if isstring(class) and class ~= "" and not seen[class] then
            seen[class] = true
            desired[#desired + 1] = class
        end
    end

    add(configured.hands)

    local isMage = char and char.class == "mage"

    if isMage then
        add(configured.mage)
    end

    -- Non-mages keep the standard hands SWEP until they equip their starter
    -- knife item from the inventory. The mage wand remains a direct loadout.
    local primary = isMage and configured.mage or configured.hands

    return desired, primary
end

local function IsRegistered(class)
    return isstring(class) and weapons and isfunction(weapons.GetStored) and
        weapons.GetStored(class) ~= nil
end

function WO.Loadout.GetDesiredClasses(char)
    local desired = GetDesired(char)

    return desired
end

--- Idempotently gives exact configured SWEP classes and strips stale WO kit weapons.
function WO.Loadout.Apply(ply, char)
    if not IsValid(ply) or not WO.Character.IsCharacter(char) or
        ply:GetCharacter() ~= char then return nil end

    local desired, primary = GetDesired(char)
    local wanted = {}

    for _, class in ipairs(desired) do
        wanted[class] = true
    end

    for _, weapon in ipairs(ply:GetWeapons()) do
        if IsValid(weapon) and weapon.WOStarterLoadout == true and
            not weapon.WOItemUID and not wanted[weapon:GetClass()] then
            ply:StripWeapon(weapon:GetClass())
        end
    end

    for _, class in ipairs(desired) do
        if not IsRegistered(class) then
            if not warnedMissing[class] then
                warnedMissing[class] = true
                WO.Warn("Starter SWEP is not registered; skipping exact class '" .. class .. "'")
            end
        else
            if not ply:HasWeapon(class) then
                ply:Give(class)
            end

            local weapon = ply:GetWeapon(class)

            if IsValid(weapon) then
                weapon.WOStarterLoadout = true
                weapon.WOItemUID = nil
                weapon.WOItemClass = nil
            end
        end
    end

    if primary and IsRegistered(primary) and ply:HasWeapon(primary) then
        return primary
    end

    local hands = WO.Config.StartingWeaponClasses and WO.Config.StartingWeaponClasses.hands

    if hands and IsRegistered(hands) and ply:HasWeapon(hands) then
        return hands
    end

    return nil
end

function WO.Loadout.Clear(ply)
    if not IsValid(ply) then return end

    for _, weapon in ipairs(ply:GetWeapons()) do
        if IsValid(weapon) and weapon.WOStarterLoadout == true then
            ply:StripWeapon(weapon:GetClass())
        end
    end
end
