--[[
    Warcraft Online — торговля (client): окно торговца (покупка/продажа).
]]

local vendorFrame = nil
local vendorData = nil
local vendorActionPending = false
local vendorActionToken = 0
local vendorButtons = {}

local function SetVendorActionPending(pending)
    vendorActionPending = pending == true

    for _, button in ipairs(vendorButtons) do
        if IsValid(button) and isfunction(button.SetBusy) then
            button:SetBusy(vendorActionPending, WO.Lang:Get("ui.pending"))
        elseif IsValid(button) then
            button:SetEnabled(not vendorActionPending)
        end
    end
end

local function BeginVendorAction(send)
    if vendorActionPending then return false end

    SetVendorActionPending(true)
    vendorActionToken = vendorActionToken + 1
    local token = vendorActionToken

    send()

    timer.Simple(3, function()
        if vendorActionPending and vendorActionToken == token then
            SetVendorActionPending(false)
            WO.Notify.Show("error", WO.Lang:Get("vendor.request_timeout"))
        end
    end)

    return true
end

local function CloseVendor()
    vendorActionToken = vendorActionToken + 1
    SetVendorActionPending(false)
    vendorButtons = {}

    if IsValid(vendorFrame) then
        vendorFrame:Remove()
        vendorFrame = nil
    end
end

WO.Vendors.CloseUI = CloseVendor

local function RefreshSync(data)
    vendorData = data

    if not IsValid(vendorFrame) then return end

    WO.Hook.Run("VendorUIRefresh", data)
end

WO.Hook.Add("VendorActionResult", "vendor_ui_action_result", function(data)
    if not istable(data) or not vendorActionPending then return end
    if vendorData and data.npcId and data.npcId ~= vendorData.npcId then return end

    SetVendorActionPending(false)

    if data.success ~= true then
        local reason = tostring(data.reason or "unknown")
        local message

        if reason == "not_enough_money" then
            message = WO.Lang:Get("vendor.not_enough_money")
        elseif reason == "inventory_full" or reason == "no_space" then
            message = WO.Lang:Get("vendor.inventory_full")
        else
            message = WO.Lang:Get("vendor.action_failed", reason)
        end

        WO.Notify.Show("error", message)
    end

    if IsValid(vendorFrame) then
        WO.Hook.Run("VendorUIRefresh", vendorData)
    end
end)

