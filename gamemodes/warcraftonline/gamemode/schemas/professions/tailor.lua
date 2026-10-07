-- Data-driven profession schema: three paid ranks and three server-validated orders per shift.
WO.Professions.Register({
    id = "tailor",
    name = "Портной",
    description = "Раскрой ткани, пошив одежды и изготовление брони.",
    xpPerOrder = 100,
    ranks = {
        {
            name = "Закройщик",
            requiredXP = 0,
            basePay = 3600,
            activities = {
                {
                    name = "Разметить ткань",
                    mode = "sewing",
                    instruction = "Совместите линию раскроя с меткой.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
                {
                    name = "Выкроить детали",
                    mode = "sewing",
                    instruction = "Режьте ткань по выкройке без отклонений.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
                {
                    name = "Перенести рулоны",
                    mode = "delivery",
                    instruction = "Доставьте рулоны ткани в мастерскую.",
                    deliveryDistance = 520,
                },
            },
        },
        {
            name = "Швея",
            requiredXP = 300,
            basePay = 6000,
            activities = {
                {
                    name = "Подготовить нить",
                    mode = "sewing",
                    instruction = "Подберите натяжение нити перед шитьём.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
                {
                    name = "Сшить изделие",
                    mode = "sewing",
                    instruction = "Держите стежок в зелёной зоне.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
                {
                    name = "Сдать одежду",
                    mode = "delivery",
                    instruction = "Отнесите готовую одежду на склад.",
                    deliveryDistance = 560,
                },
            },
        },
        {
            name = "Бронник",
            requiredXP = 900,
            basePay = 9200,
            activities = {
                {
                    name = "Сложить подкладку",
                    mode = "sewing",
                    instruction = "Подготовьте тканевую основу для брони.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Сшить панцирь",
                    mode = "sewing",
                    instruction = "Укрепите швы, удерживая темп работы.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Доставить доспех",
                    mode = "delivery",
                    instruction = "Доставьте готовую броню в пункт приёмки.",
                    deliveryDistance = 600,
                },
            },
        },
    },
})
