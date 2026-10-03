--[[
    Warcraft Online — экран выбора персонажа (client).
    Список персонажей с 3D-превью, создание, удаление, вход в мир.
]]

WO.CharacterUI = WO.CharacterUI or {}

local frame = nil
local currentScreen = nil

local SELECTED_COLOR = WO.UI.Colors.accent

local function SetScreen(screen)
    currentScreen = screen
    WO.CharacterUI.CurrentScreen = screen
end

local function CloseAllCharacterUI()
    if IsValid(frame) then
        frame:Remove()
        frame = nil
    end

    if WO.MenuUI and WO.MenuUI.Close then
        WO.MenuUI.Close()
    end

    SetScreen(nil)

    if WO.CharacterUI.CloseCreate then
        WO.CharacterUI.CloseCreate()
    end
end

WO.CharacterUI.CloseMenus = CloseAllCharacterUI

---------------------------------------------------------------------------
-- Главное меню: создать / загрузить / выйти (disconnect)
---------------------------------------------------------------------------

function WO.CharacterUI.OpenMainMenu()
    CloseAllCharacterUI()
    SetScreen("main")

    if WO.MenuUI and WO.MenuUI.Show then
        WO.MenuUI.Show("characters")
        return
    end

    -- Fallback для запуска без scoreboard-плагина.
    local list = WO.Character.GetList()
    local panelWidth = math.min(520, ScrW() - 48)
    local panelHeight = 380
    local panelX = (ScrW() - panelWidth) / 2
    local panelY = (ScrH() - panelHeight) / 2

    frame = vgui.Create("DFrame")
    frame:SetSize(ScrW(), ScrH())
    frame:SetPos(0, 0)
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:MakePopup()
    SetScreen("main")
    frame.OnKeyCodePressed = function(_, key)
        -- Не даём закрыть главное меню и оставить игрока в лимбо.
        if key == KEY_ESCAPE then return end
    end

    frame.Paint = function(_, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(8, 11, 18, 248))
        draw.SimpleText("Warcraft Online", "WO.Title", w / 2, panelY - 58,
            WO.UI.Colors.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local panel = vgui.Create("DPanel", frame)
    panel:SetPos(panelX, panelY)
    panel:SetSize(panelWidth, panelHeight)
    panel.Paint = function(_, w, h)
        WO.UI.DrawPanelOutlined(0, 0, w, h, WO.UI.Colors.panel, WO.UI.Colors.borderLight)
        draw.SimpleText(WO.Lang:Get("character.main_menu"), "WO.Subtitle", w / 2, 32,
            WO.UI.Colors.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local buttonWidth = math.min(420, panelWidth - 56)
    local buttonHeight = 54
    local buttonX = (panelWidth - buttonWidth) / 2

    local createButton = WO.UI.Button(panel, WO.Lang:Get("character.menu.create"), function()
        WO.CharacterUI.OpenCreate()
    end)
    createButton:SetPos(buttonX, 82)
    createButton:SetSize(buttonWidth, buttonHeight)
    createButton:SetAccent(true)
    createButton:SetFont("WO.MenuButton")

    local loadButton = WO.UI.Button(panel, WO.Lang:Get("character.menu.load"), function()
        if #WO.Character.GetList() > 0 then
            WO.CharacterUI.OpenSelect()
        else
            if WO.Notify and WO.Notify.Show then
                WO.Notify.Show("info", WO.Lang:Get("character.no_saved_characters"))
            end
        end
    end)
    loadButton:SetPos(buttonX, 154)
    loadButton:SetSize(buttonWidth, buttonHeight)
    loadButton:SetEnabled(#list > 0)
    loadButton:SetFont("WO.MenuButton")

    local emptyLabel = WO.UI.Label(panel, WO.Lang:Get("character.no_saved_characters"),
        "WO.Small", WO.UI.Colors.textDim)
    emptyLabel:SetPos(0, 218)
    emptyLabel:SetSize(panelWidth, 24)
    emptyLabel:SetCentered(true)
    emptyLabel:SetVisible(#list == 0)

    local exitButton = WO.UI.Button(panel, WO.Lang:Get("character.menu.exit"), function()
        RunConsoleCommand("disconnect")
    end)
    exitButton:SetPos(buttonX, 278)
    exitButton:SetSize(buttonWidth, 48)
    exitButton:SetFont("WO.MenuButton")
end

---------------------------------------------------------------------------
-- Карточка персонажа
---------------------------------------------------------------------------

local function CreateCharacterCard(parent, entry, onSelect)
    local card = vgui.Create("DPanel", parent)

    card:SetSize(180, 260)
    card:SetPaintBackground(false)
    card.selected = false

    -- Модель
    local model = WO.UI.CreateCharacterModel(card, entry.model ~= "" and entry.model or "models/player/group01/male_01.mdl")
    model:SetPos(10, 10)
    model:SetSize(160, 170)

    -- Уровень / раса / класс
    local raceDef = WO.Races.Get(entry.race)
    local classDef = WO.Classes.Get(entry.class)
    local info = WO.Lang:Get("character.level") .. " " .. entry.level .. " · " ..
        (raceDef and raceDef.name or entry.race) .. " · " ..
        (classDef and classDef.name or entry.class)

    card.Paint = function(_, w, h)
        local border = card.selected and SELECTED_COLOR or WO.UI.Colors.border

        WO.UI.DrawPanelOutlined(0, 0, w, h, WO.UI.Colors.panel, border)

        draw.SimpleText(entry.name .. " " .. entry.surname, "WO.Subtitle", w / 2, 186, WO.UI.Colors.text, TEXT_ALIGN_CENTER)
        draw.SimpleText(info, "WO.Tiny", w / 2, 212, WO.UI.Colors.textDim, TEXT_ALIGN_CENTER)
    end

    card.OnMousePressed = function()
        onSelect(card, entry)
    end

    return card
end

---------------------------------------------------------------------------
-- Экран выбора
---------------------------------------------------------------------------

function WO.CharacterUI.OpenSelect()
    CloseAllCharacterUI()

    local list = WO.Character.GetList()

    frame = vgui.Create("DFrame")
    frame:SetSize(ScrW(), ScrH())
    frame:SetPos(0, 0)
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:MakePopup()
    SetScreen("select")
    frame.OnKeyCodePressed = function(_, key)
        if key == KEY_ESCAPE then
            WO.CharacterUI.OpenMainMenu()
        end
    end

    frame.Paint = function(_, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(10, 12, 18, 250))
        draw.SimpleText(WO.Lang:Get("character.select"), "WO.Title", w / 2, 40, WO.UI.Colors.accent, TEXT_ALIGN_CENTER)
    end

    local selectedEntry = nil
    local selectedCard = nil

    local cardsPanel = vgui.Create("DPanel", frame)
    cardsPanel:SetPos(0, 100)
    cardsPanel:SetSize(ScrW(), 300)
    cardsPanel:SetPaintBackground(false)

    -- Карточки
    local x = ScrW() / 2 - (#list * 190) / 2

    local function SelectCard(card, entry)
        if IsValid(selectedCard) then
            selectedCard.selected = false
        end

        selectedCard = card
        selectedEntry = entry

        if IsValid(card) then
            card.selected = true
        end
    end

    for _, entry in ipairs(list) do
        local card = CreateCharacterCard(cardsPanel, entry, SelectCard)

        card:SetPos(x, 10)
        x = x + 190

        if not selectedEntry then
            SelectCard(card, entry)
        end
    end

    -- Надпись при пустом списке
    if #list == 0 then
        local label = vgui.Create("DPanel", cardsPanel)

        label:SetPos(0, 100)
        label:SetSize(ScrW(), 40)
        label:SetPaintBackground(false)

        label.Paint = function(_, w, h)
            draw.SimpleText(WO.Lang:Get("character.no_characters"), "WO.Subtitle", w / 2, h / 2, WO.UI.Colors.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    -- Кнопки
    local buttonY = ScrH() - 112
    local buttonWidth = math.min(190, math.floor((ScrW() - 80) / 4))
    local buttonGap = 12
    local rowWidth = buttonWidth * 4 + buttonGap * 3
    local buttonX = (ScrW() - rowWidth) / 2

    local playButton = WO.UI.Button(frame, WO.Lang:Get("ui.confirm"), function()
        if selectedEntry then
            WO.Character.RequestSelect(selectedEntry.id)
        end
    end)

    playButton:SetPos(buttonX, buttonY)
    playButton:SetSize(buttonWidth, 42)
    playButton:SetAccent(true)
    playButton:SetEnabled(selectedEntry ~= nil)

    local createButton = WO.UI.Button(frame, WO.Lang:Get("character.menu.create"), function()
        WO.CharacterUI.OpenCreate()
    end)

    createButton:SetPos(buttonX + buttonWidth + buttonGap, buttonY)
    createButton:SetSize(buttonWidth, 42)

    local deleteButton = WO.UI.Button(frame, WO.Lang:Get("ui.delete"), function()
        if not selectedEntry then return end

        Derma_Query(
            WO.Lang:Get("character.delete_confirm"),
            WO.Lang:Get("ui.delete"),
            WO.Lang:Get("ui.yes"), function()
                WO.Character.RequestDelete(selectedEntry.id)
            end,
            WO.Lang:Get("ui.no"), function() end
        )
    end)

    deleteButton:SetPos(buttonX + (buttonWidth + buttonGap) * 2, buttonY)
    deleteButton:SetSize(buttonWidth, 42)
    deleteButton:SetEnabled(selectedEntry ~= nil)

    local backButton = WO.UI.Button(frame, WO.Lang:Get("character.back_to_menu"), function()
        WO.CharacterUI.OpenMainMenu()
    end)
    backButton:SetPos(buttonX + (buttonWidth + buttonGap) * 3, buttonY)
    backButton:SetSize(buttonWidth, 42)

    WO.CharacterUI.CloseSelect = function()
        if IsValid(frame) then
            frame:Remove()
            frame = nil
        end
    end
end

---------------------------------------------------------------------------
-- События
---------------------------------------------------------------------------

WO.Hook.Add("OpenCharacterMenu", "character_ui", function()
    WO.CharacterUI.OpenMainMenu()
end)

WO.Hook.Add("OpenCharacterSelect", "character_ui", function()
    WO.CharacterUI.OpenSelect()
end)

WO.Hook.Add("CharacterListReceived", "character_ui", function()
    -- При повторной синхронизации остаёмся на текущем экране, не перескакиваем
    -- из главного меню в список выбора автоматически.
    if currentScreen == "main" then
        WO.CharacterUI.OpenMainMenu()
    elseif currentScreen == "select" then
        WO.CharacterUI.OpenSelect()
    end
end)

-- Успешный выбор — закрываем все меню
WO.Hook.Add("CharacterSelectResult", "character_ui", function(success)
    if success then
        CloseAllCharacterUI()
    end
end)

WO.Hook.Add("CharacterCreateResult", "character_ui", function(success)
    if success then
        CloseAllCharacterUI()
    end
end)
