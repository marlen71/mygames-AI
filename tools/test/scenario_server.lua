--[[
    scenario_server.lua — серверный smoke-тест Warcraft Online.
    Загружает гейммод (init.lua) через моки GMod API и прогоняет:
    загрузку → вход игрока → создание персонажа → инвентарь/валюта/опыт →
    бой → сохранение/перезагрузку → выход.
]]

local MOCK = MOCK

-- Тестовые mounted assets. Пути моделей нужны только для моков и не выдаются
-- за подтверждённые пути из внешнего Workshop-пака.
MOCK.mountedFiles = {
    ["models/mailer/character/human/male/humanmale00_00.mdl"] = true,
    ["models/mailer/character/human/female/humanfemale00_00.mdl"] = true,
    ["models/mailer/character/orc/male/orcmale00_00.mdl"] = true,
    ["models/mailer/wow_characters/wowanim_worgen_male.mdl"] = true,
    ["models/mailer/wow_characters/wowanim_skyhunterNL.mdl"] = true,
    ["models/mailer/wow_characters/wowanim_gnome_male.mdl"] = true,
    ["models/mailer/wow_characters/wowanim_c_stoneconstruct.mdl"] = true,
    ["models/mailer/wow_characters/wowanim_malygos.mdl"] = true,
}

-- Runtime registry mocks only the three exact required Workshop NPC classes.
scripted_ents.Register({}, "wow_npc_14892")
scripted_ents.Register({}, "wow_npc_2809")
scripted_ents.Register({}, "wow_npc_8883")

for _, class in ipairs({ "drc_unarmed", "tfa_cso_coldsteelblade", "weapon_hpwr_stick" }) do
    weapons.Register({
        PrintName = class,
        Category = "Workshop test fixture",
        Base = "weapon_base",
    }, class)
end

print("[scenario] loading gamemode (server)...")

include("gamemodes/warcraftonline/gamemode/init.lua")

-- GMod вызывает Initialize после загрузки Lua — инициализация БД и т.д.
hook.Run("Initialize")
hook.Run("InitPostEntity")
MOCK.RunTimers(0.1)

---------------------------------------------------------------------------
-- 1. Загрузка
---------------------------------------------------------------------------

MOCK.Assert(WO.Core.IsLoaded, "WO.Core.IsLoaded после загрузки")
MOCK.Assert(WO.GamemodeIncludeFolder == "warcraftonline/gamemode",
    "абсолютный include-root GMod: " .. tostring(WO.GamemodeIncludeFolder))
MOCK.Assert(table.Count(WO.Plugins.GetAll()) == 31,
    "загружены все 31 plugin metadata: " .. table.Count(WO.Plugins.GetAll()))
MOCK.Assert(WO.Plugins.IsLoaded("character") and WO.Plugins.IsLoaded("hud") and
    WO.Plugins.IsLoaded("spells") and WO.Plugins.IsLoaded("mounts") and
    WO.Plugins.IsLoaded("settings"),
    "плагины персонажа, HUD, книги заклинаний, маунтов и настроек загрузились")
MOCK.Assert(MOCK.clientFilesAdded["warcraftonline/gamemode/plugins/character/sh_plugin.lua"],
    "сервер отправил клиенту метаданные character через AddCSLuaFile")

do
weapons.Register({ Base = "weapon_base", WOTestInherited = true }, "wo_test_merge_parent")
local childDefinition = { Base = "wo_test_merge_parent", WOTestOwn = true }
MOCK.Assert(WO.Weapons.Register(childDefinition, "wo_test_merge_child") == true and
    weapons.GetStored("wo_test_merge_child").WOTestInherited == true and
    weapons.GetStored("wo_test_merge_child").WOTestOwn == true and
    weapons.GetStored("wo_test_merge_child").Base == "weapon_base",
    "MergeBase применяет цепочку наследования без рекурсии и сохраняет поля дочернего SWEP")
local registeredChild = weapons.GetStored("wo_test_merge_child")
MOCK.Assert(WO.Weapons.Register({ Base = "wo_test_merge_parent", WOTestOwn = true },
    "wo_test_merge_child") == true and weapons.GetStored("wo_test_merge_child") == registeredChild,
    "повторная идентичная регистрация SWEP идемпотентна")
weapons.Register({ Base = "wo_test_merge_cycle_b" }, "wo_test_merge_cycle_a")
weapons.Register({ Base = "wo_test_merge_cycle_a" }, "wo_test_merge_cycle_b")
MOCK.Assert(WO.Weapons.Register({ Base = "wo_test_merge_cycle_a" },
    "wo_test_merge_cycle_child") == false and weapons.GetStored("wo_test_merge_cycle_child") == nil,
    "циклические базовые SWEP отклоняются без stack overflow")
