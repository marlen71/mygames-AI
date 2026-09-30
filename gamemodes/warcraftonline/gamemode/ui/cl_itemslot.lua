--[[
    Warcraft Online — слот предмета + тултип + drag & drop (client).

    Слот используется в инвентаре, экипировке, торговле (в будущем).
    Тултип полностью data-driven: строится из item definition + instance.

    Drop targets регистрируются автоматически:
        slot.WOIsDropTarget = true
        slot:CanDropItem(dragInfo) → bool
        slot:OnItemDropped(dragInfo)
]]

---------------------------------------------------------------------------
-- Глобальное состояние перетаскивания
---------------------------------------------------------------------------

WO.UI.Drag = nil
WO.UI.DropTargets = {}

local function RegisterDropTarget(panel)
    panel.WOIsDropTarget = true
    WO.UI.DropTargets[panel] = true
end

local function UnregisterDropTarget(panel)
    WO.UI.DropTargets[panel] = nil
end

local function FindDropTarget(x, y)
    for panel in pairs(WO.UI.DropTargets) do
        if IsValid(panel) then
            local px, py = panel:LocalToScreen(0, 0)
            local w, h = panel:GetSize()

            if x >= px and x <= px + w and y >= py and y <= py + h then
                return panel
            end
        end
    end

    return nil
end

---------------------------------------------------------------------------
-- Тултип
---------------------------------------------------------------------------

local tooltip = nil

