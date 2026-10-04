--[[ Warcraft Online — Маршал Дугхал: одно актуальное поручение за раз. ]]

WO.Dialogue.Register({
    id = "marshal_intro",
    nodes = {
        start = {
            text = "Дороги вокруг Вальдрака должны быть безопасны. Если есть время — найду для тебя подходящее поручение.",
            options = {
                { text = "Есть работа?", action = "next:work" },
                { text = "Что это за место?", action = "next:lore" },
                { text = "До встречи!", action = "close" },
            },
        },
        work = {
            work = true,
            backNode = "start",
            backText = "Назад",
            emptyCloseText = "До встречи!",
            availableText = "Вот одно поручение, которое сейчас важнее всего.",
            emptyText = "Сейчас подходящей работы нет. Проверь позже.",
        },
        lore = {
            text = "Вальдрак — королевство Альянса: его жители держат дороги открытыми и помогают союзникам. Отсюда начинаются наши вылазки к фермам и лесным тропам.",
            options = {
                { text = "Понятно. Назад", action = "next:start" },
            },
        },
    },
})
