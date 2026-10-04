--[[ Warcraft Online — торговец маунтами. ]]

WO.Dialogue.Register({
    id = "mount_vendor",
    nodes = {
        start = {
            text = "Камень призыва позволяет вызвать или отпустить лошадь; он не расходуется. У меня есть овёс и снаряжение для обучения.",
            options = {
                { text = "Торговать", action = "vendor" },
                { text = "Есть работа?", action = "next:work" },
                { text = "Расскажи, что это за место?", action = "next:lore" },
                { text = "До встречи!", action = "close" },
            },
        },
        work = {
            text = "Я отвечаю за маунтов, а не за поручения. За работой обратись к Охотнику или Маршалу Дугхалу.",
            options = {
                { text = "Назад", action = "next:start" },
                { text = "До встречи!", action = "close" },
            },
        },
        lore = {
            text = "Вальдрак — королевство Альянса. Торговые ряды снабжают путешественников перед дорогой к фермам и лесным тропам.",
            options = {
                { text = "Назад", action = "next:start" },
            },
        },
    },
})