local function BuildTooltipLines(item)
    local lines = {}

    if not item then return lines end

    local def = WO.Items.Get(item.class)

    if not def then
        lines[#lines + 1] = { text = tostring(item.class), font = "WO.Subtitle", color = WO.UI.Colors.text }
        return lines
    end

    local rarityColor = WO.UI.GetRarityColor(def.rarity)

    -- Название
    lines[#lines + 1] = { text = def.name or item.class, font = "WO.Subtitle", color = rarityColor }

    -- Редкость + тип
    local rarityName = WO.Lang:Get("rarity." .. (def.rarity or "common"))
    local typeName = WO.Lang:Get("item.type." .. (def.type or "misc"))

    lines[#lines + 1] = { text = rarityName .. " " .. typeName, font = "WO.Small", color = WO.UI.Colors.textDim }

    -- Слот экипировки
    if def.equipment and def.equipment.slot then
        lines[#lines + 1] = { text = WO.Lang:Get("slot." .. def.equipment.slot), font = "WO.Small", color = WO.UI.Colors.textDim }
    end

    -- Урон
    if def.weapon and def.weapon.damage then
        lines[#lines + 1] = { text = WO.Lang:Get("item.damage") .. ": " .. tostring(def.weapon.damage), font = "WO.Body", color = WO.UI.Colors.text }
    end

    -- Броня
    if def.armor and def.armor.value then
        lines[#lines + 1] = { text = WO.Lang:Get("stats.armor") .. ": " .. tostring(def.armor.value), font = "WO.Body", color = WO.UI.Colors.text }
    end

    -- Прочность
    if item.durability ~= nil and def.durability then
        local broken = item.durability <= 0

        lines[#lines + 1] = {
            text = WO.Lang:Get("item.durability") .. ": " .. math.floor(item.durability) .. "/" .. def.durability ..
                (broken and (" (" .. WO.Lang:Get("item.broken") .. ")") or ""),
            font = "WO.Body",
            color = broken and WO.UI.Colors.bad or WO.UI.Colors.text,
        }
    end

    -- Вес
    if def.weight then
        lines[#lines + 1] = { text = WO.Lang:Get("item.weight") .. ": " .. tostring(def.weight), font = "WO.Small", color = WO.UI.Colors.textDim }
    end

    -- Стак
    if def.stackable and item.amount and item.amount > 1 then
        lines[#lines + 1] = { text = WO.Lang:Get("item.stack") .. ": " .. item.amount, font = "WO.Small", color = WO.UI.Colors.textDim }
    end

    -- Требования
    local req = def.requirements
    local hasReq = false

    if req then
        local reqLines = {}

        if req.level then
            reqLines[#reqLines + 1] = WO.Lang:Get("item.required_level") .. " " .. req.level
        end

        if req.class then
            local names = {}

            for _, classId in ipairs(istable(req.class) and req.class or { req.class }) do
                local classDef = WO.Classes.Get and WO.Classes.Get(classId)

                names[#names + 1] = (classDef and classDef.name) or classId
            end

            reqLines[#reqLines + 1] = WO.Lang:Get("item.required_class") .. ": " .. table.concat(names, ", ")
        end

        if req.race then
            local names = {}

            for _, raceId in ipairs(istable(req.race) and req.race or { req.race }) do
                local raceDef = WO.Races.Get and WO.Races.Get(raceId)

                names[#names + 1] = (raceDef and raceDef.name) or raceId
            end

            reqLines[#reqLines + 1] = WO.Lang:Get("item.required_race") .. ": " .. table.concat(names, ", ")
        end

        if #reqLines > 0 then
            hasReq = true
            lines[#lines + 1] = { text = WO.Lang:Get("item.requirements") .. ":", font = "WO.Small", color = WO.UI.Colors.warn }

            for _, text in ipairs(reqLines) do
                lines[#lines + 1] = { text = text, font = "WO.Small", color = WO.UI.Colors.warn }
            end
        end
    end

    -- Бонусы статов
    if istable(def.stats) then
        for stat, value in pairs(def.stats) do
            local statName = WO.Lang:Get("stats." .. stat)

            if statName ~= "stats." .. stat then
                lines[#lines + 1] = {
                    text = (value >= 0 and "+" or "") .. value .. " " .. statName,
                    font = "WO.Body",
                    color = WO.UI.Colors.good,
                }
            end
        end
    end

    -- Описание
    if isstring(def.description) and def.description ~= "" then
        lines[#lines + 1] = { text = "", font = "WO.Small", color = WO.UI.Colors.text }
        lines[#lines + 1] = { text = def.description, font = "WO.Small", color = WO.UI.Colors.textDim, wrap = true }
    end

    return lines
end

function WO.UI.HideTooltip()
    if IsValid(tooltip) then
        tooltip:Remove()
    end

    tooltip = nil
end

function WO.UI.ShowTooltip(item, x, y)
    if not item then
        WO.UI.HideTooltip()
        return
    end

    if not IsValid(tooltip) then
        tooltip = vgui.Create("DPanel")
        tooltip:SetPaintBackground(false)
        tooltip:SetMouseInputEnabled(false)
        tooltip:SetDrawOnTop(true)

        tooltip.Paint = function(self, w, h)
            WO.UI.DrawPanelOutlined(0, 0, w, h, WO.UI.Colors.panelDark, WO.UI.Colors.accentDark, WO.UI.Metrics.radiusSmall)
        end
    end

    local lines = BuildTooltipLines(item)
    local maxWidth = 0
    local totalHeight = 12

    tooltip.lines = lines

    surface.SetFont("WO.Subtitle")

    for _, line in ipairs(lines) do
        surface.SetFont(line.font or "WO.Body")

        local tw, th = surface.GetTextSize(line.text)

        if line.wrap then
            tw = math.min(tw, 260)
        end

        maxWidth = math.max(maxWidth, tw)
        totalHeight = totalHeight + th + 3
    end

    local w = math.Clamp(maxWidth + 24, 140, 320)
    local h = totalHeight + 8

    tooltip:SetSize(w, h)

    x = x or gui.MouseX()
    y = y or gui.MouseY()

    local sw, sh = ScrW(), ScrH()

    if x + w + 20 > sw then
        x = x - w - 16
    end

    if y + h + 20 > sh then
        y = sh - h - 10
    end

    tooltip:SetPos(x + 16, y + 16)

    tooltip.Paint = function(self, pw, ph)
        WO.UI.DrawPanelOutlined(0, 0, pw, ph, WO.UI.Colors.panelDark, WO.UI.Colors.accentDark, WO.UI.Metrics.radiusSmall)

        local ly = 8

        for _, line in ipairs(self.lines or {}) do
            surface.SetFont(line.font or "WO.Body")

            local _, th = surface.GetTextSize(line.text)

            if line.text ~= "" then
                draw.DrawText(line.text, line.font or "WO.Body", 12, ly, line.color or WO.UI.Colors.text, TEXT_ALIGN_LEFT)
            end

            ly = ly + th + 3
        end
    end
end

---------------------------------------------------------------------------
-- Слот предмета
---------------------------------------------------------------------------

local SLOT = {}

AccessorFunc(SLOT, "item", "Item")
AccessorFunc(SLOT, "slotSize", "SlotSize")

function SLOT:Init()
    self.item = nil
    self:SetSize(WO.UI.Metrics.slotSize, WO.UI.Metrics.slotSize)
    self.slotColor = WO.UI.Colors.panelLight
end

--- Регистрирует слот как цель для drop.
function SLOT:SetDroppable(bool)
    if bool then
        RegisterDropTarget(self)
    else
        UnregisterDropTarget(self)
    end
end

function SLOT:OnRemove()
    UnregisterDropTarget(self)
end

function SLOT:Paint(w, h)
    local item = self.item
    local def = item and WO.Items.Get(item.class)
    local rarityColor = def and WO.UI.GetRarityColor(def.rarity) or WO.UI.Colors.border

    -- Фон
    draw.RoundedBox(WO.UI.Metrics.radiusSmall, 0, 0, w, h, self.slotColor)

    -- Рамка редкости
    if item then
        surface.SetDrawColor(rarityColor)
        surface.DrawOutlinedRect(0, 0, w, h, 2)
    else
        surface.SetDrawColor(WO.UI.Colors.border)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    -- Количество (стак)
    if item and item.amount and item.amount > 1 then
        draw.SimpleText(tostring(item.amount), "WO.Number", w - 3, h - 2, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
    end

    -- Прочность (полоска снизу)
    if item and item.durability ~= nil and def and def.durability then
        local frac = math.Clamp(item.durability / def.durability, 0, 1)

        surface.SetDrawColor(0, 0, 0, 160)
        surface.DrawRect(3, h - 6, w - 6, 3)

        local col = frac > 0.5 and WO.UI.Colors.good or (frac > 0.2 and WO.UI.Colors.warn or WO.UI.Colors.bad)

        surface.SetDrawColor(col)
        surface.DrawRect(3, h - 6, (w - 6) * frac, 3)
    end

    -- Иконка предмета (материал или модель)
    if item and def then
        if isstring(def.icon) and def.icon ~= "" then
            local mat = Material(def.icon)

            if mat and not mat:IsError() then
                surface.SetMaterial(mat)
                surface.SetDrawColor(255, 255, 255)
                surface.DrawTexturedRect(4, 4, w - 8, h - 8)
            end
        elseif self.itemIcon then
            -- DModelPanel иконка
            self.itemIcon:SetPos(2, 2)
            self.itemIcon:SetSize(w - 4, h - 4)
        end
    end
end

function SLOT:UpdateIcon()
    if IsValid(self.itemIcon) then
        self.itemIcon:Remove()
        self.itemIcon = nil
    end

    local item = self.item
    local def = item and WO.Items.Get(item.class)

    if not item or not def then return end

    if (not isstring(def.icon) or def.icon == "") and isstring(def.model) then
        self.itemIcon = vgui.Create("DModelPanel", self)
        self.itemIcon:SetModel(def.model)
        self.itemIcon:SetMouseInputEnabled(false)

        local ent = self.itemIcon.Entity

        if IsValid(ent) then
            local mins, maxs = ent:GetModelBounds()
            local size = (maxs - mins):Length()

            self.itemIcon:SetFOV(30 + size * 0.35)
            self.itemIcon:SetLookAt((mins + maxs) / 2)
            self.itemIcon:SetCamPos((mins + maxs) / 2 + Vector(size * 0.6, size * 0.35, size * 0.25))
        end

        self.itemIcon.LayoutEntity = function(_, ent)
            ent:SetAngles(Angle(15, SysTime() * 25 % 360, 0))
        end
    end
end

function SLOT:SetItem(item)
    self.item = item
    self:UpdateIcon()
end

function SLOT:OnCursorEntered()
    if self.item then
        WO.UI.ShowTooltip(self.item)
    end
end

function SLOT:OnCursorExited()
    WO.UI.HideTooltip()
end

function SLOT:OnMousePressed(code)
    if code == MOUSE_LEFT and self.item then
        -- Начало перетаскивания
        local ghost = vgui.Create("DPanel")
        ghost:SetSize(self:GetWide(), self:GetTall())
        ghost:SetMouseInputEnabled(false)
        ghost:SetDrawOnTop(true)
        ghost:SetPaintBackground(false)

        ghost.Paint = function(_, w, h)
            draw.RoundedBox(WO.UI.Metrics.radiusSmall, 0, 0, w, h, Color(255, 255, 255, 40))

            local def = WO.Items.Get(self.item.class)
            local col = def and WO.UI.GetRarityColor(def.rarity) or color_white

            surface.SetDrawColor(col)
            surface.DrawOutlinedRect(0, 0, w, h, 2)
        end

        WO.UI.Drag = {
            uid = self.item.uid,
            item = self.item,
            source = self,
            ghost = ghost,
        }

        WO.UI.HideTooltip()
    elseif code == MOUSE_RIGHT then
        self:OpenContextMenu()
    end
end

function SLOT:OnMouseReleased(code)
    if code == MOUSE_LEFT and WO.UI.Drag then
        local drag = WO.UI.Drag

        if IsValid(drag.ghost) then
            drag.ghost:Remove()
        end

        local x, y = gui.MouseX(), gui.MouseY()
        local target = FindDropTarget(x, y)

        WO.UI.Drag = nil

        if IsValid(target) and target ~= drag.source then
            local canDrop = true

            if isfunction(target.CanDropItem) then
                canDrop = target:CanDropItem(drag) == true
            end

            if canDrop and isfunction(target.OnItemDropped) then
                target:OnItemDropped(drag)
            end
        end
    end
end

function SLOT:Think()
    if WO.UI.Drag and WO.UI.Drag.source == self and IsValid(WO.UI.Drag.ghost) then
        local x, y = gui.MouseX(), gui.MouseY()

        WO.UI.Drag.ghost:SetPos(x - self:GetWide() / 2, y - self:GetTall() / 2)
    end
end

-- Контекстное меню (правый клик)
function SLOT:OpenContextMenu()
    if not self.item then return end

    if self.OnContextMenu then
        self:OnContextMenu(self.item)
    end
end

vgui.Register("WO_ItemSlot", SLOT, "DPanel")

---------------------------------------------------------------------------
-- Фабрика
---------------------------------------------------------------------------

function WO.UI.ItemSlot(parent)
    local slot = vgui.Create("WO_ItemSlot", parent)

    return slot
end
