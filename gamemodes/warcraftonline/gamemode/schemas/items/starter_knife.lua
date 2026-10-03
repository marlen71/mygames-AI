--[[
    Legacy tombstone for old saves that used starter_knife as an item.
    New starter weapons are granted directly by WO.Loadout and never enter a
    container or equipment slot. Deserialize/AddItem safely discard old records.
]]
WO.Items.Register({
    id = "starter_knife",
    name = "Legacy starter knife (not an item)",
    type = "weapon",
    category = "dagger",
    noInventory = true,
    legacyStarter = true,
    description = "This legacy inventory definition is disabled; the class loadout grants its SWEP.",
    stackable = false,
    stats = {},
})
