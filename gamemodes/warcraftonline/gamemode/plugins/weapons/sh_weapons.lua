--[[
    Warcraft Online — регистрация оружия (shared).
    WO.Weapons.Register(SWEP, "wo_sword_iron") — с гарантированным наследованием
    от SWEP.Base (даже если движок не смержит базу при ручной регистрации).
]]

WO.Weapons = WO.Weapons or {}

local function MergeBase(sWEP, baseName)
    local base = weapons.GetStored(baseName)

    if not base then
        return sWEP
    end

    -- Рекурсивно поднимаемся по цепочке баз
    if isstring(base.Base) and base.Base ~= "" then
        base = MergeBase(base, base.Base)
    end

    local merged = {}

    -- Сначала поля базы, затем собственные (собственные приоритетнее)
    for k, v in pairs(base) do
        merged[k] = v
    end

    for k, v in pairs(sWEP) do
        merged[k] = v
    end

    return merged
end

--[[
    Регистрирует SWEP с наследованием от SWEP.Base.

    @param sWEP table таблица оружия
    @param name string класс оружия
    @return boolean success
]]
function WO.Weapons.Register(sWEP, name)
    if not istable(sWEP) or not isstring(name) then
        WO.Error("WO.Weapons.Register: invalid arguments")
        return false
    end

    if weapons.GetStored(name) then
        WO.Error("WO.Weapons.Register: duplicate weapon '" .. name .. "'")
        return false
    end

    if isstring(sWEP.Base) and sWEP.Base ~= "" and sWEP.Base ~= "weapon_base" then
        if not weapons.GetStored(sWEP.Base) then
            WO.Error("WO.Weapons.Register: missing base '" .. sWEP.Base .. "' for '" .. name .. "'")
            return false
        end

        sWEP = MergeBase(sWEP, sWEP.Base)
    end

    sWEP.Base = "weapon_base"
    sWEP.Spawnable = false
    sWEP.AdminSpawnable = false

    weapons.Register(sWEP, name)

    WO.Debug("Weapon registered: " .. name)

    return true
end
