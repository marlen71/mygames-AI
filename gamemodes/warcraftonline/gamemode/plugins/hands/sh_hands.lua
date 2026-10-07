--[[
    Warcraft Online — viewmodel hands (shared).

    Используем зарегистрированное соответствие модели игрока, когда оно есть.
    WoW-модели без player_manager mapping получают базовые GMod c_arms — это
    совместимый путь Draconic Base; никаких неподтверждённых моделей рук здесь нет.
]]

local function ApplyHands(ply, handsEntity)
    if not IsValid(ply) or not IsValid(handsEntity) then return end

    local info
    local manager = rawget(_G, "player_manager")

    if istable(manager) and isfunction(manager.TranslatePlayerHands) then
        local modelNames = { ply:GetModel() }

        if isfunction(manager.TranslateToPlayerModelName) then
            local ok, translated = pcall(manager.TranslateToPlayerModelName, ply:GetModel())

            if ok and isstring(translated) and translated ~= "" and translated ~= modelNames[1] then
                table.insert(modelNames, 1, translated)
            end
        end

        for _, modelName in ipairs(modelNames) do
            local ok, result = pcall(manager.TranslatePlayerHands, modelName)

            if ok and istable(result) and isstring(result.model) and result.model ~= "" then
                info = result
                break
            end
        end
    end

    local model = info and info.model or WO.Config.DefaultHandsModel or "models/weapons/c_arms.mdl"
    handsEntity:SetModel(model)
    handsEntity:SetSkin(info and tonumber(info.skin) or 0)

    if info and info.body and handsEntity.SetBodyGroups then
        handsEntity:SetBodyGroups(info.body)
    end
end

-- This gamemode hook is the engine's supported customization point for hands.
function GM:PlayerSetHandsModel(ply, handsEntity)
    ApplyHands(ply, handsEntity)
end

WO.Hands = WO.Hands or {}
WO.Hands.Apply = ApplyHands
