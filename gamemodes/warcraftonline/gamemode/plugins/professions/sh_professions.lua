--[[
    Warcraft Online — общий реестр ремёсел и сетевой контракт.

    Профессии и три ступени каждой работы задаются отдельными схемами.
    Сетевой интерфейс передаёт только выбор работы и ввод мини-игры; XP,
    завершение задач и деньги рассчитывает сервер.
]]

WO.Professions = WO.Professions or {}
WO.Professions.Registry = WO.Professions.Registry or WO.Registry.New("Professions")
WO.Professions.ClientData = WO.Professions.ClientData or nil

-- Each trade has its own world mini-game. Engines share server-side primitives,
-- but each mode has a distinct activity, controls and world-HUD presentation.
WO.Professions.MiniGames = WO.Professions.MiniGames or {
    fishing = { engine = "hold", label = "Рыбалка", controls = "Удерживайте ПРОБЕЛ, пока рыба в зелёной зоне." },
    chopping = { engine = "strike", label = "Рубка", controls = "Нажимайте ПРОБЕЛ, когда метка пилы проходит по зарубке." },
    mining = { engine = "tap", label = "Добыча руды", controls = "Ударяйте кирку ПРОБЕЛОМ, чтобы расколоть жилу." },
    sowing = { engine = "sequence", label = "Посев", controls = "Повторите порядок семян клавишами 1–4." },
    herding = { engine = "steer", axis = "horizontal", label = "Управление стадом", controls = "A / D направляют животное к отмеченным воротам." },
    loading = { engine = "alternate", label = "Погрузка", controls = "Чередуйте A и D, чтобы переносить ящики равномерно." },
    smithing = { engine = "rhythm", label = "Кузнечное дело", controls = "Куйте ПРОБЕЛОМ, попадая по раскалённой зоне." },
    sewing = { engine = "sequence", label = "Шитьё", controls = "Введите последовательность стежков клавишами 1–4." },
    baking = { engine = "alternate", label = "Замес теста", controls = "Чередуйте A и D, чтобы вымесить тесто." },
    brewing = { engine = "adjust", axis = "vertical", label = "Варка напитка", controls = "W / S удерживают температуру в рецептурном диапазоне." },
    alchemy = { engine = "sequence", label = "Алхимическая формула", controls = "Добавьте реагенты в порядке, показанном на колбах 1–4." },
    haggling = {
        engine = "choice", label = "Торговый торг",
        controls = "Оцените цель сделки и выберите ближайшее предложение клавишей 1–3.",
        choiceOptions = { "10 монет", "50 монет", "90 монет" },
    },
    sweeping = { engine = "sweep", axis = "horizontal", label = "Подметание", controls = "A / D ведут щётку по отмеченному мусору." },
    balancing = { engine = "balance", axis = "horizontal", label = "Баланс воды", controls = "A / D выравнивают коромысло и удерживают воду." },
    sawing = { engine = "alternate", label = "Распил", controls = "Чередуйте A и D, чтобы вести пилу ровно." },
    fletching = { engine = "sequence", label = "Изготовление оружия", controls = "Соберите детали в показанном порядке клавишами 1–4." },
    gemcutting = { engine = "precision", axis = "horizontal", label = "Огранка камня", controls = "A / D наведите резец, ПРОБЕЛ фиксирует грань." },
    ropemaking = { engine = "rhythm", label = "Канатная работа", controls = "Нажимайте ПРОБЕЛ в такт натяжению каната." },
    beekeeping = { engine = "dodge", label = "Сбор мёда", controls = "W / A / S / D уворачивают от пчёл и ведут к сотам." },
    herbcraft = {
        engine = "identify", label = "Опознание трав",
        controls = "Найдите заказанное растение и выберите его клавишей 1–4.",
        choiceOptions = { "Мята", "Чабрец", "Лаванда", "Полынь" },
    },
    masonry = { engine = "stack", label = "Кладка", controls = "Укладывайте камень ПРОБЕЛОМ, пока метка над швом." },
    delivery = { engine = "delivery", label = "Перенос груза", controls = "Заберите груз у точки и доставьте его, пройдя нужное расстояние." },
    lumber_delivery = {
        engine = "lumber", label = "Перенос брёвен",
        controls = "E — взять/сдать брёвна · нажмите шесть случайных подсказок WASD по очереди.",
    },
    timing = { engine = "hold", label = "Рабочий ритм", controls = "Удерживайте ПРОБЕЛ в зелёной зоне." },

}

