--[[
    Warcraft Online — жизненный цикл игрока (server).

    PlayerConnected → PlayerInitialSpawn (загрузка списка персонажей)
        → CharacterSelected → CharacterLoaded → CharacterSpawned
        → CharacterSaved / CharacterUnloaded → PlayerDisconnected
]]

---------------------------------------------------------------------------
-- Спавн-точки
---------------------------------------------------------------------------

--- Находит безопасную стартовую позицию на текущей карте.
function WO.FindSpawnPoint()
    local spawns = ents.FindByClass("info_player_start")

    if #spawns > 0 then
        local spawn = spawns[math.random(#spawns)]

        return spawn:GetPos() + Vector(0, 0, 8), spawn:GetAngles()
    end

    -- Фолбэк: центр карты
    return Vector(0, 0, 128), Angle(0, 0, 0)
end

---------------------------------------------------------------------------
-- Лимбо: игрок без персонажа не появляется в мире (см. sv_characters.lua)
---------------------------------------------------------------------------

local function PutInLimbo(ply)
    WO.Character.EnterLimbo(ply)

    local pos = WO.FindSpawnPoint()

    ply:SetPos(pos)
end

local function ReleaseFromLimbo(ply)
    WO.Character.ExitLimbo(ply)
end

---------------------------------------------------------------------------
-- GMod-хуки жизненного цикла
---------------------------------------------------------------------------

hook.Add("PlayerInitialSpawn", "wo_player_initial_spawn", function(ply)
    if not IsValid(ply) then return end

    WO.Log("Player connected: " .. ply:Nick() .. " (" .. ply:SteamID() .. ")")

    PutInLimbo(ply)

    -- Загружаем список персонажей игрока и отправляем клиенту
    local list = WO.Character.LoadList(ply)

    WO.Hook.Run("PlayerConnected", ply)

    -- Отложенный запрос на случай, если клиент ещё не готов принимать net
    timer.Simple(1, function()
        if IsValid(ply) then
            WO.Net.Send("Character.List", ply, list)

            if #list == 0 then
                WO.Net.Send("Character.OpenCreate", ply)
            else
                WO.Net.Send("Character.OpenSelect", ply)
            end
        end
    end)
end)

hook.Add("PlayerSpawn", "wo_player_spawn", function(ply)
    if not IsValid(ply) then return end

    local char = ply:GetCharacter()

    if not char then
        -- Персонаж ещё не выбран — остаёмся в лимбо
        PutInLimbo(ply)
        return
    end

    ReleaseFromLimbo(ply)

    WO.Character.ApplyToPlayer(ply)

    WO.Hook.Run("CharacterSpawned", char, ply)
end)

hook.Add("PlayerLoadout", "wo_player_loadout", function(ply)
    if not IsValid(ply) or not ply:HasCharacter() then
        return true -- ничего не выдаём
    end

    -- Стартовые предметы выдаются при создании персонажа (см. items plugin).
    -- Экипированное оружие восстанавливается из equipment:
    if WO.Equipment and WO.Equipment.ApplyWeapons then
        timer.Simple(0, function()
            if IsValid(ply) then
                WO.Equipment.ApplyWeapons(ply)
            end
        end)
    end

    return true
end)

-- Респавн только по таймеру (стандартное поведение подавляем)
hook.Add("PlayerDeathThink", "wo_death_think", function(ply)
    return true
end)

hook.Add("PlayerDeath", "wo_player_death", function(victim, infl, attacker)
    if not IsValid(victim) then return end

    local char = victim:GetCharacter()

    if char then
        WO.Hook.Run("CharacterDied", char, attacker)
    end

    -- Отправляем death UI
    WO.Net.Send("Character.Death", victim, {
        killer = IsValid(attacker) and (attacker.IsNPC and attacker:GetNW2String("wo_name", attacker:GetClass()) or attacker:Nick()) or nil,
        respawnTime = WO.Config.RespawnTime or 5,
    })

    -- Автоматический респавн
    timer.Create("wo_respawn_" .. victim:UserID(), WO.Config.RespawnTime or 5, 1, function()
        if IsValid(victim) and victim:Alive() == false then
            victim:Spawn()
        end
    end)
end)

hook.Add("PlayerDisconnected", "wo_player_disconnected", function(ply)
    if not IsValid(ply) then return end

    local char = ply:GetCharacter()

    if char then
        WO.Log("Player disconnected: " .. ply:Nick() .. " — saving character " .. char:GetFullName())

        -- Принудительное сохранение при выходе
        WO.SaveQueue.SaveNow(char)
        WO.Character.Unload(ply)
    end

    WO.Hook.Run("PlayerDisconnected", ply)
end)

---------------------------------------------------------------------------
-- Движение / базовые ограничения
---------------------------------------------------------------------------

-- Игрок без персонажа не двигается
hook.Add("SetupMove", "wo_setup_move", function(ply, mv, cmd)
    if IsValid(ply) and not ply:HasCharacter() then
        mv:SetVelocity(vector_origin)
        mv:SetForwardSpeed(0)
        mv:SetSideSpeed(0)
        mv:SetUpSpeed(0)
    end
end)

-- Скорости из конфига применяются при загрузке персонажа (см. ApplyToPlayer)
