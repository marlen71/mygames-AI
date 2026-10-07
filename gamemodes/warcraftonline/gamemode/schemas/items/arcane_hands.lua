--[[
    Legacy tombstone for old saves that used arcane_hands as an item.
    Mages use wo_magic_grimoire and Warcraft Online's own spell system.
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
