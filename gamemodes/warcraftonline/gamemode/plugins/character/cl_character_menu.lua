--[[
    Warcraft Online — экран выбора персонажа (client).
    Список персонажей с 3D-превью, создание, удаление, вход в мир.
]]

WO.CharacterUI = WO.CharacterUI or {}

local frame = nil

local SELECTED_COLOR = WO.UI.Colors.accent

local function CloseAllCharacterUI()
    if IsValid(frame) then
        frame:Remove()
        frame = nil
    end

    if WO.CharacterUI.CloseCreate then
        WO.CharacterUI.CloseCreate()
    end
end

---------------------------------------------------------------------------
-- Карточка персонажа
---------------------------------------------------------------------------

local function CreateCharacterCard(parent, entry, onSelect)
    local card = vgui.Create("DPanel", parent)

    card:SetSize(180, 260)
    card:SetPaintBackground(false)
    card.selected = false

    card.Paint = function(_, w, h)
        local border = card.selected and SELECTED_COLOR or WO.UI.Colors.border

        WO.UI.DrawPanelOutlined(0, 0, w, h, WO.UI.Colors.panel, border)
    end

    -- Модель
    local model = WO.UI.CreateCharacterModel(card, entry.model ~= "" and entry.model or "models/player/group01/male_01.mdl")
    model:SetPos(10, 10)
    model:SetSize(160, 170)

    -- Имя
    draw.SimpleText(entry.name .. " " .. entry.surname, "WO.Subtitle", 90, 190, WO.UI.Colors.text, TEXT_ALIGN_CENTER)

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
    local buttonY = ScrH() - 110

    local playButton = WO.UI.Button(frame, WO.Lang:Get("ui.confirm"), function()
        if selectedEntry then
            WO.Character.RequestSelect(selectedEntry.id)
        end
    end)

    playButton:SetPos(ScrW() / 2 - 220, buttonY)
    playButton:SetSize(200, 40)
    playButton:SetAccent(true)

    local createButton = WO.UI.Button(frame, WO.Lang:Get("ui.create"), function()
        WO.CharacterUI.OpenCreate()
    end)

    createButton:SetPos(ScrW() / 2 + 20, buttonY)
    createButton:SetSize(200, 40)

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

    deleteButton:SetPos(ScrW() / 2 - 100, buttonY + 52)
    deleteButton:SetSize(200, 32)

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

WO.Hook.Add("OpenCharacterSelect", "character_ui", function()
    WO.CharacterUI.OpenSelect()
end)

WO.Hook.Add("CharacterListReceived", "character_ui", function(list)
    -- Если экран открыт — перестраиваем
    if IsValid(frame) then
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
