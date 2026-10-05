--[[
    Warcraft Online — единое полноэкранное игровое меню и TAB-scoreboard (client).

    Один корневой экран обслуживает главное меню, список игроков и переходы к
    листу персонажа/инвентарю/квестам. Все изменения данных идут через API плагинов.
]]

WO.MenuUI = WO.MenuUI or {}

local menuFrame = nil
local currentPage = nil
local openedByScoreboardKey = false
local scoreboardKeyDown = false
local escapeDispatchActive = false
local HEADER_HEIGHT = 78

local function LocalCharacter()
    return WO.Character and WO.Character.GetLocal and WO.Character.GetLocal() or nil
end

local function HasLocalCharacter()
    local ply = LocalPlayer()

    return IsValid(ply) and ply:HasCharacter() and LocalCharacter() ~= nil
end

local function DefaultPage()
    return HasLocalCharacter() and "overview" or "characters"
end

local function PanelWidth(panel, fallback)
    local width = IsValid(panel) and panel:GetWide() or nil

    if isnumber(width) and width > 0 then
        return width
    end

    return fallback or 800
end

local function PreviewModelPath(char)
    if char and isstring(char.model) and char.model ~= "" and
        WO.Races and WO.Races.IsPlayableModel and WO.Races.IsPlayableModel(char.model) then
        return char.model
    end

    return nil
end

local function AddPageHeader(parent, title, subtitle)
    local header = vgui.Create("DPanel", parent)
    header:Dock(TOP)
    header:SetTall(subtitle and 76 or 54)
    header:DockMargin(0, 0, 0, 12)
    header:SetPaintBackground(false)

    header.Paint = function(_, w, h)
        WO.UI.DrawTextFit(title, "WO.Title", 0, 3, WO.UI.Colors.accent,
            TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, w - 8, 34)

        if subtitle then
            WO.UI.DrawTextFit(subtitle, "WO.Small", 2, 42, WO.UI.Colors.textDim,
                TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, w - 12, 22)
        end
    end

    return header
end

local function AddPreviewPanel(parent, char, title)
    local preview = vgui.Create("DPanel", parent)
    preview:Dock(RIGHT)
    preview:SetWide(math.max(250, math.min(720, math.floor(ScrW() * 0.32))))
    preview:DockMargin(12, 0, 0, 0)

    preview.Paint = function(_, w, h)
        WO.UI.DrawPanelOutlined(0, 0, w, h, WO.UI.Colors.panelDark,
            WO.UI.Colors.borderLight)
        WO.UI.DrawTextFit(title, "WO.Subtitle", 18, 16, WO.UI.Colors.accent,
            TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, w - 36, 26)
    end

    local model = WO.UI.CreateCharacterModel(preview, PreviewModelPath(char))
    model:Dock(FILL)
    model:DockMargin(12, 48, 12, 12)

    return preview, model
end

function WO.MenuUI.IsOpen()
    return IsValid(menuFrame)
end

function WO.MenuUI.GetPage()
    return currentPage
end

function WO.MenuUI.Close()
    local oldFrame = menuFrame

    menuFrame = nil
    currentPage = nil
    openedByScoreboardKey = false

    if IsValid(oldFrame) then
        oldFrame:Close()
    end
end

-- Escape can reach both the focused VGUI frame and the engine pause-menu hook
-- for one key press. Process that physical press once, then clear the guard on
-- the next tick.
local function BeginEscapeDispatch()
    if escapeDispatchActive then return false end

    escapeDispatchActive = true
    timer.Simple(0, function()
        escapeDispatchActive = false
    end)

    return true
end

local function ToggleMenuFromEscape()
    if WO.MenuUI.IsOpen() then
        local ply = LocalPlayer()
        local mandatoryCharacterMenu = IsValid(ply) and not ply:HasCharacter() and
            currentPage == "characters"

        if not mandatoryCharacterMenu then
            WO.MenuUI.Close()
        end

        return
    end

    WO.MenuUI.Show(DefaultPage())
end

-- Character creation/selection screens have their own Escape navigation. They
-- can mark the same key press as consumed so the global pause-menu hook cannot
-- also open/close the gameplay menu after the character screen changes.
WO.MenuUI.SuppressEscapeToggle = BeginEscapeDispatch