local DEFAULT_RANK_XP = { 0, 300, 900 }

function WO.Professions.GetMiniGame(mode)
    return isstring(mode) and WO.Professions.MiniGames[mode] or nil
end

function WO.Professions.Register(def)
    if not istable(def) or not isstring(def.id) or
        not string.match(def.id, "^[a-z0-9_]+$") then
        WO.Error("WO.Professions.Register: invalid profession definition")
        return false
    end

    if not isstring(def.name) or def.name == "" or not istable(def.ranks) or #def.ranks ~= 3 then
        WO.Error("WO.Professions.Register: '" .. def.id .. "' must define exactly three ranks")
        return false
    end

    def.description = isstring(def.description) and def.description or ""
    def.xpPerOrder = math.Clamp(math.floor(tonumber(def.xpPerOrder) or 100), 1, 10000)

    for rankIndex, rank in ipairs(def.ranks) do
        if not istable(rank) or not isstring(rank.name) or rank.name == "" or
            not istable(rank.activities) or #rank.activities < 3 then
            WO.Error("WO.Professions.Register: invalid rank " .. rankIndex .. " for '" .. def.id .. "'")
            return false
        end

        rank.requiredXP = math.max(0, math.floor(tonumber(rank.requiredXP) or DEFAULT_RANK_XP[rankIndex]))
        rank.basePay = math.Clamp(math.floor(tonumber(rank.basePay) or (25 + rankIndex * 20)), 1, 100000)

        for activityIndex, activity in ipairs(rank.activities) do
            if not istable(activity) or not isstring(activity.name) or activity.name == "" or
                not WO.Professions.GetMiniGame(activity.mode) then
                WO.Error("WO.Professions.Register: invalid activity " .. activityIndex ..
                    " in rank " .. rankIndex .. " for '" .. def.id .. "'")
                return false
            end

            activity.instruction = isstring(activity.instruction) and activity.instruction or ""
        end
    end

    return WO.Professions.Registry:Register(def.id, def)
end

function WO.Professions.Get(id)
    return WO.Professions.Registry:Get(id)
end

function WO.Professions.GetAll()
    return WO.Professions.Registry:GetAll()
end

function WO.Professions.GetIDs()
    return WO.Professions.Registry:GetIDs()
end

function WO.Professions.GetLevelForXP(professionOrId, experience)
    local def = istable(professionOrId) and professionOrId or WO.Professions.Get(professionOrId)
    if not def then return 1 end

    experience = math.max(0, math.floor(tonumber(experience) or 0))

    for level = 3, 1, -1 do
        local rank = def.ranks[level]
        if experience >= (rank.requiredXP or DEFAULT_RANK_XP[level]) then
            return level
        end
    end

    return 1
end

function WO.Professions.GetSkillData(char, professionId)
    local state = char and char.professions
    local skills = istable(state) and state.skills or nil
    local skill = istable(skills) and skills[professionId] or nil
    local xp = math.max(0, math.floor(tonumber(skill and skill.xp) or 0))

    return {
        xp = xp,
        level = WO.Professions.GetLevelForXP(professionId, xp),
        completedShifts = math.max(0, math.floor(tonumber(skill and skill.completedShifts) or 0)),
    }
end

function WO.Professions.GetBonus(char, professionId)
    if not char then return 0 end

    local race = WO.Races and WO.Races.Get and WO.Races.Get(char.race)
    local class = WO.Classes and WO.Classes.Get and WO.Classes.Get(char.class)
    local raceBonus = race and race.professionBonuses and race.professionBonuses[professionId] or 0
    local classBonus = class and class.professionBonuses and class.professionBonuses[professionId] or 0

    return math.Clamp((tonumber(raceBonus) or 0) + (tonumber(classBonus) or 0), 0, 0.35)
end

function WO.Professions.GetBasePay(professionId, level, orders)
    local def = WO.Professions.Get(professionId)
    if not def then return 0 end

    level = math.Clamp(math.floor(tonumber(level) or 1), 1, 3)
    orders = math.Clamp(math.floor(tonumber(orders) or 3), 1, 3)

    return def.ranks[level].basePay * orders
end

---------------------------------------------------------------------------
-- Synchronous messages contain server snapshots; no reward data is accepted
-- back from clients.
---------------------------------------------------------------------------

