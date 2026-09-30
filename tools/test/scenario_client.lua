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
local hudShouldDraw = hook.GetTable().HUDShouldDraw
MOCK.Assert(hudShouldDraw and isfunction(hudShouldDraw.wo_hud_hide) and
    hudShouldDraw.wo_hud_hide("CHudHealth") == false and
    hudShouldDraw.wo_hud_hide("CHudScoreboard") == false,
    "стандартные HUD и scoreboard скрыты")
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

GM:ScoreboardShow()
GM:ScoreboardHide()
MOCK.Assert(WO.MenuUI.IsOpen(), "TAB не закрывает постоянное меню выбора персонажа")
WO.MenuUI.Close()
GM:ScoreboardShow()
MOCK.Assert(WO.MenuUI.IsOpen(), "TAB открывает собственный scoreboard")
GM:ScoreboardHide()
MOCK.Assert(not WO.MenuUI.IsOpen(), "отпускание TAB закрывает scoreboard")
WO.CharacterUI.OpenMainMenu()

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

local preview = WO.CharacterUI.PreviewModel
local previewEntity = MOCK.NewEntity("prop")
local yawBeforeSpin = preview:GetYaw()
MOCK.frameTime = 0.1
preview:LayoutEntity(previewEntity)
MOCK.frameTime = nil
MOCK.Assert(preview:GetYaw() > yawBeforeSpin and
    previewEntity.__ang.y == (preview:GetYaw() + 180) % 360,
    "автоматический spin меняет угол самой модели, а не только освещение")

local function ClickWizardNext()
    local nextButton = MOCK.FindPanelByText(WO.Lang:Get("ui.next"))
    MOCK.Assert(nextButton ~= nil, "у шага мастера есть кнопка Далее")
    nextButton:DoClick()
end

local raceIDs = WO.Races.GetIDs()
local selectedRace = WO.Races.Get(raceIDs[1])
local raceButton = MOCK.FindPanelByText(selectedRace.name)
MOCK.Assert(raceButton ~= nil, "первый шаг содержит варианты рас")
raceButton:DoClick()
ClickWizardNext()

local genderButton = MOCK.FindPanelByText(WO.Lang:Get("gender.male"))
MOCK.Assert(genderButton ~= nil, "второй шаг содержит выбор пола")
genderButton:DoClick()
ClickWizardNext() -- возраст
ClickWizardNext() -- имя

local nameEntry
for i = #MOCK.createdPanels, 1, -1 do
    local candidate = MOCK.createdPanels[i]
    if rawget(candidate, "__class") == "DTextEntry" and rawget(candidate, "__removed") ~= true then
        nameEntry = candidate
        break
    end
end
MOCK.Assert(nameEntry and nameEntry.OnChange, "шаг имени содержит поле ввода")
nameEntry:SetValue("Aria")
nameEntry:OnChange(nameEntry)
ClickWizardNext() -- фамилия

local surnameEntry
for i = #MOCK.createdPanels, 1, -1 do
    local candidate = MOCK.createdPanels[i]
    if rawget(candidate, "__class") == "DTextEntry" and rawget(candidate, "__removed") ~= true then
        surnameEntry = candidate
        break
    end
end
MOCK.Assert(surnameEntry and surnameEntry.OnChange, "шаг фамилии содержит поле ввода")
surnameEntry:SetValue("Storm")
surnameEntry:OnChange(surnameEntry)
ClickWizardNext() -- кастомизация
MOCK.Assert(MOCK.FindPanelByText(WO.Lang:Get("character.model")) ~= nil,
    "шаг кастомизации содержит выбор модели")
ClickWizardNext() -- класс

local allowedClass
for _, classId in ipairs(WO.Classes.GetIDs()) do
    if WO.Races.IsClassAllowed(selectedRace.id, classId) then
        allowedClass = WO.Classes.Get(classId)
        break
    end
end
MOCK.Assert(allowedClass ~= nil, "у выбранной расы есть доступный класс")
local classButton = MOCK.FindPanelByText(allowedClass.name)
MOCK.Assert(classButton ~= nil, "шаг класса показывает варианты классов")
classButton:DoClick()
ClickWizardNext() -- итоговая карточка

MOCK.Assert(MOCK.FindPanelByText(WO.Lang:Get("character.review_instructions")) ~= nil,
    "последний шаг ясно просит проверить персонажа")
MOCK.Assert(MOCK.FindPanelByText(WO.Lang:Get("character.full_name") .. ": Aria Storm") ~= nil,
    "итоговая карточка показывает, кто будет создан")
local confirmCheckText = "☐ " .. WO.Lang:Get("character.create_confirm_check")
local confirmCheck = MOCK.FindPanelByText(confirmCheckText)
MOCK.Assert(confirmCheck ~= nil, "создание требует явного подтверждения")
confirmCheck:DoClick()
local confirmAction = MOCK.FindPanelByText(WO.Lang:Get("character.create_confirm_action"))
MOCK.Assert(confirmAction ~= nil and confirmAction:IsEnabled(),
    "подтверждённый персонаж активирует ясную кнопку создания")

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
-- 4b. Инвентарь/экипировка и UI квестов / диалога / торговли
---------------------------------------------------------------------------

