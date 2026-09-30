--[[
    Warcraft Online — характеристики (server).
    Применение vitals к игроку, регенерация, синхронизация.
]]

---------------------------------------------------------------------------
-- Vitals: HP / Mana / Stamina
---------------------------------------------------------------------------

--[[
    Применяет рассчитанные статы к Entity Player:
    MaxHealth/Health, mana/stamina (NW2 для HUD).
]]
function WO.Stats.ApplyVitals(ply)
    if not IsValid(ply) then return end

    local char = ply:GetCharacter()

    if not char then return end

    if not WO.Stats.IsStats(char.stats) then
        WO.Stats.Recalculate(char)
    end

    local stats = char.stats

    if not stats then return end

    local maxHealth = math.max(1, stats:Get("maxHealth"))
    local maxMana = math.max(0, stats:Get("maxMana"))
    local maxStamina = math.max(0, stats:Get("maxStamina"))

    ply:SetMaxHealth(maxHealth)

    -- Не восстанавливаем HP при обычном апдейте (кроме полного применения)
    if ply:Health() > maxHealth then
        ply:SetHealth(maxHealth)
    end

    -- При первом применении/повышении уровня — полное здоровье
    if ply._woFullHeal then
        ply:SetHealth(maxHealth)
        ply._woFullHeal = nil
    end

    ply:SetNW2Int("wo_maxmana", maxMana)
    ply:SetNW2Int("wo_mana", math.min(ply:GetMana(), maxMana))

    ply:SetNW2Int("wo_maxstamina", maxStamina)
    ply:SetNW2Int("wo_stamina", math.min(ply:GetStamina(), maxStamina))

    -- Синхронизация статов клиенту
    WO.Net.Send("Stats.Sync", ply, stats:GetNetworkTable())
end

--[[
    Полный пересчёт + применение vitals (после смены экипировки/уровня).
]]
function WO.Stats.Refresh(ply, fullHeal)
    if not IsValid(ply) then return end

    local char = ply:GetCharacter()

    if not char then return end

    WO.Stats.Recalculate(char)

    if fullHeal then
        ply._woFullHeal = true
    end

    WO.Stats.ApplyVitals(ply)
end

---------------------------------------------------------------------------
-- Статы при загрузке персонажа
---------------------------------------------------------------------------

WO.Hook.Add("CharacterLoad", "stats", function(char)
    char.stats = WO.Stats.New(char)
    WO.Stats.Recalculate(char)
end)

WO.Hook.Add("CharacterSelected", "stats", function(char, ply)
    ply._woFullHeal = true
    WO.Stats.ApplyVitals(ply)
end)

---------------------------------------------------------------------------
-- Регенерация (тик раз в секунду, без нагрузки на Think)
---------------------------------------------------------------------------

timer.Create("wo_stats_regen", 1, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:HasCharacter() and ply:Alive() then
            local char = ply:GetCharacter()
            local stats = char and char.stats

            if stats and not ply:InCombat() then
                local maxHealth = ply:GetMaxHealth()

                if ply:Health() < maxHealth then
                    ply:SetHealth(math.min(maxHealth, ply:Health() + (WO.Config.HealthRegen and WO.Config.HealthRegen(stats:GetAll()) or 1)))
                end

                local maxMana = ply:GetNW2Int("wo_maxmana", 0)

                if maxMana > 0 and ply:GetMana() < maxMana then
                    ply:SetNW2Int("wo_mana", math.min(maxMana, ply:GetMana() + (WO.Config.ManaRegen and WO.Config.ManaRegen(stats:GetAll()) or 1)))
                end

                local maxStamina = ply:GetNW2Int("wo_maxstamina", 0)

                if maxStamina > 0 and ply:GetStamina() < maxStamina then
                    ply:SetNW2Int("wo_stamina", math.min(maxStamina, ply:GetStamina() + (WO.Config.StaminaRegen and WO.Config.StaminaRegen(stats:GetAll()) or 2)))
                end
            end
        end
    end
end)
