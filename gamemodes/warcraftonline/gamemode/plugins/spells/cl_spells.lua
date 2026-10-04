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

local function RebuildBook()
    if not IsValid(bookFrame) or not IsValid(bookFrame.spellList) then return end

    local scroll = bookFrame.spellList
    scroll:Clear()

    local book = CurrentBook()
    local pointsLabel = bookFrame.pointsLabel

    if IsValid(pointsLabel) then
        pointsLabel:SetDisplayText("Очки заклинаний: " .. tostring(book.points or 0) ..
            "    Уровень: " .. tostring(book.level or 1))
    end

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
                local requiredLevel = (spell.requiredLevel or 1) + rank
                local canTrain = (book.points or 0) > 0 and (book.level or 1) >= requiredLevel
                local label = rank == 0 and "Изучить" or "Улучшить"
                local trainButton = WO.UI.Button(row, label, function()
                    WO.Net.SendToServer("Spell.Learn", spellId)
                end)
                trainButton:SetPos(455, 47)
                trainButton:SetSize(110, 28)
                trainButton:SetEnabled(canTrain)
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
    bookFrame.pointsLabel:SetPos(18, 48)
    bookFrame.pointsLabel:SetSize(width - 36, 24)

    bookFrame.spellList = WO.UI.Scroll(bookFrame)
    bookFrame.spellList:SetPos(16, 80)
    bookFrame.spellList:SetSize(width - 32, height - 96)

    RebuildBook()

    if not WO.Spells.LocalBook then
        WO.Net.SendToServer("Spell.SyncRequest")
    end
end

WO.Hook.Add("SpellbookSynced", "spell_ui_refresh", function()
    RebuildBook()
end)

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
