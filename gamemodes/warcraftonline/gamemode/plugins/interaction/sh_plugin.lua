--[[
    Warcraft Online — плагин взаимодействия.
    Единая система: NPC, предметы, двери, контейнеры, торговцы —
    всё реализует интерфейс:
        Entity:CanInteract(ply) → bool
        Entity:GetInteractionText(ply) → string
        Entity:Interact(ply)
]]

return {
    name = "Interaction",
    id = "interaction",
    author = "Warcraft Online Team",
    version = "1.0.0",
    dependencies = {},
    priority = 65,
}
