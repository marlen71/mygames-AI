--[[
    Warcraft Online — HUD (client): скрытие стандартного HUD + каркас.
    Каждый элемент — отдельная функция (WO.HUD.*).
]]

WO.HUD = WO.HUD or {}

local playerPortrait
local playerPortraitKey
local targetPortrait
local targetPortraitModel
local targetPortraitNextRetry = 0
local hudCanvas
local hudCanvasSize = { w = 0, h = 0 }
local hudDrawErrors = {}

---------------------------------------------------------------------------
-- Скрытие стандартного HUD
---------------------------------------------------------------------------

local function HasCustomHUD()
    local ply = LocalPlayer()

    return IsValid(ply) and ply:HasCharacter() and WO.Character and
        WO.Character.GetLocal and WO.Character.GetLocal() ~= nil
end

-- Suppress every stock HUD element (including death notice/killfeed) in every
-- player state. Warcraft Online renders its own HUD and UI independently.
hook.Add("HUDShouldDraw", "wo_hud_hide", function()
    return false
end)

-- Suppress the engine target ID and default player-name text even in limbo.
hook.Add("HUDDrawTargetID", "wo_hud_hide_targetid", function()
    return false
end)

---------------------------------------------------------------------------
-- Портрет/кадр персонажа (левый нижний угол)
---------------------------------------------------------------------------

local function GetPlayerPortrait(char, x, y, size)
    if not IsValid(playerPortrait) then
        playerPortrait = WO.UI.CreateCharacterModel(hudCanvas, nil)

        if not IsValid(playerPortrait) then
            playerPortrait = nil
            return nil
        end

        playerPortrait:SetMouseInputEnabled(false)
        playerPortrait:SetKeyboardInputEnabled(false)
        playerPortrait:SetPaintBackground(false)
        playerPortrait:SetFOV(30)
        playerPortrait.spin = false

        -- Крупный RPG-портрет: кадрируем лицо и плечи, а не весь рост модели.
        playerPortrait.Think = function(self)
            local ent = self.Entity

            if not IsValid(ent) then return end

            local mins, maxs = ent:GetModelBounds()
            local height = math.max(maxs.z - mins.z, 32)
            local center = Vector((mins.x + maxs.x) * 0.5,
                (mins.y + maxs.y) * 0.5, mins.z + height * 0.84)

            self:SetLookAt(center)
            self:SetCamPos(center - Angle(5, 0, 0):Forward() * (height * 0.95) +
                Vector(0, 0, height * 0.025))
        end

        playerPortrait.LayoutEntity = function(_, ent)
            ent:SetAngles(Angle(0, 180, 0))
            ent:FrameAdvance(0)
        end
    end

    local portraitKey = tostring(char.id or "") .. "|" .. tostring(char.model or "") ..
        "|" .. tostring(char.customization or "")

    if playerPortraitKey ~= portraitKey then
        playerPortrait:SetPreviewModel(char.model)
        playerPortrait:ApplyCustomization(char.customization)
        playerPortraitKey = portraitKey
    end

    playerPortrait:SetPos(x, y)
    playerPortrait:SetSize(size, size)
    playerPortrait:SetVisible(true)

    return playerPortrait
end

