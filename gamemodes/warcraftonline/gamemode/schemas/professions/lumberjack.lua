-- The rank catalogue is retained for future release toggles; this build exposes
-- only rank 1, whose shift can repeat deliveries until the worker settles.
WO.Professions.Register({
    id = "lumberjack",
    name = "Лесоруб",
    description = "Бесконечная смена переноски брёвен с добровольной сдачей работодателю.",
    xpPerOrder = 100,
    ranks = {
        {
            name = "Дровосек",
            requiredXP = 0,
            basePay = WO.Config.Economy.LumberjackPayPerBundle,
            activities = {
                {
                    name = "Перенести связку брёвен",
                    mode = "lumber_delivery",
                    instruction = "У штабеля нажмите E и правильно нажмите шесть случайных подсказок WASD по одной, затем отнесите связку на склад.",
                },
                {
                    name = "Подать брёвна на склад",
                    mode = "lumber_delivery",
                    instruction = "У штабеля нажмите E и верно нажмите шесть случайных подсказок WASD по одной, затем доставьте связку брёвен на склад.",
                },
                {
                    name = "Сдать последнюю связку",
                    mode = "lumber_delivery",
                    instruction = "У штабеля нажмите E и верно нажмите шесть случайных клавиш WASD по одной; сдайте связку у склада клавишей E.",
                },
            },
        },
        {
            name = "Кольщик дров",
            requiredXP = 300,
            basePay = 5500,
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
            basePay = 8600,
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
