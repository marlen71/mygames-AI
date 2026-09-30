--[[
    Warcraft Online — экран создания персонажа (client).

    Шаги:
        1. Раса → 2. Пол → 3. Возраст → 4. Имя → 5. Фамилия →
        6. Кастомизация → 7. Класс → 8. Предпросмотр → 9. Подтверждение

    Справа — 3D-preview (вращение мышью, zoom колесом, обновление в реальном времени).
    Сервер — финальный авторитет: клиентская валидация только для удобства.
]]

local createFrame = nil

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
    "character.step.preview",
    "character.step.confirm",
}

local function CloseCreate()
    if IsValid(createFrame) then
        createFrame:Remove()
        createFrame = nil
    end
end

WO.CharacterUI.CloseCreate = CloseCreate

local function PreviewUpdate(modelPanel)
    if not IsValid(modelPanel) then return end

    if draft.model and draft.model ~= modelPanel.currentModel then
        modelPanel:SetModel(draft.model)
        modelPanel.currentModel = draft.model

        -- Модель сменилась — перестраиваем контролы bodygroups (у каждой модели свои)
        if isfunction(modelPanel.UpdateBodygroups) then
            modelPanel.UpdateBodygroups()
        end
    end

    modelPanel:ApplyCustomization(draft.customization)
end

---------------------------------------------------------------------------
-- Валидация черновика (клиентская, для удобства; сервер проверяет всё)
---------------------------------------------------------------------------

local function ValidateStep(step)
    if step == 1 and not draft.race then
        return false, "character.race"
    elseif step == 2 and not draft.gender then
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
        if not draft.model then
            return false, "character.model"
        end
    elseif step == 7 and not draft.class then
        return false, "character.class"
    end

    return true
end

---------------------------------------------------------------------------
-- Построение шагов
---------------------------------------------------------------------------

local stepBuilders = {}

-- Шаг 1: раса
stepBuilders[1] = function(parent, modelPanel)
    local scroll = WO.UI.Scroll(parent)

    scroll:Dock(FILL)
    scroll:DockMargin(0, 10, 0, 0)

    for _, raceId in ipairs(WO.Races.GetIDs()) do
        local race = WO.Races.Get(raceId)

        local button = WO.UI.Button(scroll, race.name, function()
            draft.race = raceId

            -- Сбрасываем пол/модель/класс при смене расы
            draft.gender = nil
            draft.model = nil
            draft.class = nil

            local models = WO.Races.GetModels(raceId, draft.gender or "male")

            if models[1] then
                draft.model = models[1]
                draft.modelIndex = 1
            end

            PreviewUpdate(modelPanel)
        end)

        button:Dock(TOP)
        button:DockMargin(0, 0, 0, 6)
        button:SetTall(36)

        if race.description then
            local label = WO.UI.Label(scroll, race.description, "WO.Tiny", WO.UI.Colors.textDim)

            label:Dock(TOP)
            label:DockMargin(8, -4, 8, 6)
            label:SetTall(16)
        end
    end
end

