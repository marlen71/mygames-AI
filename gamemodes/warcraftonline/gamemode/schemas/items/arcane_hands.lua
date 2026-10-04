--[[
    Legacy tombstone for old saves that used arcane_hands as an item.
    Mages now receive wo_magic_grimoire; weapon_hpwr_stick remains an alternate rollback SWEP.
]]
WO.Items.Register({
    id = "arcane_hands",
    name = "Legacy arcane hands (not an item)",
    type = "weapon",
    category = "magic",
    noInventory = true,
    legacyStarter = true,
    description = "This legacy inventory definition is disabled; mages receive wo_magic_grimoire.",
    stackable = false,
    stats = {},
})
