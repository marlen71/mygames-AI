--[[
    Warcraft Online — жизненный цикл игрока (server).

    PlayerConnected → PlayerInitialSpawn (загрузка списка персонажей)
        → CharacterSelected → CharacterLoaded → CharacterSpawned
        → CharacterSaved / CharacterUnloaded → PlayerDisconnected
]]

---------------------------------------------------------------------------
-- Спавн-точки
---------------------------------------------------------------------------

--- Возвращает обычную spawn-точку карты; никаких координат/центра от gamemode.
function WO.FindSpawnPoint(ply)
    local gamemode = GAMEMODE or GM

    if IsValid(ply) and gamemode and isfunction(gamemode.PlayerSelectSpawn) then
        local ok, selected = pcall(gamemode.PlayerSelectSpawn, gamemode, ply)

        if ok and IsValid(selected) then
            return selected:GetPos() + Vector(0, 0, 8), selected:GetAngles()
        end
    end

    local spawnClasses = {
        "info_player_start",
        "info_player_deathmatch",
        "info_player_combine",
        "info_player_rebel",
        "info_player_counterterrorist",
        "info_player_terrorist",
    }
    local spawns, seen = {}, {}

    for _, class in ipairs(spawnClasses) do
        for _, spawn in ipairs(ents.FindByClass(class) or {}) do
            if IsValid(spawn) and not seen[spawn] then
                seen[spawn] = true
                spawns[#spawns + 1] = spawn
            end
        end
    end

    if #spawns == 0 then return nil, nil end

    local spawn = spawns[math.random(#spawns)]

    return spawn:GetPos() + Vector(0, 0, 8), spawn:GetAngles()
end

---------------------------------------------------------------------------
-- Лимбо: игрок без персонажа не появляется в мире (см. sv_characters.lua)
---------------------------------------------------------------------------

local function PutInLimbo(ply)
    WO.Character.EnterLimbo(ply)

    local pos = WO.FindSpawnPoint(ply)

    if isvector(pos) then
        ply:SetPos(pos)
    else
        WO.Warn("No standard map spawn point found; leaving limbo player at engine-selected position")
    end
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

    WO.Hook.Run("PlayerConnected", ply)

    -- Фолбэк: клиент мог не успеть/не ответить — отправляем состояние повторно.
    -- Основной путь — хендшейк Client.Ready (см. sh_character_net.lua).
    timer.Simple(3, function()
        if IsValid(ply) and not ply.wo_client_ready then
            WO.Character.SendState(ply)
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

    if WO.Character.ApplyToPlayer(ply) == false then
        WO.Character.Unload(ply)
        PutInLimbo(ply)
        return
    end

    WO.Hook.Run("CharacterSpawned", char, ply)
end)

---------------------------------------------------------------------------
-- Позиция персонажа: периодически помечаем её для autosave.
---------------------------------------------------------------------------

local function AngleDistance(a, b)
    local delta = (tonumber(a) or 0) - (tonumber(b) or 0)
    delta = math.abs(delta) % 360

    return math.min(delta, 360 - delta)
end

local function StartPositionTracking()
    timer.Create("wo_position_dirty_check", 15, 0, function()
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and ply:HasCharacter() then
                local char = ply:GetCharacter()
                local pos = ply:GetPos()
                local ang = ply:EyeAngles()
                local savedPos = char.pos
                local savedAng = char.ang
                local moved = not isvector(savedPos) or
                    savedPos:DistToSqr(pos) >= (64 * 64)
                local turned = not savedAng or
                    AngleDistance(savedAng.p, ang.p) >= 15 or
                    AngleDistance(savedAng.y, ang.y) >= 15 or
                    AngleDistance(savedAng.r, ang.r) >= 15
                local map = game.GetMap()

                if moved or turned or char.map ~= map then
                    char.pos = Vector(pos.x, pos.y, pos.z)
                    char.ang = Angle(ang.p, ang.y, ang.r)
                    char.map = map
                    WO.SaveQueue.MarkDirty(char)
                end
            end
        end
    end)
end

hook.Add("Initialize", "wo_position_tracking_init", StartPositionTracking)

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