function WO.HUD.DrawPlayerFrame()
    local ply = LocalPlayer()

    if not IsValid(ply) or not ply:HasCharacter() then return end

    local char = WO.Character.GetLocal()

    if not char then return end

    local w, h = math.Clamp(ScrW() * 0.25, 320, 360), 148
    local x, y = 24, math.max(12, ScrH() - h - 24)
    local portraitSize = 94
    local portraitX, portraitY = x + 10, y + 10
    local detailsX = portraitX + portraitSize + 12
    local detailsWidth = w - (detailsX - x) - 12

    WO.UI.DrawPanelOutlined(x, y, w, h, WO.UI.Colors.panel, WO.UI.Colors.accentDark)

    local name = isfunction(char.GetFullName) and char:GetFullName() or
        (tostring(char.name or "") .. " " .. tostring(char.surname or ""))
    local levelData = WO.Leveling and WO.Leveling.ClientData
    local level = (levelData and levelData.level) or char.level or 1

    WO.UI.DrawTextFit(name, "WO.HUDName", detailsX, y + 12, WO.UI.Colors.accent,
        TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, detailsWidth, 24)
    WO.UI.DrawTextFit(WO.Lang:Get("character.level") .. " " .. level, "WO.Small",
        detailsX, y + 34, WO.UI.Colors.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP,
        detailsWidth, 18)

    local hp = math.max(0, ply:Health())
    local maxHp = math.max(1, ply:GetMaxHealth())
    local barY = y + 56

    WO.UI.DrawBar(detailsX, barY, detailsWidth, 18, hp / maxHp,
        WO.UI.Colors.health, WO.UI.Colors.healthBg,
        WO.Lang:Get("stats.maxHealth") .. "  " .. hp .. " / " .. maxHp)
    barY = barY + 22

    local networkedStats = WO.Stats and WO.Stats.Networked or {}
    local maxMana = math.max(0, ply:GetNW2Int("wo_maxmana", tonumber(networkedStats.maxMana) or 0))
    local maxStamina = math.max(0, ply:GetNW2Int("wo_maxstamina", tonumber(networkedStats.maxStamina) or 0))

    if maxMana > 0 then
        local mana = math.Clamp(isfunction(ply.GetMana) and ply:GetMana() or
            ply:GetNW2Int("wo_mana", 0), 0, maxMana)
        WO.UI.DrawBar(detailsX, barY, detailsWidth, 13, mana / maxMana,
            WO.UI.Colors.mana, WO.UI.Colors.manaBg,
            WO.Lang:Get("stats.maxMana") .. "  " .. mana .. " / " .. maxMana)
        barY = barY + 16
    end

    if maxStamina > 0 then
        local stamina = math.Clamp(isfunction(ply.GetStamina) and ply:GetStamina() or
            ply:GetNW2Int("wo_stamina", 0), 0, maxStamina)
        WO.UI.DrawBar(detailsX, barY, detailsWidth, 13, stamina / maxStamina,
            WO.UI.Colors.stamina, WO.UI.Colors.staminaBg,
            WO.Lang:Get("stats.maxStamina") .. "  " .. stamina .. " / " .. maxStamina)
    end

    local xpData = WO.Leveling and WO.Leveling.ClientData or {}
    local xp = math.max(0, tonumber(xpData.experience) or tonumber(char.experience) or 0)
    local xpNeeded = math.max(1, tonumber(xpData.needed) or WO.Config.GetXPForLevel(level))
    local xpBarY = y + h - 9
    local xpText = WO.Lang:Get("xp.compact", xp, xpNeeded, math.max(0, xpNeeded - xp))

    WO.UI.DrawTextFit(xpText, "WO.Tiny", x + 9, y + h - 29,
        WO.UI.Colors.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, w - 18, 16)
    WO.UI.DrawBar(x + 9, xpBarY, w - 18, 5, xp / xpNeeded,
        WO.UI.Colors.xp, WO.UI.Colors.xpBg, nil)

    -- Create the VGUI portrait last: custom HUD text/bars must never be hidden
    -- by DModelPanel's higher VGUI paint layer.
    GetPlayerPortrait(char, portraitX, portraitY, portraitSize)
end

---------------------------------------------------------------------------
-- Target frame (верхний центр)
---------------------------------------------------------------------------

local function GetTargetPortrait(modelPath, x, y, size)
    if not isstring(modelPath) or modelPath == "" then
        if IsValid(targetPortrait) then
            targetPortrait:SetVisible(false)
        end

        return nil
    end

    if not IsValid(targetPortrait) then
        targetPortrait = vgui.Create("DModelPanel", hudCanvas)

        if not IsValid(targetPortrait) then
            targetPortrait = nil
            return nil
        end

        targetPortrait:SetMouseInputEnabled(false)
        targetPortrait:SetKeyboardInputEnabled(false)
        targetPortrait:SetPaintBackground(false)
        targetPortrait:SetFOV(34)
        targetPortrait.LayoutEntity = function(_, ent)
            ent:SetAngles(Angle(0, 180, 0))
            ent:FrameAdvance(0)
        end
        targetPortrait.Think = function(self)
            local ent = self.Entity

            if not IsValid(ent) then return end

            local mins, maxs = ent:GetModelBounds()
            local center = (mins + maxs) / 2
            local size = (maxs - mins):Length()

            self:SetLookAt(center)
            self:SetCamPos(center - Angle(5, 0, 0):Forward() * math.max(size * 0.82, 24))
        end
    end

    if targetPortraitModel ~= modelPath or
        (not IsValid(targetPortrait.Entity) and CurTime() >= targetPortraitNextRetry) then
        targetPortrait:SetModel(modelPath)
        targetPortraitModel = modelPath
        targetPortraitNextRetry = CurTime() + 1
    end

    targetPortrait:SetPos(x, y)
    targetPortrait:SetSize(size, size)
    targetPortrait:SetVisible(true)

    return targetPortrait
end

