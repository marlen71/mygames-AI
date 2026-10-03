--[[
    Legacy tombstone for old saves that used arcane_hands as an item.
    Mages now receive weapon_hpwr_stick directly; it is not inventory/equipment.
]]
WO.Items.Register({
    id = "arcane_hands",
    name = "Legacy arcane hands (not an item)",
    type = "weapon",
    category = "magic",
    noInventory = true,
    legacyStarter = true,
    description = "This legacy inventory definition is disabled; the class loadout grants its SWEP.",
    stackable = false,
    stats = {},
})
