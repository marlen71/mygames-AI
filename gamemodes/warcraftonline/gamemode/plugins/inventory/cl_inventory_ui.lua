--[[
    Warcraft Online — UI инвентаря (client).

    Окно делится на две независимые панели:
      1) предметы, ресурсы и сетка инвентаря;
      2) 3D-модель персонажа и отдельные слоты экипировки.

    Содержимое и все операции остаются серверно-авторитетными.
]]

WO.InventoryUI = WO.InventoryUI or {}

local frame = nil

---------------------------------------------------------------------------
-- Вспомогательные функции
---------------------------------------------------------------------------

local function GetItems()
    return (WO.Inventory.ClientData and WO.Inventory.ClientData.items) or {}
end

local function GetItemDefinition(item)
    return item and WO.Items.Get(item.class) or nil
end

local function GetItemSize(item)
    local def = GetItemDefinition(item)
    local size = def and def.size or nil

    return math.max(1, math.floor((size and size.w) or 1)),
        math.max(1, math.floor((size and size.h) or 1))
end

---------------------------------------------------------------------------
-- Диалог разделения стака
---------------------------------------------------------------------------

local function OpenSplitDialog(item)
    if not item or (item.amount or 1) <= 1 then return end

    local dialog = WO.UI.Window(WO.Lang:Get("inventory.split"), 280, 140)
    local slider = vgui.Create("DNumSlider", dialog)
    slider:SetPos(20, 55)
    slider:SetSize(240, 30)
    slider:SetText("")
    slider:SetMin(1)
    slider:SetMax((item.amount or 1) - 1)
    slider:SetDecimals(0)
    slider:SetValue(math.floor((item.amount or 1) / 2))

    local confirm = WO.UI.Button(dialog, WO.Lang:Get("ui.confirm"), function()
        local amount = math.floor(slider:GetValue())

        if amount >= 1 and amount < (item.amount or 1) then
            WO.Net.SendToServer("Inventory.Split", item.uid, amount)
        end

        dialog:Close()
    end)
    confirm:SetPos(70, 95)
    confirm:SetSize(140, 30)
end

---------------------------------------------------------------------------
-- Контекстное меню предмета
---------------------------------------------------------------------------

local function OpenItemMenu(_, item)
    if not item then return end

    local def = GetItemDefinition(item)

    if not def then return end

    local menu = DermaMenu()

    if def.equipment or def.consumable then
        local actionKey = def.equipment and "inventory.equip" or "inventory.use"
        menu:AddOption(WO.Lang:Get(actionKey), function()
            WO.Net.SendToServer("Inventory.Use", item.uid)
        end)
    end

    if def.stackable and (item.amount or 1) > 1 then
        menu:AddOption(WO.Lang:Get("inventory.split"), function()
            OpenSplitDialog(item)
        end)
    end

    menu:AddOption(WO.Lang:Get("inventory.drop"), function()
        WO.Net.SendToServer("Inventory.Drop", item.uid, 0)
    end)

    menu:AddSpacer()

    local destroy = menu:AddOption(WO.Lang:Get("inventory.destroy"), function()
        WO.Net.SendToServer("Inventory.Destroy", item.uid)
    end)
    destroy:SetTextColor(WO.UI.Colors.bad)
    menu:Open()
end

---------------------------------------------------------------------------
-- Панель ресурсов
---------------------------------------------------------------------------

