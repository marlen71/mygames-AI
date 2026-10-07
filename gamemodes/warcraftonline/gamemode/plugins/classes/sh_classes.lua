--[[
    Warcraft Online — система классов (shared).
    Data-driven: новый класс добавляется файлом в schemas/classes/.

    WO.Classes:Register({
        id = "warrior",
        name = "Воин",
        description = "...",

        stats = {
            strength = 12, agility = 9, intelligence = 6,
            stamina = 11, spirit = 8,
        },

        resource = "stamina",       -- "mana" | "stamina" | "energy" (будущее)

        allowedWeapons = { "melee", "sword", "axe", "shield" },
        allowedArmor = { "plate", "mail", "leather", "shield" },

        abilities = {},             -- id способностей (будущее)
        startingItems = {
            { class = "iron_sword", amount = 1 },
        },
        startingEquipment = { main_hand = "iron_sword" },

        modifiers = {},
    })
]]

WO.Classes.Registry = WO.Classes.Registry or WO.Registry.New("Classes")

--[[
    Регистрирует класс.

    @param def table определение класса
    @return boolean success
]]
function WO.Classes.Register(def)
    if not istable(def) or not isstring(def.id) then
        WO.Error("WO.Classes.Register: invalid class definition")
        return false
    end

    def.name = def.name or def.id
    def.stats = def.stats or {}
    def.allowedWeapons = def.allowedWeapons or {}
    def.allowedArmor = def.allowedArmor or {}
    def.startingItems = def.startingItems or {}
    def.startingEquipment = def.startingEquipment or {}
    def.abilities = def.abilities or {}
    def.professionBonuses = istable(def.professionBonuses) and def.professionBonuses or {}
    def.magicBonuses = istable(def.magicBonuses) and def.magicBonuses or {}

    return WO.Classes.Registry:Register(def.id, def)
end

--- Получить класс по id.
function WO.Classes.Get(id)
    return WO.Classes.Registry:Get(id)
end

--- Все классы.
function WO.Classes.GetAll()
    return WO.Classes.Registry:GetAll()
end

--- Список id классов.
function WO.Classes.GetIDs()
    return WO.Classes.Registry:GetIDs()
end

function WO.Classes.IsCharacterCreationAllowed(classId, raceId)
    if not WO.Classes.Get(classId) then return false end

    local order = WO.Config and WO.Config.CharacterCreationClassOrder
    if istable(order) then
        local found = false
        for _, configuredId in ipairs(order) do
            if configuredId == classId then
                found = true
                break
            end
        end
        if not found then return false end
    end

    if raceId and WO.Races and WO.Races.IsClassAllowed and
        not WO.Races.IsClassAllowed(raceId, classId) then
        return false
    end

    return true
end

function WO.Classes.GetCharacterCreationIDs(raceId)
    local out = {}
    local order = WO.Config and WO.Config.CharacterCreationClassOrder or WO.Classes.GetIDs()

    for _, classId in ipairs(order) do
        if WO.Classes.IsCharacterCreationAllowed(classId, raceId) then
            out[#out + 1] = classId
        end
    end

    return out
end

--[[
    Базовые характеристики класса.

    @param classId string
    @return table
]]
function WO.Classes.GetStats(classId)
    local class = WO.Classes.Get(classId)

    return (class and class.stats) or {}
end

--[[
    Разрешён ли классу тип оружия/брони.

    @param classId string
    @param category string категория (melee, plate, ...)
    @return boolean
]]
function WO.Classes.IsWeaponAllowed(classId, category)
    local class = WO.Classes.Get(classId)

    if not class then return false end

    if #class.allowedWeapons == 0 then return true end

    for _, cat in ipairs(class.allowedWeapons) do
        if cat == category then
            return true
        end
    end

    return false
end

function WO.Classes.IsArmorAllowed(classId, category)
    local class = WO.Classes.Get(classId)

    if not class then return false end

    if #class.allowedArmor == 0 then return true end

    for _, cat in ipairs(class.allowedArmor) do
        if cat == category then
            return true
        end
    end

    return false
end

--[[
    Стартовые предметы класса.

    @param classId string
    @return table массив { class, amount }
]]
function WO.Classes.GetStartingItems(classId)
    local class = WO.Classes.Get(classId)

    return (class and class.startingItems) or {}
end
