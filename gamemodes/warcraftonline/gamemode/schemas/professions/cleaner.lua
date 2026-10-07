-- Data-driven profession schema: three paid ranks and three server-validated orders per shift.
WO.Professions.Register({
    id = "cleaner",
    name = "Уборщик",
    description = "Уборка дворов, подметание улиц и сортировка отходов.",
    xpPerOrder = 100,
    ranks = {
        {
            name = "Дворник",
            requiredXP = 0,
            basePay = 2500,
            activities = {
                {
                    name = "Собрать мусор",
                    mode = "delivery",
                    instruction = "Соберите отходы и перенесите их от двора к месту сбора.",
                    deliveryDistance = 520,
                },
                {
                    name = "Подмести двор",
                    mode = "sweeping",
                    instruction = "Ведите метлу ровными движениями.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
                {
                    name = "Унести мешок",
                    mode = "delivery",
                    instruction = "Отнесите собранный мешок к пункту приёмки.",
                    deliveryDistance = 520,
                },
            },
        },
        {
            name = "Подметальщик",
            requiredXP = 300,
            basePay = 4200,
            activities = {
                {
                    name = "Очистить проход",
                    mode = "sweeping",
                    instruction = "Поддерживайте равномерный темп подметания.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
                {
                    name = "Убрать улицу",
                    mode = "delivery",
                    instruction = "Перенесите собранный мусор от улицы к пункту сбора.",
                    deliveryDistance = 560,
                },
                {
                    name = "Собрать листву",
                    mode = "sweeping",
                    instruction = "Сгребите листву в нужную зону.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
            },
        },
        {
            name = "Мусорщик",
            requiredXP = 900,
            basePay = 6600,
            activities = {
                {
                    name = "Отсортировать отходы",
                    mode = "sweeping",
                    instruction = "Разделите пригодные и опасные отходы.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Перевезти контейнер",
                    mode = "delivery",
                    instruction = "Доставьте контейнер к месту переработки.",
                    deliveryDistance = 600,
                },
                {
                    name = "Сдать вторсырьё",
                    mode = "sweeping",
                    instruction = "Проверьте сортировку перед сдачей.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
            },
        },
    },
})
