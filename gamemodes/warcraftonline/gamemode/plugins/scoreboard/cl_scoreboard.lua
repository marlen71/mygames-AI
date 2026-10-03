--[[
    Warcraft Online — единое полноэкранное игровое меню и TAB-scoreboard (client).

    Один корневой экран обслуживает главное меню, список игроков и переходы к
    листу персонажа/инвентарю/квестам. Все изменения данных идут через API плагинов.
]]

WO.MenuUI = WO.MenuUI or {}

local menuFrame = nil
local currentPage = nil
local openedByScoreboardKey = false
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
    if char and isstring(char.model) and char.model ~= "" then
        return char.model
    end

    local raceModels = WO.Models and WO.Models.GetRace and WO.Models.GetRace("human") or nil
    local maleModels = raceModels and raceModels.male or nil

    return (maleModels and maleModels[1]) or "models/player/group01/male_01.mdl"
end

local function AddPageHeader(parent, title, subtitle)
    local header = vgui.Create("DPanel", parent)
    header:Dock(TOP)
    header:SetTall(subtitle and 76 or 54)
    header:DockMargin(0, 0, 0, 12)
    header:SetPaintBackground(false)

    header.Paint = function(_, w, h)
        draw.SimpleText(title, "WO.Title", 0, 3, WO.UI.Colors.accent,
            TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        if subtitle then
            draw.SimpleText(subtitle, "WO.Small", 2, 42, WO.UI.Colors.textDim,
                TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
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
        draw.SimpleText(title, "WO.Subtitle", 18, 16, WO.UI.Colors.accent,
            TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
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
        draw.SimpleText(char:GetFullName(), "WO.Title", 16, 16,
            WO.UI.Colors.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(WO.Lang:Get("character.level") .. " " .. level .. "  ·  " ..
            (race and race.name or char.race) .. "  ·  " ..
            (class and class.name or char.class), "WO.Body", 16, 60,
            WO.UI.Colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
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

    local hero = vgui.Create("DPanel", parent)
    hero:Dock(TOP)
    hero:SetTall(278)
    hero:DockMargin(0, 0, 0, 16)
    hero:SetPaintBackground(false)

    AddPreviewPanel(hero, char, WO.Lang:Get("menu.character_preview"))

    local details = vgui.Create("DPanel", hero)
    details:Dock(FILL)
    details:DockMargin(0, 0, 12, 0)
    details.Paint = function(_, w, h)
        WO.UI.DrawPanelOutlined(0, 0, w, h, WO.UI.Colors.panel,
            WO.UI.Colors.border)

        if char then
            local race = WO.Races.Get(char.race)
            local class = WO.Classes.Get(char.class)
            local level = (WO.Leveling.ClientData and WO.Leveling.ClientData.level) or char.level or 1

            draw.SimpleText(char:GetFullName(), "WO.Title", 20, 20,
                WO.UI.Colors.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText(WO.Lang:Get("character.level") .. " " .. level .. "  ·  " ..
                (race and race.name or char.race) .. "  ·  " ..
                (class and class.name or char.class), "WO.Body", 22, 66,
                WO.UI.Colors.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText(WO.Lang:Get("menu.server_players") .. ": " .. #player.GetAll(),
                "WO.Small", 22, 108, WO.UI.Colors.textDim,
                TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        else
            draw.SimpleText(WO.Lang:Get("menu.no_character"), "WO.Subtitle", 20, 22,
                WO.UI.Colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText(WO.Lang:Get("menu.character_start_hint"), "WO.Body", 22, 66,
                WO.UI.Colors.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
    end

    local actionRow = vgui.Create("DPanel", details)
    actionRow:Dock(BOTTOM)
    actionRow:DockMargin(16, 0, 16, 16)
    actionRow:SetTall(48)
    actionRow:SetPaintBackground(false)

    local actionButtons = char and {
        { text = WO.Lang:Get("menu.inventory"), id = "inventory" },
        { text = WO.Lang:Get("menu.sheet"), id = "sheet" },
        { text = WO.Lang:Get("menu.quests"), id = "quests" },
    } or {
        { text = WO.Lang:Get("character.menu.create"), id = "create" },
        { text = WO.Lang:Get("character.menu.load"), id = "characters" },
    }

    local gap = 8
    local estimatedPreviewWidth = math.max(250, math.min(720, math.floor(ScrW() * 0.32)))
    local expectedDetailsWidth = math.max(1,
        PanelWidth(parent, math.max(500, ScrW() - 340)) - estimatedPreviewWidth - 24)
    local columns = #actionButtons

    if expectedDetailsWidth < 560 then
        columns = math.min(2, #actionButtons)
    end

    if expectedDetailsWidth < 300 then
        columns = 1
    end

    local rows = math.ceil(#actionButtons / columns)
    local rowHeight = 44
    local rowGap = 8
    local actionControls = {}

    actionRow:SetTall(rows * rowHeight + (rows - 1) * rowGap)
    actionRow.PerformLayout = function(self, w)
        local controlWidth = math.max(1, math.floor((w - gap * (columns - 1)) / columns))

        for index, button in ipairs(actionControls) do
            local row = math.floor((index - 1) / columns)
            local column = (index - 1) % columns

            button:SetPos(column * (controlWidth + gap), row * (rowHeight + rowGap))
            button:SetSize(controlWidth, rowHeight)
        end
    end

    for index, action in ipairs(actionButtons) do
        local entry = action
        local button = WO.UI.Button(actionRow, entry.text, function()
            if entry.id == "create" then
                WO.CharacterUI.OpenCreate()
            elseif entry.id == "characters" then
                WO.MenuUI.Show("characters")
            else
                WO.MenuUI.Close()

                if entry.id == "inventory" and WO.InventoryUI then
                    WO.InventoryUI.Open()
                elseif entry.id == "sheet" and WO.CharacterUI.OpenSheet then
                    WO.CharacterUI.OpenSheet()
                elseif entry.id == "quests" and WO.Quests and WO.Quests.OpenLog then
                    WO.Quests.OpenLog()
                end
            end
        end)
        button:SetAccent(index == 1)
        button:SetFont(expectedDetailsWidth / columns < 180 and "WO.Small" or "WO.Body")
        actionControls[index] = button
    end

    local playersTitle = WO.UI.Label(parent, WO.Lang:Get("menu.players"),
        "WO.Subtitle", WO.UI.Colors.accent)
    playersTitle:Dock(TOP)
    playersTitle:DockMargin(0, 0, 0, 8)
    playersTitle:SetTall(30)

    local playerList = vgui.Create("DScrollPanel", parent)
    playerList:Dock(FILL)

    local allPlayers = player.GetAll and player.GetAll() or {}

    table.sort(allPlayers, function(a, b)
        local first = IsValid(a) and a:GetNW2String("wo_name", a:Nick()) or ""
        local second = IsValid(b) and b:GetNW2String("wo_name", b:Nick()) or ""

        return string.lower(first) < string.lower(second)
    end)

    for _, ply in ipairs(allPlayers) do
        if IsValid(ply) then
            local row = vgui.Create("DPanel", playerList)
            row:Dock(TOP)
            row:SetTall(48)
            row:DockMargin(0, 0, 0, 6)

            local name = ply:GetNW2String("wo_name", ply:Nick())
            local raceName = ply:GetNW2String("wo_race", "")
            local className = ply:GetNW2String("wo_class", "")
            local level = ply:GetNW2Int("wo_level", 1)
            local detailsText = ""

            if raceName ~= "" or className ~= "" then
                detailsText = "  ·  " .. raceName .. (className ~= "" and (" / " .. className) or "")
            end

            row.Paint = function(_, w, h)
                WO.UI.DrawPanelOutlined(0, 0, w, h, WO.UI.Colors.panel,
                    WO.UI.Colors.border)
                draw.SimpleText(name .. detailsText, "WO.Body", 14, h / 2,
                    WO.UI.Colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(WO.Lang:Get("character.level") .. " " .. level,
                    "WO.Small", w - 118, h / 2, WO.UI.Colors.textDim,
                    TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                draw.SimpleText(tostring(ply:Ping()) .. " ms", "WO.Small", w - 18,
                    h / 2, WO.UI.Colors.textDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end
        end
    end

    if #allPlayers == 0 then
        local empty = WO.UI.Label(playerList, WO.Lang:Get("menu.no_players"),
            "WO.Body", WO.UI.Colors.textDim)
        empty:Dock(TOP)
        empty:DockMargin(2, 6, 0, 0)
        empty:SetTall(34)
    end
end

local function BuildPage(page)
    if not IsValid(menuFrame) or not IsValid(menuFrame.content) then return end

    currentPage = page or DefaultPage()
    menuFrame.content:Clear()

    if currentPage == "characters" then
        BuildCharactersPage(menuFrame.content)
    else
        BuildOverviewPage(menuFrame.content)
    end

    for id, button in pairs(menuFrame.navButtons or {}) do
        if IsValid(button) then
            button:SetAccent(id == currentPage)
            button:SetEnabled(not button.characterOnly or HasLocalCharacter())
        end
    end
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

        draw.SimpleText(WO.Lang:Get("menu.title"), "WO.Title", 28, 27,
            WO.UI.Colors.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(WO.Lang:Get("menu.fullscreen_subtitle"), "WO.Small", 30, 56,
            WO.UI.Colors.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        local char = LocalCharacter()

        if char then
            local level = (WO.Leveling.ClientData and WO.Leveling.ClientData.level) or char.level or 1
            draw.SimpleText(char:GetFullName() .. "  ·  " .. WO.Lang:Get("character.level") .. " " .. level,
                "WO.Body", w - 84, 39, WO.UI.Colors.text,
                TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        else
            draw.SimpleText(WO.Lang:Get("menu.character_none"), "WO.Body", w - 84, 39,
                WO.UI.Colors.textDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
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
        { id = "sheet", text = WO.Lang:Get("menu.sheet"), characterOnly = true },
        { id = "quests", text = WO.Lang:Get("menu.quests"), characterOnly = true },
    }

    local navY = 24

    for _, item in ipairs(navItems) do
        local entry = item
        local button = WO.UI.Button(sidebar, entry.text, function()
            if entry.characterOnly and not HasLocalCharacter() then
                WO.Notify.Show("info", WO.Lang:Get("menu.no_character"))
                return
            end

            if entry.id == "overview" or entry.id == "characters" then
                BuildPage(entry.id)
                return
            end

            WO.MenuUI.Close()

            if entry.id == "inventory" and WO.InventoryUI and WO.InventoryUI.Open then
                WO.InventoryUI.Open()
            elseif entry.id == "sheet" and WO.CharacterUI and WO.CharacterUI.OpenSheet then
                WO.CharacterUI.OpenSheet()
            elseif entry.id == "quests" and WO.Quests and WO.Quests.OpenLog then
                WO.Quests.OpenLog()
            end
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
        draw.DrawText(text, "WO.Small", 2, 12, WO.UI.Colors.textDim, TEXT_ALIGN_LEFT)
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
            local ply = LocalPlayer()

            -- Не закрываем обязательное меню персонажа в лимбо.
            if not (IsValid(ply) and not ply:HasCharacter() and currentPage == "characters") then
                WO.MenuUI.Close()
            end
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

local function ActivatePage(page)
    if page == "overview" or page == "characters" then
        BuildPage(page)
    elseif page == "inventory" then
        if not HasLocalCharacter() then return end
        WO.MenuUI.Close()
        if WO.InventoryUI and WO.InventoryUI.Open then WO.InventoryUI.Open() end
    elseif page == "sheet" then
        if not HasLocalCharacter() then return end
        WO.MenuUI.Close()
        if WO.CharacterUI and WO.CharacterUI.OpenSheet then WO.CharacterUI.OpenSheet() end
    elseif page == "quests" then
        if not HasLocalCharacter() then return end
        WO.MenuUI.Close()
        if WO.Quests and WO.Quests.OpenLog then WO.Quests.OpenLog() end
    end
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

function GM:ScoreboardShow()
    if WO.MenuUI.IsOpen() then
        openedByScoreboardKey = false
    else
        WO.MenuUI.Show(DefaultPage(), true)
    end

    return true
end

function GM:ScoreboardHide()
    if openedByScoreboardKey then
        WO.MenuUI.Close()
    end

    openedByScoreboardKey = false
    return true
end
