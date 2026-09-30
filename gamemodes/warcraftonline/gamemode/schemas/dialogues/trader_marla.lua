--[[
    Warcraft Online — диалог: торговка Марла.
]]

WO.Dialogue.Register({
    id = "trader_marla",
    nodes = {
        start = {
            text = "Добро пожаловать в мой прилавок! Товары — лучшие в округе.",
            options = {
                { text = "Показать товары",        action = "vendor" },
                { text = "Я ищу работу",           action = "next:work" },
                { text = "До встречи",             action = "close" },
            },
        },
        work = {
            text = "Работа? Хм... Пока всё спокойно. Загляни к маршалу Дугхалу — ему всегда нужны руки. А пока осмотри товары.",
            options = {
                { text = "Хорошо, осмотрюсь", action = "quest:meet_the_trader" },
                { text = "Назад",             action = "next:start" },
            },
        },
    },
})
