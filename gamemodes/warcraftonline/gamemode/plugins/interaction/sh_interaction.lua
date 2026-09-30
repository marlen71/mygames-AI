--[[
    Warcraft Online — взаимодействие (shared): интерфейс и net-сообщения.
]]

WO.Interaction = WO.Interaction or {}

--[[
    Проверяет, может ли сущность взаимодействовать (общий интерфейс).

    Любой entity может реализовать:
        Entity:CanInteract(ply) → boolean
        Entity:GetInteractionText(ply) → string
        Entity:Interact(ply)

    Если методов нет — взаимодействие невозможно.
]]
function WO.Interaction.CanInteract(ent, ply)
    if not IsValid(ent) or not IsValid(ply) then return false end

    if isfunction(ent.CanInteract) then
        local ok, result = pcall(ent.CanInteract, ent, ply)

        return ok and result == true
    end

    return false
end

--[[
    Текст подсказки для UI.
]]
function WO.Interaction.GetText(ent, ply)
    if not IsValid(ent) then return "" end

    if isfunction(ent.GetInteractionText) then
        local ok, text = pcall(ent.GetInteractionText, ent, ply)

        if ok and isstring(text) then
            return text
        end
    end

    return WO.Lang:Get("interact.use")
end

---------------------------------------------------------------------------
-- Серверная обработка запроса взаимодействия
---------------------------------------------------------------------------

--[[
    Серверная проверка и выполнение взаимодействия.
    ВСЕГДА валидирует дистанцию и CanInteract — клиенту не доверяем.
]]
function WO.Interaction.TryInteract(ply, ent)
    if not IsValid(ply) or not IsValid(ent) then return false end

    -- Дистанция (жёсткая серверная проверка)
    if ply:GetPos():Distance(ent:GetPos()) > (WO.Config.InteractDistance or 100) * 1.25 then
        return false
    end

    if not WO.Interaction.CanInteract(ent, ply) then
        return false
    end

    if not isfunction(ent.Interact) then
        return false
    end

    local ok, err = pcall(ent.Interact, ent, ply)

    if not ok then
        WO.Error("Interaction failed on " .. ent:GetClass() .. ": " .. tostring(err))
        return false
    end

    return true
end

---------------------------------------------------------------------------
-- Net: запрос взаимодействия (запасной путь, помимо +use)
---------------------------------------------------------------------------

WO.Net.Register("Interact.Request", {
    direction = "toserver",
    rate = { max = 5, window = 1 },
    write = function(entIndex)
        net.WriteUInt(entIndex or 0, 16)
    end,
    read = function()
        return net.ReadUInt(16)
    end,
    validate = function(ply, entIndex)
        if not IsValid(ply) or not ply:HasCharacter() then return false, "no_character" end
        if not isnumber(entIndex) or entIndex <= 0 then return false, "invalid_entity" end

        return true
    end,
    handler = function(ply, entIndex)
        local ent = Entity(entIndex)

        if not IsValid(ent) then return end

        WO.Interaction.TryInteract(ply, ent)
    end,
})