function WO.HUD.DrawTargetFrame()
    local target = WO.Target and WO.Target.Get and WO.Target.Get()

    if not IsValid(target) then
        if IsValid(targetPortrait) then targetPortrait:SetVisible(false) end
        return
    end

    local w, h = 352, 92
    local x = ScrW() / 2 - w / 2
    local y = 28
    local portraitSize = 70
    local detailsX = x + portraitSize + 24
    local detailsWidth = w - (detailsX - x) - 14

    WO.UI.DrawPanelOutlined(x, y, w, h, WO.UI.Colors.panel, WO.UI.Colors.border)

    local name
    local detail
    local hp, maxHp
    local showHealth = true

    if target:IsPlayer() then
        local identity = WO.Social and WO.Social.GetVisibleIdentity and
            WO.Social.GetVisibleIdentity(target) or { known = false, name = "Неизвестный", race = "" }
        name = identity.name or "Неизвестный"

        if identity.known then
            detail = WO.Lang:Get("character.level") .. " " .. (identity.level or 1) ..
                " · " .. (identity.class or "") .. " · " .. (identity.race or "")
        else
            detail = identity.race or ""
            showHealth = false
        end
    else
        name = target:GetNW2String("wo_name", target.PrintName or target:GetClass())
        detail = WO.Lang:Get("character.level") .. " " .. target:GetNW2Int("wo_level", 1)
    end

    hp = math.max(0, target:Health())
    maxHp = math.max(1, target:GetMaxHealth())
    GetTargetPortrait(target:GetModel(), x + 10, y + 10, portraitSize)

    WO.UI.DrawTextFit(name, "WO.HUDName", detailsX, y + 14, WO.UI.Colors.text,
        TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, detailsWidth, 24)
    WO.UI.DrawTextFit(detail or "", "WO.Tiny", detailsX, y + 37,
        WO.UI.Colors.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, detailsWidth, 16)

    if showHealth then
        WO.UI.DrawBar(detailsX, y + 61, detailsWidth, 17, hp / maxHp,
            WO.UI.Colors.health, WO.UI.Colors.healthBg, hp .. " / " .. maxHp)
    end
end

---------------------------------------------------------------------------
-- Имя игрока, NPC-инспектор, числа урона и пользовательский прицел
---------------------------------------------------------------------------

local damageNumbers = {}
local lastAimTrace = nil
local DAMAGE_NUMBER_LIFETIME = 1.6

local function DrawOutlinedText(text, font, x, y, color, alignX, alignY, outlineColor)
    if draw.SimpleTextOutlined then
        draw.SimpleTextOutlined(text, font, x, y, color, alignX, alignY,
            1, outlineColor or Color(8, 10, 14, 230))
    else
        draw.SimpleText(text, font, x, y, color, alignX, alignY)
    end
end

