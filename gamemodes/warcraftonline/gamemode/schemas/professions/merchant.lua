-- Data-driven profession schema: three paid ranks and three server-validated orders per shift.
WO.Professions.Register({
    id = "merchant",
    name = "Рыночный торговец",
    description = "Подготовка прилавка, закупка товара и оценка поставок без торговли между игроками.",
    xpPerOrder = 100,
    ranks = {
        {
            name = "Лавочник",
            requiredXP = 0,
            basePay = 36,
            activities = {
                {
                    name = "Оформить прилавок",
                    mode = "timing",
                    instruction = "Разложите товары и ценники в правильном порядке.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
                {
                    name = "Пополнить витрину",
                    mode = "delivery",
                    instruction = "Перенесите запас товара со склада к прилавку.",
                    deliveryDistance = 520,
                },
                {
                    name = "Сверить выручку",
                    mode = "timing",
                    instruction = "Сверьте записи в торговой ведомости.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
            },
        },
        {
            name = "Закупщик",
            requiredXP = 300,
            basePay = 60,
            activities = {
                {
                    name = "Составить список",
                    mode = "timing",
                    instruction = "Подберите нужную партию товара по заказу.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
                {
                    name = "Получить поставку",
                    mode = "delivery",
                    instruction = "Доставьте оплаченный груз от точки выдачи на склад.",
                    deliveryDistance = 560,
                },
                {
                    name = "Проверить поставку",
                    mode = "timing",
                    instruction = "Сверьте количество товара с накладной.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
            },
        },
        {
            name = "Оценщик",
            requiredXP = 900,
            basePay = 94,
            activities = {
                {
                    name = "Осмотреть товар",
                    mode = "timing",
                    instruction = "Найдите признаки качества товара.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Доставить образец",
                    mode = "delivery",
                    instruction = "Отнесите образцы оценщику гильдии.",
                    deliveryDistance = 600,
                },
                {
                    name = "Назначить цену",
                    mode = "timing",
                    instruction = "Оцените стоимость по правильной шкале.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
            },
        },
    },
})