WO.Net.Register("Profession.Sync", {
    direction = "toclient",
    write = function(data) net.WriteTable(data) end,
    read = function() return net.ReadTable() end,
    handler = function(_, data)
        if not CLIENT or not istable(data) then return end

        local previous = WO.Professions.ClientData
        local revisionChanged = not previous or
            previous.characterId ~= data.characterId or
            tonumber(previous.revision) ~= tonumber(data.revision)

        if istable(data.shift) and istable(data.shift.task) then
            local elapsed = math.max(0, tonumber(data.shift.task.elapsed) or 0)
            data.shift.task.clientStartedAt = CurTime() - elapsed
        end

        WO.Professions.ClientData = data
        WO.Hook.Run("ProfessionsSynced", data, revisionChanged)
    end,
})

WO.Net.Register("Profession.SyncRequest", {
    direction = "toserver",
    rate = { max = 3, window = 5 },
    read = function() end,
    validate = function(ply)
        return IsValid(ply) and ply:HasCharacter(), "no_character"
    end,
    handler = function(ply)
        if SERVER then WO.Professions.Sync(ply) end
    end,
})

WO.Net.Register("Profession.StartShift", {
    direction = "toserver",
    rate = { max = 3, window = 5 },
    write = function(professionId, rank)
        net.WriteString(professionId or "")
        net.WriteUInt(math.Clamp(math.floor(tonumber(rank) or 1), 1, 3), 2)
    end,
    read = function() return net.ReadString(), net.ReadUInt(2) end,
    validate = function(ply, professionId, rank)
        if not IsValid(ply) or not ply:HasCharacter() then return false, "no_character" end
        if not isstring(professionId) or #professionId > 48 or not WO.Professions.Get(professionId) then
            return false, "unknown_profession"
        end
        if not isnumber(rank) or rank < 1 or rank > 3 or rank ~= math.floor(rank) then
            return false, "invalid_rank"
        end
        if not WO.Professions.CanWorkAtNPC(ply, professionId) then return false, "wrong_employer" end
        return true
    end,
    handler = function(ply, professionId, rank)
        if SERVER then WO.Professions.StartShift(ply, professionId, rank) end
    end,
})

WO.Net.Register("Profession.WorkInput", {
    direction = "toserver",
    rate = { max = 14, window = 1 },
    write = function(shiftId, action, value)
        net.WriteString(shiftId or "")
        net.WriteString(action or "")
        net.WriteBool(value == true)
    end,
    read = function() return net.ReadString(), net.ReadString(), net.ReadBool() end,
    validate = function(ply, shiftId, action, value)
        if not IsValid(ply) or not ply:HasCharacter() then return false, "no_character" end
        if not isstring(shiftId) or #shiftId > 64 or not isstring(action) or #action > 16 or
            not isbool(value) then return false, "invalid_input" end
        local allowed = {
            hold = true, pickup = true, strike = true, tap = true, confirm = true,
            left = true, right = true, up = true, down = true,
            choice1 = true, choice2 = true, choice3 = true, choice4 = true,
            drop = true,
        }
        if not allowed[action] then return false, "invalid_action" end
        if (action == "pickup" or action == "drop") and not value then
            return false, "invalid_input"
        end
        return true
    end,
    handler = function(ply, shiftId, action, value)
        if SERVER then WO.Professions.HandleInput(ply, shiftId, action, value) end
    end,
})

WO.Net.Register("Profession.FinishShift", {
    direction = "toserver",
    rate = { max = 2, window = 5 },
    write = function(shiftId) net.WriteString(shiftId or "") end,
    read = function() return net.ReadString() end,
    validate = function(ply, shiftId)
        if not IsValid(ply) or not ply:HasCharacter() then return false, "no_character" end
        return isstring(shiftId) and #shiftId <= 64, "invalid_shift"
    end,
    handler = function(ply, shiftId)
        if SERVER then WO.Professions.FinishShift(ply, shiftId) end
    end,
})

WO.Net.Register("Profession.CancelShift", {
    direction = "toserver",
    rate = { max = 2, window = 5 },
    write = function(shiftId) net.WriteString(shiftId or "") end,
    read = function() return net.ReadString() end,
    validate = function(ply, shiftId)
        if not IsValid(ply) or not ply:HasCharacter() then return false, "no_character" end
        return isstring(shiftId) and #shiftId <= 64, "invalid_shift"
    end,
    handler = function(ply, shiftId)
        if SERVER then WO.Professions.CancelShift(ply, shiftId) end
    end,
})
