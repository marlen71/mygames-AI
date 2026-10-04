--[[ Одноразовое улучшение брони конкретного маунта. ]]

WO.Items.Register({
    id = "mount_barding",
    name = "Комплект брони для лошади",
    type = "consumable",
    category = "mount",
    model = "models/props_c17/TrapPropeller_Engine.mdl",
    weight = 1.5,
    stackable = true,
    maxStack = 5,
    rarity = "rare",
    description = "Повышает уровень брони принадлежащей вам лошади. Максимум три улучшения.",
    consumeOnUse = true,
    useHandler = function(ply, instance)
        if not (WO.Mounts and WO.Mounts.UpgradeArmor) then return false, "mounts_unavailable" end
        return WO.Mounts.UpgradeArmor(ply, instance)
    end,
    price = { buy = 180, sell = 0 },
})
