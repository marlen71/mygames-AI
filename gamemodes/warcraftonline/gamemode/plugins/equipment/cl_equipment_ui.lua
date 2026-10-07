--[[
    Warcraft Online — UI экипировки (client).
    Независимая панель со всеми configured equipment slots.
]]

WO.EquipmentUI = WO.EquipmentUI or {}

local nextPanelId = 0

function WO.EquipmentUI.CreatePanel(parent, options)
    options = options or {}

    local panel = vgui.Create("DPanel", parent)
    local panelWidth = math.max(1, tonumber(options.width) or 300)
    local panelHeight = math.max(1, tonumber(options.height) or 500)
    local topInset = math.max(38, tonumber(options.topInset) or 42)

    panel:SetPos(tonumber(options.x) or 0, tonumber(options.y) or 0)
    panel:SetSize(panelWidth, panelHeight)
    panel:SetPaintBackground(false)

    panel.Paint = function(_, w, h)
        WO.UI.DrawPanelOutlined(0, 0, w, h, WO.UI.Colors.panel, WO.UI.Colors.border)
        WO.UI.DrawTextFit(WO.Lang:Get("equipment.title"), "WO.Subtitle",
            14, 20, WO.UI.Colors.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, w - 28, 30)
    end

    local slots = {}
    local slotDefs = WO.Config.EquipSlots or {}
    local columns = panelWidth < 360 and 1 or 2
    local rowCount = math.max(1, math.ceil(#slotDefs / columns))
    local padding = 10
    local columnGap = 8
    local columnWidth = math.floor((panelWidth - padding * 2 - columnGap * (columns - 1)) / columns)
    local availableHeight = math.max(0, panelHeight - topInset - 8)
    local rowHeight = math.floor(availableHeight / rowCount)
    rowHeight = math.max(20, math.min(38, rowHeight))
    local slotSize = math.max(18, math.min(34, rowHeight - 2))

    for index, slotDef in ipairs(slotDefs) do
        local column = math.floor((index - 1) / rowCount)
        local row = (index - 1) % rowCount
        local rowPanel = vgui.Create("DPanel", panel)
        rowPanel:SetPos(padding + column * (columnWidth + columnGap), topInset + row * rowHeight)
        rowPanel:SetSize(columnWidth, rowHeight - 2)
        rowPanel:SetPaintBackground(false)

        local slot = vgui.Create("WO_ItemSlot", rowPanel)
        slot:SetPos(math.max(0, columnWidth - slotSize), math.floor((rowHeight - slotSize) / 2))
        slot:SetSize(slotSize, slotSize)
        slot:SetDroppable(true)
        slot.slotId = slotDef.id
        slot.slotColor = WO.UI.Colors.panelDark

        rowPanel.Paint = function(_, w, h)
            local labelWidth = math.max(0, w - slotSize - 8)
            WO.UI.DrawTextFit(WO.Lang:Get(slotDef.nameKey), "WO.Tiny",
                labelWidth, h / 2, WO.UI.Colors.textDim,
                TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, labelWidth, h - 2)
        end

        slot.CanDropItem = function(_, drag)
            return drag ~= nil and drag.uid ~= nil and
                not (IsValid(drag.source) and drag.source.slotId ~= nil)
        end

        slot.OnItemDropped = function(_, drag)
            WO.Net.SendToServer("Equipment.Equip", drag.uid)
        end

        slot.OnContextMenu = function(selfSlot, item)
            if not item then return end

            local menu = DermaMenu()
            menu:AddOption(WO.Lang:Get("inventory.unequip"), function()
                WO.Net.SendToServer("Equipment.Unequip", selfSlot.slotId)
            end)
            menu:Open()
        end

        slots[#slots + 1] = slot
    end

    local function Refresh()
        for _, slot in ipairs(slots) do
            if IsValid(slot) then
                local item = WO.Equipment.ClientData and WO.Equipment.ClientData[slot.slotId] or nil
                slot:SetItem(item)
            end
        end
    end

    Refresh()

    nextPanelId = nextPanelId + 1
    local hookId = "wo_equip_ui_" .. tostring(nextPanelId)
    WO.Hook.Add("EquipmentSynced", hookId, function()
        if IsValid(panel) then
            Refresh()
        end
    end)

    panel.OnRemove = function()
        WO.Hook.Remove("EquipmentSynced", hookId)
    end

    panel.RefreshEquipment = Refresh

    return panel
end

WO.Hook.Add("CharacterMenuOpening", "equipment_client_clear", function()
    WO.Equipment.ClientData = {}
end)
