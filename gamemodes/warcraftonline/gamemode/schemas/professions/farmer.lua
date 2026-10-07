-- Data-driven profession schema: three paid ranks and three server-validated orders per shift.
WO.Professions.Register({
    id = "farmer",
    name = "Земледелец",
    description = "Полевые работы: вспашка, посев и уборка урожая.",
    xpPerOrder = 100,
    ranks = {
        {
            name = "Пахарь",
            requiredXP = 0,
            basePay = 3000,
            activities = {
                {
                    name = "Вспахать борозду",
                    mode = "sowing",
                    instruction = "Ведите плуг ровно по зелёному сектору.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
                {
                    name = "Разрыхлить почву",
                    mode = "sowing",
                    instruction = "Поддерживайте равномерный темп обработки земли.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
                {
                    name = "Доставить семена",
                    mode = "delivery",
                    instruction = "Принесите мешок семян от амбара к полю.",
                    deliveryDistance = 520,
                },
            },
        },
        {
            name = "Сеятель",
            requiredXP = 300,
            basePay = 5000,
            activities = {
                {
                    name = "Подготовить семена",
                    mode = "sowing",
                    instruction = "Отмерьте нужную порцию зерна для посева.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
                {
                    name = "Засеять ряд",
                    mode = "sowing",
                    instruction = "Удерживайте сеялку на правильном ритме.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
                {
                    name = "Отнести урожай",
                    mode = "delivery",
                    instruction = "Перенесите собранное зерно к амбару.",
                    deliveryDistance = 560,
                },
            },
        },
        {
            name = "Жнец",
            requiredXP = 900,
            basePay = 7800,
            activities = {
                {
                    name = "Настроить серп",
                    mode = "sowing",
                    instruction = "Выберите момент для чистого среза колосьев.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Сжать сноп",
                    mode = "sowing",
                    instruction = "Свяжите сноп, удерживая маркер в зелёной зоне.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Сдать зерно",
                    mode = "delivery",
                    instruction = "Отнесите мешок урожая на склад.",
                    deliveryDistance = 600,
                },
            },
        },
    },
})
