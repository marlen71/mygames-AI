-- Data-driven profession schema: three paid ranks and three server-validated orders per shift.
WO.Professions.Register({
    id = "water_carrier",
    name = "Водонос",
    description = "Добыча чистой воды, доставка и обслуживание колодца.",
    xpPerOrder = 100,
    ranks = {
        {
            name = "Черпальщик",
            requiredXP = 0,
            basePay = 28,
            activities = {
                {
                    name = "Опустить ведро",
                    mode = "balancing",
                    instruction = "Выберите момент, чтобы наполнить ведро без пролива.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
                {
                    name = "Набрать воду",
                    mode = "balancing",
                    instruction = "Удерживайте уровень воды в безопасном секторе.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
                {
                    name = "Отнести ведро",
                    mode = "delivery",
                    instruction = "Доставьте воду от колодца к складу.",
                    deliveryDistance = 520,
                },
            },
        },
        {
            name = "Водонос",
            requiredXP = 300,
            basePay = 46,
            activities = {
                {
                    name = "Наполнить бурдюк",
                    mode = "balancing",
                    instruction = "Отмерьте нужный объём воды.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
                {
                    name = "Донести воду",
                    mode = "delivery",
                    instruction = "Перенесите воду к месту раздачи.",
                    deliveryDistance = 560,
                },
                {
                    name = "Раздать запас",
                    mode = "balancing",
                    instruction = "Распределите воду между ёмкостями без потерь.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
            },
        },
        {
            name = "Колодезник",
            requiredXP = 900,
            basePay = 72,
            activities = {
                {
                    name = "Проверить подъёмник",
                    mode = "balancing",
                    instruction = "Отрегулируйте механизм колодца.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Поднять бочку",
                    mode = "balancing",
                    instruction = "Поднимайте бочку, удерживая тягу в зелёной зоне.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Доставить запас",
                    mode = "delivery",
                    instruction = "Доставьте бочку с чистой водой на склад.",
                    deliveryDistance = 600,
                },
            },
        },
    },
})