local savedLocalPlayer = LocalPlayer
LocalPlayer = nil
local serverUUID = WO.Util.UUID()
LocalPlayer = savedLocalPlayer
MOCK.Assert(WO.Util.IsUUID(serverUUID), "UUID создаётся на сервере без LocalPlayer")
end
MOCK.Assert(WO.Races.GetIDs and #WO.Races.GetIDs() == 17, "все 17 рас зарегистрированы: " ..
    (WO.Races.GetIDs and #WO.Races.GetIDs() or 0))
local explicitHumanModel = "models/mailer/character/human/male/humanmale00_00.mdl"
local discoveredHumanModel = "models/mailer/character/human/male/humanmale00_99.mdl"
MOCK.mountedFiles[explicitHumanModel] = nil
MOCK.mountedFiles[discoveredHumanModel] = true
player_manager.AddValidModel("humanmale00_99", discoveredHumanModel)
WO.Models.RefreshRaceLists()
local configuredHumanModels = WO.Races.GetModels("human", "male")
MOCK.Assert(table.HasValue(configuredHumanModels, explicitHumanModel) and
    not table.HasValue(configuredHumanModels, discoveredHumanModel),
    "race allowlist берёт явный путь без file.Exists и игнорирует player_manager discovery")
MOCK.mountedFiles[explicitHumanModel] = true
MOCK.Assert(WO.Classes.GetIDs and #WO.Classes.GetIDs() == 13,
    "зарегистрированы базовые и девять новых классов: " ..
        (WO.Classes.GetIDs and #WO.Classes.GetIDs() or 0))

local expectedRaces = {
    "human", "elf", "orc", "dwarf", "gnome", "undead", "tauren", "troll", "goblin",
    "bloodelf", "dracthyr", "draenei", "pandaren", "worgen", "vulpera", "sethrak", "naga",
}
local expectedClasses = {
    "warrior", "mage", "rogue", "ranger", "paladin", "priest", "druid", "shaman",
    "warlock", "monk", "deathknight", "demonhunter", "evoker",
}
local specialRaces = { bloodelf = true, dracthyr = true, vulpera = true }
local function HasCyrillic(values)
    for _, value in ipairs(values or {}) do
        for _, codepoint in utf8.codes(value) do
            if (codepoint >= 0x0410 and codepoint <= 0x044F) or
                codepoint == 0x0401 or codepoint == 0x0451 then
                return true
            end
        end
    end

    return false
end

local allRaceSchemasValid = true
for _, raceID in ipairs(expectedRaces) do
    local race = WO.Races.Get(raceID)
    local pools = WO.CharacterNames.Get(raceID)
    local russianName = WO.Lang:Get("race." .. raceID)
    local raceValid = race ~= nil and race.name == russianName and
        string.find(russianName, "race.", 1, true) == nil and
        (race.special == true) == (specialRaces[raceID] == true) and
        #WO.Races.GetModels(raceID, "male") > 0 and
        #WO.Races.GetModels(raceID, "female") > 0 and pools ~= nil and
        #pools.givenNames.male >= 25 and #pools.givenNames.female >= 25 and
        #pools.surnames >= 24 and HasCyrillic(pools.givenNames.male) and
        HasCyrillic(pools.givenNames.female) and HasCyrillic(pools.surnames)

    if race and istable(race.classes) then
        for _, classID in ipairs(race.classes) do
            if not WO.Classes.Get(classID) then raceValid = false end
        end
    end

    allRaceSchemasValid = allRaceSchemasValid and raceValid
end

local allClassesRegistered = true
for _, classID in ipairs(expectedClasses) do
    local class = WO.Classes.Get(classID)
    allClassesRegistered = allClassesRegistered and class ~= nil and
        isstring(class.name) and class.name ~= ""
end
MOCK.Assert(allRaceSchemasValid and allClassesRegistered,
    "у всех рас есть русское имя, модели обоих полов, классы и расширенные русские имена/фамилии")
MOCK.Assert(#WO.Models.GetConfiguredModels("pandaren", "male") == 18 and
    #WO.Models.GetConfiguredModels("pandaren", "female") == 20 and
    table.HasValue(WO.Races.GetModels("pandaren", "male"),
        "models/mailer/character/pandaren/male/pandarenmale05_02.mdl") and
    table.HasValue(WO.Races.GetModels("pandaren", "female"),
        "models/mailer/character/pandaren/female/pandarenfemale03_04.mdl"),
    "статический Pandaren-каталог содержит все 18 male и 20 female подтверждённых вариантов")
MOCK.Assert(WO.Races.IsSpecial("bloodelf") and WO.Races.IsSpecial("dracthyr") and
    WO.Races.IsSpecial("vulpera") and not WO.Races.IsSpecial("naga"),
    "только Blood Elf, Dracthyr и Vulpera отмечены особыми расами")
local specialRaceData = {
    name = "Аэлион", surname = "Светлый", age = 25, gender = "male",
    race = "bloodelf", class = "mage",
    model = WO.Races.GetModels("bloodelf", "male")[1], customization = {},
}
local nonAdminSpecial = MOCK.NewEntity("player")
local adminSpecial = MOCK.NewEntity("player")
adminSpecial.__admin = true
local nonAdminSpecialValid, nonAdminSpecialReason = WO.Character.Validate(specialRaceData,
    { strict = true, player = nonAdminSpecial })
local adminSpecialValid = WO.Character.Validate(specialRaceData,
    { strict = true, player = adminSpecial })
MOCK.Assert(not nonAdminSpecialValid and nonAdminSpecialReason == "race_unavailable" and
    adminSpecialValid == true and WO.Races.CanCreate("human", nonAdminSpecial),
    "строгая race-валидация блокирует особые расы для игрока и пропускает администратора")
local ordinarySlotPlayer = MOCK.NewEntity("player")
local adminSlotPlayer = MOCK.NewEntity("player")
adminSlotPlayer.__admin = true
MOCK.Assert(WO.Character.GetMaxCharacters(ordinarySlotPlayer) == 2 and
    WO.Character.GetMaxCharacters(adminSlotPlayer) == 5,
    "серверный лимит слотов: 2 для обычного игрока и 5 для администратора")

MOCK.Assert(WO.Items.GetAll and table.Count(WO.Items.GetAll()) >= 12,
    "предметы зарегистрированы: " .. (WO.Items.GetAll and table.Count(WO.Items.GetAll()) or 0))
local allItemsAreOneCell = true
for _, itemDef in pairs(WO.Items.GetAll()) do
    if itemDef.size.w ~= 1 or itemDef.size.h ~= 1 then
        allItemsAreOneCell = false
        break
    end
end
local fixedCapacityInventory = WO.Container.New("inventory", 10, 6)
local insertedHeavyItems = true
for index = 1, 60 do
    local instance = WO.Items.CreateInstance("wooden_shield", 1)
    local ok = instance and fixedCapacityInventory:AddItem(instance)
    if not ok then
        insertedHeavyItems = false
        break
    end
end
local occupiedCells = {}
local uniqueCells = true
for _, instance in pairs(fixedCapacityInventory:GetItems()) do
    local cell = tostring(instance.x) .. ":" .. tostring(instance.y)
    if occupiedCells[cell] then uniqueCells = false end
    occupiedCells[cell] = true
end
local overflowItem = WO.Items.CreateInstance("wooden_shield", 1)
local overflowPlaced, overflowReason = fixedCapacityInventory:AddItem(overflowItem)
MOCK.Assert(allItemsAreOneCell and insertedHeavyItems and uniqueCells and
    fixedCapacityInventory:ItemCount() == 60 and table.Count(occupiedCells) == 60 and
    overflowPlaced == false and overflowReason == "no_space",
    "все предметы занимают одну клетку; 10x6 вмещает ровно 60 даже при большом весе")

local legacyInventory = WO.Container.New("inventory", 2, 1)
for _ = 1, 2 do
    MOCK.Assert(legacyInventory:AddItem(WO.Items.CreateInstance("wooden_shield", 1)),
        "legacy inventory fixture accepts existing items")
end
local legacySerialized = legacyInventory:Serialize()
local originalInventoryFetch = WO.Database.Fetch
WO.Database.Fetch = function(self, query, ...)
    if string.find(query, "FROM wo_inventories", 1, true) then
        return { {
            width = 2,
            height = 1,
            items = util.TableToJSON(legacySerialized.items),
        } }
    end

    return originalInventoryFetch(self, query, ...)
end
local migratedCharacter = WO.Character.New({
    id = "legacy-inventory-dimensions", name = "Старая", surname = "Сетка",
    race = "human", gender = "male", class = "warrior", level = 1,
})
WO.Hook.Run("CharacterLoad", migratedCharacter)
WO.Database.Fetch = originalInventoryFetch
local migratedInventory = WO.Inventory.GetContainer(migratedCharacter)
MOCK.Assert(migratedInventory.width == 10 and migratedInventory.height == 6 and
    migratedInventory:ItemCount() == 2 and
    migratedInventory:CountItem("wooden_shield") == 2,
    "загрузка игнорирует старые размеры контейнера и сохраняет содержимое в сетке 10x6")

local overCapacityItems = {}
for index = 1, 61 do
    local itemData = WO.Items.Serialize(WO.Items.CreateInstance("wooden_shield", 1))
    itemData.x = (index - 1) % 10 + 1
    itemData.y = math.floor((index - 1) / 10) + 1
    overCapacityItems[index] = itemData
end
local overCapacity = WO.Container.Deserialize({
    id = "legacy-over-capacity", width = 10, height = 6,
    items = overCapacityItems,
})
local preservedOverflow = overCapacity:Serialize()
local overCapacityReloaded = WO.Container.Deserialize(preservedOverflow)
local visibleUID
for uid, instance in pairs(overCapacityReloaded:GetItems()) do
    if instance.x == 1 and instance.y == 1 then
        visibleUID = uid
        break
    end
end
if visibleUID then overCapacityReloaded:RemoveItem(visibleUID) end
overCapacityReloaded:RebuildGrid()
MOCK.Assert(overCapacity:ItemCount() == 61 and overCapacity:CountUnplacedItems() == 1 and
    #preservedOverflow.items == 61 and overCapacityReloaded:ItemCount() == 60 and
    overCapacityReloaded:CountUnplacedItems() == 0,
    "61-й предмет сохраняется вне сетки, переживает сериализацию и восстанавливается после освобождения ячейки")
MOCK.Assert(WO.Models ~= nil and WO.Models.Catalog ~= nil, "каталог моделей Mailer на месте")
MOCK.Assert(WO.Plugins.IsLoaded("workshop") and WO.Workshop.ModelOr ~= nil,
    "Workshop adapter загружен отдельным плагином")
MOCK.Assert(WO.NPCs.Get("black_wolf").entityClass == nil and
    WO.NPCs.Get("black_wolf").workshopClass == "wow_npc_14892" and
    WO.NPCs.Get("black_wolf").model == nil and
    WO.NPCs.Get("black_wolf").maxLevel == 4 and
    WO.NPCs.Get("elwynn_boar").workshopClass == "wow_npc_2809" and
    WO.NPCs.Get("elwynn_boar").maxLevel == 4,
    "wolf and boar use their exact external Workshop NPC classes without fallback")
MOCK.Assert(WO.Workshop.HasNPCClass("wow_npc_14892") and
    WO.Workshop.HasNPCClass("wow_npc_2809") and
    WO.Workshop.HasNPCClass("wow_npc_8883"),
    "runtime registry requires exact wolf, boar, and horse classes")
MOCK.Assert(WO.NPCs.Get("hunter_dyrne").model ==
    "models/mailer/wow_characters/wowanim_worgen_male.mdl" and
    WO.NPCs.Get("marshal_dughal").model ==
    "models/mailer/wow_characters/wowanim_skyhunterNL.mdl" and
    WO.NPCs.Get("trader_marla").model ==
    "models/mailer/wow_characters/wowanim_gnome_male.mdl" and
    WO.NPCs.Get("mount_merchant").model ==
    "models/mailer/wow_characters/wowanim_c_stoneconstruct.mdl",
    "все NPC используют точные заданные пользователем WoW-модели")
MOCK.Assert(WO.Spells and table.Count(WO.Spells.GetAll()) == 7 and
    WO.Spells.WeaponClass == "wo_magic_grimoire" and
    WO.Config.Mounts.horseClass == "wow_npc_8883" and
    WO.Items.Get("mount_stone").uniquePerCharacter == true,
    "зарегистрированы семь spells и защищённый exact-class mount stone")
do
local spellElementEffects = {
    firebolt = { element = "fire", effect = "Explosion" },
    water_bolt = { element = "water", effect = "WaterSurfaceExplosion" },
    air_burst = { element = "air", effect = "cball_bounce" },
    earth_shard = { element = "earth", effect = "ThumperDust" },
    frost_lance = { element = "frost", effect = "GlassImpact" },
    lightning_strike = { element = "lightning", effect = "TeslaHitBoxes" },
    healing_wave = { element = "life", effect = "VortDispel" },
}
local allSpellEffectsMatch = true
for spellID, expected in pairs(spellElementEffects) do
    local spell = WO.Spells.Get(spellID)
    local effect = spell and WO.Config.SpellEffects[spell.elementType]
    allSpellEffectsMatch = allSpellEffectsMatch and spell ~= nil and
        spell.elementType == expected.element and istable(effect) and
        isstring(effect.castSound) and isstring(effect.impactSound) and
        effect.effect == expected.effect and tonumber(effect.effectScale) ~= nil
end
local scrollVendor = WO.NPCs.Get("malygos_scroll_vendor")
local requiredAddonsExcludeCharacterPack = true
for _, addon in ipairs(WO.Workshop.RequiredAddons or {}) do
    if addon.id == 3796529373 then requiredAddonsExcludeCharacterPack = false end
end
MOCK.Assert(allSpellEffectsMatch and scrollVendor and
    scrollVendor.model == "models/mailer/wow_characters/wowanim_malygos.mdl" and
    #scrollVendor.vendor.stock == 35 and #scrollVendor.vendor.buybackClasses == 35 and
    requiredAddonsExcludeCharacterPack and
    WO.Items.Get(WO.Spells.GetScrollClass("firebolt", 1)) and
    WO.Items.Get(WO.Spells.GetScrollClass("firebolt", 5)),
    "зарегистрированы элементальные эффекты, 35 уровней свитков и Малигос без workshop-зависимости моделей персонажей")

local starterKnifeDef = WO.Items.Get("starter_knife")
local arcaneHandsDef = WO.Items.Get("arcane_hands")
local desiredWeapons = WO.Config.StartingWeaponClasses
local mageDesired = WO.Loadout.GetDesiredClasses({ class = "mage" })
local warriorDesired = WO.Loadout.GetDesiredClasses({ class = "warrior" })
local grimoireClassesAreConfigured = true
for _, classID in ipairs({ "mage", "priest", "druid", "shaman", "warlock", "evoker" }) do
    local desired = WO.Loadout.GetDesiredClasses({ class = classID })
    grimoireClassesAreConfigured = grimoireClassesAreConfigured and
        #desired == 2 and desired[1] == "drc_unarmed" and desired[2] == "wo_magic_grimoire"
end
local mageStartingItems = WO.Classes.GetStartingItems("mage")
local mageHasKnifeItem = false
for _, entry in ipairs(mageStartingItems) do
    if entry.class == "starter_knife" then mageHasKnifeItem = true end
end
MOCK.Assert(starterKnifeDef and starterKnifeDef.allowStarterKnifeItem == true and
    starterKnifeDef.weapon.class == "tfa_cso_coldsteelblade" and
    starterKnifeDef.equipment.slot == "main_hand" and
    arcaneHandsDef and arcaneHandsDef.noInventory == true and
    WO.Items.IsInventoryAllowed("starter_knife") and
    not WO.Items.IsInventoryAllowed({ weapon = { class = "tfa_cso_coldsteelblade" } }) and
    not WO.Items.IsInventoryAllowed("arcane_hands"),
    "только явный starter_knife является предметом; магическая книга остаётся loadout-only")
MOCK.Assert(desiredWeapons.hands == "drc_unarmed" and
    desiredWeapons.knife == "tfa_cso_coldsteelblade" and
    desiredWeapons.mage == "wo_magic_grimoire" and
    desiredWeapons.mageLegacy == nil and
    WO.Workshop.RequestedSWEPs.legacyMageStick == nil and
    weapons.GetStored("drc_unarmed") and
    weapons.GetStored("tfa_cso_coldsteelblade") and
    weapons.GetStored("wo_magic_grimoire") and
    weapons.GetStored("weapon_hpwr_stick"),
    "магический loadout запрашивает только wo_magic_grimoire; старый класс нужен лишь для миграционной проверки")
local anyClassStartsWithKnife = false
for _, classId in ipairs(WO.Classes.GetIDs()) do
    for _, entry in ipairs(WO.Classes.GetStartingItems(classId)) do
        if entry.class == "starter_knife" then anyClassStartsWithKnife = true end
    end
end
MOCK.Assert(grimoireClassesAreConfigured and
    #mageDesired == 2 and mageDesired[1] == "drc_unarmed" and
    mageDesired[2] == "wo_magic_grimoire" and
    #warriorDesired == 1 and warriorDesired[1] == "drc_unarmed" and
    not mageHasKnifeItem and not anyClassStartsWithKnife and
    WO.Classes.IsWeaponAllowed("mage", "dagger") and
    starterKnifeDef.uniquePerCharacter == true and
    WO.Equipment.MigrateStarterKnife == nil,
    "нож не входит в стартовые наборы/миграции и будет выдаваться только квестом")

local badLoadedCharacter, badModelWarnings = WO.Character.SanitizeLoaded({
    id = "bad-model-test", name = "Тест", surname = "Модели", age = 25,
    race = "human", gender = "male", class = "warrior",
    model = "models/player/group01/male_01.mdl", customization = {},
})
MOCK.Assert(badLoadedCharacter == nil and table.HasValue(badModelWarnings, "model_unavailable"),
    "сохранённая гражданская модель отклоняется без fallback")

local explicitHumanModel = "models/mailer/character/human/male/humanmale00_00.mdl"
MOCK.mountedFiles[explicitHumanModel] = nil
local createAllowedWithoutFile, createValidated = WO.Character.Validate({
    name = "Тест", surname = "Модели", age = 25,
    race = "human", gender = "male", class = "warrior",
    model = explicitHumanModel, customization = {},
}, { strict = true })
MOCK.Assert(createAllowedWithoutFile and createValidated.model == explicitHumanModel,
    "создание разрешает точный race model path без file.Exists")
local validUnmountedCharacter, unmountedWarnings = WO.Character.SanitizeLoaded({
    id = "valid-unmounted-model", name = "Тест", surname = "Модели", age = 25,
    race = "human", gender = "male", class = "warrior",
    model = explicitHumanModel, customization = {},
})
MOCK.Assert(validUnmountedCharacter ~= nil and
    not table.HasValue(unmountedWarnings, "model_unavailable"),
    "сохранённый allowlisted путь не блокируется локальным file.Exists")
local directModelPlayer = MOCK.NewEntity("player")
directModelPlayer:SetCharacter(WO.Character.New(validUnmountedCharacter or {}))
MOCK.Assert(validUnmountedCharacter ~= nil and
    WO.Character.ApplyToPlayer(directModelPlayer) == true and
    directModelPlayer:GetModel() == explicitHumanModel,
    "сервер применяет точный race model path без обнаружения наличия и citizen fallback")
MOCK.mountedFiles[explicitHumanModel] = true

local invalidModelPlayer = MOCK.NewEntity("player")
invalidModelPlayer:SetCharacter(WO.Character.New({
    id = "invalid-model-player", race = "human", gender = "male",
    model = "models/player/group01/male_01.mdl",
}))
local modelBeforeReject = invalidModelPlayer:GetModel()
MOCK.Assert(WO.Character.ApplyToPlayer(invalidModelPlayer) == false and
    invalidModelPlayer:GetModel() == modelBeforeReject and
    invalidModelPlayer:GetNW2Bool("wo_char_active", true) == false,
    "ApplyToPlayer не выдаёт гражданскую модель при ошибке/отсутствии race model")

-- Проверяем приоритет SAM над встроенными GMod-флагами администратора.
local previousSAM = rawget(_G, "sam")
local registeredSAMPermissions = {}
sam = {
    permissions = {
        add = function(name, _, defaultGroup)
            registeredSAMPermissions[name] = defaultGroup
        end,
    },
}
WO.Admin.RegisteredSAMPermissions = nil
MOCK.Assert(WO.Admin.RegisterSAMPermissions(), "SAM права регистрируются")
MOCK.Assert(table.Count(registeredSAMPermissions) == 7 and
    registeredSAMPermissions.wo_debug == "admin", "в SAM добавлены семь WO permissions")

local permissionPly = MOCK.NewEntity("player")
permissionPly.__admin = true
permissionPly.__samPermissions = {}
permissionPly.HasPermission = function(self, permission)
    return self.__samPermissions[permission] == true
end
MOCK.Assert(not WO.Admin.IsAdmin(permissionPly),
    "SAM deny не обходится встроенным Player:IsAdmin")
permissionPly.__samPermissions.wo_item_give = true
MOCK.Assert(WO.Admin.Can(permissionPly, "item.give") and
    not WO.Admin.Can(permissionPly, "money.give") and
    not WO.Admin.Can(permissionPly, "unknown.permission"),
    "SAM проверяет индивидуальные разрешения и fail-closed unknown права")
MOCK.TakeOutbox()
WO.Admin.SendMenuData(permissionPly)
local adminMenuOutbox = MOCK.TakeOutbox()
local adminMenuMessages = MOCK.FindInbox(adminMenuOutbox, "Admin.MenuData")
local adminMenuData = adminMenuMessages[1] and adminMenuMessages[1].args[1]
MOCK.Assert(adminMenuData and adminMenuData.isAdmin == true and
    #adminMenuData.commands == 2 and
    adminMenuData.commands[1].permission == "item.give" and
    adminMenuData.commands[2].permission == "item.give",
    "админ-меню отправляет только каталог команд, разрешённых SAM-правом игрока")

local deniedAdminPly = MOCK.NewEntity("player")
deniedAdminPly.__samPermissions = {}
local debugBeforeDeniedAction = WO.Config.Debug
MOCK.NetDeliver({ name = "Admin.CommandRun", args = { "wo_debug", 0 } }, 8, deniedAdminPly)
MOCK.RunCommand("wo_debug", deniedAdminPly, {})
MOCK.Assert(WO.Config.Debug == debugBeforeDeniedAction,
    "неавторизованный игрок не запускает admin net action или исходный concommand")
MOCK.TakeOutbox()
WO.Admin.SendMenuData(deniedAdminPly)
local deniedMenuMessages = MOCK.FindInbox(MOCK.TakeOutbox(), "Admin.MenuData")
local deniedMenuData = deniedMenuMessages[1] and deniedMenuMessages[1].args[1]
MOCK.Assert(deniedMenuData and deniedMenuData.isAdmin == false and
    #deniedMenuData.commands == 0,
    "сервер не отдаёт неавторизованному игроку админ-каталог")
permissionPly.__samPermissions.wo_debug = true
MOCK.NetDeliver({ name = "Admin.CommandRun", args = { "wo_debug", 0 } }, 8, permissionPly)
MOCK.Assert(WO.Config.Debug ~= debugBeforeDeniedAction,
    "разрешённый admin net action проходит серверную проверку и выполняется")
WO.Config.Debug = debugBeforeDeniedAction
permissionPly.__samPermissions.wo_debug = nil

sam = previousSAM
WO.Admin.RegisteredSAMPermissions = nil
WO.Admin.SAMReady = nil

print("[scenario] load OK: plugins=" .. table.Count(WO.Plugins.GetAll()) ..
    " races=" .. #WO.Races.GetIDs() .. " items=" .. table.Count(WO.Items.GetAll()))
end

---------------------------------------------------------------------------
-- 2. Вход игрока (лимбо + меню)
---------------------------------------------------------------------------

local ply = MOCK.CreatePlayer("Тестер", "STEAM_0:0:42")

hook.Run("PlayerInitialSpawn", ply)
hook.Run("PlayerLoadout", ply)
hook.Run("PlayerSpawn", ply)

MOCK.RunTimers(3.5)

local outbox = MOCK.TakeOutbox()

MOCK.Assert(#MOCK.FindInbox(outbox, "Character.List") >= 1, "Character.List отправлен")
MOCK.Assert(#MOCK.FindInbox(outbox, "Character.OpenMenu") >= 1, "Character.OpenMenu отправлен")

print("[scenario] join OK: главное меню доставлено")

---------------------------------------------------------------------------
-- 3. Хендшейк Client.Ready
---------------------------------------------------------------------------

MOCK.NetDeliver({ name = "Client.Ready", args = {} }, 8, ply)
MOCK.RunTimers(0.1)

outbox = MOCK.TakeOutbox()
MOCK.Assert(#MOCK.FindInbox(outbox, "Character.OpenMenu") >= 1, "SendState по Client.Ready")

print("[scenario] handshake OK")

---------------------------------------------------------------------------
-- 4. Создание персонажа (через net-слой, как это делает клиент)
---------------------------------------------------------------------------

local models = WO.Races.GetModels("human", "male")

MOCK.Assert(#models > 0, "у расы human/male есть модели")

local createData = {
    name = "Тест",
    surname = "Герой",
    age = 25,
    gender = "male",
    race = "human",
    class = "warrior",
    model = models[1],
    customization = { skin = 0, bodygroups = {}, color = nil },
}

local mockedLocalPlayer = LocalPlayer
LocalPlayer = nil -- На dedicated server LocalPlayer() не существует.
MOCK.NetDeliver({ name = "Character.Create", args = { createData } }, 8, ply)
LocalPlayer = mockedLocalPlayer
-- Повторный клик до автоматического выбора не должен создать второй персонаж.
MOCK.NetDeliver({ name = "Character.Create", args = { createData } }, 8, ply)
MOCK.RunTimers(1)

local char = ply:GetCharacter()

MOCK.Assert(char ~= nil, "персонаж создан и выбран")
MOCK.Assert(char.name == "Тест", "имя сохранено: " .. tostring(char.name))
MOCK.Assert(char.race == "human" and char.class == "warrior", "раса/класс сохранены")
MOCK.Assert(char.model == models[1], "модель сохранена")
MOCK.Assert(ply:HasCharacter(), "HasCharacter() == true")
MOCK.Assert(ply:GetPos():DistToSqr(Vector(0, 0, 24)) == 0 and
    char.map == game.GetMap() and isvector(char.pos),
    "новый персонаж использует обычную map spawn point вместо нулевой координаты")
MOCK.Assert(ply:GetStamina() > 0,
    "персонаж входит в мир с полной выносливостью для стартового оружия")
MOCK.Assert(#WO.Character.LoadList(ply) == 1, "повторный net-запрос не создал дубликат")

local function MakeSlotTestPlayer(steamid, isAdmin)
    local testPlayer = MOCK.NewEntity("player")
    testPlayer.__steamid = steamid
    testPlayer.__steamid64 = steamid .. "64"
    testPlayer.__admin = isAdmin == true
    testPlayer.__nick = isAdmin and "Администратор слотов" or "Игрок слотов"
    return testPlayer
end

local slotData = table.Copy(createData)
local ordinarySlotPlayer = MakeSlotTestPlayer("STEAM_0:1:10001", false)
local regularSlotResults = {}
local originalUUID = WO.Util.UUID
local injectDuplicateID = true
WO.Util.UUID = function()
    if injectDuplicateID then
        injectDuplicateID = false
        return char.id -- deliberately collide with an existing row on the first attempt
    end

    return originalUUID()
end
local regularFirstOK, regularFirstResult = WO.Character.Create(ordinarySlotPlayer, slotData)
WO.Util.UUID = originalUUID
regularSlotResults[#regularSlotResults + 1] = { ok = regularFirstOK, result = regularFirstResult }
for _ = 1, 2 do
    local ok, result = WO.Character.Create(ordinarySlotPlayer, slotData)
    regularSlotResults[#regularSlotResults + 1] = { ok = ok, result = result }
end
local slotAdminPlayer = MakeSlotTestPlayer("STEAM_0:1:10002", true)
local adminSlotResults = {}
for _ = 1, 6 do
    local ok, result = WO.Character.Create(slotAdminPlayer, slotData)
    adminSlotResults[#adminSlotResults + 1] = { ok = ok, result = result }
end
MOCK.Assert(not injectDuplicateID and regularSlotResults[1].ok and
    regularSlotResults[1].result.id ~= char.id and regularSlotResults[2].ok and
    regularSlotResults[3].ok == false and regularSlotResults[3].result == "character_limit" and
    adminSlotResults[1].ok and adminSlotResults[2].ok and adminSlotResults[3].ok and
    adminSlotResults[4].ok and adminSlotResults[5].ok and
    adminSlotResults[6].ok == false and adminSlotResults[6].result == "character_limit",
    "Character.Create повторяет создание при конфликте ID и соблюдает пределы 2/5")

do
local characterListDefinition = WO.Net.Messages["Character.List"]
local function DecodeCharacterListPacket(args)
    local previousRead = MOCK.currentRead
    MOCK.currentRead = { args = args, pos = 0 }
    local decoded = characterListDefinition.read()
    MOCK.currentRead = previousRead
    return decoded
end

local function RoundTripCharacterList(list)
    net.Start("Character.List")
    characterListDefinition.write(list)
    local packet = MOCK.currentWrite
    MOCK.currentWrite = nil
    return DecodeCharacterListPacket(packet.args), packet.args
end

local savedSlotCharacters = WO.Character.LoadList(ordinarySlotPlayer)
local decodedSlotCharacters = RoundTripCharacterList(savedSlotCharacters)
MOCK.Assert(#savedSlotCharacters == 2 and #decodedSlotCharacters == 2 and
    decodedSlotCharacters[1].id == savedSlotCharacters[1].id and
    decodedSlotCharacters[2].id == savedSlotCharacters[2].id and
    WO.Util.IsUUID(decodedSlotCharacters[2].id) and
    decodedSlotCharacters[2].experience == savedSlotCharacters[2].experience and
    decodedSlotCharacters[2].needed == savedSlotCharacters[2].needed,
    "Character.List передаёт все поля: второй ID не сдвигается и XP карточки сохраняется")

local firstSlotID = savedSlotCharacters[1].id
local secondSlotID = savedSlotCharacters[2].id
MOCK.NetDeliver({ name = "Character.Select", args = { firstSlotID } }, 8, ordinarySlotPlayer)
MOCK.Assert(ordinarySlotPlayer:HasCharacter() and
    ordinarySlotPlayer:GetCharacter().id == firstSlotID,
    "первый сохранённый персонаж выбирается через net")

local firstSwitchCharacter = ordinarySlotPlayer:GetCharacter()
firstSwitchCharacter.experience = 321
firstSwitchCharacter.money = 4321
WO.SaveQueue.MarkDirty(firstSwitchCharacter)
MOCK.TakeOutbox()
MOCK.NetDeliver({ name = "Character.Logout", args = {} }, 8, ordinarySlotPlayer)
local logoutOutbox = MOCK.TakeOutbox()
local logoutListMessages = MOCK.FindInbox(logoutOutbox, "Character.List")
local logoutList = logoutListMessages[1] and DecodeCharacterListPacket(logoutListMessages[1].args)
local savedFirstSlotRow = WO.Database:Fetch(
    "SELECT experience, money FROM wo_characters WHERE id = ?", firstSlotID)[1]
MOCK.Assert(not ordinarySlotPlayer:HasCharacter() and #logoutListMessages == 1 and
    logoutList and #logoutList == 2 and logoutList[2].id == secondSlotID and
    #MOCK.FindInbox(logoutOutbox, "Character.OpenMenu") == 1 and
    tonumber(savedFirstSlotRow.experience) == 321 and tonumber(savedFirstSlotRow.money) == 4321,
    "выход в главное меню сохраняет персонажа и возвращает оба корректных ID")

MOCK.NetDeliver({ name = "Character.Select", args = { secondSlotID } }, 8, ordinarySlotPlayer)
MOCK.Assert(ordinarySlotPlayer:HasCharacter() and
    ordinarySlotPlayer:GetCharacter().id == secondSlotID,
    "после выхода можно выбрать второго персонажа")
MOCK.TakeOutbox()
MOCK.NetDeliver({ name = "Character.Logout", args = {} }, 8, ordinarySlotPlayer)
MOCK.TakeOutbox()
MOCK.NetDeliver({ name = "Character.Select", args = { firstSlotID } }, 8, ordinarySlotPlayer)
MOCK.Assert(ordinarySlotPlayer:HasCharacter() and
    ordinarySlotPlayer:GetCharacter().id == firstSlotID and
    ordinarySlotPlayer:GetCharacter().experience == 321 and
    ordinarySlotPlayer:GetCharacter().money == 4321,
    "при возврате к первому персонажу сохранённые опыт и деньги восстановлены")
end

print("[scenario] create, character list wire format and switching OK: " ..
    char:GetFullName() .. " lvl " .. char:GetLevel())

-- Повторный вход: сервер должен открыть список сохранённых персонажей, а не создать дубликат.
local savedCharID = char.id

MOCK.TakeOutbox()
WO.Character.Unload(ply)
WO.Character.SendState(ply)
outbox = MOCK.TakeOutbox()

MOCK.Assert(#MOCK.FindInbox(outbox, "Character.List") >= 1,
    "при повторном входе сервер отправляет список персонажей")
MOCK.Assert(#MOCK.FindInbox(outbox, "Character.OpenMenu") >= 1,
    "при повторном входе сервер открывает главное меню персонажей")
MOCK.Assert(WO.Character.Select(ply, savedCharID), "загрузка сохранённого персонажа")
char = ply:GetCharacter()
MOCK.Assert(char and char.id == savedCharID, "загружен тот же персонаж без дубликата")
MOCK.Assert(WO.Equipment.Get(char).startingEquipmentApplied == true and
    WO.Equipment.Get(char):Get("main_hand") == nil and
    WO.Inventory.GetContainer(char):CountItem("starter_knife") == 0,
    "новый персонаж выбирается без ножа до принятия охоты у охотника")

print("[scenario] existing character selection OK")

---------------------------------------------------------------------------
-- 5. Стартовые предметы, инвентарь, валюта
---------------------------------------------------------------------------

local inv = WO.Inventory.GetContainer(char)

MOCK.Assert(inv ~= nil, "контейнер инвентаря существует")

-- Auto-collect is opt-in, and the server decides whether the authoritative item
-- instance is a coin pile, high-rarity/value item, or needed by an active quest.
local autoCollectPlayer = MOCK.NewEntity("player")
local autoCollectCharacter = WO.Character.New({
    id = "autocollect-test-character", name = "Сборщик", surname = "Тест",
    race = "human", gender = "male", class = "warrior", level = 1,
    quests = { supplies_for_the_road = { status = "active", progress = {} } },
})
autoCollectPlayer:SetCharacter(autoCollectCharacter)
MOCK.Assert(not WO.Settings.IsAutoCollectEnabled(autoCollectPlayer) and
    WO.World.IsAutoCollectEligible(autoCollectPlayer, "bread") and
    WO.World.IsAutoCollectEligible(autoCollectPlayer, "gold_ring") and
    not WO.World.IsAutoCollectEligible(autoCollectPlayer, "boar_meat"),
    "автосбор выключен по умолчанию и выбирает квестовые/редкие/ценные предметы")
local autoCollectItem = ents.Create("wo_item_world")
autoCollectItem:SetPos(autoCollectPlayer:GetPos())
local autoCollectInstance = WO.Items.CreateInstance("bread", 1)
MOCK.Assert(autoCollectItem:SetItem(autoCollectInstance) and
    WO.Items.SetState(autoCollectInstance, WO.Items.State.WORLD),
    "тестовый world item хранит серверный экземпляр")
MOCK.AdvanceTime(1.1)
MOCK.NetDeliver({ name = "Settings.AutoCollectSet", args = { true } }, 8, autoCollectPlayer)
MOCK.Assert(WO.Settings.IsAutoCollectEnabled(autoCollectPlayer) and
    autoCollectPlayer.__pdata.wo_auto_collect_important == "1",
    "включённый opt-in хранится сервером и может быть восстановлен из PData")
autoCollectPlayer.WOAutoCollectImportant = nil
MOCK.Assert(WO.Settings.IsAutoCollectEnabled(autoCollectPlayer),
    "сервер повторно загружает сохранённое состояние автосбора из PData")
local autoCollected, autoCollectReason = WO.World.TryAutoCollect(autoCollectPlayer, autoCollectItem)
MOCK.Assert(autoCollected == true and not IsValid(autoCollectItem) and
    WO.Inventory.GetContainer(autoCollectCharacter):CountItem("bread") == 1,
    "включённый автосбор подбирает только серверный предмет, нужный активному квесту: " ..
        tostring(autoCollectReason))
MOCK.NetDeliver({ name = "Settings.AutoCollectSet", args = { false } }, 8, autoCollectPlayer)
MOCK.Assert(not WO.Settings.IsAutoCollectEnabled(autoCollectPlayer) and
    autoCollectPlayer.__pdata.wo_auto_collect_important == "0",
    "выключение автосбора серверно сохраняется как opt-in preference")

-- A stale serialized/cached bitmap must not make a mostly empty 10x6 bag look full.
inv.grid = {}
for y = 1, inv.height do
    inv.grid[y] = {}
    for x = 1, inv.width do inv.grid[y][x] = "stale-grid-cell" end
end
local repairedGive = WO.Inventory.GiveItem(ply, "iron_sword", 1)
local repairedUID
for uid, instance in pairs(inv:GetItems()) do
    if instance.class == "iron_sword" then repairedUID = uid break end
end
local repairedGrid = repairedGive == true and repairedUID ~= nil and
    WO.Inventory.RemoveItem(ply, repairedUID, 1) == true
MOCK.Assert(repairedGrid and inv:CountItem("iron_sword") == 0,
    "покупка/выдача автоматически перестраивает испорченную grid-сетку")

local itemCount = 0

for _ in pairs(inv.items or {}) do
    itemCount = itemCount + 1
end

MOCK.Assert(itemCount > 0, "стартовые предметы выданы: " .. itemCount)

local mainHand = WO.Equipment.Get(char):Get("main_hand")
local equippedHands = ply:GetWeapon("drc_unarmed")
MOCK.Assert(mainHand == nil and inv:CountItem("starter_knife") == 0 and
    not IsValid(ply:GetWeapon("tfa_cso_coldsteelblade")) and
    IsValid(equippedHands) and equippedHands.WOStarterLoadout == true and
    ply:GetActiveWeapon() == equippedHands,
    "воин появляется с руками; нож не выдаётся до принятия охотничьего задания")

local magePlayer = MOCK.NewEntity("player")
local mageCharacter = WO.Character.New({ id = "mage-loadout-test", class = "mage" })
magePlayer:SetCharacter(mageCharacter)
-- Simulate a previous version's free wand without relying on its starter marker.
magePlayer:Give("weapon_hpwr_stick")
local magePrimary = WO.Loadout.Apply(magePlayer, mageCharacter)

MOCK.Assert(magePrimary == "wo_magic_grimoire" and
    magePlayer:HasWeapon("drc_unarmed") and
    not magePlayer:HasWeapon("tfa_cso_coldsteelblade") and
    magePlayer:HasWeapon("wo_magic_grimoire") and
    not magePlayer:HasWeapon("weapon_hpwr_stick") and
    magePlayer:GetWeapon("wo_magic_grimoire").WOItemUID == nil,
    "маг получает только grimoire, старый Warp Magic wand удаляется при обновлении")

do
local function AddSpellScroll(ply, spellId, targetRank)
    local class = WO.Spells.GetScrollClass(spellId, targetRank)
    if WO.Inventory.GiveItem(ply, class, 1) == false then return nil, class end

    local container = WO.Inventory.GetContainer(ply:GetCharacter())

    for uid, instance in pairs(container:GetItems()) do
        if instance.class == class then return uid, class end
    end

    return nil, class
end

MOCK.Assert(WO.Spells.PointsAvailable(mageCharacter) == 1 and
    WO.Spells.GetRank(mageCharacter, "healing_wave") == 0 and
    WO.Spells.CanCast(magePlayer, "healing_wave") == false,
    "заклинание недоступно без соответствующего свитка в серверном инвентаре")
local learningUID, learningClass = AddSpellScroll(magePlayer, "healing_wave", 1)
local canCastHealing = WO.Spells.CanCast(magePlayer, "healing_wave")
MOCK.Assert(learningUID and WO.Spells.GetRank(mageCharacter, "healing_wave") == 1 and
    WO.Inventory.GetContainer(mageCharacter):CountItem(learningClass) == 1 and
    canCastHealing == true and WO.Spells.Select(magePlayer, "healing_wave") == true,
    "свиток изучения автоматически открывает магию, остаётся в инвентаре и даёт каст")
local fireboltUID, fireboltClass = AddSpellScroll(magePlayer, "firebolt", 1)
MOCK.Assert(fireboltUID and WO.Spells.GetRank(mageCharacter, "firebolt") == 1 and
    WO.Inventory.GetContainer(mageCharacter):CountItem(fireboltClass) == 1,
    "наличие свитка изучения синхронно открывает второе заклинание без его использования")
MOCK.TakeOutbox()
MOCK.NetDeliver({ name = "Spell.Learn", args = { "air_burst" } }, 8, magePlayer)
MOCK.Assert(WO.Spells.GetRank(mageCharacter, "air_burst") == 0,
    "legacy Spell.Learn packet не позволяет получить ранг без свитка")
MOCK.TakeOutbox()
WO.Spells.Sync(magePlayer)
local spellSyncOutbox = MOCK.TakeOutbox()
local spellPayloads = MOCK.FindInbox(spellSyncOutbox, "Spell.Sync")
MOCK.Assert(#spellPayloads == 1 and spellPayloads[1].args[1].ranks.healing_wave == 1 and
    spellPayloads[1].args[1].ranks.firebolt == 1 and
    spellPayloads[1].args[1].selected == "healing_wave" and
    spellPayloads[1].args[1].points == 0,
    "spellbook передаёт ранги из инвентарных свитков собственным payload")
WO.Hook.Run("CharacterSave", mageCharacter)
local savedAbilityRows = WO.Database:Fetch(
    "SELECT data FROM wo_abilities WHERE owner_id = ? AND ability_id = ?",
    mageCharacter.id, "spellbook")
local savedBook = savedAbilityRows[1] and util.JSONToTable(savedAbilityRows[1].data or "")
local reloadedMage = WO.Character.New({ id = mageCharacter.id, class = "mage", level = 1 })
WO.Hook.Run("CharacterLoad", reloadedMage)
local reloadedInventory = WO.Inventory.GetContainer(reloadedMage)
for _, scrollClass in ipairs({ learningClass, fireboltClass }) do
    local restoredScroll = WO.Items.CreateInstance(scrollClass, 1)
    reloadedInventory:AddItem(restoredScroll)
end
MOCK.Assert(savedBook and savedBook.ranks.healing_wave == 1 and savedBook.selected == "healing_wave" and
    WO.Spells.GetRank(reloadedMage, "healing_wave") == 1 and
    WO.Spells.GetRank(reloadedMage, "firebolt") == 1 and
    WO.Spells.GetSelected(reloadedMage) == "healing_wave",
    "после reload ранги берутся из восстановленных предметов, а выбор сохраняется")

local spellAlly = MOCK.NewEntity("player")
spellAlly:SetCharacter(WO.Character.New({ id = "spell-ally-test", class = "warrior" }))
spellAlly:SetHealth(30)
spellAlly:SetMaxHealth(100)
local healed, healedTarget, healAmount = WO.Spells.Apply(magePlayer, "healing_wave", spellAlly)
MOCK.Assert(healed == true and healedTarget == spellAlly and healAmount > 0 and
    spellAlly:Health() > 30,
    "healing spell восстанавливает здоровье союзника в радиусе")
magePlayer:SetHealth(30)
spellAlly:SetPos(Vector(5000, 0, 0))
local selfHealed, selfTarget = WO.Spells.Apply(magePlayer, "healing_wave", spellAlly)
MOCK.Assert(selfHealed == true and selfTarget == magePlayer and magePlayer:Health() > 30,
    "healing spell безопасно перенаправляется на владельца за пределами радиуса")
local rankTwoScrollUID, rankTwoScrollClass = AddSpellScroll(magePlayer, "firebolt", 2)
MOCK.Assert(rankTwoScrollUID and WO.Spells.GetRank(mageCharacter, "firebolt") == 2 and
    WO.Inventory.GetContainer(mageCharacter):CountItem(rankTwoScrollClass) == 1,
    "свиток ранга два сразу повышает магию в инвентаре без использования, траты или level gate")
local rankThreeScrollUID, rankThreeScrollClass = AddSpellScroll(magePlayer, "firebolt", 3)
MOCK.Assert(rankThreeScrollUID and WO.Spells.GetRank(mageCharacter, "firebolt") == 3 and
    WO.Inventory.GetContainer(mageCharacter):CountItem(rankThreeScrollClass) == 1,
    "свиток ранга три автоматически задаёт ранг без использования или требования уровня")
MOCK.Assert(WO.Inventory.RemoveItem(magePlayer, rankThreeScrollUID, 1) == true and
    WO.Spells.GetRank(mageCharacter, "firebolt") == 2,
    "удаление старшего свитка пересчитывает ранг по оставшемуся инвентарю")
MOCK.Assert(WO.Inventory.DropItem(magePlayer, rankTwoScrollUID, 1) == true and
    WO.Spells.GetRank(mageCharacter, "firebolt") == 1,
    "сброс свитка немедленно отзывает его ранг из серверной книги")
local droppedRankTwo
for _, ent in ipairs(ents.GetAll()) do
    if ent:GetClass() == "wo_item_world" and ent.ItemInstance and
        ent.ItemInstance.uid == rankTwoScrollUID then
        droppedRankTwo = ent
        break
    end
end
MOCK.Assert(IsValid(droppedRankTwo), "свиток улучшения создаёт физический предмет мира")
if IsValid(droppedRankTwo) then
    magePlayer:SetPos(droppedRankTwo:GetPos())
    droppedRankTwo.PickupCooldown = 0
    droppedRankTwo:Use(magePlayer, magePlayer)
end
MOCK.Assert(not IsValid(droppedRankTwo) and WO.Spells.GetRank(mageCharacter, "firebolt") == 2,
    "подбор выпавшего свитка синхронизирует его ранг без использования предмета")
MOCK.Assert(WO.Inventory.RemoveItem(magePlayer, learningUID, 1) == true and
    WO.Spells.GetRank(mageCharacter, "healing_wave") == 0 and
    WO.Spells.CanCast(magePlayer, "healing_wave") == false,
    "сервер отзывает доступ к магии после ухода соответствующего свитка из инвентаря")
end
local spellEnemy = MOCK.NewEntity("npc")
spellEnemy:SetHealth(200)
spellEnemy:SetMaxHealth(200)
local damaged = WO.Spells.Apply(magePlayer, "firebolt", spellEnemy)
MOCK.Assert(damaged == true and spellEnemy:Health() < 200,
    "стихийный damage spell проходит через серверный Combat pipeline")
local grimoireSWEP = weapons.GetStored("wo_magic_grimoire")
local originalSpellTrace = util.TraceLine
WO.Spells.Select(magePlayer, "firebolt")
magePlayer:SetNW2Int("wo_mana", 100)
spellEnemy:SetHealth(200)
util.TraceLine = function(trace)
    return { Entity = spellEnemy, HitPos = spellEnemy:GetPos(), Hit = true }
end
local spellWeaponInstance = setmetatable({
    GetOwner = function() return magePlayer end,
    SetNextPrimaryFire = function() end,
    _woNextSpellCast = nil,
}, { __index = grimoireSWEP })
grimoireSWEP.PrimaryAttack(spellWeaponInstance)
util.TraceLine = originalSpellTrace
MOCK.Assert(spellEnemy:Health() < 200 and magePlayer:GetMana() < 100,
    "ЛКМ нового magic SWEP применяет выбранное заклинание и расходует ману сервером")

local money = WO.Currency.Get(ply)

MOCK.Assert(money == (WO.Config.StartingMoney or 0), "стартовые деньги: " .. tostring(money))

MOCK.Assert(WO.Inventory.GiveItem(ply, "health_potion", 2) ~= false, "выдача предмета")
MOCK.Assert(WO.Currency.Add(ply, 100) ~= false, "начисление денег")
MOCK.Assert(WO.Currency.Get(ply) == money + 100, "баланс после начисления")
MOCK.Assert(WO.Currency.Take(ply, 50) ~= false, "списание денег")
MOCK.Assert(WO.Currency.CanAfford(ply, 1000) == false, "нельзя потратить больше, чем есть")

print("[scenario] inventory/currency OK: items=" .. itemCount .. " money=" .. WO.Currency.Get(ply))

---------------------------------------------------------------------------
-- 6. Опыт и уровень
---------------------------------------------------------------------------

local targetXP = (WO.Leveling.GetXPForLevel and WO.Leveling.GetXPForLevel(2)) or 200

WO.Leveling.AddXP(ply, targetXP + 10, "test")

MOCK.Assert(char:GetLevel() >= 2, "уровень повышен: " .. char:GetLevel())

print("[scenario] leveling OK: lvl " .. char:GetLevel() .. " xp " .. char:GetXP())

---------------------------------------------------------------------------
-- 7. Бой (damage pipeline)
---------------------------------------------------------------------------

local dummy = MOCK.CreatePlayer("Жертва", "STEAM_0:0:43")

hook.Run("PlayerInitialSpawn", dummy)
hook.Run("PlayerLoadout", dummy)
hook.Run("PlayerSpawn", dummy)
MOCK.RunTimers(3.5)

local dummyModels = WO.Races.GetModels("human", "male")

MOCK.NetDeliver({ name = "Character.Create", args = { {
    name = "Враг", surname = "Тестов", age = 30, gender = "male",
    race = "orc", class = "warrior",
    model = WO.Races.GetModels("orc", "male")[1],
    customization = { skin = 0, bodygroups = {} },
} } }, 8, dummy)
MOCK.RunTimers(1)

MOCK.Assert(dummy:HasCharacter(), "второй персонаж создан")

dummy:SetPos(ply:GetPos() + Vector(250, 0, 0))
WO.Social.Introduce(ply, "whisper")
local noWhisperMatch = WO.Database:Fetch(
    "SELECT known_id FROM wo_social_known WHERE owner_id = ?", char.id)
MOCK.Assert(#noWhisperMatch == 0,
    "радиус шёпота не раскрывает личность игрока за пределами выбранной дистанции")
MOCK.TakeOutbox()
WO.Social.Introduce(ply, "talk")
local speakerKnows = WO.Database:Fetch(
    "SELECT name FROM wo_social_known WHERE owner_id = ? AND known_id = ?",
    char.id, dummy:GetCharacter().id)
local dummyKnows = WO.Database:Fetch(
    "SELECT name FROM wo_social_known WHERE owner_id = ? AND known_id = ?",
    dummy:GetCharacter().id, char.id)
local socialMessages = MOCK.TakeOutbox()
MOCK.Assert(speakerKnows[1] and speakerKnows[1].name == dummy:GetCharacter():GetFullName() and
    dummyKnows[1] and dummyKnows[1].name == char:GetFullName() and
    #MOCK.FindInbox(socialMessages, "Social.Sync") >= 2,
    "в выбранном радиусе знакомство взаимно и сохраняется сервером")
local savedKnownLevel = dummy:GetCharacter().level or 1
dummy:GetCharacter().level = savedKnownLevel + 1
WO.Social.Introduce(ply, "talk")
local refreshedKnownRow = WO.Database:Fetch(
    "SELECT level FROM wo_social_known WHERE owner_id = ? AND known_id = ?",
    char.id, dummy:GetCharacter().id)
MOCK.Assert(refreshedKnownRow[1] and tonumber(refreshedKnownRow[1].level) == savedKnownLevel + 1,
    "повторное знакомство обновляет сохранённый уровень уже знакомого персонажа")
dummy:GetCharacter().level = savedKnownLevel

local hpBefore = dummy:Health()
local combatInfo = {
    amount = 15,
    type = WO.Enums.DamageType.PHYSICAL,
    canCrit = false,
}

MOCK.TakeOutbox()
WO.Combat.Damage(ply, dummy, combatInfo)
local damageOutbox = MOCK.TakeOutbox()
local damageMessages = MOCK.FindInbox(damageOutbox, "Combat.DamageNumber")
MOCK.Assert(combatInfo.critical == false,
    "canCrit=false отключает повторный critical roll в общем damage pipeline")
MOCK.Assert(#damageMessages == 2 and damageMessages[1].args[1].amount > 0 and
    isvector(damageMessages[1].args[1].position),
    "число урона по игроку отправляется атакующему и цели с world-позицией")

local npcDamageTarget = MOCK.NewEntity("npc")
npcDamageTarget:SetPos(Vector(12, 24, 32))
npcDamageTarget:SetNW2String("wo_npc_id", "black_wolf")
npcDamageTarget:SetHealth(180)
npcDamageTarget:SetMaxHealth(200)
npcDamageTarget.__methods.OBBMaxs = function() return Vector(20, 20, 96) end
MOCK.TakeOutbox()
WO.Combat.Damage(ply, npcDamageTarget, {
    amount = 27,
    type = WO.Enums.DamageType.PHYSICAL,
    canCrit = false,
})
local npcDamageMessages = MOCK.FindInbox(MOCK.TakeOutbox(), "Combat.DamageNumber")
MOCK.Assert(#npcDamageMessages == 1 and npcDamageMessages[1].args[1].amount == 27 and
    npcDamageMessages[1].args[1].position.z == 138,
    "урон по NPC отображается атакующему над моделью, с учётом высоты hitbox")

local externalDamage = {
    GetDamage = function() return 13 end,
    GetInflictor = function() return nil end,
    GetAttacker = function() return ply end,
}
MOCK.TakeOutbox()
hook.GetTable().PostEntityTakeDamage.wo_combat_engine_damage_feedback(
    npcDamageTarget, externalDamage, true)
local externalDamageMessages = MOCK.FindInbox(MOCK.TakeOutbox(), "Combat.DamageNumber")
MOCK.Assert(#externalDamageMessages == 1 and externalDamageMessages[1].args[1].amount == 13,
    "урон внешних Workshop SWEP по NPC тоже создаёт combat text без двойной отправки")

local damagedProp = MOCK.NewEntity("prop_physics")
MOCK.TakeOutbox()
hook.GetTable().PostEntityTakeDamage.wo_combat_engine_damage_feedback(
    damagedProp, externalDamage, true)
MOCK.Assert(#MOCK.FindInbox(MOCK.TakeOutbox(), "Combat.DamageNumber") == 0,
    "обычный физический prop не засоряет боевой HUD damage numbers")
print("[scenario] combat OK: pipeline executed (hp " .. tostring(hpBefore) .. ")")

---------------------------------------------------------------------------
-- 8. Сохранение / выгрузка / загрузка
---------------------------------------------------------------------------

local charId = char.id
local moneyBefore = WO.Currency.Get(ply)
local levelBefore = char:GetLevel()

-- Старая таблица того же ID не должна затереть свежий объект после reload.
local staleSnapshot = WO.Character.New({
    id = char.id, steamid = char.steamid, steamid64 = char.steamid64,
    name = char.name, surname = char.surname, age = char.age,
    gender = char.gender, race = char.race, class = char.class,
    model = char.model, level = 1, experience = 0, money = 0,
    map = char.map, pos = Vector(-1, -1, -1), ang = Angle(0, 0, 0),
    customization = char.customization, inventory = char.inventory,
    equipment = char.equipment, quests = char.quests,
})
WO.SaveQueue.MarkDirty(staleSnapshot)
MOCK.Assert(WO.SaveQueue.SaveNow(char) == true,
    "активная версия персонажа сохраняется поверх очередного старого snapshot")
WO.SaveQueue.FlushAll()
local afterStaleFlush = WO.Database:Fetch(
    "SELECT level, experience, money FROM wo_characters WHERE id = ?", char.id)[1]
MOCK.Assert(tonumber(afterStaleFlush.level) == levelBefore and
    tonumber(afterStaleFlush.money) == moneyBefore,
    "повторный flush не перезаписывает прогресс/валюту устаревшим объектом")

local originalTransaction = WO.Database.Transaction
local retryPosition = Vector(916, 48, 144)
ply:SetPos(retryPosition)
ply:SetEyeAngles(Angle(6, 91, 0))
WO.Database.Transaction = function() return false end
WO.SaveQueue.MarkDirty(char)

MOCK.Assert(WO.SaveQueue.SaveNow(char) == false and WO.SaveQueue.IsDirty(char) and
    char.pos:DistToSqr(retryPosition) == 0,
    "при временной ошибке БД очередь сохраняет актуальную позицию для повтора")

WO.Character.Unload(ply)
MOCK.Assert(ply:HasCharacter() == false and char.player == nil and WO.SaveQueue.IsDirty(char),
    "выгрузка отвязывает игрока, не теряя неуспешное сохранение")

local rejectedStaleLoad = WO.Character.Select(ply, charId)
MOCK.Assert(rejectedStaleLoad == false and not ply:HasCharacter() and WO.SaveQueue.IsDirty(char),
    "после ошибки БД устаревшая запись не загружается, пока pending snapshot не сохранён")

WO.Database.Transaction = originalTransaction
MOCK.Assert(WO.Character.Select(ply, charId) == true and not WO.SaveQueue.IsDirty(char),
    "повтор перед загрузкой сохраняет pending snapshot после восстановления БД")
MOCK.RunTimers(0.5)

local restored = ply:GetCharacter()

MOCK.Assert(restored ~= nil, "персонаж загружен обратно")
MOCK.Assert(restored.name == "Тест", "имя восстановлено")
MOCK.Assert(restored:GetLevel() == levelBefore, "уровень восстановлен")
MOCK.Assert(ply:GetPos():DistToSqr(retryPosition) == 0 and
    math.abs(ply:EyeAngles().y - 91) < 0.01 and restored.map == game.GetMap(),
    "сохранённые после retry позиция, направление и карта восстанавливаются")
MOCK.Assert(WO.Currency.Get(ply) == moneyBefore, "деньги восстановлены: " ..
    tostring(WO.Currency.Get(ply)) .. " == " .. tostring(moneyBefore))
MOCK.Assert(WO.Inventory.GetContainer(restored):CountItem("starter_knife") == 0,
    "сохранение/перезагрузка не выдаёт нож без принятия охотничьего квеста")

print("[scenario] persistence OK")

---------------------------------------------------------------------------
-- 8b. NPC / диалоги / квесты / торговля
---------------------------------------------------------------------------

MOCK.Assert(#WO.NPCs.Spawned == 0,
    "NPC без map-specific spawn-точек не появляются автоматически")

local anchorPosition = WO.NPCs.ResolveSpawnPoint({
    anchor = "info_player_start",
    anchorIndex = 1,
    offset = Vector(12, 0, 4),
})
MOCK.Assert(isvector(anchorPosition) and anchorPosition.x == 12 and anchorPosition.z == 20,
    "map anchor разрешается детерминированно с явным смещением")
local ordinarySpawn = WO.FindSpawnPoint(ply)
MOCK.Assert(isvector(ordinarySpawn) and ordinarySpawn.x == 0 and ordinarySpawn.z == 24,
    "новый персонаж использует обычную map spawn point, а не центр карты")
local findByClass = ents.FindByClass
ents.FindByClass = function() return {} end
local missingSpawn = WO.FindSpawnPoint(ply)
ents.FindByClass = findByClass
MOCK.Assert(missingSpawn == nil,
    "при отсутствии map spawn point код не выдумывает координату в центре карты")

MOCK.mapName = "gm_construct"
local wolfSpawnPoints = WO.Config.NPCSpawnPoints.black_wolf
local boarSpawnPoints = WO.Config.NPCSpawnPoints.elwynn_boar
local function MatchPoints(points, expected, questId)
    if #points ~= 4 then return false end

    for index, xyz in ipairs(expected) do
        local point = points[index]
        local pos = point and point.pos

        if not point or point.map ~= "gm_construct" or point.questId ~= questId or
            not isvector(pos) or pos.x ~= xyz[1] or pos.y ~= xyz[2] or pos.z ~= xyz[3] then
            return false
        end
    end

    return true
end

MOCK.Assert(MatchPoints(wolfSpawnPoints, {
    { -4887.5, -3415.5, 250 }, { -4415, -3048.3, 250 },
    { -4057.9, -2683.4, 250 }, { -4878.6, -2474.7, 250 },
}, "wolves_of_elwynn") and MatchPoints(boarSpawnPoints, {
    { 1115.8, 6149.4, -32 }, { 1593.3, 6078.2, -32 },
    { 1176.7, 5825.2, -32 }, { 1586.2, 5735, -32 },
}, "boar_hunt"),
"ровно четыре волчьи и четыре кабаньи точки заданы на gm_construct без наложения")

-- Статические quest/vendor NPC размещаются только на своей подтверждённой карте.
WO.NPCs.SpawnAll()

MOCK.Assert(#WO.NPCs.Spawned == 5,
    "пять статических NPC заспавнены, включая Малигоса: " .. #WO.NPCs.Spawned)

local function FindNPC(id)
    for _, ent in ipairs(WO.NPCs.Spawned) do
        if IsValid(ent) and ent.npcDef and ent.npcDef.id == id then return ent end
    end
end

local function FindNPCs(id)
    local out = {}

    for _, ent in ipairs(WO.NPCs.Spawned) do
        if IsValid(ent) and ent.npcDef and ent.npcDef.id == id then
            out[#out + 1] = ent
        end
    end

    return out
end

local function FindDialogueOption(ply, action)
    for index, option in ipairs(ply.wo_dialogue and ply.wo_dialogue.options or {}) do
        if option.action == action then return index, option end
    end
end

local function ChooseDialogueAction(ply, action)
    local session = ply.wo_dialogue
    local index = FindDialogueOption(ply, action)
    if not session or not index then return false end

    MOCK.NetDeliver({ name = "Dialogue.Choose", args = {
        session.dialogueId, session.nodeId, index,
    } }, 8, ply)
    return true
end

local function At(ent, x, y, z)
    if not IsValid(ent) then return false end
    local pos = ent:GetPos()
    return math.abs(pos.x - x) < 0.01 and math.abs(pos.y - y) < 0.01 and
        math.abs(pos.z - z) < 0.01
end

local marshal = FindNPC("marshal_dughal")
local marla = FindNPC("trader_marla")
local hunter = FindNPC("hunter_dyrne")
local mountVendor = FindNPC("mount_merchant")
local malygos = FindNPC("malygos_scroll_vendor")

MOCK.Assert(marshal and marla and hunter and mountVendor and malygos and
    #FindNPCs("marshal_dughal") == 1 and #FindNPCs("trader_marla") == 1 and
    #FindNPCs("hunter_dyrne") == 1 and #FindNPCs("mount_merchant") == 1,
    "маршал, торговец, отдельный охотник и торговец маунтами размещены по одному")
MOCK.Assert(At(hunter, 1572.5, -416.2, -144) and
    At(marshal, 1341.2, -654.8, -144) and At(marla, 1089.1, -352.7, -144) and
    At(mountVendor, 850, -520, -144),
    "NPC используют точные подтверждённые координаты; mount vendor имеет отдельную явную точку")
MOCK.Assert(hunter:GetModel() == "models/mailer/wow_characters/wowanim_worgen_male.mdl" and
    marshal:GetModel() == "models/mailer/wow_characters/wowanim_skyhunterNL.mdl" and
    marla:GetModel() == "models/mailer/wow_characters/wowanim_gnome_male.mdl" and
    mountVendor:GetModel() == "models/mailer/wow_characters/wowanim_c_stoneconstruct.mdl",
    "в runtime выставлены точные модели NPC")
MOCK.Assert(hunter.npcDef.quests[1] == "boar_hunt" and
    #hunter.npcDef.quests == 1 and marshal.npcDef.quests[3] == "wolves_of_elwynn" and
    WO.Quests.Get("boar_hunt").giver == "hunter_dyrne" and
    WO.Quests.Get("boar_hunt").turnInGiver == "hunter_dyrne" and
    WO.Quests.Get("wolves_of_elwynn").giver == "marshal_dughal" and
    WO.Quests.Get("wolves_of_elwynn").turnInGiver == "marshal_dughal" and
    hunter.__useType == SIMPLE_USE and marshal.__useType == SIMPLE_USE and
    marla.__useType == SIMPLE_USE and mountVendor.__useType == SIMPLE_USE,
    "Охотник выдаёт/принимает кабанов; Маршал выдаёт/принимает волков")
MOCK.Assert(WO.Interaction.GetRange(marla) == WO.Config.InteractDistance,
    "клиентская подсказка и серверный Use согласованы по диапазону")
MOCK.Assert(#FindNPCs("black_wolf") == 0 and #FindNPCs("elwynn_boar") == 0,
    "волки и кабаны не появляются до принятия соответствующих квестов")

for level = 1, 4 do
    local wolfStats = WO.NPCs.GetLevelStats(WO.NPCs.Get("black_wolf"), level)
    local boarStats = WO.NPCs.GetLevelStats(WO.NPCs.Get("elwynn_boar"), level)
    MOCK.Assert(wolfStats and boarStats and wolfStats.health > 0 and boarStats.health > 0,
        "wolf/boar имеют серверные характеристики уровня " .. level)

    if level > 1 then
        MOCK.Assert(wolfStats.health > WO.NPCs.GetLevelStats(WO.NPCs.Get("black_wolf"), level - 1).health and
            wolfStats.damage > WO.NPCs.GetLevelStats(WO.NPCs.Get("black_wolf"), level - 1).damage and
            boarStats.health > WO.NPCs.GetLevelStats(WO.NPCs.Get("elwynn_boar"), level - 1).health and
            boarStats.damage > WO.NPCs.GetLevelStats(WO.NPCs.Get("elwynn_boar"), level - 1).damage,
            "здоровье и урон обоих существ растут к уровню " .. level)
    end
end

-- Хлебный квест можно закрыть независимо от охотничьей цепочки.
local breadContainer = WO.Inventory.GetContainer(ply:GetCharacter())
local breadBefore = breadContainer:CountItem("bread")
if breadBefore < 3 then
    MOCK.Assert(WO.Inventory.GiveItem(ply, "bread", 3 - breadBefore) == true,
        "тестовые припасы можно положить в инвентарь")
end
local breadBeforeTurnIn = breadContainer:CountItem("bread")
local moneyBeforeSupplies = WO.Currency.Get(ply)
ply:SetPos(marshal:GetPos())
marshal:Use(ply, ply)
MOCK.Assert(ChooseDialogueAction(ply, "next:supplies"),
    "диалог динамически открывает узел хлебного поручения")
MOCK.Assert(ChooseDialogueAction(ply, "quest:supplies_for_the_road"),
    "Маршал выдаёт хлебное поручение через разрешённый option")
local suppliesQuest = ply:GetCharacter().quests["supplies_for_the_road"]
MOCK.Assert(suppliesQuest and suppliesQuest.status == "active" and suppliesQuest.progress[1] == 3,
    "хлебный сбор готов отдельно, но требует физической сдачи")
MOCK.Assert(ChooseDialogueAction(ply, "quest:supplies_for_the_road"),
    "динамический option сдаёт готовое хлебное поручение")
MOCK.Assert(suppliesQuest.status == "completed" and
    breadContainer:CountItem("bread") == breadBeforeTurnIn - 3 and
    WO.Currency.Get(ply) == moneyBeforeSupplies + 60 and
    ply:GetCharacter().quests["boar_hunt"] == nil,
    "хлеб сдаётся независимо от обязательной охотничьей цепочки")

-- Торговец покупает материалы и возвращает деньги за собственный ассортимент.
ply:SetPos(marla:GetPos())
marla:Use(ply, ply)
MOCK.Assert(ChooseDialogueAction(ply, "next:work"), "торговец открывает узел работы")
MOCK.Assert(ChooseDialogueAction(ply, "quest:meet_the_trader"),
    "диалоговый talk-квест доступен как серверный dynamic option")
MOCK.Assert(ply:GetCharacter().quests["meet_the_trader"] and
    ply:GetCharacter().quests["meet_the_trader"].status == "completed",
    "диалоговый talk-квест торговца завершается по факту разговора")
marla:Use(ply, ply)
MOCK.Assert(ChooseDialogueAction(ply, "vendor"), "кнопка торговца открывает витрину")
local vendorMoneyBefore = WO.Currency.Get(ply)
MOCK.NetDeliver({ name = "Vendor.Buy", args = { "trader_marla", "health_potion", 2 } }, 8, ply)
MOCK.Assert(WO.Currency.Get(ply) == vendorMoneyBefore - 50,
    "покупка у торговца валидирует stock и списывает серверную цену")
local vendorActionOutbox = MOCK.TakeOutbox()
local vendorActionResults = MOCK.FindInbox(vendorActionOutbox, "Vendor.ActionResult")
MOCK.Assert(#vendorActionResults == 1 and vendorActionResults[1].args[1].success == true,
    "сервер подтверждает завершение покупки торговцу, чтобы UI не ждал повторных нажатий")
MOCK.NetDeliver({ name = "Vendor.Buy", args = { "trader_marla", "not_in_stock_item", 1 } }, 8, ply)
local failedVendorResult = MOCK.FindInbox(MOCK.TakeOutbox(), "Vendor.ActionResult")
MOCK.Assert(#failedVendorResult == 1 and failedVendorResult[1].args[1].success == false and
    failedVendorResult[1].args[1].reason == "not_in_stock",
    "сервер немедленно возвращает причину отклонённой покупки вместо молчаливого отказа")
local boughtPotionUID
for uid, instance in pairs(WO.Inventory.GetContainer(ply:GetCharacter()):GetItems()) do
    if instance.class == "health_potion" then boughtPotionUID = uid break end
end
local potionSellPrice = WO.Vendors.GetSellPrice(marla.npcDef, "health_potion")
local potionAmountBeforeSale = WO.Inventory.GetContainer(ply:GetCharacter()):CountItem("health_potion")
local moneyBeforePotionSale = WO.Currency.Get(ply)
local potionSold = boughtPotionUID and
    WO.Vendors.Sell(ply, "trader_marla", boughtPotionUID, 1) == true
local potionAmountAfterSale = WO.Inventory.GetContainer(ply:GetCharacter()):CountItem("health_potion")
local breadSellPrice = WO.Vendors.GetSellPrice(marla.npcDef, "bread")
local tuskGiven = WO.Inventory.GiveItem(ply, "boar_tusk", 1)
MOCK.Assert(boughtPotionUID and potionSellPrice and potionSold and
    WO.Currency.Get(ply) == moneyBeforePotionSale + potionSellPrice and
    potionAmountAfterSale == potionAmountBeforeSale - 1 and breadSellPrice ~= nil and tuskGiven == true,
    "торговец принимает обратно предметы собственной витрины и корректно проводит продажу: " ..
        tostring(boughtPotionUID) .. "/" .. tostring(potionSellPrice) .. "/" ..
        tostring(potionSold) .. "/" .. tostring(potionAmountAfterSale) .. "/" .. tostring(breadSellPrice) ..
        "/" .. tostring(tuskGiven))
local tuskUID
for uid, instance in pairs(WO.Inventory.GetContainer(ply:GetCharacter()):GetItems()) do
    if instance.class == "boar_tusk" then tuskUID = uid break end
end
local junkMoneyBefore = WO.Currency.Get(ply)
MOCK.Assert(tuskUID and WO.Vendors.Sell(ply, "trader_marla", tuskUID, 1) == true and
    WO.Currency.Get(ply) > junkMoneyBefore,
    "низкоуровневый трофей продаётся за серверную цену торговцу")

local oldScrollClass = WO.Spells.GetScrollClass("healing_wave", 1)
MOCK.Assert(WO.Inventory.GiveItem(ply, oldScrollClass, 1) == true,
    "старый свиток помещается в инвентарь для проверки перепродажи")
local oldScrollUID
for uid, instance in pairs(WO.Inventory.GetContainer(ply:GetCharacter()):GetItems()) do
    if instance.class == oldScrollClass then oldScrollUID = uid break end
end
ply:SetPos(malygos:GetPos())
MOCK.Assert(WO.Vendors.Open(ply, malygos.npcDef, malygos) == true,
    "Малигос открывает серверную сессию для возврата свитка")
local scrollSellPrice = WO.Vendors.GetSellPrice(malygos.npcDef, oldScrollClass)
local moneyBeforeScrollSale = WO.Currency.Get(ply)
MOCK.Assert(oldScrollUID and scrollSellPrice and
    WO.Vendors.Sell(ply, "malygos_scroll_vendor", oldScrollUID, 1) == true and
    WO.Currency.Get(ply) == moneyBeforeScrollSale + scrollSellPrice and
    WO.Inventory.GetContainer(ply:GetCharacter()):CountItem(oldScrollClass) == 0,
    "старые магические свитки отображаются и успешно продаются NPC-Малигосу")
ply.wo_vendor = nil
ply:SetPos(marla:GetPos())
MOCK.AdvanceTime(5) -- separate test phases to respect the real dialogue rate limit

-- Сохранённое старое active-состояние не обходит новый prerequisite волчьей цепочки.
local char = ply:GetCharacter()
local savedQuestStates = char.quests
char.quests = { wolves_of_elwynn = { status = "active", progress = { [1] = 4 }, tracked = true } }
MOCK.Assert(WO.NPCs.HasActiveQuest("wolves_of_elwynn") == false and
    WO.Quests.TryComplete(ply, "wolves_of_elwynn") == false,
    "старый wolf state без завершённой охоты не может спавниться или сдаваться")
char.quests = savedQuestStates

-- Общее Use-range и невозможность выдать квест по поддельному/дальнему NPC.
ply:SetPos(marshal:GetPos() + Vector(WO.Config.InteractDistance + 1, 0, 0))
MOCK.Assert(WO.Interaction.TryInteract(ply, marshal) == false and
    WO.Quests.OfferFromDialogue(ply, "wolves_of_elwynn", marshal.npcDef, marshal) == false and
    char.quests["wolves_of_elwynn"] == nil,
    "дальний marshal interaction и невалидный wolf giver отклоняются")
ply:SetPos(hunter:GetPos())
MOCK.NetDeliver({ name = "Quest.Accept", args = { "wolves_of_elwynn" } }, 8, ply)
MOCK.Assert(char.quests["wolves_of_elwynn"] == nil and char.quests["boar_hunt"] == nil,
    "прямой клиентский Quest.Accept без серверной сессии не выдаёт задание")

-- Охотник выдаёт нож за охоту на кабанов; Маршал откроет волков только после отчёта.
ply:SetPos(marshal:GetPos())
marshal:Use(ply, ply)
MOCK.Assert(FindDialogueOption(ply, "quest:wolves_of_elwynn") == nil,
    "волчье задание скрыто в диалоге, пока не выполнен prerequisite")
local earlyWolves, earlyWolvesReason = WO.Quests.Accept(
    ply, "wolves_of_elwynn", marshal.npcDef, marshal)
MOCK.Assert(earlyWolves == false and earlyWolvesReason == "prerequisites",
    "Маршал не выдаёт волков до сдачи охоты на кабанов")

ply:SetPos(hunter:GetPos())
hunter:Use(ply, ply)
MOCK.Assert(FindDialogueOption(ply, "quest:wolves_of_elwynn") == nil,
    "охотник не предлагает волков — это задание Маршала")
MOCK.Assert(ChooseDialogueAction(ply, "quest:boar_hunt"),
    "принятие охоты динамически выдаёт нож и создаёт четыре spawn-точки")

local boarQuest = char.quests["boar_hunt"]
local dynamicBoarOption, dynamicBoarData = FindDialogueOption(ply, "quest:boar_hunt")
local abandonBoarOption = FindDialogueOption(ply, "abandon:boar_hunt")
MOCK.Assert(dynamicBoarOption and dynamicBoarData.text:find("Проверить задание", 1, true) and
    dynamicBoarData.text:find("0/1", 1, true) and abandonBoarOption and
    WO.Inventory.GetContainer(char):CountItem("starter_knife") == 1,
    "после принятия исчезает «взять», показываются проверка прогресса/отказ, нож выдан")
local activeBoars = FindNPCs("elwynn_boar")
MOCK.Assert(boarQuest and boarQuest.status == "active" and #activeBoars == 4 and
    #FindNPCs("black_wolf") == 0,
    "принятие первого задания создаёт ровно четыре кабана и ни одного волка")
local knifeUID
for uid, instance in pairs(WO.Inventory.GetContainer(char):GetItems()) do
    if instance.class == "starter_knife" then knifeUID = uid break end
end
MOCK.TakeOutbox()
MOCK.Assert(knifeUID and WO.Equipment.Equip(ply, knifeUID) == true and
    boarQuest.progress[1] == 1,
    "экипировка выданного охотником ножа выполняет обязательный первый шаг")
local acceptedKnife = ply:GetWeapon("tfa_cso_coldsteelblade")
MOCK.Assert(IsValid(acceptedKnife) and acceptedKnife.WOItemUID == knifeUID and
    ply:GetActiveWeapon() == acceptedKnife and
    WO.Inventory.GetContainer(char):CountItem("starter_knife") == 0,
    "weapon selector получает экипированный нож; предмет хранится только в слоте")
local activeWeaponBeforeDeniedSelect = ply:GetActiveWeapon()
MOCK.NetDeliver({ name = "Weapons.Select", args = { "weapon_hpwr_stick" } }, 8, ply)
MOCK.Assert(ply:GetActiveWeapon() == activeWeaponBeforeDeniedSelect,
    "сервер отклоняет выбор SWEP, которым персонаж не владеет")
MOCK.NetDeliver({ name = "Weapons.Select", args = { "tfa_cso_coldsteelblade" } }, 8, ply)
MOCK.Assert(ply:GetActiveWeapon() == acceptedKnife,
    "сервер выбирает принадлежащий персонажу SWEP только после проверки владения")

local outsider = MOCK.CreatePlayer("Посторонний", "STEAM_0:0:777")
local outsiderChar = WO.Character.New({
    id = "outsider-test-character", name = "Посторонний", surname = "Охотник",
    race = "human", class = "warrior", level = 1,
})
outsider:SetCharacter(outsiderChar)
outsiderChar.player = outsider
local outsiderTarget = activeBoars[1]
outsiderTarget:SetHealth(0)
WO.NPCs.HandleKilled(outsiderTarget, outsider)
outsiderTarget:Remove()
MOCK.RunTimers(1.0)
activeBoars = FindNPCs("elwynn_boar")
table.sort(activeBoars, function(a, b) return a.WO_NPCSpawnKey < b.WO_NPCSpawnKey end)
local replacementFound = false
for _, ent in ipairs(activeBoars) do
    if ent.WO_NPCSpawnKey == outsiderTarget.WO_NPCSpawnKey then replacementFound = true end
end
MOCK.Assert(#activeBoars == 4 and replacementFound,
    "чужой игрок убившего квестовую цель вызывает её повторный спавн в той же точке")

for index, boar in ipairs(activeBoars) do
    local point = boarSpawnPoints[index]
    MOCK.Assert(boar:GetClass() == "wow_npc_2809" and
        boar.WO_NPCLevel == point.level and boar:GetPos().x == point.pos.x and
        boar:GetPos().y == point.pos.y and boar:GetPos().z == point.pos.z,
        "кабан " .. index .. " использует точный внешний класс и свою отдельную точку")
end

local originalRandom = math.random
math.random = function(minimum, maximum)
    if minimum == nil then return 0 end
    if maximum == nil then return minimum end
    return minimum
end

do
local participantTarget = activeBoars[1]
local xpBeforeNPCDeath = char.experience or 0
local levelBeforeNPCDeath = char.level or 1
local expectedNPCXP, expectedNPCLevel = xpBeforeNPCDeath + 44, levelBeforeNPCDeath
while expectedNPCLevel < (WO.Config.MaxLevel or 60) and
    expectedNPCXP >= WO.Config.GetXPForLevel(expectedNPCLevel) do
    expectedNPCXP = expectedNPCXP - WO.Config.GetXPForLevel(expectedNPCLevel)
    expectedNPCLevel = expectedNPCLevel + 1
end
MOCK.TakeOutbox()
participantTarget:SetHealth(0)
WO.NPCs.HandleKilled(participantTarget, ply)
local npcXPOutbox = MOCK.TakeOutbox()
local clearXPMessage = false
for _, message in ipairs(MOCK.FindInbox(npcXPOutbox, "Notify.Show")) do
    if message.args[2] == "+44 XP" then clearXPMessage = true end
end
MOCK.Assert(char.level == expectedNPCLevel and char.experience == expectedNPCXP and clearXPMessage,
    "убийца получает 44 XP сразу, с учётом level-up, и видит понятное уведомление +44 XP")
participantTarget:Remove()
end
WO.NPCs.SyncQuestSpawns("boar_hunt")
MOCK.Assert(#FindNPCs("elwynn_boar") == 3,
    "убийство участником задания не создаёт замену даже при синхронизации группы")

activeBoars = FindNPCs("elwynn_boar")
for _, boar in ipairs(activeBoars) do
    boar:SetHealth(0)
    WO.NPCs.HandleKilled(boar, ply)
    boar:Remove() -- external engine NPC is removed after its native death hook
end
math.random = originalRandom

MOCK.Assert(boarQuest.status == "active" and boarQuest.progress[2] == 4 and
    #FindNPCs("elwynn_boar") == 0,
    "четыре кабана завершают прогресс, но не закрывают квест без отчёта Охотнику")
local wolfQuest
do
local lootCoins, lootItems = 0, 0
local function CountLoot()
    local coins, items = 0, 0

    for _, ent in ipairs(ents.GetAll()) do
        if ent:GetClass() == "wo_coin_pile" then coins = coins + 1 end
        if ent:GetClass() == "wo_item_world" then items = items + 1 end
    end

    return coins, items
end
lootCoins, lootItems = CountLoot()
MOCK.Assert(lootCoins > 0 and lootItems > 0,
    "смерть кабанов физически выбрасывает подбираемые монеты и предметы добычи")

-- Подбор physical loot транзакционно переносит item/currency ровно один раз.
local lootItem
for _, ent in ipairs(ents.GetAll()) do
    if ent:GetClass() == "wo_item_world" and ent.ItemInstance then
        lootItem = ent
        break
    end
end
MOCK.Assert(IsValid(lootItem), "loot item создан в мире")
ply:SetPos(lootItem:GetPos())
lootItem.PickupCooldown = 0
local lootedClass = lootItem.ItemInstance.class
lootItem:Use(ply, ply)
MOCK.Assert(not IsValid(lootItem) and
    WO.Inventory.GetContainer(char):CountItem(lootedClass) > 0 and
    WO.World.PickupItem(ply, lootItem) == false,
    "нажатие E переносит серверный NPC-loot в инвентарь ровно один раз")
local coinPile
for _, ent in ipairs(ents.GetAll()) do
    if ent:GetClass() == "wo_coin_pile" then coinPile = ent break end
end
MOCK.Assert(IsValid(coinPile), "монеты представлены отдельной физической кучкой")
ply:SetPos(coinPile:GetPos())
coinPile.PickupCooldown = 0
local moneyBeforeCoinPickup = WO.Currency.Get(ply)
coinPile:Use(ply, ply)
MOCK.Assert(not IsValid(coinPile) and WO.Currency.Get(ply) > moneyBeforeCoinPickup and
    WO.World.PickupCoins(ply, coinPile) == false,
    "нажатие E зачисляет физические монеты ровно один раз")

-- Cabana hunt turns in at Hunter, not Marshal; the Marshal then gives the wolf task.
ply:SetPos(marshal:GetPos())
marshal:Use(ply, ply)
MOCK.Assert(FindDialogueOption(ply, "quest:boar_hunt") == nil and
    WO.Quests.OfferFromDialogue(ply, "boar_hunt", marshal.npcDef, marshal) == false and
    boarQuest.status == "active",
    "Маршал не показывает и не принимает охоту на кабанов")

ply:SetPos(hunter:GetPos())
hunter:Use(ply, ply)
MOCK.Assert(FindDialogueOption(ply, "quest:boar_hunt") ~= nil and
    ChooseDialogueAction(ply, "quest:boar_hunt"),
    "Охотник принимает выполненную охоту на кабанов")
MOCK.Assert(boarQuest.status == "completed" and char.quests["wolves_of_elwynn"] == nil and
    WO.Inventory.GetContainer(char):CountItem("starter_knife") == 0,
    "правильная сдача завершает охоту и сохраняет выданный нож в экипировке")

ply:SetPos(marshal:GetPos())
marshal:Use(ply, ply)
local wolfOfferIndex, wolfOffer = FindDialogueOption(ply, "quest:wolves_of_elwynn")
MOCK.Assert(wolfOfferIndex ~= nil and wolfOffer.text:find("Взять задание", 1, true) and
    ChooseDialogueAction(ply, "quest:wolves_of_elwynn"),
    "после отчёта Маршал динамически выдаёт поручение на волков")
wolfQuest = char.quests["wolves_of_elwynn"]
local wolfProgressIndex, wolfProgressOption = FindDialogueOption(ply, "quest:wolves_of_elwynn")
MOCK.Assert(wolfProgressIndex and wolfProgressOption.text:find("0/4", 1, true) and
    FindDialogueOption(ply, "abandon:wolves_of_elwynn"),
    "активное задание Маршала показывает прогресс волков и отказ вместо повторного принятия")
local activeWolves = FindNPCs("black_wolf")
MOCK.Assert(wolfQuest and wolfQuest.status == "active" and #activeWolves == 4 and
    #FindNPCs("elwynn_boar") == 0,
    "wolf quest spawns ровно четыре внешних NPC после prerequisite")

table.sort(activeWolves, function(a, b) return a.WO_NPCSpawnKey < b.WO_NPCSpawnKey end)
local wolf = activeWolves[1]
MOCK.Assert(wolf:GetClass() == "wow_npc_14892" and
    wolf.npcDef.workshopClass == "wow_npc_14892" and
    WO.Workshop.HasNPCClass("wow_npc_14892") and
    scripted_ents.GetStored("wo_wolf") == nil and
    wolf:GetNW2String("wo_npc_id", "") == "black_wolf" and
    wolf:GetNW2String("wo_name", "") == "Волк" and
    wolf:GetNW2Int("wo_level", 0) == 1,
    "квестовый волк — точный внешний wow_npc_14892 без custom SENT или fallback")
for index, ent in ipairs(activeWolves) do
    local point = wolfSpawnPoints[index]
    MOCK.Assert(ent:GetClass() == "wow_npc_14892" and
        ent.WO_NPCLevel == point.level and ent:GetPos().x == point.pos.x and
        ent:GetPos().y == point.pos.y and ent:GetPos().z == point.pos.z,
        "волк " .. index .. " использует точный внешний класс, уровень и spawn-точку")
end

local originalWolfRandom = math.random
math.random = function(minimum, maximum)
    if minimum == nil then return 0 end
    if maximum == nil then return minimum end
    return minimum
end
local coinsBeforeDeath, itemsBeforeDeath = CountLoot()
local npcAttacker = MOCK.NewEntity("npc")
local npcKilledTarget = activeWolves[1]
local npcKilledKey = npcKilledTarget.WO_NPCSpawnKey
npcKilledTarget:SetHealth(0)
WO.NPCs.HandleKilled(npcKilledTarget, npcAttacker)
local afterFirstWolfCoins, afterFirstWolfItems = CountLoot()
local dropsAfterDeath = afterFirstWolfCoins + afterFirstWolfItems
hook.Run("OnNPCKilled", npcKilledTarget, npcAttacker)
local duplicateCoins, duplicateItems = CountLoot()
MOCK.Assert(afterFirstWolfCoins > coinsBeforeDeath and afterFirstWolfItems > itemsBeforeDeath and
    duplicateCoins + duplicateItems == dropsAfterDeath and wolfQuest.progress[1] == nil,
    "NPC-смерть даёт физический loot ровно один раз и не засчитывается игроку")
npcKilledTarget:Remove()
MOCK.RunTimers(1.0)
activeWolves = FindNPCs("black_wolf")
table.sort(activeWolves, function(a, b) return a.WO_NPCSpawnKey < b.WO_NPCSpawnKey end)
local wolfReplacementFound = false
for _, ent in ipairs(activeWolves) do
    if ent.WO_NPCSpawnKey == npcKilledKey then wolfReplacementFound = true end
end
MOCK.Assert(#activeWolves == 4 and wolfReplacementFound,
    "если квестовую цель убивает NPC, она снова появляется в своей точке")

for _, target in ipairs(activeWolves) do
    target:SetHealth(0)
    WO.NPCs.HandleKilled(target, ply)
    target:Remove()
end
math.random = originalWolfRandom
MOCK.RunTimers(1.0) -- settle death hooks and fixed-point quest cleanup
MOCK.Assert(wolfQuest.status == "active" and wolfQuest.progress[1] == 4 and
    #FindNPCs("black_wolf") == 0,
    "четыре волка дают готовность, не завершая ручной turn-in")
end
ply:SetPos(marshal:GetPos())
marshal:Use(ply, ply)
local readyWolfIndex, readyWolfOption = FindDialogueOption(ply, "quest:wolves_of_elwynn")
MOCK.Assert(readyWolfIndex and readyWolfOption.text:find("Сдать задание", 1, true) and
    ChooseDialogueAction(ply, "quest:wolves_of_elwynn"),
    "Маршал показывает актуальную сдачу и принимает волчий квест")
MOCK.Assert(wolfQuest.status == "completed" and char.quests["boar_hunt"].status == "completed",
    "маршал принимает отчёт об охоте на волков только после prerequisite")

-- Mount vendor uses the exact horse class and the unique, reusable stone item.
WO.Currency.Add(ply, 10000, "mount-test-funds")
ply:SetPos(mountVendor:GetPos())
mountVendor:Use(ply, ply)
MOCK.NetDeliver({ name = "Dialogue.Choose", args = { "mount_vendor", "start", 1 } }, 8, ply)
local moneyBeforeMountBuy = WO.Currency.Get(ply)
MOCK.NetDeliver({ name = "Vendor.Buy", args = { "mount_merchant", "mount_stone", 1 } }, 8, ply)
local mountStone = WO.Inventory.GetContainer(char):GetItems()
local mountUID, mountInstance
for uid, instance in pairs(mountStone) do
    if instance.class == "mount_stone" then mountUID, mountInstance = uid, instance break end
end
MOCK.Assert(mountUID and mountInstance and WO.Currency.Get(ply) == moneyBeforeMountBuy - 500 and
    WO.Inventory.GiveItem(ply, "mount_stone", 1) == false,
    "покупка списывает верную цену, выдаёт один бесконечно используемый unique stone")
MOCK.Assert(WO.Inventory.UseItem(ply, mountUID) == true and
    WO.Inventory.GetContainer(char):CountItem("mount_stone") == 1 and
    #ents.FindByClass("wow_npc_8883") == 1,
    "использование камня призывает ровно одну лошадь класса wow_npc_8883")
local summonedHorse = ents.FindByClass("wow_npc_8883")[1]
local duplicateHorse = ents.Create("wow_npc_8883")
duplicateHorse.WO_MountOwnerCharID = char.id
duplicateHorse:Spawn()
MOCK.Assert(WO.Inventory.UseItem(ply, mountUID) == true and
    not IsValid(summonedHorse) and not IsValid(duplicateHorse) and
    WO.Inventory.GetContainer(char):CountItem("mount_stone") == 1,
    "повторное применение отзывает коня и удаляет runtime-дубликаты без дюпа камня")

mountInstance.data.hunger = 0
local hungryUse, hungryReason = WO.Inventory.UseItem(ply, mountUID)
MOCK.Assert(hungryUse == false and hungryReason == "mount_hungry" and
    #ents.FindByClass("wow_npc_8883") == 0,
    "голодный маунт не вызывается")
MOCK.Assert(WO.Inventory.GiveItem(ply, "mount_oats", 1) == true,
    "овёс можно приобрести/выдать как обычный расходуемый предмет")
local oatsUID
for uid, instance in pairs(WO.Inventory.GetContainer(char):GetItems()) do
    if instance.class == "mount_oats" then oatsUID = uid break end
end
MOCK.Assert(oatsUID and WO.Inventory.UseItem(ply, oatsUID) == true and
    mountInstance.data.hunger == 35 and WO.Inventory.GetContainer(char):CountItem("mount_oats") == 0,
    "овёс кормит лошадь и расходуется только после успешной серверной операции")
MOCK.Assert(WO.Inventory.GiveItem(ply, "mount_training_kit", 1) == true,
    "лошадь можно прокачивать тренировочным набором")
local trainingUID
for uid, instance in pairs(WO.Inventory.GetContainer(char):GetItems()) do
    if instance.class == "mount_training_kit" then trainingUID = uid break end
end
MOCK.Assert(trainingUID and WO.Inventory.UseItem(ply, trainingUID) == true and
    mountInstance.data.level == 2 and
    WO.Inventory.GetContainer(char):CountItem("mount_training_kit") == 0,
    "mount upgrade требует успешного kit use и сохраняет level на stone item")
MOCK.Assert(WO.Inventory.UseItem(ply, mountUID) == true and
    #ents.FindByClass("wow_npc_8883") == 1,
    "сытая улучшенная лошадь снова вызывается одним камнем")
do
summonedHorse = ents.FindByClass("wow_npc_8883")[1]
summonedHorse:SetHealth(50)
WO.Hook.Run("CombatPostDamage", { target = summonedHorse })
MOCK.Assert(mountInstance.data.health == 50,
    "текущая HP лошади сохраняется в принадлежащем игроку камне")
MOCK.Assert(WO.Inventory.GiveItem(ply, "mount_healing_salve", 1) == true,
    "лечебный предмет маунта доступен в инвентаре")
local salveUID
for uid, instance in pairs(WO.Inventory.GetContainer(char):GetItems()) do
    if instance.class == "mount_healing_salve" then salveUID = uid break end
end
MOCK.Assert(salveUID and WO.Inventory.UseItem(ply, salveUID) == true and
    mountInstance.data.health == 110 and summonedHorse:Health() == 110,
    "лечебный бальзам восстанавливает здоровье конкретного summoned маунта")
MOCK.Assert(WO.Inventory.GiveItem(ply, "mount_barding", 1) == true,
    "для конкретной лошади можно получить предмет улучшения брони")
local bardingUID
for uid, instance in pairs(WO.Inventory.GetContainer(char):GetItems()) do
    if instance.class == "mount_barding" then bardingUID = uid break end
end
local armorTest = { target = summonedHorse, amount = 100 }
MOCK.Assert(bardingUID and WO.Inventory.UseItem(ply, bardingUID) == true and
    mountInstance.data.armorLevel == 1 and
    summonedHorse:GetNW2Int("wo_mount_armor", 0) == 1,
    "сервер применяет mount-specific броню и отражает улучшение в runtime NPC")
WO.Hook.Run("CombatCalculate", armorTest)
MOCK.Assert(armorTest.amount == 94,
    "улучшение брони действительно снижает урон по принадлежащему маунту")
end
WO.Mounts.Toggle(ply, mountInstance)
MOCK.Assert(#ents.FindByClass("wow_npc_8883") == 0 and
    WO.Inventory.GetContainer(char):CountItem("mount_stone") == 1,
    "лошадь отзывается повторным использованием камня без его расходования")

print("[scenario] ordered quest chain / exact NPC placements / physical loot / guarded mounts OK")

---------------------------------------------------------------------------
-- 9. Выход
---------------------------------------------------------------------------

hook.Run("PlayerDisconnected", ply)
MOCK.RunTimers(1)

print("[scenario] ALL SERVER TESTS PASSED")
