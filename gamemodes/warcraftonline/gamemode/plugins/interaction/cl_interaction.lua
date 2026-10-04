--[[
    Warcraft Online — взаимодействие (client).
    Периодический trace, подсказка [E], ресурсный halo и плавная карточка ресурса.
]]

local currentEnt = nil
local currentText = ""
local hoverTargetInfo = nil
local hoverDisplayInfo = nil
local hoverAlpha = 0

local function IsResourceEntity(ent)
    if not IsValid(ent) or not isfunction(ent.GetClass) then return false end

    local class = ent:GetClass()
    return class == "wo_item_world" or class == "wo_coin_pile"
end

--- Клиентские данные карточки извлекаются только из безопасных NW2/schema полей.
function WO.Interaction.GetResourceHoverInfo(ent)
    if not IsResourceEntity(ent) then return nil end

    if ent:GetClass() == "wo_coin_pile" then
        local amount = math.max(0, ent:GetNW2Int("wo_coin_amount", 0))

        return {
            entity = ent,
            name = WO.Lang:Get("resource.coins"),
            description = WO.Lang:Get("resource.coins_description", amount),
            amount = amount,
            color = WO.UI.Colors.accent,
        }
    end

    local itemClass = ent:GetNW2String("wo_item_class", "")
    local def = itemClass ~= "" and WO.Items.Get(itemClass) or nil
    local name = ent:GetNW2String("wo_item_name", def and def.name or itemClass)

    if name == "" then return nil end

    return {
        entity = ent,
        name = name,
        description = def and def.description or WO.Lang:Get("resource.unknown_description"),
        amount = math.max(1, ent:GetNW2Int("wo_item_amount", 1)),
        rarity = def and def.rarity or "common",
        color = WO.UI.GetRarityColor(def and def.rarity or "common"),
    }
end

function WO.Interaction.GetHoveredResourceInfo()
    return hoverTargetInfo
end

-- Trace is throttled: not run every frame.
function WO.Interaction.UpdateClientTarget()
    local ply = LocalPlayer()

    if not IsValid(ply) or not ply:HasCharacter() or not ply:Alive() then
        currentEnt = nil
        currentText = ""
        hoverTargetInfo = nil
        return
    end

    local trace = isfunction(ply.GetEyeTrace) and ply:GetEyeTrace() or nil
    local ent = trace and trace.Entity
    local inRange = IsValid(ent) and
        ent:GetPos():Distance(ply:GetPos()) <= WO.Interaction.GetRange(ent)

    if inRange and WO.Interaction.CanInteract(ent, ply) then
        currentEnt = ent
        currentText = WO.Interaction.GetText(ent, ply)

        local info = WO.Interaction.GetResourceHoverInfo(ent)

        if info then
            if not hoverTargetInfo or hoverTargetInfo.entity ~= info.entity then
                hoverDisplayInfo = info
                hoverAlpha = 0
            else
                hoverDisplayInfo = info
            end

            hoverTargetInfo = info
        else
            hoverTargetInfo = nil
        end
    else
        currentEnt = nil
        currentText = ""
        hoverTargetInfo = nil
    end
end

timer.Create("wo_interaction_trace", 0.25, 0, function()
    WO.Interaction.UpdateClientTarget()
end)

local function UpdateHoverAlpha()
    local target = hoverTargetInfo and IsValid(hoverTargetInfo.entity) and 1 or 0
    local fraction = math.Clamp((FrameTime() or 0) * 8, 0, 1)
    hoverAlpha = Lerp(fraction, hoverAlpha, target)

    if hoverAlpha <= 0.01 and target == 0 then
        hoverAlpha = 0
        hoverDisplayInfo = nil
    end
end

hook.Add("PreDrawHalos", "wo_resource_hover_halo", function()
    if hoverAlpha <= 0.02 or not hoverTargetInfo or
        not IsValid(hoverTargetInfo.entity) or not halo or not isfunction(halo.Add) then
        return
    end

    local color = hoverTargetInfo.color or WO.UI.Colors.accent
    local opacity = math.floor(180 * hoverAlpha)
    halo.Add({ hoverTargetInfo.entity }, Color(color.r, color.g, color.b, opacity),
        1, 1, 1, true, false)
end)

