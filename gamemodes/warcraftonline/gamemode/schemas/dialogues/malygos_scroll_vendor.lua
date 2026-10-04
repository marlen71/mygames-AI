--[[ Warcraft Online — Малигос, торговец магическими свитками. ]]

WO.Dialogue.Register({
    id = "malygos_scroll_vendor",
    nodes = {
        start = {
            text = "Я храню свитки стихий. У торговца можно купить свиток заклинания или более высокий ранг для подходящего уровня.",
            options = {
                { text = "Торговать", action = "vendor" },
                { text = "Есть работа?", action = "next:work" },
                { text = "Расскажи, что это за место?", action = "next:lore" },
                { text = "До встречи!", action = "close" },
            },
        },
        work = {
            text = "Моё дело — магические свитки. За поручениями поговори с Охотником или Маршалом Дугхалом.",
            options = {
                { text = "Назад", action = "next:start" },
                { text = "До встречи!", action = "close" },
            },
        },
        lore = {
            text = "Ты в Вальдраке — королевстве Альянса. Маги и торговцы здесь помогают путникам подготовиться к дороге и охранять владения.",
            options = {
                { text = "Назад", action = "next:start" },
            },
        },
    },
})
