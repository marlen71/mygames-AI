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
    self.yaw = 0
    -- zoom — множитель относительно рассчитанной по bounds дистанции, а не
    -- фиксированные Source units (фиксированные 70 обрезали ростовые модели).
    self.zoom = 1
    self.previewFOV = 32
    self.woModelAvailable = false
    self:SetFOV(self.previewFOV)
    self:SetAnimated(true)

    -- Preview cards should visibly rotate without requiring an extra toggle.
    self.spin = true
    self.dragging = false
end

local PREVIEW_RETRY_INTERVAL = 0.75

local function IsModelMounted(modelPath)
    if not isstring(modelPath) or modelPath == "" then return false end

    -- DModelPanel uses the local model cache directly. No Workshop registry or
    -- package lookup is required; the character picker/server validate eligibility.
    if util and isfunction(util.IsValidModel) then
        return util.IsValidModel(modelPath) == true
    end

    return WO.Models and WO.Models.Exists and WO.Models.Exists(modelPath) == true or false
end

local function SchedulePreviewRetry(self)
    self.woModelAvailable = false
    self.nextModelRetry = CurTime() + PREVIEW_RETRY_INTERVAL
end

function MODEL:ClearPreviewModel()
    if IsValid(self.Entity) then
        self.Entity:Remove()
    end

    self.Entity = nil
    self.currentModel = nil
    self.requestedModel = nil
    self.nextModelRetry = nil
    self.woModelAvailable = false
end

function MODEL:TrySetPreviewModel(modelPath)
    if not IsModelMounted(modelPath) then
        SchedulePreviewRetry(self)
        return false
    end

    if IsValid(self.Entity) then
        self.Entity:Remove()
    end

    self.Entity = nil
    local ok = pcall(self.SetModel, self, modelPath)

    if ok and IsValid(self.Entity) then
        self.currentModel = modelPath
        self.woModelAvailable = true
        self.nextModelRetry = nil

        if istable(self.pendingCustomization) then
            self:ApplyCustomization(self.pendingCustomization)
        end

        return true
    end

    self.currentModel = nil
    if IsValid(self.Entity) then
        self.Entity:Remove()
    end
    self.Entity = nil
    SchedulePreviewRetry(self)
    return false
end

function MODEL:SetPreviewModel(modelPath)
    if not isstring(modelPath) or modelPath == "" then
        self:ClearPreviewModel()
        return false
    end

    if self.currentModel == modelPath and IsValid(self.Entity) then
        self.requestedModel = modelPath
        self.woModelAvailable = true
        return true
    end

    self.requestedModel = modelPath

    if IsValid(self.Entity) then
        self.Entity:Remove()
    end

    self.Entity = nil
    self.currentModel = nil
    self.woModelAvailable = false
    return self:TrySetPreviewModel(modelPath)
end

function MODEL:PaintOver(w, h)
    if not IsValid(self.Entity) then
        draw.RoundedBox(WO.UI.Metrics.radius, 0, 0, w, h, WO.UI.Colors.panelDark)
        WO.UI.DrawTextFit(WO.Lang:Get("character.model_preview_unavailable"), "WO.Body",
            w / 2, h / 2, WO.UI.Colors.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
            w - 32, h - 24)
        return
    end

    surface.SetDrawColor(WO.UI.Colors.borderLight)
    surface.DrawOutlinedRect(0, 0, w, h, 1)
end

function MODEL:LayoutEntity(ent)
    if self.spin and not self.dragging then
        local frameTime = FrameTime and FrameTime() or 0
        self.yaw = (self.yaw + frameTime * 12) % 360
    end

    -- Камера находится со стороны -Forward(), поэтому лицо должно смотреть
    -- туда же: разворачиваем исходную ориентацию модели на 180 градусов.
    ent:SetAngles(Angle(0, (self.yaw + 180) % 360, 0))

    -- Не проигрывать анимации — статичная поза
    if self:GetAnimated() then
        ent:FrameAdvance(0)
    end
end

function MODEL:RotateBy(degrees)
    self.yaw = (self.yaw + (tonumber(degrees) or 0)) % 360
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

        self.yaw = (self.yaw + dx * 0.6) % 360
        self._lastX = x
    else
        self._lastX = x
    end
end

function MODEL:OnMouseWheeled(delta)
    -- Колесо вверх — приблизить, вниз — отдалить.
    self.zoom = math.Clamp(self.zoom + delta * 0.08, 0.6, 1.8)

    return true
end

function MODEL:Think()
    local ent = self.Entity

    if not IsValid(ent) and isstring(self.requestedModel) and self.requestedModel ~= "" and
        CurTime() >= (self.nextModelRetry or 0) then
        self:TrySetPreviewModel(self.requestedModel)
        ent = self.Entity
    end

    if not IsValid(ent) then return end

    local mins, maxs = ent:GetModelBounds()
    local size = maxs - mins
    local height = math.max(size.z, 32)
    local center = Vector((mins.x + maxs.x) * 0.5, (mins.y + maxs.y) * 0.5,
        mins.z + height * 0.52)
    local halfFOV = math.rad(self.previewFOV * 0.5)
    local tangent = math.max(math.tan(halfFOV), 0.01)
    local verticalDistance = (height * 0.5) / tangent
    local diagonal = math.sqrt(size.x * size.x + size.y * size.y + size.z * size.z)
    local fitDistance = math.max(verticalDistance, diagonal * 1.08) * 1.18
    local distance = fitDistance / self.zoom

    self:SetLookAt(center)

    -- Keep the camera in a fixed position. Only the model rotates, so every
    -- button press and drag changes the viewed side instead of chasing it.
    local cameraDirection = Angle(6, 0, 0):Forward()
    local cameraPos = center - cameraDirection * distance + Vector(0, 0, height * 0.025)

    self:SetCamPos(cameraPos)
end

--[[
    Применяет кастомизацию к превью: skin, bodygroups, color.
]]
function MODEL:ApplyCustomization(customization)
    customization = istable(customization) and customization or {}
    self.pendingCustomization = table.Copy(customization)

    local ent = self.Entity
    if not IsValid(ent) then return false end

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

    return true
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

    if isfunction(panel.SetPreviewModel) then
        panel:SetPreviewModel(modelPath)
    elseif isstring(modelPath) and modelPath ~= "" and IsModelMounted(modelPath) then
        panel:SetModel(modelPath)
    end

    return panel
end
