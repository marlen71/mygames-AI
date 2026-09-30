--[[
    Warcraft Online — система валюты (server).
    Единая currency-система с возможностью расширения (gold/silver/copper
    как единицы: 1 gold = 100 silver = 10000 copper — конвертация в UI).

    Клиент НИКОГДА не меняет деньги напрямую.
]]

WO.Currency.Types = WO.Currency.Types or {
    copper = { nameKey = "currency.name", rate = 1 },
}

-- Конвертация для отображения: 1 gold = 100 silver = 10000 copper
WO.Currency.Display = {
    gold = 10000,
    silver = 100,
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

    return char.money or 0
end

--[[
    Проверяет, хватает ли средств.

    @param ply Player
    @param amount number
    @return boolean
]]
function WO.Currency.CanAfford(ply, amount)
    return WO.Currency.Get(ply) >= (tonumber(amount) or 0)
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

    -- Защита от аномальных сумм
    if amount > 100000000 then
        WO.Warn("Suspicious currency add from " .. ply:Nick() .. ": " .. amount)
        return false
    end

    char.money = (char.money or 0) + amount

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

    if (char.money or 0) < amount then
        return false, "not_enough_money"
    end

    char.money = char.money - amount

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

    local ok, reason = WO.Currency.Take(from, amount)

    if not ok then
        return false, reason
    end

    WO.Currency.Add(to, amount, "transfer")

    return true
end

---------------------------------------------------------------------------
-- Синхронизация
---------------------------------------------------------------------------

function WO.Currency.Sync(ply)
    if not IsValid(ply) then return end

    local char = ply:GetCharacter()

    if not char then return end

    WO.Net.Send("Currency.Sync", ply, char.money or 0)
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

    char.money = math.max(0, math.floor(tonumber(amount) or 0))

    WO.SaveQueue.MarkDirty(char)
    WO.Currency.Sync(ply)

    WO.Hook.Run("CurrencyChanged", char, char.money)

    return true
end

---------------------------------------------------------------------------
-- Форматирование (gold/silver/copper) — см. sh_currency.lua (shared)
---------------------------------------------------------------------------
