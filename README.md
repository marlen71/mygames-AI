# Warcraft Online

**Warcraft Online** — MMO/RPG-гейммод для Garry's Mod на GLua: создание персонажа, расы,
классы, кастомизация, инвентарь, экипировка, предметы, характеристики, уровни,
боевая система, физические предметы в мире, вид от третьего лица, MMORPG HUD
и полноценное сохранение персонажей.

Проект спроектирован как **самостоятельный MMORPG-гейммод**, вдохновлённый общей
концепцией жанра: создание персонажа → мир → прокачка → предметы → задания.

**Текущая версия: 2.3.0.** [Релиз на GitHub](https://github.com/marlen71/mygames-AI/releases/tag/warcraft-online-v2.3.0).

---

## Установка

1. Остановите сервер. Скопируйте папку `gamemodes/warcraftonline` целиком в
   `garrysmod/gamemodes/` (не в `garrysmod/addons/`). Итоговые пути должны быть:
   `garrysmod/gamemodes/warcraftonline/warcraftonline.txt` и
   `garrysmod/gamemodes/warcraftonline/gamemode/shared.lua`.
2. Укажите гейммод в параметрах запуска: `+gamemode warcraftonline`.
3. Запустите сервер. База SQLite создаётся автоматически.
4. Подключитесь заново. Откроется главное меню с кнопками «Создать персонажа»,
   «Загрузить персонажа» и «Выйти» (`disconnect`). Загрузка доступна, если у
   игрока уже есть персонажи; после создания новый персонаж автоматически
   загружается в мир.

При обновлении **замените всю старую папку** `warcraftonline`, затем перезапустите
сервер и переподключитесь клиентом — не смешивайте файлы разных версий.
При старте в консоли должны появиться `[WO] Gamemode Lua include root:
warcraftonline/gamemode` и сообщения `[WO] Plugin loaded: ...` для 27 плагинов,
включая Workshop Assets, Menu and Scoreboard и Viewmodel Hands.
`sh_plugin.lua must return a metadata table` или `Couldn't include file` означает,
что в каталоге осталась неполная/старая копия. Не продолжайте играть с такими
ошибками: UI создания персонажа и HUD зависят от загрузки плагинов.

Рекомендуемые карты: любые с `info_player_start` (gm_flatgrass, rp_* и т.д.).

---

## Возможности (MVP)

| Система | Описание |
|---|---|
| **Персонажи** | Создание (8 ясных шагов с итоговой карточкой и явным подтверждением), выбор, удаление, SQLite |
| **Расы** | Data-driven WoW races; в выборе показываются только смонтированные модели подходящего пола, без гражданского fallback |
| **Классы** | Data-driven: воин, маг, разбойник, стрелок (+ стартовые предметы и допуски) |
| **Кастомизация** | Модель, bodygroups, skin и цвет; вращающееся 3D-превью с управлением мышью/кнопками |
| **Инвентарь** | Адаптивное окно из двух блоков: предметы/ресурсы и отдельные слоты экипировки; grid 10×6, drag & drop, сортировка, стаки |
| **Предметы** | Definition vs Instance (уникальный UID, прочность), редкость, требования |
| **Экипировка** | 14 слотов в отдельной панели, проверки (уровень/класс/раса/статы), оружие в руках |
| **Мир** | Физические предметы с настоящей физикой: выброс → полёт → подбор по [E] |
| **NPC** | Fang (`wow_npc_14892`) и кабан (`wow_npc_2809`), уровни 1–5 с серверными статами; торговцы/квестодатели; спавн только в явных map-specific точках |
| **Диалоги** | Деревья диалогов с узлами и действиями (квесты, торговля, разговор) |
| **Квесты** | Типы шагов kill / collect / talk, награды (опыт/деньги/предметы), журнал (J), трекер в HUD |
| **Торговцы** | Покупка/продажа с серверным контролем цен и денег |
| **Статы** | Сила/Ловкость/Интеллект/Стамина/Дух + производные (HP, мана, броня, крит) |
| **Уровни** | Опыт, повышение уровня, пересчёт статов, уведомления |
| **Боёвка** | Server-authoritative damage/quest-death hooks; уровневые параметры внешних существ задаются схемами |
| **Стартовое оружие** | `drc_unarmed` выдаётся как обычные руки; `tfa_cso_coldsteelblade` хранится предметом `starter_knife` до экипировки в main hand; маг дополнительно получает прямой `weapon_hpwr_stick` |
| **Камера** | Третье лицо: zoom, collision, shoulder offset, сглаживание |
| **Меню/scoreboard** | Полноэкранное главное меню в едином TAB-интерфейсе; native HUD скрывается только после синхронизации активного персонажа |
| **Читаемость UI** | Общие fit/wrap-компоненты, адаптивные размеры, округлые панели и заголовки в WoW-стиле; длинный текст кнопок и окон обрезается безопасно |
| **HUD** | Кадр персонажа (HP/мана/стамина/XP), target frame, экран смерти и трекер квестов; возвращается после выбора персонажа |
| **Валюта** | Монеты (gold/silver/copper), серверный контроль |
| **Сеть** | Rate-limit, валидаторы, дельта-синхронизация, server authority |
| **Безопасность** | Валидация имён/возраста/данных, анти-дюп (машина состояний), транзакции |
| **Админ** | SAM permissions (`WO.Admin`) + debug-команды; GMod admin fallback только без SAM |

---

## Модели WoW из Steam Workshop

Гейммод использует WoW-модели из каталога Mailer и смонтированные playermodels
из Workshop (включая [Playable Characters Megapack, ID `3796529373`](https://steamcommunity.com/sharedfiles/filedetails/?id=3796529373)).
Пути-кандидаты лежат в `gamemode/config/sh_models.lua`; в создание персонажа
попадают только файлы, реально доступные через `file.Exists(..., "GAME")` и
зарегистрированные для выбранных расы/пола. Для рас, где Workshop-модель не
смонтирована, выбор временно недоступен: гражданские модели GMod намеренно не
используются как fallback. Это предотвращает неожиданную замену персонажа на
обычного гражданского и не сохраняет невалидные модели в новом персонаже.

**Паки и пути (извлечены из описаний самих аддонов):**

| Раса / пол | Workshop ID (база / exp / exp2) | Базовая модель |
|---|---|---|
| Человек, муж. | 1930795899 / 1930800507 / 1930805571 | `models/mailer/character/human/male/humanmale00_00.mdl` |
| Человек, жен. | 1930787430 / 1930791858 | `models/mailer/character/human/female/humanfemale00_00.mdl` |
| Ночной эльф, муж. | 1944399771 / 1944404675 / 1944409769 | `models/mailer/character/nightelf/male/nightelfmale00_00.mdl` |
| Ночной эльф, жен. | «[WoW] Night Elf Female» / 1944390645 / 1944395669 | `models/mailer/character/nightelf/female/nightelffemale00_00.mdl` |
| Орк, муж. | 1950316295 / 1950319321 | `models/mailer/character/orc/male/orcmale00_00.mdl` |
| Орк, жен. | 1950310689 | `models/mailer/character/orc/female/orcfemale00_00.mdl` |
| Гном, муж. | 1907948872 / 1907951439 / 1907954262 | `models/mailer/character/gnome/male/gnomemale00_00.mdl` |
| Гном, жен. | 1907944015 / 1907946461 | `models/mailer/character/gnome/female/gnomefemale00_00.mdl` |
| Дворф, нежить, таурен, тролль, гоблин | `3796529373` — runtime discovery only | Путь не угадывается; берётся из зарегистрированного `player_manager` |

Для dwarf, undead/scourge, tauren, troll и goblin путь не зашит в код без
подтверждения. Модели появляются в мастере только если аддон зарегистрировал
смонтированный `.mdl` и его identity явно указывает расу и пол; иначе раса
остаётся недоступной вместо гражданского fallback. Сервер и клиент должны иметь
одинаковые аддоны.

Expansion-паки добавляют варианты-файлы с суффиксами (сетка из описаний аддонов):
например, exp2 для человека — `humanmale00_XX_YY.mdl` (XX = 00…09, YY = 00…07).
Все существующие варианты попадают в выбор модели при создании персонажа
(переключатель «◀ ▶» на шаге «Модель»), а bodygroups (Hair / Facial Hair /
Clothes / Piercings и т.д.) настраиваются на шаге кастомизации.

Проверить, что видит сервер: `wo_models` (сводка) и `wo_models human male`
(полный список с пометками «есть/нет»).

Пути и диапазоны хранятся только в `config/sh_models.lua` — добавить новую расу
или пак можно одной записью в каталог (см. комментарии в файле).

### Коллекции и optional-ассеты Workshop

Запрошенная коллекция **World of Warcraft**, ID `3801728890`, учитывается как
ссылка, но на последней проверке Steam показывала `Items (0)`. Не считайте её
состав подтверждённым манифестом. Отдельные известные страницы:
[Playable Characters Megapack `3796529373`](https://steamcommunity.com/sharedfiles/filedetails/?id=3796529373)
и [Creatures Megapack `3798571666`](https://steamcommunity.com/sharedfiles/filedetails/?id=3798571666).
Их IDs и другие известные зависимости перечислены в
`config/sh_workshop.lua`. `resource.AddWorkshop` просит клиент скачать контент,
но сервер всё равно должен установить и смонтировать addons локально.

Точные запрошенные runtime-классы заданы явно:

- NPC: `wow_npc_14892` (Fang / Клык), `wow_npc_2809` (кабан);
- SWEP: `drc_unarmed`, `tfa_cso_coldsteelblade`, `weapon_hpwr_stick`.

Плагин `plugins/workshop` проверяет эти значения в реестрах GMod. Он не подменяет
не найденный класс похожим. Команда `wo_workshop_assets` (SAM permission
`wo_debug`) показывает `registered`/`MISSING`; при отсутствии обязательного
класса loadout пропускается, а внешний NPC не создаётся. Проверяйте статус на
самом dedicated server после установки Workshop-паков.

Стандартные руки `drc_unarmed` выдаются сервером напрямую. Нож `tfa_cso_coldsteelblade`
до экипировки хранится как обычный предмет `starter_knife` и появляется в руках
только после помещения в main-hand; маг дополнительно получает прямой `weapon_hpwr_stick`.
Legacy-определение `arcane_hands` остаётся отключённым, а старые персонажи однократно
мигрируют к инвентарному ножу без повторной выдачи. Схемы сохраняют баланс NPC,
предметов, квестов и наград на стороне Warcraft Online.

Позиция и угол персонажа сохраняются при autosave/выходе; возврат на ту же карту
восстанавливает сохранённое место. У новой записи без позиции используется обычная
map spawn point, а не искусственная координата у начала мира.

Плагин `plugins/workshop` принимает модель только при наличии файла в mounted
virtual filesystem (`file.Exists(..., "GAME")`). Если аддон не публикует модель
в стандартном реестре NPC, администратор может включить ограниченный recursive
scan в `config/sh_workshop.lua` (`WO.Config.Workshop.DeepModelDiscovery = true`)
или внести вручную проверенный путь в `WO.Config.WorkshopModelOverrides`:

```lua
WO.Config.WorkshopModelOverrides = {
    wow_wolf = { "models/<проверенный-путь>/wolf.mdl" },
    wow_vendor = { "models/<проверенный-путь>/merchant.mdl" },
}
```

Не вводите path по догадке. У стандартного c_arms свой отдельный fallback
`models/weapons/c_arms.mdl`; он не меняет модель персонажа.

---

## NPC, квесты, диалоги, торговцы

Всё data-driven — новый контент = новые файлы схем, без изменения ядра:

| Что добавить | Файл | Пример |
|---|---|---|
| NPC (квестодатель/торговец/существо) | `schemas/npcs/<id>.lua` | `schemas/npcs/marshal_dughal.lua` |
| Диалог (дерево узлов и действий) | `schemas/dialogues/<id>.lua` | `schemas/dialogues/marshal_intro.lua` |
| Квест (шаги kill/collect/talk + награды) | `schemas/quests/<id>.lua` | `schemas/quests/wolves_of_elwynn.lua` |

- NPC не появляются в случайных точках. Для каждого нужно задать map-specific
  `pos = Vector(...)` либо существующий `anchor` с `anchorIndex` и явным `offset`;
  пустая/невалидная точка ничего не спавнит. Точки хаба привязаны к
  `gm_construct` (карта подтверждена); для других карт добавьте свои точки в
  `WO.Config.NPCSpawnPoints`
  (`config/sh_settings.lua`).
- `hunter_dyrne` последовательно предлагает `wolves_of_elwynn` и `boar_hunt`;
  семь Fang (`black_wolf`, точный класс `wow_npc_14892`, уровни 1–5) и семь кабанов
  (`wow_npc_2809`) появляются только после принятия соответствующего задания.
  Группа существует, пока хотя бы один игрок выполняет квест, и убитые цели
  восстанавливаются в тех же точках; после отказа/завершения последним активным
  игроком группа удаляется. У обоих существ серверные характеристики заданы
  для каждого уровня 1–5.
  Смерть внешнего NPC обрабатывается серверными `OnNPCKilled`/
  `PostEntityTakeDamage` hooks с защитой от двойного прогресса.
- Торговец и квестодатель имеют разные 3D-маркеры (`$`, `!`, `?`). Клавиша E
  проходит через `SetUseType(SIMPLE_USE)`, общий диапазон 100 единиц и серверный
  `CanInteract`/`TryInteract`; диалог/торговая сессия повторно проверяет сущность,
  игрока и дистанцию.
- Действия диалога: `close`, `next:<узел>`, `quest:<id>`, `vendor`, `talk:<npcId>`.
- Квесты хранятся в БД (`wo_quests`), прогресс собирается сервером
  (убийства NPC, предметы в инвентаре, разговоры), награды выдаются сервером.
- Торговец описывается прямо в схеме NPC (`vendor = { stock = ..., sellRate = ... }`);
  все цены и деньги контролируются сервером.
- Трекер квестов — в правом верхнем углу HUD, журнал — клавиша `J`.

---

## Тесты и отладка

В `tools/` лежит smoke-тест стенд (Lupa + моки GMod API + SQLite). Запуск из корня:

```bash
python3 -m venv .venv
.venv/bin/pip install -r requirements-test.txt
.venv/bin/python tools/smoke_test.py          # сервер + клиент
.venv/bin/python tools/smoke_test.py server   # только сервер
.venv/bin/python tools/smoke_test.py client   # только клиент
```

Проверяются загрузка обоих realms, плагины, создание/сохранение/выбор персонажа,
отклонение гражданской/невалидной модели, точные стартовые SWEP-классы и запрет
старых starter-предметов, HUD и общие UI-компоненты, инвентарь/экипировка, SAM,
явные NPC-spawn точки, точные Fang/boar классы и уровневые статы 1–5, E/`SIMPLE_USE`
и серверная дистанция, диалоги/квестовые сессии/торговля, начисление наград и
обработка убийства NPC без дублирования. Registry и Workshop-модели в стенде
мокируются: это проверяет логику, но не подтверждает фактическую регистрацию
классов или видимость моделей в реальном GMod. После установки addon проверьте
серверной командой `wo_workshop_assets`, затем вручную протестируйте анимации,
HUD и визуальную отрисовку на клиенте Garry's Mod.

---

## Управление

| Клавиша | Действие |
|---|---|
| `Tab` | Единый menu/scoreboard; открыть при нажатии, закрыть при отпускании |
| `I` | Инвентарь: предметы/ресурсы и экипировка в отдельных панелях |
| `C` | Лист персонажа (статы) |
| `J` | Журнал заданий |
| `F3` | Выбор цели / сброс цели |
| `E` | Взаимодействие (предмет, NPC, торговец) |
| `Колесо мыши` | Zoom камеры |
| `ЛКМ по предмету` | Перетащить (drag & drop) |
| `ПКМ по предмету` | Меню: использовать / выбросить / уничтожить |

---

## Структура проекта

```
gamemodes/warcraftonline/
├── warcraftonline.txt            # дескриптор гейммода
├── gamemode/
│   ├── init.lua / cl_init.lua / shared.lua   # точка входа + загрузчик
│   ├── core/                     # фундамент
│   │   ├── sh_core.lua           # namespace'ы, логирование (WO.Log/Warn/Error/Debug)
│   │   ├── sh_hooks.lua          # внутренние хуки WO.Hook
│   │   ├── sh_network.lua        # WO.Net (rate limit, валидаторы)
│   │   ├── sh_registry.lua       # фабрика реестров (проверка дубликатов ID)
│   │   ├── sh_character.lua      # класс персонажа + валидация
│   │   ├── sv_database.lua       # абстракция БД (SQLite → MySQL-ready) + миграции
│   │   ├── sv_savequeue.lua      # dirty state / queued save
│   │   ├── sv_characters.lua     # CRUD персонажей (server authority)
│   │   └── ...
│   ├── plugins/                  # независимые плагины (metadata + sh/sv/cl)
│   │   ├── character/            # UI создания/выбора персонажа
│   │   ├── races/ classes/ customization/
│   │   ├── items/ inventory/ equipment/
│   │   ├── stats/ leveling/ combat/ weapons/
│   │   ├── world/ interaction/ currency/
│   │   ├── thirdperson/ targeting/ hud/
│   │   ├── notifications/ admin/ debug/
│   ├── schemas/                  # КОНТЕНТ (data-driven, без изменения ядра)
│   │   ├── races/                # human.lua, elf.lua, dwarf.lua, orc.lua
│   │   ├── classes/              # warrior.lua, mage.lua, rogue.lua, ranger.lua
│   │   └── items/                # iron_sword.lua, health_potion.lua, ...
│   ├── weapons/                  # SWEP base + melee/magic оружие
│   ├── entities/                 # wo_item_world (физический предмет)
│   ├── config/                   # ВСЕ настройки баланса
│   ├── ui/                       # дизайн-система (тема, шрифты, компоненты)
│   └── localization/             # ru.lua, en.lua
```

### Ключевые принципы

1. **Модульность** — каждый плагин независим, возвращает metadata-таблицу из
   `sh_plugin.lua`; загрузчик проверяет зависимости и сортирует загрузку.
   Все динамические `include`/`AddCSLuaFile` используют абсолютный GMod-путь
   `<FolderName>/gamemode/...`, поэтому плагины грузятся из вложенных каталогов.
2. **Server authority** — клиент НИКОГДА не решает: деньги, предметы, урон, опыт,
   экипировку, создание предметов. Клиент отправляет *запросы*, сервер валидирует.
3. **Data-driven контент** — новая раса/класс/предмет = новый файл в `schemas/`.
4. **Item Definition vs Instance** — описание предмета хранится один раз;
   экземпляры (`uid`, `durability`) сохраняются и синхронизируются.
5. **Анти-дюп** — машина состояний предмета
   (`INVENTORY → EQUIPPED → WORLD → DESTROYED`) + транзакции с откатом.
6. **Производительность** — нет SQL/тяжёлых операций в Think/HUDPaint,
   дельта-сеть, таймеры вместо постоянных проверок.

---

## Как расширять

### Добавить предмет

`gamemode/schemas/items/my_item.lua`:

```lua
WO.Items.Register({
    id = "my_item",
    name = "Мой предмет",
    type = "consumable",
    model = "models/props_junk/PopCan01a.mdl",
    size = { w = 1, h = 1 },
    stackable = true,
    maxStack = 5,
    rarity = "rare",
    description = "Описание в тултипе.",
    consumable = { heal = 100 },
    price = { buy = 50, sell = 12 },
})
```

### Добавить расу / класс

`gamemode/schemas/races/my_race.lua` → `WO.Races.Register({ ... })`
`gamemode/schemas/classes/my_class.lua` → `WO.Classes.Register({ ... })`

### Добавить плагин

Создайте `gamemode/plugins/my_plugin/`:

```lua
-- sh_plugin.lua
return {
    name = "My Plugin",
    id = "my_plugin",
    author = "Me",
    version = "1.0.0",
    dependencies = { "items" },
    priority = 45,
}
```

Файлы `sh_*` / `sv_*` / `cl_*` в папке плагина загрузятся автоматически.

---

## Debug-команды (только админы)

Если SAM загружен, плагин регистрирует в нём права `wo_character_edit`,
`wo_item_give`, `wo_money_give`, `wo_npc_spawn`, `wo_quest_complete`,
`wo_teleport` и `wo_debug` (по умолчанию уровень `admin`). Выдавайте права
нужным группам через штатную настройку SAM; при наличии SAM встроенные
`IsAdmin`/`IsSuperAdmin` не используются как обход разрешений. GMod fallback
включается только если SAM вообще не загружен.

| Команда | Действие |
|---|---|
| `wo_debug` | Переключить debug-режим |
| `wo_giveitem <class> [n]` | Выдать предмет себе |
| `wo_spawnitem <class>` | Бросить физический предмет в мир |
| `wo_givexp <n>` | Выдать опыт |
| `wo_setlevel <n>` | Установить уровень |
| `wo_setmoney <n>` | Установить деньги |
| `wo_setstat <stat> <n>` | Временный модификатор стата |
| `wo_reloadconfig` | Hot-reload конфигов и схем |
| `wo_info` | Информация о загруженных системах |
| `wo_models [race] [gender]` | Каталог моделей WoW: только реально смонтированные Mailer/Workshop-файлы |
| `wo_workshop_assets` | Runtime-статус точных моделей, NPC/SWEP-классов и внешних аддонов |
| `wo_npc_respawn` | Пересоздать всех NPC на карте |
| `wo_npc_list` | Список зарегистрированных NPC |

---

## Сохранение

- SQLite через абстрактный слой `WO.Database` (готов к MySQL-драйверу).
- Миграции схемы: `WO.Database:RegisterMigration(version, fn)`.
- Autosave каждые 60 сек + при выходе, смене персонажа и остановке сервера.
- Dirty state / queued save: изменения не пишутся в БД после каждого клика.

---

## Roadmap (следующие этапы)

- ~~NPC, квесты, диалоги, quest tracker~~ (реализовано)
- ~~Торговцы~~ (реализовано)
- Способности, action bar, cast bar, статус-эффекты
- Пати, фракции, PvP-зоны, торговля между игроками
- Банк, крафт, карта, достижения, ремонт

---

## Лицензия

Проект создан для образовательных и развлекательных целей.
Warcraft и World of Warcraft — торговые марки Blizzard Entertainment;
проект не связан с Blizzard и не использует их проприетарный контент.
