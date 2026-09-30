--[[
    Warcraft Online — камера от третьего лица (client).

    MMORPG-камера:
        - камера за персонажем;
        - плавное вращение мышью (через eye angles);
        - zoom колесом мыши;
        - камера не проходит сквозь стены (collision);
        - shoulder offset;
        - настраиваемая дистанция/высота/FOV/сглаживание.

    Настройки: WO.Config.Camera* (config/sh_config.lua).
]]

WO.ThirdPerson = WO.ThirdPerson or {}

-- Локальное состояние камеры
local state = {
    distance = WO.Config.CameraDistance or 150,
    smoothPos = nil,
    enabled = true,
}

WO.ThirdPerson.State = state

--[[
    Включает/выключает камеру (например, в меню персонажа).
]]
function WO.ThirdPerson.SetEnabled(bool)
    state.enabled = bool

    if not bool then
        state.smoothPos = nil
    end
end

function WO.ThirdPerson.IsEnabled()
    return state.enabled and not (LocalPlayer():GetNW2Bool("wo_inmenu", false))
end

---------------------------------------------------------------------------
-- Zoom колесом мыши
---------------------------------------------------------------------------

hook.Add("PlayerBindPress", "wo_thirdperson_zoom", function(ply, bind, pressed)
    if not pressed then return end

    if not WO.ThirdPerson.IsEnabled() then return end

    if bind == "invprev" then
        state.distance = math.Clamp(state.distance + 16,
            WO.Config.CameraMinDistance or 60,
            WO.Config.CameraMaxDistance or 400)

        return true
    elseif bind == "invnext" then
        state.distance = math.Clamp(state.distance - 16,
            WO.Config.CameraMinDistance or 60,
            WO.Config.CameraMaxDistance or 400)

        return true
    end
end)

---------------------------------------------------------------------------
-- CalcView — позиционирование камеры
---------------------------------------------------------------------------

hook.Add("CalcView", "wo_thirdperson_view", function(ply, pos, angles, fov)
    if not WO.ThirdPerson.IsEnabled() then return end

    if not IsValid(ply) or not ply:Alive() then return end

    -- Не в транспорте
    if ply:InVehicle() then return end

    local eyePos = ply:GetShootPos() + Vector(0, 0, WO.Config.CameraHeight or 20)

    -- Направление взгляда (мышь вращает eye angles → нашу камеру)
    local forward = angles:Forward()
    local right = angles:Right()
    local up = angles:Up()

    -- Желаемая позиция камеры: за персонажем + смещение в сторону (shoulder)
    local shoulder = WO.Config.CameraShoulder or 0
    local desired = eyePos
        - forward * state.distance
        + right * shoulder

    -- Collision: камера не проходит сквозь стены
    if WO.Config.CameraCollision ~= false then
        local tr = util.TraceLine({
            start = eyePos,
            endpos = desired,
            filter = ply,
            mask = MASK_SOLID,
        })

        if tr.Fraction < 1 then
            desired = tr.HitPos + tr.HitNormal * 6
        end
    end

    -- Плавное сглаживание
    local smooth = WO.Config.CameraSmooth or 0

    if smooth > 0 then
        if state.smoothPos then
            state.smoothPos = LerpVector(math.Clamp(FrameTime() * smooth, 0, 1), state.smoothPos, desired)
        else
            state.smoothPos = desired
        end
    else
        state.smoothPos = desired
    end

    local view = {}

    view.origin = state.smoothPos
    view.angles = angles
    view.fov = WO.Config.CameraFOV or 75
    view.drawviewer = true

    return view
end)

---------------------------------------------------------------------------
-- Персонаж смотрит по камере (MMORPG-style поворот модели)
-- Стандартный movement GMod не ломаем: модель разворачивается сама
-- в сторону движения (аним-система GMod), а при стоянии — к камере.
---------------------------------------------------------------------------

hook.Add("CalcMainActivity", "wo_thirdperson_facing", function(ply, velocity)
    if not WO.ThirdPerson.IsEnabled() then return end

    if ply ~= LocalPlayer() then return end

    -- Модель поворачивается к направлению движения автоматически
    -- (стандартная аним-система GMod). Дополнительная обработка не требуется.
end)
