--[[
    Warcraft Online — собственный селектор оружия (client).
    Список строится только по реально выданным LocalPlayer SWEP; сервер повторно
    проверяет владение перед каждым переключением.
]]

WO.WeaponSelector = WO.WeaponSelector or {}

local MAX_VISIBLE_WEAPONS = 6

local function GetWeaponClass(weapon)
    if not IsValid(weapon) or not isfunction(weapon.GetClass) then return nil end

    local class = weapon:GetClass()
    return isstring(class) and class ~= "" and class or nil
end

local function FindItemDefinition(weaponClass)
    for _, def in pairs(WO.Items.GetAll and WO.Items.GetAll() or {}) do
        if def.weapon and def.weapon.class == weaponClass then
            return def
        end
    end

    return nil
end

local function GetWeaponName(weapon, weaponClass)
    local itemDef = FindItemDefinition(weaponClass)

    if itemDef and isstring(itemDef.name) and itemDef.name ~= "" then
        return itemDef.name
    end

    local stored = weapons and isfunction(weapons.GetStored) and weapons.GetStored(weaponClass)
    local name = isfunction(weapon.GetPrintName) and weapon:GetPrintName() or
        weapon.PrintName or (stored and stored.PrintName)

    if not isstring(name) or name == "" or string.sub(name, 1, 1) == "#" then
        return weaponClass
    end

    return name
end

function WO.WeaponSelector.GetWeapons(ply)
    ply = ply or LocalPlayer()
    if not IsValid(ply) or not isfunction(ply.GetWeapons) then return {} end

    local active = isfunction(ply.GetActiveWeapon) and ply:GetActiveWeapon() or nil
    local activeClass = GetWeaponClass(active)
    local entries, seen = {}, {}

    for _, weapon in ipairs(ply:GetWeapons() or {}) do
        local class = GetWeaponClass(weapon)

        if class and not seen[class] then
            seen[class] = true
            local stored = weapons and isfunction(weapons.GetStored) and weapons.GetStored(class)
            local slot = isfunction(weapon.GetSlot) and weapon:GetSlot() or
                (stored and tonumber(stored.Slot)) or tonumber(weapon.Slot) or 0
            local slotPos = isfunction(weapon.GetSlotPos) and weapon:GetSlotPos() or
                (stored and tonumber(stored.SlotPos)) or tonumber(weapon.SlotPos) or 0

            entries[#entries + 1] = {
                class = class,
                name = GetWeaponName(weapon, class),
                slot = tonumber(slot) or 0,
                slotPos = tonumber(slotPos) or 0,
                active = class == activeClass,
            }
        end
    end

    table.sort(entries, function(a, b)
        if a.slot ~= b.slot then return a.slot < b.slot end
        if a.slotPos ~= b.slotPos then return a.slotPos < b.slotPos end
        return a.class < b.class
    end)

    return entries
end

function WO.WeaponSelector.GetVisibleWeapons(ply)
    local allWeapons = WO.WeaponSelector.GetWeapons(ply)
    local count = #allWeapons

    if count <= MAX_VISIBLE_WEAPONS then
        for index, entry in ipairs(allWeapons) do
            entry.slot = index
            entry.index = index
        end

        return allWeapons
    end

    local activeIndex = 1

    for index, entry in ipairs(allWeapons) do
        if entry.active then
            activeIndex = index
            break
        end
    end

    local firstIndex = math.max(1, math.min(activeIndex,
        count - MAX_VISIBLE_WEAPONS + 1))
    local visible = {}

    for index = firstIndex, firstIndex + MAX_VISIBLE_WEAPONS - 1 do
        local entry = allWeapons[index]
        entry.slot = index - firstIndex + 1
        entry.index = index
        visible[#visible + 1] = entry
    end

    return visible
end

function WO.WeaponSelector.SelectClass(class)
    if not isstring(class) then return false end

    local found = false

    for _, entry in ipairs(WO.WeaponSelector.GetWeapons()) do
        if entry.class == class then
            found = true
            break
        end
    end

    if not found then return false end

    WO.Net.SendToServer("Weapons.Select", class)
    return true
end

function WO.WeaponSelector.SelectSlot(slot)
    slot = math.floor(tonumber(slot) or 0)

    if slot < 1 or slot > MAX_VISIBLE_WEAPONS then return false end

    for _, entry in ipairs(WO.WeaponSelector.GetVisibleWeapons()) do
        if entry.slot == slot then
            return WO.WeaponSelector.SelectClass(entry.class)
        end
    end

    return false
end

function WO.WeaponSelector.Cycle(direction)
    local weapons = WO.WeaponSelector.GetWeapons()
    local count = #weapons

    if count == 0 then return false end

    local activeIndex

    for index, entry in ipairs(weapons) do
        if entry.active then
            activeIndex = index
            break
        end
    end

    if not activeIndex then
        activeIndex = direction and direction < 0 and 1 or count
    end

    local step = (tonumber(direction) or 1) < 0 and -1 or 1
    local nextIndex = ((activeIndex - 1 + step) % count) + 1
    return WO.WeaponSelector.SelectClass(weapons[nextIndex].class)
end

local function IsZoomModifierDown()
    if not input or not isfunction(input.IsKeyDown) then return false end

    local leftAlt = rawget(_G, "KEY_LALT")
    local rightAlt = rawget(_G, "KEY_RALT")

    return (leftAlt and input.IsKeyDown(leftAlt)) or
        (rightAlt and input.IsKeyDown(rightAlt)) or false
end

local function HasKeyboardFocus()
    if not vgui or not isfunction(vgui.GetKeyboardFocus) then return false end

    return IsValid(vgui.GetKeyboardFocus())
end

hook.Add("PlayerBindPress", "wo_weapon_selector_bind", function(ply, bind, pressed)
    if ply ~= LocalPlayer() or not IsValid(ply) or not ply:HasCharacter() then return end
    if HasKeyboardFocus() or (gui and gui.IsGameUIVisible and gui.IsGameUIVisible()) then return end
    if WO.MenuUI and WO.MenuUI.IsOpen and WO.MenuUI.IsOpen() then return end

    if bind == "invnext" or bind == "invprev" then
        -- Alt + wheel remains a camera zoom gesture; plain wheel changes weapon.
        if IsZoomModifierDown() then return end
        if pressed then WO.WeaponSelector.Cycle(bind == "invprev" and -1 or 1) end
        return true
    end

    local slot = tonumber(string.match(bind or "", "^slot([1-6])$"))

    if slot then
        if pressed then WO.WeaponSelector.SelectSlot(slot) end
        return true
    end
end)
