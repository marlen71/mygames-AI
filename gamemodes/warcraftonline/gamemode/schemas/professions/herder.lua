-- Data-driven profession schema: three paid ranks and three server-validated orders per shift.
WO.Professions.Register({
    id = "herder",
    name = "Скотник",
    description = "Уход за стадом, кормление и безопасный перегон животных.",
    xpPerOrder = 100,
    ranks = {
        {
            name = "Пастух",
            requiredXP = 0,
            basePay = 30,
            activities = {
                {
                    name = "Собрать стадо",
                    mode = "timing",
                    instruction = "Соберите животных в стадо, удерживая ритм.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
                {
                    name = "Отвести стадо",
                    mode = "delivery",
                    instruction = "Проведите стадо от места выпаса на нужное расстояние.",
                    deliveryDistance = 520,
                },
                {
                    name = "Доставить корм",
                    mode = "delivery",
                    instruction = "Отнесите запас корма к загону.",
                    deliveryDistance = 520,
                },
            },
        },
        {
            name = "Кормильщик",
            requiredXP = 300,
            basePay = 50,
            activities = {
                {
                    name = "Подготовить корм",
                    mode = "timing",
                    instruction = "Смешайте корм в правильной пропорции.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
                {
                    name = "Раздать корм",
                    mode = "timing",
                    instruction = "Поддерживайте ровную подачу корма.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
                {
                    name = "Перенести тюки",
                    mode = "delivery",
                    instruction = "Доставьте тюки сена к стойлам.",
                    deliveryDistance = 560,
                },
            },
        },
        {
            name = "Загонщик",
            requiredXP = 900,
            basePay = 78,
            activities = {
                {
                    name = "Открыть проход",
                    mode = "timing",
                    instruction = "Выберите безопасный момент для открытия ворот.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Перегнать скот",
                    mode = "delivery",
                    instruction = "Переведите стадо к дальнему загону.",
                    deliveryDistance = 600,
                },
                {
                    name = "Закрыть загон",
                    mode = "timing",
                    instruction = "Зафиксируйте ворота в нужном положении.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
            },
        },
    },
})
