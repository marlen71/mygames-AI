--[[
    Warcraft Online — каталог optional-ассетов Garry's Mod Workshop.

    В каталог заносятся только подтверждённые IDs аддонов. Пути моделей и
    SWEP-классы из описаний, где их нет, не угадываются: их адаптер обнаруживает
    по реально загруженному NPC/SWEP-реестру и проверяет через file.Exists(...).
    Проверенные владельцем пути можно задать в WO.Config.WorkshopModelOverrides.
]]

WO.Workshop = WO.Workshop or {}

WO.Config.Workshop = WO.Config.Workshop or {}
-- Тяжёлый recursive scan выключен по умолчанию; включает администратор, если
-- NPC-пак смонтирован, но не публикует model path в стандартном registry.
WO.Config.Workshop.DeepModelDiscovery = WO.Config.Workshop.DeepModelDiscovery == true
WO.Config.Workshop.ModelScanDirectoryLimit = tonumber(WO.Config.Workshop.ModelScanDirectoryLimit) or 2500
WO.Config.WorkshopModelOverrides = WO.Config.WorkshopModelOverrides or {}

WO.Workshop.Collections = {
    wow = {
        id = 3801728890,
        title = "World of Warcraft",
        url = "https://steamcommunity.com/sharedfiles/filedetails/?id=3801728890",
        -- Collection contents are not assumed; verified addon items are listed below.
    },
}

WO.Workshop.PlayableCharacterPack = {
    id = 3796529373,
    title = "World of Warcraft (1.12.1) – Playable Characters Megapack (All Outfits)",
    url = "https://steamcommunity.com/sharedfiles/filedetails/?id=3796529373",
}

-- Clients download these addons automatically. The dedicated server must also
-- subscribe/mount them to pass runtime model/SWEP/NPC-class validation.
WO.Workshop.RequiredAddons = {
    { id = 3796529373, title = "Playable Characters Megapack" },
    { id = 3798571666, title = "Creatures Megapack" },
    { id = 1847505933, title = "Draconic Base" },
    { id = 712848264, title = "TFA CS:O / Nexon SWEPs Part 1" },
    { id = 2840031720, title = "TFA Base" },
    { id = 1309914309, title = "TFA CS:O Part 2" },
    { id = 1538229351, title = "TFA CS:O Part 3" },
    { id = 1845577793, title = "TFA CS:O Part 4" },
}

WO.Workshop.RequestedNPCClasses = {
    wolf = "wow_npc_14892",
    boar = "wow_npc_2809",
    horseMount = "wow_npc_8883",
}

WO.Workshop.RequestedSWEPs = {
    hands = WO.Config.StartingWeaponClasses.hands,
    starterKnife = WO.Config.StartingWeaponClasses.knife,
    mageGrimoire = WO.Config.StartingWeaponClasses.mage,
}

WO.Workshop.Catalog = {
    draconic_base = {
        id = 1847505933,
        title = "Draconic Base",
        type = "framework",
        url = "https://steamcommunity.com/sharedfiles/filedetails/?id=1847505933",
    },

    basic_swords = {
        id = 3605762684,
        title = "Basic Swords (Swords + Abilities)",
        type = "weapons",
        url = "https://steamcommunity.com/sharedfiles/filedetails/?id=3605762684",
        weaponSearch = {
            nameTerms = { "sword" },
            contextTerms = { "basic swords", "sword" },
        },
    },

    wow_creatures = {
        id = 3798571666,
        title = "World of Warcraft – Creatures Megapack (NPCs & Mounts)",
        type = "npc_pack",
        url = "https://steamcommunity.com/sharedfiles/filedetails/?id=3798571666",
    },

    wow_wolf = {
        id = 3798571666,
        title = "World of Warcraft level-one wolf",
        type = "npc_model",
        url = "https://steamcommunity.com/sharedfiles/filedetails/?id=3798571666",
        npcSearch = {
            nameTerms = { "wolf" },
            level = 1,
            categoryTerms = { "wow", "world of warcraft", "creature" },
        },
        modelSearch = {
            nameTerms = { "wolf" },
            preferredPathTerms = { "wow", "world", "creature", "npc" },
            requirePreferredPath = true,
        },
    },

    wow_vendor = {
        id = 3798571666,
        title = "World of Warcraft merchant NPC",
        type = "npc_model",
        url = "https://steamcommunity.com/sharedfiles/filedetails/?id=3798571666",
        npcSearch = {
            nameTerms = { "merchant", "vendor", "trader", "innkeeper", "shopkeeper" },
            categoryTerms = { "wow", "world of warcraft", "creature" },
        },
        modelSearch = {
            nameTerms = { "merchant", "vendor", "trader", "innkeeper", "shopkeeper" },
            preferredPathTerms = { "wow", "world", "creature", "npc" },
            requirePreferredPath = true,
        },
    },

    wow_questgiver = {
        id = 3798571666,
        title = "World of Warcraft quest giver NPC",
        type = "npc_model",
        url = "https://steamcommunity.com/sharedfiles/filedetails/?id=3798571666",
        npcSearch = {
            nameTerms = { "quest giver", "questgiver", "marshal", "captain", "guard" },
            categoryTerms = { "wow", "world of warcraft", "creature" },
        },
        modelSearch = {
            nameTerms = { "quest", "marshal", "captain", "guard" },
            preferredPathTerms = { "wow", "world", "creature", "npc" },
            requirePreferredPath = true,
        },
    },

    cso_part1 = {
        id = 712848264,
        title = "TFA Counter-Strike: Online / Counter-Strike Nexon: Zombie SWEPs [Part 1]",
        type = "weapon_pack",
        url = "https://steamcommunity.com/sharedfiles/filedetails/?id=712848264",
        dependencies = { 2840031720, 1309914309, 1538229351, 1845577793 },
        weaponSearch = {
            nameTerms = { "knife" },
            contextTerms = { "tfa", "cso", "nexon", "counter-strike: online", "counter strike online" },
            requireContext = true,
        },
    },

    black_wolf = {
        id = 2080218553,
        title = "Black Wolf PlayerModel [ANIMS FIXED]",
        type = "model",
        url = "https://steamcommunity.com/sharedfiles/filedetails/?id=2080218553",
        playerModelSearch = { "wolf" },
    },

    kha_beleth = {
        id = 2326822966,
        title = "Dark Messiah of Might and Magic - Kha-Beleth",
        type = "model",
        url = "https://steamcommunity.com/sharedfiles/filedetails/?id=2326822966",
    },
}
