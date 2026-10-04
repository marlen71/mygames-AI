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
    ["models/wow_monsters/direwolf.mdl"] = true,
}

-- Runtime registry mocks only the exact external boar and horse classes.
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
MOCK.Assert(table.Count(WO.Plugins.GetAll()) == 29,
    "загружены все 29 plugin metadata: " .. table.Count(WO.Plugins.GetAll()))
MOCK.Assert(WO.Plugins.IsLoaded("character") and WO.Plugins.IsLoaded("hud") and
    WO.Plugins.IsLoaded("spells") and WO.Plugins.IsLoaded("mounts"),
    "плагины персонажа, HUD, книги заклинаний и маунтов загрузились")
MOCK.Assert(MOCK.clientFilesAdded["warcraftonline/gamemode/plugins/character/sh_plugin.lua"],
    "сервер отправил клиенту метаданные character через AddCSLuaFile")
local savedLocalPlayer = LocalPlayer
LocalPlayer = nil
local serverUUID = WO.Util.UUID()
LocalPlayer = savedLocalPlayer
MOCK.Assert(WO.Util.IsUUID(serverUUID), "UUID создаётся на сервере без LocalPlayer")
MOCK.Assert(WO.Races.GetIDs and #WO.Races.GetIDs() >= 4, "расы зарегистрированы: " ..
    (WO.Races.GetIDs and #WO.Races.GetIDs() or 0))
local concatenatedHumanModel = "models/mailer/character/human/male/humanmale00_99.mdl"
MOCK.mountedFiles[concatenatedHumanModel] = true
player_manager.AddValidModel("humanmale00_99", concatenatedHumanModel)
WO.Models.RefreshRaceLists()
MOCK.Assert(table.HasValue(WO.Races.GetModels("human", "male"), concatenatedHumanModel),
    "server refresh находит player_manager race/gender в слитой строке humanmale00_99")
MOCK.Assert(WO.Classes.GetIDs and #WO.Classes.GetIDs() >= 4, "классы зарегистрированы")
MOCK.Assert(WO.Items.GetAll and table.Count(WO.Items.GetAll()) >= 12,
    "предметы зарегистрированы: " .. (WO.Items.GetAll and table.Count(WO.Items.GetAll()) or 0))
MOCK.Assert(WO.Models ~= nil and WO.Models.Catalog ~= nil, "каталог моделей Mailer на месте")
MOCK.Assert(WO.Plugins.IsLoaded("workshop") and WO.Workshop.ModelOr ~= nil,
    "Workshop adapter загружен отдельным плагином")
MOCK.Assert(WO.NPCs.Get("black_wolf").entityClass == "wo_wolf" and
    WO.NPCs.Get("black_wolf").workshopClass == nil and
    WO.NPCs.Get("black_wolf").model == "models/wow_monsters/direwolf.mdl" and
    WO.NPCs.Get("black_wolf").maxLevel == 4 and
    WO.NPCs.Get("elwynn_boar").workshopClass == "wow_npc_2809" and
    WO.NPCs.Get("elwynn_boar").maxLevel == 4,
    "wolf is the exact custom direwolf; boars keep exact wow_npc_2809 class")
MOCK.Assert(not WO.Workshop.HasNPCClass("wow_npc_14892") and
    WO.Workshop.HasNPCClass("wow_npc_2809") and
    WO.Workshop.HasNPCClass("wow_npc_8883"),
    "runtime registry requires the exact boar/horse classes and no old wolf class")
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
local requestedParticles = {
    ["pfx1_08~"] = true, ["pfx1_0e"] = true, ["pfx1_08#"] = true,
    ["pfx1_08_~a"] = true, ["pfx1_08_"] = true, ["pfx1_08_~"] = true,
    ["pfx1_06"] = true, ["pfx1_06~"] = true, ["pfx1_04"] = true,
    ["pfx8_07"] = true, ["pfx2_03"] = true,
}
local foundParticles = {}
for _, spell in pairs(WO.Spells.GetAll()) do
    if spell.particle then foundParticles[spell.particle] = true end
    if spell.trailParticle then foundParticles[spell.trailParticle] = true end
    if spell.impactParticle then foundParticles[spell.impactParticle] = true end
end
for particle in pairs(requestedParticles) do
    MOCK.Assert(foundParticles[particle] == true,
        "spell schemas include requested impact particle " .. particle)
end

local starterKnifeDef = WO.Items.Get("starter_knife")
local arcaneHandsDef = WO.Items.Get("arcane_hands")
local desiredWeapons = WO.Config.StartingWeaponClasses
local mageDesired = WO.Loadout.GetDesiredClasses({ class = "mage" })
local warriorDesired = WO.Loadout.GetDesiredClasses({ class = "warrior" })
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
    "только явный starter_knife является предметом; нож, руки и wand сохраняют точные классы")
MOCK.Assert(desiredWeapons.hands == "drc_unarmed" and
    desiredWeapons.knife == "tfa_cso_coldsteelblade" and
    desiredWeapons.mage == "wo_magic_grimoire" and
    desiredWeapons.mageLegacy == "weapon_hpwr_stick" and
    weapons.GetStored("drc_unarmed") and
    weapons.GetStored("tfa_cso_coldsteelblade") and
    weapons.GetStored("wo_magic_grimoire") and
    weapons.GetStored("weapon_hpwr_stick"),
    "новый grimoire активен, а точные hands/knife и прежний wand сохранены")
MOCK.Assert(#mageDesired == 3 and mageDesired[1] == "drc_unarmed" and
    mageDesired[2] == "wo_magic_grimoire" and mageDesired[3] == "weapon_hpwr_stick" and
    #warriorDesired == 1 and warriorDesired[1] == "drc_unarmed" and mageHasKnifeItem and
    WO.Classes.IsWeaponAllowed("mage", "dagger"),
    "маг получает новый spellbook и legacy wand для отката, нож остаётся инвентарным предметом")

local migrationPlayer = MOCK.NewEntity("player")
local migrationChar = WO.Character.New({
    id = "starter-knife-migration-test", name = "Миграция", surname = "Тест",
    class = "warrior",
})
migrationPlayer:SetCharacter(migrationChar)
local migrationContainer = WO.Inventory.GetContainer(migrationChar)
MOCK.Assert(WO.Equipment.MigrateStarterKnife(migrationChar, migrationPlayer) == true and
    migrationContainer:CountItem("starter_knife") == 1 and
    WO.Equipment.MigrateStarterKnife(migrationChar, migrationPlayer) == false and
    migrationContainer:CountItem("starter_knife") == 1,
    "legacy loadout мигрируется в один сохраняемый нож без повторной выдачи")
local migrationEquipmentData = WO.Equipment.Get(migrationChar):Serialize()
local restoredMigrationEquipment = WO.Equipment.Deserialize(migrationEquipmentData)
MOCK.Assert(restoredMigrationEquipment.starterKnifeMigrationApplied == true,
    "флаг миграции starter knife переживает сериализацию экипировки")
WO.SaveQueue.Clear(migrationChar)

local badLoadedCharacter, badModelWarnings = WO.Character.SanitizeLoaded({
    id = "bad-model-test", name = "Тест", surname = "Модели", age = 25,
    race = "human", gender = "male", class = "warrior",
    model = "models/player/group01/male_01.mdl", customization = {},
})
MOCK.Assert(badLoadedCharacter == nil and table.HasValue(badModelWarnings, "model_unavailable"),
    "сохранённая гражданская модель отклоняется без fallback")

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

sam = previousSAM
WO.Admin.RegisteredSAMPermissions = nil
WO.Admin.SAMReady = nil

print("[scenario] load OK: plugins=" .. table.Count(WO.Plugins.GetAll()) ..
    " races=" .. #WO.Races.GetIDs() .. " items=" .. table.Count(WO.Items.GetAll()))

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

print("[scenario] create OK: " .. char:GetFullName() .. " lvl " .. char:GetLevel())

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
    WO.Inventory.GetContainer(char):CountItem("starter_knife") == 1,
    "стартовый нож сохраняется один раз в инвентаре до явного экипирования")

print("[scenario] existing character selection OK")

---------------------------------------------------------------------------
-- 5. Стартовые предметы, инвентарь, валюта
---------------------------------------------------------------------------

local inv = WO.Inventory.GetContainer(char)

MOCK.Assert(inv ~= nil, "контейнер инвентаря существует")

local itemCount = 0

for _ in pairs(inv.items or {}) do
    itemCount = itemCount + 1
end

MOCK.Assert(itemCount > 0, "стартовые предметы выданы: " .. itemCount)

local mainHand = WO.Equipment.Get(char):Get("main_hand")
local equippedHands = ply:GetWeapon("drc_unarmed")
local starterKnifeUID

for uid, instance in pairs(inv.items) do
    if instance.class == "starter_knife" then
        starterKnifeUID = uid
        break
    end
end

MOCK.Assert(mainHand == nil and not IsValid(ply:GetWeapon("tfa_cso_coldsteelblade")) and
    IsValid(equippedHands) and equippedHands.WOStarterLoadout == true and
    ply:GetActiveWeapon() == equippedHands and starterKnifeUID ~= nil,
    "воин появляется с обычными руками, а точный нож остаётся предметом в инвентаре")

MOCK.TakeOutbox()
MOCK.Assert(WO.Equipment.Equip(ply, starterKnifeUID) == true,
    "использование предмета экипирует стартовый нож")
local equipOutbox = MOCK.TakeOutbox()
local equippedKnife = ply:GetWeapon("tfa_cso_coldsteelblade")
mainHand = WO.Equipment.Get(char):Get("main_hand")
MOCK.Assert(mainHand and mainHand.uid == starterKnifeUID and
    IsValid(equippedKnife) and equippedKnife.WOItemUID == starterKnifeUID and
    ply:GetActiveWeapon() == equippedKnife and inv:CountItem("starter_knife") == 0 and
    #MOCK.FindInbox(equipOutbox, "Inventory.Sync") >= 1,
    "нож появляется/выбирается только после equip, а инвентарь синхронизирован")

MOCK.TakeOutbox()
MOCK.Assert(WO.Equipment.Unequip(ply, "main_hand") == true,
    "нож можно снять обратно")
local unequipOutbox = MOCK.TakeOutbox()
MOCK.Assert(not IsValid(ply:GetWeapon("tfa_cso_coldsteelblade")) and
    IsValid(ply:GetWeapon("drc_unarmed")) and ply:GetActiveWeapon() == ply:GetWeapon("drc_unarmed") and
    inv:CountItem("starter_knife") == 1 and
    WO.Equipment.Get(char):Get("main_hand") == nil and
    #MOCK.FindInbox(unequipOutbox, "Inventory.Sync") >= 1,
    "снятый нож возвращается в инвентарь с тем же UID и немедленной синхронизацией")

local magePlayer = MOCK.NewEntity("player")
local mageCharacter = WO.Character.New({ id = "mage-loadout-test", class = "mage" })
magePlayer:SetCharacter(mageCharacter)
local magePrimary = WO.Loadout.Apply(magePlayer, mageCharacter)

MOCK.Assert(magePrimary == "wo_magic_grimoire" and
    magePlayer:HasWeapon("drc_unarmed") and
    not magePlayer:HasWeapon("tfa_cso_coldsteelblade") and
    magePlayer:HasWeapon("wo_magic_grimoire") and
    magePlayer:HasWeapon("weapon_hpwr_stick") and
    magePlayer:GetWeapon("wo_magic_grimoire").WOItemUID == nil and
    magePlayer:GetWeapon("weapon_hpwr_stick").WOItemUID == nil,
    "маг получает новый grimoire и сохраняет старый wand для безопасного отката, но не нож")

MOCK.Assert(WO.Spells.PointsAvailable(mageCharacter) == 1 and
    WO.Spells.LearnOrUpgrade(magePlayer, "healing_wave") == true and
    WO.Spells.GetRank(mageCharacter, "healing_wave") == 1 and
    WO.Spells.Select(magePlayer, "healing_wave") == true,
    "маг изучает и выбирает заклинание за доступное очко уровня")
local noSpellPoints, noSpellPointsReason = WO.Spells.LearnOrUpgrade(magePlayer, "firebolt")
MOCK.Assert(noSpellPoints == false and noSpellPointsReason == "no_points",
    "сервер не выдаёт spell ranks сверх доступных очков")
MOCK.TakeOutbox()
WO.Spells.Sync(magePlayer)
local spellSyncOutbox = MOCK.TakeOutbox()
local spellPayloads = MOCK.FindInbox(spellSyncOutbox, "Spell.Sync")
MOCK.Assert(#spellPayloads == 1 and spellPayloads[1].args[1].ranks.healing_wave == 1 and
    spellPayloads[1].args[1].selected == "healing_wave" and
    spellPayloads[1].args[1].points == 0,
    "spellbook синхронизируется собственным payload, не CharacterSync")
WO.Hook.Run("CharacterSave", mageCharacter)
local savedAbilityRows = WO.Database:Fetch(
    "SELECT data FROM wo_abilities WHERE owner_id = ? AND ability_id = ?",
    mageCharacter.id, "spellbook")
local savedBook = savedAbilityRows[1] and util.JSONToTable(savedAbilityRows[1].data or "")
local reloadedMage = WO.Character.New({ id = mageCharacter.id, class = "mage", level = 1 })
WO.Hook.Run("CharacterLoad", reloadedMage)
MOCK.Assert(savedBook and savedBook.ranks.healing_wave == 1 and savedBook.selected == "healing_wave" and
    WO.Spells.GetRank(reloadedMage, "healing_wave") == 1 and
    WO.Spells.GetSelected(reloadedMage) == "healing_wave",
    "ранг и выбор заклинания сохраняются в plugin persistence и переживают reload персонажа")

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
mageCharacter.level = 2
MOCK.Assert(WO.Spells.LearnOrUpgrade(magePlayer, "firebolt") == true,
    "повышение уровня открывает новое очко для следующего spell")
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

local hpBefore = dummy:Health()
local combatInfo = {
    amount = 15,
    type = WO.Enums.DamageType.PHYSICAL,
    canCrit = false,
}

WO.Combat.Damage(ply, dummy, combatInfo)

MOCK.Assert(combatInfo.critical == false,
    "canCrit=false отключает повторный critical roll в общем damage pipeline")
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
MOCK.Assert(WO.Inventory.GetContainer(restored):CountItem("starter_knife") == 1,
    "повтор сохранения не дублирует предмет ножа в инвентаре")

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

MOCK.Assert(#WO.NPCs.Spawned == 4, "четыре статических NPC заспавнены: " .. #WO.NPCs.Spawned)

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

MOCK.Assert(marshal and marla and hunter and mountVendor and
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
    hunter.npcDef.quests[2] == "wolves_of_elwynn" and
    hunter.__useType == SIMPLE_USE and marshal.__useType == SIMPLE_USE and
    marla.__useType == SIMPLE_USE and mountVendor.__useType == SIMPLE_USE,
    "охотник предлагает кабанов перед волками, все interact NPC используют SIMPLE_USE")
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
MOCK.NetDeliver({ name = "Dialogue.Choose", args = { "marshal_intro", "start", 1 } }, 8, ply)
MOCK.NetDeliver({ name = "Dialogue.Choose", args = { "marshal_intro", "supplies", 1 } }, 8, ply)
local suppliesQuest = ply:GetCharacter().quests["supplies_for_the_road"]
MOCK.Assert(suppliesQuest and suppliesQuest.status == "active" and suppliesQuest.progress[1] == 3,
    "хлебный сбор готов отдельно, но требует физической сдачи")
MOCK.NetDeliver({ name = "Dialogue.Choose", args = { "marshal_intro", "supplies", 1 } }, 8, ply)
MOCK.Assert(suppliesQuest.status == "completed" and
    breadContainer:CountItem("bread") == breadBeforeTurnIn - 3 and
    WO.Currency.Get(ply) == moneyBeforeSupplies + 60 and
    ply:GetCharacter().quests["boar_hunt"] == nil,
    "хлеб сдаётся независимо от обязательной охотничьей цепочки")

-- Торговец покупает низкоуровневый хлам, но не принимает хлеб обратно.
ply:SetPos(marla:GetPos())
marla:Use(ply, ply)
MOCK.NetDeliver({ name = "Dialogue.Choose", args = { "trader_marla", "start", 2 } }, 8, ply)
MOCK.NetDeliver({ name = "Dialogue.Choose", args = { "trader_marla", "work", 1 } }, 8, ply)
MOCK.Assert(ply:GetCharacter().quests["meet_the_trader"] and
    ply:GetCharacter().quests["meet_the_trader"].status == "completed",
    "диалоговый talk-квест торговца завершается по факту разговора")
marla:Use(ply, ply)
MOCK.NetDeliver({ name = "Dialogue.Choose", args = { "trader_marla", "start", 1 } }, 8, ply)
local vendorMoneyBefore = WO.Currency.Get(ply)
MOCK.NetDeliver({ name = "Vendor.Buy", args = { "trader_marla", "health_potion", 2 } }, 8, ply)
MOCK.Assert(WO.Currency.Get(ply) == vendorMoneyBefore - 50,
    "покупка у торговца валидирует stock и списывает серверную цену")
MOCK.Assert(WO.Vendors.GetSellPrice(marla.npcDef, "bread") == nil and
    WO.Inventory.GiveItem(ply, "boar_tusk", 1) == true,
    "торговец покупает только заданные низкоуровневые материалы, не обычный хлеб")
local tuskUID
for uid, instance in pairs(WO.Inventory.GetContainer(ply:GetCharacter()):GetItems()) do
    if instance.class == "boar_tusk" then tuskUID = uid break end
end
local junkMoneyBefore = WO.Currency.Get(ply)
MOCK.Assert(tuskUID and WO.Vendors.Sell(ply, "trader_marla", tuskUID, 1) == true and
    WO.Currency.Get(ply) > junkMoneyBefore,
    "низкоуровневый трофей продаётся за серверную цену торговцу")
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

-- Охотник выдаёт только первое звено: стартовый нож должен быть экипирован,
-- затем убиваются четыре внешних wow_npc_2809 и отчёт сдаётся маршалу.
hunter:Use(ply, ply)
MOCK.NetDeliver({ name = "Dialogue.Choose", args = { "hunter_intro", "start", 2 } }, 8, ply)
MOCK.Assert(char.quests["wolves_of_elwynn"] == nil,
    "охотник не принимает волчий квест до сдачи охоты на кабанов")
local earlyWolves, earlyWolvesReason = WO.Quests.Accept(
    ply, "wolves_of_elwynn", hunter.npcDef, hunter)
MOCK.Assert(earlyWolves == false and earlyWolvesReason == "prerequisites",
    "сервер блокирует волков до prerequisite даже при валидной сессии охотника")
MOCK.NetDeliver({ name = "Dialogue.Choose", args = { "hunter_intro", "start", 1 } }, 8, ply)

local boarQuest = char.quests["boar_hunt"]
local activeBoars = FindNPCs("elwynn_boar")
MOCK.Assert(boarQuest and boarQuest.status == "active" and #activeBoars == 4 and
    #FindNPCs("black_wolf") == 0,
    "принятие первого задания создаёт ровно четыре кабана и ни одного волка")
local knifeUID
for uid, instance in pairs(WO.Inventory.GetContainer(char):GetItems()) do
    if instance.class == "starter_knife" then knifeUID = uid break end
end
MOCK.Assert(knifeUID and WO.Equipment.Equip(ply, knifeUID) == true and
    boarQuest.progress[1] == 1,
    "экипировка сохранённого starter_knife выполняет обязательный первый шаг")
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

for _, boar in ipairs(activeBoars) do
    boar:SetHealth(0)
    WO.NPCs.HandleKilled(boar, ply)
    boar:Remove() -- the external engine NPC is removed after its native death/corpse hook
end
math.random = originalRandom

MOCK.Assert(boarQuest.status == "active" and boarQuest.progress[2] == 4 and
    #FindNPCs("elwynn_boar") == 0,
    "четыре кабана завершают прогресс, но не закрывают квест без отчёта маршалу")
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
MOCK.Assert(WO.World.PickupItem(ply, lootItem) == true and
    WO.Inventory.GetContainer(char):CountItem(lootedClass) > 0 and
    WO.World.PickupItem(ply, lootItem) == false,
    "физическая добыча подбирается только один раз")
local coinPile
for _, ent in ipairs(ents.GetAll()) do
    if ent:GetClass() == "wo_coin_pile" then coinPile = ent break end
end
MOCK.Assert(IsValid(coinPile), "монеты представлены отдельной физической кучкой")
ply:SetPos(coinPile:GetPos())
coinPile.PickupCooldown = 0
local moneyBeforeCoinPickup = WO.Currency.Get(ply)
MOCK.Assert(WO.World.PickupCoins(ply, coinPile) == true and
    WO.Currency.Get(ply) > moneyBeforeCoinPickup and
    WO.World.PickupCoins(ply, coinPile) == false,
    "физические монеты зачисляются ровно один раз")

-- Завершённый по шагам квест всё ещё требует реального возврата к marshal.
ply:SetPos(marshal:GetPos())
marshal:Use(ply, ply)
MOCK.NetDeliver({ name = "Dialogue.Choose", args = { "marshal_intro", "start", 3 } }, 8, ply)
MOCK.Assert(boarQuest.status == "completed" and char.quests["wolves_of_elwynn"] == nil,
    "сдача отчёта marshal завершает кабаний квест, не обходит его prerequisite")

-- Только после отчёта охотник принимает отдельный wolf assignment на marshal's просьбу.
ply:SetPos(hunter:GetPos())
hunter:Use(ply, ply)
MOCK.NetDeliver({ name = "Dialogue.Choose", args = { "hunter_intro", "start", 2 } }, 8, ply)
local wolfQuest = char.quests["wolves_of_elwynn"]
local activeWolves = FindNPCs("black_wolf")
MOCK.Assert(wolfQuest and wolfQuest.status == "active" and #activeWolves == 4 and
    #FindNPCs("elwynn_boar") == 0,
    "после prerequisites появляются ровно четыре custom direwolf")

local sequences = {
    "attackunarmed", "combatcritical", "combatwound", "death", "fall", "jump",
    "jumpend", "jumpstart", "mountspecial", "run", "shuffleleft", "shuffleright",
    "stand", "stand_v1", "stand_v2", "swim", "swimidle", "walk", "walkbackwards",
}
local wolf = activeWolves[1]
local seenSequences = {}
for _, sequence in ipairs(wolf.WORequestedSequences or {}) do seenSequences[sequence] = true end
for _, sequence in ipairs(sequences) do
    MOCK.Assert(seenSequences[sequence] == true, "direwolf поддерживает требуемую анимацию " .. sequence)
end
MOCK.Assert(wolf:GetClass() == "wo_wolf" and
    wolf:GetModel() == "models/wow_monsters/direwolf.mdl" and
    wolf.npcDef.workshopClass == nil and WO.Workshop.HasNPCClass("wow_npc_14892") == false,
    "старый внешний wolf class заменён точной custom direwolf моделью")
for index, ent in ipairs(activeWolves) do
    local point = wolfSpawnPoints[index]
    MOCK.Assert(ent.WO_NPCLevel == point.level and ent:GetPos().x == point.pos.x and
        ent:GetPos().y == point.pos.y and ent:GetPos().z == point.pos.z,
        "волк " .. index .. " имеет уровень и свою отдельную фиксированную точку")
end
ply:SetPos(wolf:GetPos() + Vector(12, 0, 0))
MOCK.Assert(wolf:FindTarget() == ply,
    "custom direwolf обнаруживает ближайшего живого игрока с персонажем")

local coinsBeforeDeath, itemsBeforeDeath = CountLoot()
local damageInfo = {
    GetDamage = function() return 10000 end,
    GetAttacker = function() return ply end,
}
wolf:OnTakeDamage(damageInfo)
local afterFirstWolfCoins, afterFirstWolfItems = CountLoot()
MOCK.Assert(wolf.WO_Dead == true and wolf.WO_NPCKillEventSent == true and
    afterFirstWolfCoins > coinsBeforeDeath and afterFirstWolfItems > itemsBeforeDeath and
    wolfQuest.progress[1] == 1,
    "смерть custom wolf запускает серверный kill progress и физический loot")
local dropsAfterDeath = afterFirstWolfCoins + afterFirstWolfItems
hook.Run("OnNPCKilled", wolf, ply)
local duplicateCoins, duplicateItems = CountLoot()
MOCK.Assert(duplicateCoins + duplicateItems == dropsAfterDeath and wolfQuest.progress[1] == 1,
    "повторный engine death hook не дублирует добычу или прогресс")

for index = 2, #activeWolves do
    local target = activeWolves[index]
    target:SetHealth(1)
    target:OnTakeDamage({
        GetDamage = function() return 10000 end,
        GetAttacker = function() return ply end,
    })
end
MOCK.RunTimers(1.0) -- death animations and the fixed-point quest group cleanup
MOCK.Assert(wolfQuest.status == "active" and wolfQuest.progress[1] == 4 and
    #FindNPCs("black_wolf") == 0,
    "четыре волка дают готовность, не завершая ручной turn-in")
ply:SetPos(marshal:GetPos())
marshal:Use(ply, ply)
MOCK.NetDeliver({ name = "Dialogue.Choose", args = { "marshal_intro", "start", 4 } }, 8, ply)
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
