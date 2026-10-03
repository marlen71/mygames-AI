--[[
    Warcraft Online — диалог: Маршал Дугхал.
    Добавление диалога = новый файл в schemas/dialogues/.
]]

WO.Dialogue.Register({
    id = "marshal_intro",
    nodes = {
        start = {
            text = "Приветствую, странник. Эти земли небезопасны: волки терзают путников, а обозам не хватает припасов. Поможешь?",
            options = {
                { text = "Расскажи о волках",      action = "next:wolves" },
                { text = "Чем помочь с припасами?", action = "next:supplies" },
                { text = "Прощай",                 action = "close" },
            },
        },
        wolves = {
            text = "Серые твари обнаглели. Победи одного волка первого уровня у дороги — и награда не заставит себя ждать.",
            options = {
                { text = "Я возьмусь за это дело", action = "quest:wolves_of_elwynn" },
                { text = "Назад",                  action = "next:start" },
            },
        },
        supplies = {
            text = "Нашим обозам нужен хлеб в дорогу. Три буханки — и ты спасёшь не одну жизнь.",
            options = {
                { text = "Сделаю", action = "quest:supplies_for_the_road" },
                { text = "Назад",  action = "next:start" },
            },
        },
    },
})
