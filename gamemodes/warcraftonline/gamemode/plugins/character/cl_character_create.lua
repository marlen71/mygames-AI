--[[
    Warcraft Online — экран создания персонажа (client).

    Шаги:
        1. Раса → 2. Пол → 3. Возраст → 4. Имя → 5. Фамилия →
        6. Кастомизация → 7. Класс → 8. Итоговая карточка и подтверждение

    Справа — 3D-preview (вращение мышью, zoom колесом, обновление в реальном времени).
    Сервер — финальный авторитет: клиентская валидация только для удобства.
]]

-- Namespace UI персонажа (создаётся здесь: файл загружается первым)
WO.CharacterUI = WO.CharacterUI or {}

local createFrame = nil
local submitButton = nil
local submitPending = false
local createLayout = nil

---------------------------------------------------------------------------
-- Состояние черновика
---------------------------------------------------------------------------

local function NewDraft()
    return {
        step = 1,
        race = nil,
        gender = nil,
        age = 25,
        name = "",
        surname = "",
        model = nil,
        modelIndex = 1,
        customization = {
            skin = 0,
            bodygroups = {},
        },
        class = nil,
        confirmed = false,
    }
end

local draft = NewDraft()

---------------------------------------------------------------------------
-- Хелперы
---------------------------------------------------------------------------

local STEP_NAMES = {
    "character.step.race",
    "character.step.gender",
    "character.step.age",
    "character.step.name",
    "character.step.surname",
    "character.step.customization",
    "character.step.class",
    "character.step.confirm",
}

local function LayoutCreateFrame()
    if not IsValid(createFrame) or not istable(createFrame.woControls) then return end

    local controls = createFrame.woControls
    local screenW, screenH = ScrW(), ScrH()
    local margin = math.max(18, math.min(60, screenW * 0.035))
    local gap = math.max(16, math.min(48, screenW * 0.025))
    local top = 72
    local navY = math.max(top + 190, screenH - 64)
    local rotateButtonY = navY - 78
    local panelBottom = rotateButtonY - 44
    local panelH = math.max(140, panelBottom - top)

    createFrame:SetSize(screenW, screenH)
    createFrame:SetPos(0, 0)
    controls.title:SetPos(margin, 16)
    controls.title:SetSize(math.max(160, screenW - margin * 2 - 56), 40)
    controls.close:SetPos(screenW - margin - 40, 16)
    controls.close:SetSize(40, 40)
    controls.back:SetPos(margin, navY)
    controls.back:SetSize(150, 40)
    controls.next:SetPos(math.max(margin + 170, screenW - margin - 190), navY)
    controls.next:SetSize(190, 40)

    if screenW < 760 then
        controls.step:SetPos(margin, top)
        controls.step:SetSize(math.max(1, screenW - margin * 2), panelH)
        controls.model:SetVisible(false)
        controls.rotateLeft:SetVisible(false)
        controls.rotateRight:SetVisible(false)
        controls.rotateHint:SetVisible(false)
        return
    end

    local availableW = screenW - margin * 2 - gap
    local stepW = math.Clamp(availableW * 0.38, 320, 590)

    if availableW < 650 then
        stepW = math.max(250, availableW * 0.47)
    end

    local modelX = margin + stepW + gap
    local modelW = math.max(180, screenW - margin - modelX)

    controls.step:SetPos(margin, top)
    controls.step:SetSize(stepW, panelH)
    controls.model:SetVisible(true)
    controls.model:SetPos(modelX, top)
    controls.model:SetSize(modelW, panelH)

    local rotateWidth = math.min(190, math.max(92, (modelW - 30) / 2))
    local centerX = modelX + modelW / 2

    controls.rotateLeft:SetVisible(true)
    controls.rotateLeft:SetPos(centerX - rotateWidth - 8, rotateButtonY)
    controls.rotateLeft:SetSize(rotateWidth, 34)
    controls.rotateRight:SetVisible(true)
    controls.rotateRight:SetPos(centerX + 8, rotateButtonY)
    controls.rotateRight:SetSize(rotateWidth, 34)
    controls.rotateHint:SetVisible(true)
    controls.rotateHint:SetPos(centerX - math.min(240, modelW / 2), rotateButtonY - 24)
    controls.rotateHint:SetSize(math.min(480, modelW), 20)
    controls.rotateHint:SetContentAlignment(5)
