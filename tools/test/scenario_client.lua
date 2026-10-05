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

for _, class in ipairs({ "drc_unarmed", "tfa_cso_coldsteelblade" }) do
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

local function PressKey(key)
    MOCK.keysDown[key] = true
    hook.Run("Think")
    MOCK.keysDown[key] = false
    hook.Run("Think")
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
MOCK.Assert(WO.Config.Sounds.ui_open == "ui/buttonclickrelease.wav" and
    WO.Config.Sounds.ui_close == "ui/buttonclickrelease.wav",
    "звуки открытия/закрытия используют встроенный UI asset, а не отсутствующую папку menu")
MOCK.Assert(MOCK.fonts["WO.Body"].weight >= 600 and MOCK.fonts["WO.Small"].size >= 15 and
    MOCK.fonts["WO.Tiny"].size >= 13,
    "глобальные UI-шрифты стали крупнее и плотнее")
MOCK.Assert(WO.CharacterUI ~= nil and WO.CharacterUI.OpenCreate ~= nil, "экран создания зарегистрирован")
MOCK.Assert(WO.Plugins.IsLoaded("character") and WO.Plugins.IsLoaded("hud"),
    "client загрузил плагины персонажа и HUD")
local hudShouldDraw = hook.GetTable().HUDShouldDraw
local hudDrawTargetID = hook.GetTable().HUDDrawTargetID
MOCK.Assert(hudShouldDraw and isfunction(hudShouldDraw.wo_hud_hide) and
    hudShouldDraw.wo_hud_hide("CHudHealth") == false and
    hudShouldDraw.wo_hud_hide("CHudScoreboard") == false and
    hudShouldDraw.wo_hud_hide("CHudDeathNotice") == false and
    hudShouldDraw.wo_hud_hide("any_other_stock_panel") == false and
    hudDrawTargetID and hudDrawTargetID.wo_hud_hide_targetid() == false,
    "весь стандартный HUD, killfeed и target ID скрыты даже в лимбо")
