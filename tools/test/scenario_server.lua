--[[
    scenario_server.lua — серверный smoke-тест Warcraft Online.
    Загружает гейммод (init.lua) через моки GMod API и прогоняет:
    загрузку → вход игрока → создание персонажа → инвентарь/валюта/опыт →
    бой → сохранение/перезагрузку → выход.
]]

local MOCK = MOCK

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
MOCK.Assert(table.Count(WO.Plugins.GetAll()) == 24,
    "загружены все 24 plugin metadata: " .. table.Count(WO.Plugins.GetAll()))
MOCK.Assert(WO.Plugins.IsLoaded("character") and WO.Plugins.IsLoaded("hud"),
    "плагины персонажа и HUD загрузились")
MOCK.Assert(MOCK.clientFilesAdded["warcraftonline/gamemode/plugins/character/sh_plugin.lua"],
    "сервер отправил клиенту метаданные character через AddCSLuaFile")
MOCK.Assert(WO.Races.GetIDs and #WO.Races.GetIDs() >= 4, "расы зарегистрированы: " ..
    (WO.Races.GetIDs and #WO.Races.GetIDs() or 0))
MOCK.Assert(WO.Classes.GetIDs and #WO.Classes.GetIDs() >= 4, "классы зарегистрированы")
MOCK.Assert(WO.Items.GetAll and table.Count(WO.Items.GetAll()) >= 10, "предметы зарегистрированы: " ..
    (WO.Items.GetAll and table.Count(WO.Items.GetAll()) or 0))
MOCK.Assert(WO.Models ~= nil and WO.Models.Catalog ~= nil, "каталог моделей Mailer на месте")

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
MOCK.Assert(#MOCK.FindInbox(outbox, "Character.OpenCreate") >= 1, "Character.OpenCreate отправлен")

print("[scenario] join OK: OpenCreate доставлен")

---------------------------------------------------------------------------
-- 3. Хендшейк Client.Ready
---------------------------------------------------------------------------

MOCK.NetDeliver({ name = "Client.Ready", args = {} }, 8, ply)
MOCK.RunTimers(0.1)

outbox = MOCK.TakeOutbox()
MOCK.Assert(#MOCK.FindInbox(outbox, "Character.OpenCreate") >= 1, "SendState по Client.Ready")

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

MOCK.NetDeliver({ name = "Character.Create", args = { createData } }, 8, ply)
MOCK.RunTimers(1)

local char = ply:GetCharacter()

MOCK.Assert(char ~= nil, "персонаж создан и выбран")
MOCK.Assert(char.name == "Тест", "имя сохранено: " .. tostring(char.name))
MOCK.Assert(char.race == "human" and char.class == "warrior", "раса/класс сохранены")
MOCK.Assert(char.model == models[1], "модель сохранена")
MOCK.Assert(ply:HasCharacter(), "HasCharacter() == true")

print("[scenario] create OK: " .. char:GetFullName() .. " lvl " .. char:GetLevel())

-- Повторный вход: сервер должен открыть список сохранённых персонажей, а не создать дубликат.
local savedCharID = char.id

MOCK.TakeOutbox()
WO.Character.Unload(ply)
WO.Character.SendState(ply)
outbox = MOCK.TakeOutbox()

MOCK.Assert(#MOCK.FindInbox(outbox, "Character.List") >= 1,
    "при повторном входе сервер отправляет список персонажей")
MOCK.Assert(#MOCK.FindInbox(outbox, "Character.OpenSelect") >= 1,
    "при повторном входе сервер открывает выбор существующего персонажа")
MOCK.Assert(WO.Character.Select(ply, savedCharID), "загрузка сохранённого персонажа")
char = ply:GetCharacter()
MOCK.Assert(char and char.id == savedCharID, "загружен тот же персонаж без дубликата")

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

WO.Combat.Damage(ply, dummy, {
    amount = 15,
    damageType = "physical",
    canCrit = false,
})

print("[scenario] combat OK: pipeline executed (hp " .. tostring(hpBefore) .. ")")

---------------------------------------------------------------------------
-- 8. Сохранение / выгрузка / загрузка
---------------------------------------------------------------------------

local charId = char.id
local moneyBefore = WO.Currency.Get(ply)
local levelBefore = char:GetLevel()

MOCK.Assert(WO.SaveQueue.SaveNow(char) ~= false, "SaveNow")

WO.Character.Unload(ply)

MOCK.Assert(ply:HasCharacter() == false, "персонаж выгружен")

WO.Character.Select(ply, charId)
MOCK.RunTimers(0.5)

local restored = ply:GetCharacter()

MOCK.Assert(restored ~= nil, "персонаж загружен обратно")
MOCK.Assert(restored.name == "Тест", "имя восстановлено")
MOCK.Assert(restored:GetLevel() == levelBefore, "уровень восстановлен")
MOCK.Assert(WO.Currency.Get(ply) == moneyBefore, "деньги восстановлены: " ..
    tostring(WO.Currency.Get(ply)) .. " == " .. tostring(moneyBefore))

print("[scenario] persistence OK")

---------------------------------------------------------------------------
-- 8b. NPC / диалоги / квесты / торговля
---------------------------------------------------------------------------

MOCK.Assert(#WO.NPCs.Spawned >= 3, "NPC заспавнены: " .. #WO.NPCs.Spawned)

local function FindNPC(id)
    for _, ent in ipairs(WO.NPCs.Spawned) do
        if IsValid(ent) and ent.npcDef and ent.npcDef.id == id then
            return ent
        end
    end

    return nil
end

local marshal = FindNPC("marshal_dughal")
local marla = FindNPC("trader_marla")
local wolfEnt = FindNPC("black_wolf")

MOCK.Assert(marshal ~= nil, "marshal_dughal заспавнен")
MOCK.Assert(marla ~= nil, "trader_marla заспавнен")
MOCK.Assert(wolfEnt ~= nil, "black_wolf заспавнен")
MOCK.Assert(WO.Models ~= nil, "каталог моделей доступен")

-- Диалог с маршалом: узел → квест collect (хлеб уже в инвентаре → завершится сразу)
ply:SetPos(marshal:GetPos())
marshal:Interact(ply)

local dialogueOut = MOCK.TakeOutbox()

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
marla:Interact(ply)

MOCK.NetDeliver({ name = "Dialogue.Choose", args = { "trader_marla", "start", 2 } }, 8, ply)   -- узел work
MOCK.NetDeliver({ name = "Dialogue.Choose", args = { "trader_marla", "work", 1 } }, 8, ply)     -- quest:meet_the_trader

local talkQuest = ply:GetCharacter().quests and ply:GetCharacter().quests["meet_the_trader"]

MOCK.Assert(talkQuest ~= nil and talkQuest.status == "completed", "talk-квест завершён: " ..
    (talkQuest and talkQuest.status or "nil"))

print("[scenario] talk quest OK")

-- Торговля: действие vendor из диалога → покупка → продажа
marla:Interact(ply)
MOCK.NetDeliver({ name = "Dialogue.Choose", args = { "trader_marla", "start", 1 } }, 8, ply)   -- action vendor

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

-- Kill-квест: принимаем и «убиваем» волков через хук NPCKilled
local acceptQuest = WO.Quests.Accept(ply, "wolves_of_elwynn")

MOCK.Assert(acceptQuest == true, "kill-квест принят")

for _ = 1, 3 do
    WO.Hook.Run("NPCKilled", WO.NPCs.Get("black_wolf"), ply)
end

local wolfQuest = ply:GetCharacter().quests["wolves_of_elwynn"]

MOCK.Assert(wolfQuest.status == "completed", "kill-квест завершён: " .. tostring(wolfQuest.status))

print("[scenario] kill quest OK")

---------------------------------------------------------------------------
-- 9. Выход
---------------------------------------------------------------------------

hook.Run("PlayerDisconnected", ply)
MOCK.RunTimers(1)

print("[scenario] ALL SERVER TESTS PASSED")
