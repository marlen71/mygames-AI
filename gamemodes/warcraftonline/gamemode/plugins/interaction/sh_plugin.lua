--[[
    Warcraft Online — плагин взаимодействия.
    Единая система: NPC, предметы, двери, контейнеры, торговцы —
    всё реализует интерфейс:
        Entity:CanInteract(ply) → bool
        Entity:GetInteractionText(ply) → string
        Entity:Interact(ply)
]]

PLUGIN.name = "Interaction"
PLUGIN.id = "interaction"
PLUGIN.author = "Warcraft Online Team"
PLUGIN.version = "1.0.0"
PLUGIN.dependencies = {}
PLUGIN.priority = 65
