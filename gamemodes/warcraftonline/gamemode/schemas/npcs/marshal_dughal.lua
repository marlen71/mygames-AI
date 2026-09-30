--[[
    Warcraft Online — NPC: Маршал Дугхал (квестодатель).
    Добавление NPC = новый файл в schemas/npcs/ (без изменения ядра).
]]

WO.NPCs.Register({
    id = "marshal_dughal",
    name = "Маршал Дугхал",
    type = "questgiver",

    model = "models/player/Group01/male_02.mdl",
    skin = 0,
    scale = 1,

    -- Пустой список намеренный: NPC появится только после явной map-точки.
    spawns = {},

    dialogue = "marshal_intro",
    quests = { "wolves_of_elwynn", "supplies_for_the_road" },

    interactRange = 140,
})
