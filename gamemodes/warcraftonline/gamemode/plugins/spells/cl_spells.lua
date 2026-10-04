--[[ Warcraft Online — окно книги заклинаний на ПКМ. ]]

local bookFrame
local spellOrder = {
    "healing_wave", "firebolt", "air_burst", "water_bolt",
    "earth_shard", "lightning_strike", "frost_lance",
}

local function CloseBook()
    if IsValid(bookFrame) then bookFrame:Remove() end
    bookFrame = nil
end

WO.Spells.CloseBook = CloseBook

local function CurrentBook()
    return WO.Spells.LocalBook or { ranks = {}, selected = "", points = 0, level = 1 }
end

local function RefreshBookProgress(data)
    if not IsValid(bookFrame) then return end

    local book = CurrentBook()
    local char = WO.Character and WO.Character.GetLocal and WO.Character.GetLocal()
    data = istable(data) and data or (WO.Leveling and WO.Leveling.ClientData) or {}
    local level = math.max(1, tonumber(data.level) or tonumber(book.level) or
        tonumber(char and char.level) or 1)
    local needed = math.max(1, tonumber(data.needed) or WO.Config.GetXPForLevel(level))
    local experience = math.max(0, tonumber(data.experience) or tonumber(char and char.experience) or 0)

    if IsValid(bookFrame.pointsLabel) then
        bookFrame.pointsLabel:SetDisplayText("Очки заклинаний: " .. tostring(book.points or 0) ..
            "    Уровень: " .. tostring(level))
    end

    if IsValid(bookFrame.xpLabel) then
        bookFrame.xpLabel:SetDisplayText(WO.Lang:Get("xp.compact", experience, needed,
            math.max(0, needed - experience)))
    end

    if IsValid(bookFrame.xpBar) then
        bookFrame.xpBar:SetFraction(experience / needed)
    end
end

local function RebuildBook()
    if not IsValid(bookFrame) or not IsValid(bookFrame.spellList) then return end

    local scroll = bookFrame.spellList
    scroll:Clear()

    local book = CurrentBook()
    RefreshBookProgress()

    for _, spellId in ipairs(spellOrder) do
        local spell = WO.Spells.Get(spellId)

        if spell then
            local rank = math.max(0, math.floor(tonumber(book.ranks and book.ranks[spellId]) or 0))
            local selected = book.selected == spellId
            local row = vgui.Create("DPanel", scroll)

            row:Dock(TOP)
            row:DockMargin(0, 0, 0, 8)
            row:SetTall(82)
            row.Paint = function(_, w, h)
                WO.UI.DrawPanelOutlined(0, 0, w, h,
                    selected and WO.UI.Colors.panelLight or WO.UI.Colors.panel,
                    selected and WO.UI.Colors.accent or WO.UI.Colors.border,
                    WO.UI.Metrics.radiusSmall)
            end

            local title = WO.UI.Label(row,
                spell.name .. "  ·  " .. spell.element .. "  ·  " .. rank .. "/" .. spell.maxRank ..
                    (selected and "  ·  выбрано" or ""),
                "WO.Subtitle", selected and WO.UI.Colors.accent or WO.UI.Colors.text)
            title:SetPos(12, 8)
            title:SetSize(420, 22)

            local description = WO.UI.Label(row, spell.description or "", "WO.Small", WO.UI.Colors.textDim)
            description:SetPos(12, 34)
            description:SetSize(430, 36)

            if rank > 0 then
                local selectButton = WO.UI.Button(row, selected and "Выбрано" or "Выбрать", function()
                    WO.Net.SendToServer("Spell.Select", spellId)
                end)
                selectButton:SetPos(455, 12)
                selectButton:SetSize(110, 28)
                selectButton:SetEnabled(not selected)
            end

            if rank < spell.maxRank then
                local targetRank = rank + 1
                local requiredLevel = (spell.requiredLevel or 1) + targetRank - 1
                local status = (book.level or 1) < requiredLevel and
                    ("Нужен ур. " .. requiredLevel) or (rank == 0 and "Свиток изучения" or
                    ("Свиток ранга " .. targetRank))
                local scrollLabel = WO.UI.Label(row, status, "WO.Small", WO.UI.Colors.warn)
                scrollLabel:SetPos(455, 48)
                scrollLabel:SetSize(130, 26)
            end
        end
    end
end

function WO.Spells.OpenBook()
    CloseBook()

    local sw, sh = ScrW(), ScrH()
    local width, height = math.min(620, sw - 32), math.min(620, sh - 32)
    bookFrame = vgui.Create("DFrame")
    bookFrame:SetSize(width, height)
    bookFrame:SetPos((sw - width) / 2, (sh - height) / 2)
    bookFrame:SetTitle("")
    bookFrame:ShowCloseButton(true)
    bookFrame:MakePopup()
    bookFrame.Paint = function(_, w, h)
        WO.UI.DrawPanelOutlined(0, 0, w, h, WO.UI.Colors.bg, WO.UI.Colors.accent)
        WO.UI.DrawTitleBar(0, 0, w, 38, "Книга заклинаний")
    end

    bookFrame.pointsLabel = WO.UI.Label(bookFrame, "", "WO.Subtitle", WO.UI.Colors.accent)
    bookFrame.pointsLabel:SetPos(18, 45)
    bookFrame.pointsLabel:SetSize(width - 36, 22)

    bookFrame.xpLabel = WO.UI.Label(bookFrame, "", "WO.Tiny", WO.UI.Colors.textDim)
    bookFrame.xpLabel:SetPos(18, 68)
    bookFrame.xpLabel:SetSize(width - 36, 16)

    bookFrame.xpBar = WO.UI.ProgressBar(bookFrame, WO.UI.Colors.xp, WO.UI.Colors.xpBg)
    bookFrame.xpBar:SetPos(18, 86)
    bookFrame.xpBar:SetSize(width - 36, 6)

    bookFrame.spellList = WO.UI.Scroll(bookFrame)
    bookFrame.spellList:SetPos(16, 99)
    bookFrame.spellList:SetSize(width - 32, height - 115)

    RebuildBook()

    if not WO.Spells.LocalBook then
        WO.Net.SendToServer("Spell.SyncRequest")
    end
end

WO.Hook.Add("SpellbookSynced", "spell_ui_refresh", function()
    RebuildBook()
end)

WO.Hook.Add("LevelingSynced", "spell_ui_xp_progress", RefreshBookProgress)

WO.Hook.Add("CharacterMenuOpening", "spell_ui_close", CloseBook)

hook.Add("Think", "wo_spell_book_autoclose", function()
    if not IsValid(bookFrame) then return end

    local ply = LocalPlayer()
    local weapon = IsValid(ply) and ply:GetActiveWeapon()

    if not IsValid(ply) or not ply:HasCharacter() or not IsValid(weapon) or
        weapon:GetClass() ~= WO.Spells.WeaponClass then
        CloseBook()
    end
end)
