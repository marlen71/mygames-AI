--[[
    scenario_client.lua — клиентский smoke-тест Warcraft Online.
    Загружает cl_init.lua и открывает экран создания персонажа,
    проверяя, что UI строится без ошибок.
]]

local MOCK = MOCK

MOCK.mountedFiles = {
    ["models/mailer/character/human/male/humanmale00_00.mdl"] = true,
    ["models/mailer/character/human/female/humanfemale00_00.mdl"] = true,
    ["models/mailer/character/human/male/humanmale00_99.mdl"] = true,
}

player_manager.AddValidModel("humanmale00_99", "models/mailer/character/human/male/humanmale00_99.mdl")

for _, class in ipairs({ "drc_unarmed", "tfa_cso_coldsteelblade", "weapon_hpwr_stick" }) do
    weapons.Register({
        PrintName = class,
        Category = "Workshop test fixture",
        Base = "weapon_base",
    }, class)
end

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
MOCK.Assert(MOCK.fonts["WO.Body"].weight >= 600 and MOCK.fonts["WO.Small"].size >= 15 and
    MOCK.fonts["WO.Tiny"].size >= 13,
    "глобальные UI-шрифты стали крупнее и плотнее")
MOCK.Assert(WO.CharacterUI ~= nil and WO.CharacterUI.OpenCreate ~= nil, "экран создания зарегистрирован")
MOCK.Assert(WO.Plugins.IsLoaded("character") and WO.Plugins.IsLoaded("hud"),
    "client загрузил плагины персонажа и HUD")
local hudShouldDraw = hook.GetTable().HUDShouldDraw
local hudDrawTargetID = hook.GetTable().HUDDrawTargetID
MOCK.Assert(hudShouldDraw and isfunction(hudShouldDraw.wo_hud_hide) and
    hudShouldDraw.wo_hud_hide("CHudHealth") == nil and
    hudShouldDraw.wo_hud_hide("CHudScoreboard") == nil and
    hudDrawTargetID and hudDrawTargetID.wo_hud_hide_targetid() == nil,
    "стандартный HUD и target ID не скрываются в лимбо до синхронизации персонажа")
MOCK.Assert(WO.Races.GetIDs and #WO.Races.GetIDs() >= 4, "расы видны на клиенте")
MOCK.Assert(WO.Models ~= nil and WO.Models.GetRace ~= nil, "каталог моделей виден на клиенте")
WO.Models.RefreshRaceLists()
local refreshedHumanModels = WO.Races.GetModels("human", "male")
MOCK.Assert(table.HasValue(refreshedHumanModels,
    "models/mailer/character/human/male/humanmale00_99.mdl"),
    "refresh обнаруживает слитый player_manager идентификатор humanmale00_99")
MOCK.Assert(WO.Config.StartingWeaponClasses.hands == "drc_unarmed" and
    WO.Config.StartingWeaponClasses.knife == "tfa_cso_coldsteelblade" and
    WO.Config.StartingWeaponClasses.mage == "wo_magic_grimoire" and
    WO.Config.StartingWeaponClasses.mageLegacy == "weapon_hpwr_stick" and
    WO.Spells.WeaponClass == "wo_magic_grimoire" and
    weapons.GetStored("drc_unarmed") and
    weapons.GetStored("tfa_cso_coldsteelblade") and
    weapons.GetStored("wo_magic_grimoire") and
    weapons.GetStored("weapon_hpwr_stick"),
    "клиент видит новый grimoire и точный legacy wand для отката")
MOCK.Assert(WO.Items.IsInventoryAllowed("starter_knife") and
    WO.Items.Get("starter_knife").weapon.class == "tfa_cso_coldsteelblade" and
    not WO.Items.IsInventoryAllowed("arcane_hands"),
    "предмет ножа хранит точный SWEP-класс, а руки остаются loadout-only")

local oneTextButton = WO.UI.Button(nil, "Один текст", function() end)
local oneTextLabel = WO.UI.Label(nil, "Один текст")
MOCK.Assert(oneTextButton:GetText() == "" and oneTextButton.woText == "Один текст" and
    oneTextLabel:GetText() == "" and oneTextLabel.woText == "Один текст",
    "WO_Button/WO_Label держат native label пустым и рисуют themed text один раз")

local function PaintedOccurrences(panel)
    MOCK.drawnTextValues = {}
    panel:Paint(180, 32)

    local count = 0

    for _, text in ipairs(MOCK.drawnTextValues) do
        if text == "Один текст" then count = count + 1 end
    end

    return count
end

MOCK.Assert(PaintedOccurrences(oneTextButton) == 1 and
    PaintedOccurrences(oneTextLabel) == 1,
    "кастомные кнопка и метка рисуют видимый текст ровно один раз")

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
local drawCallsBeforeMenu = MOCK.drawTextCalls
MOCK.NetDeliver({ name = "Character.OpenMenu", args = {} }, 8, nil)

MOCK.Assert(WO.CharacterUI.CurrentScreen == "main", "открылось главное меню персонажей")
MOCK.Assert(#MOCK.createdPanels > panelsBeforeMenu, "главное меню создало UI")
MOCK.Assert(MOCK.drawTextCalls == drawCallsBeforeMenu,
    "текст не рисуется императивно во время сборки панелей")
local fullscreenMenu = FindLatestLiveFrame()
local fullscreenWidth, fullscreenHeight = fullscreenMenu:GetSize()
local fullscreenX, fullscreenY = fullscreenMenu:GetPos()
MOCK.Assert(fullscreenWidth == ScrW() and fullscreenHeight == ScrH() and
    fullscreenX == 0 and fullscreenY == 0,
    "единое игровое меню занимает весь экран")
local foundHeroPreview = false
for _, panel in ipairs(MOCK.createdPanels) do
    if rawget(panel, "__class") == "WO_CharacterModel" and rawget(panel, "__removed") ~= true then
        foundHeroPreview = true
        break
    end
end
MOCK.Assert(foundHeroPreview, "главное меню показывает вращающееся 3D-превью персонажа")

MOCK.screenW, MOCK.screenH = 800, 600
hook.Run("OnScreenSizeChanged", 1920, 1080, 800, 600)
local compactMenu = FindLatestLiveFrame()
local compactWidth, compactHeight = compactMenu:GetSize()
MOCK.Assert(compactWidth == 800 and compactHeight == 600,
    "полноэкранное меню перестраивается на компактном разрешении")
MOCK.screenW, MOCK.screenH = 1920, 1080
hook.Run("OnScreenSizeChanged", 800, 600, 1920, 1080)
local restoredMenu = FindLatestLiveFrame()
local restoredWidth, restoredHeight = restoredMenu:GetSize()
MOCK.Assert(restoredWidth == 1920 and restoredHeight == 1080,
    "полноэкранное меню восстанавливает исходное разрешение")

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
local exitButton = MOCK.FindPanelByText(WO.Lang:Get("menu.exit"))

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

local selectedRace = WO.Races.Get("human")
MOCK.Assert(selectedRace and #WO.Races.GetAvailableGenders("human") > 0,
    "test fixture mounts at least one WoW race")
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
    "models/mailer/character/human/male/humanmale00_00.mdl", 0,
} }, 8, nil)

