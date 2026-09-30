--[[
    Warcraft Online — UI инвентаря (client).
    Grid с drag & drop, контекстным меню, тултипами (единый WO.UI).

    Структура окна (MMORPG):
        слева   — 3D-модель персонажа;
        центр   — сетка инвентаря;
        справа  — экипировка (если загружен equipment-плагин).
]]

WO.InventoryUI = WO.InventoryUI or {}

local frame = nil

---------------------------------------------------------------------------
-- Вспомогательные
---------------------------------------------------------------------------

local function GetItems()
    return (WO.Inventory.ClientData and WO.Inventory.ClientData.items) or {}
end

local function FindItem(uid)
    for _, item in ipairs(GetItems()) do
        if item.uid == uid then
            return item
        end
    end

    return nil
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

local function OpenItemMenu(slot, item)
    if not item then return end

    local def = WO.Items.Get(item.class)

    if not def then return end

    local menu = DermaMenu()

    -- Использовать / Экипировать
    if def.equipment then
        menu:AddOption(WO.Lang:Get("inventory.equip"), function()
            WO.Net.SendToServer("Inventory.Use", item.uid)
        end)
    elseif def.consumable then
        menu:AddOption(WO.Lang:Get("inventory.use"), function()
            WO.Net.SendToServer("Inventory.Use", item.uid)
        end)
    end

    -- Разделить стак
    if def.stackable and (item.amount or 1) > 1 then
        menu:AddOption(WO.Lang:Get("inventory.split"), function()
            OpenSplitDialog(item)
        end)
    end

    -- Выбросить
    menu:AddOption(WO.Lang:Get("inventory.drop"), function()
        WO.Net.SendToServer("Inventory.Drop", item.uid, 0)
    end)

    menu:AddSpacer()

    -- Уничтожить
    local destroy = menu:AddOption(WO.Lang:Get("inventory.destroy"), function()
        WO.Net.SendToServer("Inventory.Destroy", item.uid)
    end)

    destroy:SetTextColor(WO.UI.Colors.bad)

    menu:Open()
end

---------------------------------------------------------------------------
-- Сетка инвентаря
---------------------------------------------------------------------------

local function BuildGrid(parent)
    local data = WO.Inventory.ClientData

    if not data then return end

    if IsValid(parent.grid) then
        parent.grid:Remove()
    end

    local slotSize = WO.UI.Metrics.slotSize
    local gap = WO.UI.Metrics.slotGap

    local grid = vgui.Create("DPanel", parent)
    grid:SetPos(parent:GetWide() * 0.32, 55)
    grid:SetSize(data.width * (slotSize + gap) + gap, data.height * (slotSize + gap) + gap)
    grid:SetPaintBackground(false)

    grid.Paint = function(_, w, h)
        WO.UI.DrawPanelOutlined(0, 0, w, h, WO.UI.Colors.panelDark, WO.UI.Colors.border)
    end

    parent.grid = grid

    -- Слоты
    parent.slots = parent.slots or {}

    for _, slot in ipairs(parent.slots) do
        if IsValid(slot) then
            slot:Remove()
        end
    end

    parent.slots = {}

    for y = 1, data.height do
        for x = 1, data.width do
            local slot = vgui.Create("WO_ItemSlot", grid)

            slot:SetPos(gap + (x - 1) * (slotSize + gap), gap + (y - 1) * (slotSize + gap))
            slot:SetSize(slotSize, slotSize)
            slot:SetDroppable(true)
            slot.gridX = x
            slot.gridY = y

            -- Drop из другого слота
            slot.OnItemDropped = function(selfSlot, drag)
                WO.Net.SendToServer("Inventory.Move", drag.uid, selfSlot.gridX, selfSlot.gridY)
            end

            slot.CanDropItem = function()
                return true
            end

            slot.OnContextMenu = function(selfSlot, item)
                OpenItemMenu(selfSlot, item)
            end

            parent.slots[#parent.slots + 1] = slot
        end
    end

    -- Заполнение предметами
    local function RefreshItems()
        for _, slot in ipairs(parent.slots) do
            slot:SetItem(nil)
        end

        for _, item in ipairs(GetItems()) do
            for _, slot in ipairs(parent.slots) do
                if slot.gridX == item.x and slot.gridY == item.y then
                    slot:SetItem(item)
                    break
                end
            end
        end
    end

    RefreshItems()

    parent.RefreshItems = RefreshItems
end

---------------------------------------------------------------------------
-- Окно
---------------------------------------------------------------------------

function WO.InventoryUI.Open()
    if IsValid(frame) then
        frame:Close()
        frame = nil
    end

    -- Запрашиваем актуальное состояние
    WO.Net.SendToServer("Inventory.RequestSync")

    frame = WO.UI.Window(WO.Lang:Get("inventory.title"), 860, 480)

    -- 3D-модель персонажа слева
    local char = WO.Character.GetLocal()
    local modelPath = (char and char.model) or "models/player/group01/male_01.mdl"

    local model = WO.UI.CreateCharacterModel(frame, modelPath)
    model:SetPos(15, 55)
    model:SetSize(240, 400)

    if char and char.customization then
        model:ApplyCustomization(char.customization)
    end

    -- Кнопка сортировки
    local sortButton = WO.UI.Button(frame, WO.Lang:Get("inventory.title") .. " ↕", function()
        WO.Net.SendToServer("Inventory.Sort")
    end)

    sortButton:SetPos(20, 460 - 32)
    sortButton:SetSize(120, 26)

    -- Сетка
    BuildGrid(frame)

    -- Экипировка справа (если плагин загружен)
    if WO.EquipmentUI and WO.EquipmentUI.CreatePanel then
        local equipPanel = WO.EquipmentUI.CreatePanel(frame)

        if IsValid(equipPanel) then
            equipPanel:SetPos(585, 55)
        end
    end

    -- Обновления
    local refreshHookId = "wo_inventory_ui_" .. frame:EntIndex()

    WO.Hook.Add("InventoryChanged", refreshHookId, function()
        if IsValid(frame) and frame.RefreshItems then
            frame:RefreshItems()
        end
    end)

    WO.Hook.Add("InventorySynced", refreshHookId .. "_sync", function()
        if IsValid(frame) then
            BuildGrid(frame)
        end
    end)

    frame.OnRemove = function()
        WO.Hook.Remove("InventoryChanged", refreshHookId)
        WO.Hook.Remove("InventorySynced", refreshHookId .. "_sync")
        WO.UI.HideTooltip()
        frame = nil
    end
end

function WO.InventoryUI.Close()
    if IsValid(frame) then
        frame:Close()
    end

    frame = nil
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

WO.UI.BindKey(KEY_I, function()
    if WO.Character.GetLocal() then
        WO.InventoryUI.Toggle()
    end
end, "inventory_toggle")
