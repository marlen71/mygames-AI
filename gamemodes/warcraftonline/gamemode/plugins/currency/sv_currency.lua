--[[
    Warcraft Online — система валюты (server).
    Единая currency-система с возможностью расширения (gold/silver/copper
    как единицы: 1 gold = 100 silver = 10000 copper — конвертация в UI).

    Клиент НИКОГДА не меняет деньги напрямую.
]]

WO.Currency.Types = WO.Currency.Types or {
    copper = { nameKey = "currency.name", rate = 1 },
}

-- Номиналы в медных монетах; одинаковы для экономики и форматирования.
local economy = WO.Config and WO.Config.Economy or {}
local COPPER_PER_SILVER = math.max(1, math.floor(tonumber(economy.CopperPerSilver) or 100))
local SILVER_PER_GOLD = math.max(1, math.floor(tonumber(economy.SilverPerGold) or 100))
local MAX_BALANCE = math.max(1, math.floor(tonumber(economy.MaxBalance) or 4294967295))
local MAX_TRANSACTION = math.max(1, math.floor(tonumber(economy.MaxTransaction) or 100000000))

WO.Currency.MAX_BALANCE = MAX_BALANCE
WO.Currency.MAX_TRANSACTION = MAX_TRANSACTION
WO.Currency.Display = {
    gold = COPPER_PER_SILVER * SILVER_PER_GOLD,
    silver = COPPER_PER_SILVER,
    copper = 1,
}

--[[
    Возвращает баланс персонажа.

    @param ply Player|table character
    @return number
]]
function WO.Currency.Get(ply)
    local char = WO.Character.IsCharacter(ply) and ply or (IsValid(ply) and ply:GetCharacter())

    if not char then return 0 end

    return math.Clamp(math.floor(tonumber(char.money) or 0), 0, MAX_BALANCE)
end

--[[
    Проверяет, хватает ли средств.

    @param ply Player
    @param amount number
    @return boolean
]]
function WO.Currency.CanAfford(ply, amount)
    amount = tonumber(amount)
    return amount ~= nil and amount >= 0 and WO.Currency.Get(ply) >= amount
end

--[[
    Начисляет деньги (серверная операция).

    @param ply Player
    @param amount number
    @param reason string|nil причина (для логов)
    @return boolean success
]]
function WO.Currency.Add(ply, amount, reason)
    if not IsValid(ply) then return false end

    local char = ply:GetCharacter()

    if not char then return false end

    amount = math.floor(tonumber(amount) or 0)

    if amount <= 0 then return false end

    -- Ограничения предотвращают переполнение сетевого UInt32/баланса персонажа.
    local current = math.Clamp(math.floor(tonumber(char.money) or 0), 0, MAX_BALANCE)
    if amount > MAX_TRANSACTION or amount > MAX_BALANCE - current then
        WO.Warn("Suspicious currency add from " .. ply:Nick() .. ": " .. amount)
        return false
    end

    char.money = current + amount

    WO.SaveQueue.MarkDirty(char)
    WO.Currency.Sync(ply)

    WO.Debug("Currency add: " .. ply:Nick() .. " +" .. amount .. (reason and (" (" .. reason .. ")") or ""))

    WO.Hook.Run("CurrencyChanged", char, char.money)

    return true
end

--[[
    Списывает деньги (серверная операция).

    @param ply Player
    @param amount number
    @return boolean success, string|nil reason
]]
function WO.Currency.Take(ply, amount)
    if not IsValid(ply) then return false, "invalid_player" end

    local char = ply:GetCharacter()

    if not char then return false, "no_character" end

    amount = math.floor(tonumber(amount) or 0)

    if amount < 0 then return false, "invalid_amount" end
    if amount == 0 then return true end
    if amount > MAX_TRANSACTION then return false, "transaction_limit" end

    local current = math.Clamp(math.floor(tonumber(char.money) or 0), 0, MAX_BALANCE)
    if current < amount then
        return false, "not_enough_money"
    end

    char.money = current - amount

    WO.SaveQueue.MarkDirty(char)
    WO.Currency.Sync(ply)

    WO.Debug("Currency take: " .. ply:Nick() .. " -" .. amount)

    WO.Hook.Run("CurrencyChanged", char, char.money)

    return true
end

--[[
    Переводит деньги между игроками.
]]
function WO.Currency.Transfer(from, to, amount)
    if not IsValid(from) or not IsValid(to) then return false, "invalid_player" end

    amount = math.floor(tonumber(amount) or 0)

    if amount <= 0 then return false, "invalid_amount" end

    local toChar = to:GetCharacter()
    local toBalance = math.max(0, math.floor(tonumber(toChar and toChar.money) or 0))
    if amount > MAX_TRANSACTION or amount > MAX_BALANCE - toBalance then
        return false, "balance_limit"
    end

    local ok, reason = WO.Currency.Take(from, amount)
    if not ok then return false, reason end

    local added, addReason = WO.Currency.Add(to, amount, "transfer")
    if not added then
        WO.Currency.Add(from, amount, "transfer_rollback")
        return false, addReason or "transfer_failed"
    end

    return true
end

---------------------------------------------------------------------------
-- Синхронизация
---------------------------------------------------------------------------

function WO.Currency.Sync(ply)
    if not IsValid(ply) then return end

    local char = ply:GetCharacter()

    if not char then return end

    WO.Net.Send("Currency.Sync", ply,
        math.Clamp(math.floor(tonumber(char.money) or 0), 0, MAX_BALANCE))
end

WO.Hook.Add("CharacterSync", "currency", function(char, ply)
    WO.Currency.Sync(ply)
end)

---------------------------------------------------------------------------
-- Установка (админ)
---------------------------------------------------------------------------

function WO.Currency.Set(ply, amount)
    if not IsValid(ply) then return false end

    local char = ply:GetCharacter()

    if not char then return false end

    char.money = math.Clamp(math.floor(tonumber(amount) or 0), 0, MAX_BALANCE)

    WO.SaveQueue.MarkDirty(char)
    WO.Currency.Sync(ply)

    WO.Hook.Run("CurrencyChanged", char, char.money)

    return true
end

---------------------------------------------------------------------------
-- Форматирование (gold/silver/copper) — см. sh_currency.lua (shared)
---------------------------------------------------------------------------
