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
            basePay = 34,
            activities = {
                {
                    name = "Разметить котлован",
                    mode = "timing",
                    instruction = "Совместите линию копки с разметкой.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
                {
                    name = "Копать грунт",
                    mode = "timing",
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
            basePay = 57,
            activities = {
                {
                    name = "Подготовить раствор",
                    mode = "timing",
                    instruction = "Смешайте строительный раствор до нужной густоты.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
                {
                    name = "Уложить камень",
                    mode = "timing",
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
            basePay = 90,
            activities = {
                {
                    name = "Подготовить крышу",
                    mode = "timing",
                    instruction = "Закрепите основу для кровельного покрытия.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Уложить черепицу",
                    mode = "timing",
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
