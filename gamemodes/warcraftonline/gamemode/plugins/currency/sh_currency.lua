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
function WO.Currency.Format(amount)
    amount = math.max(0, math.floor(tonumber(amount) or 0))

    local gold = math.floor(amount / 10000)
    local silver = math.floor((amount % 10000) / 100)
    local copper = amount % 100

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
        net.WriteUInt(math.max(0, math.floor(tonumber(amount) or 0)), 32)
    end,
    read = function()
        return net.ReadUInt(32)
    end,
    handler = function(_, amount)
        WO.Currency.ClientAmount = amount

        WO.Hook.Run("CurrencySynced", amount)
    end,
})
