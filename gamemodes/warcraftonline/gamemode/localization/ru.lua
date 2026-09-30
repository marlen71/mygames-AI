--[[
    Warcraft Online — локализация: русский.
]]

WO.Lang.Register("ru", {
    -----------------------------------------------------------------------
    -- Общее
    -----------------------------------------------------------------------
    ["ui.ok"] = "ОК",
    ["ui.cancel"] = "Отмена",
    ["ui.close"] = "Закрыть",
    ["ui.back"] = "Назад",
    ["ui.next"] = "Далее",
    ["ui.confirm"] = "Подтвердить",
    ["ui.delete"] = "Удалить",
    ["ui.create"] = "Создать",
    ["ui.save"] = "Сохранить",
    ["ui.yes"] = "Да",
    ["ui.no"] = "Нет",

    -----------------------------------------------------------------------
    -- Персонаж
    -----------------------------------------------------------------------
    ["character.create"] = "Создание персонажа",
    ["character.select"] = "Выбор персонажа",
    ["character.create_failed"] = "Не удалось создать персонажа",
    ["character.select_failed"] = "Не удалось выбрать персонажа",
    ["character.deleted"] = "Персонаж удалён",
    ["character.delete_failed"] = "Не удалось удалить персонажа",
    ["character.delete_confirm"] = "Вы уверены, что хотите удалить этого персонажа?",
    ["character.no_characters"] = "У вас нет персонажей",
    ["character.logout"] = "Выйти из персонажа",
    ["character.main_menu"] = "Главное меню",
    ["character.menu.create"] = "Создать персонажа",
    ["character.menu.load"] = "Загрузить персонажа",
    ["character.menu.exit"] = "Выйти",
    ["character.no_saved_characters"] = "Сохранённых персонажей пока нет",
    ["character.back_to_menu"] = "В главное меню",
    ["character.rotate_left"] = "Повернуть влево",
    ["character.rotate_right"] = "Повернуть вправо",
    ["character.rotate_hint"] = "Потяните мышью или используйте кнопки поворота",

    ["character.step.race"] = "Раса",
    ["character.step.gender"] = "Пол",
    ["character.step.age"] = "Возраст",
    ["character.step.name"] = "Имя",
    ["character.step.surname"] = "Фамилия",
    ["character.step.customization"] = "Внешность",
    ["character.step.class"] = "Класс",
    ["character.step.preview"] = "Предпросмотр",
    ["character.step.confirm"] = "Подтверждение",

    ["character.name"] = "Имя",
    ["character.surname"] = "Фамилия",
    ["character.age"] = "Возраст",
    ["character.gender"] = "Пол",
    ["character.race"] = "Раса",
    ["character.class"] = "Класс",
    ["character.model"] = "Модель",
    ["character.level"] = "Уровень",
    ["character.full_name"] = "Полное имя",
    ["character.selected_class"] = "Выбранный класс",
    ["character.class_unselected"] = "не выбран",
    ["character.review_instructions"] = "Проверьте данные персонажа. Для отправки отметьте подтверждение ниже.",
    ["character.create_confirm_check"] = "Подтверждаю создание этого персонажа",
    ["character.create_confirm_action"] = "Подтвердить и создать",
    ["character.confirm_required"] = "Подтвердите создание персонажа перед отправкой",

    ["menu.title"] = "Warcraft Online",
    ["menu.overview"] = "Обзор и игроки",
    ["menu.overview_subtitle"] = "Состояние персонажа и список игроков на сервере",
    ["menu.characters"] = "Персонажи",
    ["menu.characters_subtitle"] = "Создайте персонажа или загрузите сохранённого",
    ["menu.inventory"] = "Инвентарь",
    ["menu.sheet"] = "Характеристики",
    ["menu.quests"] = "Журнал заданий",
    ["menu.players"] = "Игроки на сервере",
    ["menu.server_players"] = "Игроков",
    ["menu.no_players"] = "Список игроков пуст",
    ["menu.no_character"] = "Персонаж не выбран. Создайте нового или загрузите сохранённого.",
    ["menu.character_none"] = "Активный персонаж не выбран",
    ["menu.saved_characters"] = "Сохранённых персонажей",
    ["menu.logout_before_switch"] = "Сначала выйдите из активного персонажа.",
    ["menu.exit"] = "Выйти из игры",

    ["gender.male"] = "Мужской",
    ["gender.female"] = "Женский",

    -----------------------------------------------------------------------
    -- Характеристики
    -----------------------------------------------------------------------
    ["stats.strength"] = "Сила",
    ["stats.agility"] = "Ловкость",
    ["stats.intelligence"] = "Интеллект",
    ["stats.stamina"] = "Стамина",
    ["stats.spirit"] = "Дух",
    ["stats.maxHealth"] = "Здоровье",
    ["stats.maxMana"] = "Мана",
    ["stats.maxStamina"] = "Выносливость",
    ["stats.attackPower"] = "Сила атаки",
    ["stats.spellPower"] = "Сила заклинаний",
    ["stats.armor"] = "Броня",
    ["stats.magicResistance"] = "Сопротивление магии",
    ["stats.critChance"] = "Шанс крита",
    ["stats.critMultiplier"] = "Множитель крита",
    ["stats.attackSpeed"] = "Скорость атаки",

    -----------------------------------------------------------------------
    -- Инвентарь / предметы
    -----------------------------------------------------------------------
    ["inventory.title"] = "Инвентарь",
    ["inventory.empty"] = "Инвентарь пуст",
    ["inventory.drop"] = "Выбросить",
    ["inventory.use"] = "Использовать",
    ["inventory.equip"] = "Экипировать",
    ["inventory.unequip"] = "Снять",
    ["inventory.destroy"] = "Уничтожить",
    ["inventory.split"] = "Разделить",
    ["inventory.no_space"] = "Недостаточно места",
    ["inventory.item_received"] = "Получен предмет: %s",
    ["inventory.item_lost"] = "Предмет потерян: %s",
    ["inventory.full"] = "Инвентарь полон",
    ["inventory.items_count"] = "Предметы",
    ["inventory.loading"] = "Загрузка инвентаря…",
    ["inventory.sort"] = "Сортировать",
    ["inventory.invalid_drop_position"] = "Нельзя переместить предмет в эту ячейку",

    ["item.type.weapon"] = "Оружие",
    ["item.type.armor"] = "Броня",
    ["item.type.helmet"] = "Шлем",
    ["item.type.boots"] = "Сапоги",
    ["item.type.gloves"] = "Перчатки",
    ["item.type.ring"] = "Кольцо",
    ["item.type.amulet"] = "Амулет",
    ["item.type.food"] = "Еда",
    ["item.type.drink"] = "Напиток",
    ["item.type.consumable"] = "Расходник",
    ["item.type.material"] = "Материал",
    ["item.type.quest"] = "Квестовый предмет",
    ["item.type.container"] = "Контейнер",
    ["item.type.currency"] = "Валюта",
    ["item.type.misc"] = "Разное",
    ["item.type.special"] = "Особый",

    ["item.weight"] = "Вес",
    ["item.damage"] = "Урон",
    ["item.durability"] = "Прочность",
    ["item.requirements"] = "Требования",
    ["item.required_level"] = "Требуемый уровень",
    ["item.required_class"] = "Требуемый класс",
    ["item.required_race"] = "Требуемая раса",
    ["item.broken"] = "Сломано",
    ["item.stack"] = "Количество",

    ["rarity.poor"] = "Низкое качество",
    ["rarity.common"] = "Обычный",
    ["rarity.uncommon"] = "Необычный",
    ["rarity.rare"] = "Редкий",
    ["rarity.epic"] = "Эпический",
    ["rarity.legendary"] = "Легендарный",
    ["rarity.artifact"] = "Артефакт",
    ["rarity.quest"] = "Квестовый",

    -----------------------------------------------------------------------
    -- Слоты экипировки
    -----------------------------------------------------------------------
    ["slot.head"] = "Голова",
    ["slot.neck"] = "Шея",
    ["slot.shoulders"] = "Плечи",
    ["slot.chest"] = "Грудь",
    ["slot.back"] = "Спина",
    ["slot.hands"] = "Кисти",
    ["slot.belt"] = "Пояс",
    ["slot.legs"] = "Ноги",
    ["slot.feet"] = "Ступни",
    ["slot.main_hand"] = "Правая рука",
    ["slot.off_hand"] = "Левая рука",
    ["slot.ring_1"] = "Кольцо 1",
    ["slot.ring_2"] = "Кольцо 2",
    ["slot.amulet"] = "Амулет",

    -----------------------------------------------------------------------
    -- Экипировка / меню
    -----------------------------------------------------------------------
    ["equipment.title"] = "Экипировка",
    ["character_menu.title"] = "Персонаж",
    ["character_menu.stats"] = "Характеристики",
    ["character_menu.inventory"] = "Инвентарь",
    ["character_menu.equipment"] = "Экипировка",
    ["character_menu.quests"] = "Задания",

    -----------------------------------------------------------------------
    -- Мир / интеракция
    -----------------------------------------------------------------------
    ["interact.pickup"] = "Поднять",
    ["interact.talk"] = "Поговорить",
    ["interact.open"] = "Открыть",
    ["interact.use"] = "Использовать",
    ["interact.key"] = "[E]",

    -----------------------------------------------------------------------
    -- Прогресс
    -----------------------------------------------------------------------
    ["xp.gain"] = "+%d опыта",
    ["xp.reason.kill"] = "За убийство",
    ["xp.reason.quest"] = "За задание",
    ["levelup.text"] = "Вы достигли %d уровня!",
    ["levelup.title"] = "Новый уровень",

    -----------------------------------------------------------------------
    -- Прочее
    -----------------------------------------------------------------------
    ["notify.error"] = "Ошибка",
    ["notify.success"] = "Успех",
    ["notify.info"] = "Информация",
    ["death.title"] = "Вы погибли",
    ["death.respawn"] = "Возрождение через %d сек.",
    ["currency.name"] = "Монеты",
    ["target.none"] = "Нет цели",
    -----------------------------------------------------------------------
    -- Квесты / диалоги / торговля
    -----------------------------------------------------------------------
    ["quest.log_title"] = "Журнал заданий",
    ["quest.log_empty"] = "Заданий пока нет",
    ["quest.status_active"] = "Активно",
    ["quest.status_completed"] = "Завершено",
    ["quest.track"] = "Отслеживать",
    ["quest.untrack"] = "Не отслеживать",
    ["quest.abandon"] = "Отказаться",
    ["quest.accepted"] = "Задание получено",
    ["quest.completed"] = "Задание выполнено",
    ["quest.abandoned"] = "Задание отменено",
    ["quest.in_progress"] = "Задание уже выполняется",
    ["quest.already_completed"] = "Задание уже выполнено",
    ["quest.not_available"] = "Задание недоступно",
    ["quest.no_quests"] = "У меня пока нет заданий",
    ["dialogue.title"] = "Диалог",
    ["vendor.title"] = "Торговля",
    ["vendor.buy"] = "Покупка",
    ["vendor.sell"] = "Продажа",
    ["vendor.buy_one"] = "Купить",
    ["vendor.sell_one"] = "Продать",
    ["vendor.no_items"] = "Нет предметов для продажи",
    ["vendor.not_enough_money"] = "Недостаточно монет",
    ["vendor.inventory_full"] = "Инвентарь полон",
    ["currency.coins"] = "монет",
    ["npc.interact"] = "[E] Взаимодействовать",
})
