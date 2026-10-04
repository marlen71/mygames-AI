# Warcraft Online

**Warcraft Online** — MMO/RPG-гейммод для Garry's Mod на GLua: создание персонажа, расы,
классы, кастомизация, инвентарь, экипировка, предметы, характеристики, уровни,
боевая система, физические предметы в мире, вид от третьего лица, MMORPG HUD
и полноценное сохранение персонажей.

Проект спроектирован как **самостоятельный MMORPG-гейммод**, вдохновлённый общей
концепцией жанра: создание персонажа → мир → прокачка → предметы → задания.

**Последний релиз: 2.4.7.** [Релиз на GitHub](https://github.com/marlen71/mygames-AI/releases/tag/warcraft-online-v2.4.7).

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
warcraftonline/gamemode` и сообщения `[WO] Plugin loaded: ...` для 31 плагина,
включая Workshop Assets, Menu and Scoreboard и Viewmodel Hands.
`sh_plugin.lua must return a metadata table` или `Couldn't include file` означает,
что в каталоге осталась неполная/старая копия. Не продолжайте играть с такими
ошибками: UI создания персонажа и HUD зависят от загрузки плагинов.

Рекомендуемые карты: любые с `info_player_start` (gm_flatgrass, rp_* и т.д.).

---

## Возможности (MVP)

| Система | Описание |
|---|---|
| **Персонажи** | Создание (8 ясных шагов с итоговой карточкой и явным подтверждением), выбор, удаление, SQLite; тематические имена и фамилии для всех рас; серверный лимит — 2 персонажа обычному игроку и 5 администратору (покупок слотов нет) |
| **Расы** | 17 data-driven рас с русскими названиями и расширенными кириллическими пулами имён/фамилий; race/gender-модели берутся из явного каталога без проверки file.Exists и гражданского fallback; Blood Elf, Dracthyr и Vulpera помечены «Особая раса» и создаются только после серверной проверки прав; покупка рас и платёжная интеграция не реализованы |
| **Классы** | 13 data-driven классов: воин, маг, разбойник, охотник, паладин, жрец, друид, шаман, чернокнижник, монах, рыцарь смерти, охотник на демонов, пробудитель (+ стартовые предметы и допуски) |
| **Кастомизация** | Модель, bodygroups, skin и цвет; общее 3D-превью напрямую получает заданный путь, не блокируется локальным обнаружением моделей и не подменяется citizen-моделью |
| **Инвентарь** | Адаптивное окно из двух блоков: предметы/ресурсы и отдельные слоты экипировки; фиксированная сетка 10×6 (60 ячеек, каждый предмет 1×1 независимо от веса), drag & drop, сортировка, стаки; переполнение старого сейва сохраняется в резерве и возвращается в сетку при освобождении места |
| **Предметы** | Definition vs Instance (уникальный UID, прочность), редкость, требования; glyph fallback для предметов без модели и надежный подбор выпавшего лута |
| **Экипировка** | 14 слотов в отдельной панели, проверки (уровень/класс/раса/статы), оружие в руках |
| **Мир** | Физические предметы с настоящей физикой: выброс → полёт → подсказка и подбор по [E] (с коротким ассистом при промахе eye trace); модели отсутствующих предметов заменяются видимым предметом-представителем, а glyph остаётся в UI |
| **Настройки** | В игровом меню есть opt-in автосбор квестовых, редких и ценных ресурсов; выключен по умолчанию, настройка сохраняется сервером, право и условия pickup проверяются только сервером |
| **NPC** | Враждебные внешние классы `wow_npc_14892` (волк) и `wow_npc_2809` (кабан), `wow_npc_8883` (лошадь); только точные классы без случайного fallback, уровни/статы и физический loot; статические NPC только в заданных map-specific точках |
| **Диалоги** | Динамические диалоги с серверной выдачей/сдачей заданий, торговлей, знакомством и отказом при недоступном действии |
| **Квесты** | Охотник выдаёт и принимает охоту на 4 кабанов и нож при принятии; после prerequisite Маршал выдаёт и принимает охоту на 4 волков; хлебный сбор независим; журнал (J), обновляемый трекер и маркер маршрута к текущей цели/сдаче, который исчезает при входе в радиус точки |
| **Торговцы** | Покупка и продажа доступных предметов прямо из инвентаря NPC-торговцу; сервер контролирует дистанцию, владение, предмет, цены и деньги. Продажи между игроками нет |
| **Заклинания** | Маг, жрец, друид, шаман, чернокнижник и пробудитель получают `wo_magic_grimoire`; Малигос продаёт 35 свитков для 7 заклинаний/5 рангов; наличие свитка в инвентаре автоматически даёт заклинание/ранг без использования или расходования, сервер пересчитывает прогресс; старые свитки можно продать NPC |
| **Маунты** | Уникальный reusable mount stone, точный класс лошади `wow_npc_8883`, здоровье/голод/уровень/броня в инвентаре; кормление, тренировка, лечение и броня конкретного маунта |
| **Статы** | Сила/Ловкость/Интеллект/Стамина/Дух + производные (HP, мана, броня, крит) |
| **Уровни** | Опыт, уведомление `+XP`, шкала прогресса и точное оставшееся XP в HUD, листе персонажа, карточках и scoreboard |
| **Боёвка** | Server-authoritative damage/quest-death hooks; реальный урон от падения рассчитывается как скорость падения / 8 и проходит через общий combat pipeline; уровневые параметры внешних существ задаются схемами; floating combat text над NPC/игроками поднимается и затухает как в WoW |
| **Стартовое оружие** | `drc_unarmed` — обычные руки; `starter_knife` выдаётся Охотником только при принятии `boar_hunt` (не при создании персонажа, без ограничений класса/расы) и даёт точный `tfa_cso_coldsteelblade` после экипировки в main hand; магические классы используют `wo_magic_grimoire` |
| **Социальная идентичность** | Знакомство взаимное через F2 (шёпот/разговор/крик); до знакомства scoreboard и nameplate не раскрывают имя, класс и уровень |
| **Камера** | Третье лицо: zoom по `Alt` + колёсико, collision, shoulder offset, сглаживание |
| **Меню/scoreboard** | Полноэкранное главное меню, настройки и приватный список игроков в TAB; selector оружия справа переключается только клавишами 1–0 и скрывается после выбора, обычное колесо его не переключает; админ-каталог проверяется сервером на каждом действии |
| **Читаемость UI** | Общие fit/wrap-компоненты, адаптивные размеры, округлые панели и заголовки в WoW-стиле; текст обрезается безопасно, кнопки обрабатывают действие сразу и блокируют только повторный запрос на время ответа сервера |
| **HUD** | Собственный WoW HUD, квестовый маршрут, кадр персонажа (HP/мана/стамина/XP), NPC halo и плашка имени/уровня/здоровья при наведении, точный прицел и floating damage text; весь stock HUD Garry's Mod, включая killfeed и engine target-ID, скрыт даже в лимбо |
| **Валюта** | Монеты (gold/silver/copper), серверный контроль |
| **Сеть** | Rate-limit, валидаторы, дельта-синхронизация, server authority |
| **Безопасность** | Валидация имён/возраста/данных, анти-дюп (машина состояний), транзакции |
| **Админ** | SAM permissions (`WO.Admin`) + серверный data-driven каталог команд; noclip запрещён всем, включая администраторов; GMod admin fallback только без SAM |

---

## Модели персонажей

Race/gender allowlist объявлен явно в `gamemode/config/sh_models.lua`.
Мастер создания, карточки выбора, HUD-портреты и серверная модель игрока
используют заданный путь напрямую: список не фильтруется через `file.Exists`,
`util.IsValidModel` или `player_manager`, и не требует Workshop discovery.
Сервер по-прежнему проверяет, что путь входит в каталог конкретных расы и пола,
но не блокирует его по локальному статусу файла. Citizen/обычная модель не
используется ни как fallback, ни как замена превью.

Файлы моделей должны быть доступны самой игре на сервере/клиенте для отрисовки;
если движок не смог создать модельный entity, интерфейс не подменяет её другим
персонажем и повторяет прямую попытку загрузки. Для новой модели добавьте точный
путь в `config/sh_models.lua`. Модели персонажей не запрашиваются через
`resource.AddWorkshop`; список обязательных внешних NPC/SWEP-паков описан отдельно.

Базовые race/gender пути каталога:

| Раса / пол | Модель |
|---|---|
| Человек, муж. | `models/mailer/character/human/male/humanmale00_00.mdl` |
| Человек, жен. | `models/mailer/character/human/female/humanfemale00_00.mdl` |
| Ночной эльф, муж. | `models/mailer/character/nightelf/male/nightelfmale00_00.mdl` |
| Ночной эльф, жен. | `models/mailer/character/nightelf/female/nightelffemale00_00.mdl` |
| Орк, муж. | `models/mailer/character/orc/male/orcmale00_00.mdl` |
| Орк, жен. | `models/mailer/character/orc/female/orcfemale00_00.mdl` |
| Гном, муж. | `models/mailer/character/gnome/male/gnomemale00_00.mdl` |
| Гном, жен. | `models/mailer/character/gnome/female/gnomefemale00_00.mdl` |
| Гоблин, муж. | `models/mailer/character/goblin/male/goblinmale00_00.mdl` |
| Гоблин, жен. | `models/mailer/character/goblin/female/goblinfemale00_00.mdl` |
| Таурен, муж. | `models/mailer/character/tauren/male/taurenmale00_00.mdl` |
| Таурен, жен. | `models/mailer/character/tauren/female/taurenfemale00_00.mdl` |
| Тролль, муж. | `models/mailer/character/troll/male/trollmale00_00.mdl` |
| Тролль, жен. | `models/mailer/character/troll/female/trollfemale00_00.mdl` |
| Нежить, муж. | `models/mailer/character/scourge/male/scourgemale00_00.mdl` |
| Нежить, жен. | `models/mailer/character/scourge/female/scourgefemale00_00.mdl` |
| Дворф, муж. | `models/mailer/wow/character/dwarf/male/dwarfmale_00_00_hd.mdl` |
| Дворф, жен. | `models/mailer/wow/character/dwarf/female/dwarffemale_00_00_hd.mdl` |
| Кровавый эльф, муж. (особая) | `models/mailer/wow/character/bloodelf/male/bloodelfmale_00_00_hd.mdl` |
| Кровавый эльф, жен. (особая) | `models/mailer/wow/character/bloodelf/female/bloodelffemale_00_00_hd.mdl` |
| Драктир (особая), оба пола | `models/mailer/wow/character/dracthyr/dracthyrdragon_00_00_hd_l.mdl`; `models/mailer/wow/character/dracthyr/dracthyrdragon_00_00_c_l.mdl` |
| Дреней, муж. | `models/mailer/wow/character/draenei/male/draeneimale_00_00_hd.mdl` |
| Дреней, жен. | `models/mailer/wow/character/draenei/female/draeneifemale_00_00_hd.mdl` |
| Пандарен, муж. | `models/mailer/character/pandaren/male/pandarenmale00_00.mdl`; варианты `00–05 × 00–02` |
| Пандарен, жен. | `models/mailer/character/pandaren/female/pandarenfemale00_00.mdl`; варианты `00–03 × 00–04` |
| Ворген, муж. | `models/mailer/character/worgen/male/worgenmale00_00.mdl` |
| Ворген, жен. | `models/mailer/character/worgen/female/worgenfemale00_00.mdl` |
| Вульпера, муж. (особая) | `models/mailer/wow_characters/wowanim_vulpera_male.mdl` |
| Вульпера, жен. (особая) | `models/mailer/wow_characters/wowanim_vulpera_female.mdl` |
| Сетрак, оба пола | `models/mailer/wow_characters/wowanim_sethrak.mdl` |
| Нага, муж. | `models/mailer/wow_characters/wowanim_naga_male.mdl` |
| Нага, жен. | `models/mailer/wow_characters/wowanim_naga_female.mdl` |

Пути в таблице — базовые статические записи каталога; расширения Pandaren
раскрываются в конкретные пути (18 мужских и 20 женских моделей), без локального
поиска файлов или проверки наличия. В превью вращается сама модель (мышь
или кнопки), камера остаётся на месте, колесо приближает/отдаляет. Команда
`wo_models` выводит настроенные race/gender пути без сканирования файловой
системы или `player_manager`.

### Коллекции и optional-ассеты Workshop

Запрошенная коллекция **World of Warcraft**, ID `3801728890`, учитывается как
ссылка, но на последней проверке Steam показывала `Items (0)`. Не считайте её
состав подтверждённым манифестом. Известные страницы:
[Playable Characters Megapack `3796529373`](https://steamcommunity.com/sharedfiles/filedetails/?id=3796529373)
и [Creatures Megapack `3798571666`](https://steamcommunity.com/sharedfiles/filedetails/?id=3798571666).
Пак персонажей приведён только как один из возможных источников локальных
файлов: он не входит в required addons и не запрашивается через
`resource.AddWorkshop`. Список внешних NPC/SWEP-зависимостей, для которых
загрузка всё ещё требуется, находится в `config/sh_workshop.lua`; серверу
нужно смонтировать эти игровые addons локально.

Точные runtime-классы заданы явно:

- NPC: волк `wow_npc_14892`, кабан `wow_npc_2809`, лошадь `wow_npc_8883`;
- SWEP: `drc_unarmed`, `tfa_cso_coldsteelblade`, новая книга `wo_magic_grimoire`;
- случайные и самодельные fallback-классы NPC не используются.

Плагин `plugins/workshop` проверяет внешние классы в реестрах GMod и ничего не
подменяет похожим. Команда `wo_workshop_assets` (SAM permission `wo_debug`)
показывает `registered`/`MISSING`; если точный класс отсутствует, существо не
создаётся. Проверяйте статус на dedicated server и клиенте: smoke-тест использует
моки только для проверки логики и не подтверждает установку Workshop.

Стандартные руки `drc_unarmed` выдаются сервером напрямую. `starter_knife`
выдаётся Охотником только при принятии `boar_hunt`, а не при создании персонажа;
выдача не ограничена классом или расой. Предмет хранится в инвентаре и выдаёт
`tfa_cso_coldsteelblade` только после экипировки в main hand. Маг получает
только `wo_magic_grimoire`; старый Warp Magic (`weapon_hpwr_stick`) не входит в
loadout и удаляется у мага при применении обновлённой стартовой экипировки.
Изученные spells и ранги хранятся в существующей plugin-таблице `wo_abilities`,
а не в generic `CharacterSync`.

Позиция и угол персонажа сохраняются при autosave/выходе; возврат на ту же карту
восстанавливает сохранённое место. У новой записи без позиции используется обычная
map spawn point, а не искусственная координата у начала мира.

Дополнительное обнаружение из `plugins/workshop` относится только к внешним
NPC-моделям и не участвует в каталоге моделей персонажей. NPC-модель принимается
только при наличии файла в mounted virtual filesystem (`file.Exists(..., "GAME")`).
Если NPC-аддон не публикует модель в стандартном реестре, администратор может
включить ограниченный recursive scan в `config/sh_workshop.lua`
(`WO.Config.Workshop.DeepModelDiscovery = true`) или внести вручную проверенный
путь в `WO.Config.WorkshopModelOverrides`:

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
| Квест (шаги equip/kill/collect/talk + награды) | `schemas/quests/<id>.lua` | `schemas/quests/wolves_of_elwynn.lua` |

- NPC не появляются в случайных точках. Для каждого нужно задать map-specific
  `pos = Vector(...)` либо существующий `anchor` с `anchorIndex` и явным `offset`;
  пустая/невалидная точка ничего не спавнит. Основной мир и заданные координаты
  привязаны к `rp_lordaeron`; сервер запускайте с `+map rp_lordaeron`. Для других
  карт добавьте собственные точки в `WO.Config.NPCSpawnPoints`
  (`config/sh_settings.lua`).
- На `rp_lordaeron` настроены NPC и четыре волка/кабана на фиксированных точках
  (координаты в `config/sh_settings.lua`; геометрию на живой карте нужно проверить):

  | NPC / точка | Координата | Поворот (pitch, yaw, roll) | Класс / модель |
  |---|---|---|---|
  | Маршал | `(-8678.3, 8009.3, -1489)` | `(1, 46, 0)` | `models/mailer/wow_characters/wowanim_skyhunterNL.mdl` |
  | Торговец | `(-7083.1, 8847.6, -1535.6)` | `(2, -90, 0)` | `models/mailer/wow_characters/wowanim_gnome_male.mdl` |
  | Торговец маунтами | `(-7316.9, 8827.6, -1572)` | `(1, -65, 0)` | `models/mailer/wow_characters/wowanim_c_stoneconstruct.mdl` |
  | Охотник | `(-5812.6, 7972.9, -1572)` | `(0, 4, 0)` | `models/mailer/wow_characters/wowanim_worgen_male.mdl` |
  | Торговец свитками | `(-6746.5, 8830.4, -1572)` | `(0, -45, 0)` | `models/mailer/wow_characters/wowanim_malygos.mdl` |
  | Кабаны ×4 | `(-5344.3,1652.2,-3071.8)`, `(-5158.9,1170.1,-3072)`, `(-4937.5,833.7,-3072)`, `(-4810.9,1435.8,-3071.5)` | — | точный внешний класс `wow_npc_2809` |
  | Волки ×4 | `(-2674.5,-10887.5,-3072)`, `(-3131.4,-10645.7,-3072)`, `(-2746.8,-10087.1,-3072)`, `(-2182.1,-11247.3,-3072)` | — | точный внешний класс `wow_npc_14892` |
- Цепочка: Охотник выдаёт `boar_hunt` и при принятии поручения выдаёт `starter_knife`;
  после экипировки игрок побеждает ровно 4 кабанов (`wow_npc_2809`) и сдаёт задание
  Охотнику. После этого Маршал выдаёт `wolves_of_elwynn`; игрок побеждает ровно
  4 волков (`wow_npc_14892`) и сдаёт задание Маршалу. На каждую группу задано
  ровно 4 координаты; prerequisite валидируется сервером и при загрузке старого
  прогресса. Хлебный сбор маршала от охотничьей цепочки не зависит.
- Волк и кабан используют только точные внешние классы `wow_npc_14892` и
  `wow_npc_2809`; собственный `wo_wolf` и случайные fallback-классы отсутствуют.
  Существа имеют уровни 1–4 и уровневые параметры. За убийство XP начисляется
  напрямую с уведомлением (`+44 XP` на первом уровне); обычно дополнительно
  выпадают монеты и один тематический предмет, а оружие/броня/свитки имеют малый
  шанс. Death hooks дедуплицируют loot и quest progress.
- Торговец и квестодатель имеют разные 3D-маркеры (`$`, `!`, `?`). Клавиша E
  проходит через `SetUseType(SIMPLE_USE)` и fallback `Interact.Request`; сервер
  повторно проверяет общий диапазон 100 единиц, `CanInteract`, cooldown, владение
  item instance и место в инвентаре, чтобы физический loot не пропадал при pickup.
  Диалог/торговая сессия повторно проверяет сущность, игрока и дистанцию.
- Действия диалога: `close`, `next:<узел>`, `quest:<id>`, `vendor`, `talk:<npcId>`.
- Квесты хранятся в БД (`wo_quests`), прогресс собирается сервером
  (убийства NPC, предметы в инвентаре, разговоры), награды выдаются сервером.
- Малигос — NPC-продавец свитков, модель
  `models/mailer/wow_characters/wowanim_malygos.mdl`. Каталог генерирует
  35 свитков (7 заклинаний × 5 рангов); серверный spellbook автоматически
  пересчитывает магию из свитков, остающихся в инвентаре, без использования,
  расходования или покупки очков. Старые свитки продаются NPC по пониженной
  цене; обмена между игроками нет.
- Торговцы описываются прямо в схеме NPC (`vendor = { stock = ..., sellRate = ... }`);
  UI показывает продаваемые предметы из инвентаря, а все цены, владение и деньги
  контролируются сервером.
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
17 race-схем, 13 классов, русские имена/фамилии, серверная защита особых рас и
лимиты 2/5; модельный allowlist и прямое отображение путей без
file.Exists-gating; HUD/UI, сетка, миграция и восстановление переполненного
инвентаря, использование предметов, spell rank persistence/cast и отдельный
`Spell.Sync`; quest prerequisites, правильные questgiver/turn-in, четыре
фиксированных spawn-точки для каждого вида и подавление quest-spawn после
завершения; точные классы NPC; социальная приватность, F2-знакомство и обновление
уровня знакомого; права админ-каталога, владение weapon selector, серверный
автосбор, NPC halo/nameplate, пользовательский прицел и fade/float анимацию
damage text с проверкой урона по NPC и игрокам. Лошадь использует точный
`wow_npc_8883`, включая проверки голода, кормления, улучшения и антидубликатов.
Registry и Workshop-модели в стенде мокируются: это проверяет логику, но не
подтверждает фактическую регистрацию классов, геометрию `rp_lordaeron`, анимации
или отрисовку в реальном GMod. Перед production проверьте `wo_workshop_assets`
и вручную протестируйте NPC, маунта, модели и HUD на клиенте Garry's Mod.

---

## Управление

| Клавиша | Действие |
|---|---|
| `Tab` | Единый menu/scoreboard; открыть при нажатии, закрыть при отпускании |
| `I` | Инвентарь: предметы/ресурсы и экипировка в отдельных панелях |
| `C` | Лист персонажа (статы и прогресс XP) |
| `J` | Журнал заданий |
| `F2` | Меню взаимного знакомства рядом: шёпот / разговор / крик |
| `F3` | Выбор цели / сброс цели (информационная плашка скрыта) |
| `E` | Взаимодействие (предмет, NPC, торговец) |
| `1`–`9`, `0` | Выбрать соответствующий слот в собственном selector; после выбора selector скрывается |
| `Колесо мыши` | Не переключает оружие; zoom камеры работает только с `Alt` |
| `Alt` + `колесо мыши` | Zoom камеры |
| `ЛКМ по предмету` | Перетащить (drag & drop) |
| `ПКМ по предмету` | Меню: использовать / выбросить / уничтожить |
| `ПКМ с книгой стихий` | Открыть изучение/выбор заклинаний |
| `ЛКМ с книгой стихий` | Применить выбранное заклинание |
| `Использовать mount stone` в меню предмета | Вызвать или отозвать лошадь |

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
│   │   ├── stats/ leveling/ combat/ weapons/ spells/
│   │   ├── world/ interaction/ currency/ mounts/
│   │   ├── thirdperson/ targeting/ hud/ settings/
│   │   ├── notifications/ admin/ debug/
│   ├── schemas/                  # КОНТЕНТ (data-driven, без изменения ядра)
│   │   ├── races/                # human.lua, elf.lua, dwarf.lua, orc.lua
│   │   ├── classes/              # warrior.lua, mage.lua, rogue.lua, ranger.lua
│   │   └── items/                # iron_sword.lua, health_potion.lua, ...
│   ├── weapons/                  # SWEP base + melee/magic оружие
│   ├── entities/                 # wo_item_world, coin piles, NPC talker
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

Если SAM загружен, плагин регистрирует права `wo_character_edit`,
`wo_item_give`, `wo_money_give`, `wo_npc_spawn`, `wo_quest_complete`,
`wo_teleport` и `wo_debug` (по умолчанию уровень `admin`). Noclip запрещён
всем игрокам, включая GMod/SAM-администраторов; старое SAM-право `wo_noclip`,
если оно осталось в конфигурации сервера, не даёт доступ. При наличии SAM
встроенные `IsAdmin`/`IsSuperAdmin` не используются как обход разрешений.
GMod fallback включается только если SAM вообще не загружен.

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
| `wo_models [race] [gender]` | Показывает настроенные race/gender-пути; не сканирует файловую систему или player_manager |
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
- Расширение книги заклинаний; action bar, cast bar и статус-эффекты
- Пати, фракции, PvP-зоны, торговля между игроками
- Банк, крафт, карта, достижения, ремонт

---

## Лицензия

Проект создан для образовательных и развлекательных целей.
Warcraft и World of Warcraft — торговые марки Blizzard Entertainment;
проект не связан с Blizzard и не использует их проприетарный контент.
