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
    ui_open = "ui/buttonclickrelease.wav",
    ui_close = "ui/buttonclickrelease.wav",
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
-- Items with this schema price (buy or sell) and above are considered valuable
-- for the optional server-authoritative auto-collect setting.
WO.Config.AutoCollectValueThreshold = 15
-- Aim-trace range used only to recognize an NPC for the HUD nameplate/halo.
WO.Config.NPCHoverTraceRange = 1800

-- Draconic Base templates use SWEP.UseHands = true and GMod c_arms models.
-- Registered player-model hand mappings are preferred; this is the safe fallback.
WO.Config.DefaultHandsModel = "models/weapons/c_arms.mdl"

---------------------------------------------------------------------------
-- Точные внешние SWEP-классы стартового оружия.
-- Магические классы получают нашу книгу; заклинания обрабатывает собственная система.
-- Руки выдаются сервером напрямую, а knife — только при экипировке starter_knife.
WO.Config.StartingWeaponClasses = {
    hands = "drc_unarmed",
    knife = "tfa_cso_coldsteelblade",
    mage = "wo_magic_grimoire", -- сохранили ключ для совместимости конфигураций
    grimoireClasses = {
        "mage", "priest", "druid", "shaman", "warlock", "evoker",
        "alchemist", "runeknight",
    },
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
-- Map-specific NPC spawn points.
-- World/NPC coordinates were supplied for rp_lordaeron; on other maps these
-- NPCs remain unplaced rather than being moved to guessed coordinates.
---------------------------------------------------------------------------

WO.Config.WorldMap = "rp_lordaeron"

-- Точки штабеля/склада отделены от мест появления работодателей.
-- Работы лесоруба доступны только на настроенной карте rp_lordaeron.
WO.Config.ProfessionWorksites = WO.Config.ProfessionWorksites or {}
WO.Config.ProfessionWorksites.lumberjack = {
    map = WO.Config.WorldMap,
    pickupPos = Vector(-8583.5, 1422.4, -2772),
    deliveryPos = Vector(-7312.7, 1722.3, -2943.2),
    interactionRadius = 160,
    sequenceLength = 6,
    carryWeaponClass = "wo_lumber_logs",
    carryModel = "models/lumber/lumber.mdl",
}

WO.Config.NPCSpawnPoints = {
    -- Работодатели спавнятся только по указанным координатам rp_lordaeron.
    work_lumberjack = {
        { map = WO.Config.WorldMap, pos = Vector(-7212.8, 1684.4, -2942.4), ang = Angle(-2, -143, 0) },
    },
    work_miner = {
        { map = WO.Config.WorldMap, pos = Vector(-7898.3, 1848.8, -2896.8), ang = Angle(4, -52, 0) },
    },
    work_farmer = {
        { map = WO.Config.WorldMap, pos = Vector(-3114.2, -4176.7, -3072), ang = Angle(0, -136, 0) },
    },
    work_herder = {
        { map = WO.Config.WorldMap, pos = Vector(-5823.3, -5347.6, -3072), ang = Angle(0, 0, 0) },
    },
    work_fisher = {
        { map = WO.Config.WorldMap, pos = Vector(-4211.7, -7101, -3072.7), ang = Angle(3, 8, 0) },
    },
    work_porter = {
        { map = WO.Config.WorldMap, pos = Vector(-7321.9, 9852, -1572), ang = Angle(0, -175, 0) },
    },
    work_blacksmith = {
        { map = WO.Config.WorldMap, pos = Vector(-4926.8, 9688.6, -1572), ang = Angle(0, -180, 0) },
    },
    work_tailor = {
        --{ map = WO.Config.WorldMap, pos = Vector(), ang = Angle(0, 0, 0) },
    },
    work_baker = {
        { map = WO.Config.WorldMap, pos = Vector(-5965.9, 7210.9, -1572), ang = Angle(0, 36, 0) },
    },
    work_brewer = {
        { map = WO.Config.WorldMap, pos = Vector(-6257.3, 8075.1, -1558), ang = Angle(0, 90, 0) },
    },
    work_alchemist = {
        { map = WO.Config.WorldMap, pos = Vector(-8680.7, 7593, -1489), ang = Angle(0, 90, 0) },
    },
    work_merchant = {
        --{ map = WO.Config.WorldMap, pos = Vector(), ang = Angle(0, 0, 0) },
    },
    work_cleaner = {
        { map = WO.Config.WorldMap, pos = Vector(-6034, 8606.4, -1572), ang = Angle(0, 0, 0) },
    },
    work_water_carrier = {
        { map = WO.Config.WorldMap, pos = Vector(-8950.7, 8737.1, -1572), ang = Angle(0, 90, 0) },
    },
    work_carpenter = {
        --{ map = WO.Config.WorldMap, pos = Vector(), ang = Angle(0, 0, 0) },
    },
    work_weaponsmith = {
        --{ map = WO.Config.WorldMap, pos = Vector(), ang = Angle(0, 0, 0) },
    },
    work_jeweler = {
        --{ map = WO.Config.WorldMap, pos = Vector(), ang = Angle(0, 0, 0) },
    },
    work_dockworker = {
        --{ map = WO.Config.WorldMap, pos = Vector(), ang = Angle(0, 0, 0) },
    },
    work_beekeeper = {
        { map = WO.Config.WorldMap, pos = Vector(-3046.5, -6456.3, -3072), ang = Angle(0, 180, 0) },
    },
    work_herbalist = {
        { map = WO.Config.WorldMap, pos = Vector(-6111.5, -4552.5, -3072), ang = Angle(0, -90, 0) },
    },
    work_builder = {
        --{ map = WO.Config.WorldMap, pos = Vector(), ang = Angle(0, 0, 0) },
    },

    hunter_dyrne = {
        { map = WO.Config.WorldMap, pos = Vector(-5812.6, 7972.9, -1572), ang = Angle(0, 4, 0) },
    },
    marshal_dughal = {
        { map = WO.Config.WorldMap, pos = Vector(-8678.3, 8009.3, -1489), ang = Angle(1, 46, 0) },
    },
    trader_marla = {
        { map = WO.Config.WorldMap, pos = Vector(-7083.1, 8847.6, -1535.6), ang = Angle(2, -90, 0) },
    },
    mount_merchant = {
        { map = WO.Config.WorldMap, pos = Vector(-7316.9, 8827.6, -1572), ang = Angle(1, -65, 0) },
    },
    malygos_scroll_vendor = {
        { map = WO.Config.WorldMap, pos = Vector(-6746.5, 8830.4, -1572), ang = Angle(0, -45, 0) },
    },
    black_wolf = {
        { map = WO.Config.WorldMap, spawnKey = "wolf_01", questId = "wolves_of_elwynn",
            pos = Vector(-2674.5, -10887.5, -3072), ang = Angle(0, 0, 0), level = 1 },
        { map = WO.Config.WorldMap, spawnKey = "wolf_02", questId = "wolves_of_elwynn",
            pos = Vector(-3131.4, -10645.7, -3072), ang = Angle(0, 0, 0), level = 2 },
        { map = WO.Config.WorldMap, spawnKey = "wolf_03", questId = "wolves_of_elwynn",
            pos = Vector(-2746.8, -10087.1, -3072), ang = Angle(0, 0, 0), level = 3 },
        { map = WO.Config.WorldMap, spawnKey = "wolf_04", questId = "wolves_of_elwynn",
            pos = Vector(-2182.1, -11247.3, -3072), ang = Angle(0, 0, 0), level = 4 },
    },
    elwynn_boar = {
        -- Persistent ambient world mobs are available to every character; quests
        -- count their deaths without gating the NPCs on a character's quest state.
        { map = WO.Config.WorldMap, spawnKey = "boar_01", questId = "boar_hunt",
            ambient = true, respawnDelay = 30,
            pos = Vector(-5344.3, 1652.2, -3071.8), ang = Angle(0, 0, 0), level = 1 },
        { map = WO.Config.WorldMap, spawnKey = "boar_02", questId = "boar_hunt",
            ambient = true, respawnDelay = 30,
            pos = Vector(-5158.9, 1170.1, -3072), ang = Angle(0, 0, 0), level = 2 },
        { map = WO.Config.WorldMap, spawnKey = "boar_03", questId = "boar_hunt",
            ambient = true, respawnDelay = 30,
            pos = Vector(-4937.5, 833.7, -3072), ang = Angle(0, 0, 0), level = 3 },
        { map = WO.Config.WorldMap, spawnKey = "boar_04", questId = "boar_hunt",
            ambient = true, respawnDelay = 30,
            pos = Vector(-4810.9, 1435.8, -3071.5), ang = Angle(0, 0, 0), level = 4 },
    },
}

WO.Config.MagicScrolls = {
    sellRate = 0.25,
    stackSize = 20,
    learningPrice = 40,
    rankPriceMultiplier = 1.5,
    rankPriceStep = 0.5,
    vendorStockAmount = 20,
}

-- These are built-in GMod sounds/effects, grouped by spell element so the
-- grimoire never depends on a mismatched shared zap or optional particle pack.
WO.Config.SpellEffects = {
    fire = {
        castSound = "ambient/fire/fire_small1.wav",
        impactSound = "ambient/fire/fire_medburn.wav",
        effect = "Explosion",
        effectScale = 0.55,
    },
    water = {
        castSound = "ambient/water/water_splash1.wav",
        impactSound = "ambient/water/water_splash2.wav",
        effect = "WaterSurfaceExplosion",
        effectScale = 0.7,
    },
    air = {
        castSound = "ambient/wind/wind_snippet1.wav",
        impactSound = "ambient/wind/wind_snippet1.wav",
        effect = "cball_bounce",
        effectScale = 0.6,
    },
    earth = {
        castSound = "physics/concrete/rock_impact_hard1.wav",
        impactSound = "physics/concrete/rock_impact_hard1.wav",
        effect = "ThumperDust",
        effectScale = 0.65,
    },
    frost = {
        castSound = "physics/glass/glass_impact_bullet1.wav",
        impactSound = "physics/glass/glass_impact_bullet2.wav",
        effect = "GlassImpact",
        effectScale = 0.6,
    },
    lightning = {
        castSound = "ambient/energy/zap1.wav",
        impactSound = "ambient/energy/zap5.wav",
        effect = "TeslaHitBoxes",
        effectScale = 0.7,
    },
    life = {
        castSound = "items/medshot4.wav",
        impactSound = "items/medshot4.wav",
        effect = "VortDispel",
        effectScale = 0.65,
    },
}

WO.Config.Mounts = {
    horseClass = "wow_npc_8883",
    stoneItem = "mount_stone",
    maximumLevel = 5,
    maximumHunger = 100,
    hungerPerMinute = 1,
    definitions = {
        ["wow_npc_8883"] = {
            name = "Лошадь",
            maximumLevel = 5,
            baseHealth = 120,
            healthPerLevel = 35,
            maximumHunger = 100,
            maximumArmorLevel = 3,
            armorReductionPerLevel = 0.06,
            feedItem = "mount_oats",
            trainingItem = "mount_training_kit",
            healingItem = "mount_healing_salve",
            armorItem = "mount_barding",
            hungerPerFeed = 35,
            healAmount = 60,
            minimumArmorLevel = 2,
        },
    },
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
