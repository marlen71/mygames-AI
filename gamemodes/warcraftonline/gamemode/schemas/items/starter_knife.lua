--[[
    Warcraft Online — слабый стартовый нож.
    Модель TFA CS:O используется только если установленный SWEP реально содержит
    knife в имени и его view/world model смонтированы; урон остаётся WO-оружием.
]]

local config = WO.Config.StarterKnife or {}
local _, worldModel = WO.Workshop.WeaponModelPair(
    "cso_part1",
    config.fallbackViewModel or "models/weapons/c_crowbar.mdl",
    config.fallbackWorldModel or "models/weapons/w_crowbar.mdl"
)

WO.Items.Register({
    id = "starter_knife",
    name = "Тренировочный нож",
    type = "weapon",
    category = "dagger",

    model = worldModel,
    weight = 0.8,
    size = { w = 1, h = 2 },
    stackable = false,
    rarity = "common",
    durability = config.durability or 55,

    description = "Слабое стартовое оружие. Урон контролируется сервером Warcraft Online.",

    weapon = {
        class = "wo_knife_starter",
        damage = config.damage or 6,
        range = config.range or 62,
        attackSpeed = config.attackSpeed or 1.1,
    },

    equipment = { slot = "main_hand" },
    stats = {},
    requirements = { level = 1 },
    price = { buy = 12, sell = 3 },
})