local function CreateResourcesPanel(parent)
    local panel = vgui.Create("DPanel", parent)
    panel:SetPos(12, 48)
    panel:SetSize(parent:GetWide() - 24, 42)

    panel.Paint = function(_, w, h)
        WO.UI.DrawPanelOutlined(0, 0, w, h, WO.UI.Colors.panelDark, WO.UI.Colors.border)

        local money = WO.Currency.ClientAmount or 0
        local moneyText = WO.Currency.Format and WO.Currency.Format(money) or tostring(money)
        local data = WO.Inventory.ClientData
        local capacity = data and ((data.width or 0) * (data.height or 0)) or 0

        draw.SimpleText(WO.Lang:Get("currency.name") .. ": " .. moneyText,
            "WO.Small", 12, h / 2, WO.UI.Colors.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(WO.Lang:Get("inventory.items_count") .. ": " .. #GetItems() ..
            "  /  " .. capacity, "WO.Small", w - 12, h / 2,
            WO.UI.Colors.textDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end

    return panel
end

---------------------------------------------------------------------------
-- Сетка инвентаря
---------------------------------------------------------------------------

local function BuildGrid(parent)
    local data = WO.Inventory.ClientData

    if IsValid(parent.grid) then
        parent.grid:Remove()
    end

    parent.grid = nil
    parent.slots = {}
    parent.itemPanels = {}

    if not data then
        local empty = vgui.Create("DPanel", parent)
        empty:SetPos(12, 104)
        empty:SetSize(parent:GetWide() - 24, math.max(60, parent:GetTall() - 160))
        empty:SetPaintBackground(false)
        empty.Paint = function(_, w, h)
            draw.SimpleText(WO.Lang:Get("inventory.loading"), "WO.Small",
                w / 2, h / 2, WO.UI.Colors.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        parent.emptyState = empty
        return
    end

    if IsValid(parent.emptyState) then
        parent.emptyState:Remove()
        parent.emptyState = nil
    end

    local width = math.max(1, math.floor(tonumber(data.width) or WO.Config.InventoryWidth or 10))
    local height = math.max(1, math.floor(tonumber(data.height) or WO.Config.InventoryHeight or 6))
    local gap = WO.UI.Metrics.slotGap
    local padding = 12
    local maxSlot = WO.UI.Metrics.slotSize
    local slotSize = math.floor((parent:GetWide() - padding * 2 - (width + 1) * gap) / width)
    slotSize = math.max(20, math.min(maxSlot, slotSize))

    local gridWidth = width * slotSize + (width + 1) * gap
    local gridHeight = height * slotSize + (height + 1) * gap
    local grid = vgui.Create("DPanel", parent)
    grid:SetPos(math.floor((parent:GetWide() - gridWidth) / 2), 104)
    grid:SetSize(gridWidth, gridHeight)
    grid:SetPaintBackground(false)
    grid.Paint = function(_, w, h)
        WO.UI.DrawPanelOutlined(0, 0, w, h, WO.UI.Colors.panelDark, WO.UI.Colors.border)
    end

    parent.grid = grid
    parent.gridSlotSize = slotSize
    parent.gridGap = gap

    for y = 1, height do
        for x = 1, width do
            local slot = vgui.Create("WO_ItemSlot", grid)
            slot:SetPos(gap + (x - 1) * (slotSize + gap), gap + (y - 1) * (slotSize + gap))
            slot:SetSize(slotSize, slotSize)
            slot:SetDroppable(true)
            slot.gridX = x
            slot.gridY = y
            slot.gridPitch = slotSize + gap

            slot.CanDropItem = function(_, drag)
                return drag ~= nil and drag.uid ~= nil
            end

            slot.OnItemDropped = function(selfSlot, drag)
                local source = drag.source

                if IsValid(source) and source.slotId then
                    -- Снятие экипировки использует серверное авто-размещение,
                    -- которое само проверяет свободную площадь.
                    WO.Net.SendToServer("Equipment.Unequip", source.slotId)
                    return
                end

                local targetX = selfSlot.gridX - (drag.offsetX or 0)
                local targetY = selfSlot.gridY - (drag.offsetY or 0)

                if targetX < 1 or targetY < 1 then
                    WO.Notify.Show("error", WO.Lang:Get("inventory.invalid_drop_position"))
                    return
                end

                WO.Net.SendToServer("Inventory.Move", drag.uid, targetX, targetY)
            end

            slot.OnContextMenu = OpenItemMenu
            parent.slots[#parent.slots + 1] = slot
        end
    end

    local function RefreshItems()
        for _, slot in ipairs(parent.slots) do
            if IsValid(slot) then
                slot:SetItem(nil)
            end
        end

        for _, itemPanel in ipairs(parent.itemPanels) do
            if IsValid(itemPanel) then
                itemPanel:Remove()
            end
        end
        parent.itemPanels = {}

        local cellPitch = slotSize + gap

        for _, item in ipairs(GetItems()) do
            local itemWidth, itemHeight = GetItemSize(item)
            local x = math.floor(tonumber(item.x) or 0)
            local y = math.floor(tonumber(item.y) or 0)

            if x >= 1 and y >= 1 and x + itemWidth - 1 <= width and y + itemHeight - 1 <= height then
                local itemPanel = vgui.Create("WO_ItemSlot", grid)
                itemPanel:SetPos(gap + (x - 1) * cellPitch, gap + (y - 1) * cellPitch)
                itemPanel:SetSize(itemWidth * slotSize + (itemWidth - 1) * gap,
                    itemHeight * slotSize + (itemHeight - 1) * gap)
                itemPanel:SetItem(item)
                itemPanel:SetDroppable(false)
                itemPanel.gridPitch = cellPitch
                itemPanel.gridSlotSize = slotSize
                itemPanel.itemWidth = itemWidth
                itemPanel.itemHeight = itemHeight
                itemPanel:SetZPos(2)
                itemPanel.OnContextMenu = OpenItemMenu
                parent.itemPanels[#parent.itemPanels + 1] = itemPanel
            end
        end
    end

    RefreshItems()
    parent.RefreshItems = RefreshItems
end

---------------------------------------------------------------------------
-- Сборка окна
---------------------------------------------------------------------------

local function ClearDrag()
    if WO.UI.CancelDrag then
        WO.UI.CancelDrag()
    elseif WO.UI.Drag then
        if IsValid(WO.UI.Drag.ghost) then
            WO.UI.Drag.ghost:Remove()
        end
        WO.UI.Drag = nil
    end
end

local function BelongsTo(panel, ancestor)
    if not IsValid(panel) or not IsValid(ancestor) then return false end

    local current = panel

    while IsValid(current) do
        if current == ancestor then return true end
        current = current:GetParent()
    end

    return false
end

function WO.InventoryUI.Open()
    if IsValid(frame) then
        WO.InventoryUI.Close()
    end

    local char = WO.Character.GetLocal()

    if not char then
        WO.Notify.Show("info", WO.Lang:Get("menu.no_character"))
        return
    end

    WO.Net.SendToServer("Inventory.RequestSync")

    local frameWidth = math.min(1280, ScrW() - 24)
    local frameHeight = math.min(760, ScrH() - 24)
    frame = WO.UI.Window(WO.Lang:Get("inventory.title"), frameWidth, frameHeight)
    local thisFrame = frame

    local contentX = 14
    local contentY = 48
    local contentHeight = frameHeight - contentY - 14
    local gap = 14
    local contentWidth = frameWidth - contentX * 2
    local inventoryWidth = math.floor((contentWidth - gap) * 0.62)
    local equipmentWidth = contentWidth - gap - inventoryWidth

    local inventoryPanel = vgui.Create("DPanel", frame)
    inventoryPanel:SetPos(contentX, contentY)
    inventoryPanel:SetSize(inventoryWidth, contentHeight)
    inventoryPanel.Paint = function(_, w, h)
        WO.UI.DrawPanelOutlined(0, 0, w, h, WO.UI.Colors.panel, WO.UI.Colors.border)
        draw.SimpleText(WO.Lang:Get("inventory.title"), "WO.Subtitle",
            14, 22, WO.UI.Colors.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    CreateResourcesPanel(inventoryPanel)
    BuildGrid(inventoryPanel)

    local sortButton = WO.UI.Button(inventoryPanel, WO.Lang:Get("inventory.sort"), function()
        WO.Net.SendToServer("Inventory.Sort")
    end)
    sortButton:SetPos(12, contentHeight - 40)
    sortButton:SetSize(math.min(180, inventoryWidth - 24), 30)

    local equipmentX = contentX + inventoryWidth + gap
    local previewHeight = math.min(178, math.max(112, math.floor(equipmentWidth * 0.42)))
    local equipmentPanel = WO.EquipmentUI and WO.EquipmentUI.CreatePanel and
        WO.EquipmentUI.CreatePanel(frame, {
            x = equipmentX,
            y = contentY,
            width = equipmentWidth,
            height = contentHeight,
            topInset = 42 + previewHeight,
        }) or nil

    if IsValid(equipmentPanel) then
        local charModel = WO.UI.CreateCharacterModel(equipmentPanel,
            char.model or "models/player/group01/male_01.mdl")
        local modelWidth = math.min(220, equipmentWidth - 30)
        charModel:SetPos(math.floor((equipmentWidth - modelWidth) / 2), 38)
        charModel:SetSize(modelWidth, previewHeight - 4)
        charModel.spin = true

        if char.customization then
            charModel:ApplyCustomization(char.customization)
        end
    end

    local refreshHookId = "wo_inventory_ui_" .. tostring(thisFrame:EntIndex())

    WO.Hook.Add("InventoryChanged", refreshHookId, function()
        if IsValid(thisFrame) and IsValid(inventoryPanel) and inventoryPanel.RefreshItems then
            inventoryPanel:RefreshItems()
        end
    end)

    WO.Hook.Add("InventorySynced", refreshHookId .. "_sync", function()
        if IsValid(thisFrame) and IsValid(inventoryPanel) then
            BuildGrid(inventoryPanel)
        end
    end)

    thisFrame.OnRemove = function()
        WO.Hook.Remove("InventoryChanged", refreshHookId)
        WO.Hook.Remove("InventorySynced", refreshHookId .. "_sync")
        WO.UI.HideTooltip()

        if WO.UI.Drag and
            (not IsValid(WO.UI.Drag.source) or BelongsTo(WO.UI.Drag.source, thisFrame)) then
            ClearDrag()
        end

        if frame == thisFrame then
            frame = nil
        end
    end
end

function WO.InventoryUI.Close()
    if IsValid(frame) then
        local oldFrame = frame
        frame = nil
        oldFrame:Close()
    else
        frame = nil
    end

    ClearDrag()
end

function WO.InventoryUI.Toggle()
    if IsValid(frame) then
        WO.InventoryUI.Close()
    else
        WO.InventoryUI.Open()
    end
end

---------------------------------------------------------------------------
-- Клавиша I
---------------------------------------------------------------------------

function WO.InventoryUI.IsOpen()
    return IsValid(frame)
end

WO.Hook.Add("CharacterMenuOpening", "inventory_ui_clear", function()
    WO.InventoryUI.Close()
    WO.Inventory.ClientData = nil
end)

WO.UI.BindKey(KEY_I, function()
    if WO.Character.GetLocal() then
        WO.InventoryUI.Toggle()
    end
end, "inventory_toggle")
