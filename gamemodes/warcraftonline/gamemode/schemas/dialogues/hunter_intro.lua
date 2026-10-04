--[[ Warcraft Online — Охотник: короткий вход и одна актуальная работа. ]]

WO.Dialogue.Register({
    id = "hunter_intro",
    nodes = {
        start = {
            text = "У фермы снова видели кабанов. Если хочешь помочь — я подскажу, с чего начать.",
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
            availableText = "Есть одно поручение. Подробности — в карточке задания.",
            emptyText = "Пока охоты для тебя нет. Загляни позже.",
        },
        lore = {
            text = "Мы в Вальдраке — королевстве Альянса. Здесь сходятся торговые дороги, а за фермами начинаются угодья и опасные тропы.",
            options = {
                { text = "Понятно. Назад", action = "next:start" },
            },
        },
    },
})