MOCK.Assert(WO.Races.GetIDs and #WO.Races.GetIDs() == 17, "все расы видны на клиенте")
MOCK.Assert(WO.Models ~= nil and WO.Models.GetRace ~= nil, "каталог моделей виден на клиенте")
local themedNameRaces = {
    "dwarf", "elf", "gnome", "goblin", "human", "orc", "tauren", "troll", "undead",
    "bloodelf", "dracthyr", "draenei", "pandaren", "worgen", "vulpera", "sethrak", "naga",
}
local allNamePoolsValid = WO.CharacterNames and WO.CharacterNames.Generate ~= nil
for _, raceID in ipairs(themedNameRaces) do
    local pools = WO.CharacterNames and WO.CharacterNames.Get(raceID)
    allNamePoolsValid = allNamePoolsValid and pools ~= nil and
        #pools.givenNames.male >= 25 and #pools.givenNames.female >= 25 and #pools.surnames >= 24

    if pools then
        for _, pool in ipairs({ pools.givenNames.male, pools.givenNames.female, pools.surnames }) do
            for _, name in ipairs(pool) do
                allNamePoolsValid = allNamePoolsValid and WO.Util.IsValidName(name)
            end
        end
    end
end
MOCK.Assert(allNamePoolsValid, "все 17 рас имеют расширенные имена и фамилии, включая кириллические варианты")
local configuredHumanModel = "models/mailer/character/human/male/humanmale00_00.mdl"
local discoveredHumanModel = "models/mailer/character/human/male/humanmale00_99.mdl"
MOCK.mountedFiles[configuredHumanModel] = nil
MOCK.mountedFiles[discoveredHumanModel] = true
WO.Models.RefreshRaceLists()
local refreshedHumanModels = WO.Races.GetModels("human", "male")
MOCK.Assert(table.HasValue(refreshedHumanModels, configuredHumanModel) and
    not table.HasValue(refreshedHumanModels, discoveredHumanModel),
    "race UI использует явный путь без file.Exists и не сканирует player_manager")
MOCK.mountedFiles[configuredHumanModel] = true
local configuredPlayableRaces = {
    "human", "elf", "orc", "dwarf", "gnome", "undead", "tauren", "troll", "goblin",
    "bloodelf", "dracthyr", "draenei", "pandaren", "worgen", "vulpera", "sethrak", "naga",
}
local everyConfiguredRaceHasBothModels = true
for _, raceId in ipairs(configuredPlayableRaces) do
    for _, gender in ipairs({ "male", "female" }) do
        local paths = WO.Races.GetModels(raceId, gender)
        everyConfiguredRaceHasBothModels = everyConfiguredRaceHasBothModels and
            #paths > 0 and string.sub(paths[1] or "", 1, 14) == "models/mailer/"
    end
end
MOCK.Assert(everyConfiguredRaceHasBothModels and
    table.HasValue(WO.Races.GetModels("pandaren", "male"),
        "models/mailer/character/pandaren/male/pandarenmale05_02.mdl") and
    table.HasValue(WO.Races.GetModels("pandaren", "female"),
        "models/mailer/character/pandaren/female/pandarenfemale03_04.mdl"),
    "явный каталог показывает пути всех рас и подтверждённые варианты Pandaren без локального fallback")

local unlistedModelPath = "models/mailer/character/test/unlisted_preview.mdl"
MOCK.mountedFiles[unlistedModelPath] = true
local mountedPreview = WO.UI.CreateCharacterModel(nil, unlistedModelPath)
mountedPreview.spin = false
mountedPreview:SetYaw(0)
mountedPreview:Think()
local cameraAtZero = mountedPreview:GetCamPos()
mountedPreview:LayoutEntity(mountedPreview.Entity)
local modelAngleAtZero = mountedPreview.Entity:GetAngles().y
mountedPreview:RotateBy(90)
mountedPreview:Think()
local cameraAfterRotation = mountedPreview:GetCamPos()
mountedPreview:LayoutEntity(mountedPreview.Entity)
MOCK.Assert(not WO.Races.IsPlayableModel(unlistedModelPath) and
    mountedPreview.woModelAvailable == true and IsValid(mountedPreview.Entity) and
    cameraAtZero.x == cameraAfterRotation.x and cameraAtZero.y == cameraAfterRotation.y and
    cameraAtZero.z == cameraAfterRotation.z and modelAngleAtZero == 180 and
    mountedPreview.Entity:GetAngles().y == 270,
    "любая смонтированная модель видна в preview; камера фиксирована, модель вращается относительно неё")

local delayedModelPath = "models/mailer/character/test/delayed_mount.mdl"
local delayedPreview = WO.UI.CreateCharacterModel(nil, delayedModelPath)
MOCK.Assert(not IsValid(delayedPreview.Entity) and delayedPreview.requestedModel == delayedModelPath and
    delayedPreview.__lastSetModelPath == delayedModelPath,
    "превью сразу передаёт заданный путь DModelPanel без предварительной проверки наличия")
MOCK.mountedFiles[delayedModelPath] = true
delayedPreview.nextModelRetry = CurTime() - 1
delayedPreview:Think()
MOCK.Assert(IsValid(delayedPreview.Entity) and delayedPreview.currentModel == delayedModelPath,
    "общее preview повторно загружает модель после монтирования контента")
MOCK.drawnTextValues = {}
local unmountedPreviewPath = "models/mailer/character/test/not_mounted.mdl"
local unavailablePreview = WO.UI.CreateCharacterModel(nil, unmountedPreviewPath)
unavailablePreview:PaintOver(120, 180)
MOCK.Assert(unavailablePreview.__lastSetModelPath == unmountedPreviewPath and
    #MOCK.drawnTextValues == 0,
    "3D-превью передаёт точный путь напрямую и не рисует блокирующее сообщение")

MOCK.Assert(WO.Config.StartingWeaponClasses.hands == "drc_unarmed" and
    WO.Config.StartingWeaponClasses.knife == "tfa_cso_coldsteelblade" and
    WO.Config.StartingWeaponClasses.mage == "wo_magic_grimoire" and
    WO.Config.StartingWeaponClasses.mageLegacy == nil and
    WO.Workshop.RequestedSWEPs.legacyMageStick == nil and
    WO.Spells.WeaponClass == "wo_magic_grimoire" and
    weapons.GetStored("drc_unarmed") and
    weapons.GetStored("tfa_cso_coldsteelblade") and
    weapons.GetStored("wo_magic_grimoire") and
    not weapons.GetStored("weapon_hpwr_stick"),
    "клиент видит только grimoire для мага и собственную систему заклинаний")
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

local buttonActionCount = 0
local responsiveButton = WO.UI.Button(nil, "Проверить", function()
    buttonActionCount = buttonActionCount + 1
end)
local sharedButtonDoClick = responsiveButton.DoClick
MOCK.Assert(isfunction(sharedButtonDoClick) and isfunction(responsiveButton.woAction) and
    responsiveButton.DoClick == sharedButtonDoClick,
    "каждая WO-кнопка использует общий зарегистрированный DoClick-диспетчер")
responsiveButton:DoClick()
responsiveButton:SetBusy(true, WO.Lang:Get("ui.pending"))
responsiveButton:DoClick() -- disabled buttons never dispatch a second request
MOCK.Assert(buttonActionCount == 1 and responsiveButton:IsEnabled() == false,
    "общая WO-кнопка сразу вызывает действие и блокирует повторный запрос в ожидании")
responsiveButton:SetBusy(false)
MOCK.Assert(responsiveButton:IsEnabled() and responsiveButton.woText == "Проверить",
    "WO-кнопка возвращает текст и доступность после завершения запроса")

MOCK.TakeOutbox()
WO.Dialogue.OpenUI({
    dialogueId = "trader_marla",
    nodeId = "start",
    npcId = "trader_marla",
    npcName = "Торговка Марла",
    text = "Добро пожаловать.",
    options = { { text = "Торговать", action = "vendor" } },
})
local dialogueWindow = FindLatestLiveFrame()
local dialogueWidth, dialogueHeight = dialogueWindow:GetSize()
local dialogueX = dialogueWindow:GetPos()
local tradeOption = MOCK.FindPanelByText("Торговать")
MOCK.Assert(dialogueWindow and dialogueWidth >= 350 and dialogueHeight >= 400 and
    dialogueX > ScrW() / 2 and tradeOption ~= nil,
    "диалог открывается справа в компактном WoW-подобном окне с понятным вариантом")
tradeOption:DoClick()
local dialogueChoose = MOCK.FindInbox(MOCK.TakeOutbox(), "Dialogue.Choose")
MOCK.Assert(dialogueChoose and dialogueChoose[1].args[1] == "trader_marla" and
    dialogueChoose[1].args[2] == "start" and dialogueChoose[1].args[3] == 1 and
    tradeOption:IsEnabled() == false,
    "кнопка диалога сразу отправляет серверу только индекс варианта и ждёт ответ")
WO.Dialogue.CloseUI()

MOCK.TakeOutbox()
WO.Dialogue.OpenQuestOfferUI({
    dialogueId = "hunter_intro",
    nodeId = "work",
    npcId = "hunter_dyrne",
    npcName = "Охотник",
    questId = "boar_hunt",
    name = "Кабаны у фермы",
    description = "Победите четырёх кабанов и вернитесь за наградой.",
    objectives = { { text = "Победите кабанов", amount = 4 } },
    rewards = { xp = 100, money = 35, items = {} },
    acceptItems = { { name = "Охотничий нож", amount = 1 } },
})
local questOfferWindow = FindLatestLiveFrame()
local acceptOffer = MOCK.FindPanelByText("Принять")
local declineOffer = MOCK.FindPanelByText("Не сейчас")
MOCK.Assert(questOfferWindow and acceptOffer and declineOffer,
    "карточка задания показывает цель, награду и выбор принять/отложить")
acceptOffer:DoClick()
local questResponse = MOCK.FindInbox(MOCK.TakeOutbox(), "Dialogue.QuestResponse")
MOCK.Assert(questResponse and questResponse[1].args[1] == "boar_hunt" and
    questResponse[1].args[2] == true,
    "принятие задания отправляет серверу подтверждение для текущего предложения")
WO.Dialogue.CloseUI()

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

do
    GM:ScoreboardShow()
    GM:ScoreboardHide()
    MOCK.Assert(WO.MenuUI.IsOpen(), "TAB не закрывает постоянное меню выбора персонажа")

    WO.MenuUI.Close()
    local bindHandler = hook.GetTable().PlayerBindPress.wo_menu_scoreboard_bind
    MOCK.Assert(isfunction(bindHandler), "TAB bind handler установлен")
    MOCK.Assert(bindHandler(LocalPlayer(), "+showscores", true) == true and
        WO.MenuUI.IsOpen(), "нажатие TAB перехватывает штатный scoreboard и открывает свой")
    MOCK.Assert(bindHandler(LocalPlayer(), "+showscores", true) == true and
        WO.MenuUI.IsOpen(), "удержание TAB не открывает повторно или не закрывает меню")
    MOCK.Assert(bindHandler(LocalPlayer(), "+showscores", false) == true and
        not WO.MenuUI.IsOpen(), "отпускание TAB закрывает собственное меню")

    local showFallback = hook.GetTable().ScoreboardShow.wo_menu_scoreboard_show
    local hideFallback = hook.GetTable().ScoreboardHide.wo_menu_scoreboard_hide
    MOCK.Assert(showFallback() == true and WO.MenuUI.IsOpen(),
        "callback ScoreboardShow также заменяет штатную таблицу игроков")
    MOCK.Assert(hideFallback() == true and not WO.MenuUI.IsOpen(),
        "callback ScoreboardHide корректно закрывает кастомное меню")

    WO.CharacterUI.OpenMainMenu()
end

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
MOCK.RunTimers(0)

exitButton:DoClick()
MOCK.Assert(MOCK.consoleCommands[#MOCK.consoleCommands][1] == "disconnect",
    "кнопка выхода вызывает disconnect")

-- Exit closes the entire menu; reacquire a live create button instead of
-- dispatching a click to a stale child panel.
WO.CharacterUI.OpenMainMenu()
createButton = MOCK.FindPanelByText(WO.Lang:Get("character.menu.create"))
MOCK.Assert(createButton ~= nil and IsValid(createButton),
    "главное меню повторно открывается перед действием создания")
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

local specialRace = WO.Races.Get("bloodelf")
local specialRaceLabel = specialRace.name .. " · " .. WO.Lang:Get("race.special")
local specialRaceButton = MOCK.FindPanelByText(specialRaceLabel)
MOCK.Assert(specialRaceButton ~= nil and specialRaceButton:IsEnabled(),
    "особая раса помечена ровно нейтральной меткой без клиентского admin gate")
specialRaceButton:DoClick()
MOCK.Assert(WO.CharacterUI.PreviewModel.requestedModel == specialRace.models.male[1] and
    WO.CharacterUI.PreviewModel.__lastSetModelPath == specialRace.models.male[1],
    "особая раса передаёт точный путь в preview, а создание отдельно защищает сервер")

local selectedRace = WO.Races.Get("human")
MOCK.Assert(selectedRace and #WO.Races.GetAvailableGenders("human") > 0,
    "test fixture mounts at least one WoW race")
local raceButton = MOCK.FindPanelByText(selectedRace.name)
MOCK.Assert(raceButton ~= nil, "первый шаг содержит варианты рас")
raceButton:DoClick()
MOCK.Assert(WO.CharacterUI.PreviewModel.woModelAvailable == true and
    IsValid(WO.CharacterUI.PreviewModel.Entity) and
    WO.CharacterUI.PreviewModel.currentModel == selectedRace.models.male[1],
    "выбор расы показывает её реальную доступную 3D-модель")
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
local generateNameButton = MOCK.FindPanelByText(WO.Lang:Get("character.generate_name"))
MOCK.Assert(generateNameButton ~= nil, "шаг имени предлагает тематическую генерацию")
generateNameButton:DoClick()
local generatedHumanName = nameEntry:GetValue()
local generatedNameIsHuman = false
for _, candidate in ipairs(WO.CharacterNames.Get("human").givenNames.male) do
    if candidate == generatedHumanName then generatedNameIsHuman = true end
end
MOCK.Assert(generatedNameIsHuman and WO.Util.IsValidName(generatedHumanName),
    "генератор имени использует пул выбранной расы и принимает значение серверной валидацией")
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
local generateSurnameButton = MOCK.FindPanelByText(WO.Lang:Get("character.generate_surname"))
MOCK.Assert(generateSurnameButton ~= nil, "шаг фамилии предлагает тематическую генерацию")
generateSurnameButton:DoClick()
local generatedHumanSurname = surnameEntry:GetValue()
local generatedSurnameIsHuman = false
for _, candidate in ipairs(WO.CharacterNames.Get("human").surnames) do
    if candidate == generatedHumanSurname then generatedSurnameIsHuman = true end
end
MOCK.Assert(generatedSurnameIsHuman and WO.Util.IsValidName(generatedHumanSurname),
    "генератор фамилии использует отдельный расовый пул и принимает значение серверной валидацией")
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
MOCK.Assert(hook.GetTable().OnPauseMenuShow.wo_menu_escape_toggle() == false and
    WO.MenuUI.IsOpen(), "глобальный Escape не переключает повторно меню после закрытия мастера")
MOCK.RunTimers(0)

-- Повторное открытие через net (например, при retry) не должно падать.
MOCK.NetDeliver({ name = "Character.OpenCreate", args = {} }, 8, nil)

print("[scenario] Main menu and OpenCreate OK")

---------------------------------------------------------------------------
-- 3. Загрузка существующего персонажа
---------------------------------------------------------------------------

local firstSavedCharacterID = "11111111-1111-4111-8111-111111111111"
local secondSavedCharacterID = "22222222-2222-4222-8222-222222222222"
MOCK.NetDeliver({ name = "Character.List", args = {
    2,
    firstSavedCharacterID, "Тест", "Герой", 3, "human", "warrior", "male",
    "models/mailer/character/human/male/humanmale00_00.mdl", 1700000000, 150, 600,
    secondSavedCharacterID, "Ария", "Буря", 5, "human", "mage", "female",
    "models/mailer/character/human/female/humanfemale00_00.mdl", 1700000123, 240, 700,
} }, 8, nil)
MOCK.Assert(#WO.Character.GetList() == 2 and
    WO.Character.GetList()[1].id == firstSavedCharacterID and
    WO.Character.GetList()[2].id == secondSavedCharacterID and
    WO.Util.IsUUID(WO.Character.GetList()[2].id) and
    WO.Character.GetList()[1].experience == 150 and
    WO.Character.GetList()[1].needed == 600 and
    WO.Character.GetList()[2].experience == 240 and
    WO.Character.GetList()[2].needed == 700,
    "список персонажей сохраняет ID и XP всех записей в net-пакете")

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
MOCK.Assert(hook.GetTable().OnPauseMenuShow.wo_menu_escape_toggle() == false and
    WO.MenuUI.IsOpen(), "глобальный Escape не закрывает меню после возврата из списка персонажей")
MOCK.RunTimers(0)

local preview = WO.UI.CreateCharacterModel(nil,
    "models/mailer/character/human/male/humanmale00_00.mdl")
preview:RotateBy(30)
local previewEntity = MOCK.NewEntity("preview")
preview:LayoutEntity(previewEntity)
MOCK.Assert(previewEntity:GetAngles().y == 210,
    "превью развёрнуто лицом к камере и вращается кнопками")

local selectionPanelStart = #MOCK.createdPanels + 1
MOCK.NetDeliver({ name = "Character.OpenSelect", args = {} }, 8, nil)
MOCK.Assert(WO.CharacterUI.CurrentScreen == "select", "экран выбора персонажа")

local selectionCards = {}
for i = selectionPanelStart, #MOCK.createdPanels do
    local panel = MOCK.createdPanels[i]

    if rawget(panel, "__class") == "DPanel" and
        rawget(panel, "selected") ~= nil and
        isfunction(rawget(panel, "OnMousePressed")) then
        selectionCards[#selectionCards + 1] = panel
    end
end

MOCK.Assert(#selectionCards == 2, "экран выбора строит карточки всех сохранённых персонажей")
selectionCards[2].OnMousePressed()
MOCK.Assert(selectionCards[1].selected == false and selectionCards[2].selected == true,
    "клик по второй карточке выбирает именно второго персонажа")

local playCharacterButton = MOCK.FindPanelByText(WO.Lang:Get("ui.confirm"))
MOCK.Assert(playCharacterButton and playCharacterButton:IsEnabled(),
    "после выбора карточки активна кнопка входа")
MOCK.TakeOutbox()
playCharacterButton:DoClick()
local requestedCharacterMessages = MOCK.FindInbox(MOCK.TakeOutbox(), "Character.Select")
MOCK.Assert(#requestedCharacterMessages == 1 and
    requestedCharacterMessages[1].args[1] == secondSavedCharacterID,
    "кнопка входа отправляет ID именно выбранного второго персонажа")

local selectionCardHasModel = false
for _, panel in ipairs(MOCK.createdPanels) do
    if rawget(panel, "__class") == "WO_CharacterModel" and
        rawget(panel, "__removed") ~= true and
        rawget(panel, "currentModel") == "models/mailer/character/human/male/humanmale00_00.mdl" and
        IsValid(rawget(panel, "Entity")) then
        selectionCardHasModel = true
        break
    end
end
MOCK.Assert(selectionCardHasModel,
    "карточка выбора использует ту же фабрику и показывает смонтированную модель персонажа")

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
LocalPlayer():SetNW2Bool("wo_char_active", true)
LocalPlayer():SetNW2String("wo_character_id", "active-test-character")
LocalPlayer():SetNW2String("wo_name", "Тест Герой")
LocalPlayer():SetNW2String("wo_race", "human")
LocalPlayer():SetNW2String("wo_class", "warrior")
LocalPlayer():SetNW2Int("wo_level", 3)

do
    MOCK.Assert(WO.Plugins.IsLoaded("professions") and #WO.Professions.GetIDs() == 21 and
        WO.ProfessionsUI and WO.ProfessionsUI.GetCurrentShift and
        WO.ProfessionsUI.BuildPanel == nil,
        "клиент зарегистрировал ремёсла, но не строит их внутри общего меню")

    WO.MenuUI.Show("overview")
    MOCK.Assert(MOCK.FindPanelByText("Ремёсла") == nil,
        "страницы или вкладки ремёсел нет в главном меню")
    WO.MenuUI.Close()

    MOCK.NetDeliver({ name = "Profession.Sync", args = { {
        characterId = "active-test-character",
        revision = 1,
        skills = { fisher = { xp = 0, level = 1, completedShifts = 0 } },
        shift = {
            id = "client-work-shift", professionId = "fisher", professionName = "Рыбак",
            npcId = "work_fisher", npcName = "Рыбак", rank = 1,
            completedOrders = 0, requiredOrders = 3, status = "working", basePay = 33, bonus = 0,
            task = {
                orderIndex = 1, mode = "fishing", engine = "hold", title = "Подсечь рыбу",
                instruction = "Рыба клюёт.", phase = "working", progress = 0.25, elapsed = 0,
                zoneCenter = 0.5, zoneWidth = 0.2, speed = 1, phaseOffset = 0,
            },
        },
    } } }, 8, nil)

    local fishPolygonsBefore = MOCK.surfacePolyCalls or 0
    MOCK.drawnTextValues = {}
    hook.GetTable().HUDPaint.wo_professions_world_hud()
    local fishHudVisible = false
    for _, text in ipairs(MOCK.drawnTextValues) do
        if text:find("Рыбалка", 1, true) then fishHudVisible = true end
    end
    MOCK.Assert(fishHudVisible and (MOCK.surfacePolyCalls or 0) >= fishPolygonsBefore + 2,
        "рыбалка рисуется поверх живого мира отдельной вертикальной шкалой с иконкой рыбы")

    MOCK.TakeOutbox()
    MOCK.keysDown[KEY_SPACE] = true
    hook.GetTable().Think.wo_professions_world_input()
    MOCK.keysDown[KEY_SPACE] = false
    hook.GetTable().Think.wo_professions_world_input()
    local workInputMessages = MOCK.FindInbox(MOCK.TakeOutbox(), "Profession.WorkInput")
    MOCK.Assert(#workInputMessages == 2 and workInputMessages[1].args[1] == "client-work-shift" and
        workInputMessages[1].args[2] == "hold" and workInputMessages[1].args[3] == true and
        workInputMessages[2].args[3] == false,
        "рыбацкая мини-игра принимает удержание/отпускание пробела без открытия меню")

    MOCK.NetDeliver({ name = "Profession.Sync", args = { {
        characterId = "active-test-character", revision = 2, skills = {},
        shift = {
            id = "client-merchant-shift", professionId = "merchant", professionName = "Торговец",
            npcId = "work_merchant", npcName = "Торговец", rank = 1,
            completedOrders = 0, requiredOrders = 3, status = "working", basePay = 36, bonus = 0,
            task = {
                orderIndex = 1, mode = "haggling", engine = "choice", title = "Оценить партию",
                instruction = "Сверьте цель сделки.", phase = "working", progress = 0.25,
                choiceOptions = { "10 монет", "50 монет", "90 монет" },
                choiceTarget = "Цель сделки — 60 монет. Выберите ближайшую цену.",
            },
        },
    } } }, 8, nil)
    MOCK.drawnTextValues = {}
    hook.GetTable().HUDPaint.wo_professions_world_hud()
    local merchantTargetVisible, merchantPriceVisible = false, false
    for _, text in ipairs(MOCK.drawnTextValues) do
        merchantTargetVisible = merchantTargetVisible or text:find("60 монет", 1, true) ~= nil
        merchantPriceVisible = merchantPriceVisible or text:find("50 монет", 1, true) ~= nil
    end
    MOCK.Assert(merchantTargetVisible and merchantPriceVisible,
        "торговая мини-игра выводит на игровой HUD рыночную цель и выбор цен")
    MOCK.TakeOutbox()
    MOCK.keysDown[KEY_1] = true
    hook.GetTable().Think.wo_professions_world_input()
    MOCK.keysDown[KEY_1] = false
    hook.GetTable().Think.wo_professions_world_input()
    local merchantInput = MOCK.FindInbox(MOCK.TakeOutbox(), "Profession.WorkInput")
    MOCK.Assert(#merchantInput == 1 and merchantInput[1].args[1] == "client-merchant-shift" and
        merchantInput[1].args[2] == "choice1" and merchantInput[1].args[3] == true,
        "клавиши выбора цены отправляют действие напрямую серверу, не открывая меню")

    MOCK.NetDeliver({ name = "Profession.Sync", args = { {
        characterId = "active-test-character", revision = 3, skills = {},
        shift = {
            id = "client-herbalist-shift", professionId = "herbalist", professionName = "Травник",
            npcId = "work_herbalist", npcName = "Травник", rank = 1,
            completedOrders = 0, requiredOrders = 3, status = "working", basePay = 33, bonus = 0,
            task = {
                orderIndex = 1, mode = "herbcraft", engine = "identify", title = "Найти растение",
                instruction = "Найдите заказанную траву.", phase = "working", progress = 0.25,
                choiceOptions = { "Мята", "Чабрец", "Лаванда", "Полынь" },
                choiceTarget = "Найдите заказанное растение: Полынь",
            },
        },
    } } }, 8, nil)
    MOCK.drawnTextValues = {}
    hook.GetTable().HUDPaint.wo_professions_world_hud()
    local herbTargetVisible, herbOptionVisible = false, false
    for _, text in ipairs(MOCK.drawnTextValues) do
        herbTargetVisible = herbTargetVisible or text:find("Полынь", 1, true) ~= nil
        herbOptionVisible = herbOptionVisible or text:find("Мята", 1, true) ~= nil
    end
    MOCK.Assert(herbTargetVisible and herbOptionVisible,
        "мини-игра травника отображает опознание растения среди четырёх названий")
    MOCK.TakeOutbox()
    MOCK.keysDown[KEY_4] = true
    hook.GetTable().Think.wo_professions_world_input()
    MOCK.keysDown[KEY_4] = false
    hook.GetTable().Think.wo_professions_world_input()
    local herbInput = MOCK.FindInbox(MOCK.TakeOutbox(), "Profession.WorkInput")
    MOCK.Assert(#herbInput == 1 and herbInput[1].args[1] == "client-herbalist-shift" and
        herbInput[1].args[2] == "choice4" and herbInput[1].args[3] == true,
        "идентификация травы использует четвёртую клавишу и отправляет её серверу")

    local lumberPickup = Vector(-8583.5, 1422.4, -2772)
    local lumberDelivery = Vector(-7312.7, 1722.3, -2943.2)
    local previousLumberTestMap = MOCK.mapName
    MOCK.mapName = "rp_lordaeron"
    LocalPlayer():SetPos(lumberPickup)

    MOCK.NetDeliver({ name = "Profession.Sync", args = { {
        characterId = "active-test-character", revision = 4, skills = {}, shift = nil,
    } } }, 8, nil)
    MOCK.drawnTextValues = {}
    hook.GetTable().HUDPaint.wo_professions_world_hud()
    local noShiftHint, falseMarker = false, false
    for _, text in ipairs(MOCK.drawnTextValues) do
        noShiftHint = noShiftHint or text == "СМЕНА ЛЕСОРУБА НЕ НАЧАТА"
        falseMarker = falseMarker or text == "ШТАБЕЛЬ БРЁВЕН" or text == "СКЛАД БРЁВЕН"
    end
    MOCK.Assert(noShiftHint and not falseMarker,
        "у штабеля без активной смены показывается объяснение, но не появляется метка")

    MOCK.TakeOutbox()
    MOCK.keysDown[KEY_E] = true
    hook.GetTable().Think.wo_professions_world_input()
    MOCK.keysDown[KEY_E] = false
    hook.GetTable().Think.wo_professions_world_input()
    local noShiftProbeRequest = MOCK.FindInbox(MOCK.TakeOutbox(), "Profession.SyncRequest")
    MOCK.Assert(#noShiftProbeRequest == 1,
        "E у штабеля перепроверяет состояние смены даже при локальном снимке без работы")

    hook.GetTable().CharacterMenuOpening.professions_reset_world_controls()
    MOCK.TakeOutbox()
    hook.GetTable().Think.wo_professions_world_input()
    local initialSnapshotRequest = MOCK.FindInbox(MOCK.TakeOutbox(), "Profession.SyncRequest")
    MOCK.AdvanceTime(2.6)
    hook.GetTable().Think.wo_professions_world_input()
    local retriedSnapshotRequest = MOCK.FindInbox(MOCK.TakeOutbox(), "Profession.SyncRequest")
    MOCK.Assert(#initialSnapshotRequest == 1 and #retriedSnapshotRequest == 1,
        "если снимок профессии потерян, клиент повторно запрашивает его с rate-limit интервалом")

    MOCK.NetDeliver({ name = "Profession.Sync", args = { {
        characterId = "active-test-character", revision = 5, skills = {},
        shift = {
            id = "client-lumber-shift", professionId = "lumberjack", professionName = "Лесоруб",
            npcId = "work_lumberjack", npcName = "Лесоруб", rank = 1,
            completedOrders = 0, requiredOrders = 3, status = "working", basePay = 32, bonus = 0,
            task = {
                orderIndex = 1, mode = "lumber_delivery", engine = "lumber",
                title = "Перенести связку брёвен", instruction = "Отнесите брёвна на склад.",
                phase = "pickup", progress = 0, elapsed = 0, sequenceIndex = 1,
                sequenceLength = 6, pickupPos = lumberPickup, deliveryPos = lumberDelivery,
                interactionRadius = 160, routeDistance = lumberPickup:Distance(lumberDelivery),
                requiredDistance = 1175, carriedDistance = 0,
            },
        },
    } } }, 8, nil)
    MOCK.drawnTextValues = {}
    hook.GetTable().HUDPaint.wo_professions_world_hud()
    local lumberPickupHud, lumberPickupMarker = false, false
    for _, text in ipairs(MOCK.drawnTextValues) do
        lumberPickupHud = lumberPickupHud or text:find("ЛЕСНАЯ ЗАГОТОВКА", 1, true) ~= nil
        lumberPickupMarker = lumberPickupMarker or text == "ШТАБЕЛЬ БРЁВЕН"
    end
    local lumberBind = hook.GetTable().PlayerBindPress.wo_professions_world_bind
    MOCK.Assert(lumberPickupHud and lumberPickupMarker and
        lumberBind(LocalPlayer(), "+use", true) == true,
        "активная смена показывает метку штабеля и E на мировом HUD без общего меню")

    MOCK.TakeOutbox()
    MOCK.keysDown[KEY_E] = true
    hook.GetTable().Think.wo_professions_world_input()
    MOCK.keysDown[KEY_E] = false
    hook.GetTable().Think.wo_professions_world_input()
    local lumberPickupInput = MOCK.FindInbox(MOCK.TakeOutbox(), "Profession.WorkInput")
    MOCK.Assert(#lumberPickupInput == 1 and lumberPickupInput[1].args[1] == "client-lumber-shift" and
        lumberPickupInput[1].args[2] == "pickup" and lumberPickupInput[1].args[3] == true,
        "E у штабеля отправляет серверу только запрос начала мини-игры")

    MOCK.NetDeliver({ name = "Profession.Sync", args = { {
        characterId = "active-test-character", revision = 6, skills = {},
        shift = {
            id = "client-lumber-shift", professionId = "lumberjack", professionName = "Лесоруб",
            npcId = "work_lumberjack", npcName = "Лесоруб", rank = 1,
            completedOrders = 0, requiredOrders = 3, status = "working", basePay = 32, bonus = 0,
            task = {
                orderIndex = 1, mode = "lumber_delivery", engine = "lumber",
                title = "Перенести связку брёвен", instruction = "Отнесите брёвна на склад.",
                phase = "work", progress = 0, elapsed = 0,
                sequenceIndex = 1, sequencePrompt = "up", sequenceCount = 0,
                sequenceLength = 6,
                pickupPos = lumberPickup, deliveryPos = lumberDelivery,
                interactionRadius = 160, routeDistance = lumberPickup:Distance(lumberDelivery),
                requiredDistance = 1175, carriedDistance = 0,
            },
        },
    } } }, 8, nil)
    local lumberWorldHud = hook.GetTable().HUDPaint.wo_professions_world_hud
    local lumberMinigameHud = hook.GetTable().HUDPaint.wo_professions_lumber_minigame_hud
    MOCK.drawnTextValues = {}
    lumberWorldHud()
    local pickupMarkerDuringWork = false
    for _, text in ipairs(MOCK.drawnTextValues) do
        pickupMarkerDuringWork = pickupMarkerDuringWork or text == "ШТАБЕЛЬ БРЁВЕН"
    end
    MOCK.Assert(pickupMarkerDuringWork and isfunction(lumberMinigameHud),
        "во время мини-игры метка штабеля остаётся видимой, а у мини-игры есть отдельный HUD hook")
    lumberMinigameHud()
    local shownDirections = { W = false, A = false, S = false, D = false }
    local lumberCountLabel = false
    for _, text in ipairs(MOCK.drawnTextValues) do
        if shownDirections[text] ~= nil then shownDirections[text] = true end
        lumberCountLabel = lumberCountLabel or text == "Правильные нажатия: 0 / 6"
    end
    MOCK.Assert(shownDirections.W and not shownDirections.A and not shownDirections.S and
        not shownDirections.D and lumberCountLabel,
        "отдельный HUD мини-игры показывает только текущую клавишу W и счёт 0/6")

    MOCK.TakeOutbox()
    MOCK.keysDown[KEY_A] = true
    hook.GetTable().Think.wo_professions_world_input()
    MOCK.keysDown[KEY_A] = false
    hook.GetTable().Think.wo_professions_world_input()
    local lumberWrongInput = MOCK.FindInbox(MOCK.TakeOutbox(), "Profession.WorkInput")
    MOCK.Assert(#lumberWrongInput == 1 and lumberWrongInput[1].args[2] == "left" and
        lumberWrongInput[1].args[3] == true and
        lumberBind(LocalPlayer(), "+moveleft", true) == true,
        "A отправляет одиночное серверное действие, а управление персонажем заблокировано")

    MOCK.NetDeliver({ name = "Profession.Sync", args = { {
        characterId = "active-test-character", revision = 7, skills = {},
        shift = {
            id = "client-lumber-shift", professionId = "lumberjack", professionName = "Лесоруб",
            npcId = "work_lumberjack", npcName = "Лесоруб", rank = 1,
            completedOrders = 0, requiredOrders = 3, status = "working", basePay = 32, bonus = 0,
            task = {
                orderIndex = 1, mode = "lumber_delivery", engine = "lumber",
                title = "Перенести связку брёвен", instruction = "Отнесите брёвна на склад.",
                phase = "pickup", progress = 0, elapsed = 0,
                sequenceIndex = 1, sequenceLastInputCorrect = false,
                sequenceLength = 6, pickupPos = lumberPickup, deliveryPos = lumberDelivery,
                interactionRadius = 160, routeDistance = lumberPickup:Distance(lumberDelivery),
                requiredDistance = 1175, carriedDistance = 0,
            },
        },
    } } }, 8, nil)
    LocalPlayer():SetPos(lumberPickup)
    MOCK.drawnTextValues = {}
    lumberWorldHud()
    lumberMinigameHud()
    local lumberFailureShown, lumberRestartHint, failurePickupMarker = false, false, false
    local stalePromptShown = false
    for _, text in ipairs(MOCK.drawnTextValues) do
        lumberFailureShown = lumberFailureShown or text == "МИНИ-ИГРА ПРОВАЛЕНА"
        lumberRestartHint = lumberRestartHint or text:find("начать заново", 1, true) ~= nil
        failurePickupMarker = failurePickupMarker or text == "ШТАБЕЛЬ БРЁВЕН"
        stalePromptShown = stalePromptShown or text == "W" or text == "A" or text == "S" or text == "D"
    end
    MOCK.Assert(lumberFailureShown and lumberRestartHint and failurePickupMarker and
        not stalePromptShown,
        "после ошибки HUD показывает провал и повторное E у штабеля, но скрывает WASD-подсказку")

    MOCK.TakeOutbox()
    MOCK.keysDown[KEY_E] = true
    hook.GetTable().Think.wo_professions_world_input()
    MOCK.keysDown[KEY_E] = false
    hook.GetTable().Think.wo_professions_world_input()
    local lumberRestartInput = MOCK.FindInbox(MOCK.TakeOutbox(), "Profession.WorkInput")
    MOCK.Assert(#lumberRestartInput == 1 and lumberRestartInput[1].args[2] == "pickup" and
        lumberRestartInput[1].args[3] == true,
        "после провала клиент требует отдельное нажатие E для повтора")

    MOCK.NetDeliver({ name = "Profession.Sync", args = { {
        characterId = "active-test-character", revision = 8, skills = {},
        shift = {
            id = "client-lumber-shift", professionId = "lumberjack", professionName = "Лесоруб",
            npcId = "work_lumberjack", npcName = "Лесоруб", rank = 1,
            completedOrders = 0, requiredOrders = 3, status = "working", basePay = 32, bonus = 0,
            task = {
                orderIndex = 1, mode = "lumber_delivery", engine = "lumber",
                title = "Перенести связку брёвен", instruction = "Отнесите брёвна на склад.",
                phase = "work", progress = 0, elapsed = 0,
                sequenceIndex = 1, sequencePrompt = "up", sequenceCount = 0,
                sequenceLength = 6, sequenceLastInputCorrect = nil,
                pickupPos = lumberPickup, deliveryPos = lumberDelivery,
                interactionRadius = 160, routeDistance = lumberPickup:Distance(lumberDelivery),
                requiredDistance = 1175, carriedDistance = 0,
            },
        },
    } } }, 8, nil)
    MOCK.drawnTextValues = {}
    lumberWorldHud()
    lumberMinigameHud()
    MOCK.TakeOutbox()
    MOCK.keysDown[KEY_W] = true
    hook.GetTable().Think.wo_professions_world_input()
    MOCK.keysDown[KEY_W] = false
    hook.GetTable().Think.wo_professions_world_input()
    local lumberDirectionInput = MOCK.FindInbox(MOCK.TakeOutbox(), "Profession.WorkInput")
    MOCK.Assert(#lumberDirectionInput == 1 and lumberDirectionInput[1].args[2] == "up" and
        lumberDirectionInput[1].args[3] == true and
        lumberBind(LocalPlayer(), "+forward", true) == true,
        "после повторного E новая подсказка W отправляется серверу, а движение заблокировано")

    MOCK.NetDeliver({ name = "Profession.Sync", args = { {
        characterId = "active-test-character", revision = 9, skills = {},
        shift = {
            id = "client-lumber-shift", professionId = "lumberjack", professionName = "Лесоруб",
            npcId = "work_lumberjack", npcName = "Лесоруб", rank = 1,
            completedOrders = 0, requiredOrders = 3, status = "working", basePay = 32, bonus = 0,
            task = {
                orderIndex = 1, mode = "lumber_delivery", engine = "lumber",
                title = "Перенести связку брёвен", instruction = "Отнесите брёвна на склад.",
                phase = "work", progress = 1 / 6, elapsed = 0,
                sequenceIndex = 2, sequencePrompt = "left", sequenceCount = 1,
                sequenceLength = 6, sequenceLastInputCorrect = true,
                pickupPos = lumberPickup, deliveryPos = lumberDelivery,
                interactionRadius = 160, routeDistance = lumberPickup:Distance(lumberDelivery),
                requiredDistance = 1175, carriedDistance = 0,
            },
        },
    } } }, 8, nil)
    MOCK.drawnTextValues = {}
    lumberWorldHud()
    lumberMinigameHud()
    shownDirections = { W = false, A = false, S = false, D = false }
    lumberCountLabel = false
    local correctFeedback = false
    for _, text in ipairs(MOCK.drawnTextValues) do
        if shownDirections[text] ~= nil then shownDirections[text] = true end
        lumberCountLabel = lumberCountLabel or text == "Правильные нажатия: 1 / 6"
        correctFeedback = correctFeedback or text == "Верно! Следующая подсказка уже готова."
    end
    MOCK.Assert(shownDirections.A and not shownDirections.W and not shownDirections.S and
        not shownDirections.D and lumberCountLabel and correctFeedback,
        "после правильного нажатия HUD сменяет подсказку на A и обновляет прогресс 1/6")

    MOCK.NetDeliver({ name = "Profession.Sync", args = { {
        characterId = "active-test-character", revision = 10, skills = {},
        shift = {
            id = "client-lumber-shift", professionId = "lumberjack", professionName = "Лесоруб",
            npcId = "work_lumberjack", npcName = "Лесоруб", rank = 1,
            completedOrders = 0, requiredOrders = 3, status = "working", basePay = 32, bonus = 0,
            task = {
                orderIndex = 1, mode = "lumber_delivery", engine = "lumber",
                title = "Перенести связку брёвен", instruction = "Отнесите брёвна на склад.",
                phase = "carry", progress = 1, elapsed = 0,
                sequenceIndex = 7, sequenceCount = 6, sequenceLength = 6,
                pickupPos = lumberPickup, deliveryPos = lumberDelivery,
                interactionRadius = 160, routeDistance = lumberPickup:Distance(lumberDelivery),
                requiredDistance = 1175, carriedDistance = 0,
            },
        },
    } } }, 8, nil)
    MOCK.drawnTextValues = {}
    hook.GetTable().HUDPaint.wo_professions_world_hud()
    local lumberCarryHud = false
    for _, text in ipairs(MOCK.drawnTextValues) do
        lumberCarryHud = lumberCarryHud or text:find("СКЛАД БРЁВЕН", 1, true) ~= nil
    end
    MOCK.Assert(lumberCarryHud and
        lumberBind(LocalPlayer(), "+speed", true) == true and
        lumberBind(LocalPlayer(), "+jump", true) == true and
        lumberBind(LocalPlayer(), "slot1", true) == true and
        lumberBind(LocalPlayer(), "+forward", true) == nil,
        "при переносе интерфейс блокирует Shift, прыжок и смену оружия, оставляя ходьбу доступной")
    MOCK.TakeOutbox()
    MOCK.keysDown[KEY_E] = true
    hook.GetTable().Think.wo_professions_world_input()
    MOCK.keysDown[KEY_E] = false
    hook.GetTable().Think.wo_professions_world_input()
    local lumberDropInput = MOCK.FindInbox(MOCK.TakeOutbox(), "Profession.WorkInput")
    MOCK.Assert(#lumberDropInput == 1 and lumberDropInput[1].args[2] == "drop" and
        lumberDropInput[1].args[3] == true,
        "E у склада отправляет серверу запрос сдачи брёвен")

    MOCK.NetDeliver({ name = "Profession.Sync", args = { {
        characterId = "active-test-character", revision = 11, skills = {},
        shift = {
            id = "client-lumber-shift", professionId = "lumberjack", professionName = "Лесоруб",
            npcId = "work_lumberjack", npcName = "Лесоруб", rank = 1,
            completedOrders = 1, requiredOrders = 3, status = "working", basePay = 32, bonus = 0,
            task = {
                orderIndex = 2, mode = "lumber_delivery", engine = "lumber",
                title = "Перенести связку брёвен", instruction = "Отнесите брёвна на склад.",
                phase = "pickup", progress = 0, sequenceLength = 6,
                pickupPos = lumberPickup, deliveryPos = lumberDelivery,
                interactionRadius = 160, routeDistance = lumberPickup:Distance(lumberDelivery),
                requiredDistance = 1175, carriedDistance = 0,
            },
        },
    } } }, 8, nil)
    MOCK.drawnTextValues = {}
    lumberWorldHud()
    local nextOrderPickupMarker, staleDeliveryMarker = false, false
    for _, text in ipairs(MOCK.drawnTextValues) do
        nextOrderPickupMarker = nextOrderPickupMarker or text == "ШТАБЕЛЬ БРЁВЕН"
        staleDeliveryMarker = staleDeliveryMarker or text == "СКЛАД БРЁВЕН"
    end
    MOCK.Assert(nextOrderPickupMarker and not staleDeliveryMarker,
        "после сдачи связки метка переносится со склада обратно к штабелю следующего заказа")

    MOCK.NetDeliver({ name = "Profession.Sync", args = { {
        characterId = "active-test-character", revision = 12, skills = {},
        shift = {
            id = "client-lumber-shift", professionId = "lumberjack", professionName = "Лесоруб",
            npcId = "work_lumberjack", npcName = "Лесоруб", rank = 1,
            completedOrders = 3, requiredOrders = 3, status = "ready", basePay = 32, bonus = 0,
        },
    } } }, 8, nil)
    MOCK.drawnTextValues = {}
    lumberWorldHud()
    local markerShownOutsideWork = false
    for _, text in ipairs(MOCK.drawnTextValues) do
        markerShownOutsideWork = markerShownOutsideWork or
            text == "ШТАБЕЛЬ БРЁВЕН" or text == "СКЛАД БРЁВЕН"
    end
    MOCK.Assert(not markerShownOutsideWork,
        "мировые метки лесоруба исчезают после завершения рабочих заказов")

    MOCK.NetDeliver({ name = "Profession.Sync", args = { {
        characterId = "active-test-character", revision = 13, skills = {}, shift = nil,
    } } }, 8, nil)
    MOCK.mapName = previousLumberTestMap
end

do
    -- Simulate the post-creation transition into the world, where stale character
    -- selection UI must no longer own TAB or ESC.
    if WO.CharacterUI.CloseMenus then WO.CharacterUI.CloseMenus() end

    local bindHandler = hook.GetTable().PlayerBindPress.wo_menu_scoreboard_bind
    WO.MenuUI.Close()
    MOCK.Assert(bindHandler(LocalPlayer(), "+showscores", true) == true and
        WO.MenuUI.IsOpen() and WO.MenuUI.GetPage() == "overview",
        "после создания персонажа TAB открывает кастомное игровое меню")
    MOCK.Assert(bindHandler(LocalPlayer(), "+showscores", false) == true and
        not WO.MenuUI.IsOpen(), "после создания персонажа отпускание TAB закрывает меню")

    local pauseHandler = hook.GetTable().OnPauseMenuShow.wo_menu_escape_toggle
    MOCK.Assert(isfunction(pauseHandler), "Escape перехватывает попытку открыть паузу GMod")
    MOCK.Assert(pauseHandler() == false and WO.MenuUI.IsOpen() and
        WO.MenuUI.GetPage() == "overview", "одиночное нажатие Escape открывает своё меню")

    local escapeFrame = FindLatestLiveFrame()
    escapeFrame:OnKeyCodePressed(KEY_ESCAPE)
    MOCK.Assert(WO.MenuUI.IsOpen(), "два пути одного нажатия Escape не переключают меню дважды")
    MOCK.RunTimers(0)

    escapeFrame = FindLatestLiveFrame()
    escapeFrame:OnKeyCodePressed(KEY_ESCAPE)
    MOCK.Assert(not WO.MenuUI.IsOpen(), "следующее нажатие Escape закрывает своё меню")
    MOCK.RunTimers(0)

    MOCK.Assert(pauseHandler() == false and WO.MenuUI.IsOpen(),
        "повторное нажатие Escape снова открывает меню")
    MOCK.RunTimers(0)
    MOCK.Assert(pauseHandler() == false and not WO.MenuUI.IsOpen(),
        "следующее одиночное нажатие Escape снова закрывает меню")
    MOCK.RunTimers(0)
end

MOCK.Assert(hudShouldDraw.wo_hud_hide("CHudHealth") == false and
    hudShouldDraw.wo_hud_hide("CHudScoreboard") == false and
    hudShouldDraw.wo_hud_hide("CHudDeathNotice") == false and
    hudDrawTargetID.wo_hud_hide_targetid() == false and
    hudShouldDraw.wo_hud_hide("CHudCrosshair") == false and
    hudShouldDraw.wo_hud_hide("CHudWeaponSelection") == false,
    "WoW HUD replaces all stock HUD elements, killfeed, target names, crosshair and weapon selector")
WO.MenuUI.Close()

local localWeaponPlayer = LocalPlayer()
localWeaponPlayer:Give("drc_unarmed")
localWeaponPlayer:Give("tfa_cso_coldsteelblade")
localWeaponPlayer:SelectWeapon("drc_unarmed")
local selectorWeapons = WO.WeaponSelector.GetVisibleWeapons(localWeaponPlayer)
local selectorClasses = {}
for _, entry in ipairs(selectorWeapons) do selectorClasses[entry.class] = true end
MOCK.Assert(#selectorWeapons == 2 and selectorClasses.drc_unarmed and
    selectorClasses.tfa_cso_coldsteelblade and
    isfunction(WO.HUD.DrawWeaponSelector) and
    WO.WeaponSelector.IsVisible(localWeaponPlayer) == false,
    "селектор содержит только выданные SWEP и скрыт до нажатия клавиши")
local weaponBind = hook.GetTable().PlayerBindPress.wo_weapon_selector_bind
MOCK.TakeOutbox()
MOCK.Assert(isfunction(weaponBind) and weaponBind(localWeaponPlayer, "invnext", true) == true,
    "обычное колесо мыши блокируется для смены оружия")
local scrollSelectionOutbox = MOCK.TakeOutbox()
MOCK.Assert(#MOCK.FindInbox(scrollSelectionOutbox, "Weapons.Select") == 0 and
    localWeaponPlayer:GetActiveWeapon():GetClass() == "drc_unarmed",
    "колёсико больше не отправляет запрос и не меняет активное оружие")

-- More than six and more than ten SWEPs must still expose the complete numeric
-- window; the tenth standard slot is bound to key 0.
for index = 1, 10 do
    local class = string.format("wo_selector_test_%02d", index)
    weapons.Register({ PrintName = "Test weapon " .. index, Slot = index, SlotPos = 0 }, class)
    localWeaponPlayer:Give(class)
end
local allSelectorWeapons = WO.WeaponSelector.GetWeapons(localWeaponPlayer)
local numericWindow = WO.WeaponSelector.GetVisibleWeapons(localWeaponPlayer)
local expectedKeys = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 0 }
local numericWindowValid = #allSelectorWeapons == 12 and #numericWindow == 10
for index, key in ipairs(expectedKeys) do
    numericWindowValid = numericWindowValid and numericWindow[index] ~= nil and
        numericWindow[index].key == key
end
MOCK.Assert(numericWindowValid,
    "селектор показывает десять SWEP одновременно и подписывает десятый клавишей 0")

local lastSelectedWeapon

for _, key in ipairs(expectedKeys) do
    MOCK.AdvanceTime(1) -- let the previous optimistic selection expire
    local visible = WO.WeaponSelector.GetVisibleWeapons(localWeaponPlayer)
    local expected

    for _, entry in ipairs(visible) do
        if entry.key == key then expected = entry.class break end
    end

    MOCK.TakeOutbox()
    local bind = "slot" .. tostring(key == 0 and 10 or key)
    MOCK.Assert(expected ~= nil and weaponBind(localWeaponPlayer, bind, true) == true,
        "keyboard slot bind is consumed for key " .. tostring(key))
    local slotMessages = MOCK.FindInbox(MOCK.TakeOutbox(), "Weapons.Select")
    MOCK.Assert(#slotMessages == 1 and slotMessages[1].args[1] == expected,
        "keyboard key " .. tostring(key) .. " selects its visible owned SWEP")
    lastSelectedWeapon = expected
end

MOCK.Assert(WO.WeaponSelector.IsVisible(localWeaponPlayer),
    "числовой выбор временно показывает selector, пока сервер не подтвердил смену")
localWeaponPlayer:SelectWeapon(lastSelectedWeapon) -- simulate authoritative server selection
MOCK.Assert(not WO.WeaponSelector.IsVisible(localWeaponPlayer),
    "selector исчезает сразу после подтверждения выбранного оружия сервером")
MOCK.Assert(weaponBind(localWeaponPlayer, "slot1", true) == true and
    WO.WeaponSelector.IsVisible(localWeaponPlayer),
    "следующий выбор цифрой снова кратковременно показывает selector")
MOCK.AdvanceTime(1)
MOCK.Assert(not WO.WeaponSelector.IsVisible(localWeaponPlayer),
    "selector автоматически скрывается, если подтверждение сервера не пришло")

local aimWeapon = MOCK.NewEntity("weapon")
aimWeapon.__weaponClass = "wo_test_melee"
aimWeapon.__methods.GetClass = function(self) return self.__weaponClass end
aimWeapon.WORange = 80
aimWeapon.WOAttackSpeed = 1
aimWeapon.WOStaminaCost = 2
localWeaponPlayer:SetActiveWeapon(aimWeapon)
local oldTraceLine = util.TraceLine
local aimTraceCalls = {}
local aimedTarget = MOCK.NewEntity("npc")
util.TraceLine = function(data)
    aimTraceCalls[#aimTraceCalls + 1] = data
    return { Hit = true, HitPos = Vector(0, 120, 64), Entity = aimedTarget }
end
local attackTrace, attackEnd = WO.HUD.GetAimTrace(localWeaponPlayer)
local expectedShootPos = localWeaponPlayer:GetShootPos()
local expectedAimEnd = expectedShootPos + localWeaponPlayer:GetAimVector() * 80
MOCK.Assert(attackTrace and attackTrace.Entity == aimedTarget and #aimTraceCalls == 1 and
    aimTraceCalls[1].start.x == expectedShootPos.x and
    aimTraceCalls[1].start.y == expectedShootPos.y and
    aimTraceCalls[1].start.z == expectedShootPos.z and
    aimTraceCalls[1].endpos.x == expectedAimEnd.x and
    aimTraceCalls[1].endpos.y == expectedAimEnd.y and
    aimTraceCalls[1].endpos.z == expectedAimEnd.z and
    attackEnd.y == expectedAimEnd.y and aimTraceCalls[1].mask == MASK_SHOT_HULL,
    "прицел трассируется из shoot position по тому же направлению и дистанции, что атака SWEP")
util.TraceLine = oldTraceLine

local stranger = MOCK.CreatePlayer("Private Nick", "STEAM_0:0:991")
stranger:SetNW2Bool("wo_char_active", true)
stranger:SetNW2String("wo_character_id", "remote-character")
stranger:SetNW2String("wo_race", "orc")
stranger:SetNW2String("wo_class", "mage")
stranger:SetNW2Int("wo_level", 12)
stranger:SetPos(LocalPlayer():GetPos() + Vector(100, 0, 0))
local unknownIdentity = WO.Social.GetVisibleIdentity(stranger)
MOCK.Assert(unknownIdentity.known == false and unknownIdentity.name == "Неизвестный" and
    unknownIdentity.race == WO.Races.Get("orc").name and
    unknownIdentity.class == nil and unknownIdentity.level == nil,
    "до знакомства публичны только «Неизвестный» и раса")
MOCK.drawnTextValues = {}
WO.HUD.DrawPlayerNameplates()
local defaultPlateHasName, defaultPlateHasRace, defaultPlateLeaksClass = false, false, false
for _, text in ipairs(MOCK.drawnTextValues) do
    if text == "Неизвестный" then defaultPlateHasName = true end
    if text == WO.Races.Get("orc").name then defaultPlateHasRace = true end
    if text == "Маг" or text == "ур. 12" then defaultPlateLeaksClass = true end
end
MOCK.Assert(defaultPlateHasName and defaultPlateHasRace and not defaultPlateLeaksClass,
    "nameplate до знакомства не раскрывает уровень или класс")
WO.MenuUI.Show("overview")
local privateScoreboardRow
for index = #MOCK.createdPanels, 1, -1 do
    local panel = MOCK.createdPanels[index]
    local parent = rawget(panel, "__parent")
    if rawget(panel, "woScoreboardRow") == true and isfunction(panel.Paint) and parent then
        privateScoreboardRow = panel
        break
    end
end
MOCK.Assert(privateScoreboardRow ~= nil, "общее меню создаёт строки списка игроков")
MOCK.drawnTextValues = {}
privateScoreboardRow:Paint(640, 48)
local privateRowText = table.concat(MOCK.drawnTextValues, " ")
MOCK.Assert(string.find(privateRowText, "Неизвестный", 1, true) and
    string.find(privateRowText, WO.Races.Get("orc").name, 1, true) and
    not string.find(privateRowText, "Private Nick", 1, true) and
    not string.find(privateRowText, "Маг", 1, true) and
    not string.find(privateRowText, "12", 1, true),
    "scoreboard скрывает личность, класс и уровень незнакомого игрока")
WO.MenuUI.Close()
MOCK.NetDeliver({ name = "Social.Sync", args = { {
    { characterId = "remote-character", name = "Бран Торн", raceId = "orc",
        classId = "warrior", level = 12 },
} } }, 8, nil)
local knownIdentity = WO.Social.GetVisibleIdentity(stranger)
MOCK.Assert(knownIdentity.known and knownIdentity.name == "Бран Торн" and
    knownIdentity.class == WO.Classes.Get("warrior").name and knownIdentity.level == 12,
    "серверная запись знакомства раскрывает имя, уровень, класс и расу")
MOCK.NetDeliver({ name = "Social.Sync", args = { {
    { characterId = "remote-character", name = "Бран Торн", raceId = "orc",
        classId = "warrior", level = 13 },
} } }, 8, nil)
MOCK.Assert(WO.Social.GetVisibleIdentity(stranger).level == 13,
    "обновлённый Social.Sync немедленно меняет уровень сохранённого знакомства")

local f2Bound = false
for _, bind in ipairs(WO.UI.Binds or {}) do
    if bind.id == "social_introduction" and bind.key == KEY_F2 then f2Bound = true end
end
MOCK.Assert(f2Bound and WO.Social.IntroductionModes.whisper.range <
    WO.Social.IntroductionModes.talk.range and
    WO.Social.IntroductionModes.talk.range < WO.Social.IntroductionModes.shout.range,
    "F2 открывает меню знакомства с разными радиусами шёпота/разговора/крика")
WO.Social.OpenIntroductionMenu()
local whisperButton = MOCK.FindPanelByText("Шёпотом — радиус 180")
MOCK.Assert(whisperButton ~= nil, "меню F2 отображает точный вариант радиуса шёпота")
MOCK.TakeOutbox()
whisperButton.DoClick(whisperButton)
local introductionOutbox = MOCK.TakeOutbox()
local introductionMessages = MOCK.FindInbox(introductionOutbox, "Social.Introduce")
MOCK.Assert(#introductionMessages == 1 and introductionMessages[1].args[1] == "whisper",
    "выбор радиуса отправляет серверу только идентификатор режима знакомства")

-- Клиентский NW2-флаг может запаздывать после respawn; при активном snapshot
-- кастомный HUD всё равно должен рисоваться. Валюта в player frame не входит.
LocalPlayer():SetNW2Bool("wo_inmenu", true)
MOCK.drawnTextValues = {}
local hudDrawsBefore = MOCK.drawTextCalls
local crosshairLinesBefore = MOCK.surfaceLineCalls
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
MOCK.Assert(MOCK.surfaceLineCalls > crosshairLinesBefore,
    "HUDPaint вызывает пользовательский прицел, а не только экспортирует функцию")
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

local hoverNPC = MOCK.NewEntity("npc")
local unmountedTargetModel = "models/mailer/wow_characters/target_preview_test.mdl"
MOCK.mountedFiles[unmountedTargetModel] = nil
hoverNPC:SetModel(unmountedTargetModel)
LocalPlayer():SetNW2Entity("wo_target", hoverNPC)
WO.HUD.DrawTargetFrame()
local targetPreviewUsedConfiguredPath = false
for _, panel in ipairs(MOCK.createdPanels) do
    if rawget(panel, "__lastSetModelPath") == unmountedTargetModel then
        targetPreviewUsedConfiguredPath = true
        break
    end
end
MOCK.Assert(targetPreviewUsedConfiguredPath,
    "HUD target portrait attempts its model path directly without file.Exists gating")
LocalPlayer():SetNW2Entity("wo_target", nil)
hoverNPC:SetNW2String("wo_npc_id", "black_wolf")
hoverNPC:SetNW2String("wo_name", "Волк")
hoverNPC:SetNW2Int("wo_level", 4)
hoverNPC:SetHealth(72)
hoverNPC:SetMaxHealth(120)
hoverNPC.__methods.OBBMaxs = function() return Vector(16, 16, 96) end
local oldNPCTraceLine = util.TraceLine
util.TraceLine = function()
    return { Hit = true, HitPos = hoverNPC:GetPos() + Vector(0, 0, 48), Entity = hoverNPC }
end
WO.HUD.DrawCrosshair()
MOCK.lastHalo = nil
local npcHaloHook = hook.GetTable().PreDrawHalos.wo_npc_aim_highlight
if isfunction(npcHaloHook) then npcHaloHook() end
MOCK.drawnTextValues = {}
WO.HUD.DrawHoverNPC()
local hoverText = table.concat(MOCK.drawnTextValues, " ")
MOCK.Assert(string.find(hoverText, "Волк", 1, true) and
    string.find(hoverText, "Ур.", 1, true) and
    string.find(hoverText, "72 / 120", 1, true) and
    MOCK.lastHalo and MOCK.lastHalo.entities[1] == hoverNPC,
    "NPC под прицелом подсвечивается и получает компактную WoW-плашку с именем, уровнем и HP")
util.TraceLine = oldNPCTraceLine

local savedTraceLine, savedTraceHull = util.TraceLine, util.TraceHull
local targetTraceCalls = 0
util.TraceLine = function(traceData)
    targetTraceCalls = targetTraceCalls + 1

    if targetTraceCalls == 1 then
        return { Hit = false, HitPos = traceData.endpos, Entity = nil }
    end

    return { Hit = true, HitPos = hoverNPC:GetPos(), Entity = hoverNPC }
end
util.TraceHull = function(traceData)
    return { Hit = false, HitPos = traceData.endpos, Entity = nil }
end
WO.HUD.DrawCrosshair()
MOCK.Assert(WO.HUD.GetHoveredNPC() == hoverNPC and targetTraceCalls == 2,
    "NPC HUD target keeps the attack direction but remains visible beyond melee range")
util.TraceLine, util.TraceHull = savedTraceLine, savedTraceHull

MOCK.NetDeliver({ name = "Combat.DamageNumber", args = { {
    position = Vector(20, 40, 80), amount = 42, critical = true,
} } }, 8, nil)
MOCK.drawTextDetails = {}
WO.HUD.DrawDamageNumbers()
local firstDamageText
for _, detail in ipairs(MOCK.drawTextDetails) do
    if detail.text:find("CRIT  -42", 1, true) then firstDamageText = detail break end
end
MOCK.Assert(firstDamageText and firstDamageText.color.a == 255 and
    isfunction(WO.HUD.DrawCrosshair) and isfunction(WO.HUD.DrawPlayerNameplates),
    "HUD рисует яркое WoW-style critical damage number поверх NPC/игроков")
MOCK.AdvanceTime(0.8)
MOCK.drawTextDetails = {}
WO.HUD.DrawDamageNumbers()
local fadedDamageText
for _, detail in ipairs(MOCK.drawTextDetails) do
    if detail.text:find("CRIT  -42", 1, true) then fadedDamageText = detail break end
end
MOCK.Assert(fadedDamageText and fadedDamageText.color.a < firstDamageText.color.a and
    fadedDamageText.outlineColor.a < firstDamageText.outlineColor.a and
    fadedDamageText.y < firstDamageText.y,
    "floating damage number поднимается вверх и плавно затухает вместе с обводкой")
MOCK.AdvanceTime(0.9)
MOCK.drawTextDetails = {}
WO.HUD.DrawDamageNumbers()
local expiredDamageNumber = false
for _, detail in ipairs(MOCK.drawTextDetails) do
    if detail.text:find("CRIT  -42", 1, true) then expiredDamageNumber = true end
end
MOCK.Assert(not expiredDamageNumber,
    "floating damage number удаляется после завершения fade-анимации")
WO.HUD.DrawCrosshair()

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

local hoverItem = ents.Create("wo_item_world")
hoverItem:SetPos(LocalPlayer():GetPos() + Vector(25, 0, 0))
local hoverInstance = WO.Items.CreateInstance("wolf_pelt", 2)
MOCK.Assert(hoverItem:SetItem(hoverInstance) and isfunction(hoverItem.Draw) and
    hoverItem:CanInteract(LocalPlayer()) == false,
    "world resource exposes safe hover data, Draw, and the replicated short pickup cooldown")
local modelLessWorldItem = ents.Create("wo_item_world")
local modelLessInstance = WO.Items.CreateInstance("starter_knife", 1)
MOCK.Assert(modelLessWorldItem:SetItem(modelLessInstance) and
    modelLessWorldItem:GetModel() == "models/props_junk/PopCan01a.mdl",
    "предмет мира без model definition получает видимую базовую модель")
MOCK.AdvanceTime(1.1)
MOCK.Assert(hoverItem:CanInteract(LocalPlayer()) == true,
    "E становится доступной клиенту сразу после короткого серверного кулдауна")
local savedEyeTrace = LocalPlayer().__methods.GetEyeTrace
LocalPlayer().__methods.GetEyeTrace = function()
    return { Entity = hoverItem, Hit = true, HitPos = hoverItem:GetPos() }
end
WO.Interaction.UpdateClientTarget()
local resourceHoverInfo = WO.Interaction.GetHoveredResourceInfo()
MOCK.Assert(resourceHoverInfo and resourceHoverInfo.entity == hoverItem and
    resourceHoverInfo.name == WO.Items.Get("wolf_pelt").name and
    resourceHoverInfo.description == WO.Items.Get("wolf_pelt").description and
    resourceHoverInfo.amount == 2,
    "подсказка ресурса собирает название, описание и количество из безопасной схемы/NW2")
local interactionBind = hook.GetTable().PlayerBindPress.wo_interaction_use_request
MOCK.TakeOutbox()
MOCK.Assert(isfunction(interactionBind) and
    interactionBind(LocalPlayer(), "+use", true) == true,
    "клавиша E отправляет серверно проверяемый запрос подбора физического loot")
local interactionRequests = MOCK.FindInbox(MOCK.TakeOutbox(), "Interact.Request")
MOCK.Assert(#interactionRequests == 1 and
    interactionRequests[1].args[1] == hoverItem:EntIndex(),
    "клиент запрашивает взаимодействие только с прицельной сущностью")
MOCK.frameTime = 0.25
MOCK.drawnTextValues = {}
hook.GetTable().HUDPaint.wo_interaction_paint()
hook.GetTable().PreDrawHalos.wo_resource_hover_halo()
MOCK.Assert(MOCK.lastHalo and MOCK.lastHalo.entities[1] == hoverItem and
    table.concat(MOCK.drawnTextValues, " "):find("Волчья шкура", 1, true) ~= nil,
    "ресурс получает лёгкий halo и плавную карточку при наведении")
local assistedItem = ents.Create("wo_item_world")
assistedItem:SetPos(LocalPlayer():GetPos() + Vector(0, 48, 0))
MOCK.Assert(assistedItem:SetItem(WO.Items.CreateInstance("wolf_fang", 1)),
    "проверка E-assist создаёт малую цель добычи перед игроком")
MOCK.AdvanceTime(0.3)
LocalPlayer().__methods.GetEyeTrace = function()
    return { Entity = nil, Hit = true, HitPos = LocalPlayer():GetPos() + Vector(0, 60, 0) }
end
WO.Interaction.UpdateClientTarget()
MOCK.Assert(WO.Interaction.GetHoveredResourceInfo() and
    WO.Interaction.GetHoveredResourceInfo().entity == assistedItem,
    "близкая добыча в направлении взгляда выбирается даже без попадания eye trace")
MOCK.TakeOutbox()
MOCK.Assert(interactionBind(LocalPlayer(), "+use", true) == true,
    "E отправляет серверный запрос для ближайшей мелкой добычи без прямого попадания")
local assistedRequest = MOCK.FindInbox(MOCK.TakeOutbox(), "Interact.Request")
MOCK.Assert(#assistedRequest == 1 and assistedRequest[1].args[1] == assistedItem:EntIndex(),
    "ассистированный подбор передаёт серверу только индекс физической сущности")
LocalPlayer().__methods.GetEyeTrace = savedEyeTrace
MOCK.frameTime = nil
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

local potionDef = WO.Items.Get("health_potion")
local originalPotionModel = potionDef.model
MOCK.mountedFiles[originalPotionModel] = true
local potionSlot = WO.UI.ItemSlot(nil)
potionSlot:SetItem({ class = "health_potion", uid = "potion-icon-test", amount = 1 })
MOCK.Assert(IsValid(potionSlot.itemIcon) and IsValid(potionSlot.itemIcon.Entity) and
    potionSlot.itemIcon:GetCamPos() ~= nil,
    "зелье здоровья получает DModelPanel с рассчитанной камерой для малого пропа")
potionDef.model = "models/missing/health_potion.mdl"
potionSlot:SetItem({ class = "health_potion", uid = "potion-fallback-test", amount = 1 })
MOCK.drawnTextValues = {}
potionSlot:Paint(64, 64)
MOCK.Assert(not IsValid(potionSlot.itemIcon) and
    table.concat(MOCK.drawnTextValues, " "):find("✚", 1, true) ~= nil,
    "при недоступной модели зелье всё равно показывает читаемую fallback-иконку")
potionDef.model = originalPotionModel
local modelLessSlot = WO.UI.ItemSlot(nil)
modelLessSlot:SetItem({ class = "starter_knife", uid = "knife-icon-test", amount = 1 })
MOCK.drawnTextValues = {}
modelLessSlot:Paint(64, 64)
MOCK.Assert(table.concat(MOCK.drawnTextValues, " "):find("Н", 1, true) ~= nil,
    "предметы без 3D-модели отображают заданный iconText")

do
local panelsBeforeInventory = #MOCK.createdPanels
PressKey(KEY_I)
local inventoryMenuFrame = FindLatestLiveFrame()
MOCK.Assert(#MOCK.createdPanels > panelsBeforeInventory and inventoryMenuFrame and
    WO.MenuUI.IsOpen() and WO.MenuUI.GetPage() == "inventory",
    "клавиша I открывает инвентарь внутри игрового меню")

local inventoryRoot
for i = #MOCK.createdPanels, 1, -1 do
    local candidate = MOCK.createdPanels[i]
    if rawget(candidate, "woInventoryPage") == true and rawget(candidate, "__removed") ~= true then
        inventoryRoot = candidate
        break
    end
end
MOCK.Assert(inventoryRoot ~= nil and rawget(inventoryRoot, "__class") == "DPanel",
    "инвентарь встроен в страницу меню, отдельное окно не создаётся")

local inventoryScroll
for _, child in ipairs(inventoryRoot.__children) do
    if rawget(child, "__class") == "DScrollPanel" then inventoryScroll = child end
end
local inventoryLayout = inventoryScroll and inventoryScroll.__children[1]
local inventoryPanelCount = inventoryLayout and #inventoryLayout.__children or 0
MOCK.Assert(inventoryPanelCount >= 2, "инвентарь и экипировка остаются отдельными панелями")
MOCK.Assert(WO.InventoryUI.IsOpen(), "интегрированный инвентарь сообщает открытое состояние")
PressKey(KEY_I)
MOCK.Assert(WO.MenuUI.IsOpen() and WO.MenuUI.GetPage() == "overview" and
    not WO.InventoryUI.IsOpen() and FindLatestLiveFrame() == inventoryMenuFrame,
    "повторное I возвращает в обзор того же окна меню")
PressKey(KEY_I)
MOCK.Assert(WO.MenuUI.GetPage() == "inventory" and WO.InventoryUI.IsOpen() and
    FindLatestLiveFrame() == inventoryMenuFrame,
    "I открывает страницу инвентаря в том же уже открытом меню")
local itemSlotPanel
for index = #MOCK.createdPanels, 1, -1 do
    local panel = MOCK.createdPanels[index]
    if rawget(panel, "__class") == "WO_ItemSlot" and rawget(panel, "item") ~= nil and
        rawget(panel, "__removed") ~= true and isfunction(rawget(panel, "OnContextMenu")) then
        itemSlotPanel = panel
        break
    end
end
MOCK.Assert(itemSlotPanel ~= nil and WO.Items.Get("mount_stone").useHandler ~= nil,
    "контекстное меню предмета поддерживает utility-items с useHandler")
itemSlotPanel.OnContextMenu(itemSlotPanel, { class = "mount_stone", uid = "mount-test-stone" })
local mountContextMenu = MOCK.dermaMenus[#MOCK.dermaMenus]
MOCK.Assert(mountContextMenu and mountContextMenu.options[1] and
    mountContextMenu.options[1].text == WO.Lang:Get("inventory.use"),
    "камень маунта получает пункт «использовать» в контекстном меню")
MOCK.TakeOutbox()
mountContextMenu.options[1].callback()
local mountUseOutbox = MOCK.TakeOutbox()
local mountUseMessages = MOCK.FindInbox(mountUseOutbox, "Inventory.Use")
MOCK.Assert(#mountUseMessages == 1 and mountUseMessages[1].args[1] == "mount-test-stone",
    "пункт контекстного меню отправляет UID камня на серверное использование")
WO.InventoryUI.Close()

local panelsBeforeOverview = #MOCK.createdPanels
WO.CharacterUI.OpenSheet()
MOCK.Assert(#MOCK.createdPanels > panelsBeforeOverview and WO.MenuUI.IsOpen() and
    WO.MenuUI.GetPage() == "overview",
    "совместимый вызов листа персонажа открывает обзор общего меню")
local overviewStatsPanel
local overviewDetails
for _, panel in ipairs(MOCK.createdPanels) do
    if rawget(panel, "woCharacterStatsOverview") == true and rawget(panel, "__removed") ~= true then
        overviewStatsPanel = panel
    elseif rawget(panel, "woOverviewDetails") == true and rawget(panel, "__removed") ~= true then
        overviewDetails = panel
    end
end
MOCK.Assert(overviewStatsPanel and isfunction(overviewStatsPanel.Paint),
    "характеристики встроены в обзор отдельной страницы не создаётся")
local expectedXPRemaining = WO.Lang:Get("xp.compact", 10, 100, 90)
MOCK.drawnTextValues = {}
overviewDetails:Paint(620, 270)
local overviewText = table.concat(MOCK.drawnTextValues, " ")
MOCK.Assert(overviewText:find(expectedXPRemaining, 1, true) ~= nil,
    "обзор показывает точное количество XP до следующего уровня")
MOCK.drawnTextValues = {}
overviewStatsPanel:Paint(620, overviewStatsPanel:GetTall())
local overviewStatsText = table.concat(MOCK.drawnTextValues, " ")
MOCK.Assert(overviewStatsText:find(WO.Lang:Get("stats.strength"), 1, true) ~= nil and
    overviewStatsText:find("12", 1, true) ~= nil,
    "обзор показывает синхронизированные характеристики персонажа")
MOCK.drawnTextValues = {}
WO.HUD.DrawPlayerFrame()
local hudShowsXPRemaining = false
for _, text in ipairs(MOCK.drawnTextValues) do
    if text:find(expectedXPRemaining, 1, true) then hudShowsXPRemaining = true end
end
MOCK.Assert(hudShowsXPRemaining,
    "основной HUD выводит числом оставшийся XP рядом со шкалой")
end

local panelsBeforeUI = #MOCK.createdPanels

-- Синхронизация квестов + журнал
MOCK.NetDeliver({ name = "Quest.Sync", args = { {
    ["supplies_for_the_road"] = { status = "completed", progress = { [1] = 3 }, tracked = true },
    ["wolves_of_elwynn"] = { status = "active", progress = { [1] = 1 }, tracked = true },
} } }, 8, nil)

MOCK.Assert(WO.Quests.LocalStates["wolves_of_elwynn"] ~= nil, "состояние квестов синхронизировано")

local trackerLines = WO.Quests.GetTrackerLines()

MOCK.Assert(#trackerLines > 0, "трекер HUD получает строки: " .. #trackerLines)

do
local previousMapName = MOCK.mapName
local previousQuestStates = WO.Quests.LocalStates
local previousLocalPosition = LocalPlayer():GetPos()
MOCK.mapName = "rp_lordaeron"
LocalPlayer():SetPos(Vector(0, 0, 0))
WO.Quests.LocalStates = {
    boar_hunt = { status = "active", progress = {}, tracked = true },
}
local boarWaypoint = WO.Quests.GetTrackedWaypoint()
MOCK.Assert(boarWaypoint and boarWaypoint.questId == "boar_hunt" and
    boarWaypoint.position == WO.Config.NPCSpawnPoints.elwynn_boar[1].pos and
    boarWaypoint.text == "Победите кабанов",
    "принятое и отслеживаемое задание показывает точку следующего кабана")
LocalPlayer():SetPos(boarWaypoint.position)
MOCK.Assert(WO.Quests.GetTrackedWaypoint() ~= nil,
    "непространственный prerequisite не удаляет метку будущей цели преждевременно")
LocalPlayer():SetPos(Vector(0, 0, 0))
MOCK.drawnTextValues = {}
local waypointPolygonsBefore = MOCK.surfacePolyCalls or 0
local vectorMeta = getmetatable(Vector())
local originalToScreen = vectorMeta.ToScreen
function vectorMeta:ToScreen()
    MOCK.lastQuestWaypointProjection = Vector(self.x, self.y, self.z)
    return originalToScreen(self)
end
WO.HUD.DrawQuestWaypoint()
vectorMeta.ToScreen = originalToScreen
local waypointDrawText = table.concat(MOCK.drawnTextValues, " ")
local waypointMeters = math.max(0, math.Round(boarWaypoint.position:Length() / 52.4934))
MOCK.Assert(string.find(waypointDrawText, "Кабаны у фермы", 1, true) and
    string.find(waypointDrawText, "Победите кабанов", 1, true) and
    string.find(waypointDrawText, WO.Lang:Get("quest.distance", waypointMeters), 1, true) and
    MOCK.lastQuestWaypointProjection == boarWaypoint.position + Vector(0, 0, 72) and
    (MOCK.surfacePolyCalls or 0) >= waypointPolygonsBefore + 2,
    "HUD ставит видимый маркер прямо над точкой цели и показывает расстояние на нём")
WO.Quests.LocalStates.boar_hunt.progress[1] = 1
LocalPlayer():SetPos(boarWaypoint.position)
MOCK.Assert(WO.Quests.GetTrackedWaypoint() == nil,
    "метка исчезает после входа в радиус активной цели")
WO.Quests.LocalStates.boar_hunt.progress[2] = 1
LocalPlayer():SetPos(Vector(0, 0, 0))
local nextBoarWaypoint = WO.Quests.GetTrackedWaypoint()
MOCK.Assert(nextBoarWaypoint and
    nextBoarWaypoint.position == WO.Config.NPCSpawnPoints.elwynn_boar[2].pos,
    "после продвижения квеста маршрут переключается на следующую точку кабана")
WO.Quests.LocalStates = {
    supplies_for_the_road = { status = "active", progress = {}, tracked = true },
}
local breadWaypoint = WO.Quests.GetTrackedWaypoint()
MOCK.Assert(breadWaypoint and breadWaypoint.position == WO.Config.NPCSpawnPoints.trader_marla[1].pos,
    "сбор хлеба ведёт к торговцу, у которого хлеб доступен")
WO.Quests.LocalStates.supplies_for_the_road.progress[1] = 3
local turnInWaypoint = WO.Quests.GetTrackedWaypoint()
MOCK.Assert(turnInWaypoint and turnInWaypoint.turnIn == true and
    turnInWaypoint.position == WO.Config.NPCSpawnPoints.marshal_dughal[1].pos,
    "после сбора предметов метка указывает NPC для сдачи задания")
WO.Quests.LocalStates.supplies_for_the_road.tracked = false
MOCK.Assert(WO.Quests.GetTrackedWaypoint() == nil,
    "отключённое отслеживание скрывает навигационную метку")
WO.Quests.LocalStates = {
    boar_hunt = { status = "active", progress = {}, tracked = true },
}
MOCK.mapName = "gm_construct"
MOCK.Assert(WO.Quests.GetTrackedWaypoint() == nil,
    "map-specific waypoint не показывается на другой карте")
WO.Quests.LocalStates = previousQuestStates or WO.Quests.LocalStates
LocalPlayer():SetPos(previousLocalPosition)
MOCK.mapName = previousMapName
end

do
    local commonMenuFrame = FindLatestLiveFrame()
    WO.Quests.OpenLog()
    MOCK.Assert(#MOCK.createdPanels > panelsBeforeUI and commonMenuFrame and
        FindLatestLiveFrame() == commonMenuFrame and WO.MenuUI.IsOpen() and
        WO.MenuUI.GetPage() == "quests",
        "журнал заданий открывается страницей того же общего меню")

    local function FindLatestLiveQuestHeader()
        for index = #MOCK.createdPanels, 1, -1 do
            local panel = MOCK.createdPanels[index]
            if rawget(panel, "woQuestJournalHeader") == true and
                rawget(panel, "__removed") ~= true then
                return panel
            end
        end
    end

    local originalQuestHeader = FindLatestLiveQuestHeader()
    MOCK.NetDeliver({ name = "Quest.Sync", args = { {
        ["supplies_for_the_road"] = { status = "completed", progress = { [1] = 3 }, tracked = true },
        ["boar_hunt"] = { status = "active", progress = { [1] = 1 }, tracked = true },
        ["wolves_of_elwynn"] = { status = "active", progress = { [1] = 1 }, tracked = true },
    } } }, 8, nil)
    local refreshedQuestHeader = FindLatestLiveQuestHeader()
    MOCK.Assert(originalQuestHeader and rawget(originalQuestHeader, "__removed") == true and
        refreshedQuestHeader and refreshedQuestHeader ~= originalQuestHeader and
        WO.MenuUI.GetPage() == "quests" and
        WO.Quests.LocalStates["boar_hunt"].progress[1] == 1,
        "встроенный журнал обновляется после Quest.Sync, не создавая отдельное окно")
end
local refreshedTracker = WO.Quests.GetTrackerLines()
local trackerHasBoars = false
for _, line in ipairs(refreshedTracker) do
    if string.find(string.lower(line.text or ""), "кабан", 1, true) then trackerHasBoars = true end
end
MOCK.Assert(trackerHasBoars, "HUD-трекер сразу отражает новое состояние задания")

local untrackButton = MOCK.FindPanelByText(WO.Lang:Get("quest.untrack"))
MOCK.Assert(untrackButton ~= nil, "в журнале есть доступная кнопка отслеживания")
MOCK.TakeOutbox()
untrackButton:DoClick()
local trackRequest = MOCK.FindInbox(MOCK.TakeOutbox(), "Quest.Track")
MOCK.Assert(#trackRequest == 1 and untrackButton:IsEnabled() == false and
    rawget(untrackButton, "__removed") ~= true,
    "одно нажатие сразу отправляет Quest.Track, блокирует дубли и не закрывает журнал")
local trackedQuestId = trackRequest[1].args[1]
MOCK.NetDeliver({ name = "Quest.Sync", args = { {
    [trackedQuestId] = { status = "active", progress = { [1] = 1 }, tracked = false },
} } }, 8, nil)
MOCK.NetDeliver({ name = "Quest.ActionResult", args = { {
    action = "track", questId = trackedQuestId, success = true,
} } }, 8, nil)
local retrackButton = MOCK.FindPanelByText(WO.Lang:Get("quest.track"))
MOCK.Assert(retrackButton ~= nil and retrackButton:IsEnabled(),
    "серверный ответ завершает запрос и возвращает кнопку в рабочее состояние")
PressKey(KEY_J)
MOCK.Assert(WO.MenuUI.IsOpen() and WO.MenuUI.GetPage() == "overview",
    "повторное J возвращает из журнала в обзор, не закрывая игровое меню")
PressKey(KEY_J)
MOCK.Assert(WO.MenuUI.GetPage() == "quests",
    "J снова открывает журнал внутри того же меню")

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
    "ПКМ нового SWEP открывает книгу выбора заклинаний и подсказки о нужных свитках")
do
    local spellbookXPText = WO.Lang:Get("xp.compact", 10, 100, 90)
    local spellbookShowsXP = false

    for _, panel in ipairs(MOCK.createdPanels) do
        if rawget(panel, "woText") == spellbookXPText then spellbookShowsXP = true end
    end

    MOCK.Assert(spellbookShowsXP,
        "книга заклинаний показывает оставшийся XP рядом с уровнем мага")
end

-- Диалог
local panelsBeforeDlg = #MOCK.createdPanels

MOCK.NetDeliver({ name = "Dialogue.Open", args = { {
    dialogueId = "marshal_intro", nodeId = "start", npcId = "marshal_dughal",
    npcName = "Маршал Дугхал", text = "Привет!",
    options = { { text = "Пока", action = "close" } },
} } }, 8, nil)

MOCK.Assert(#MOCK.createdPanels > panelsBeforeDlg, "окно диалога создано")
local dialogueOption = MOCK.FindPanelByText("Пока")
MOCK.Assert(dialogueOption ~= nil, "вариант диалога представлен доступной кнопкой без числового префикса")
MOCK.TakeOutbox()
dialogueOption:DoClick()
local dialogueChoose = MOCK.FindInbox(MOCK.TakeOutbox(), "Dialogue.Choose")
MOCK.Assert(#dialogueChoose == 1 and dialogueOption:IsEnabled() == false and
    rawget(dialogueOption, "__removed") ~= true,
    "кнопка диалога отправляет один запрос и ждёт ответа вместо преждевременного закрытия")

MOCK.NetDeliver({ name = "Dialogue.Finish", args = {} }, 8, nil)

-- Торговля
do
local panelsBeforeVendor = #MOCK.createdPanels

MOCK.NetDeliver({ name = "Vendor.Open", args = { { npcId = "trader_marla", npcName = "Марла" } } }, 8, nil)
MOCK.Assert(MOCK.FindPanelByText(WO.Lang:Get("vendor.loading")) ~= nil,
    "витрина немедленно показывает состояние загрузки, пока сервер присылает stock")
MOCK.NetDeliver({ name = "Vendor.Sync", args = { {
    npcId = "trader_marla", npcName = "Марла", money = 100, sellRate = 0.35,
    stock = { { class = "bread", name = "Хлеб", price = 4, amount = 20, rarity = "common" } },
} } }, 8, nil)

MOCK.Assert(#MOCK.createdPanels > panelsBeforeVendor, "окно торговли создано")
local vendorBuyButton = MOCK.FindPanelByText(WO.Lang:Get("vendor.buy_one"))
MOCK.Assert(vendorBuyButton ~= nil and vendorBuyButton:IsEnabled(),
    "витрина создаёт активную кнопку покупки")
local vendorSellTab = MOCK.FindPanelByText(WO.Lang:Get("vendor.sell"))
MOCK.Assert(vendorSellTab ~= nil and vendorSellTab:IsEnabled(),
    "переключатель продажи доступен до начала транзакции")
do
    local vendorCard

    for _, panel in ipairs(MOCK.createdPanels) do
        if rawget(panel, "woVendorCard") and panel.woNameLabel and
            panel.woNameLabel.woText == "Хлеб" and rawget(panel, "__removed") ~= true then
            vendorCard = panel
            break
        end
    end

    MOCK.Assert(vendorCard and isfunction(vendorCard.PerformLayout),
        "строка товара строит собственную геометрию кнопки вместо конфликтующего Dock(FILL)")
    vendorCard:PerformLayout(400, 68)
    local actionX = vendorCard.woActionButton:GetPos()
    local actionWidth = vendorCard.woActionButton:GetWide()
    local nameX = vendorCard.woNameLabel:GetPos()
    local nameWidth = vendorCard.woNameLabel:GetWide()
    MOCK.Assert(actionX > nameX and actionX + actionWidth <= 400 and
        nameX + nameWidth < actionX and
        vendorCard.woActionButton:IsMouseInputEnabled() and
        not vendorCard.woNameLabel:IsMouseInputEnabled() and
        not vendorCard.woDetailLabel:IsMouseInputEnabled(),
        "hitbox покупки отделена от текста, не перекрыта метками и целиком помещается в карточке")
end
MOCK.TakeOutbox()
vendorBuyButton:DoClick()
local buyRequest = MOCK.FindInbox(MOCK.TakeOutbox(), "Vendor.Buy")
local buyRequestId = buyRequest[1] and buyRequest[1].args[4]
MOCK.Assert(#buyRequest == 1 and isnumber(buyRequestId) and buyRequestId > 0 and
    vendorBuyButton:IsEnabled() == false and not vendorSellTab:IsEnabled() and
    vendorBuyButton.woText == WO.Lang:Get("vendor.buy_pending"),
    "кнопка сразу показывает Покупаю…, отправляет запрос и блокирует дубликаты")
MOCK.NetDeliver({ name = "Vendor.ActionResult", args = { {
    action = "buy", npcId = "trader_marla", requestId = buyRequestId + 1,
    success = true,
} } }, 8, nil)
MOCK.Assert(vendorBuyButton:IsEnabled() == false and
    vendorBuyButton.woText == WO.Lang:Get("vendor.buy_pending") and
    not vendorSellTab:IsEnabled(),
    "запоздалый ответ другой покупки не снимает блокировку текущего действия")
MOCK.NetDeliver({ name = "Vendor.ActionResult", args = { {
    action = "buy", npcId = "trader_marla", requestId = buyRequestId,
    money = 96, success = true,
} } }, 8, nil)
local updatedWalletText = WO.Lang:Get("currency.name") .. ": " ..
    (isfunction(WO.Util.FormatMoney) and WO.Util.FormatMoney(96) or tostring(96))
local updatedWalletImmediately = false
for _, panel in ipairs(MOCK.createdPanels) do
    if rawget(panel, "woText") == updatedWalletText and rawget(panel, "__removed") ~= true then
        updatedWalletImmediately = true
        break
    end
end
MOCK.Assert(updatedWalletImmediately,
    "серверный ответ сразу обновляет баланс, не ожидая полной синхронизации витрины")
MOCK.NetDeliver({ name = "Vendor.Sync", args = { {
    npcId = "trader_marla", npcName = "Марла", money = 96, sellRate = 0.35,
    stock = { { class = "bread", name = "Хлеб", price = 4, amount = 19, rarity = "common" } },
} } }, 8, nil)
local retryBuyButton = MOCK.FindPanelByText(WO.Lang:Get("vendor.buy_one"))
MOCK.Assert(retryBuyButton ~= nil and retryBuyButton:IsEnabled() and
    vendorSellTab:IsEnabled(),
    "подтверждённая покупка сразу возвращает кнопки и обновлённый список")
MOCK.TakeOutbox()
retryBuyButton:DoClick()
local secondBuyRequest = MOCK.FindInbox(MOCK.TakeOutbox(), "Vendor.Buy")
local secondBuyRequestId = secondBuyRequest[1] and secondBuyRequest[1].args[4]
MOCK.Assert(#secondBuyRequest == 1 and isnumber(secondBuyRequestId) and
    secondBuyRequestId ~= buyRequestId,
    "повторная покупка получает отдельный ID, исключающий путаницу ответов")
MOCK.NetDeliver({ name = "Vendor.ActionResult", args = { {
    action = "buy", npcId = "trader_marla", requestId = secondBuyRequestId,
    money = 96, success = false, reason = "not_enough_money",
} } }, 8, nil)
local sellTabButton = vendorSellTab
MOCK.Assert(sellTabButton ~= nil and sellTabButton:IsEnabled(),
    "витрина торговли предлагает отдельную вкладку продажи")
sellTabButton:DoClick()
local vendorSellButton = MOCK.FindPanelByText(WO.Lang:Get("vendor.sell_one"))
MOCK.Assert(vendorSellButton ~= nil and vendorSellButton:IsEnabled(),
    "список продажи строится из серверно синхронизированного Inventory.ClientData")
MOCK.TakeOutbox()
vendorSellButton:DoClick()
local sellRequest = MOCK.FindInbox(MOCK.TakeOutbox(), "Vendor.Sell")
local sellRequestId = sellRequest[1] and sellRequest[1].args[4]
MOCK.Assert(#sellRequest == 1 and sellRequest[1].args[1] == "trader_marla" and
    sellRequest[1].args[2] == "test-item-uid" and sellRequest[1].args[3] == 1 and
    isnumber(sellRequestId) and vendorSellButton:IsEnabled() == false and
    vendorSellButton.woText == WO.Lang:Get("vendor.sell_pending"),
    "кнопка продажи сразу показывает Продаю… и передаёт серверу UID и ID операции")
MOCK.NetDeliver({ name = "Vendor.ActionResult", args = { {
    action = "sell", npcId = "trader_marla", requestId = sellRequestId,
    money = 96, success = false, reason = "cannot_sell",
} } }, 8, nil)
local retrySellButton = MOCK.FindPanelByText(WO.Lang:Get("vendor.sell_one"))
MOCK.Assert(retrySellButton ~= nil and retrySellButton:IsEnabled(),
    "ответ сервера разблокирует продажу без закрытия окна")
end

print("[scenario] quest/dialogue/vendor UI OK")

---------------------------------------------------------------------------
-- 4c. Админ-меню доступно только после серверной проверки прав
---------------------------------------------------------------------------

WO.Admin.ClientMenuLoaded = false
WO.Admin.ClientMenuAccess = false
WO.Admin.MenuRequestPending = false
WO.Admin.ClientMenuPermissions = {}
WO.Admin.ClientMenuCommands = {}
MOCK.TakeOutbox()
WO.MenuUI.Show("overview")
local adminRequestOutbox = MOCK.TakeOutbox()
MOCK.Assert(#MOCK.FindInbox(adminRequestOutbox, "Admin.MenuRequest") == 1,
    "открытие общего меню запрашивает серверные права админ-каталога")
MOCK.Assert(MOCK.FindPanelByText("Админ-меню") == nil,
    "клиент не показывает админ-кнопку до ответа сервера")

MOCK.NetDeliver({ name = "Admin.MenuData", args = { {
    isAdmin = true,
    permissions = { ["item.give"] = true },
    commands = { {
        id = "wo_giveitem", title = "Выдать предмет",
        description = "Добавить предмет в инвентарь.", permission = "item.give",
        args = {
            { name = "Класс предмета", placeholder = "bread" },
            { name = "Количество", placeholder = "1" },
        },
    } },
} } }, 8, nil)
MOCK.Assert(WO.Admin.ClientMenuAccess and MOCK.FindPanelByText("Админ-меню") ~= nil,
    "серверные права добавляют админ-кнопку в общее меню")
WO.MenuUI.Show("admin")
MOCK.Assert(WO.MenuUI.GetPage() == "admin" and
    WO.Admin.ClientMenuCommands[1] and WO.Admin.ClientMenuCommands[1].id == "wo_giveitem",
    "админ-страница показывает только команду, присланную сервером")
local adminFields = {}
for _, panel in ipairs(MOCK.createdPanels) do
    local placeholder = rawget(panel, "__placeholder") or ""
    if rawget(panel, "__class") == "DTextEntry" and rawget(panel, "__removed") ~= true and
        (string.find(placeholder, "Класс предмета", 1, true) or
            string.find(placeholder, "Количество", 1, true)) then
        adminFields[#adminFields + 1] = panel
    end
end
MOCK.Assert(#adminFields == 2, "админ-команда получает поля своих schema arguments")
adminFields[1]:SetValue("health_potion")
adminFields[2]:SetValue("2")
local executeAdminCommand = MOCK.FindPanelByText("Выполнить")
MOCK.Assert(executeAdminCommand ~= nil, "у админ-команды есть кнопка выполнения")
MOCK.TakeOutbox()
executeAdminCommand.DoClick(executeAdminCommand)
local adminRunOutbox = MOCK.TakeOutbox()
local adminRunMessages = MOCK.FindInbox(adminRunOutbox, "Admin.CommandRun")
MOCK.Assert(#adminRunMessages == 1 and adminRunMessages[1].args[1] == "wo_giveitem" and
    adminRunMessages[1].args[2] == 2 and adminRunMessages[1].args[3] == "health_potion" and
    adminRunMessages[1].args[4] == "2",
    "кнопка отправляет только catalog ID и аргументы на серверную авторизацию")

MOCK.NetDeliver({ name = "Admin.MenuData", args = { {
    isAdmin = false, permissions = {}, commands = {},
} } }, 8, nil)
MOCK.Assert(not WO.Admin.ClientMenuAccess and MOCK.FindPanelByText("Админ-меню") == nil,
    "без серверных прав админ-кнопка скрыта")
WO.MenuUI.Close()

---------------------------------------------------------------------------
-- 4d. Игровая настройка автосбора получает серверное состояние
---------------------------------------------------------------------------

WO.Settings.ClientAutoCollectEnabled = false
WO.Settings.ClientAutoCollectLoaded = false
WO.Settings.AutoCollectRequestPending = false
MOCK.TakeOutbox()
WO.MenuUI.Show("settings")
local settingsRequestOutbox = MOCK.TakeOutbox()
MOCK.Assert(WO.MenuUI.GetPage() == "settings" and
    #MOCK.FindInbox(settingsRequestOutbox, "Settings.AutoCollectRequest") == 1 and
    MOCK.FindPanelByText(WO.Lang:Get("menu.settings")) ~= nil,
    "в игровом меню есть раздел настроек, запрашивающий состояние автосбора")
MOCK.NetDeliver({ name = "Settings.AutoCollectSync", args = { false } }, 8, nil)
MOCK.Assert(WO.Settings.ClientAutoCollectLoaded and
    not WO.Settings.ClientAutoCollectEnabled,
    "серверный opt-in автосбора синхронизирован в выключенном состоянии")
local autoCollectToggle = MOCK.FindPanelByText(WO.Lang:Get("settings.auto_collect_off"))
MOCK.Assert(autoCollectToggle ~= nil, "настройки показывают переключатель автосбора")
MOCK.TakeOutbox()
autoCollectToggle.DoClick(autoCollectToggle)
local autoCollectSetOutbox = MOCK.TakeOutbox()
local autoCollectSetMessages = MOCK.FindInbox(autoCollectSetOutbox, "Settings.AutoCollectSet")
MOCK.Assert(#autoCollectSetMessages == 1 and autoCollectSetMessages[1].args[1] == true,
    "переключатель отправляет только предпочтение opt-in серверу")
MOCK.NetDeliver({ name = "Settings.AutoCollectSync", args = { true } }, 8, nil)
MOCK.Assert(WO.Settings.ClientAutoCollectEnabled == true,
    "включённое состояние подтверждается сервером")
WO.MenuUI.Close()

---------------------------------------------------------------------------
-- 4e. Выход из персонажа: очистка клиентского состояния и окон
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
