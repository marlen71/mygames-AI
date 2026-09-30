--[[
    Warcraft Online — система уровней (server).

    Источники опыта: kill XP, quest XP, exploration XP, event XP —
    все идут через WO.Leveling:AddXP(ply, amount, reason).

    При достижении нового уровня:
        - увеличить level;
        - пересчитать stats;
        - уведомить игрока;
        - вызвать hook CharacterLevelUp;
        - сохранить персонажа.
]]

---------------------------------------------------------------------------
-- Опыт
---------------------------------------------------------------------------

--[[
    Добавляет опыт персонажу.

    @param ply Player
    @param amount number количество опыта
    @param reason string|nil "kill" | "quest" | "explore" | "event" | ...
    @return number новые уровни (сколько раз повысились)
]]
function WO.Leveling.AddXP(ply, amount, reason)
    if not IsValid(ply) then return 0 end

    local char = ply:GetCharacter()

    if not char then return 0 end

    amount = math.floor(tonumber(amount) or 0)

    if amount <= 0 then return 0 end

    -- Защита от аномальных значений
    if amount > 10000000 then
        WO.Warn("Suspicious XP add for " .. ply:Nick() .. ": " .. amount)
        return 0
    end

    local maxLevel = WO.Config.MaxLevel or 60

    if char.level >= maxLevel then
        char.experience = 0
        return 0
    end

    char.experience = (char.experience or 0) + amount

    WO.Debug("XP: " .. ply:Nick() .. " +" .. amount .. (reason and (" (" .. reason .. ")") or ""))

    -- Уведомление об опыте
    WO.Notify(ply, "xp", string.format(WO.Lang:Get("xp.gain"), amount))

    -- Проверка повышения уровня (может быть несколько уровней разом)
    local levelsGained = 0

    while char.level < maxLevel do
        local needed = WO.Config.GetXPForLevel(char.level)

        if char.experience >= needed then
            char.experience = char.experience - needed

            WO.Leveling.LevelUp(ply)
            levelsGained = levelsGained + 1
        else
            break
        end
    end

    if levelsGained == 0 then
        WO.SaveQueue.MarkDirty(char)
        WO.Leveling.SyncXP(ply)
    end

    return levelsGained
end

---------------------------------------------------------------------------
-- Повышение уровня
---------------------------------------------------------------------------

--[[
    Повышает уровень персонажа на 1 (вызывается из AddXP).
]]
function WO.Leveling.LevelUp(ply)
    if not IsValid(ply) then return end

    local char = ply:GetCharacter()

    if not char then return end

    char.level = math.min(WO.Config.MaxLevel or 60, (char.level or 1) + 1)

    -- Пересчёт статов + полное восстановление
    WO.Stats.Recalculate(char)
    ply._woFullHeal = true
    WO.Stats.ApplyVitals(ply)

    -- NW2 для HUD
    ply:SetNW2Int("wo_level", char.level)

    WO.Log("Level up: " .. char:GetFullName() .. " -> " .. char.level)

    -- Уведомление
    WO.Notify(ply, "levelup", string.format(WO.Lang:Get("levelup.text"), char.level), "level_up")

    -- Сохранение и хуки
    WO.SaveQueue.MarkDirty(char)
    WO.SaveQueue.SaveNow(char)

    WO.Hook.Run("CharacterLevelUp", char, char.level)

    WO.Leveling.SyncXP(ply)
end

---------------------------------------------------------------------------
-- Синхронизация XP
---------------------------------------------------------------------------

function WO.Leveling.SyncXP(ply)
    if not IsValid(ply) then return end

    local char = ply:GetCharacter()

    if not char then return end

    WO.Net.Send("Leveling.Sync", ply, {
        level = char.level or 1,
        experience = char.experience or 0,
        needed = WO.Config.GetXPForLevel(char.level or 1),
    })
end

WO.Hook.Add("CharacterSync", "leveling", function(char, ply)
    WO.Leveling.SyncXP(ply)
end)
