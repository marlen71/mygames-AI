--[[
    Warcraft Online — игровые перечисления (enums).
    Единый источник констант для всех систем.
]]

WO.Enums = WO.Enums or {}

-- Состояния предмета (защита от дюпа: переходы контролируются сервером).
WO.Enums.ItemState = {
    INVENTORY = "inventory",
    EQUIPPED = "equipped",
    WORLD = "world",
    CONTAINER = "container",
    DESTROYED = "destroyed",
}

-- Типы предметов.
WO.Enums.ItemType = {
    WEAPON = "weapon",
    ARMOR = "armor",
    HELMET = "helmet",
    BOOTS = "boots",
    GLOVES = "gloves",
    RING = "ring",
    AMULET = "amulet",
    FOOD = "food",
    DRINK = "drink",
    CONSUMABLE = "consumable",
    MATERIAL = "material",
    QUEST = "quest",
    CONTAINER = "container",
    CURRENCY = "currency",
    MISC = "misc",
    SPECIAL = "special",
}

-- Редкость предметов.
WO.Enums.Rarity = {
    POOR = "poor",
    COMMON = "common",
    UNCOMMON = "uncommon",
    RARE = "rare",
    EPIC = "epic",
    LEGENDARY = "legendary",
    ARTIFACT = "artifact",
    QUEST = "quest",
}

-- Цвета редкости (используются UI).
WO.Enums.RarityColors = {
    poor = Color(157, 157, 157),
    common = Color(255, 255, 255),
    uncommon = Color(30, 200, 30),
    rare = Color(64, 156, 255),
    epic = Color(170, 80, 255),
    legendary = Color(255, 128, 0),
    artifact = Color(255, 80, 80),
    quest = Color(255, 200, 40),
}

-- Типы урона.
WO.Enums.DamageType = {
    PHYSICAL = "physical",
    FIRE = "fire",
    FROST = "frost",
    ARCANE = "arcane",
    NATURE = "nature",
    SHADOW = "shadow",
    HOLY = "holy",
    POISON = "poison",
}

-- Слоты экипировки (расширяются конфигом).
WO.Enums.EquipSlot = {
    HEAD = "head",
    NECK = "neck",
    SHOULDERS = "shoulders",
    CHEST = "chest",
    BACK = "back",
    HANDS = "hands",
    BELT = "belt",
    LEGS = "legs",
    FEET = "feet",
    MAIN_HAND = "main_hand",
    OFF_HAND = "off_hand",
    RING_1 = "ring_1",
    RING_2 = "ring_2",
    AMULET = "amulet",
}

-- Типы пола (расширяется конфигом WO.Config.Genders).
WO.Enums.Gender = {
    MALE = "male",
    FEMALE = "female",
}

-- Типы целей способностей (для будущих систем).
WO.Enums.TargetType = {
    SELF = "self",
    ALLY = "ally",
    ENEMY = "enemy",
    AREA = "area",
    CONE = "cone",
    GROUND = "ground",
}

-- Типы уведомлений.
WO.Enums.NotifyType = {
    INFO = "info",
    SUCCESS = "success",
    ERROR = "error",
    XP = "xp",
    ITEM = "item",
    LEVELUP = "levelup",
    COMBAT = "combat",
}

-- Типы целей (target system).
WO.Enums.TargetKind = {
    PLAYER = "player",
    NPC = "npc",
    ENTITY = "entity",
}