function WO.HUD.DrawPlayerNameplates()
    local localPlayer = LocalPlayer()
    if not IsValid(localPlayer) then return end

    for _, target in ipairs(player.GetAll()) do
        if IsValid(target) and target ~= localPlayer and
            target:GetNW2Bool("wo_char_active", false) then
            local distance = localPlayer:GetPos():Distance(target:GetPos())

            if distance <= 1800 then
                local identity = WO.Social and WO.Social.GetVisibleIdentity and
                    WO.Social.GetVisibleIdentity(target) or {
                        known = false,
                        name = "Неизвестный",
                        race = "Неизвестная раса",
                    }
                local head = target:GetPos() + Vector(0, 0, 82)
                local screen = head:ToScreen()

                if screen.visible then
                    local x = screen.x
                    local y = screen.y - (identity.known and 34 or 22)
                    local line

                    if identity.known then
                        line = "ур. " .. (identity.level or 1) .. "  ·  " ..
                            (identity.class or "") .. "  ·  " .. (identity.race or "")
                    else
                        line = identity.race or "Неизвестная раса"
                    end

                    draw.RoundedBox(4, x - 122, y - 4, 244, identity.known and 42 or 27,
                        Color(9, 13, 20, 190))
                    DrawOutlinedText(identity.name or "Неизвестный", "WO.Small", x, y,
                        identity.known and WO.UI.Colors.text or WO.UI.Colors.textDim,
                        TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                    DrawOutlinedText(line, "WO.Tiny", x, y + 17,
                        WO.UI.Colors.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                end
            end
        end
    end
end

local aimedNPCTarget = nil

local function IsNPCNameplateTarget(target)
    if not IsValid(target) then return false end
    if isfunction(target.IsNPC) and target:IsNPC() then return true end

    return isfunction(target.GetNW2String) and
        target:GetNW2String("wo_npc_id", "") ~= ""
end

local function GetNPCDefinition(target)
    if not IsValid(target) or not isfunction(target.GetNW2String) then return nil end

    local npcID = target:GetNW2String("wo_npc_id", "")
    return npcID ~= "" and WO.NPCs and WO.NPCs.Get and WO.NPCs.Get(npcID) or nil
end

local function UpdateAimedNPCTarget(ply, attackTrace)
    local hitEntity = attackTrace and attackTrace.Entity

    if attackTrace and attackTrace.Hit and IsValid(hitEntity) then
        aimedNPCTarget = IsNPCNameplateTarget(hitEntity) and hitEntity or nil
        return
    end

    aimedNPCTarget = nil

    if not isfunction(ply.GetShootPos) or not isfunction(ply.GetAimVector) or
        not util or not isfunction(util.TraceLine) then return end

    local startPos = ply:GetShootPos()
    local aim = ply:GetAimVector()
    if not isvector(startPos) or not isvector(aim) then return end

    local range = math.Clamp(tonumber(WO.Config.NPCHoverTraceRange) or 1800, 128, 8192)
    local trace = util.TraceLine({
        start = startPos,
        endpos = startPos + aim * range,
        filter = ply,
        mask = MASK_SHOT or MASK_SOLID,
    })
    local target = trace and trace.Entity or nil

    aimedNPCTarget = IsNPCNameplateTarget(target) and target or nil
end

local function GetAimedEntity(ply)
    if not lastAimTrace and isfunction(WO.HUD.GetAimTrace) then
        lastAimTrace = WO.HUD.GetAimTrace(ply)
        UpdateAimedNPCTarget(ply, lastAimTrace)
    end

    return aimedNPCTarget
end

function WO.HUD.GetHoveredNPC()
    local ply = LocalPlayer()
    if not IsValid(ply) then return nil end

    local target = GetAimedEntity(ply)
    if not IsNPCNameplateTarget(target) then return nil end

    return target, GetNPCDefinition(target)
end

function WO.HUD.DrawHoverNPC()
    local target, npcDefinition = WO.HUD.GetHoveredNPC()
    if not IsValid(target) then return end

    local name = target:GetNW2String("wo_name", target.PrintName or target:GetClass())
    local level = math.max(1, target:GetNW2Int("wo_level", 1))
    local maxHealth = math.max(1, isfunction(target.GetMaxHealth) and target:GetMaxHealth() or 1)
    local health = math.Clamp(isfunction(target.Health) and target:Health() or 0, 0, maxHealth)
    local height = 56

    if isfunction(target.OBBMaxs) then
        local bounds = target:OBBMaxs()
        if isvector(bounds) then height = math.max(height, bounds.z + 12) end
    end

    local screen = (target:GetPos() + Vector(0, 0, height)):ToScreen()
    if not screen or not screen.visible then return end

    local width, panelHeight = 260, 60
    local x = math.Clamp(screen.x - width / 2, 8, ScrW() - width - 8)
    local y = math.Clamp(screen.y - panelHeight - 10, 8, ScrH() - panelHeight - 8)
    local hostile = npcDefinition and npcDefinition.hostile == true
    local frameColor = hostile and WO.UI.Colors.health or WO.UI.Colors.accentDark
    local nameColor = hostile and WO.UI.Colors.text or WO.UI.Colors.accent

    WO.UI.DrawPanelOutlined(x, y, width, panelHeight, Color(10, 14, 22, 230), frameColor)
    WO.UI.DrawTextFit(name, "WO.Small", x + 10, y + 7, nameColor,
        TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, width - 94, 20)
    WO.UI.DrawTextFit(WO.Lang:Get("hud.level_short") .. " " .. level, "WO.Tiny",
        x + width - 82, y + 9, WO.UI.Colors.textDim,
        TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 72, 16)
    WO.UI.DrawBar(x + 10, y + 33, width - 20, 16, health / maxHealth,
        WO.UI.Colors.health, WO.UI.Colors.healthBg, health .. " / " .. maxHealth)
end

hook.Add("PreDrawHalos", "wo_npc_aim_highlight", function()
    if not HasCustomHUD() or not halo or not isfunction(halo.Add) then return end

    local target, npcDefinition = WO.HUD.GetHoveredNPC()
    if not IsValid(target) then return end

    local color = npcDefinition and npcDefinition.hostile and
        WO.UI.Colors.health or WO.UI.Colors.accent
    halo.Add({ target }, Color(color.r, color.g, color.b, 170), 2, 2, 1, true, false)
end)

function WO.HUD.DrawDamageNumbers()
    local now = CurTime()

    for index = #damageNumbers, 1, -1 do
        local entry = damageNumbers[index]
        local age = now - entry.started

        if age >= DAMAGE_NUMBER_LIFETIME then
            table.remove(damageNumbers, index)
        else
            local screen = entry.position:ToScreen()

            if screen.visible then
                local progress = math.Clamp(age / DAMAGE_NUMBER_LIFETIME, 0, 1)
                local alpha = math.floor(255 * ((1 - progress) ^ 1.15))
                local rise = age * 48
                local drift = entry.driftX * progress
                local text = (entry.critical and "CRIT  " or "") .. "-" ..
                    tostring(math.floor(entry.amount + 0.5))
                local color = entry.critical and Color(255, 208, 92, alpha) or
                    Color(255, 238, 208, alpha)
                local outline = Color(8, 10, 14, math.floor(alpha * 0.9))

                if alpha > 0 then
                    DrawOutlinedText(text, entry.critical and "WO.Subtitle" or "WO.Body",
                        screen.x + entry.offsetX + drift,
                        screen.y + entry.offsetY - rise, color,
                        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, outline)
                end
            end
        end
    end
end

function WO.HUD.AddDamageNumber(data)
    if not istable(data) or not isvector(data.position) then return end

    local amount = math.max(0, tonumber(data.amount) or 0)
    if amount <= 0 then return end

    damageNumbers[#damageNumbers + 1] = {
        position = data.position,
        amount = amount,
        critical = data.critical == true,
        started = CurTime(),
        offsetX = math.Rand(-16, 16),
        offsetY = math.Rand(-8, 8),
        driftX = math.Rand(-10, 10),
    }

    if #damageNumbers > 32 then table.remove(damageNumbers, 1) end
end

local function ActiveWeaponValue(ply, key)
    local weapon = IsValid(ply) and isfunction(ply.GetActiveWeapon) and
        ply:GetActiveWeapon() or nil

    if IsValid(weapon) and weapon[key] ~= nil then
        return weapon[key], weapon
    end

    if IsValid(weapon) and isfunction(weapon.GetClass) and weapons and
        isfunction(weapons.GetStored) then
        local stored = weapons.GetStored(weapon:GetClass())

        if stored then return stored[key], weapon end
    end

    return nil, weapon
end

--- Trace from the same shoot position/direction/range used by the active SWEP.
function WO.HUD.GetAimTrace(ply)
    if not IsValid(ply) or not isfunction(ply.GetShootPos) or
        not isfunction(ply.GetAimVector) then return nil end

    local startPos = ply:GetShootPos()
    local aim = ply:GetAimVector()

    if not isvector(startPos) or not isvector(aim) then return nil end

    local weapon
    local configuredRange
    configuredRange, weapon = ActiveWeaponValue(ply, "WORange")
    local staminaCost = ActiveWeaponValue(ply, "WOStaminaCost")
    local attackSpeed = ActiveWeaponValue(ply, "WOAttackSpeed")
    local isMelee = staminaCost ~= nil or attackSpeed ~= nil

    if IsValid(weapon) and isfunction(weapon.GetClass) and WO.Spells and
        weapon:GetClass() == WO.Spells.WeaponClass then
        local selectedSpell = WO.Spells.LocalBook and WO.Spells.LocalBook.selected
        local spell = selectedSpell and WO.Spells.Get and WO.Spells.Get(selectedSpell)
        configuredRange = spell and spell.range or 700
    end

    local range = math.Clamp(tonumber(configuredRange) or 8192, 32, 8192)
    local endPos = startPos + aim * range
    local filter = ply
    local mask = isMelee and (MASK_SHOT_HULL or MASK_SHOT or MASK_SOLID) or
        (MASK_SHOT or MASK_SOLID)

    local trace = util.TraceLine({
        start = startPos,
        endpos = endPos,
        filter = filter,
        mask = mask,
    })

    if isMelee and (not trace or not IsValid(trace.Entity)) then
        trace = util.TraceHull({
            start = startPos,
            endpos = endPos,
            filter = filter,
            mins = Vector(-8, -8, -8),
            maxs = Vector(8, 8, 8),
            mask = mask,
        })
    end

    return trace, endPos, weapon
end

function WO.HUD.GetCrosshairPosition(ply)
    local trace, endPos = WO.HUD.GetAimTrace(ply)
    local point = trace and trace.HitPos or endPos

    if isvector(point) then
        local screen = point:ToScreen()

        if screen and isnumber(screen.x) and isnumber(screen.y) then
            -- If third-person parallax moves the actual attack point just beyond
            -- the viewport, keep the reticle visible at the nearest screen edge.
            return math.Clamp(screen.x, 12, ScrW() - 12),
                math.Clamp(screen.y, 12, ScrH() - 12), trace
        end
    end

    return ScrW() / 2, ScrH() / 2, trace
end

function WO.HUD.DrawCrosshair()
    local ply = LocalPlayer()
    local cx, cy, trace = WO.HUD.GetCrosshairPosition(ply)
    lastAimTrace = trace
    if IsValid(ply) then UpdateAimedNPCTarget(ply, trace) end
    local target = trace and trace.Entity
    local color = Color(240, 202, 115, 235)

    if IsValid(target) and target:GetNW2String("wo_npc_id", "") ~= "" then
        color = Color(241, 112, 91, 245)
    elseif IsValid(target) and target:IsPlayer() then
        local identity = WO.Social and WO.Social.GetVisibleIdentity and
            WO.Social.GetVisibleIdentity(target)
        color = identity and identity.known and Color(128, 222, 164, 245) or
            Color(205, 211, 224, 235)
    end

    -- Four bracketed arms leave the center open, with an inner diamond and dot.
    local segments = {
        { -11, -5, -11, -11 }, { -11, -11, -5, -11 },
        { 5, -11, 11, -11 }, { 11, -11, 11, -5 },
        { 11, 5, 11, 11 }, { 11, 11, 5, 11 },
        { -5, 11, -11, 11 }, { -11, 11, -11, 5 },
        { -4, 0, 0, -4 }, { 0, -4, 4, 0 },
        { 4, 0, 0, 4 }, { 0, 4, -4, 0 },
    }

    surface.SetDrawColor(7, 9, 14, 235)
    for _, line in ipairs(segments) do
        surface.DrawLine(cx + line[1], cy + line[2], cx + line[3], cy + line[4])
    end
    surface.SetDrawColor(color)
    for _, line in ipairs(segments) do
        surface.DrawLine(cx + line[1], cy + line[2], cx + line[3], cy + line[4])
    end
    surface.SetDrawColor(color)
    surface.DrawRect(cx - 1, cy - 1, 2, 2)
end

--- Собственный компактный список оружия у правого края экрана.
function WO.HUD.DrawWeaponSelector()
    if not (WO.WeaponSelector and WO.WeaponSelector.GetVisibleWeapons) then return end

    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:HasCharacter() then return end
    if WO.WeaponSelector.IsVisible and not WO.WeaponSelector.IsVisible(ply) then return end

    local weapons = WO.WeaponSelector.GetVisibleWeapons(ply)
    if #weapons == 0 then return end

    local width, rowHeight, headerHeight = 224, 40, 30
    local height = headerHeight + #weapons * rowHeight + 10
    local x = ScrW() - width - 18
    local maxY = math.max(12, ScrH() - height - 12)
    local minY = math.min(260, maxY)
    local y = math.Clamp(ScrH() / 2 - height / 2, minY, maxY)

    WO.UI.DrawPanelOutlined(x, y, width, height, WO.UI.Colors.panelDark,
        WO.UI.Colors.border)
    WO.UI.DrawTextFit(WO.Lang:Get("weapon.selector_title"), "WO.Tiny",
        x + 12, y + 6, WO.UI.Colors.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP,
        width - 24, 18)

    for index, entry in ipairs(weapons) do
        local rowY = y + headerHeight + (index - 1) * rowHeight + 2
        local rowColor = entry.active and WO.UI.Colors.accentDark or WO.UI.Colors.panel
        local borderColor = entry.active and WO.UI.Colors.accent or WO.UI.Colors.border
        local textColor = entry.active and WO.UI.Colors.accent or WO.UI.Colors.text

        WO.UI.DrawPanelOutlined(x + 6, rowY, width - 12, rowHeight - 3,
            rowColor, borderColor, WO.UI.Metrics.radiusSmall)
        WO.UI.DrawTextFit(tostring(entry.key or entry.slot or index), "WO.Number",
            x + 24, rowY + (rowHeight - 3) / 2, WO.UI.Colors.accent,
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 26, rowHeight - 8)
        WO.UI.DrawTextFit(entry.name or entry.class or "?", "WO.Small",
            x + 46, rowY + (rowHeight - 3) / 2, textColor,
            TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, width - 62, rowHeight - 8)
    end
end

---------------------------------------------------------------------------
-- Death UI (экран смерти)
---------------------------------------------------------------------------

local deathInfo = nil

WO.Hook.Add("CharacterDeath", "hud", function(data)
    deathInfo = {
        killer = data.killer,
        respawnTime = data.respawnTime or 5,
        diedAt = SysTime(),
    }

    WO.Sound.PlayLocal("death")
end)

function WO.HUD.DrawDeathScreen()
    if not deathInfo then return end

    local ply = LocalPlayer()

    -- Выход из состояния смерти
    if IsValid(ply) and ply:Alive() then
        deathInfo = nil
        return
    end

    local w, h = ScrW(), ScrH()

    -- Затемнение
    draw.RoundedBox(0, 0, 0, w, h, Color(60, 0, 0, 150))

    WO.UI.DrawTextFit(WO.Lang:Get("death.title"), "WO.Title", w / 2, h * 0.35,
        color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, w - 48, 42)

    if deathInfo.killer then
        WO.UI.DrawTextFit(deathInfo.killer, "WO.Subtitle", w / 2, h * 0.35 + 36,
            WO.UI.Colors.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, w - 48, 30)
    end

    local remaining = math.max(0, deathInfo.respawnTime - (SysTime() - deathInfo.diedAt))

    WO.UI.DrawTextFit(string.format(WO.Lang:Get("death.respawn"), math.ceil(remaining)),
        "WO.Body", w / 2, h * 0.35 + 70, WO.UI.Colors.accent,
        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, w - 48, 26)
end

---------------------------------------------------------------------------
-- Трекер квестов (правый верхний угол)
---------------------------------------------------------------------------

function WO.HUD.DrawQuestTracker()
    if not (WO.Quests and WO.Quests.GetTrackerLines) then return end

    local lines = WO.Quests.GetTrackerLines()

    if #lines == 0 then return end

    local width = math.min(320, ScrW() - 32)
    local x = ScrW() - width - 16
    local y = 32
    local maxRows = math.max(1, math.floor((ScrH() - y - 24) / 20))
    local visibleRows = math.min(#lines, maxRows)

    WO.UI.DrawPanelOutlined(x - 12, y - 10, width, visibleRows * 20 + 20,
        WO.UI.Colors.panel, WO.UI.Colors.border)

    for index = 1, visibleRows do
        local line = lines[index]
        local isLast = index == visibleRows and #lines > visibleRows
        local text = isLast and (tostring(line.text or "") .. " …") or line.text
        local color = line.header and WO.UI.Colors.accent or
            (line.done and WO.UI.Colors.good or WO.UI.Colors.textDim)

        WO.UI.DrawTextFit(text, line.header and "WO.Small" or "WO.Tiny",
            x + (line.header and 0 or 8), y, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP,
            width - 32, 18)
        y = y + 20
    end
end

local function DrawWaypointArrow(centerX, centerY, relativeYaw)
    local radians = math.rad(relativeYaw)
    local forwardX, forwardY = math.sin(radians), -math.cos(radians)
    local sideX, sideY = math.cos(radians), math.sin(radians)

    local function Triangle(length, halfWidth)
        local tipX, tipY = centerX + forwardX * length, centerY + forwardY * length
        local baseX, baseY = centerX - forwardX * (length * 0.75),
            centerY - forwardY * (length * 0.75)

        return {
            { x = tipX, y = tipY },
            { x = baseX + sideX * halfWidth, y = baseY + sideY * halfWidth },
            { x = baseX - sideX * halfWidth, y = baseY - sideY * halfWidth },
        }
    end

    surface.SetDrawColor(7, 9, 14, 255)
    surface.DrawPoly(Triangle(15, 10))
    surface.SetDrawColor(WO.UI.Colors.accent)
    surface.DrawPoly(Triangle(12, 7))
end

--- Navigation badge for the next tracked quest objective or turn-in NPC.
function WO.HUD.DrawQuestWaypoint()
    if not (WO.Quests and WO.Quests.GetTrackedWaypoint) then return end

    local waypoint = WO.Quests.GetTrackedWaypoint()
    if not istable(waypoint) or not isvector(waypoint.position) then return end

    local ply = LocalPlayer()
    if not IsValid(ply) or not isfunction(ply.GetPos) then return end

    local playerPosition = ply:GetPos()
    local delta = waypoint.position - playerPosition
    local distance = delta:Length()
    if distance <= 0 then return end

    local eyeAngles = isfunction(ply.EyeAngles) and ply:EyeAngles() or angle_zero
    local eyeYaw = eyeAngles and tonumber(eyeAngles.y) or 0
    local bearing = math.deg(math.atan2(delta.y, delta.x))
    local relativeYaw = (bearing - eyeYaw + 180) % 360 - 180
    local width = math.min(390, ScrW() - 32)
    local height = 58
    local x = (ScrW() - width) / 2
    local y = 136
    local arrowX = x + 27
    local arrowY = y + height / 2
    local textX = x + 52
    local textWidth = math.max(80, width - 124)

    WO.UI.DrawPanelOutlined(x, y, width, height, WO.UI.Colors.panelDark,
        WO.UI.Colors.accentDark)
    DrawWaypointArrow(arrowX, arrowY, relativeYaw)

    WO.UI.DrawTextFit(waypoint.questName or WO.Lang:Get("quest.waypoint_title"),
        "WO.Small", textX, y + 6, WO.UI.Colors.accent,
        TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, textWidth, 22)
    WO.UI.DrawTextFit(waypoint.text or WO.Lang:Get("quest.waypoint_title"),
        "WO.Tiny", textX, y + 31, WO.UI.Colors.textDim,
        TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, textWidth, 18)
    WO.UI.DrawTextFit(WO.Lang:Get("quest.distance", math.max(1,
        math.Round(distance / 52.4934))), "WO.Small", x + width - 62,
        y + 19, WO.UI.Colors.text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, 52, 20)
end

---------------------------------------------------------------------------
-- Отрисовка
---------------------------------------------------------------------------

local function HideHUDModels()
    if IsValid(playerPortrait) then playerPortrait:SetVisible(false) end
    if IsValid(targetPortrait) then targetPortrait:SetVisible(false) end
end

local function DrawHUDSection(name, callback)
    local ok, reason = pcall(callback)

    if not ok and not hudDrawErrors[name] then
        hudDrawErrors[name] = true
        ErrorNoHalt("[WO HUD] " .. name .. " failed: " .. tostring(reason) .. "\n")
    end
end

local function EnsureHUDCanvas()
    if IsValid(hudCanvas) then return hudCanvas end

    hudCanvas = vgui.Create("DPanel")

    if not IsValid(hudCanvas) then
        hudCanvas = nil
        return nil
    end

    hudCanvas:SetPos(0, 0)
    hudCanvas:SetSize(ScrW(), ScrH())
    hudCanvas:SetPaintBackground(false)
    hudCanvas:SetMouseInputEnabled(false)
    hudCanvas:SetKeyboardInputEnabled(false)
    hudCanvas:SetZPos(-100)
    hudCanvasSize.w = ScrW()
    hudCanvasSize.h = ScrH()

    hudCanvas.Think = function(self)
        if hudCanvasSize.w ~= ScrW() or hudCanvasSize.h ~= ScrH() then
            hudCanvas:SetPos(0, 0)
            hudCanvas:SetSize(ScrW(), ScrH())
            hudCanvasSize.w = ScrW()
            hudCanvasSize.h = ScrH()
        end
    end

    hudCanvas.Paint = function()
        local ply = LocalPlayer()

        -- Avoid retaining a stale portrait/banner after a live Lua refresh.
        if IsValid(targetPortrait) then targetPortrait:SetVisible(false) end

        if not IsValid(ply) then
            HideHUDModels()
            return
        end

        if deathInfo then
            DrawHUDSection("death", WO.HUD.DrawDeathScreen)
        end

        -- The DModelPanels are children of this transparent canvas, so all
        -- HUD frames and labels paint in the same VGUI layer and remain visible.
        if not ply:HasCharacter() or not WO.Character or not WO.Character.GetLocal or
            not WO.Character.GetLocal() then
            HideHUDModels()
            return
        end

        DrawHUDSection("player frame", WO.HUD.DrawPlayerFrame)
        -- F3 still selects a combat target, but no target-information banner is drawn.
        DrawHUDSection("quest tracker", WO.HUD.DrawQuestTracker)
        DrawHUDSection("quest waypoint", WO.HUD.DrawQuestWaypoint)
        DrawHUDSection("weapon selector", WO.HUD.DrawWeaponSelector)
    end

    return hudCanvas
end

-- VGUI paints after HUDPaint. Keeping the WoW HUD in a transparent full-screen
-- panel (with its portraits as children) prevents DModelPanel from covering the
-- text/resource frames and makes the z-order deterministic.
hook.Add("HUDPaint", "wo_hud_paint", function()
    EnsureHUDCanvas()

    if not HasCustomHUD() then return end

    DrawHUDSection("crosshair", WO.HUD.DrawCrosshair)
    DrawHUDSection("player nameplates", WO.HUD.DrawPlayerNameplates)
    DrawHUDSection("npc hover", WO.HUD.DrawHoverNPC)
    DrawHUDSection("damage numbers", WO.HUD.DrawDamageNumbers)
end)

hook.Add("InitPostEntity", "wo_hud_canvas_init", function()
    timer.Simple(0, EnsureHUDCanvas)
end)

hook.Add("OnScreenSizeChanged", "wo_hud_canvas_resize", function()
    timer.Simple(0, function()
        if IsValid(hudCanvas) then
            hudCanvas:SetPos(0, 0)
            hudCanvas:SetSize(ScrW(), ScrH())
            hudCanvasSize.w = ScrW()
            hudCanvasSize.h = ScrH()
        end
    end)
end)
