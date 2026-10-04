-- Data-driven profession schema: three paid ranks and three server-validated orders per shift.
WO.Professions.Register({
    id = "fisher",
    name = "Рыбак",
    description = "Ловля, сетевой промысел и разделка улова.",
    xpPerOrder = 100,
    ranks = {
        {
            name = "Рыбак",
            requiredXP = 0,
            basePay = 33,
            activities = {
                {
                    name = "Подсечь рыбу",
                    mode = "timing",
                    instruction = "Удерживайте маркер в зелёной зоне, чтобы вываживать рыбу.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
                {
                    name = "Настроить снасть",
                    mode = "timing",
                    instruction = "Подберите натяжение лески в нужном секторе.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
                {
                    name = "Сдать улов",
                    mode = "delivery",
                    instruction = "Доставьте корзину с уловом на рыбный склад.",
                    deliveryDistance = 520,
                },
            },
        },
        {
            name = "Сеточник",
            requiredXP = 300,
            basePay = 56,
            activities = {
                {
                    name = "Поставить сеть",
                    mode = "timing",
                    instruction = "Выберите подходящий момент для заброса сети.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
                {
                    name = "Вытащить сеть",
                    mode = "delivery",
                    instruction = "Перенесите сеть и улов к месту приёмки.",
                    deliveryDistance = 560,
                },
                {
                    name = "Распутать снасть",
                    mode = "timing",
                    instruction = "Освободите улов, удерживая натяжение в зелёной зоне.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
            },
        },
        {
            name = "Разделочник",
            requiredXP = 900,
            basePay = 88,
            activities = {
                {
                    name = "Подготовить рыбу",
                    mode = "timing",
                    instruction = "Подберите точный темп разделки рыбы.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Разделать улов",
                    mode = "timing",
                    instruction = "Проводите нож по безопасному сектору.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Отнести ящики",
                    mode = "delivery",
                    instruction = "Доставьте ящики с разделанным уловом на склад.",
                    deliveryDistance = 600,
                },
            },
        },
    },
})
