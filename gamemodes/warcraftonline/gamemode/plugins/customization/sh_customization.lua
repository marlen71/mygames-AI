--[[
    Warcraft Online — система кастомизации (shared).

    ПРИНЦИП: у каждой модели свои bodygroups. Нельзя считать,
    что bodygroup 0 — всегда волосы. Поэтому конфигурация ведётся на модель:

        WO.Customization:RegisterModel("models/player/group01/male_01.mdl", {
            bodygroups = {
                {
                    id = 0,
                    name = "Head",
                    options = {
                        { value = 0, name = "Default" },
                        { value = 1, name = "Alt" },
                    },
                },
            },
            skins = { { value = 0, name = "Default" } },
        })

    Если конфигурация не зарегистрирована, клиент перечисляет bodygroups
    модели автоматически (auto-discovery через ClientsideModel).
]]

WO.Customization.Registry = WO.Customization.Registry or {}

--[[
    Регистрирует конфигурацию кастомизации для модели.

    @param modelPath string
    @param profile table { bodygroups = {...}, skins = {...} }
]]
function WO.Customization.RegisterModel(modelPath, profile)
    if not isstring(modelPath) or not istable(profile) then
        WO.Error("WO.Customization.RegisterModel: invalid arguments")
        return
    end

    profile.bodygroups = profile.bodygroups or {}
    profile.skins = profile.skins or {}

    WO.Customization.Registry[modelPath] = profile
end

--- Возвращает зарегистрированный профиль модели (или nil).
function WO.Customization.GetModelProfile(modelPath)
    return WO.Customization.Registry[modelPath]
end

---------------------------------------------------------------------------
-- Auto-discovery (client): перечисление bodygroups реальной модели
---------------------------------------------------------------------------

local discovered = {}

--[[
    Возвращает список bodygroups модели.
    Если есть конфиг — используется он; иначе — авто-перечисление (клиент).

    @param modelPath string
    @return table массив { id, name, options = { {value, name}, ... } }
]]
function WO.Customization.GetBodygroups(modelPath)
    if not isstring(modelPath) or modelPath == "" then return {} end

    -- Зарегистрированный конфиг имеет приоритет
    local profile = WO.Customization.GetModelProfile(modelPath)

    if profile and #profile.bodygroups > 0 then
        return profile.bodygroups
    end

    -- Авто-перечисление (клиент)
    if CLIENT then
        if discovered[modelPath] then
            return discovered[modelPath]
        end

        local mdl = ClientsideModel(modelPath, RENDERGROUP_OPAQUE)

        if not IsValid(mdl) then
            discovered[modelPath] = {}
            return {}
        end

        local result = {}

        for i = 0, mdl:GetNumBodyGroups() - 1 do
            local options = {}

            for value = 0, mdl:GetBodygroupCount(i) - 1 do
                options[#options + 1] = {
                    value = value,
                    name = value == 0 and "Default" or ("Variant " .. value),
                }
            end

            result[#result + 1] = {
                id = i,
                name = mdl:GetBodygroupName(i) ~= "" and mdl:GetBodygroupName(i) or ("Bodygroup " .. i),
                options = options,
            }
        end

        mdl:Remove()

        discovered[modelPath] = result

        return result
    end

    return {}
end

--[[
    Возвращает список доступных скинов модели.

    @param modelPath string
    @return table массив { value, name }
]]
function WO.Customization.GetSkins(modelPath)
    local profile = WO.Customization.GetModelProfile(modelPath)

    if profile and #profile.skins > 0 then
        return profile.skins
    end

    if CLIENT then
        local mdl = ClientsideModel(modelPath, RENDERGROUP_OPAQUE)

        if IsValid(mdl) then
            local result = {}
            local count = mdl:SkinCount()

            for i = 0, math.max(0, count - 1) do
                result[#result + 1] = {
                    value = i,
                    name = "Skin " .. i,
                }
            end

            mdl:Remove()

            return result
        end
    end

    return { { value = 0, name = "Default" } }
end

---------------------------------------------------------------------------
-- Применение кастомизации
---------------------------------------------------------------------------

--[[
    Применяет кастомизацию к сущности/игроку (skin, bodygroups, color).

    @param ent Entity|Player
    @param customization table { skin, bodygroups, color }
]]
function WO.Customization.Apply(ent, customization)
    if not IsValid(ent) then return end

    customization = customization or {}

    if isnumber(customization.skin) then
        ent:SetSkin(math.max(0, math.floor(customization.skin)))
    end

    if istable(customization.bodygroups) then
        for bgId, value in pairs(customization.bodygroups) do
            local id = tonumber(bgId)

            if id and id >= 0 then
                ent:SetBodygroup(id, math.max(0, math.floor(tonumber(value) or 0)))
            end
        end
    end

    if istable(customization.color) then
        local c = customization.color

        ent:SetColor(Color(
            WO.Util.ClampNumber(c.r, 0, 255),
            WO.Util.ClampNumber(c.g, 0, 255),
            WO.Util.ClampNumber(c.b, 0, 255),
            WO.Util.ClampNumber(c.a, 0, 255)
        ))
    end
end

--[[
    Валидация кастомизации на сервере (границы значений).

    @param modelPath string
    @param customization table
    @return boolean ok, table cleanCustomization
]]
function WO.Customization.Validate(modelPath, customization)
    customization = customization or {}

    local clean = {
        skin = math.max(0, WO.Util.ToInt(customization.skin, 0)),
        bodygroups = {},
        color = nil,
    }

    -- Ограничиваем skin разумным диапазоном
    clean.skin = math.min(clean.skin, 64)

    if istable(customization.bodygroups) then
        local profile = WO.Customization.GetModelProfile(modelPath)

        for bgId, value in pairs(customization.bodygroups) do
            local id = tonumber(bgId)
            local val = tonumber(value)

            if id and val and id >= 0 and id <= 32 and val >= 0 and val <= 64 then
                -- Если есть профиль — проверяем допустимость значения
                local allowed = true

                if profile then
                    for _, bg in ipairs(profile.bodygroups) do
                        if bg.id == id then
                            allowed = false

                            for _, option in ipairs(bg.options or {}) do
                                if option.value == val then
                                    allowed = true
                                    break
                                end
                            end

                            break
                        end
                    end
                end

                if allowed then
                    clean.bodygroups[id] = math.floor(val)
                end
            end
        end
    end

    if istable(customization.color) then
        clean.color = {
            r = WO.Util.ClampNumber(customization.color.r, 0, 255),
            g = WO.Util.ClampNumber(customization.color.g, 0, 255),
            b = WO.Util.ClampNumber(customization.color.b, 0, 255),
            a = WO.Util.ClampNumber(customization.color.a, 0, 255),
        }
    end

    return true, clean
end
