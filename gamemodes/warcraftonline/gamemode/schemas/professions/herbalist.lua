-- Data-driven profession schema: three paid ranks and three server-validated orders per shift.
WO.Professions.Register({
    id = "herbalist",
    name = "Травник",
    description = "Сбор, сушка и сортировка лекарственных растений.",
    xpPerOrder = 100,
    ranks = {
        {
            name = "Собиратель",
            requiredXP = 0,
            basePay = 33,
            activities = {
                {
                    name = "Найти траву",
                    mode = "herbcraft",
                    instruction = "Выберите подходящий момент для сбора растения.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
                {
                    name = "Собрать листья",
                    mode = "herbcraft",
                    instruction = "Снимите листья, не повредив корень.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
                {
                    name = "Отнести сбор",
                    mode = "delivery",
                    instruction = "Доставьте связку трав в сушильню.",
                    deliveryDistance = 520,
                },
            },
        },
        {
            name = "Сушильщик",
            requiredXP = 300,
            basePay = 55,
            activities = {
                {
                    name = "Разложить травы",
                    mode = "herbcraft",
                    instruction = "Распределите растения по сушильным рамам.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
                {
                    name = "Высушить сбор",
                    mode = "herbcraft",
                    instruction = "Поддерживайте сушку в правильном диапазоне.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
                {
                    name = "Перенести связки",
                    mode = "delivery",
                    instruction = "Отнесите высушенные травы на склад.",
                    deliveryDistance = 560,
                },
            },
        },
        {
            name = "Сортировщик",
            requiredXP = 900,
            basePay = 86,
            activities = {
                {
                    name = "Отобрать листья",
                    mode = "herbcraft",
                    instruction = "Отделите ценные листья от примесей.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Разделить сбор",
                    mode = "herbcraft",
                    instruction = "Сверьте травы с заказом гильдии.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Сдать ингредиенты",
                    mode = "delivery",
                    instruction = "Доставьте отсортированные ингредиенты алхимику.",
                    deliveryDistance = 600,
                },
            },
        },
    },
})
