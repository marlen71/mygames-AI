-- Data-driven profession schema: three paid ranks and three server-validated orders per shift.
WO.Professions.Register({
    id = "carpenter",
    name = "Плотник",
    description = "Распил досок, столярная сборка и строительные заготовки.",
    xpPerOrder = 100,
    ranks = {
        {
            name = "Досочник",
            requiredXP = 0,
            basePay = 37,
            activities = {
                {
                    name = "Выбрать бревно",
                    mode = "sawing",
                    instruction = "Подберите ровную заготовку для распила.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
                {
                    name = "Распилить доску",
                    mode = "sawing",
                    instruction = "Ведите пилу по направляющей.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
                {
                    name = "Перенести доски",
                    mode = "delivery",
                    instruction = "Доставьте доски из лесопилки в мастерскую.",
                    deliveryDistance = 520,
                },
            },
        },
        {
            name = "Столяр",
            requiredXP = 300,
            basePay = 61,
            activities = {
                {
                    name = "Разметить деталь",
                    mode = "sawing",
                    instruction = "Совместите разметку с шаблоном.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
                {
                    name = "Собрать изделие",
                    mode = "sawing",
                    instruction = "Соедините детали в правильной последовательности.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
                {
                    name = "Сдать мебель",
                    mode = "delivery",
                    instruction = "Отнесите готовую мебель на склад.",
                    deliveryDistance = 560,
                },
            },
        },
        {
            name = "Строитель",
            requiredXP = 900,
            basePay = 95,
            activities = {
                {
                    name = "Подготовить балки",
                    mode = "sawing",
                    instruction = "Подгоните балки для строительного заказа.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Собрать каркас",
                    mode = "sawing",
                    instruction = "Выставьте каркас по уровню.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Доставить конструкцию",
                    mode = "delivery",
                    instruction = "Отнесите готовые деревянные элементы к месту сдачи.",
                    deliveryDistance = 600,
                },
            },
        },
    },
})
