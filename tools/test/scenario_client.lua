--[[
    scenario_client.lua — клиентский smoke-тест Warcraft Online.
    Загружает cl_init.lua и открывает экран создания персонажа,
    проверяя, что UI строится без ошибок.
]]

local MOCK = MOCK

local function FindLatestLiveFrame()
    for i = #MOCK.createdPanels, 1, -1 do
        local panel = MOCK.createdPanels[i]
        if rawget(panel, "__class") == "DFrame" and rawget(panel, "__removed") ~= true then
            return panel
        end
    end
end

print("[scenario] loading gamemode (client)...")

include("gamemodes/warcraftonline/gamemode/cl_init.lua")

hook.Run("Initialize")
MOCK.RunTimers(0.1)

MOCK.Assert(WO.Core.IsLoaded, "WO.Core.IsLoaded (client)")
MOCK.Assert(WO.UI.Scroll ~= nil, "WO.UI.Scroll существует")
MOCK.Assert(WO.UI.Button ~= nil, "WO.UI.Button существует")
MOCK.Assert(WO.UI.CreateCharacterModel ~= nil, "WO.UI.CreateCharacterModel существует")
MOCK.Assert(WO.UI.Colors ~= nil and WO.UI.Metrics ~= nil, "тема загружена")
MOCK.Assert(WO.CharacterUI ~= nil and WO.CharacterUI.OpenCreate ~= nil, "экран создания зарегистрирован")
MOCK.Assert(WO.Plugins.IsLoaded("character") and WO.Plugins.IsLoaded("hud"),
    "client загрузил плагины персонажа и HUD")
