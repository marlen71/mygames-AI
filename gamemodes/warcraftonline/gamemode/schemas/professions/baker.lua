-- Data-driven profession schema: three paid ranks and three server-validated orders per shift.
WO.Professions.Register({
    id = "baker",
    name = "Пекарь",
    description = "Подготовка теста, выпечка и изготовление сладостей.",
    xpPerOrder = 100,
    ranks = {
        {
            name = "Месильщик",
            requiredXP = 0,
            basePay = 34,
            activities = {
                {
                    name = "Просеять муку",
                    mode = "baking",
                    instruction = "Отмерьте муку и просейте её без потерь.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
                {
                    name = "Замесить тесто",
                    mode = "baking",
                    instruction = "Удерживайте ритм замеса в зелёном секторе.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
                {
                    name = "Принести припасы",
                    mode = "delivery",
                    instruction = "Отнесите мешок муки от склада в пекарню.",
                    deliveryDistance = 520,
                },
            },
        },
        {
            name = "Печник",
            requiredXP = 300,
            basePay = 56,
            activities = {
                {
                    name = "Разогреть печь",
                    mode = "baking",
                    instruction = "Следите за температурой печи.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
                {
                    name = "Испечь хлеб",
                    mode = "baking",
                    instruction = "Выньте хлеб в правильный момент.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
                {
                    name = "Сдать выпечку",
                    mode = "delivery",
                    instruction = "Доставьте корзины с хлебом на склад.",
                    deliveryDistance = 560,
                },
            },
        },
        {
            name = "Кондитер",
            requiredXP = 900,
            basePay = 86,
            activities = {
                {
                    name = "Приготовить крем",
                    mode = "baking",
                    instruction = "Смешивайте ингредиенты с ровной скоростью.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Украсить десерт",
                    mode = "baking",
                    instruction = "Нанесите узор, удерживая маркер в зелёной зоне.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Передать заказ",
                    mode = "delivery",
                    instruction = "Отнесите коробку с десертами заказчику.",
                    deliveryDistance = 600,
                },
            },
        },
    },
})
