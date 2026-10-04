-- Data-driven profession schema: three paid ranks and three server-validated orders per shift.
WO.Professions.Register({
    id = "porter",
    name = "Грузчик",
    description = "Складские заказы: сбор, перенос и погрузка грузов.",
    xpPerOrder = 100,
    ranks = {
        {
            name = "Складчик",
            requiredXP = 0,
            basePay = 28,
            activities = {
                {
                    name = "Собрать заказ",
                    mode = "timing",
                    instruction = "Сверьте и соберите груз по ведомости.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
                {
                    name = "Перенести ящик",
                    mode = "delivery",
                    instruction = "Возьмите ящик и донесите его до складской зоны.",
                    deliveryDistance = 520,
                },
                {
                    name = "Разложить товар",
                    mode = "timing",
                    instruction = "Установите ящики в безопасном порядке.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
            },
        },
        {
            name = "Развозчик",
            requiredXP = 300,
            basePay = 47,
            activities = {
                {
                    name = "Подготовить тележку",
                    mode = "timing",
                    instruction = "Равномерно разместите груз на тележке.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
                {
                    name = "Развезти заказ",
                    mode = "delivery",
                    instruction = "Доставьте груз по маршруту, пройдя нужное расстояние.",
                    deliveryDistance = 560,
                },
                {
                    name = "Сдать накладную",
                    mode = "timing",
                    instruction = "Подтвердите доставку по правильной ведомости.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
            },
        },
        {
            name = "Погрузчик",
            requiredXP = 900,
            basePay = 74,
            activities = {
                {
                    name = "Поднять груз",
                    mode = "timing",
                    instruction = "Поймайте баланс при подъёме тяжёлого груза.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Перевезти паллету",
                    mode = "delivery",
                    instruction = "Переместите паллету к обозначенной зоне приёмки.",
                    deliveryDistance = 600,
                },
                {
                    name = "Закрепить груз",
                    mode = "timing",
                    instruction = "Проверьте крепление груза перед сдачей.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
            },
        },
    },
})