MOCK.NetDeliver({ name = "Character.Sync", args = { {
    id = "active-test-character", name = "Тест", surname = "Герой", age = 25,
    gender = "male", race = "human", class = "warrior",
    model = "models/player/group01/male_01.mdl", level = 3, experience = 10, money = 1234,
    customization = { skin = 0, bodygroups = {} },
} } }, 8, nil)
MOCK.Assert(WO.Net.Messages["Stats.Sync"] ~= nil, "Stats.Sync зарегистрирован в клиентском realm")
MOCK.NetDeliver({ name = "Stats.Sync", args = { {
    strength = 12, agility = 10, intelligence = 8, stamina = 14, spirit = 9,
    maxHealth = 140, maxMana = 90, maxStamina = 140,
} } }, 8, nil)
MOCK.Assert(WO.Stats.Networked.strength == 12, "финальные статы синхронизированы клиенту")

MOCK.NetDeliver({ name = "Currency.Sync", args = { 1234 } }, 8, nil)
MOCK.NetDeliver({ name = "Leveling.Sync", args = { 3, 10, 100 } }, 8, nil)
MOCK.Assert(WO.Leveling.ClientData.level == 3, "уровень синхронизирован клиенту")
MOCK.NetDeliver({ name = "Inventory.Sync", args = {
    10, 6, 1, "test-item-uid", "iron_sword", 1, 100, 1, 1, {},
} }, 8, nil)
MOCK.NetDeliver({ name = "Equipment.Sync", args = { {} } }, 8, nil)

MOCK.Assert(WO.Inventory.ClientData.items[1].uid == "test-item-uid" and
    WO.Inventory.ClientData.items[1].class == "iron_sword" and
    WO.Inventory.ClientData.items[1].durability == 100,
    "Inventory.Sync сохраняет порядок полей предмета")
MOCK.NetDeliver({ name = "Inventory.Delta", args = {
    "update", true, "test-item-uid", "iron_sword", 2, 80, 1, 1, {}, false,
} }, 8, nil)
MOCK.Assert(WO.Inventory.ClientData.items[1].amount == 2 and
    WO.Inventory.ClientData.items[1].durability == 80,
    "Inventory.Delta сохраняет порядок полей предмета")

local panelsBeforeInventory = #MOCK.createdPanels
WO.InventoryUI.Open()
MOCK.Assert(#MOCK.createdPanels > panelsBeforeInventory, "окно инвентаря создаёт панели")

local inventoryFrame
for i = #MOCK.createdPanels, 1, -1 do
    local candidate = MOCK.createdPanels[i]
    if rawget(candidate, "__class") == "WO_Window" and rawget(candidate, "__removed") ~= true then
        inventoryFrame = candidate
        break
    end
end
MOCK.Assert(inventoryFrame ~= nil, "окно инвентаря открыто")

local inventoryPanelCount = 0
for _, child in ipairs(inventoryFrame.__children) do
    if rawget(child, "__class") == "DPanel" and rawget(child, "__removed") ~= true then
        inventoryPanelCount = inventoryPanelCount + 1
    end
end
MOCK.Assert(inventoryPanelCount >= 2, "инвентарь и экипировка — отдельные панели")
MOCK.Assert(WO.InventoryUI.IsOpen(), "окно инвентаря сообщает открытое состояние")
WO.InventoryUI.Close()

local panelsBeforeSheet = #MOCK.createdPanels
WO.CharacterUI.OpenSheet()
MOCK.Assert(#MOCK.createdPanels > panelsBeforeSheet,
    "лист персонажа создаётся после синхронизации статов")

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
-- 4c. Выход из персонажа: очистка клиентского состояния и окон
---------------------------------------------------------------------------

WO.InventoryUI.Open()
MOCK.Assert(WO.InventoryUI.IsOpen(), "инвентарь открыт перед выходом")
MOCK.Assert(WO.Character.GetLocal() ~= nil, "локальный персонаж загружен до выхода")

MOCK.NetDeliver({ name = "Character.OpenMenu", args = {} }, 8, nil)

MOCK.Assert(WO.Character.GetLocal() == nil, "Character.OpenMenu очищает локальный персонаж")
MOCK.Assert(not WO.InventoryUI.IsOpen() and WO.Inventory.ClientData == nil,
    "выход закрывает окно и очищает данные инвентаря")
MOCK.Assert(istable(WO.Equipment.ClientData) and next(WO.Equipment.ClientData) == nil,
    "выход очищает клиентский кэш экипировки")
MOCK.Assert(WO.Currency.ClientAmount == nil and WO.Leveling.ClientData == nil and
    WO.Stats.Networked == nil, "выход очищает кэш валюты, уровня и статов")
MOCK.Assert(next(WO.Quests.LocalStates) == nil, "выход очищает локальные квесты")
MOCK.Assert(WO.MenuUI.IsOpen(), "главное меню открывается после выхода")

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
