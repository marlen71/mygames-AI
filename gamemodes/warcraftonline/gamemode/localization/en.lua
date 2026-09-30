--[[
    Warcraft Online — localization: english.
]]

WO.Lang.Register("en", {
    -----------------------------------------------------------------------
    -- Common
    -----------------------------------------------------------------------
    ["ui.ok"] = "OK",
    ["ui.cancel"] = "Cancel",
    ["ui.close"] = "Close",
    ["ui.back"] = "Back",
    ["ui.next"] = "Next",
    ["ui.confirm"] = "Confirm",
    ["ui.delete"] = "Delete",
    ["ui.create"] = "Create",
    ["ui.save"] = "Save",
    ["ui.yes"] = "Yes",
    ["ui.no"] = "No",

    -----------------------------------------------------------------------
    -- Character
    -----------------------------------------------------------------------
    ["character.create"] = "Character Creation",
    ["character.select"] = "Character Selection",
    ["character.create_failed"] = "Failed to create character",
    ["character.select_failed"] = "Failed to select character",
    ["character.deleted"] = "Character deleted",
    ["character.delete_failed"] = "Failed to delete character",
    ["character.delete_confirm"] = "Are you sure you want to delete this character?",
    ["character.no_characters"] = "You have no characters",
    ["character.logout"] = "Leave character",
    ["character.main_menu"] = "Character Menu",
    ["character.menu.create"] = "Create Character",
    ["character.menu.load"] = "Load Character",
    ["character.menu.exit"] = "Exit",
    ["character.no_saved_characters"] = "No saved characters yet",
    ["character.back_to_menu"] = "Back to Menu",
    ["character.rotate_left"] = "Rotate Left",
    ["character.rotate_right"] = "Rotate Right",
    ["character.rotate_hint"] = "Drag the model or use the rotation buttons",

    ["character.step.race"] = "Race",
    ["character.step.gender"] = "Gender",
    ["character.step.age"] = "Age",
    ["character.step.name"] = "Name",
    ["character.step.surname"] = "Surname",
    ["character.step.customization"] = "Appearance",
    ["character.step.class"] = "Class",
    ["character.step.preview"] = "Preview",
    ["character.step.confirm"] = "Confirmation",

    ["character.name"] = "Name",
    ["character.surname"] = "Surname",
    ["character.age"] = "Age",
    ["character.gender"] = "Gender",
    ["character.race"] = "Race",
    ["character.class"] = "Class",
    ["character.model"] = "Model",
    ["character.level"] = "Level",
    ["character.full_name"] = "Full name",

    ["gender.male"] = "Male",
    ["gender.female"] = "Female",

    -----------------------------------------------------------------------
    -- Stats
    -----------------------------------------------------------------------
    ["stats.strength"] = "Strength",
    ["stats.agility"] = "Agility",
    ["stats.intelligence"] = "Intelligence",
    ["stats.stamina"] = "Stamina",
    ["stats.spirit"] = "Spirit",
    ["stats.maxHealth"] = "Health",
    ["stats.maxMana"] = "Mana",
    ["stats.maxStamina"] = "Stamina",
    ["stats.attackPower"] = "Attack Power",
    ["stats.spellPower"] = "Spell Power",
    ["stats.armor"] = "Armor",
    ["stats.magicResistance"] = "Magic Resistance",
    ["stats.critChance"] = "Critical Chance",
    ["stats.critMultiplier"] = "Critical Multiplier",
    ["stats.attackSpeed"] = "Attack Speed",

    -----------------------------------------------------------------------
    -- Inventory / items
    -----------------------------------------------------------------------
    ["inventory.title"] = "Inventory",
    ["inventory.empty"] = "Inventory is empty",
    ["inventory.drop"] = "Drop",
    ["inventory.use"] = "Use",
    ["inventory.equip"] = "Equip",
    ["inventory.unequip"] = "Unequip",
    ["inventory.destroy"] = "Destroy",
    ["inventory.split"] = "Split",
    ["inventory.no_space"] = "Not enough space",
    ["inventory.item_received"] = "Received item: %s",
    ["inventory.item_lost"] = "Item lost: %s",
    ["inventory.full"] = "Inventory is full",

    ["item.type.weapon"] = "Weapon",
    ["item.type.armor"] = "Armor",
    ["item.type.helmet"] = "Helmet",
    ["item.type.boots"] = "Boots",
    ["item.type.gloves"] = "Gloves",
    ["item.type.ring"] = "Ring",
    ["item.type.amulet"] = "Amulet",
    ["item.type.food"] = "Food",
    ["item.type.drink"] = "Drink",
    ["item.type.consumable"] = "Consumable",
    ["item.type.material"] = "Material",
    ["item.type.quest"] = "Quest Item",
    ["item.type.container"] = "Container",
    ["item.type.currency"] = "Currency",
    ["item.type.misc"] = "Miscellaneous",
    ["item.type.special"] = "Special",

    ["item.weight"] = "Weight",
    ["item.damage"] = "Damage",
    ["item.durability"] = "Durability",
    ["item.requirements"] = "Requirements",
    ["item.required_level"] = "Required Level",
    ["item.required_class"] = "Required Class",
    ["item.required_race"] = "Required Race",
    ["item.broken"] = "Broken",
    ["item.stack"] = "Stack",

    ["rarity.poor"] = "Poor",
    ["rarity.common"] = "Common",
    ["rarity.uncommon"] = "Uncommon",
    ["rarity.rare"] = "Rare",
    ["rarity.epic"] = "Epic",
    ["rarity.legendary"] = "Legendary",
    ["rarity.artifact"] = "Artifact",
    ["rarity.quest"] = "Quest",

    -----------------------------------------------------------------------
    -- Equipment slots
    -----------------------------------------------------------------------
    ["slot.head"] = "Head",
    ["slot.neck"] = "Neck",
    ["slot.shoulders"] = "Shoulders",
    ["slot.chest"] = "Chest",
    ["slot.back"] = "Back",
    ["slot.hands"] = "Hands",
    ["slot.belt"] = "Belt",
    ["slot.legs"] = "Legs",
    ["slot.feet"] = "Feet",
    ["slot.main_hand"] = "Main Hand",
    ["slot.off_hand"] = "Off Hand",
    ["slot.ring_1"] = "Ring 1",
    ["slot.ring_2"] = "Ring 2",
    ["slot.amulet"] = "Amulet",

    -----------------------------------------------------------------------
    -- Equipment / menu
    -----------------------------------------------------------------------
    ["equipment.title"] = "Equipment",
    ["character_menu.title"] = "Character",
    ["character_menu.stats"] = "Stats",
    ["character_menu.inventory"] = "Inventory",
    ["character_menu.equipment"] = "Equipment",
    ["character_menu.quests"] = "Quests",

    -----------------------------------------------------------------------
    -- World / interaction
    -----------------------------------------------------------------------
    ["interact.pickup"] = "Pick up",
    ["interact.talk"] = "Talk",
    ["interact.open"] = "Open",
    ["interact.use"] = "Use",
    ["interact.key"] = "[E]",

    -----------------------------------------------------------------------
    -- Progress
    -----------------------------------------------------------------------
    ["xp.gain"] = "+%d XP",
    ["xp.reason.kill"] = "For killing",
    ["xp.reason.quest"] = "For quest",
    ["levelup.text"] = "You have reached level %d!",
    ["levelup.title"] = "Level Up",

    -----------------------------------------------------------------------
    -- Misc
    -----------------------------------------------------------------------
    ["notify.error"] = "Error",
    ["notify.success"] = "Success",
    ["notify.info"] = "Info",
    ["death.title"] = "You died",
    ["death.respawn"] = "Respawning in %d sec.",
    ["currency.name"] = "Coins",
    ["target.none"] = "No target",
    -----------------------------------------------------------------------
    -- Quests / dialogue / vendors
    -----------------------------------------------------------------------
    ["quest.log_title"] = "Quest Log",
    ["quest.log_empty"] = "No quests yet",
    ["quest.status_active"] = "Active",
    ["quest.status_completed"] = "Completed",
    ["quest.track"] = "Track",
    ["quest.untrack"] = "Untrack",
    ["quest.abandon"] = "Abandon",
    ["quest.accepted"] = "Quest accepted",
    ["quest.completed"] = "Quest completed",
    ["quest.abandoned"] = "Quest abandoned",
    ["quest.in_progress"] = "Quest already in progress",
    ["quest.already_completed"] = "Quest already completed",
    ["quest.not_available"] = "Quest unavailable",
    ["quest.no_quests"] = "I have no quests for you",
    ["dialogue.title"] = "Dialogue",
    ["vendor.title"] = "Trade",
    ["vendor.buy"] = "Buy",
    ["vendor.sell"] = "Sell",
    ["vendor.buy_one"] = "Buy",
    ["vendor.sell_one"] = "Sell",
    ["vendor.no_items"] = "Nothing to sell",
    ["vendor.not_enough_money"] = "Not enough coins",
    ["vendor.inventory_full"] = "Inventory is full",
    ["currency.coins"] = "coins",
    ["npc.interact"] = "[E] Interact",
})
