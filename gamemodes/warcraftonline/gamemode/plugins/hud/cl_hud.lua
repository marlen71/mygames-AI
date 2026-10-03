--[[
    Warcraft Online — HUD (client): скрытие стандартного HUD + каркас.
    Каждый элемент — отдельная функция (WO.HUD.*).
]]

WO.HUD = WO.HUD or {}

local playerPortrait
local playerPortraitKey
local targetPortrait
local targetPortraitModel

---------------------------------------------------------------------------
-- Скрытие стандартного HUD
---------------------------------------------------------------------------

local HIDE = {
    CHudHealth = true,
    CHudBattery = true,
    CHudAmmo = true,
    CHudSecondaryAmmo = true,
    CHudWeaponSelection = true,
    CHudCrosshair = true,
    CHudScoreboard = true,
    CHudDamageIndicator = true,
    CHudGeiger = true,
    CHudSuitPower = true,
    CHudVehicle = true,
    CHudTrain = true,
    CHudGMod = true,
}

local function HasCustomHUD()
    local ply = LocalPlayer()

    return IsValid(ply) and ply:HasCharacter() and WO.Character and
        WO.Character.GetLocal and WO.Character.GetLocal() ~= nil
end

hook.Add("HUDShouldDraw", "wo_hud_hide", function(name)
    -- Preserve the stock HUD while in limbo / before the character snapshot arrives.
    if not HasCustomHUD() then return nil end

    if HIDE[name] then
        return false
    end
end)

-- Стандартный target ID заменяется собственным target frame; false подавляет native label.
hook.Add("HUDDrawTargetID", "wo_hud_hide_targetid", function()
    if HasCustomHUD() then return false end
end)

---------------------------------------------------------------------------
-- Портрет/кадр персонажа (левый нижний угол)
---------------------------------------------------------------------------

local function GetPlayerPortrait(char, x, y, size)
    if not IsValid(playerPortrait) then
        playerPortrait = WO.UI.CreateCharacterModel(nil, nil)

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

    local w, h = math.Clamp(ScrW() * 0.25, 320, 360), 132
    local x, y = 24, math.max(12, ScrH() - h - 24)
    local portraitSize = 94
    local portraitX, portraitY = x + 10, y + 10
    local detailsX = portraitX + portraitSize + 12
    local detailsWidth = w - (detailsX - x) - 12

    WO.UI.DrawPanelOutlined(x, y, w, h, WO.UI.Colors.panel, WO.UI.Colors.accentDark)

    GetPlayerPortrait(char, portraitX, portraitY, portraitSize)

    local name = char:GetFullName()
    local level = (WO.Leveling.ClientData and WO.Leveling.ClientData.level) or char.level or 1

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

    local maxMana = ply:GetNW2Int("wo_maxmana", 0)
    local maxStamina = ply:GetNW2Int("wo_maxstamina", 0)

    if maxMana > 0 then
        local mana = math.Clamp(ply:GetMana(), 0, maxMana)
        WO.UI.DrawBar(detailsX, barY, detailsWidth, 13, mana / maxMana,
            WO.UI.Colors.mana, WO.UI.Colors.manaBg,
            WO.Lang:Get("stats.maxMana") .. "  " .. mana .. " / " .. maxMana)
        barY = barY + 16
    end

    if maxStamina > 0 then
        local stamina = math.Clamp(ply:GetStamina(), 0, maxStamina)
        WO.UI.DrawBar(detailsX, barY, detailsWidth, 13, stamina / maxStamina,
            WO.UI.Colors.stamina, WO.UI.Colors.staminaBg,
            WO.Lang:Get("stats.maxStamina") .. "  " .. stamina .. " / " .. maxStamina)
    end

    local xpData = WO.Leveling.ClientData
    local xp = xpData and xpData.experience or 0
    local xpNeeded = math.max(1, xpData and xpData.needed or 1)
    local xpBarY = y + h - 9

    WO.UI.DrawBar(x + 9, xpBarY, w - 18, 5, xp / xpNeeded,
        WO.UI.Colors.xp, WO.UI.Colors.xpBg, nil)
end

---------------------------------------------------------------------------
-- Target frame (верхний центр)
---------------------------------------------------------------------------

local function GetTargetPortrait(modelPath, x, y, size)
    if not isstring(modelPath) or modelPath == "" or not file.Exists(modelPath, "GAME") then
        if IsValid(targetPortrait) then
            targetPortrait:SetVisible(false)
        end

        return nil
    end

    if not IsValid(targetPortrait) then
        targetPortrait = vgui.Create("DModelPanel")

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

    if targetPortraitModel ~= modelPath then
        targetPortrait:SetModel(modelPath)
        targetPortraitModel = modelPath
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
    local level = 1
    local hp, maxHp

    if target:IsPlayer() then
        name = target:GetNW2String("wo_name", target:Nick())
        level = target:GetNW2Int("wo_level", 1)
    else
        name = target:GetNW2String("wo_name", target.PrintName or target:GetClass())
        level = target:GetNW2Int("wo_level", 1)
    end

    hp = math.max(0, target:Health())
    maxHp = math.max(1, target:GetMaxHealth())
    GetTargetPortrait(target:GetModel(), x + 10, y + 10, portraitSize)

    WO.UI.DrawTextFit(name, "WO.HUDName", detailsX, y + 14, WO.UI.Colors.text,
        TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, detailsWidth, 24)
    WO.UI.DrawTextFit(WO.Lang:Get("character.level") .. " " .. level, "WO.Tiny",
        detailsX, y + 37, WO.UI.Colors.textDim,
        TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, detailsWidth, 16)
    WO.UI.DrawBar(detailsX, y + 61, detailsWidth, 17, hp / maxHp,
        WO.UI.Colors.health, WO.UI.Colors.healthBg, hp .. " / " .. maxHp)
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

---------------------------------------------------------------------------
-- Отрисовка
---------------------------------------------------------------------------

hook.Add("HUDPaint", "wo_hud_paint", function()
    local ply = LocalPlayer()

    if not IsValid(ply) then return end

    -- Экран смерти
    if deathInfo then
        WO.HUD.DrawDeathScreen()
    end

    -- HUD существует только для выбранного персонажа. Не полагаемся на
    -- wo_inmenu здесь: после возрождения NW2-флаг может прийти с задержкой.
    if not ply:HasCharacter() or not WO.Character.GetLocal() then
        if IsValid(playerPortrait) then playerPortrait:SetVisible(false) end
        if IsValid(targetPortrait) then targetPortrait:SetVisible(false) end
        return
    end

    WO.HUD.DrawPlayerFrame()
    WO.HUD.DrawTargetFrame()
    WO.HUD.DrawQuestTracker()
end)
