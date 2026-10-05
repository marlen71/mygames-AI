-- Data-driven profession schema: three paid ranks and three server-validated orders per shift.
WO.Professions.Register({
    id = "beekeeper",
    name = "Пасечник",
    description = "Уход за ульями, сбор мёда и изготовление воска.",
    xpPerOrder = 100,
    ranks = {
        {
            name = "Пчеловод",
            requiredXP = 0,
            basePay = 36,
            activities = {
                {
                    name = "Осмотреть улей",
                    mode = "beekeeping",
                    instruction = "Проверьте улей в правильный момент.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
                {
                    name = "Подготовить рамку",
                    mode = "beekeeping",
                    instruction = "Установите рамку, не тревожа пчёл.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
                {
                    name = "Принести корм",
                    mode = "delivery",
                    instruction = "Доставьте запас корма к пасеке.",
                    deliveryDistance = 520,
                },
            },
        },
        {
            name = "Медосборщик",
            requiredXP = 300,
            basePay = 59,
            activities = {
                {
                    name = "Открыть улей",
                    mode = "beekeeping",
                    instruction = "Выберите безопасный момент для работы с ульем.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
                {
                    name = "Собрать мёд",
                    mode = "beekeeping",
                    instruction = "Снимите рамку, удерживая движение в зелёной зоне.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
                {
                    name = "Доставить мёд",
                    mode = "delivery",
                    instruction = "Перенесите ёмкости с мёдом в хранилище.",
                    deliveryDistance = 560,
                },
            },
        },
        {
            name = "Воскодел",
            requiredXP = 900,
            basePay = 92,
            activities = {
                {
                    name = "Очистить воск",
                    mode = "beekeeping",
                    instruction = "Отделите чистый воск от примесей.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Растопить воск",
                    mode = "beekeeping",
                    instruction = "Поддерживайте нагрев в зелёном секторе.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Сдать слитки",
                    mode = "delivery",
                    instruction = "Доставьте готовые восковые слитки на склад.",
                    deliveryDistance = 600,
                },
            },
        },
    },
})