local function DrawResourceHoverCard()
    UpdateHoverAlpha()

    if hoverAlpha <= 0 or not hoverDisplayInfo or
        not IsValid(hoverDisplayInfo.entity) then return end

    local ent = hoverDisplayInfo.entity
    local point = isfunction(ent.WorldSpaceCenter) and ent:WorldSpaceCenter() or ent:GetPos()
    point = point + Vector(0, 0, 12)
    local screen = point:ToScreen()

    if not screen or not isnumber(screen.x) or not isnumber(screen.y) then return end

    local width, height = math.min(296, ScrW() - 16), 58
    local x = math.Clamp(screen.x - width / 2, 8, ScrW() - width - 8)
    local y = math.Clamp(screen.y - height - 18, 8, ScrH() - height - 8)
    local alpha = math.floor(232 * hoverAlpha)
    local rarityColor = hoverDisplayInfo.color or WO.UI.Colors.accent

    WO.UI.DrawPanelOutlined(x, y, width, height,
        Color(WO.UI.Colors.panelDark.r, WO.UI.Colors.panelDark.g,
            WO.UI.Colors.panelDark.b, alpha),
        Color(rarityColor.r, rarityColor.g, rarityColor.b, alpha),
        WO.UI.Metrics.radiusSmall)

    surface.SetDrawColor(rarityColor.r, rarityColor.g, rarityColor.b, alpha)
    surface.DrawRect(x + 8, y + 8, 3, height - 16)

    local title = hoverDisplayInfo.name or ""
    if (hoverDisplayInfo.amount or 1) > 1 then
        title = title .. "  ×" .. tostring(hoverDisplayInfo.amount)
    end

    local titleColor = Color(rarityColor.r, rarityColor.g, rarityColor.b, alpha)
    local textColor = Color(WO.UI.Colors.textDim.r, WO.UI.Colors.textDim.g,
        WO.UI.Colors.textDim.b, alpha)

    WO.UI.DrawTextFit(title, "WO.Small", x + 18, y + 8, titleColor,
        TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, width - 30, 18)
    WO.UI.DrawTextFit(hoverDisplayInfo.description or "", "WO.Tiny",
        x + 18, y + 31, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP,
        width - 30, 18)
end

-- Подсказка [E] для ближайшей интерактивной сущности.
hook.Add("HUDPaint", "wo_interaction_paint", function()
    DrawResourceHoverCard()

    if not IsValid(currentEnt) then return end

    local ply = LocalPlayer()

    if not IsValid(ply) or not ply:Alive() then return end

    local keyText = WO.Lang:Get("interact.key")
    local maxWidth = math.max(80, ScrW() - 48)
    surface.SetFont("WO.HUD")
    local keyWidth = select(1, surface.GetTextSize(keyText))
    local _, font = WO.UI.FitText(currentText, "WO.HUD", maxWidth - keyWidth - 54, 28)
    local text = WO.UI.FitText(currentText, font, maxWidth - keyWidth - 54, 28)
    local textWidth = select(1, surface.GetTextSize(text))
    local h = 42
    local w = math.min(maxWidth, keyWidth + textWidth + 50)
    local x = (ScrW() - w) / 2
    local y = math.Clamp(ScrH() * 0.62, 12, ScrH() - h - 12)

    draw.RoundedBox(WO.UI.Metrics.radiusSmall, x, y, w, h,
        Color(WO.UI.Colors.panelDark.r, WO.UI.Colors.panelDark.g,
            WO.UI.Colors.panelDark.b, 230))

    surface.SetDrawColor(WO.UI.Colors.accent)
    surface.DrawRect(x + 8, y + h - 2, w - 16, 2)

    WO.UI.DrawTextFit(keyText, "WO.HUD", x + 16, y + h / 2,
        WO.UI.Colors.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, keyWidth + 8, 28)
    WO.UI.DrawTextFit(text, font, x + 22 + keyWidth, y + h / 2,
        color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, maxWidth - keyWidth - 42, 28)
end)