--- Открывает окно торговца.
function WO.Vendors.OpenUI(data)
    CloseVendor()

    vendorData = istable(data) and data or nil

    local sw, sh = ScrW(), ScrH()
    local w, h = math.min(860, sw * 0.7), math.min(560, sh * 0.75)

    vendorFrame = vgui.Create("DFrame")
    vendorFrame:SetSize(w, h)
    vendorFrame:SetPos((sw - w) / 2, (sh - h) / 2)
    vendorFrame:SetTitle("")
    vendorFrame:ShowCloseButton(true)
    vendorFrame:MakePopup()

    vendorFrame.Paint = function(_, pw, ph)
        WO.UI.DrawPanelOutlined(0, 0, pw, ph, WO.UI.Colors.bg, WO.UI.Colors.accent)
        WO.UI.DrawTitleBar(0, 0, pw, 38,
            (data and data.npcName or WO.Lang:Get("vendor.title")) .. " — " .. WO.Lang:Get("vendor.title"))
    end

    -- Кошелёк
    local moneyLabel = WO.UI.Label(vendorFrame, "", "WO.Subtitle", WO.UI.Colors.accent)

    moneyLabel:SetPos(24, 50)
    moneyLabel:SetSize(w - 48, 24)

    -- Покупка (слева)
    local buyTitle = WO.UI.Label(vendorFrame, WO.Lang:Get("vendor.buy"), "WO.Subtitle", WO.UI.Colors.text)

    buyTitle:SetPos(24, 86)
    buyTitle:SetSize(w * 0.48, 22)

    local buyScroll = WO.UI.Scroll(vendorFrame)

    buyScroll:SetPos(24, 114)
    buyScroll:SetSize(w * 0.46, h - 150)

    -- Продажа (справа)
    local sellTitle = WO.UI.Label(vendorFrame, WO.Lang:Get("vendor.sell"), "WO.Subtitle", WO.UI.Colors.text)

    sellTitle:SetPos(w * 0.52, 86)
    sellTitle:SetSize(w * 0.46, 22)

    local sellScroll = WO.UI.Scroll(vendorFrame)

    sellScroll:SetPos(w * 0.52, 114)
    sellScroll:SetSize(w * 0.44, h - 150)

    local function Rebuild()
        vendorButtons = {}
        buyScroll:Clear()
        sellScroll:Clear()

        local current = vendorData or {}
        local moneyText = tostring(current.money or 0)

        if isfunction(WO.Util.FormatMoney) then
            moneyText = WO.Util.FormatMoney(current.money or 0)
        end

        moneyLabel:SetDisplayText(WO.Lang:Get("currency.name") .. ": " .. moneyText)

        -- Товары
        for _, entry in ipairs(current.stock or {}) do
            local row = vgui.Create("DPanel", buyScroll)

            row:Dock(TOP)
            row:DockMargin(0, 0, 0, 6)
            row:SetTall(40)
            row:SetPaintBackground(false)

            local label = WO.UI.Label(row,
                (entry.name or entry.class) .. "  —  " .. (entry.price or 0) .. " " .. WO.Lang:Get("currency.name"),
                "WO.Small", WO.UI.GetRarityColor(entry.rarity) or WO.UI.Colors.text)

            label:Dock(FILL)
            label:DockMargin(8, 10, 8, 0)

            local buyBtn = WO.UI.Button(row, WO.Lang:Get("vendor.buy_one"), function()
                BeginVendorAction(function()
                    WO.Net.SendToServer("Vendor.Buy", current.npcId or "", entry.class, 1)
                end)
            end)

            buyBtn:Dock(RIGHT)
            buyBtn:SetWide(96)
            vendorButtons[#vendorButtons + 1] = buyBtn

            if vendorActionPending then
                buyBtn:SetBusy(true, WO.Lang:Get("ui.pending"))
            end
        end

        -- Inventory.Sync has its own client cache; Character.GetLocal() does
        -- not contain the server's private inventory container.
        local states = (WO.Inventory.ClientData and WO.Inventory.ClientData.items) or {}

        local sellableCount = 0
        local sellVendor = { vendor = {
            sellRate = current.sellRate,
            buybackClasses = current.buybackClasses,
        } }

        for _, instance in ipairs(states) do
            local def = WO.Items.Get(instance.class)
            local price = WO.Vendors.GetSellPrice and
                WO.Vendors.GetSellPrice(sellVendor, instance.class) or nil

            if price then
            sellableCount = sellableCount + 1
            local row = vgui.Create("DPanel", sellScroll)

            row:Dock(TOP)
            row:DockMargin(0, 0, 0, 6)
            row:SetTall(40)
            row:SetPaintBackground(false)

            local label = WO.UI.Label(row,
                ((def and def.name) or instance.class) .. " x" .. (instance.amount or 1) ..
                "  —  " .. price .. " " .. WO.Lang:Get("currency.name"),
                "WO.Small", WO.UI.Colors.textDim)

            label:Dock(FILL)
            label:DockMargin(8, 10, 8, 0)

            local sellBtn = WO.UI.Button(row, WO.Lang:Get("vendor.sell_one"), function()
                BeginVendorAction(function()
                    WO.Net.SendToServer("Vendor.Sell", current.npcId or "", instance.uid, 1)
                end)
            end)

            sellBtn:Dock(RIGHT)
            sellBtn:SetWide(96)
            vendorButtons[#vendorButtons + 1] = sellBtn

            if vendorActionPending then
                sellBtn:SetBusy(true, WO.Lang:Get("ui.pending"))
            end
            end
        end

        if sellableCount == 0 then
            local empty = WO.UI.Label(sellScroll, WO.Lang:Get("vendor.no_items"), "WO.Small", WO.UI.Colors.textDim)

            empty:Dock(TOP)
            empty:DockMargin(8, 12, 8, 0)
            empty:SetTall(18)
        end
    end

    WO.Hook.Add("VendorUIRefresh", "vendor_ui", function()
        if IsValid(vendorFrame) then
            Rebuild()
        end
    end)

    Rebuild()
end

---------------------------------------------------------------------------
-- События
---------------------------------------------------------------------------

WO.Hook.Add("VendorOpened", "vendor_ui", function(data)
    WO.Vendors.OpenUI(data)
end)

WO.Hook.Add("VendorSynced", "vendor_ui", function(data)
    RefreshSync(data)
end)

local function RefreshVendorInventory()
    if IsValid(vendorFrame) then
        WO.Hook.Run("VendorUIRefresh", vendorData)
    end
end

WO.Hook.Add("InventoryChanged", "vendor_inventory_refresh", RefreshVendorInventory)
WO.Hook.Add("InventorySynced", "vendor_inventory_refresh", RefreshVendorInventory)

-- Автозакрытие: смерть/выход из персонажа
hook.Add("Think", "wo_vendor_autoclose", function()
    if IsValid(vendorFrame) then
        local ply = LocalPlayer()

        if not IsValid(ply) or not ply:HasCharacter() or not ply:Alive() then
            CloseVendor()
        end
    end
end)

WO.Hook.Add("CharacterMenuOpening", "vendor_ui_close", function()
    CloseVendor()
    vendorData = nil
end)
