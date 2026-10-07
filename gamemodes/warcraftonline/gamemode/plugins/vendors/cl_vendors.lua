--[[
    Warcraft Online — торговля (client): компактная витрина в стиле диалогов.
    Клики сразу меняют состояние кнопки; результат транзакции всегда подтверждает сервер.
]]

local vendorUI = nil
local nextVendorRequestId = 0
local BeginVendorAction

local function IsVendorUIActive(ui)
    return ui ~= nil and vendorUI == ui and IsValid(ui.frame)
end

local function FormatMoney(amount)
    amount = tonumber(amount) or 0

    if WO.Currency and isfunction(WO.Currency.Format) then
        return WO.Currency.Format(amount)
    end

    return tostring(amount) .. "c"
end

local function SetMouseInput(panel, enabled)
    if IsValid(panel) and isfunction(panel.SetMouseInputEnabled) then
        panel:SetMouseInputEnabled(enabled == true)
    end
end

local function UpdateWallet(ui)
    if not IsVendorUIActive(ui) or not IsValid(ui.walletLabel) then return end

    ui.walletLabel:SetDisplayText(WO.Lang:Get("currency.name") .. ": " ..
        FormatMoney(ui.data and ui.data.money or 0))
end

local function CloseVendor()
    local ui = vendorUI
    vendorUI = nil

    if not ui then return end

    ui.actionToken = (ui.actionToken or 0) + 1

    if IsValid(ui.frame) then
        ui.frame:Remove()
    end
end

WO.Vendors.CloseUI = CloseVendor

local function SetControlsEnabled(ui, enabled, busyButton)
    for _, button in ipairs(ui.actionButtons or {}) do
        if IsValid(button) and button ~= busyButton then
            button:SetEnabled(enabled == true)
        end
    end

    for _, button in pairs(ui.tabButtons or {}) do
        if IsValid(button) then
            button:SetEnabled(enabled == true)
        end
    end
end

local function UpdateTabs(ui)
    for tab, button in pairs(ui.tabButtons or {}) do
        if IsValid(button) then
            button:SetAccent(tab == ui.activeTab)
        end
    end
end

local function AddEmptyMessage(ui, text)
    local label = WO.UI.Label(ui.list, text, "WO.Body", WO.UI.Colors.textDim)
    label:Dock(TOP)
    label:DockMargin(8, 18, 8, 0)
    label:SetTall(42)
    SetMouseInput(label, false)
end

