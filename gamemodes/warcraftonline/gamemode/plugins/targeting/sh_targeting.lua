--[[
    Warcraft Online — цель (shared): net-сообщения и API.
]]

WO.Target = WO.Target or {}

WO.Net.Register("Target.Set", {
    direction = "toserver",
    rate = { max = 10, window = 1 },
    write = function(entIndex)
        net.WriteUInt(entIndex or 0, 16)
    end,
    read = function()
        return net.ReadUInt(16)
    end,
    validate = function(ply)
        return IsValid(ply) and ply:HasCharacter()
    end,
    handler = function(ply, entIndex)
        local ent = entIndex > 0 and Entity(entIndex) or nil

        if IsValid(ent) then
            -- Валидация цели: игроки, NPC, сущности с интерфейсом
            local valid = ent:IsPlayer() or ent:IsNPC() or ent.CanInteract ~= nil

            if not valid then
                ent = nil
            elseif ent == ply then
                ent = nil
            elseif ent:GetPos():Distance(ply:GetPos()) > 5000 then
                ent = nil
            end
        end

        ply.WOTarget = ent
        ply:SetNW2Entity("wo_target", ent)
    end,
})
