-- Data-driven profession schema: three paid ranks and three server-validated orders per shift.
WO.Professions.Register({
    id = "dockworker",
    name = "Портовый рабочий",
    description = "Обработка портовых грузов, работа с канатами и причалом.",
    xpPerOrder = 100,
    ranks = {
        {
            name = "Грузчик",
            requiredXP = 0,
            basePay = 3200,
            activities = {
                {
                    name = "Принять ящик",
                    mode = "ropemaking",
                    instruction = "Проверьте груз и закрепите его для выгрузки.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
                {
                    name = "Перенести груз",
                    mode = "delivery",
                    instruction = "Доставьте ящик от причала к складской зоне.",
                    deliveryDistance = 520,
                },
                {
                    name = "Сложить партию",
                    mode = "ropemaking",
                    instruction = "Уложите груз устойчивой стопкой.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
            },
        },
        {
            name = "Канатчик",
            requiredXP = 300,
            basePay = 5400,
            activities = {
                {
                    name = "Подготовить трос",
                    mode = "ropemaking",
                    instruction = "Проверьте натяжение каната.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
                {
                    name = "Перевязать груз",
                    mode = "ropemaking",
                    instruction = "Закрепите узел в зелёном секторе.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
                {
                    name = "Перенести снасти",
                    mode = "delivery",
                    instruction = "Доставьте связки канатов в портовый склад.",
                    deliveryDistance = 560,
                },
            },
        },
        {
            name = "Причальщик",
            requiredXP = 900,
            basePay = 8500,
            activities = {
                {
                    name = "Подать швартов",
                    mode = "ropemaking",
                    instruction = "Выберите момент для безопасной подачи каната.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Закрепить причал",
                    mode = "ropemaking",
                    instruction = "Удерживайте натяжение швартова в нужном диапазоне.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Сдать груз",
                    mode = "delivery",
                    instruction = "Отнесите портовую партию к месту приёмки.",
                    deliveryDistance = 600,
                },
            },
        },
    },
})
