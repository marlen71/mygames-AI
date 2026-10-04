-- Data-driven profession schema: three paid ranks and three server-validated orders per shift.
WO.Professions.Register({
    id = "brewer",
    name = "Пивовар",
    description = "Переработка солода, варка напитков и розлив.",
    xpPerOrder = 100,
    ranks = {
        {
            name = "Солодовник",
            requiredXP = 0,
            basePay = 37,
            activities = {
                {
                    name = "Подготовить ячмень",
                    mode = "timing",
                    instruction = "Отберите чистое зерно для солода.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
                {
                    name = "Перемолоть солод",
                    mode = "timing",
                    instruction = "Настройте помол на нужную крупность.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
                {
                    name = "Перенести мешки",
                    mode = "delivery",
                    instruction = "Доставьте мешки солода в варочную.",
                    deliveryDistance = 520,
                },
            },
        },
        {
            name = "Варщик",
            requiredXP = 300,
            basePay = 62,
            activities = {
                {
                    name = "Загрузить котёл",
                    mode = "timing",
                    instruction = "Добавляйте ингредиенты в нужный момент.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
                {
                    name = "Выдержать варку",
                    mode = "timing",
                    instruction = "Сохраняйте температуру сусла в зелёной зоне.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
                {
                    name = "Перенести бочку",
                    mode = "delivery",
                    instruction = "Доставьте готовую бочку в хранилище.",
                    deliveryDistance = 560,
                },
            },
        },
        {
            name = "Разливщик",
            requiredXP = 900,
            basePay = 96,
            activities = {
                {
                    name = "Подготовить бутылки",
                    mode = "timing",
                    instruction = "Выстройте тару для розлива.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Разлить напиток",
                    mode = "timing",
                    instruction = "Держите уровень наполнения в зелёном секторе.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Сдать партию",
                    mode = "delivery",
                    instruction = "Доставьте ящики с напитком на склад.",
                    deliveryDistance = 600,
                },
            },
        },
    },
})
