--[[
    Warcraft Online — HUD (client): скрытие стандартного HUD + каркас.
    Каждый элемент — отдельная функция (WO.HUD.*).
]]

WO.HUD = WO.HUD or {}

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

hook.Add("HUDShouldDraw", "wo_hud_hide", function(name)
    local ply = LocalPlayer()
    local hasCustomHUD = IsValid(ply) and ply:HasCharacter() and
        WO.Character and WO.Character.GetLocal and WO.Character.GetLocal() ~= nil

    -- Preserve the stock HUD while in limbo / before the character snapshot arrives.
    if not hasCustomHUD then return nil end

    if HIDE[name] then
        return false
    end
end)

-- Стандартный target ID (имя над игроком) — заменяем своим target frame
hook.Add("HUDDrawTargetID", "wo_hud_hide_targetid", function()
    return true -- возвращаем true = стандартный рисовать НЕ нужно? (false = не рисовать)
end)

---------------------------------------------------------------------------
-- Портрет/кадр персонажа (левый нижний угол)
---------------------------------------------------------------------------

function WO.HUD.DrawPlayerFrame()
    local ply = LocalPlayer()

    if not IsValid(ply) or not ply:HasCharacter() then return end

    local char = WO.Character.GetLocal()

    if not char then return end

    local w, h = math.Clamp(ScrW() * 0.235, 260, 340), 148
    local x, y = 24, math.max(12, ScrH() - h - 24)

    WO.UI.DrawPanelOutlined(x, y, w, h, WO.UI.Colors.panel, WO.UI.Colors.accentDark)

    -- Имя и уровень
    local name = char:GetFullName()
    local level = (WO.Leveling.ClientData and WO.Leveling.ClientData.level) or char.level or 1

    WO.UI.DrawTextFit(name, "WO.HUDName", x + 14, y + 16, WO.UI.Colors.accent,
        TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, w - 98, 26)

    WO.UI.DrawTextFit(WO.Lang:Get("character.level") .. " " .. level, "WO.Small",
        x + w - 14, y + 18, WO.UI.Colors.textDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP,
        72, 22)

    -- HP
    local hp = ply:Health()
    local maxHp = ply:GetMaxHealth()

    WO.UI.DrawBar(x + 14, y + 42, w - 28, 18, maxHp > 0 and hp / maxHp or 0,
        WO.UI.Colors.health, WO.UI.Colors.healthBg, hp .. " / " .. maxHp)

    -- Mana
    local mana = ply:GetMana()
    local maxMana = ply:GetNW2Int("wo_maxmana", 0)

    WO.UI.DrawBar(x + 14, y + 66, w - 28, 14, maxMana > 0 and mana / maxMana or 0,
        WO.UI.Colors.mana, WO.UI.Colors.manaBg, maxMana > 0 and (mana .. " / " .. maxMana) or nil)

    -- Stamina
    local stamina = ply:GetStamina()
    local maxStamina = ply:GetNW2Int("wo_maxstamina", 0)

    WO.UI.DrawBar(x + 14, y + 86, w - 28, 14, maxStamina > 0 and stamina / maxStamina or 0,
        WO.UI.Colors.stamina, WO.UI.Colors.staminaBg, maxStamina > 0 and (stamina .. " / " .. maxStamina) or nil)

    -- XP
    local xpData = WO.Leveling.ClientData
    local xp = xpData and xpData.experience or 0
    local xpNeeded = xpData and xpData.needed or 1

    WO.UI.DrawBar(x + 14, y + 106, w - 28, 12, xpNeeded > 0 and xp / xpNeeded or 0,
        WO.UI.Colors.xp, WO.UI.Colors.xpBg, xp .. " / " .. xpNeeded)

    -- Валюта
    local money = WO.Currency.ClientAmount or 0

    WO.UI.DrawTextFit(WO.Currency.Format and WO.Currency.Format(money) or tostring(money),
        "WO.Small", x + 14, y + 126, WO.UI.Colors.accent,
        TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, w - 28, 18)
end

---------------------------------------------------------------------------
-- Target frame (верхний центр)
---------------------------------------------------------------------------

function WO.HUD.DrawTargetFrame()
    local target = WO.Target and WO.Target.Get and WO.Target.Get()

    if not IsValid(target) then return end

    local w, h = 280, 64
    local x = ScrW() / 2 - w / 2
    local y = 28

    WO.UI.DrawPanelOutlined(x, y, w, h, WO.UI.Colors.panel, WO.UI.Colors.border)

    local name
    local level = 1
    local hp, maxHp

    if target:IsPlayer() then
        name = target:GetNW2String("wo_name", target:Nick())
        level = target:GetNW2Int("wo_level", 1)
        hp = target:Health()
        maxHp = target:GetMaxHealth()
    else
        name = target:GetNW2String("wo_name", target.PrintName or target:GetClass())
        level = target:GetNW2Int("wo_level", 1)
        hp = target:Health()
        maxHp = target:GetMaxHealth()
    end

    WO.UI.DrawTextFit(name, "WO.HUD", x + w / 2, y + 10, WO.UI.Colors.text,
        TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, w - 24, 20)
    WO.UI.DrawTextFit(WO.Lang:Get("character.level") .. " " .. level, "WO.Tiny",
        x + w / 2, y + 30, WO.UI.Colors.textDim,
        TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, w - 24, 16)

    WO.UI.DrawBar(x + 14, y + 46, w - 28, 12, maxHp > 0 and hp / maxHp or 0,
        WO.UI.Colors.health, WO.UI.Colors.healthBg, nil)
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

    -- В меню персонажа HUD скрываем
    if ply:GetNW2Bool("wo_inmenu", false) then return end

    WO.HUD.DrawPlayerFrame()
    WO.HUD.DrawTargetFrame()
    WO.HUD.DrawQuestTracker()
end)
