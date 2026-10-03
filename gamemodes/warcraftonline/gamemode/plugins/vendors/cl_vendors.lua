--[[
    Warcraft Online — торговля (client): окно торговца (покупка/продажа).
]]

local vendorFrame = nil
local vendorData = nil

local function CloseVendor()
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

--- Открывает окно торговца.
function WO.Vendors.OpenUI(data)
    CloseVendor()

    vendorData = nil

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
                WO.Net.SendToServer("Vendor.Buy", current.npcId or "", entry.class, 1)
            end)

            buyBtn:Dock(RIGHT)
            buyBtn:SetWide(96)
        end

        -- Инвентарь для продажи
        local char = WO.Character.GetLocal()
        local states = {}

        if char and char.inventory and char.inventory.items then
            for uid, instance in pairs(char.inventory.items) do
                states[#states + 1] = instance
            end
        end

        for _, instance in ipairs(states) do
            local def = WO.Items.Get(instance.class)
            local price = WO.Vendors.GetSellPrice and math.floor(
                ((def and def.price and def.price.sell) or 0) * (current.sellRate or 0.35)) or 0

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
                WO.Net.SendToServer("Vendor.Sell", current.npcId or "", instance.uid, 1)
            end)

            sellBtn:Dock(RIGHT)
            sellBtn:SetWide(96)
        end

        if #states == 0 then
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