MOCK.NetDeliver({ name = "Character.OpenMenu", args = {} }, 8, nil)
local loadSavedButton = MOCK.FindPanelByText(WO.Lang:Get("character.menu.load"))
MOCK.Assert(loadSavedButton ~= nil and loadSavedButton:IsEnabled(),
    "загрузка доступна при наличии персонажа")
local drawCallsBeforeSelect = MOCK.drawTextCalls
loadSavedButton:DoClick()
MOCK.Assert(WO.CharacterUI.CurrentScreen == "select", "загрузка открывает список персонажей")
MOCK.Assert(MOCK.drawTextCalls == drawCallsBeforeSelect,
    "карточки персонажей не рисуют подписи дважды/вне Paint")
local selectFrame = FindLatestLiveFrame()
MOCK.Assert(selectFrame and selectFrame.OnKeyCodePressed, "список персонажей обрабатывает Escape")
selectFrame:OnKeyCodePressed(KEY_ESCAPE)
MOCK.Assert(WO.CharacterUI.CurrentScreen == "main", "Escape из списка возвращает в главное меню")

local preview = WO.UI.CreateCharacterModel(nil,
    "models/mailer/character/human/male/humanmale00_00.mdl")
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
    model = "models/mailer/character/human/male/humanmale00_00.mdl", level = 3, experience = 10, money = 1234,
    customization = { skin = 0, bodygroups = {} },
} } }, 8, nil)
MOCK.Assert(hudShouldDraw.wo_hud_hide("CHudHealth") == false and
    hudShouldDraw.wo_hud_hide("CHudScoreboard") == false and
    hudDrawTargetID.wo_hud_hide_targetid() == false,
    "при активном персонаже скрыты stock HUD и native target ID")

-- Клиентский NW2-флаг может запаздывать после respawn; при активном snapshot
-- кастомный HUD всё равно должен рисоваться. Валюта в player frame не входит.
LocalPlayer():SetNW2Bool("wo_inmenu", true)
MOCK.drawnTextValues = {}
local hudDrawsBefore = MOCK.drawTextCalls
hook.Run("HUDPaint")
local hudCanvas
for i = #MOCK.createdPanels, 1, -1 do
    local candidate = MOCK.createdPanels[i]
    local width, height = 0, 0

    if candidate.GetSize then width, height = candidate:GetSize() end

    if rawget(candidate, "__class") == "DPanel" and width == ScrW() and height == ScrH() and
        rawget(candidate, "__zpos") == -100 and isfunction(candidate.Paint) then
        hudCanvas = candidate
        break
    end
