-- Data-driven profession schema: three paid ranks and three server-validated orders per shift.
WO.Professions.Register({
    id = "lumberjack",
    name = "Лесоруб",
    description = "Лесные работы и заготовка древесины. Оформите смену в три заказа.",
    xpPerOrder = 100,
    ranks = {
        {
            name = "Дровосек",
            requiredXP = 0,
            basePay = 32,
            activities = {
                {
                    name = "Срубить дерево",
                    mode = "chopping",
                    instruction = "Подсекайте дерево и держите удар в зелёной зоне.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
                {
                    name = "Отнести брёвна",
                    mode = "delivery",
                    instruction = "Поднимите брёвна и доставьте их на склад леса.",
                    deliveryDistance = 520,
                },
                {
                    name = "Сколоть ветви",
                    mode = "chopping",
                    instruction = "Снимайте сучья точными ударами.",
                    zoneWidth = 0.24,
                    progressRate = 0.72,
                    speed = 1.05,
                },
            },
        },
        {
            name = "Кольщик дров",
            requiredXP = 300,
            basePay = 55,
            activities = {
                {
                    name = "Расколоть чурбак",
                    mode = "chopping",
                    instruction = "Попадите топором в слабое место чурбака.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
                {
                    name = "Уложить поленья",
                    mode = "chopping",
                    instruction = "Соберите ровную поленницу, удерживая маркер в зелёной зоне.",
                    zoneWidth = 0.22,
                    progressRate = 0.76,
                    speed = 1.18,
                },
                {
                    name = "Перенести охапку",
                    mode = "delivery",
                    instruction = "Отнесите связку дров от места заготовки.",
                    deliveryDistance = 560,
                },
            },
        },
        {
            name = "Лесопильщик",
            requiredXP = 900,
            basePay = 86,
            activities = {
                {
                    name = "Выставить бревно",
                    mode = "chopping",
                    instruction = "Совместите бревно с направляющей пилорамы.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Распилить доски",
                    mode = "chopping",
                    instruction = "Проведите распил без ухода маркера из зелёного сектора.",
                    zoneWidth = 0.20,
                    progressRate = 0.80,
                    speed = 1.31,
                },
                {
                    name = "Сдать пиломатериал",
                    mode = "delivery",
                    instruction = "Доставьте готовые доски на склад.",
                    deliveryDistance = 600,
                },
            },
        },
    },
})