-- Шаг 2: пол
stepBuilders[2] = function(parent, modelPanel)
    local race = WO.Races.Get(draft.race)

    for _, gender in ipairs((race and race.genders) or WO.Config.Genders or {}) do
        local button = WO.UI.Button(parent, WO.Lang:Get("gender." .. gender), function()
            draft.gender = gender

            -- Модели по полу
            local models = WO.Races.GetModels(draft.race, gender)

            if models[1] then
                draft.model = models[1]
                draft.modelIndex = 1
            end

            PreviewUpdate(modelPanel)
        end)

        button:Dock(TOP)
        button:DockMargin(0, 6, 0, 0)
        button:SetTall(36)
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
        label:SetText(WO.Lang:Get("character.age") .. ": " .. draft.age)
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

    local hint = WO.UI.Label(parent,
        WO.Config.NameMinLength .. "–" .. WO.Config.NameMaxLength .. " символов (буквы, пробел, дефис)",
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

        modelIndexLabel:SetText(draft.modelIndex .. " / " .. math.max(1, #models))
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
                draw.SimpleText(bg.name, "WO.Small", 0, h / 2, WO.UI.Colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
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
stepBuilders[7] = function(parent, modelPanel)
    local scroll = WO.UI.Scroll(parent)

    scroll:Dock(FILL)
    scroll:DockMargin(0, 10, 0, 0)

    for _, classId in ipairs(WO.Classes.GetIDs()) do
        local class = WO.Classes.Get(classId)
        local allowed = WO.Races.IsClassAllowed(draft.race, classId)

        local button = WO.UI.Button(scroll, (allowed and "" or "✖ ") .. class.name, function()
            if not allowed then return end

            draft.class = classId
        end)

        button:Dock(TOP)
        button:DockMargin(0, 0, 0, 6)
        button:SetTall(36)
        button:SetEnabled(allowed)

        if class.description then
            local label = WO.UI.Label(scroll, class.description, "WO.Tiny", WO.UI.Colors.textDim)

            label:Dock(TOP)
            label:DockMargin(8, -4, 8, 6)
            label:SetTall(16)
        end
    end
end

-- Шаг 8: предпросмотр
stepBuilders[8] = function(parent)
    local race = WO.Races.Get(draft.race)
    local class = WO.Classes.Get(draft.class)

    local lines = {
        WO.Lang:Get("character.full_name") .. ": " .. draft.name .. " " .. draft.surname,
        WO.Lang:Get("character.age") .. ": " .. draft.age,
        WO.Lang:Get("character.gender") .. ": " .. WO.Lang:Get("gender." .. tostring(draft.gender)),
        WO.Lang:Get("character.race") .. ": " .. (race and race.name or "?"),
        WO.Lang:Get("character.class") .. ": " .. (class and class.name or "?"),
    }

    for _, line in ipairs(lines) do
        local label = WO.UI.Label(parent, line, "WO.Body")

        label:Dock(TOP)
        label:DockMargin(0, 8, 0, 0)
        label:SetTall(20)
    end

    -- Бонусы расы/класса
    local statsLabel = WO.UI.Label(parent, WO.Lang:Get("character_menu.stats"), "WO.Subtitle", WO.UI.Colors.accent)

    statsLabel:Dock(TOP)
    statsLabel:DockMargin(0, 20, 0, 4)
    statsLabel:SetTall(22)

    for _, stat in ipairs(WO.Stats.PrimaryStats or { "strength", "agility", "intelligence", "stamina", "spirit" }) do
        local raceBonus = (race and race.stats and race.stats[stat]) or 0
        local classBonus = (class and class.stats and class.stats[stat]) or 0

        local label = WO.UI.Label(parent,
            WO.Lang:Get("stats." .. stat) .. ": " .. (raceBonus + classBonus),
            "WO.Small", WO.UI.Colors.textDim)

        label:Dock(TOP)
        label:DockMargin(8, 2, 0, 0)
        label:SetTall(16)
    end
end

-- Шаг 9: подтверждение
stepBuilders[9] = function(parent)
    local label = WO.UI.Label(parent, draft.name .. " " .. draft.surname, "WO.Title", WO.UI.Colors.accent)

    label:Dock(TOP)
    label:DockMargin(0, 20, 0, 10)
    label:SetTall(30)

    local confirmButton = WO.UI.Button(parent, WO.Lang:Get("ui.confirm"), function()
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
    end)

    confirmButton:Dock(TOP)
    confirmButton:DockMargin(0, 16, 0, 0)
    confirmButton:SetTall(44)
    confirmButton:SetAccent(true)

    local hint = WO.UI.Label(parent, WO.Lang:Get("character.create"), "WO.Small", WO.UI.Colors.textDim)

    hint:Dock(TOP)
    hint:DockMargin(0, 12, 0, 0)
    hint:SetTall(18)
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
end

function WO.CharacterUI.OpenCreate()
    CloseCreate()

    draft = NewDraft()

    createFrame = vgui.Create("DFrame")
    createFrame:SetSize(ScrW(), ScrH())
    createFrame:SetPos(0, 0)
    createFrame:SetTitle("")
    createFrame:ShowCloseButton(false)
    createFrame:SetDraggable(false)
    createFrame:MakePopup()

    createFrame.Paint = function(_, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(10, 12, 18, 252))
        draw.SimpleText(WO.Lang:Get("character.create"), "WO.Title", w / 2, 24, WO.UI.Colors.accent, TEXT_ALIGN_CENTER)
    end

    -- Левая панель: шаги
    local stepPanel = vgui.Create("DPanel", createFrame)

    stepPanel:SetPos(60, 70)
    stepPanel:SetSize(ScrW() * 0.32, ScrH() - 170)
    stepPanel:SetPaintBackground(false)

    -- Правая панель: 3D preview
    local modelPanel = WO.UI.CreateCharacterModel(createFrame, "models/player/group01/male_01.mdl")

    modelPanel:SetPos(ScrW() * 0.42, 70)
    modelPanel:SetSize(ScrW() * 0.52, ScrH() - 170)
    modelPanel.spin = true

    -- Навигация
    local navY = ScrH() - 80

    local backButton = WO.UI.Button(createFrame, WO.Lang:Get("ui.back"), function()
        if draft.step > 1 then
            draft.step = draft.step - 1

            BuildStep(stepPanel, modelPanel)
        end
    end)

    backButton:SetPos(60, navY)
    backButton:SetSize(150, 40)

    local nextButton = WO.UI.Button(createFrame, WO.Lang:Get("ui.next"), function()
        local valid, reason = ValidateStep(draft.step)

        if not valid then
            WO.Notify.Show("error", WO.Lang:Get(tostring(reason)))

            return
        end

        if draft.step < 9 then
            draft.step = draft.step + 1

            BuildStep(stepPanel, modelPanel)

            -- Перестраиваем bodygroups при входе в шаг кастомизации
            if draft.step == 6 and modelPanel.UpdateBodygroups then
                BuildStep(stepPanel, modelPanel)
            end
        end
    end)

    nextButton:SetPos(ScrW() * 0.42 + ScrW() * 0.52 - 150, navY)
    nextButton:SetSize(150, 40)
    nextButton:SetAccent(true)

    -- Закрыть (возврат к выбору, если есть персонажи)
    local closeButton = WO.UI.Button(createFrame, "✕", function()
        CloseCreate()

        if #WO.Character.GetList() > 0 then
            WO.CharacterUI.OpenSelect()
        end
    end)

    closeButton:SetPos(ScrW() - 70, 20)
    closeButton:SetSize(40, 40)

    BuildStep(stepPanel, modelPanel)
end

---------------------------------------------------------------------------
-- События
---------------------------------------------------------------------------

WO.Hook.Add("OpenCharacterCreate", "character_ui", function()
    WO.CharacterUI.OpenCreate()
end)
