--[[
    Warcraft Online — валюта (shared): регистрация net-сообщений и форматирование.
]]

---------------------------------------------------------------------------
-- Форматирование (gold/silver/copper) — используется HUD и UI
---------------------------------------------------------------------------

--[[
    Форматирует сумму медных монет в строку "Xg Ys Zc".

    @param amount number
    @return string
]]
function WO.Currency.FromCoins(gold, silver, copper)
    local economy = WO.Config and WO.Config.Economy or {}
    local copperPerSilver = math.max(1, math.floor(tonumber(economy.CopperPerSilver) or 100))
    local silverPerGold = math.max(1, math.floor(tonumber(economy.SilverPerGold) or 100))

    return math.max(0,
        math.floor(tonumber(gold) or 0) * copperPerSilver * silverPerGold +
        math.floor(tonumber(silver) or 0) * copperPerSilver +
        math.floor(tonumber(copper) or 0))
end

function WO.Currency.Format(amount)
    amount = math.max(0, math.floor(tonumber(amount) or 0))

    local economy = WO.Config and WO.Config.Economy or {}
    local copperPerSilver = math.max(1, math.floor(tonumber(economy.CopperPerSilver) or 100))
    local silverPerGold = math.max(1, math.floor(tonumber(economy.SilverPerGold) or 100))
    local copperPerGold = copperPerSilver * silverPerGold
    local gold = math.floor(amount / copperPerGold)
    local silver = math.floor((amount % copperPerGold) / copperPerSilver)
    local copper = amount % copperPerSilver

    local parts = {}

    if gold > 0 then
        parts[#parts + 1] = gold .. "g"
    end

    if silver > 0 or gold > 0 then
        parts[#parts + 1] = silver .. "s"
    end

    parts[#parts + 1] = copper .. "c"

    return table.concat(parts, " ")
end

---------------------------------------------------------------------------
-- Net
---------------------------------------------------------------------------

WO.Net.Register("Currency.Sync", {
    direction = "toclient",
    write = function(amount)
        local value = math.max(0, math.floor(tonumber(amount) or 0))
        net.WriteUInt(math.min(value, 4294967295), 32)
    end,
    read = function()
        return net.ReadUInt(32)
    end,
    handler = function(_, amount)
        WO.Currency.ClientAmount = amount

        WO.Hook.Run("CurrencySynced", amount)
    end,
})

if CLIENT then
    WO.Hook.Add("CharacterMenuOpening", "currency_client_clear", function()
        WO.Currency.ClientAmount = nil
    end)
end
