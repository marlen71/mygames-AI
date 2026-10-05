-- Data-driven profession schema: three paid ranks and three server-validated orders per shift.
WO.Professions.Register({
    id = "miner",
    name = "Шахтёр",
    description = "Добыча руды, работа с вагонетками и дробление породы.",
    xpPerOrder = 100,
    ranks = {
        {
            name = "Горняк",
            requiredXP = 0,
            basePay = 34,
            activities = {
                {
                    name = "Отбить жилу",
                    mode = "mining",
                    instruction = "Выберите правильный момент для удара киркой.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
                {
                    name = "Отсеять породу",
                    mode = "mining",
                    instruction = "Отделите полезную руду от пустой породы.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
                {
                    name = "Перенести руду",
                    mode = "delivery",
                    instruction = "Отнесите добытую руду к приёмному складу.",
                    deliveryDistance = 520,
                },
            },
        },
        {
            name = "Вагонетчик",
            requiredXP = 300,
            basePay = 58,
            activities = {
                {
                    name = "Загрузить вагонетку",
                    mode = "mining",
                    instruction = "Распределите руду по вагонетке равномерно.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
                {
                    name = "Провезти вагонетку",
                    mode = "delivery",
                    instruction = "Доставьте загруженную вагонетку на расстояние по маршруту.",
                    deliveryDistance = 560,
                },
                {
                    name = "Разгрузить руду",
                    mode = "mining",
                    instruction = "Сдайте содержимое в приёмный бункер без потерь.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
            },
        },
        {
            name = "Дробильщик",
            requiredXP = 900,
            basePay = 90,
            activities = {
                {
                    name = "Настроить дробилку",
                    mode = "mining",
                    instruction = "Подберите темп подачи руды в дробилку.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Раздробить породу",
                    mode = "mining",
                    instruction = "Удерживайте нагрузку в зелёном секторе.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Перенести концентрат",
                    mode = "delivery",
                    instruction = "Отнесите отсортированный концентрат на склад.",
                    deliveryDistance = 600,
                },
            },
        },
    },
})