MOCK.Assert(WO.Races.GetIDs and #WO.Races.GetIDs() >= 4, "расы видны на клиенте")
MOCK.Assert(WO.Models ~= nil and WO.Models.GetRace ~= nil, "каталог моделей виден на клиенте")

print("[scenario] client load OK")

---------------------------------------------------------------------------
-- 1. Список персонажей приходит → событие
---------------------------------------------------------------------------

local listReceived = false

WO.Hook.Add("CharacterListReceived", "scenario", function(list)
    listReceived = true
    MOCK.Assert(istable(list), "список — таблица")
end)

-- Character.List: write = UInt(count) + поля записи (плоский список аргументов)
MOCK.NetDeliver({ name = "Character.List", args = { 0 } }, 8, nil)

MOCK.Assert(listReceived, "CharacterListReceived сработал")
MOCK.Assert(WO.Character.StateReceived == true, "StateReceived выставлен")

print("[scenario] Character.List OK")

---------------------------------------------------------------------------
-- 2. Главное меню: создать / загрузить / disconnect
---------------------------------------------------------------------------

local panelsBeforeMenu = #MOCK.createdPanels
MOCK.NetDeliver({ name = "Character.OpenMenu", args = {} }, 8, nil)

MOCK.Assert(WO.CharacterUI.CurrentScreen == "main", "открылось главное меню персонажей")
MOCK.Assert(#MOCK.createdPanels > panelsBeforeMenu, "главное меню создало UI")

local createButton = MOCK.FindPanelByText(WO.Lang:Get("character.menu.create"))
local loadButton = MOCK.FindPanelByText(WO.Lang:Get("character.menu.load"))
local exitButton = MOCK.FindPanelByText(WO.Lang:Get("character.menu.exit"))

MOCK.Assert(createButton ~= nil, "в главном меню есть кнопка создания")
MOCK.Assert(loadButton ~= nil and loadButton:IsEnabled() == false,
    "загрузка отключена, когда персонажей ещё нет")
MOCK.Assert(exitButton ~= nil, "в главном меню есть выход")

local mainFrame = FindLatestLiveFrame()
MOCK.Assert(mainFrame and mainFrame.OnKeyCodePressed, "главное меню обрабатывает Escape")
mainFrame:OnKeyCodePressed(KEY_ESCAPE)
MOCK.Assert(WO.CharacterUI.CurrentScreen == "main", "Escape не закрывает главное меню")

exitButton:DoClick()
MOCK.Assert(MOCK.consoleCommands[#MOCK.consoleCommands][1] == "disconnect",
    "кнопка выхода вызывает disconnect")

createButton:DoClick()
MOCK.Assert(WO.CharacterUI.CurrentScreen == "create", "кнопка создания открывает мастер")
MOCK.Assert(WO.CharacterUI.OpenCreate ~= nil, "OpenCreate доступна")

local rotateRightButton = MOCK.FindPanelByText(WO.Lang:Get("character.rotate_right"))
MOCK.Assert(rotateRightButton ~= nil and WO.CharacterUI.PreviewModel ~= nil,
    "в мастере есть управление поворотом превью")
local yawBeforeButton = WO.CharacterUI.PreviewModel:GetYaw()
rotateRightButton:DoClick()
MOCK.Assert(WO.CharacterUI.PreviewModel:GetYaw() == (yawBeforeButton + 20) % 360,
    "кнопка поворачивает 3D-модель")

local createFrame = FindLatestLiveFrame()
MOCK.Assert(createFrame and createFrame.OnKeyCodePressed, "мастер создания обрабатывает Escape")
createFrame:OnKeyCodePressed(KEY_ESCAPE)
MOCK.Assert(WO.CharacterUI.CurrentScreen == "main", "Escape из мастера возвращает в главное меню")

-- Повторное открытие через net (например, при retry) не должно падать.
MOCK.NetDeliver({ name = "Character.OpenCreate", args = {} }, 8, nil)

print("[scenario] Main menu and OpenCreate OK")

---------------------------------------------------------------------------
-- 3. Загрузка существующего персонажа
---------------------------------------------------------------------------

MOCK.NetDeliver({ name = "Character.List", args = {
    1,
    "abc", "Тест", "Герой", 3, "human", "warrior", "male",
    "models/player/group01/male_01.mdl", 0,
} }, 8, nil)

MOCK.NetDeliver({ name = "Character.OpenMenu", args = {} }, 8, nil)
local loadSavedButton = MOCK.FindPanelByText(WO.Lang:Get("character.menu.load"))
MOCK.Assert(loadSavedButton ~= nil and loadSavedButton:IsEnabled(),
    "загрузка доступна при наличии персонажа")
loadSavedButton:DoClick()
MOCK.Assert(WO.CharacterUI.CurrentScreen == "select", "загрузка открывает список персонажей")
local selectFrame = FindLatestLiveFrame()
MOCK.Assert(selectFrame and selectFrame.OnKeyCodePressed, "список персонажей обрабатывает Escape")
selectFrame:OnKeyCodePressed(KEY_ESCAPE)
MOCK.Assert(WO.CharacterUI.CurrentScreen == "main", "Escape из списка возвращает в главное меню")

local preview = WO.UI.CreateCharacterModel(nil, "models/player/group01/male_01.mdl")
preview:RotateBy(30)
local previewEntity = MOCK.NewEntity("preview")
preview:LayoutEntity(previewEntity)
MOCK.Assert(previewEntity:GetAngles().y == 210,
    "превью развёрнуто лицом к камере и вращается кнопками")

MOCK.NetDeliver({ name = "Character.OpenSelect", args = {} }, 8, nil)
MOCK.Assert(WO.CharacterUI.CurrentScreen == "select", "экран выбора персонажа")

print("[scenario] OpenSelect OK")

---------------------------------------------------------------------------
-- 4. Результат создания (ошибка не должна падать)
---------------------------------------------------------------------------

MOCK.NetDeliver({ name = "Character.CreateResult", args = { false, "invalid_name" } }, 8, nil)
MOCK.NetDeliver({ name = "Character.CreateResult", args = { true, "" } }, 8, nil)
MOCK.NetDeliver({ name = "Character.Death", args = { { killer = "Орк", respawnTime = 5 } } }, 8, nil)

print("[scenario] result events OK")

---------------------------------------------------------------------------
-- 4b. UI квестов / диалога / торговли
---------------------------------------------------------------------------

local panelsBeforeUI = #MOCK.createdPanels

-- Синхронизация квестов + журнал
MOCK.NetDeliver({ name = "Quest.Sync", args = { {
    ["supplies_for_the_road"] = { status = "completed", progress = { [1] = 3 }, tracked = true },
    ["wolves_of_elwynn"] = { status = "active", progress = { [1] = 1 }, tracked = true },
} } }, 8, nil)

MOCK.Assert(WO.Quests.LocalStates["wolves_of_elwynn"] ~= nil, "состояние квестов синхронизировано")

local trackerLines = WO.Quests.GetTrackerLines()

MOCK.Assert(#trackerLines > 0, "трекер HUD получает строки: " .. #trackerLines)

WO.Quests.OpenLog()
MOCK.Assert(#MOCK.createdPanels > panelsBeforeUI, "журнал квестов создаёт панели")

-- События квестов (уведомления)
MOCK.NetDeliver({ name = "Quest.Event", args = { { type = "accepted", questId = "q", name = "Тест" } } }, 8, nil)
MOCK.NetDeliver({ name = "Quest.Event", args = { { type = "completed", questId = "q", name = "Тест",
    rewards = { xp = 10, money = 5 } } } }, 8, nil)

-- Диалог
local panelsBeforeDlg = #MOCK.createdPanels

MOCK.NetDeliver({ name = "Dialogue.Open", args = { {
    dialogueId = "marshal_intro", nodeId = "start", npcId = "marshal_dughal",
    npcName = "Маршал Дугхал", text = "Привет!",
    options = { { text = "Пока", action = "close" } },
} } }, 8, nil)

MOCK.Assert(#MOCK.createdPanels > panelsBeforeDlg, "окно диалога создано")

MOCK.NetDeliver({ name = "Dialogue.Finish", args = {} }, 8, nil)

-- Торговля
local panelsBeforeVendor = #MOCK.createdPanels

MOCK.NetDeliver({ name = "Vendor.Open", args = { { npcId = "trader_marla", npcName = "Марла" } } }, 8, nil)
MOCK.NetDeliver({ name = "Vendor.Sync", args = { {
    npcId = "trader_marla", npcName = "Марла", money = 100, sellRate = 0.35,
    stock = { { class = "bread", name = "Хлеб", price = 4, amount = 20, rarity = "common" } },
} } }, 8, nil)

MOCK.Assert(#MOCK.createdPanels > panelsBeforeVendor, "окно торговли создано")

print("[scenario] quest/dialogue/vendor UI OK")

---------------------------------------------------------------------------
-- 5. Хендшейк: InitPostEntity → Client.Ready в outbox
---------------------------------------------------------------------------

MOCK.TakeOutbox()
hook.Run("InitPostEntity")
MOCK.RunTimers(1)

local outbox = MOCK.TakeOutbox()
local readySent = #MOCK.FindInbox(outbox, "Client.Ready")

MOCK.Assert(readySent >= 1, "Client.Ready отправлен после InitPostEntity")

print("[scenario] handshake OK")

print("[scenario] ALL CLIENT TESTS PASSED")
