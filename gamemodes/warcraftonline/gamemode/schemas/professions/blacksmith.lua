-- Data-driven profession schema: three paid ranks and three server-validated orders per shift.
WO.Professions.Register({
    id = "blacksmith",
    name = "Кузнец",
    description = "Работа у горна, ковка и заточка инструмента.",
    xpPerOrder = 100,
    ranks = {
        {
            name = "Горновой",
            requiredXP = 0,
            basePay = 40,
            activities = {
                {
                    name = "Разжечь горн",
                    mode = "smithing",
                    instruction = "Удерживайте температуру горна в зелёном секторе.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
                {
                    name = "Подать заготовку",
                    mode = "smithing",
                    instruction = "Выберите правильный момент для подачи металла.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
                {
                    name = "Перенести слитки",
                    mode = "delivery",
                    instruction = "Доставьте подготовленные слитки к кузнице.",
                    deliveryDistance = 520,
                },
            },
        },
        {
            name = "Молотобоец",
            requiredXP = 300,
            basePay = 66,
            activities = {
                {
                    name = "Нагреть металл",
                    mode = "smithing",
                    instruction = "Следите за температурой раскалённой заготовки.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
                {
                    name = "Выковать деталь",
                    mode = "smithing",
                    instruction = "Попадайте молотом по металлу в нужный такт.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
                {
                    name = "Сдать заказ",
                    mode = "delivery",
                    instruction = "Отнесите готовую деталь заказчику на склад.",
                    deliveryDistance = 560,
                },
            },
        },
        {
            name = "Точильщик",
            requiredXP = 900,
            basePay = 100,
            activities = {
                {
                    name = "Закрепить клинок",
                    mode = "smithing",
                    instruction = "Настройте угол клинка на точильном станке.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Заточить лезвие",
                    mode = "smithing",
                    instruction = "Ведите клинок, удерживая маркер в зелёной зоне.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Доставить инструмент",
                    mode = "delivery",
                    instruction = "Сдайте заточенный инструмент на склад.",
                    deliveryDistance = 600,
                },
            },
        },
    },
})