local function AddVendorCard(ui, item, kind)
    local row = vgui.Create("DPanel", ui.list)
    row:Dock(TOP)
    row:DockMargin(0, 0, 0, 8)
    row:SetTall(68)
    row:SetPaintBackground(false)
    row.Paint = function(_, w, h)
        WO.UI.DrawPanelOutlined(0, 0, w, h, WO.UI.Colors.panelLight,
            WO.UI.Colors.border, WO.UI.Metrics.radiusSmall)
    end

    local actionName = tostring(item.name or item.class or WO.Lang:Get("vendor.unknown_item"))
    local itemName = actionName
    local price = tonumber(item.price) or 0
    local detailText = FormatMoney(price)

    if kind == "buy" and tonumber(item.amount) and tonumber(item.amount) > 0 then
        detailText = detailText .. "  •  " ..
            WO.Lang:Get("vendor.stock_count", math.floor(tonumber(item.amount)))
    elseif kind == "sell" and tonumber(item.amount) and tonumber(item.amount) > 1 then
        itemName = itemName .. " ×" .. tostring(math.floor(tonumber(item.amount)))
    end

    local actionButton
    local actionText = WO.Lang:Get(kind == "buy" and "vendor.buy_one" or "vendor.sell_one")

    actionButton = WO.UI.Button(row, actionText, function()
        if kind == "buy" then
            return BeginVendorAction(ui, {
                kind = "buy",
                class = item.class,
                name = actionName,
            }, actionButton)
        end

        return BeginVendorAction(ui, {
            kind = "sell",
            uid = item.uid,
            name = actionName,
        }, actionButton)
    end)
    actionButton:SetSize(104, 34)
    SetMouseInput(actionButton, true)

    local nameLabel = WO.UI.Label(row, itemName, "WO.Body",
        WO.UI.GetRarityColor(item.rarity) or WO.UI.Colors.text)
    local detailLabel = WO.UI.Label(row, detailText, "WO.Small", WO.UI.Colors.textDim)
    SetMouseInput(nameLabel, false)
    SetMouseInput(detailLabel, false)

    -- Manual layout keeps the label out of the button hitbox at every resolution.
    row.PerformLayout = function(_, w, h)
        local buttonWidth = math.min(112, math.max(88, math.floor(w * 0.30)))
        local textWidth = math.max(0, w - buttonWidth - 38)

        actionButton:SetSize(buttonWidth, 34)
        actionButton:SetPos(w - buttonWidth - 10, math.floor((h - 34) / 2))
        nameLabel:SetPos(12, 8)
        nameLabel:SetSize(textWidth, 24)
        detailLabel:SetPos(12, 36)
        detailLabel:SetSize(textWidth, 20)
    end

    -- Keep enough information for input/layout regression tests and diagnostics.
    row.woVendorCard = true
    row.woActionButton = actionButton
    row.woNameLabel = nameLabel
    row.woDetailLabel = detailLabel

    if isfunction(row.InvalidateLayout) then
        row:InvalidateLayout(true)
    end

    ui.actionButtons[#ui.actionButtons + 1] = actionButton
end

local function RebuildItems(ui)
    if not IsVendorUIActive(ui) or not IsValid(ui.list) then return end

    if ui.pending then return end

    ui.actionButtons = {}
    ui.list:Clear()

    local data = istable(ui.data) and ui.data or {}

    if ui.activeTab == "buy" then
        if not istable(data.stock) then
            AddEmptyMessage(ui, WO.Lang:Get("vendor.loading"))
            return
        end

        local stockCount = 0

        for _, entry in ipairs(data.stock) do
            if isstring(entry.class) and entry.class ~= "" then
                stockCount = stockCount + 1
                AddVendorCard(ui, entry, "buy")
            end
        end

        if stockCount == 0 then
            AddEmptyMessage(ui, WO.Lang:Get("vendor.stock_empty"))
        end

        return
    end

    -- Inventory.Sync owns the client item cache; the character snapshot does not.
    local states = WO.Inventory and WO.Inventory.ClientData and
        WO.Inventory.ClientData.items or {}
    local sellVendor = {
        vendor = {
            sellRate = data.sellRate,
            buybackClasses = data.buybackClasses,
        },
    }
    local sellableCount = 0

    for _, instance in ipairs(states) do
        local def = WO.Items.Get(instance.class)
        local price = WO.Vendors.GetSellPrice and
            WO.Vendors.GetSellPrice(sellVendor, instance.class) or nil

        if price and isstring(instance.uid) and instance.uid ~= "" then
            sellableCount = sellableCount + 1
            AddVendorCard(ui, {
                class = instance.class,
                uid = instance.uid,
                name = (def and def.name) or instance.class,
                amount = instance.amount or 1,
                price = price,
                rarity = def and def.rarity,
            }, "sell")
        end
    end

    if sellableCount == 0 then
        AddEmptyMessage(ui, WO.Lang:Get("vendor.no_items"))
    end
end

local function SetActiveTab(ui, tab)
    if not IsVendorUIActive(ui) or ui.pending then return end
    if tab ~= "buy" and tab ~= "sell" then return end

    ui.activeTab = tab
    UpdateTabs(ui)
    RebuildItems(ui)
end

local function GetFailureMessage(reason)
    reason = tostring(reason or "unknown")

    if reason == "not_enough_money" then
        return WO.Lang:Get("vendor.not_enough_money")
    elseif reason == "inventory_full" or reason == "no_space" then
        return WO.Lang:Get("vendor.inventory_full")
    elseif reason == "cannot_sell" then
        return WO.Lang:Get("vendor.cannot_sell")
    elseif reason == "no_item" then
        return WO.Lang:Get("vendor.item_missing")
    elseif reason == "not_in_stock" then
        return WO.Lang:Get("vendor.not_in_stock")
    elseif reason == "no_session" then
        return WO.Lang:Get("vendor.session_expired")
    end

    return WO.Lang:Get("vendor.action_failed", reason)
end

local function FinishVendorAction(ui, result, timedOut)
    if not IsVendorUIActive(ui) or not ui.pending then return false end

    local action = ui.pendingAction
    local pendingButton = ui.pendingButton
    ui.pending = false
    ui.actionToken = (ui.actionToken or 0) + 1
    ui.pendingAction = nil
    ui.pendingButton = nil

    if result and isnumber(result.money) then
        ui.data.money = result.money
    end

    if IsValid(pendingButton) and isfunction(pendingButton.SetBusy) then
        pendingButton:SetBusy(false)
    end

    SetControlsEnabled(ui, true)
    UpdateWallet(ui)
    RebuildItems(ui)

    if timedOut then
        WO.Notify.Show("error", WO.Lang:Get("vendor.request_timeout"))
        return true
    end

    if result and result.success == true then
        local key = action.kind == "buy" and "vendor.buy_success" or "vendor.sell_success"
        WO.Notify.Show("success", WO.Lang:Get(key, action.name or ""))
    else
        WO.Notify.Show("error", GetFailureMessage(result and result.reason))
    end

    return true
end

BeginVendorAction = function(ui, action, button)
    if not IsVendorUIActive(ui) or ui.pending or not istable(action) then return false end

    nextVendorRequestId = (nextVendorRequestId % 2147483646) + 1
    action.requestId = nextVendorRequestId

    ui.pending = true
    ui.pendingAction = action
    ui.pendingButton = button
    ui.actionToken = (ui.actionToken or 0) + 1
    local token = ui.actionToken

    if IsValid(button) and isfunction(button.SetBusy) then
        local pendingKey = action.kind == "buy" and "vendor.buy_pending" or "vendor.sell_pending"
        button:SetBusy(true, WO.Lang:Get(pendingKey))
    end

    SetControlsEnabled(ui, false, button)

    local ok, err = pcall(function()
        if action.kind == "buy" then
            WO.Net.SendToServer("Vendor.Buy", ui.data.npcId or "", action.class, 1,
                action.requestId)
        else
            WO.Net.SendToServer("Vendor.Sell", ui.data.npcId or "", action.uid, 1,
                action.requestId)
        end
    end)

    if not ok then
        WO.Error("Vendor request could not be sent: " .. tostring(err))
        FinishVendorAction(ui, { success = false, reason = "send_failed" }, false)
        return false
    end

    timer.Simple(8, function()
        if IsVendorUIActive(ui) and ui.pending and ui.actionToken == token then
            FinishVendorAction(ui, nil, true)
        end
    end)

    return true
end

--- Открывает компактное окно торговца.
function WO.Vendors.OpenUI(data)
    CloseVendor()

    local sw, sh = ScrW(), ScrH()
    local w = math.min(560, math.max(360, math.floor(sw * 0.42)))
    local h = math.min(660, math.max(420, math.floor(sh * 0.84)))
    w = math.min(w, math.max(280, sw - 24))
    h = math.min(h, math.max(320, sh - 24))

    local ui = {
        data = istable(data) and data or {},
        activeTab = "buy",
        actionButtons = {},
        tabButtons = {},
        pending = false,
        actionToken = 0,
    }

    local frame = vgui.Create("DFrame")
    ui.frame = frame
    vendorUI = ui

    frame:SetSize(w, h)
    frame:SetPos(sw - w - 18, math.floor((sh - h) / 2))
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(false)
    frame:MakePopup()

    frame.Paint = function(_, pw, ph)
        local npcName = tostring(ui.data.npcName or WO.Lang:Get("vendor.title"))
        local initial = string.upper(string.sub(tostring(ui.data.npcId or "v"), 1, 1))
        local header = npcName .. " — " .. WO.Lang:Get("vendor.title")

        WO.UI.DrawPanelOutlined(0, 0, pw, ph, WO.UI.Colors.bg,
            WO.UI.Colors.accent, WO.UI.Metrics.radius)
        WO.UI.DrawTitleBar(0, 0, pw, 48, "")
        draw.RoundedBox(18, 16, 7, 34, 34, WO.UI.Colors.accentDark)
        draw.SimpleText(initial, "WO.Title", 33, 24, WO.UI.Colors.text,
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        WO.UI.DrawTextFit(header, "WO.Subtitle", 60, 24, WO.UI.Colors.text,
            TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, pw - 116, 32)
    end

    local closeButton = WO.UI.Button(frame, "✕", function()
        CloseVendor()
    end)
    closeButton:SetPos(w - 44, 10)
    closeButton:SetSize(30, 28)

    ui.walletLabel = WO.UI.Label(frame, "", "WO.Subtitle", WO.UI.Colors.accent)
    ui.walletLabel:SetPos(20, 58)
    ui.walletLabel:SetSize(w - 40, 26)

    local tabTop = 94
    local tabWidth = math.floor((w - 48) / 2)

    ui.tabButtons.buy = WO.UI.Button(frame, WO.Lang:Get("vendor.buy"), function()
        SetActiveTab(ui, "buy")
    end)
    ui.tabButtons.buy:SetPos(20, tabTop)
    ui.tabButtons.buy:SetSize(tabWidth, 38)

    ui.tabButtons.sell = WO.UI.Button(frame, WO.Lang:Get("vendor.sell"), function()
        SetActiveTab(ui, "sell")
    end)
    ui.tabButtons.sell:SetPos(28 + tabWidth, tabTop)
    ui.tabButtons.sell:SetSize(tabWidth, 38)

    ui.list = WO.UI.Scroll(frame)
    ui.list:SetPos(20, 144)
    ui.list:SetSize(w - 40, h - 164)

    UpdateWallet(ui)
    UpdateTabs(ui)
    RebuildItems(ui)
end

local function RefreshSync(data)
    local ui = vendorUI

    if not IsVendorUIActive(ui) or not istable(data) then return end

    ui.data = data
    UpdateWallet(ui)
    RebuildItems(ui)
end

local function RefreshInventory()
    local ui = vendorUI

    if IsVendorUIActive(ui) and ui.activeTab == "sell" then
        RebuildItems(ui)
    end
end

WO.Hook.Add("VendorActionResult", "vendor_ui_action_result", function(data)
    local ui = vendorUI

    if not IsVendorUIActive(ui) or not ui.pending or not istable(data) then return end

    local action = ui.pendingAction

    if not action or data.requestId ~= action.requestId then return end
    if data.npcId and data.npcId ~= (ui.data.npcId or "") then return end
    if data.action and data.action ~= action.kind then return end

    FinishVendorAction(ui, data, false)
end)

WO.Hook.Add("VendorOpened", "vendor_ui", function(data)
    WO.Vendors.OpenUI(data)
end)

WO.Hook.Add("VendorSynced", "vendor_ui", RefreshSync)
WO.Hook.Add("InventoryChanged", "vendor_inventory_refresh", RefreshInventory)
WO.Hook.Add("InventorySynced", "vendor_inventory_refresh", RefreshInventory)

-- Автозакрытие: смерть/выход из персонажа.
hook.Add("Think", "wo_vendor_autoclose", function()
    local ui = vendorUI

    if IsVendorUIActive(ui) then
        local ply = LocalPlayer()

        if not IsValid(ply) or not ply:HasCharacter() or not ply:Alive() then
            CloseVendor()
        end
    end
end)

WO.Hook.Add("CharacterMenuOpening", "vendor_ui_close", CloseVendor)