end

local function CloseCreate()
    if IsValid(createFrame) then
        createFrame:Remove()
        createFrame = nil
    end

    createLayout = nil
    submitButton = nil
    submitPending = false
    WO.CharacterUI.PreviewModel = nil
end

WO.CharacterUI.CloseCreate = CloseCreate

local function PreviewUpdate(modelPanel)
    if not IsValid(modelPanel) then return end

    local changed = false

    if draft.model and draft.model ~= modelPanel.currentModel then
        changed = isfunction(modelPanel.SetPreviewModel)
            and modelPanel:SetPreviewModel(draft.model) == true

        if not isfunction(modelPanel.SetPreviewModel) then
            changed = WO.Models.Exists(draft.model)

            if changed then
                modelPanel:SetModel(draft.model)
                modelPanel.currentModel = draft.model
            end
        end
    elseif not draft.model and isfunction(modelPanel.ClearPreviewModel) then
        modelPanel:ClearPreviewModel()
        changed = true
    end

    -- Модель сменилась — перестраиваем контролы bodygroups (у каждой модели свои).
    if changed and isfunction(modelPanel.UpdateBodygroups) then
        modelPanel.UpdateBodygroups()
    end

    if isfunction(modelPanel.ApplyCustomization) then
        modelPanel:ApplyCustomization(draft.customization)
    end
end

---------------------------------------------------------------------------
-- Валидация черновика (клиентская, для удобства; сервер проверяет всё)
---------------------------------------------------------------------------

