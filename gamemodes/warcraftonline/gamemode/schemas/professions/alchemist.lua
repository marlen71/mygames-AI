-- Data-driven profession schema: three paid ranks and three server-validated orders per shift.
WO.Professions.Register({
    id = "alchemist",
    name = "Алхимик",
    description = "Сбор компонентов, измельчение ингредиентов и варка зелий.",
    xpPerOrder = 100,
    ranks = {
        {
            name = "Сборщик трав",
            requiredXP = 0,
            basePay = 4200,
            activities = {
                {
                    name = "Найти ингредиент",
                    mode = "alchemy",
                    instruction = "Выберите подходящий момент для сбора растения.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
                {
                    name = "Собрать компоненты",
                    mode = "alchemy",
                    instruction = "Снимите ингредиенты аккуратно, не повредив их.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
                {
                    name = "Доставить травы",
                    mode = "delivery",
                    instruction = "Отнесите собранные травы в лабораторию.",
                    deliveryDistance = 520,
                },
            },
        },
        {
            name = "Толкач",
            requiredXP = 300,
            basePay = 7000,
            activities = {
                {
                    name = "Подготовить ступку",
                    mode = "alchemy",
                    instruction = "Отмерьте компоненты для смеси.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
                {
                    name = "Растереть реагенты",
                    mode = "alchemy",
                    instruction = "Измельчайте ингредиенты ровным нажимом.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
                {
                    name = "Перенести порошок",
                    mode = "delivery",
                    instruction = "Доставьте герметичный набор реагентов к столу.",
                    deliveryDistance = 560,
                },
            },
        },
        {
            name = "Зельевар",
            requiredXP = 900,
            basePay = 11000,
            activities = {
                {
                    name = "Разогреть колбу",
                    mode = "alchemy",
                    instruction = "Настройте нагрев колбы в зелёной зоне.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Сварить зелье",
                    mode = "alchemy",
                    instruction = "Добавляйте реагенты в правильный момент.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Сдать флаконы",
                    mode = "delivery",
                    instruction = "Отнесите готовые зелья в пункт приёмки.",
                    deliveryDistance = 600,
                },
            },
        },
    },
})
