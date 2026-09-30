--[[
    Warcraft Online — 3D-превью персонажа (client).
    Используется в Character Creation и Character Menu.

    Возможности:
        - вращение персонажа мышью;
        - приближение/отдаление колесом;
        - смена модели;
        - применение bodygroups/skin в реальном времени;
        - плавное вращение (опционально).
]]

local MODEL = {}

AccessorFunc(MODEL, "yaw", "Yaw", FORCE_NUMBER)
AccessorFunc(MODEL, "zoom", "Zoom", FORCE_NUMBER)

function MODEL:Init()
    self.yaw = 30
    self.zoom = 70
    self:SetFOV(35)
    self:SetAnimated(true)

    self.spin = false
    self.dragging = false
end

function MODEL:LayoutEntity(ent)
    if self.spin and not self.dragging then
        self.yaw = self.yaw + FrameTime() * 12
    end

    ent:SetAngles(Angle(0, self.yaw, 0))

    -- Не проигрывать анимации — статичная поза
    if self:GetAnimated() then
        ent:FrameAdvance(0)
    end
end

function MODEL:OnMousePressed(code)
    if code == MOUSE_LEFT then
        self.dragging = true
        self:MouseCapture(true)
    end
end

function MODEL:OnMouseReleased(code)
    if code == MOUSE_LEFT then
        self.dragging = false
        self:MouseCapture(false)
    end
end

function MODEL:OnCursorMoved(x, y)
    if self.dragging then
        local dx = x - (self._lastX or x)

        self.yaw = self.yaw + dx * 0.6
        self._lastX = x
    else
        self._lastX = x
    end
end

function MODEL:OnMouseWheeled(delta)
    self.zoom = math.Clamp(self.zoom - delta * 6, 20, 160)

    return true
end

function MODEL:Think()
    local ent = self.Entity

    if not IsValid(ent) then return end

    -- Камера: дистанция zoom, прицел по центру модели
    local mins, maxs = ent:GetModelBounds()
    local center = (mins + maxs) / 2

    self:SetLookAt(center + Vector(0, 0, 10))

    local campos = center + Vector(0, 0, 8) + Angle(5, self.yaw, 0):Forward() * -self.zoom

    self:SetCamPos(campos)
end

--[[
    Применяет кастомизацию к превью: skin, bodygroups, color.
]]
function MODEL:ApplyCustomization(customization)
    local ent = self.Entity

    if not IsValid(ent) then return end

    customization = customization or {}

    ent:SetSkin(math.max(0, math.floor(tonumber(customization.skin) or 0)))

    if istable(customization.bodygroups) then
        -- Сброс
        for i = 0, ent:GetNumBodyGroups() - 1 do
            ent:SetBodygroup(i, 0)
        end

        for bgId, value in pairs(customization.bodygroups) do
            local id = tonumber(bgId)

            if id then
                ent:SetBodygroup(id, math.max(0, math.floor(tonumber(value) or 0)))
            end
        end
    end

    if istable(customization.color) then
        local c = customization.color

        ent:SetColor(Color(tonumber(c.r) or 255, tonumber(c.g) or 255, tonumber(c.b) or 255, tonumber(c.a) or 255))
    end
end

vgui.Register("WO_CharacterModel", MODEL, "DModelPanel")

---------------------------------------------------------------------------
-- Фабрика
---------------------------------------------------------------------------

--[[
    Создаёт панель превью персонажа.

    @param parent Panel
    @param modelPath string
    @return Panel WO_CharacterModel
]]
function WO.UI.CreateCharacterModel(parent, modelPath)
    local panel = vgui.Create("WO_CharacterModel", parent)

    if modelPath then
        panel:SetModel(modelPath)
    end

    return panel
end