end
MOCK.Assert(hudCanvas ~= nil, "WoW HUD создаёт прозрачный полноэкранный VGUI canvas")
hudCanvas:Paint(ScrW(), ScrH())
MOCK.Assert(MOCK.drawTextCalls > hudDrawsBefore,
    "canvas HUD не пропадает из-за устаревшего wo_inmenu после respawn")
local formattedMoney = WO.Currency.Format(1234)
local hudShowsMoney = false
for _, text in ipairs(MOCK.drawnTextValues) do
    if string.find(text, formattedMoney, 1, true) then
        hudShowsMoney = true
        break
    end
end
MOCK.Assert(not hudShowsMoney, "валюта не отображается в WoW-style HUD")
LocalPlayer():SetNW2Bool("wo_inmenu", false)

MOCK.Assert(scripted_ents.Get("wo_npc").RenderGroup == RENDERGROUP_BOTH,
    "NPC marker draw hook is enabled for both opaque and translucent passes")
local merchantNPC = ents.Create("wo_npc")
merchantNPC:SetNPCID("trader_marla")
merchantNPC:SetPos(LocalPlayer():GetPos() + Vector(50, 0, 0))
MOCK.Assert(WO.Interaction.CanInteract(merchantNPC, LocalPlayer()) and
    WO.Interaction.GetRange(merchantNPC) == WO.Config.InteractDistance and
    string.find(WO.Interaction.GetText(merchantNPC, LocalPlayer()), "Марла", 1, true),
    "клиентский trace разрешает ближайшего NPC по сетевому NPCID и общей дальности")
merchantNPC:SetPos(LocalPlayer():GetPos() + Vector(WO.Config.InteractDistance + 1, 0, 0))
MOCK.Assert(not WO.Interaction.CanInteract(merchantNPC, LocalPlayer()),
    "клиентская подсказка скрывается за пределами общей дальности")
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
local originalQuestLog = FindLatestLiveFrame()
MOCK.NetDeliver({ name = "Quest.Sync", args = { {
    ["supplies_for_the_road"] = { status = "completed", progress = { [1] = 3 }, tracked = true },
    ["boar_hunt"] = { status = "active", progress = { [1] = 1 }, tracked = true },
    ["wolves_of_elwynn"] = { status = "active", progress = { [1] = 1 }, tracked = true },
} } }, 8, nil)
local refreshedQuestLog = FindLatestLiveFrame()
MOCK.Assert(originalQuestLog and rawget(originalQuestLog, "__removed") == true and
    refreshedQuestLog and refreshedQuestLog ~= originalQuestLog and
    WO.Quests.LocalStates["boar_hunt"].progress[1] == 1,
    "открытый журнал автоматически перестраивается после Quest.Sync")
local refreshedTracker = WO.Quests.GetTrackerLines()
local trackerHasBoars = false
for _, line in ipairs(refreshedTracker) do
    if string.find(string.lower(line.text or ""), "кабан", 1, true) then trackerHasBoars = true end
end
MOCK.Assert(trackerHasBoars, "HUD-трекер сразу отражает новое состояние задания")

-- События квестов (уведомления)
MOCK.NetDeliver({ name = "Quest.Event", args = { { type = "accepted", questId = "q", name = "Тест" } } }, 8, nil)
MOCK.NetDeliver({ name = "Quest.Event", args = { { type = "completed", questId = "q", name = "Тест",
    rewards = { xp = 10, money = 5 } } } }, 8, nil)

MOCK.Assert(WO.Net.Messages["Spell.Sync"] ~= nil and isfunction(WO.Spells.OpenBook),
    "клиент зарегистрировал независимый Spell.Sync и окно книги")
MOCK.NetDeliver({ name = "Spell.Sync", args = { {
    ranks = { healing_wave = 1 }, selected = "healing_wave", points = 0, level = 3,
} } }, 8, nil)
MOCK.Assert(WO.Spells.LocalBook.selected == "healing_wave" and
    WO.Spells.LocalBook.ranks.healing_wave == 1,
    "ранги и выбранное заклинание синхронизированы клиенту")
local spellPanelsBefore = #MOCK.createdPanels
local magicSWEP = weapons.GetStored("wo_magic_grimoire")
local fakeMagicWeapon = {
    GetOwner = function() return LocalPlayer() end,
    SetNextSecondaryFire = function() end,
}
MOCK.Assert(magicSWEP and isfunction(magicSWEP.PrimaryAttack) and
    isfunction(magicSWEP.SecondaryAttack), "новый spellbook SWEP содержит ЛКМ и ПКМ обработчики")
magicSWEP.SecondaryAttack(fakeMagicWeapon)
MOCK.Assert(#MOCK.createdPanels > spellPanelsBefore,
    "ПКМ нового SWEP открывает самостоятельное окно выбора и изучения заклинаний")

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
