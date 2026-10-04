--[[
    Warcraft Online — серверно-авторитетный запрос выбора оружия.
    Клиент передаёт только класс; сервер требует активного персонажа и фактическое
    владение соответствующим SWEP перед переключением.
]]

WO.Net.Register("Weapons.Select", {
    direction = "toserver",
    rate = { max = 12, window = 1 },
    write = function(class)
        net.WriteString(class or "")
    end,
    read = function()
        return net.ReadString()
    end,
    validate = function(ply, class)
        if not IsValid(ply) or not isfunction(ply.IsPlayer) or not ply:IsPlayer() or
            not ply:HasCharacter() then
            return false, "no_character"
        end

        if not isstring(class) or #class < 1 or #class > 64 or
            not string.match(class, "^[%w_%-]+$") then
            return false, "invalid_weapon_class"
        end

        if not isfunction(ply.HasWeapon) or not ply:HasWeapon(class) or
            not isfunction(ply.GetWeapon) then
            return false, "weapon_not_owned"
        end

        local weapon = ply:GetWeapon(class)

        if not IsValid(weapon) or not isfunction(weapon.GetClass) or
            weapon:GetClass() ~= class then
            return false, "weapon_not_owned"
        end

        return true
    end,
    handler = function(ply, class)
        if not SERVER or not IsValid(ply) then return end

        -- Repeat the ownership check at the action boundary as defense in depth.
        if not ply:HasCharacter() or not ply:HasWeapon(class) then return end

        local weapon = ply:GetWeapon(class)

        if IsValid(weapon) and weapon:GetClass() == class then
            ply:SelectWeapon(class)
        end
    end,
})
