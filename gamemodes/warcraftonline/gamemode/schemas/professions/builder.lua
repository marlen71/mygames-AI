-- Data-driven profession schema: three paid ranks and three server-validated orders per shift.
WO.Professions.Register({
    id = "builder",
    name = "Строитель",
    description = "Земляные работы, кладка камня и кровельные заказы.",
    xpPerOrder = 100,
    ranks = {
        {
            name = "Землекоп",
            requiredXP = 0,
            basePay = 3400,
            activities = {
                {
                    name = "Разметить котлован",
                    mode = "masonry",
                    instruction = "Совместите линию копки с разметкой.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
                {
                    name = "Копать грунт",
                    mode = "masonry",
                    instruction = "Поддерживайте ровный темп земляных работ.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
                {
                    name = "Отнести грунт",
                    mode = "delivery",
                    instruction = "Отнесите мешки грунта от площадки к месту складирования.",
                    deliveryDistance = 520,
                },
            },
        },
        {
            name = "Каменщик",
            requiredXP = 300,
            basePay = 5700,
            activities = {
                {
                    name = "Подготовить раствор",
                    mode = "masonry",
                    instruction = "Смешайте строительный раствор до нужной густоты.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
                {
                    name = "Уложить камень",
                    mode = "masonry",
                    instruction = "Совместите камень с зелёным сектором кладки.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
                {
                    name = "Перенести блоки",
                    mode = "delivery",
                    instruction = "Доставьте блоки к месту строительства.",
                    deliveryDistance = 560,
                },
            },
        },
        {
            name = "Кровельщик",
            requiredXP = 900,
            basePay = 9000,
            activities = {
                {
                    name = "Подготовить крышу",
                    mode = "masonry",
                    instruction = "Закрепите основу для кровельного покрытия.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Уложить черепицу",
                    mode = "masonry",
                    instruction = "Выравнивайте ряд, удерживая маркер в зелёной зоне.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Сдать материалы",
                    mode = "delivery",
                    instruction = "Доставьте остаток кровельных материалов на склад.",
                    deliveryDistance = 600,
                },
            },
        },
    },
})
