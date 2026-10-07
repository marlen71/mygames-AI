--[[
    Warcraft Online — плагин боевой системы.
    Damage pipeline: PreDamage → Calculate → Resistance → Critical → Modifiers → Final → Post.
]]

return {
    name = "Combat",
    id = "combat",
    author = "Warcraft Online Team",
    version = "1.0.0",
    dependencies = { "stats" },
    priority = 60,
}
