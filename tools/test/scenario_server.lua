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
}

-- Runtime registry имитирует только точные заявленные внешние NPC/SWEP классы.
scripted_ents.Register({}, "wow_npc_14892")
scripted_ents.Register({}, "wow_npc_2809")

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
MOCK.Assert(table.Count(WO.Plugins.GetAll()) == 27,
    "загружены все 27 plugin metadata: " .. table.Count(WO.Plugins.GetAll()))
MOCK.Assert(WO.Plugins.IsLoaded("character") and WO.Plugins.IsLoaded("hud"),
    "плагины персонажа и HUD загрузились")
MOCK.Assert(MOCK.clientFilesAdded["warcraftonline/gamemode/plugins/character/sh_plugin.lua"],
    "сервер отправил клиенту метаданные character через AddCSLuaFile")
local savedLocalPlayer = LocalPlayer
LocalPlayer = nil
local serverUUID = WO.Util.UUID()
LocalPlayer = savedLocalPlayer
MOCK.Assert(WO.Util.IsUUID(serverUUID), "UUID создаётся на сервере без LocalPlayer")
MOCK.Assert(WO.Races.GetIDs and #WO.Races.GetIDs() >= 4, "расы зарегистрированы: " ..
    (WO.Races.GetIDs and #WO.Races.GetIDs() or 0))
MOCK.Assert(WO.Classes.GetIDs and #WO.Classes.GetIDs() >= 4, "классы зарегистрированы")
MOCK.Assert(WO.Items.GetAll and table.Count(WO.Items.GetAll()) >= 12,
    "предметы зарегистрированы: " .. (WO.Items.GetAll and table.Count(WO.Items.GetAll()) or 0))
MOCK.Assert(WO.Models ~= nil and WO.Models.Catalog ~= nil, "каталог моделей Mailer на месте")
MOCK.Assert(WO.Plugins.IsLoaded("workshop") and WO.Workshop.ModelOr ~= nil,
    "Workshop adapter загружен отдельным плагином")
MOCK.Assert(WO.NPCs.Get("black_wolf").workshopClass == "wow_npc_14892" and
    WO.NPCs.Get("black_wolf").level == 1 and
    WO.NPCs.Get("black_wolf").maxLevel == 5 and
    WO.NPCs.Get("elwynn_boar").workshopClass == "wow_npc_2809" and
    WO.NPCs.Get("elwynn_boar").maxLevel == 5,
    "Fang и кабан используют точные внешние классы и уровни 1–5")
MOCK.Assert(WO.Workshop.HasNPCClass("wow_npc_14892") and
    WO.Workshop.HasNPCClass("wow_npc_2809"),
    "runtime registry подтверждает оба точных класса NPC")
MOCK.Assert(WO.NPCs.Get("trader_marla").model ==
    "models/mailer/character/human/female/humanfemale00_00.mdl",
    "торговец использует только mounted race model в тестовом runtime")

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
    desiredWeapons.mage == "weapon_hpwr_stick" and
    weapons.GetStored("drc_unarmed") and
    weapons.GetStored("tfa_cso_coldsteelblade") and
    weapons.GetStored("weapon_hpwr_stick"),
    "все три точных starter SWEP зарегистрированы в тестовом runtime")
MOCK.Assert(#mageDesired == 2 and mageDesired[1] == "drc_unarmed" and
    mageDesired[2] == "weapon_hpwr_stick" and #warriorDesired == 1 and
    warriorDesired[1] == "drc_unarmed" and mageHasKnifeItem and
    WO.Classes.IsWeaponAllowed("mage", "dagger"),
    "маг сохраняет прямой HPWR wand и получает нож-предмет; остальные начинают с обычных рук")

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

MOCK.Assert(magePrimary == "weapon_hpwr_stick" and
    magePlayer:HasWeapon("drc_unarmed") and
    not magePlayer:HasWeapon("tfa_cso_coldsteelblade") and
    magePlayer:HasWeapon("weapon_hpwr_stick") and
    magePlayer:GetWeapon("weapon_hpwr_stick").WOItemUID == nil,
    "маг сохраняет точный wand как loadout, но не получает нож")

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
MOCK.Assert(#wolfSpawnPoints == 7 and #boarSpawnPoints == 7 and
    wolfSpawnPoints[1].map == "gm_construct" and wolfSpawnPoints[1].questId == "wolves_of_elwynn" and
    boarSpawnPoints[1].map == "gm_construct" and boarSpawnPoints[1].questId == "boar_hunt",
    "точные 7+7 spawn-точек привязаны к карте и своим квестам")

-- Статические квестодатели появляются на своей карте; животные до принятия
-- задания не создаются.
WO.NPCs.SpawnAll()

MOCK.Assert(#WO.NPCs.Spawned >= 3, "статические NPC заспавнены: " .. #WO.NPCs.Spawned)

local function FindNPC(id)
    for _, ent in ipairs(WO.NPCs.Spawned) do
        if IsValid(ent) and ent.npcDef and ent.npcDef.id == id then
            return ent
        end
    end

    return nil
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

local marshal = FindNPC("marshal_dughal")
local marla = FindNPC("trader_marla")
local hunter = FindNPC("hunter_dyrne")

MOCK.Assert(marshal ~= nil, "marshal_dughal заспавнен")
MOCK.Assert(marla ~= nil, "trader_marla заспавнен")
MOCK.Assert(hunter ~= nil and hunter.npcDef.quests[1] == "wolves_of_elwynn" and
    hunter.npcDef.quests[2] == "boar_hunt",
    "hunter_dyrne выдаёт оба охотничьих задания")
MOCK.Assert(#FindNPCs("black_wolf") == 0 and #FindNPCs("elwynn_boar") == 0,
    "волки и кабаны не появляются до принятия соответствующих квестов")
MOCK.Assert(math.abs(marshal:GetPos().x - 1034.032104) < 0.01 and
    math.abs(marla:GetPos().x - 241.648193) < 0.01 and
    math.abs(hunter:GetPos().x - 1311.738403) < 0.01,
    "маршал, торговка и охотник используют точки хаба на gm_construct")
MOCK.Assert(marshal.__useType == SIMPLE_USE and marla.__useType == SIMPLE_USE and
    hunter.__useType == SIMPLE_USE,
    "диалоговые/квестовые NPC используют SIMPLE_USE")
MOCK.Assert(WO.Interaction.GetRange(marla) == WO.Config.InteractDistance,
    "клиентская подсказка и серверный Use согласованы по диапазону")
for level = 1, 5 do
    local wolfStats = WO.NPCs.GetLevelStats(WO.NPCs.Get("black_wolf"), level)
    local boarStats = WO.NPCs.GetLevelStats(WO.NPCs.Get("elwynn_boar"), level)
    MOCK.Assert(wolfStats and boarStats and wolfStats.health > 0 and boarStats.health > 0,
        "wolf/boar имеют серверные характеристики уровня " .. level)
    if level > 1 then
        MOCK.Assert(wolfStats.health > WO.NPCs.GetLevelStats(WO.NPCs.Get("black_wolf"), level - 1).health and
            boarStats.health > WO.NPCs.GetLevelStats(WO.NPCs.Get("elwynn_boar"), level - 1).health,
            "сложность обоих существ растёт к уровню " .. level)
    end
end

MOCK.Assert(WO.Models ~= nil, "каталог моделей доступен")

-- Use/клавиша E за пределами общей дальности не открывает диалог.
ply:SetPos(marshal:GetPos() + Vector(WO.Config.InteractDistance + 1, 0, 0))
local farInteraction = WO.Interaction.TryInteract(ply, marshal)
MOCK.Assert(farInteraction == false, "сервер отклоняет Use за пределами настроенной дистанции")
MOCK.Assert(WO.Quests.OfferFromDialogue(ply, "wolves_of_elwynn", marshal.npcDef, marshal) == false and
    ply:GetCharacter().quests["wolves_of_elwynn"] == nil,
    "quest offer не принимается через поддельный/дальний NPC interaction")

-- Диалог с маршалом: E → узел → квест collect (хлеб уже в инвентаре → сразу завершается)
ply:SetPos(marshal:GetPos())
marshal:Use(ply, ply)

local dialogueOut = MOCK.TakeOutbox()
MOCK.Assert(#MOCK.FindInbox(dialogueOut, "Dialogue.Open") >= 1, "E открывает диалог")

-- Даже действительный индекс ответа не работает после ухода за пределы дальности.
ply:SetPos(marshal:GetPos() + Vector(WO.Config.InteractDistance + 1, 0, 0))
MOCK.NetDeliver({ name = "Dialogue.Choose", args = { "marshal_intro", "start", 2 } }, 8, ply)
MOCK.Assert(ply.wo_dialogue == nil and ply:GetCharacter().quests["supplies_for_the_road"] == nil,
    "сервер закрывает просроченную dialogue session при удалении игрока")

ply:SetPos(marshal:GetPos())
marshal:Use(ply, ply)
MOCK.TakeOutbox()

MOCK.Assert(#MOCK.FindInbox(dialogueOut, "Dialogue.Open") >= 1, "диалог открыт")

MOCK.NetDeliver({ name = "Dialogue.Choose", args = { "marshal_intro", "start", 2 } }, 8, ply)
MOCK.NetDeliver({ name = "Dialogue.Choose", args = { "marshal_intro", "supplies", 1 } }, 8, ply)

local supplies = ply:GetCharacter().quests and ply:GetCharacter().quests["supplies_for_the_road"]

MOCK.Assert(supplies ~= nil, "квест принят")
MOCK.Assert(supplies.status == "completed", "collect-квест завершён сразу: " .. tostring(supplies.status))
MOCK.Assert(WO.Currency.Get(ply) == 160, "награда деньгами: " .. WO.Currency.Get(ply))

print("[scenario] dialogue/collect quest OK")

-- Квест talk через диалог торговки + открытие торговли из диалога
ply:SetPos(marla:GetPos())
marla:Use(ply, ply)

MOCK.NetDeliver({ name = "Dialogue.Choose", args = { "trader_marla", "start", 2 } }, 8, ply)   -- узел work
MOCK.NetDeliver({ name = "Dialogue.Choose", args = { "trader_marla", "work", 1 } }, 8, ply)     -- quest:meet_the_trader

local talkQuest = ply:GetCharacter().quests and ply:GetCharacter().quests["meet_the_trader"]

MOCK.Assert(talkQuest ~= nil and talkQuest.status == "completed", "talk-квест завершён: " ..
    (talkQuest and talkQuest.status or "nil"))

print("[scenario] talk quest OK")

-- Торговля: действие vendor из диалога → проверка сессии/дистанции → покупка → продажа
marla:Use(ply, ply)
MOCK.NetDeliver({ name = "Dialogue.Choose", args = { "trader_marla", "start", 1 } }, 8, ply)   -- action vendor

local moneyBeforeInvalidBuy = WO.Currency.Get(ply)
ply:SetPos(marla:GetPos() + Vector(WO.Config.InteractDistance + 1, 0, 0))
local invalidBuy = WO.Vendors.Buy(ply, "trader_marla", "health_potion", 1)
MOCK.Assert(invalidBuy == false and WO.Currency.Get(ply) == moneyBeforeInvalidBuy and
    ply.wo_vendor == nil,
    "серверная торговая сессия закрывается и не списывает деньги при превышении дистанции")

ply:SetPos(marla:GetPos())
marla:Use(ply, ply)
MOCK.NetDeliver({ name = "Dialogue.Choose", args = { "trader_marla", "start", 1 } }, 8, ply)
local moneyBeforeBuy = WO.Currency.Get(ply)

MOCK.NetDeliver({ name = "Vendor.Buy", args = { "trader_marla", "health_potion", 2 } }, 8, ply)

MOCK.Assert(WO.Currency.Get(ply) == moneyBeforeBuy - 50, "покупка списала деньги: " ..
    WO.Currency.Get(ply) .. " (было " .. moneyBeforeBuy .. ")")

-- Продаём одну буханку
local container = WO.Inventory.GetContainer(ply:GetCharacter())
local sellUid, sellInstance = nil, nil

for uid, instance in pairs(container.items) do
    if instance.class == "bread" then
        sellUid, sellInstance = uid, instance
        break
    end
end

MOCK.Assert(sellUid ~= nil, "есть предмет для продажи")

local moneyBeforeSell = WO.Currency.Get(ply)

MOCK.NetDeliver({ name = "Vendor.Sell", args = { "trader_marla", sellUid, 1 } }, 8, ply)

MOCK.Assert(WO.Currency.Get(ply) > moneyBeforeSell, "продажа принесла деньги: " ..
    WO.Currency.Get(ply) .. " (было " .. moneyBeforeSell .. ")")

print("[scenario] vendor OK")

-- Quest.Accept — внутренний server API: прямой net-вызов без проверенного NPC
-- не должен выдавать задание, даже если игрок знает questId.
ply:SetPos(hunter:GetPos())
MOCK.NetDeliver({ name = "Quest.Accept", args = { "wolves_of_elwynn" } }, 8, ply)
MOCK.Assert(ply:GetCharacter().quests["wolves_of_elwynn"] == nil and
    ply:GetCharacter().quests["boar_hunt"] == nil,
    "клиент не может принять квест прямым Quest.Accept без server-side NPC interaction")

-- Hunter выдаёт wolf kill-квест первым: появляется только его группа из семи Fang.
MOCK.TakeOutbox()
hunter:Use(ply, ply)
local acceptQuest = ply:GetCharacter().quests["wolves_of_elwynn"]

MOCK.Assert(acceptQuest and acceptQuest.status == "active" and
    ply:GetCharacter().quests["boar_hunt"] == nil,
    "принятие wolf quest через hunter_dyrne создаёт только волчью цель")

local activeWolves = FindNPCs("black_wolf")
MOCK.Assert(#activeWolves == 7 and #FindNPCs("elwynn_boar") == 0,
    "после принятия wolf quest появляются 7 Fang, но не кабаны")
local earlyBoarAccept, earlyBoarReason = WO.Quests.Accept(
    ply, "boar_hunt", hunter.npcDef, hunter)
MOCK.Assert(earlyBoarAccept == false and earlyBoarReason == "prerequisites" and
    ply:GetCharacter().quests["boar_hunt"] == nil,
    "boar quest заблокирован до завершения волчьего задания даже при валидном NPC")
for _, wolf in ipairs(activeWolves) do
    MOCK.Assert(wolf:GetClass() == "wow_npc_14892" and
        wolf.WO_NPCLevel >= 1 and wolf.WO_NPCLevel <= 5,
        "каждая цель сохраняет точный Fang class и уровень 1–5")
end

-- Проверяем engine death bridge, дедупликацию и прогресс всех семи целей.
local lastWolf
for index, wolf in ipairs(activeWolves) do
    lastWolf = wolf
    wolf:SetHealth(1)
    hook.Run("OnNPCKilled", wolf, ply)

    if index == 1 then
        hook.Run("OnNPCKilled", wolf, ply) -- duplicate event must be ignored
    end

    wolf:SetHealth(0)
    hook.Run("PostEntityTakeDamage", wolf, {
        GetAttacker = function() return ply end,
    }, true) -- duplicate generic SENT event must also be ignored

    if index == 1 then
        MOCK.RunTimers(0)
        MOCK.Assert(#FindNPCs("black_wolf") == 7,
            "убитый Fang восстанавливается в своей фиксированной точке, пока квест активен")
    end
end

local wolfQuest = ply:GetCharacter().quests["wolves_of_elwynn"]
MOCK.Assert(wolfQuest.status == "completed" and wolfQuest.progress[1] == 7 and
    lastWolf.WO_NPCKillEventSent == true and #FindNPCs("black_wolf") == 0,
    "семь уникальных Fang завершают квест один раз, после чего группа удаляется")

-- Охотник выдаёт отдельное кабанье задание; группа появляется только тогда.
ply:SetPos(hunter:GetPos())
MOCK.TakeOutbox()
hunter:Use(ply, ply)
local boarQuest = ply:GetCharacter().quests["boar_hunt"]
local activeBoars = FindNPCs("elwynn_boar")
MOCK.Assert(boarQuest and boarQuest.status == "active" and #activeBoars == 7 and
    #FindNPCs("black_wolf") == 0,
    "принятие задания у hunter_dyrne создаёт только семь кабанов")
for _, boar in ipairs(activeBoars) do
    MOCK.Assert(boar:GetClass() == "wow_npc_2809" and
        boar.WO_NPCLevel >= 1 and boar.WO_NPCLevel <= 5,
        "каждая кабанья цель сохраняет точный wow_npc_2809 class и уровень 1–5")
end
MOCK.Assert(WO.Quests.Abandon(ply, "boar_hunt") == true and
    #FindNPCs("elwynn_boar") == 0,
    "отказ от кабаньего задания удаляет оставшуюся quest-linked группу")

print("[scenario] quest-gated Fang/boar spawns / exact starter loadout / server death hook OK")

---------------------------------------------------------------------------
-- 9. Выход
---------------------------------------------------------------------------

hook.Run("PlayerDisconnected", ply)
MOCK.RunTimers(1)

print("[scenario] ALL SERVER TESTS PASSED")
