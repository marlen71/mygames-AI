--[[
    Warcraft Online — игровые настройки: звуки, слоты экипировки, UI.
]]

---------------------------------------------------------------------------
-- Слоты экипировки (порядок отображения в UI)
---------------------------------------------------------------------------

WO.Config.EquipSlots = {
    { id = "head",      nameKey = "slot.head" },
    { id = "neck",      nameKey = "slot.neck" },
    { id = "shoulders", nameKey = "slot.shoulders" },
    { id = "chest",     nameKey = "slot.chest" },
    { id = "back",      nameKey = "slot.back" },
    { id = "hands",     nameKey = "slot.hands" },
    { id = "belt",      nameKey = "slot.belt" },
    { id = "legs",      nameKey = "slot.legs" },
    { id = "feet",      nameKey = "slot.feet" },
    { id = "main_hand", nameKey = "slot.main_hand" },
    { id = "off_hand",  nameKey = "slot.off_hand" },
    { id = "ring_1",    nameKey = "slot.ring_1" },
    { id = "ring_2",    nameKey = "slot.ring_2" },
    { id = "amulet",    nameKey = "slot.amulet" },
}

---------------------------------------------------------------------------
-- Звуки (централизованно; не хардкодить в плагинах)
---------------------------------------------------------------------------

WO.Config.Sounds = {
    ui_click = "ui/buttonclickrelease.wav",
    ui_hover = "ui/buttonrollover.wav",
    ui_open = "menu/menu_open.wav",
    ui_close = "menu/menu_close.wav",
    item_pickup = "items/ammo_pickup.wav",
    item_drop = "items/item_drop.wav",
    item_equip = "items/ammo_pickup.wav",
    item_unequip = "items/ammo_pickup.wav",
    inventory_move = "ui/buttonclickrelease.wav",
    level_up = "garrysmod/content_downloaded.wav",
    error = "buttons/button10.wav",
    notify = "buttons/lightswitch2.wav",
    death = "vo/npc/male01/ow01.wav",
    coin = "ambient/levels/labs/coinslot1.wav",
}

---------------------------------------------------------------------------
-- Инвентарь
---------------------------------------------------------------------------

WO.Config.InventoryWidth = 10
WO.Config.InventoryHeight = 6

-- Draconic Base templates use SWEP.UseHands = true and GMod c_arms models.
-- Registered player-model hand mappings are preferred; this is the safe fallback.
WO.Config.DefaultHandsModel = "models/weapons/c_arms.mdl"

---------------------------------------------------------------------------
-- Стартовое оружие (баланс остаётся в конфиге, а предметы — в schemas/items)
---------------------------------------------------------------------------

WO.Config.StarterKnife = {
    damage = 6,
    range = 62,
    attackSpeed = 1.1,
    staminaCost = 2,
    durability = 55,
    durabilityLoss = 1,
    fallbackViewModel = "models/weapons/c_crowbar.mdl",
    fallbackWorldModel = "models/weapons/w_crowbar.mdl",
}

WO.Config.ArcaneHands = {
    damage = 7,
    range = 480,
    manaCost = 5,
    cooldown = 1.15,
    spellPowerScale = 0.2,
    fallbackViewModel = "models/weapons/c_arms.mdl",
    fallbackWorldModel = "models/weapons/w_physics.mdl",
}

---------------------------------------------------------------------------
-- Явные точки тестового квест-хаба (никакого поиска случайной позиции).
-- По умолчанию хаб есть только на gm_construct; для другой карты добавьте
-- её собственные map-specific записи в соответствующую схему NPC.
---------------------------------------------------------------------------

WO.Config.NPCSpawnPoints = {
    marshal_dughal = {
        { map = "gm_construct", anchor = "info_player_start", anchorIndex = 1,
            offset = Vector(170, 0, 8), ang = Angle(0, 180, 0) },
    },
    trader_marla = {
        { map = "gm_construct", anchor = "info_player_start", anchorIndex = 1,
            offset = Vector(0, 170, 8), ang = Angle(0, 90, 0) },
    },
    black_wolf = {
        { map = "gm_construct", anchor = "info_player_start", anchorIndex = 1,
            offset = Vector(-190, 0, 8), ang = Angle(0, 0, 0) },
    },
}

---------------------------------------------------------------------------
-- Характеристики в бою
---------------------------------------------------------------------------

WO.Config.MeleeStaminaCost = 5      -- Расход выносливости за удар
WO.Config.CombatRegenDelay = 5      -- Секунд после боя до регена

-- Tab зарезервирован за единым scoreboard/menu; цель переключается на F3.
WO.Config.TargetingKeyName = "KEY_F3"
