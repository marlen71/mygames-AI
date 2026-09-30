--[[
    Warcraft Online — общие методы Player (shared).
    Player ссылается на активного персонажа, НЕ хранит character state в себе.

        ply:GetCharacter()   → table character | nil
        ply:SetCharacter(c)
        ply:HasCharacter()   → boolean
        ply:GetCharID()      → string | nil
]]

local PLAYER = FindMetaTable("Player")

if not PLAYER then
    WO.Error("Player metatable not found!")
    return
end

--[[
    Возвращает активного персонажа игрока.
    На сервере — runtime-объект; на клиенте — локальный кэш.
]]
function PLAYER:GetCharacter()
    if SERVER then
        return self.WOCharacter
    end

    return WO.Character.Local
end

--- Устанавливает активного персонажа (runtime-ссылка).
function PLAYER:SetCharacter(char)
    if SERVER then
        self.WOCharacter = char

        if char then
            char.player = self
        end
    end
end

--- Есть ли у игрока активный персонаж.
function PLAYER:HasCharacter()
    return self:GetCharacter() ~= nil
end

--- ID активного персонажа.
function PLAYER:GetCharID()
    local char = self:GetCharacter()

    return char and char.id or nil
end

--- Полное имя персонажа (для UI/HUD).
function PLAYER:NickChar()
    local char = self:GetCharacter()

    if char then
        return char:GetFullName()
    end

    return self:Nick()
end

--- Уровень персонажа.
function PLAYER:GetCharLevel()
    local char = self:GetCharacter()

    return char and char:GetLevel() or 1
end

---------------------------------------------------------------------------
-- Немногочисленные NW2-переменные (оправданы: видны всем клиентам для HUD)
---------------------------------------------------------------------------

-- wo_name, wo_level, wo_race, wo_class — для target frame / overhead
-- wo_mana, wo_stamina — vitals (клиентский HUD)
-- wo_char_active — у игрока загружен персонаж

--- Уровень (NW2, для чужих target frames).
function PLAYER:GetNetLevel()
    return self:GetNW2Int("wo_level", 1)
end

--- Мана.
function PLAYER:GetMana()
    return self:GetNW2Int("wo_mana", 0)
end

--- Выносливость.
function PLAYER:GetStamina()
    return self:GetNW2Int("wo_stamina", 0)
end
