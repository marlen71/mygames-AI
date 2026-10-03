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
-- Руки и mage wand выдаются сервером напрямую; knife хранится как starter_knife
-- и выдаётся только после экипировки этого предмета.
WO.Config.StartingWeaponClasses = {
    hands = "drc_unarmed",
    knife = "tfa_cso_coldsteelblade",
    mage = "weapon_hpwr_stick",
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
    marshal_dughal = {
        { map = "gm_construct", pos = Vector(1034.032104, -752.511169, 555.071106),
            ang = Angle(0, 111.095940, 0) },
    },
    trader_marla = {
        { map = "gm_construct", pos = Vector(241.648193, -703.025330, 288.031250),
            ang = Angle(0, 174.366852, 0) },
    },
    hunter_dyrne = {
        { map = "gm_construct", pos = Vector(1311.738403, -690.454651, 555.031250),
            ang = Angle(0, -168.689941, 0) },
    },
    black_wolf = {
        { map = "gm_construct", spawnKey = "wolf_01", questId = "wolves_of_elwynn",
            pos = Vector(-4250.202637, -2959.930420, 341.783325),
            ang = Angle(4.358677, -145.187195, 0), level = 1 },
        { map = "gm_construct", spawnKey = "wolf_02", questId = "wolves_of_elwynn",
            pos = Vector(-4461.224609, -2726.230957, 367.600311),
            ang = Angle(14.055275, -45.276627, 0), level = 2 },
        { map = "gm_construct", spawnKey = "wolf_03", questId = "wolves_of_elwynn",
            pos = Vector(-4566.822754, -3216.632813, 372.478424),
            ang = Angle(6.210093, 47.811897, 0), level = 3 },
        { map = "gm_construct", spawnKey = "wolf_04", questId = "wolves_of_elwynn",
            pos = Vector(-4318.115234, -3496.344238, 350.265167),
            ang = Angle(2.142816, 171.127808, 0), level = 4 },
        { map = "gm_construct", spawnKey = "wolf_05", questId = "wolves_of_elwynn",
            pos = Vector(-4176.732910, -3662.390381, 395.388916),
            ang = Angle(7.635193, 71.658203, 0), level = 5 },
        { map = "gm_construct", spawnKey = "wolf_06", questId = "wolves_of_elwynn",
            pos = Vector(-4488.355957, -3710.287842, 342.031250),
            ang = Angle(1.942766, 122.819931, 0), level = 3 },
        { map = "gm_construct", spawnKey = "wolf_07", questId = "wolves_of_elwynn",
            pos = Vector(-4671.655273, -3484.655029, 346.534424),
            ang = Angle(4.295212, 102.034912, 0), level = 4 },
    },
    elwynn_boar = {
        { map = "gm_construct", spawnKey = "boar_01", questId = "boar_hunt",
            pos = Vector(-3255.734375, 5412.966797, 325.156250),
            ang = Angle(2.456238, -133.576599, 0), level = 1 },
        { map = "gm_construct", spawnKey = "boar_02", questId = "boar_hunt",
            pos = Vector(-3652.754639, 5225.623535, 343.739868),
            ang = Angle(3.171993, 12.198708, 0), level = 2 },
        { map = "gm_construct", spawnKey = "boar_03", questId = "boar_hunt",
            pos = Vector(-3540.874512, 5798.093750, 340.031250),
            ang = Angle(1.414176, -116.576233, 0), level = 3 },
        { map = "gm_construct", spawnKey = "boar_04", questId = "boar_hunt",
            pos = Vector(-3199.655029, 5841.290527, 318.031250),
            ang = Angle(0.841175, -86.152107, 0), level = 4 },
        { map = "gm_construct", spawnKey = "boar_05", questId = "boar_hunt",
            pos = Vector(-2919.605225, 5738.161621, 339.234558),
            ang = Angle(1.156565, -177.910553, 0), level = 5 },
        { map = "gm_construct", spawnKey = "boar_06", questId = "boar_hunt",
            pos = Vector(-2779.346680, 5427.133789, 325.250122),
            ang = Angle(1.172629, 140.552307, 0), level = 2 },
        { map = "gm_construct", spawnKey = "boar_07", questId = "boar_hunt",
            pos = Vector(-3023.465332, 5333.988281, 317.609741),
            ang = Angle(0.612598, 127.742920, 0), level = 3 },
    },
}

---------------------------------------------------------------------------
-- Характеристики в бою
---------------------------------------------------------------------------

WO.Config.MeleeStaminaCost = 5      -- Расход выносливости за удар
WO.Config.CombatRegenDelay = 5      -- Секунд после боя до регена

-- Tab зарезервирован за единым scoreboard/menu; цель переключается на F3.
WO.Config.TargetingKeyName = "KEY_F3"
