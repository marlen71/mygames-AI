--[[
    Warcraft Online — UI экипировки (client).
    Панель слотов (используется в окне инвентаря и персонажа).
]]

WO.EquipmentUI = WO.EquipmentUI or {}

--[[
    Создаёт панель экипировки (список слотов).

    @param parent Panel
    @return Panel
]]
function WO.EquipmentUI.CreatePanel(parent)
    local panel = vgui.Create("DPanel", parent)

    panel:SetSize(255, 400)
    panel:SetPaintBackground(false)

    panel.Paint = function(_, w, h)
        draw.SimpleText(WO.Lang:Get("equipment.title"), "WO.Subtitle", w / 2, 8, WO.UI.Colors.accent, TEXT_ALIGN_CENTER)
    end

    local slots = {}

    local function BuildSlots()
        for _, slot in ipairs(slots) do
            if IsValid(slot) then
                slot:Remove()
            end
        end

        slots = {}

        local y = 30

        for _, slotDef in ipairs(WO.Config.EquipSlots or {}) do
            local row = vgui.Create("DPanel", panel)

            row:SetPos(0, y)
            row:SetSize(255, 34)
            row:SetPaintBackground(false)

            row.Paint = function(_, w, h)
                draw.SimpleText(WO.Lang:Get(slotDef.nameKey), "WO.Small", 78, h / 2, WO.UI.Colors.textDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end

            local slot = vgui.Create("WO_ItemSlot", row)

            slot:SetPos(88, 1)
            slot:SetSize(32, 32)
            slot:SetDroppable(true)
            slot.slotId = slotDef.id

            -- Drop из инвентаря → экипировать
            slot.CanDropItem = function()
                return true
            end

            slot.OnItemDropped = function(_, drag)
                WO.Net.SendToServer("Equipment.Equip", drag.uid)
            end

            -- Правый клик → снять
            slot.OnContextMenu = function(selfSlot, item)
                if not item then return end

                local menu = DermaMenu()

                menu:AddOption(WO.Lang:Get("inventory.unequip"), function()
                    WO.Net.SendToServer("Equipment.Unequip", selfSlot.slotId)
                end)

                menu:Open()
            end

            slots[#slots + 1] = slot

            y = y + 27
        end
    end

    local function Refresh()
        for _, slot in ipairs(slots) do
            if IsValid(slot) then
                local item = WO.Equipment.ClientData and WO.Equipment.ClientData[slot.slotId] or nil

                slot:SetItem(item)
            end
        end
    end

    BuildSlots()
    Refresh()

    -- Обновления
    local hookId = "wo_equip_ui_" .. panel:EntIndex()

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
