--[[
    Warcraft Online — цель (client): Tab targeting + target frame helpers.
]]

-- Tab: ближайшая валидная цель в конусе перед игроком
local function FindTarget()
    local ply = LocalPlayer()

    if not IsValid(ply) then return nil end

    local eyePos = ply:GetShootPos()
    local aim = ply:GetAimVector()

    local bestEnt = nil
    local bestScore = math.huge

    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and ent ~= ply and not ent:IsWorld() then
            local isTargetable = (ent:IsPlayer() and ent:Alive()) or ent:IsNPC() or ent.CanInteract ~= nil

            if isTargetable then
                local pos = ent:GetPos() + Vector(0, 0, 40)
                local dist = eyePos:Distance(pos)

                if dist < 3000 then
                    local dir = (pos - eyePos):GetNormalized()
                    local dot = aim:Dot(dir)

                    -- Конус примерно 60 градусов
                    if dot > 0.6 then
                        local score = dist * (2 - dot)

                        if score < bestScore then
                            bestScore = score
                            bestEnt = ent
                        end
                    end
                end
            end
        end
    end

    return bestEnt
end

local targetingKey = rawget(_G, WO.Config.TargetingKeyName or "KEY_F3") or rawget(_G, "KEY_F1")

if targetingKey then
    WO.UI.BindKey(targetingKey, function()
        local ply = LocalPlayer()

        if not IsValid(ply) or not ply:HasCharacter() then return end

        -- Повторное нажатие сбрасывает цель; иначе выбирается ближайшая.
        local current = ply:GetNW2Entity("wo_target")

        if IsValid(current) then
            WO.Net.SendToServer("Target.Set", 0)
        else
            local target = FindTarget()
            WO.Net.SendToServer("Target.Set", IsValid(target) and target:EntIndex() or 0)
        end
    end, "targeting_cycle")
end

--- Возвращает текущую цель локального игрока.
function WO.Target.Get()
    local ply = LocalPlayer()

    if not IsValid(ply) then return nil end

    local target = ply:GetNW2Entity("wo_target")

    return IsValid(target) and target or nil
end
