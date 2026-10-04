--[[ Warcraft Online — торговка Марла. ]]

WO.Dialogue.Register({
    id = "trader_marla",
    nodes = {
        start = {
            text = "Добро пожаловать. У меня можно купить припасы или продать подходящие вещи.",
            options = {
                { text = "Торговать", action = "vendor" },
                { text = "Есть работа?", action = "next:work" },
                { text = "Расскажи, что это за место?", action = "next:lore" },
                { text = "До встречи!", action = "close" },
            },
        },
        work = {
            text = "Работа найдётся, но поручения дают другие. Поговори с Охотником у фермы или с Маршалом Дугхалом.",
            options = {
                { text = "Назад", action = "next:start" },
                { text = "До встречи!", action = "close" },
            },
        },
        lore = {
            text = "Это Вальдрак — королевство Альянса. Здесь торгуют, готовят обозы и защищают дороги, ведущие к фермам и лесам.",
            options = {
                { text = "Назад", action = "next:start" },
            },
        },
    },
})
