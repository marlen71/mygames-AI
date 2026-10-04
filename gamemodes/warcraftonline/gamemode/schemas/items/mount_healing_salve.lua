--[[ Одноразовый лечебный бальзам для принадлежащего игроку маунта. ]]

WO.Items.Register({
    id = "mount_healing_salve",
    name = "Лечебный бальзам для маунта",
    type = "consumable",
    category = "mount",
    model = "models/healthvial.mdl",
    weight = 0.4,
    stackable = true,
    maxStack = 10,
    rarity = "uncommon",
    description = "Восстанавливает здоровье вашей лошади; работает и когда она отозвана.",
    consumeOnUse = true,
    useHandler = function(ply, instance)
        if not (WO.Mounts and WO.Mounts.Heal) then return false, "mounts_unavailable" end
        return WO.Mounts.Heal(ply, instance)
    end,
    price = { buy = 35, sell = 0 },
})
