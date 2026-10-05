-- Data-driven profession schema: three paid ranks and three server-validated orders per shift.
WO.Professions.Register({
    id = "weaponsmith",
    name = "Оружейник",
    description = "Изготовление луков, стрел и арбалетного снаряжения.",
    xpPerOrder = 100,
    ranks = {
        {
            name = "Лучник",
            requiredXP = 0,
            basePay = 42,
            activities = {
                {
                    name = "Подготовить древко",
                    mode = "fletching",
                    instruction = "Выберите прямую заготовку для лука.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
                {
                    name = "Согнуть лук",
                    mode = "fletching",
                    instruction = "Настройте натяжение лука в зелёном секторе.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
                {
                    name = "Доставить луки",
                    mode = "delivery",
                    instruction = "Сдайте готовые луки на оружейный склад.",
                    deliveryDistance = 520,
                },
            },
        },
        {
            name = "Стрелочник",
            requiredXP = 300,
            basePay = 68,
            activities = {
                {
                    name = "Выправить древко",
                    mode = "fletching",
                    instruction = "Выровняйте древко стрелы без перекоса.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
                {
                    name = "Установить наконечник",
                    mode = "fletching",
                    instruction = "Закрепите наконечник в правильный момент.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
                {
                    name = "Перенести колчаны",
                    mode = "delivery",
                    instruction = "Доставьте партию стрел к пункту выдачи.",
                    deliveryDistance = 560,
                },
            },
        },
        {
            name = "Арбалетчик",
            requiredXP = 900,
            basePay = 105,
            activities = {
                {
                    name = "Собрать механизм",
                    mode = "fletching",
                    instruction = "Совместите детали спускового механизма.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Настроить арбалет",
                    mode = "fletching",
                    instruction = "Отрегулируйте натяжение тетивы.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Сдать арбалеты",
                    mode = "delivery",
                    instruction = "Доставьте готовые арбалеты в оружейную.",
                    deliveryDistance = 600,
                },
            },
        },
    },
})
