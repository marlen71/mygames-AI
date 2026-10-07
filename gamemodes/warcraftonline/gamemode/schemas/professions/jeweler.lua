-- Data-driven profession schema: three paid ranks and three server-validated orders per shift.
WO.Professions.Register({
    id = "jeweler",
    name = "Ювелир",
    description = "Обработка камней, огранка и сборка украшений.",
    xpPerOrder = 100,
    ranks = {
        {
            name = "Каменщик",
            requiredXP = 0,
            basePay = 4500,
            activities = {
                {
                    name = "Отобрать камень",
                    mode = "gemcutting",
                    instruction = "Найдите подходящий камень для заказа.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
                {
                    name = "Очистить минерал",
                    mode = "gemcutting",
                    instruction = "Снимите лишнюю породу, не повредив камень.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
                {
                    name = "Доставить самоцвет",
                    mode = "delivery",
                    instruction = "Отнесите отобранный самоцвет в мастерскую.",
                    deliveryDistance = 520,
                },
            },
        },
        {
            name = "Огранщик",
            requiredXP = 300,
            basePay = 7400,
            activities = {
                {
                    name = "Разметить грани",
                    mode = "gemcutting",
                    instruction = "Выберите правильный угол будущей огранки.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
                {
                    name = "Огранить камень",
                    mode = "gemcutting",
                    instruction = "Ведите резец в зелёном секторе.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
                {
                    name = "Передать камень",
                    mode = "delivery",
                    instruction = "Доставьте огранённый камень ювелиру.",
                    deliveryDistance = 560,
                },
            },
        },
        {
            name = "Ювелир",
            requiredXP = 900,
            basePay = 11500,
            activities = {
                {
                    name = "Подготовить оправу",
                    mode = "gemcutting",
                    instruction = "Подберите оправу подходящего размера.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Закрепить самоцвет",
                    mode = "gemcutting",
                    instruction = "Установите камень в оправу без перекоса.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Сдать украшение",
                    mode = "delivery",
                    instruction = "Доставьте готовое украшение в пункт приёмки.",
                    deliveryDistance = 600,
                },
            },
        },
    },
})
