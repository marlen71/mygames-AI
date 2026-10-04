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
-- Точные внешние SWEP-классы стартового оружия.
-- Маг получает только нашу книгу; заклинания обрабатывает собственная система.
-- Руки выдаются сервером напрямую, а knife — только при экипировке starter_knife.
WO.Config.StartingWeaponClasses = {
    hands = "drc_unarmed",
    knife = "tfa_cso_coldsteelblade",
    mage = "wo_magic_grimoire",
}

---------------------------------------------------------------------------
-- Legacy-баланс предметов (не используется для стартовой выдачи SWEP)
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
-- Spawn-точки тестового хаба из переданного набора координат.
-- Привязка координат к gm_construct подтверждена пользователем 2026-10-04.
-- На других картах NPC не перемещаются в эти координаты и ждут своих точек.
---------------------------------------------------------------------------

WO.Config.NPCSpawnPoints = {
    hunter_dyrne = {
        { map = "gm_construct", pos = Vector(1572.5, -416.2, -144), ang = Angle(0, 180, 0) },
    },
    marshal_dughal = {
        { map = "gm_construct", pos = Vector(1341.2, -654.8, -144), ang = Angle(0, 0, 0) },
    },
    trader_marla = {
        { map = "gm_construct", pos = Vector(1089.1, -352.7, -144), ang = Angle(0, 90, 0) },
    },
    -- The request did not include a mount vendor coordinate. This is an explicit,
    -- provisional point in the same confirmed gm_construct hub; check its floor/clearance live.
    mount_merchant = {
        { map = "gm_construct", pos = Vector(850, -520, -144), ang = Angle(0, 0, 0) },
    },
    black_wolf = {
        { map = "gm_construct", spawnKey = "wolf_01", questId = "wolves_of_elwynn",
            pos = Vector(-4887.5, -3415.5, 250), ang = Angle(0, 0, 0), level = 1 },
        { map = "gm_construct", spawnKey = "wolf_02", questId = "wolves_of_elwynn",
            pos = Vector(-4415, -3048.3, 250), ang = Angle(0, 0, 0), level = 2 },
        { map = "gm_construct", spawnKey = "wolf_03", questId = "wolves_of_elwynn",
            pos = Vector(-4057.9, -2683.4, 250), ang = Angle(0, 0, 0), level = 3 },
        { map = "gm_construct", spawnKey = "wolf_04", questId = "wolves_of_elwynn",
            pos = Vector(-4878.6, -2474.7, 250), ang = Angle(0, 0, 0), level = 4 },
    },
    elwynn_boar = {
        { map = "gm_construct", spawnKey = "boar_01", questId = "boar_hunt",
            pos = Vector(1115.8, 6149.4, -32), ang = Angle(0, 0, 0), level = 1 },
        { map = "gm_construct", spawnKey = "boar_02", questId = "boar_hunt",
            pos = Vector(1593.3, 6078.2, -32), ang = Angle(0, 0, 0), level = 2 },
        { map = "gm_construct", spawnKey = "boar_03", questId = "boar_hunt",
            pos = Vector(1176.7, 5825.2, -32), ang = Angle(0, 0, 0), level = 3 },
        { map = "gm_construct", spawnKey = "boar_04", questId = "boar_hunt",
            pos = Vector(1586.2, 5735, -32), ang = Angle(0, 0, 0), level = 4 },
    },
}

WO.Config.Mounts = {
    horseClass = "wow_npc_8883",
    stoneItem = "mount_stone",
    maximumLevel = 5,
    maximumHunger = 100,
    hungerPerMinute = 1,
}

-- Радиусы взаимного знакомства (Source units); сервер применяет их к актуальным позициям.
WO.Config.IntroductionRanges = {
    whisper = { label = "Шёпотом", range = 180 },
    talk = { label = "Разговором", range = 560 },
    shout = { label = "Криком", range = 1400 },
}

---------------------------------------------------------------------------
-- Характеристики в бою
---------------------------------------------------------------------------

WO.Config.MeleeStaminaCost = 5      -- Расход выносливости за удар
WO.Config.CombatRegenDelay = 5      -- Секунд после боя до регена

-- Tab зарезервирован за единым scoreboard/menu; цель переключается на F3.
WO.Config.TargetingKeyName = "KEY_F3"
