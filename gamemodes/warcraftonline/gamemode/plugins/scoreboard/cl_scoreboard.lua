--[[
    Warcraft Online — единый TAB menu/scoreboard (client).

    UI-компонент не меняет серверные данные: создание/выбор/выход персонажа,
    инвентарь, лист персонажа и журнал открываются через их публичные API.
]]

WO.MenuUI = WO.MenuUI or {}

local menuFrame = nil
local currentPage = nil
local openedByScoreboardKey = false
local sidebarWidth = 218

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

local function AddPageHeader(parent, title, subtitle)
    local header = vgui.Create("DPanel", parent)
    header:Dock(TOP)
    header:SetTall(subtitle and 76 or 54)
    header:DockMargin(0, 0, 0, 12)
    header:SetPaintBackground(false)

    header.Paint = function(_, w, h)
        draw.SimpleText(title, "WO.Title", 0, 4, WO.UI.Colors.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        if subtitle then
            draw.SimpleText(subtitle, "WO.Small", 2, 43, WO.UI.Colors.textDim,
                TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
    end

    return header
end

local function AddActionButton(parent, text, callback, x, y, w, h, accent)
    local button = WO.UI.Button(parent, text, callback)
    button:SetPos(x, y)
    button:SetSize(w, h)
    button:SetAccent(accent == true)

    return button
end

local function BuildCharactersPage(parent)
    local char = LocalCharacter()
    local saved = WO.Character and WO.Character.GetList and WO.Character.GetList() or {}

    AddPageHeader(parent, WO.Lang:Get("menu.characters"),
        WO.Lang:Get("menu.characters_subtitle"))

    if not char then
        local info = WO.UI.Label(parent, WO.Lang:Get("menu.no_character"),
            "WO.Body", WO.UI.Colors.textDim)
        info:Dock(TOP)
        info:DockMargin(0, 4, 0, 18)
        info:SetTall(48)

        local contentWidth = PanelWidth(parent, 800)
        local buttonWidth = math.min(480, math.max(240, contentWidth * 0.56))
        local buttonX = math.floor((contentWidth - buttonWidth) / 2)

        local createButton = WO.UI.Button(parent, WO.Lang:Get("character.menu.create"), function()
            WO.CharacterUI.OpenCreate()
        end)
        createButton:SetPos(buttonX, 150)
        createButton:SetSize(buttonWidth, 48)
        createButton:SetAccent(true)
        createButton:SetFont("WO.MenuButton")

        local loadButton = WO.UI.Button(parent, WO.Lang:Get("character.menu.load"), function()
            if #saved > 0 then
                WO.CharacterUI.OpenSelect()
            else
                WO.Notify.Show("info", WO.Lang:Get("character.no_saved_characters"))
            end
        end)
        loadButton:SetPos(buttonX, 210)
        loadButton:SetSize(buttonWidth, 48)
        loadButton:SetEnabled(#saved > 0)
        loadButton:SetFont("WO.MenuButton")

        local savedText = #saved > 0 and
            (WO.Lang:Get("menu.saved_characters") .. ": " .. #saved) or
            WO.Lang:Get("character.no_saved_characters")
        local savedLabel = WO.UI.Label(parent, savedText, "WO.Small", WO.UI.Colors.textDim)
        savedLabel:SetPos(buttonX, 268)
        savedLabel:SetSize(buttonWidth, 24)

        local exitButton = WO.UI.Button(parent, WO.Lang:Get("character.menu.exit"), function()
            WO.MenuUI.Close()
            RunConsoleCommand("disconnect")
        end)
        exitButton:SetPos(buttonX, 318)
        exitButton:SetSize(buttonWidth, 42)
        exitButton:SetFont("WO.MenuButton")

        return
    end

    local race = WO.Races.Get(char.race)
    local class = WO.Classes.Get(char.class)
    local level = (WO.Leveling.ClientData and WO.Leveling.ClientData.level) or char.level or 1
    local summary = vgui.Create("DPanel", parent)
    summary:Dock(TOP)
    summary:SetTall(92)
    summary:DockMargin(0, 0, 0, 14)

    summary.Paint = function(_, w, h)
        WO.UI.DrawPanelOutlined(0, 0, w, h, WO.UI.Colors.panel, WO.UI.Colors.border)
        draw.SimpleText(char:GetFullName(), "WO.Subtitle", 18, 18,
            WO.UI.Colors.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(WO.Lang:Get("character.level") .. " " .. level .. "  ·  " ..
            (race and race.name or char.race) .. "  ·  " ..
            (class and class.name or char.class), "WO.Small", 18, 52,
            WO.UI.Colors.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    local logoutButton = WO.UI.Button(parent, WO.Lang:Get("character.logout"), function()
        WO.MenuUI.Close()
        WO.Character.RequestLogout()
    end)
    logoutButton:Dock(TOP)
    logoutButton:DockMargin(0, 0, 0, 8)
    logoutButton:SetTall(40)
    logoutButton:SetAccent(true)

    local selectButton = WO.UI.Button(parent, WO.Lang:Get("character.menu.load"), function()
        WO.Notify.Show("info", WO.Lang:Get("menu.logout_before_switch"))
    end)
    selectButton:Dock(TOP)
    selectButton:SetTall(36)
    selectButton:SetEnabled(false)
end

local function BuildOverviewPage(parent)
    local char = LocalCharacter()
    local subtitle = char and WO.Lang:Get("menu.overview_subtitle") or WO.Lang:Get("menu.no_character")

    AddPageHeader(parent, WO.Lang:Get("menu.overview"), subtitle)

    local summary = vgui.Create("DPanel", parent)
    summary:Dock(TOP)
    summary:SetTall(76)
    summary:DockMargin(0, 0, 0, 12)

    summary.Paint = function(_, w, h)
        WO.UI.DrawPanelOutlined(0, 0, w, h, WO.UI.Colors.panel, WO.UI.Colors.border)

        if char then
            local level = (WO.Leveling.ClientData and WO.Leveling.ClientData.level) or char.level or 1
            draw.SimpleText(char:GetFullName(), "WO.Subtitle", 16, 14,
                WO.UI.Colors.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText(WO.Lang:Get("character.level") .. " " .. level ..
                "  ·  " .. WO.Lang:Get("menu.server_players") .. ": " .. #player.GetAll(),
                "WO.Small", 16, 45, WO.UI.Colors.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        else
            draw.SimpleText(WO.Lang:Get("menu.no_character"), "WO.Body", 16, h / 2,
                WO.UI.Colors.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end

    local actionRow = vgui.Create("DPanel", parent)
    actionRow:Dock(TOP)
    actionRow:SetTall(42)
    actionRow:DockMargin(0, 0, 0, 14)
    actionRow:SetPaintBackground(false)

    local actionButtons = {}

    if char then
        actionButtons = {
            { text = WO.Lang:Get("menu.inventory"), id = "inventory" },
            { text = WO.Lang:Get("menu.sheet"), id = "sheet" },
            { text = WO.Lang:Get("menu.quests"), id = "quests" },
        }
    else
        actionButtons = {
            { text = WO.Lang:Get("character.menu.create"), id = "create" },
            { text = WO.Lang:Get("character.menu.load"), id = "characters" },
        }
    end

    local gap = 8
    local contentWidth = PanelWidth(parent, 800)
    local buttonWidth = math.floor((contentWidth - gap * (#actionButtons - 1)) / #actionButtons)

    for i, action in ipairs(actionButtons) do
        local entry = action
        local button = WO.UI.Button(actionRow, entry.text, function()
            if entry.id == "create" then
                WO.CharacterUI.OpenCreate()
            elseif entry.id == "inventory" or entry.id == "sheet" or entry.id == "quests" then
                WO.MenuUI.Close()

                if entry.id == "inventory" and WO.InventoryUI then
                    WO.InventoryUI.Open()
                elseif entry.id == "sheet" and WO.CharacterUI.OpenSheet then
                    WO.CharacterUI.OpenSheet()
                elseif entry.id == "quests" and WO.Quests and WO.Quests.OpenLog then
                    WO.Quests.OpenLog()
                end
            else
                WO.MenuUI.Show("characters")
            end
        end)
        button:SetPos((i - 1) * (buttonWidth + gap), 0)
        button:SetSize(buttonWidth, 40)
        button:SetAccent(i == 1)
    end

    local playersTitle = WO.UI.Label(parent, WO.Lang:Get("menu.players"),
        "WO.Subtitle", WO.UI.Colors.accent)
    playersTitle:Dock(TOP)
    playersTitle:DockMargin(0, 0, 0, 8)
    playersTitle:SetTall(24)

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
            row:SetTall(46)
            row:DockMargin(0, 0, 0, 5)

            local name = ply:GetNW2String("wo_name", ply:Nick())
            local race = ply:GetNW2String("wo_race", "")
            local class = ply:GetNW2String("wo_class", "")
            local level = ply:GetNW2Int("wo_level", 1)
            local details = ""

            if race ~= "" or class ~= "" then
                details = "  ·  " .. race .. (class ~= "" and (" / " .. class) or "")
            end

            row.Paint = function(_, w, h)
                WO.UI.DrawPanelOutlined(0, 0, w, h, WO.UI.Colors.panel, WO.UI.Colors.border)
                draw.SimpleText(name .. details, "WO.Body", 14, h / 2,
                    WO.UI.Colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(WO.Lang:Get("character.level") .. " " .. level,
                    "WO.Small", w - 110, h / 2, WO.UI.Colors.textDim,
                    TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                draw.SimpleText(tostring(ply:Ping()) .. " ms", "WO.Small", w - 18, h / 2,
                    WO.UI.Colors.textDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end
        end
    end

    if #allPlayers == 0 then
        local empty = WO.UI.Label(playerList, WO.Lang:Get("menu.no_players"),
            "WO.Small", WO.UI.Colors.textDim)
        empty:Dock(TOP)
        empty:SetTall(28)
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
        end
    end
end

function WO.MenuUI.Show(page, fromScoreboardKey)
    if not IsValid(menuFrame) then
        local width = math.min(1440, math.max(640, ScrW() - 48))
        local height = math.min(850, math.max(480, ScrH() - 48))
        width = math.min(width, ScrW() - 16)
        height = math.min(height, ScrH() - 16)

        menuFrame = vgui.Create("DFrame")
        menuFrame:SetSize(width, height)
        menuFrame:Center()
        menuFrame:SetTitle("")
        menuFrame:ShowCloseButton(false)
        menuFrame:SetDraggable(false)
        menuFrame:MakePopup()

        menuFrame.Paint = function(_, w, h)
            draw.RoundedBox(8, 0, 0, w, h, WO.UI.Colors.bg)
            surface.SetDrawColor(WO.UI.Colors.borderLight)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            draw.SimpleText(WO.Lang:Get("menu.title"), "WO.Title", 24, 19,
                WO.UI.Colors.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        local sidebar = vgui.Create("DPanel", menuFrame)
        sidebar:SetPos(0, 48)
        sidebar:SetSize(sidebarWidth, height - 48)
        sidebar.Paint = function(_, w, h)
            draw.RoundedBoxEx(8, 0, 0, w, h, WO.UI.Colors.panelDark,
                false, false, true, false)
            surface.SetDrawColor(WO.UI.Colors.border)
            surface.DrawRect(w - 1, 0, 1, h)
        end

        menuFrame.navButtons = {}

        local navItems = {
            { id = "overview", text = WO.Lang:Get("menu.overview") },
            { id = "characters", text = WO.Lang:Get("menu.characters") },
            { id = "inventory", text = WO.Lang:Get("menu.inventory"), characterOnly = true },
            { id = "sheet", text = WO.Lang:Get("menu.sheet"), characterOnly = true },
            { id = "quests", text = WO.Lang:Get("menu.quests"), characterOnly = true },
        }

        local navY = 18

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

                if entry.id == "inventory" then
                    if WO.InventoryUI and WO.InventoryUI.Open then
                        WO.InventoryUI.Open()
                    end
                elseif entry.id == "sheet" then
                    if WO.CharacterUI and WO.CharacterUI.OpenSheet then
                        WO.CharacterUI.OpenSheet()
                    end
                elseif entry.id == "quests" then
                    if WO.Quests and WO.Quests.OpenLog then
                        WO.Quests.OpenLog()
                    end
                end
            end)

            button:SetPos(12, navY)
            button:SetSize(sidebarWidth - 24, 38)
            button:SetEnabled(not entry.characterOnly or HasLocalCharacter())
            menuFrame.navButtons[entry.id] = button
            navY = navY + 46
        end

        local localChar = LocalCharacter()
        local footer = vgui.Create("DPanel", sidebar)
        footer:SetPos(12, height - 112)
        footer:SetSize(sidebarWidth - 24, 72)
        footer:SetPaintBackground(false)
        footer.Paint = function(_, w, h)
            surface.SetDrawColor(WO.UI.Colors.border)
            surface.DrawRect(0, 0, w, 1)

            if localChar then
                draw.DrawText(localChar:GetFullName(), "WO.Tiny", 2, 11,
                    WO.UI.Colors.textDim, TEXT_ALIGN_LEFT)
            else
                draw.DrawText(WO.Lang:Get("menu.character_none"), "WO.Tiny", 2, 11,
                    WO.UI.Colors.textDim, TEXT_ALIGN_LEFT)
            end
        end

        local exitButton = WO.UI.Button(sidebar, WO.Lang:Get("menu.exit"), function()
            WO.MenuUI.Close()
            RunConsoleCommand("disconnect")
        end)
        exitButton:SetPos(12, height - 48)
        exitButton:SetSize(sidebarWidth - 24, 34)

        local closeButton = WO.UI.Button(menuFrame, "✕", function()
            WO.MenuUI.Close()
        end)
        closeButton:SetPos(width - 48, 8)
        closeButton:SetSize(34, 32)

        local content = vgui.Create("DPanel", menuFrame)
        content:SetPos(sidebarWidth + 20, 62)
        content:SetSize(width - sidebarWidth - 40, height - 82)
        content:SetPaintBackground(false)
        menuFrame.content = content

        menuFrame.OnKeyCodePressed = function(_, key)
            if key == KEY_ESCAPE then
                local ply = LocalPlayer()

                -- Не оставляем игрока без меню персонажа в лимбо.
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