hook.Add("OnPauseMenuShow", "wo_menu_escape_toggle", function()
    if not BeginEscapeDispatch() then return false end

    local characterScreen = WO.CharacterUI and WO.CharacterUI.CurrentScreen
    if characterScreen and characterScreen ~= "main" then
        return false
    end

    ToggleMenuFromEscape()
    return false
end)

local function BuildCharactersPage(parent)
    local char = LocalCharacter()
    local saved = WO.Character and WO.Character.GetList and WO.Character.GetList() or {}
    local title = WO.Lang:Get("menu.characters")
    local subtitle = char and WO.Lang:Get("menu.overview_subtitle") or
        WO.Lang:Get("menu.characters_subtitle")

    AddPageHeader(parent, title, subtitle)

    local body = vgui.Create("DPanel", parent)
    body:Dock(FILL)
    body:SetPaintBackground(false)

    AddPreviewPanel(body, char, char and WO.Lang:Get("menu.character_preview") or
        WO.Lang:Get("menu.character_preview"))

    local details = vgui.Create("DPanel", body)
    details:Dock(FILL)
    details:DockMargin(0, 0, 12, 0)
    details.Paint = function(_, w, h)
        WO.UI.DrawPanelOutlined(0, 0, w, h, WO.UI.Colors.panel,
            WO.UI.Colors.border)
    end

    if not char then
        local info = WO.UI.Label(details, WO.Lang:Get("menu.no_character"),
            "WO.Subtitle", WO.UI.Colors.text)
        info:Dock(TOP)
        info:DockMargin(22, 26, 22, 12)
        info:SetTall(54)

        local hint = WO.UI.Label(details, WO.Lang:Get("menu.character_start_hint"),
            "WO.Body", WO.UI.Colors.textDim)
        hint:Dock(TOP)
        hint:DockMargin(22, 0, 22, 22)
        hint:SetTall(64)

        local createButton = WO.UI.Button(details, WO.Lang:Get("character.menu.create"), function()
            WO.CharacterUI.OpenCreate()
        end)
        createButton:Dock(TOP)
        createButton:DockMargin(22, 0, 22, 10)
        createButton:SetTall(52)
        createButton:SetAccent(true)
        createButton:SetFont("WO.MenuButton")

        local loadButton = WO.UI.Button(details, WO.Lang:Get("character.menu.load"), function()
            if #saved > 0 then
                WO.CharacterUI.OpenSelect()
            else
                WO.Notify.Show("info", WO.Lang:Get("character.no_saved_characters"))
            end
        end)
        loadButton:Dock(TOP)
        loadButton:DockMargin(22, 0, 22, 10)
        loadButton:SetTall(48)
        loadButton:SetEnabled(#saved > 0)
        loadButton:SetFont("WO.MenuButton")

        local savedText = #saved > 0 and
            (WO.Lang:Get("menu.saved_characters") .. ": " .. #saved) or
            WO.Lang:Get("character.no_saved_characters")
        local savedLabel = WO.UI.Label(details, savedText, "WO.Small", WO.UI.Colors.textDim)
        savedLabel:Dock(TOP)
        savedLabel:DockMargin(24, 4, 24, 0)
        savedLabel:SetTall(28)

        return
    end

    local race = WO.Races.Get(char.race)
    local class = WO.Classes.Get(char.class)
    local level = (WO.Leveling.ClientData and WO.Leveling.ClientData.level) or char.level or 1

    local summary = vgui.Create("DPanel", details)
    summary:Dock(TOP)
    summary:DockMargin(18, 20, 18, 16)
    summary:SetTall(112)
    summary.Paint = function(_, w, h)
        WO.UI.DrawPanelOutlined(0, 0, w, h, WO.UI.Colors.panelDark,
            WO.UI.Colors.border)
        WO.UI.DrawTextFit(char:GetFullName(), "WO.Title", 16, 16,
            WO.UI.Colors.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, w - 32, 32)
        WO.UI.DrawTextFit(WO.Lang:Get("character.level") .. " " .. level .. "  ·  " ..
            (race and race.name or char.race) .. "  ·  " ..
            (class and class.name or char.class), "WO.Body", 16, 60,
            WO.UI.Colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, w - 32, 24)

        local xp = WO.Leveling and WO.Leveling.ClientData or {}
        local needed = math.max(1, tonumber(xp.needed) or WO.Config.GetXPForLevel(level))
        local experience = math.max(0, tonumber(xp.experience) or tonumber(char.experience) or 0)
        WO.UI.DrawTextFit(WO.Lang:Get("xp.remaining", math.max(0, needed - experience)),
            "WO.Tiny", 16, 84, WO.UI.Colors.textDim,
            TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, w - 32, 14)
        WO.UI.DrawBar(16, 98, w - 32, 8, experience / needed,
            WO.UI.Colors.xp, WO.UI.Colors.xpBg, nil)
    end

    local logoutButton = WO.UI.Button(details, WO.Lang:Get("character.logout"), function()
        WO.MenuUI.Close()
        WO.Character.RequestLogout()
    end)
    logoutButton:Dock(TOP)
    logoutButton:DockMargin(18, 0, 18, 10)
    logoutButton:SetTall(48)
    logoutButton:SetAccent(true)
    logoutButton:SetFont("WO.MenuButton")

    local savedLabel = WO.UI.Label(details,
        WO.Lang:Get("menu.saved_characters") .. ": " .. #saved,
        "WO.Small", WO.UI.Colors.textDim)
    savedLabel:Dock(TOP)
    savedLabel:DockMargin(20, 8, 20, 0)
    savedLabel:SetTall(28)
end

local function BuildOverviewPage(parent)
    local char = LocalCharacter()
    local subtitle = char and WO.Lang:Get("menu.overview_subtitle") or
        WO.Lang:Get("menu.no_character")

    AddPageHeader(parent, WO.Lang:Get("menu.overview"), subtitle)

    local scroll = WO.UI.Scroll(parent)
    scroll:Dock(FILL)
    scroll:SetSize(parent:GetWide(), math.max(1, parent:GetTall() - 88))

    local hero = vgui.Create("DPanel", scroll)
    hero:Dock(TOP)
    hero:SetTall(270)
    hero:DockMargin(0, 0, 0, 14)
    hero:SetPaintBackground(false)

    AddPreviewPanel(hero, char, WO.Lang:Get("menu.character_preview"))

    local details = vgui.Create("DPanel", hero)
    details.woOverviewDetails = true
    details:Dock(FILL)
    details:DockMargin(0, 0, 12, 0)
    details.Paint = function(_, w, h)
        WO.UI.DrawPanelOutlined(0, 0, w, h, WO.UI.Colors.panel,
            WO.UI.Colors.border, WO.UI.Metrics.radius)

        if not char then
            WO.UI.DrawTextFit(WO.Lang:Get("menu.no_character"), "WO.Subtitle", 18, 25,
                WO.UI.Colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, w - 36, 30)
            WO.UI.DrawTextFit(WO.Lang:Get("menu.character_start_hint"), "WO.Body", 20, 66,
                WO.UI.Colors.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, w - 40, 48)
            return
        end

        local race = WO.Races.Get(char.race)
        local class = WO.Classes.Get(char.class)
        local xp = WO.Leveling and WO.Leveling.ClientData or {}
        local level = math.max(1, tonumber(xp.level) or tonumber(char.level) or 1)
        local needed = math.max(1, tonumber(xp.needed) or WO.Config.GetXPForLevel(level))
        local experience = math.max(0, tonumber(xp.experience) or tonumber(char.experience) or 0)

        WO.UI.DrawTextFit(char:GetFullName(), "WO.Title", 18, 24,
            WO.UI.Colors.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, w - 36, 34)
        WO.UI.DrawTextFit(WO.Lang:Get("character.level") .. " " .. level .. "  ·  " ..
            (race and race.name or char.race) .. "  ·  " ..
            (class and class.name or char.class), "WO.Body", 20, 67,
            WO.UI.Colors.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, w - 40, 24)
        WO.UI.DrawTextFit(WO.Lang:Get("xp.compact", experience, needed,
            math.max(0, needed - experience)), "WO.Tiny", 20, 105,
            WO.UI.Colors.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, w - 40, 18)
        WO.UI.DrawBar(20, 128, w - 40, 8, experience / needed,
            WO.UI.Colors.xp, WO.UI.Colors.xpBg, nil)
        WO.UI.DrawTextFit(WO.Lang:Get("menu.server_players") .. ": " .. #player.GetAll(),
            "WO.Small", 20, 148, WO.UI.Colors.textDim,
            TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, w - 40, 20)
    end

    local actionRow = vgui.Create("DPanel", details)
    actionRow:Dock(BOTTOM)
    actionRow:DockMargin(14, 0, 14, 14)
    actionRow:SetTall(44)
    actionRow:SetPaintBackground(false)

    local actions = char and {
        { text = WO.Lang:Get("menu.inventory"), id = "inventory" },
        { text = WO.Lang:Get("menu.quests"), id = "quests" },
    } or {
        { text = WO.Lang:Get("character.menu.create"), id = "create" },
        { text = WO.Lang:Get("character.menu.load"), id = "characters" },
    }
    local columns = #actions
    local actionControls = {}

    actionRow.PerformLayout = function(self, w)
        local gap = 8
        local buttonWidth = math.max(1, math.floor((w - gap * (columns - 1)) / columns))

        for index, button in ipairs(actionControls) do
            button:SetPos((index - 1) * (buttonWidth + gap), 0)
            button:SetSize(buttonWidth, 44)
        end
    end

    for index, action in ipairs(actions) do
        local entry = action
        local button = WO.UI.Button(actionRow, entry.text, function()
            if entry.id == "create" then
                WO.CharacterUI.OpenCreate()
            elseif entry.id == "characters" then
                WO.MenuUI.ActivatePage("characters")
            else
                WO.MenuUI.ActivatePage(entry.id)
            end
        end)
        button:SetAccent(index == 1)
        button:SetFont("WO.Body")
        actionControls[#actionControls + 1] = button
    end

    if char and WO.CharacterUI and WO.CharacterUI.BuildOverviewStats then
        WO.CharacterUI.BuildOverviewStats(scroll)
    end

    local playersTitle = WO.UI.Label(scroll, WO.Lang:Get("menu.players"),
        "WO.Subtitle", WO.UI.Colors.accent)
    playersTitle:Dock(TOP)
    playersTitle:DockMargin(0, 0, 0, 8)
    playersTitle:SetTall(30)

    local allPlayers = player.GetAll and player.GetAll() or {}
    local playerList = vgui.Create("DPanel", scroll)
    playerList:Dock(TOP)
    playerList:SetTall(math.max(66, #allPlayers * 52 + 20))
    playerList:DockMargin(0, 0, 0, 12)
    playerList.Paint = function(_, w, h)
        WO.UI.DrawPanelOutlined(0, 0, w, h, WO.UI.Colors.panel,
            WO.UI.Colors.border, WO.UI.Metrics.radius)
    end

    local function PublicPlayerName(ply)
        local identity = WO.Social and WO.Social.GetVisibleIdentity and
            WO.Social.GetVisibleIdentity(ply)
        return identity and identity.name or "Неизвестный"
    end

    table.sort(allPlayers, function(a, b)
        return string.lower(PublicPlayerName(a)) < string.lower(PublicPlayerName(b))
    end)

    if #allPlayers == 0 then
        local empty = WO.UI.Label(playerList, WO.Lang:Get("menu.no_players"),
            "WO.Body", WO.UI.Colors.textDim)
        empty:Dock(TOP)
        empty:DockMargin(14, 14, 14, 0)
        empty:SetTall(34)
    end

    for index, ply in ipairs(allPlayers) do
        if IsValid(ply) then
            local row = vgui.Create("DPanel", playerList)
            row.woScoreboardRow = true
            row:SetPos(10, 10 + (index - 1) * 52)
            row:SetSize(math.max(1, parent:GetWide() - 20), 46)
            row.Paint = function(_, w, h)
                local identity = WO.Social and WO.Social.GetVisibleIdentity and
                    WO.Social.GetVisibleIdentity(ply) or { name = "Неизвестный", race = "" }
                local name = identity.name or "Неизвестный"
                local detailsText = identity.race and identity.race ~= "" and
                    ("  ·  " .. identity.race) or ""
                local known = identity.known == true

                if known and identity.class and identity.class ~= "" then
                    detailsText = detailsText .. " / " .. identity.class
                end

                WO.UI.DrawPanelOutlined(0, 0, w, h, WO.UI.Colors.panelDark,
                    WO.UI.Colors.border, WO.UI.Metrics.radiusSmall)
                WO.UI.DrawTextFit(name .. detailsText, "WO.Body", 12, h / 2,
                    WO.UI.Colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, w - 188, h - 4)
                if known then
                    WO.UI.DrawTextFit(WO.Lang:Get("character.level") .. " " ..
                        (identity.level or 1), "WO.Small", w - 84, h / 2,
                        WO.UI.Colors.textDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, 70, h - 4)
                end
                WO.UI.DrawTextFit(tostring(ply:Ping()) .. " ms", "WO.Small", w - 14,
                    h / 2, WO.UI.Colors.textDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, 60, h - 4)
            end
            row.PerformLayout = function(self)
                local list = self:GetParent()
                if IsValid(list) then
                    self:SetWide(math.max(1, list:GetWide() - 20))
                end
            end
        end
    end
end

local function BuildSettingsPage(parent)
    AddPageHeader(parent, WO.Lang:Get("settings.title"),
        WO.Lang:Get("settings.auto_collect_hint"))

    local settings = WO.Settings

    if not (settings and settings.RequestAutoCollect) then
        local unavailable = WO.UI.Label(parent, WO.Lang:Get("settings.auto_collect_status"),
            "WO.Body", WO.UI.Colors.textDim)
        unavailable:Dock(TOP)
        unavailable:SetTall(32)
        return
    end

    settings.RequestAutoCollect(false)

    local card = vgui.Create("DPanel", parent)
    card:Dock(TOP)
    card:SetTall(190)
    card:DockMargin(0, 4, 0, 12)
    card.Paint = function(_, w, h)
        WO.UI.DrawPanelOutlined(0, 0, w, h, WO.UI.Colors.panel,
            WO.UI.Colors.border)
    end

    local label = WO.UI.Label(card, WO.Lang:Get("settings.auto_collect"),
        "WO.Subtitle", WO.UI.Colors.accent)
    label:Dock(TOP)
    label:DockMargin(18, 14, 18, 8)
    label:SetTall(28)

    local hint = WO.UI.Label(card, WO.Lang:Get("settings.auto_collect_hint"),
        "WO.Small", WO.UI.Colors.textDim)
    hint:Dock(TOP)
    hint:DockMargin(18, 0, 18, 8)
    hint:SetTall(46)

    local enabled = settings.ClientAutoCollectEnabled == true
    local toggle = WO.UI.Button(card,
        WO.Lang:Get(enabled and "settings.auto_collect_on" or "settings.auto_collect_off"),
        function()
            local nextValue = not (settings.ClientAutoCollectEnabled == true)
            settings.SetClientAutoCollectEnabled(nextValue)
        end)
    toggle:Dock(BOTTOM)
    toggle:DockMargin(18, 0, 18, 14)
    toggle:SetTall(42)
    toggle:SetAccent(enabled)
    toggle:SetEnabled(settings.ClientAutoCollectLoaded == true)

    if settings.ClientAutoCollectLoaded ~= true then
        local status = WO.UI.Label(card, WO.Lang:Get("settings.auto_collect_status"),
            "WO.Tiny", WO.UI.Colors.textDim)
        status:Dock(BOTTOM)
        status:DockMargin(18, 0, 18, 8)
        status:SetTall(16)
    end
end

local function BuildAdminPage(parent)
    AddPageHeader(parent, "Администрирование", "Доступные команды режима, их назначение и безопасный запуск.")

    local admin = WO.Admin
    if not (admin and admin.ClientMenuAccess) then
        local denied = WO.UI.Label(parent, "Недостаточно прав для этого раздела.",
            "WO.Body", WO.UI.Colors.textDim)
        denied:Dock(TOP)
        denied:SetTall(28)
        return
    end

    local commands = admin.ClientMenuCommands or {}
    local scroll = WO.UI.Scroll(parent)
    scroll:Dock(FILL)

    if #commands == 0 then
        local empty = WO.UI.Label(scroll, "Для выданных вам прав нет доступных команд.",
            "WO.Body", WO.UI.Colors.textDim)
        empty:Dock(TOP)
        empty:SetTall(32)
        return
    end

    for _, command in ipairs(commands) do
        local entry = command
        local args = istable(entry.args) and entry.args or {}
        local cardHeight = #args > 0 and 122 or 90
        local card = vgui.Create("DPanel", scroll)
        card:Dock(TOP)
        card:SetTall(cardHeight)
        card:DockMargin(0, 0, 0, 8)
        card.Paint = function(_, w, h)
            WO.UI.DrawPanelOutlined(0, 0, w, h, WO.UI.Colors.panel,
                WO.UI.Colors.border)
            WO.UI.DrawTextFit(entry.title or entry.id, "WO.Body", 14, 8,
                WO.UI.Colors.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, w - 150, 22)
            WO.UI.DrawTextFit(entry.id or "", "WO.Tiny", w - 138, 10,
                WO.UI.Colors.textDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 124, 18)
            WO.UI.DrawTextFit(entry.description or "", "WO.Small", 14, 32,
                WO.UI.Colors.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, w - 28, 22)
        end

        local fields = {}
        local fieldTop = 68
        local buttonWidth = 112
        local available = math.max(160, PanelWidth(card, 760) - 28 - buttonWidth - 10)
        local fieldWidth = #args > 0 and math.max(90, math.floor((available - (#args - 1) * 8) / #args)) or 0

        for index, definition in ipairs(args) do
            local field = vgui.Create("DTextEntry", card)
            field:SetPos(14 + (index - 1) * (fieldWidth + 8), fieldTop)
            field:SetSize(fieldWidth, 32)
            field:SetPlaceholderText((definition.name or "Аргумент") ..
                (definition.placeholder and (" · " .. definition.placeholder) or ""))
            fields[index] = field
        end

        local runButton = WO.UI.Button(card, "Выполнить", function()
            if not admin.ClientMenuAccess or
                admin.ClientMenuPermissions[entry.permission] ~= true then
                if admin.RequestMenuData then admin.RequestMenuData(true) end
                return
            end

            local values = {}
            for index, field in ipairs(fields) do
                values[index] = string.Trim(field:GetValue() or "")
            end
            while #values > 0 and values[#values] == "" do
                values[#values] = nil
            end

            WO.Net.SendToServer("Admin.CommandRun", entry.id, values)
        end)
        runButton:SetPos(PanelWidth(card, 760) - buttonWidth - 14, fieldTop)
        runButton:SetSize(buttonWidth, 32)
        card.PerformLayout = function(self, w)
            local usable = math.max(150, w - 28 - buttonWidth - 10)
            local width = #args > 0 and math.max(90,
                math.floor((usable - (#args - 1) * 8) / #args)) or 0

            for index, field in ipairs(fields) do
                field:SetPos(14 + (index - 1) * (width + 8), fieldTop)
                field:SetSize(width, 32)
            end

            runButton:SetPos(w - buttonWidth - 14, fieldTop)
        end
    end
end

local function BuildPage(page)
    if not IsValid(menuFrame) or not IsValid(menuFrame.content) then return end

    currentPage = page or DefaultPage()

    if currentPage == "sheet" then
        currentPage = "overview"
    end

    if (currentPage == "inventory" or currentPage == "quests") and not HasLocalCharacter() then
        currentPage = "characters"
    end

    if currentPage == "admin" and not (WO.Admin and WO.Admin.ClientMenuAccess) then
        currentPage = "overview"
    end

    menuFrame.content:Clear()

    if currentPage == "characters" then
        BuildCharactersPage(menuFrame.content)
    elseif currentPage == "inventory" then
        if WO.InventoryUI and WO.InventoryUI.BuildPanel then
            WO.InventoryUI.BuildPanel(menuFrame.content)
        else
            BuildOverviewPage(menuFrame.content)
        end
    elseif currentPage == "quests" then
        if WO.Quests and WO.Quests.BuildJournal then
            WO.Quests.BuildJournal(menuFrame.content)
        else
            BuildOverviewPage(menuFrame.content)
        end
    elseif currentPage == "settings" then
        BuildSettingsPage(menuFrame.content)
    elseif currentPage == "admin" then
        BuildAdminPage(menuFrame.content)
    else
        currentPage = "overview"
        BuildOverviewPage(menuFrame.content)
    end

    for id, button in pairs(menuFrame.navButtons or {}) do
        if IsValid(button) then
            button:SetAccent(id == currentPage)
            button:SetEnabled(not button.characterOnly or HasLocalCharacter())
        end
    end
end

function WO.MenuUI.RefreshPage(page)
    if not IsValid(menuFrame) or (page and currentPage ~= page) then return false end

    BuildPage(currentPage or DefaultPage())
    return true
end

local function CreateMenuFrame()
    local width = ScrW()
    local height = ScrH()
    local sidebarWidth = math.max(220, math.min(300, math.floor(width * 0.19)))
    local contentTop = HEADER_HEIGHT + 22

    menuFrame = vgui.Create("DFrame")
    menuFrame:SetSize(width, height)
    menuFrame:SetPos(0, 0)
    menuFrame:SetTitle("")
    menuFrame:ShowCloseButton(false)
    menuFrame:SetDraggable(false)
    menuFrame:MakePopup()

    menuFrame.Paint = function(_, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(7, 10, 17, 244))
        draw.RoundedBox(0, 0, 0, w, HEADER_HEIGHT, WO.UI.Colors.panelDark)

        surface.SetDrawColor(WO.UI.Colors.borderLight)
        surface.DrawRect(0, HEADER_HEIGHT - 1, w, 1)
        surface.DrawRect(sidebarWidth, HEADER_HEIGHT, 1, h - HEADER_HEIGHT)

        WO.UI.DrawTextFit(WO.Lang:Get("menu.title"), "WO.Title", 28, 27,
            WO.UI.Colors.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER,
            math.max(120, sidebarWidth - 40), 32)
        WO.UI.DrawTextFit(WO.Lang:Get("menu.fullscreen_subtitle"), "WO.Small", 30, 56,
            WO.UI.Colors.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER,
            math.max(120, sidebarWidth - 44), 20)

        local char = LocalCharacter()
        local statusText

        if char then
            local level = (WO.Leveling.ClientData and WO.Leveling.ClientData.level) or char.level or 1
            statusText = char:GetFullName() .. "  ·  " .. WO.Lang:Get("character.level") .. " " .. level
        else
            statusText = WO.Lang:Get("menu.character_none")
        end

        WO.UI.DrawTextFit(statusText, "WO.Body", w - 72, 39,
            char and WO.UI.Colors.text or WO.UI.Colors.textDim,
            TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, math.max(120, w - sidebarWidth - 120), 24)
    end

    local sidebar = vgui.Create("DPanel", menuFrame)
    sidebar:SetPos(0, HEADER_HEIGHT)
    sidebar:SetSize(sidebarWidth, height - HEADER_HEIGHT)
    sidebar.Paint = function(_, w, h)
        draw.RoundedBox(0, 0, 0, w, h, WO.UI.Colors.panelDark)
    end

    menuFrame.navButtons = {}

    local navItems = {
        { id = "overview", text = WO.Lang:Get("menu.overview") },
        { id = "characters", text = WO.Lang:Get("menu.characters") },
        { id = "inventory", text = WO.Lang:Get("menu.inventory"), characterOnly = true },
        { id = "quests", text = WO.Lang:Get("menu.quests"), characterOnly = true },
        { id = "settings", text = WO.Lang:Get("menu.settings") },
    }

    if WO.Admin and WO.Admin.ClientMenuAccess then
        navItems[#navItems + 1] = { id = "admin", text = "Админ-меню" }
    end

    local navY = 24

    for _, item in ipairs(navItems) do
        local entry = item
        local button = WO.UI.Button(sidebar, entry.text, function()
            if entry.characterOnly and not HasLocalCharacter() then
                WO.Notify.Show("info", WO.Lang:Get("menu.no_character"))
                return
            end

            BuildPage(entry.id)
        end)

        button:SetPos(14, navY)
        button:SetSize(sidebarWidth - 28, 42)
        button:SetEnabled(not entry.characterOnly or HasLocalCharacter())
        button:SetFont("WO.Body")
        button.characterOnly = entry.characterOnly == true
        menuFrame.navButtons[entry.id] = button
        navY = navY + 52
    end

    local footer = vgui.Create("DPanel", sidebar)
    footer:SetPos(14, height - HEADER_HEIGHT - 112)
    footer:SetSize(sidebarWidth - 28, 64)
    footer:SetPaintBackground(false)
    footer.Paint = function(_, w, h)
        surface.SetDrawColor(WO.UI.Colors.border)
        surface.DrawRect(0, 0, w, 1)

        local char = LocalCharacter()
        local text = char and char:GetFullName() or WO.Lang:Get("menu.character_none")
        WO.UI.DrawTextFit(text, "WO.Small", 2, 12, WO.UI.Colors.textDim,
            TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, w - 4, h - 18)
    end

    local exitButton = WO.UI.Button(sidebar, WO.Lang:Get("menu.exit"), function()
        WO.MenuUI.Close()
        RunConsoleCommand("disconnect")
    end)
    exitButton:SetPos(14, height - HEADER_HEIGHT - 52)
    exitButton:SetSize(sidebarWidth - 28, 38)
    exitButton:SetFont("WO.Body")

    local closeButton = WO.UI.Button(menuFrame, "✕", function()
        WO.MenuUI.Close()
    end)
    closeButton:SetPos(width - 58, 19)
    closeButton:SetSize(40, 40)
    closeButton:SetFont("WO.MenuButton")
    closeButton:SetVisible(HasLocalCharacter())

    local content = vgui.Create("DPanel", menuFrame)
    content:SetPos(sidebarWidth + 28, contentTop)
    content:SetSize(width - sidebarWidth - 56, height - contentTop - 26)
    content:SetPaintBackground(false)
    menuFrame.content = content

    menuFrame.OnKeyCodePressed = function(_, key)
        if key == KEY_ESCAPE then
            if BeginEscapeDispatch() then
                ToggleMenuFromEscape()
            end

            return true
        end
    end

    menuFrame.OnRemove = function(self)
        if menuFrame == self then
            menuFrame = nil
            currentPage = nil
        end
    end
end

function WO.MenuUI.Show(page, fromScoreboardKey)
    if WO.Admin and WO.Admin.RequestMenuData then
        WO.Admin.RequestMenuData(false)
    end

    if not IsValid(menuFrame) then
        CreateMenuFrame()
    end

    if not fromScoreboardKey then
        openedByScoreboardKey = false
    end

    BuildPage(page or DefaultPage())

    if fromScoreboardKey then
        openedByScoreboardKey = true
    end
end

WO.Hook.Add("AdminMenuDataUpdated", "scoreboard_admin_nav", function()
    if not IsValid(menuFrame) then return end

    local page = currentPage or DefaultPage()
    local openedFromTab = openedByScoreboardKey
    local oldFrame = menuFrame
    menuFrame = nil
    if IsValid(oldFrame) then oldFrame:Remove() end
    WO.MenuUI.Show(page, openedFromTab)
end)

WO.Hook.Add("AutoCollectSettingsUpdated", "scoreboard_settings_refresh", function()
    if IsValid(menuFrame) and currentPage == "settings" then
        BuildPage("settings")
    end
end)

local function ActivatePage(page)
    if page == "sheet" then
        page = "overview"
    end

    if page == "inventory" or page == "quests" then
        if not HasLocalCharacter() then
            WO.Notify.Show("info", WO.Lang:Get("menu.no_character"))
            return false
        end
    end

    if page == "overview" or page == "characters" or page == "inventory" or
        page == "quests" or page == "settings" or page == "admin" then
        BuildPage(page)
        return true
    end

    return false
end

WO.MenuUI.ActivatePage = ActivatePage

hook.Add("OnScreenSizeChanged", "wo_menu_resize", function()
    if not IsValid(menuFrame) then return end

    local page = currentPage or DefaultPage()
    local openedFromTab = openedByScoreboardKey
    local oldFrame = menuFrame

    menuFrame = nil
    if IsValid(oldFrame) then oldFrame:Remove() end

    WO.MenuUI.Show(page, openedFromTab)
end)

local function BeginScoreboardKey()
    if scoreboardKeyDown then return end

    scoreboardKeyDown = true

    if WO.MenuUI.IsOpen() then
        -- TAB must not close a menu that was opened by another action.
        openedByScoreboardKey = false
    else
        WO.MenuUI.Show(DefaultPage(), true)
    end
end

local function EndScoreboardKey()
    local closeMenu = openedByScoreboardKey
    scoreboardKeyDown = false
    openedByScoreboardKey = false

    if closeMenu then
        WO.MenuUI.Close()
    end
end

local function IsScoreboardBind(bind)
    return isstring(bind) and string.find(string.lower(bind), "+showscores", 1, true) ~= nil
end

-- Intercept the actual +showscores bind on both edges. Returning true prevents
-- the engine's default scoreboard command; only our custom menu is displayed.
hook.Add("PlayerBindPress", "wo_menu_scoreboard_bind", function(_, bind, pressed)
    if not IsScoreboardBind(bind) then return end

    if pressed then
        BeginScoreboardKey()
    else
        EndScoreboardKey()
    end

    return true
end)

-- Keep engine/gamemode scoreboard callbacks suppressed as a fallback for
-- commands or addons that call the scoreboard directly instead of the bind.
hook.Add("ScoreboardShow", "wo_menu_scoreboard_show", function()
    BeginScoreboardKey()
    return true
end)

hook.Add("ScoreboardHide", "wo_menu_scoreboard_hide", function()
    EndScoreboardKey()
    return true
end)

function GM:ScoreboardShow()
    BeginScoreboardKey()
    return true
end

function GM:ScoreboardHide()
    EndScoreboardKey()
    return true
end