local function ValidateStep(step)
    if step == 1 and (not draft.race or #WO.Races.GetAvailableGenders(draft.race) == 0) then
        return false, "character.race"
    elseif step == 2 and (not draft.gender or
        not WO.Races.IsGenderAllowed(draft.race, draft.gender)) then
        return false, "character.gender"
    elseif step == 3 then
        local age = tonumber(draft.age)

        if not age or age < WO.Config.AgeMin or age > WO.Config.AgeMax then
            return false, "character.age"
        end
    elseif step == 4 then
        if not WO.Util.IsValidName(WO.Util.CleanString(draft.name)) then
            return false, "character.name"
        end
    elseif step == 5 then
        if not WO.Util.IsValidName(WO.Util.CleanString(draft.surname)) then
            return false, "character.surname"
        end
    elseif step == 6 then
        if not draft.model or
            not WO.Races.IsModelAllowed(draft.race, draft.gender, draft.model) or
            not WO.Models.Exists(draft.model) then
            return false, "character.model_unavailable"
        end
    elseif step == 7 and not draft.class then
        return false, "character.class"
    elseif step == 8 and not draft.confirmed then
        return false, "character.confirm_required"
    end

    return true
end

---------------------------------------------------------------------------
-- Построение шагов
---------------------------------------------------------------------------

local stepBuilders = {}

-- Шаг 1: раса. Показываем только локально доступные модели расы и пола.
stepBuilders[1] = function(parent, modelPanel)
    local scroll = WO.UI.Scroll(parent)

    scroll:Dock(FILL)
    scroll:DockMargin(0, 10, 0, 0)

    local raceButtons = {}
    local visibleRaces = 0

    for _, raceId in ipairs(WO.Races.GetIDs()) do
        local race = WO.Races.Get(raceId)

        if race and #WO.Races.GetAvailableGenders(raceId) > 0 then
            visibleRaces = visibleRaces + 1

            local button = WO.UI.Button(scroll, race.name, function()
                draft.race = raceId
                draft.class = nil

                local genders = WO.Races.GetAvailableGenders(raceId)
                draft.gender = genders[1]
                local models = WO.Races.GetModels(raceId, draft.gender)
                draft.modelIndex = 1
                draft.model = models[1]

                for id, raceButton in pairs(raceButtons) do
                    raceButton:SetAccent(id == raceId)
                end

                PreviewUpdate(modelPanel)
            end)

            button:Dock(TOP)
            button:DockMargin(0, 0, 0, 6)
            button:SetTall(36)
            button:SetAccent(draft.race == raceId)
            raceButtons[raceId] = button

            if race.description then
                local label = WO.UI.Label(scroll, race.description, "WO.Tiny", WO.UI.Colors.textDim)

                label:Dock(TOP)
                label:DockMargin(8, -4, 8, 6)
                label:SetTall(30)
            end
        end
    end

    if visibleRaces == 0 then
        local unavailable = WO.UI.Label(parent,
            WO.Lang:Get("character.no_models_available"), "WO.Body", WO.UI.Colors.warn)
        unavailable:Dock(TOP)
        unavailable:DockMargin(8, 18, 8, 0)
        unavailable:SetTall(58)
    end
end

-- Шаг 2: только полы, для которых сервер/клиент нашли установленные модели.
stepBuilders[2] = function(parent, modelPanel)
    local buttons = {}

    for _, gender in ipairs(WO.Races.GetAvailableGenders(draft.race)) do
        local button = WO.UI.Button(parent, WO.Lang:Get("gender." .. gender), function()
            draft.gender = gender

            local models = WO.Races.GetModels(draft.race, gender)
            draft.modelIndex = 1
            draft.model = models[1]

            for id, genderButton in pairs(buttons) do
                genderButton:SetAccent(id == gender)
            end

            PreviewUpdate(modelPanel)
        end)

        button:Dock(TOP)
        button:DockMargin(0, 6, 0, 0)
        button:SetTall(36)
        button:SetAccent(draft.gender == gender)
        buttons[gender] = button
    end
end

-- Шаг 3: возраст
stepBuilders[3] = function(parent)
    local label = WO.UI.Label(parent, WO.Lang:Get("character.age") .. ": " .. draft.age, "WO.Subtitle")

    label:Dock(TOP)
    label:DockMargin(0, 10, 0, 10)

    local slider = vgui.Create("DNumSlider", parent)

    slider:Dock(TOP)
    slider:SetTall(40)
    slider:SetText("")
    slider:SetMin(WO.Config.AgeMin)
    slider:SetMax(WO.Config.AgeMax)
    slider:SetDecimals(0)
    slider:SetValue(draft.age)

    slider.OnValueChanged = function(_, value)
        draft.age = math.floor(value)
        label:SetDisplayText(WO.Lang:Get("character.age") .. ": " .. draft.age)
    end
end

-- Шаг 4/5: имя/фамилия
local function BuildTextStep(parent, field, labelKey)
    local label = WO.UI.Label(parent, WO.Lang:Get(labelKey), "WO.Subtitle")

    label:Dock(TOP)
    label:DockMargin(0, 10, 0, 8)

    local entry = vgui.Create("DTextEntry", parent)

    entry:Dock(TOP)
    entry:SetTall(34)
    entry:SetFont("WO.Body")
    entry:SetValue(draft[field] or "")
    entry:SetPlaceholderText(WO.Lang:Get(labelKey))

    entry.OnChange = function(self)
        draft[field] = self:GetValue()
    end

    local generateButton = WO.UI.Button(parent,
        WO.Lang:Get(field == "name" and "character.generate_name" or "character.generate_surname"),
        function()
            local generated = WO.CharacterNames and WO.CharacterNames.Generate and
                WO.CharacterNames.Generate(draft.race, field, draft.gender)

            if not isstring(generated) then
                if WO.Notify and WO.Notify.Show then
                    WO.Notify.Show("error", WO.Lang:Get("character.name_generator_unavailable"))
                end
                return
            end

            entry:SetValue(generated)
            draft[field] = generated
        end)

    generateButton:Dock(TOP)
    generateButton:DockMargin(0, 8, 0, 0)
    generateButton:SetTall(32)

    local hint = WO.UI.Label(parent,
        WO.Lang:Get("character.name_hint", WO.Config.NameMinLength, WO.Config.NameMaxLength),
        "WO.Tiny", WO.UI.Colors.textDim)

    hint:Dock(TOP)
    hint:DockMargin(0, 8, 0, 0)
    hint:SetTall(16)
end

stepBuilders[4] = function(parent)
    BuildTextStep(parent, "name", "character.name")
end

stepBuilders[5] = function(parent)
    BuildTextStep(parent, "surname", "character.surname")
end

-- Шаг 6: кастомизация (модель, bodygroups, skin, цвет)
stepBuilders[6] = function(parent, modelPanel)
    -- Выбор модели
    local modelLabel = WO.UI.Label(parent, WO.Lang:Get("character.model"), "WO.Subtitle")

    modelLabel:Dock(TOP)
    modelLabel:DockMargin(0, 0, 0, 6)

    local modelRow = vgui.Create("DPanel", parent)

    modelRow:Dock(TOP)
    modelRow:SetTall(34)
    modelRow:SetPaintBackground(false)

    local prevButton = WO.UI.Button(modelRow, "◀", function()
        local models = WO.Races.GetModels(draft.race, draft.gender)

        if #models == 0 then return end

        draft.modelIndex = ((draft.modelIndex - 2) % #models) + 1
        draft.model = models[draft.modelIndex]

        PreviewUpdate(modelPanel)
    end)

    prevButton:Dock(LEFT)
    prevButton:SetWide(40)

    local modelIndexLabel = WO.UI.Label(modelRow, "", "WO.Body")

    modelIndexLabel:Dock(FILL)
    modelIndexLabel:DockMargin(6, 0, 6, 0)

    local nextButton = WO.UI.Button(modelRow, "▶", function()
        local models = WO.Races.GetModels(draft.race, draft.gender)

        if #models == 0 then return end

        draft.modelIndex = (draft.modelIndex % #models) + 1
        draft.model = models[draft.modelIndex]

        PreviewUpdate(modelPanel)
    end)

    nextButton:Dock(RIGHT)
    nextButton:SetWide(40)

    local function UpdateModelLabel()
        local models = WO.Races.GetModels(draft.race, draft.gender)

        modelIndexLabel:SetDisplayText(draft.modelIndex .. " / " .. math.max(1, #models))
    end

    UpdateModelLabel()

    -- Bodygroups (для каждой модели свои!)
    local bgLabel = WO.UI.Label(parent, "Bodygroups", "WO.Subtitle")

    bgLabel:Dock(TOP)
    bgLabel:DockMargin(0, 12, 0, 4)

    local bgScroll = WO.UI.Scroll(parent)

    bgScroll:Dock(FILL)
    bgScroll:DockMargin(0, 0, 0, 0)

    local function RebuildBodygroups()
        bgScroll:Clear()

        if not draft.model then return end

        local bodygroups = WO.Customization.GetBodygroups(draft.model)

        if #bodygroups == 0 then
            local empty = WO.UI.Label(bgScroll, "—", "WO.Small", WO.UI.Colors.textDim)

            empty:Dock(TOP)
            empty:SetTall(18)

            return
        end

        for _, bg in ipairs(bodygroups) do
            local row = vgui.Create("DPanel", bgScroll)

            row:Dock(TOP)
            row:SetTall(30)
            row:SetPaintBackground(false)

            row.Paint = function(_, w, h)
                WO.UI.DrawTextFit(bg.name, "WO.Small", 0, h / 2, WO.UI.Colors.text,
                    TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, w - 144, h - 2)
            end

            local combo = vgui.Create("DComboBox", row)

            combo:Dock(RIGHT)
            combo:SetWide(130)

            for _, option in ipairs(bg.options or {}) do
                combo:AddChoice(option.name, option.value)
            end

            combo:ChooseOptionID((draft.customization.bodygroups[bg.id] or 0) + 1)

            combo.OnSelect = function(_, _, _, data)
                draft.customization.bodygroups[bg.id] = tonumber(data) or 0

                PreviewUpdate(modelPanel)
            end
        end

        -- Skin
        local skinRow = vgui.Create("DPanel", bgScroll)

        skinRow:Dock(TOP)
        skinRow:SetTall(30)
        skinRow:SetPaintBackground(false)

        skinRow.Paint = function(_, w, h)
            draw.SimpleText("Skin", "WO.Small", 0, h / 2, WO.UI.Colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        local skinCombo = vgui.Create("DComboBox", skinRow)

        skinCombo:Dock(RIGHT)
        skinCombo:SetWide(130)

        for _, skin in ipairs(WO.Customization.GetSkins(draft.model)) do
            skinCombo:AddChoice(skin.name, skin.value)
        end

        skinCombo:ChooseOptionID((draft.customization.skin or 0) + 1)

        skinCombo.OnSelect = function(_, _, _, data)
            draft.customization.skin = tonumber(data) or 0

            PreviewUpdate(modelPanel)
        end

        -- Цвет
        local colorRow = vgui.Create("DPanel", bgScroll)

        colorRow:Dock(TOP)
        colorRow:SetTall(30)
        colorRow:SetPaintBackground(false)

        colorRow.Paint = function(_, w, h)
            draw.SimpleText("Color", "WO.Small", 0, h / 2, WO.UI.Colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        local mixer = vgui.Create("DColorMixer", bgScroll)

        mixer:Dock(TOP)
        mixer:DockMargin(0, 4, 0, 0)
        mixer:SetTall(110)
        mixer:SetPalette(false)
        mixer:SetAlphaBar(false)
        mixer:SetWangs(false)

        local defaultColor = draft.customization.color
            and Color(draft.customization.color.r, draft.customization.color.g, draft.customization.color.b)
            or color_white

        mixer:SetColor(defaultColor)

        local function OnColorChanged(col)
            draft.customization.color = { r = col.r, g = col.g, b = col.b, a = 255 }

            PreviewUpdate(modelPanel)
        end

        -- DColorMixer: колбэк зависит от версии GMod (ValueChanged / OnChange)
        mixer.ValueChanged = function(_, col)
            OnColorChanged(col)
        end

        mixer.OnChange = function(_, col)
            OnColorChanged(col)
        end
    end

    RebuildBodygroups()

    -- Перестраиваем контролы при смене модели (вызывается из PreviewUpdate)
    modelPanel.UpdateBodygroups = RebuildBodygroups
end

-- Шаг 7: класс
stepBuilders[7] = function(parent)
    local selectedLabel = WO.UI.Label(parent, "", "WO.Small", WO.UI.Colors.accent)

    selectedLabel:Dock(TOP)
    selectedLabel:DockMargin(0, 0, 0, 4)
    selectedLabel:SetTall(22)

    local function UpdateSelectedClass()
        local class = draft.class and WO.Classes.Get(draft.class)
        local name = class and class.name or WO.Lang:Get("character.class_unselected")

        selectedLabel:SetDisplayText(WO.Lang:Get("character.selected_class") .. ": " .. name)
    end

    UpdateSelectedClass()

    local scroll = WO.UI.Scroll(parent)

    scroll:Dock(FILL)
    scroll:DockMargin(0, 4, 0, 0)

    for _, classId in ipairs(WO.Classes.GetIDs()) do
        local class = WO.Classes.Get(classId)
        local allowed = WO.Races.IsClassAllowed(draft.race, classId)

        local button = WO.UI.Button(scroll, (allowed and "" or "✖ ") .. class.name, function()
            if not allowed then return end

            draft.class = classId
            UpdateSelectedClass()
        end)

        button:Dock(TOP)
        button:DockMargin(0, 0, 0, 6)
        button:SetTall(36)
        button:SetEnabled(allowed)

        if class.description then
            local label = WO.UI.Label(scroll, class.description, "WO.Tiny", WO.UI.Colors.textDim)

            label:Dock(TOP)
            label:DockMargin(8, -4, 8, 6)
            label:SetTall(30)
        end
    end
end

local function SubmitDraft()
    if submitPending or not draft.confirmed then return end

    submitPending = true
    submitButton = IsValid(createFrame) and createFrame.primaryButton or nil

    if IsValid(submitButton) then
        submitButton:SetEnabled(false)
    end

    WO.Character.RequestCreate({
        name = draft.name,
        surname = draft.surname,
        age = draft.age,
        gender = draft.gender,
        race = draft.race,
        class = draft.class,
        model = draft.model,
        customization = draft.customization,
    })
end

-- Шаг 8: итоговая карточка и явное подтверждение создания
stepBuilders[8] = function(parent)
    draft.confirmed = false

    local race = WO.Races.Get(draft.race)
    local class = WO.Classes.Get(draft.class)
    local rows = {
        { key = "character.full_name", value = draft.name .. " " .. draft.surname },
        { key = "character.age", value = tostring(draft.age) },
        { key = "character.gender", value = WO.Lang:Get("gender." .. tostring(draft.gender)) },
        { key = "character.race", value = race and race.name or "—" },
        { key = "character.class", value = class and class.name or "—" },
        { key = "character.model", value = isstring(draft.model) and
            (string.match(draft.model, "([^/]+)$") or "—") or "—" },
    }

    local intro = WO.UI.Label(parent, WO.Lang:Get("character.review_instructions"),
        "WO.Small", WO.UI.Colors.textDim)
    intro:Dock(TOP)
    intro:DockMargin(0, 0, 0, 8)
    intro:SetTall(34)

    for _, row in ipairs(rows) do
        local label = WO.UI.Label(parent, WO.Lang:Get(row.key) .. ": " .. row.value, "WO.Body")
        label:Dock(TOP)
        label:DockMargin(0, 3, 0, 0)
        label:SetTall(21)
    end

    local statsLabel = WO.UI.Label(parent, WO.Lang:Get("character_menu.stats"),
        "WO.Subtitle", WO.UI.Colors.accent)
    statsLabel:Dock(TOP)
    statsLabel:DockMargin(0, 12, 0, 3)
    statsLabel:SetTall(22)

    for _, stat in ipairs(WO.Stats.PrimaryStats or { "strength", "agility", "intelligence", "stamina", "spirit" }) do
        local raceBonus = (race and race.stats and race.stats[stat]) or 0
        local classBonus = (class and class.stats and class.stats[stat]) or 0
        local label = WO.UI.Label(parent,
            WO.Lang:Get("stats." .. stat) .. ": " .. (raceBonus + classBonus),
            "WO.Small", WO.UI.Colors.textDim)
        label:Dock(TOP)
        label:DockMargin(8, 1, 0, 0)
        label:SetTall(17)
    end

    local confirmToggle
    confirmToggle = WO.UI.Button(parent, "", function()
        draft.confirmed = not draft.confirmed
        confirmToggle:SetDisplayText((draft.confirmed and "☑ " or "☐ ") ..
            WO.Lang:Get("character.create_confirm_check"))
        confirmToggle:SetAccent(draft.confirmed)

        if IsValid(createFrame) and IsValid(createFrame.primaryButton) then
            createFrame.primaryButton:SetEnabled(draft.confirmed and not submitPending)
        end
    end)
    confirmToggle:Dock(TOP)
    confirmToggle:DockMargin(0, 12, 0, 0)
    confirmToggle:SetTall(38)
    confirmToggle:SetDisplayText("☐ " .. WO.Lang:Get("character.create_confirm_check"))
end

---------------------------------------------------------------------------
-- Каркас экрана
---------------------------------------------------------------------------

local function BuildStep(parent, modelPanel)
    parent:Clear()

    local title = WO.UI.Label(parent, draft.step .. ". " .. WO.Lang:Get(STEP_NAMES[draft.step]), "WO.Subtitle", WO.UI.Colors.accent)

    title:Dock(TOP)
    title:DockMargin(0, 0, 0, 10)
    title:SetTall(26)

    local builder = stepBuilders[draft.step]

    if builder then
        builder(parent, modelPanel)
    end

    local primaryButton = IsValid(createFrame) and createFrame.primaryButton

    if IsValid(primaryButton) then
        if draft.step == 8 then
            primaryButton:SetDisplayText(WO.Lang:Get("character.create_confirm_action"))
            primaryButton:SetEnabled(draft.confirmed and not submitPending)
        else
            primaryButton:SetDisplayText(WO.Lang:Get("ui.next"))
            primaryButton:SetEnabled(true)
        end
    end
end

function WO.CharacterUI.OpenCreate()
    if WO.Models and WO.Models.RefreshRaceLists then
        WO.Models.RefreshRaceLists()
    end

    if WO.CharacterUI.CloseMenus then
        WO.CharacterUI.CloseMenus()
    else
        CloseCreate()
    end

    CloseCreate()
    WO.CharacterUI.CurrentScreen = "create"
    draft = NewDraft()

    createFrame = vgui.Create("DFrame")
    createFrame:SetTitle("")
    createFrame:ShowCloseButton(false)
    createFrame:SetDraggable(false)
    createFrame:SetSizable(false)
    createFrame:MakePopup()
    createFrame.OnKeyCodePressed = function(_, key)
        if key == KEY_ESCAPE then
            WO.CharacterUI.OpenMainMenu()
        end
    end

    createFrame.Paint = function(_, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(10, 12, 18, 252))
    end

    local stepPanel = vgui.Create("DPanel", createFrame)
    stepPanel:SetPaintBackground(false)
    stepPanel.Paint = function(_, w, h)
        WO.UI.DrawPanelOutlined(0, 0, w, h, WO.UI.Colors.panel, WO.UI.Colors.border,
            WO.UI.Metrics.radius)
    end

    -- Если локальной модели пока нет — показываем понятный placeholder, не citizen.
    local modelPanel = WO.UI.CreateCharacterModel(createFrame)
    modelPanel.spin = true
    WO.CharacterUI.PreviewModel = modelPanel

    local rotateLeftButton = WO.UI.Button(createFrame, WO.Lang:Get("character.rotate_left"), function()
        modelPanel:RotateBy(-20)
    end)

    local rotateRightButton = WO.UI.Button(createFrame, WO.Lang:Get("character.rotate_right"), function()
        modelPanel:RotateBy(20)
    end)

    local rotateHint = WO.UI.Label(createFrame, WO.Lang:Get("character.rotate_hint"),
        "WO.Small", WO.UI.Colors.textDim)

    local backButton = WO.UI.Button(createFrame, WO.Lang:Get("ui.back"), function()
        if draft.step > 1 then
            draft.step = draft.step - 1
            BuildStep(stepPanel, modelPanel)
        end
    end)

    local nextButton = WO.UI.Button(createFrame, WO.Lang:Get("ui.next"), function()
        local valid, reason = ValidateStep(draft.step)

        if not valid then
            WO.Notify.Show("error", WO.Lang:Get(tostring(reason)))
            return
        end

        if draft.step == 8 then
            SubmitDraft()
            return
        end

        if draft.step < 8 then
            draft.step = draft.step + 1
            BuildStep(stepPanel, modelPanel)

            -- Первый проход создаёт контролы bodygroups; второй обновляет их
            -- после того, как PreviewModel получил RebuildBodygroups callback.
            if draft.step == 6 and modelPanel.UpdateBodygroups then
                BuildStep(stepPanel, modelPanel)
            end
        end
    end)

    createFrame.primaryButton = nextButton
    nextButton:SetAccent(true)

    -- Возврат из мастера в главное меню (создание можно продолжить позже).
    local closeButton = WO.UI.Button(createFrame, "✕", function()
        CloseCreate()
        WO.CharacterUI.OpenMainMenu()
    end)

    closeButton:SetAccent(true)
    createFrame.woControls = {
        title = vgui.Create("DPanel", createFrame),
        step = stepPanel,
        model = modelPanel,
        rotateLeft = rotateLeftButton,
        rotateRight = rotateRightButton,
        rotateHint = rotateHint,
        back = backButton,
        next = nextButton,
        close = closeButton,
    }
    createFrame.woControls.title:SetPaintBackground(false)
    createFrame.woControls.title.Paint = function(_, w, h)
        WO.UI.DrawTextFit(WO.Lang:Get("character.create"), "WO.Title", w / 2, h / 2,
            WO.UI.Colors.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, w - 16, h - 2)
    end

    createLayout = LayoutCreateFrame
    LayoutCreateFrame()
    BuildStep(stepPanel, modelPanel)
end

---------------------------------------------------------------------------
-- События
---------------------------------------------------------------------------

WO.Hook.Add("OpenCharacterCreate", "character_ui", function()
    WO.CharacterUI.OpenCreate()
end)

WO.Hook.Add("CharacterCreateResult", "character_create_pending", function(success)
    if success then return end

    submitPending = false

    if IsValid(submitButton) then
        submitButton:SetEnabled(true)
    end

    submitButton = nil
end)

WO.Hook.Add("OnScreenSizeChanged", "character_create_layout", function()
    if createLayout then
        createLayout()
    end
end)
