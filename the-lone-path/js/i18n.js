/* ============================================================
   THE LONE PATH — i18n  (EN / RU / UK)
   Flag-switched localization for the whole game.
   ============================================================ */
'use strict';
(function (T) {
  var D = {
en: {
  slogan: 'SMALL STEPS. BIG SILENCE.',
  btn_start: 'START', btn_controls: 'CONTROLS', btn_credits: 'CREDITS',
  btn_resume: 'RESUME', btn_restart: 'RESTART', btn_menu: 'MAIN MENU',
  btn_again: 'PLAY AGAIN',
  menu_foot: 'A short interactive story. Playtime 10\u201325 minutes.',
  menu_done: 'THE PATH REMEMBERS YOU.',
  controls: 'CONTROLS', credits: 'CREDITS', paused: 'PAUSED', click_return: 'CLICK TO RETURN',
  k_move: 'MOVE', k_flash: 'FLASHLIGHT', k_inter: 'INTERACT', k_esc: 'MENU', k_mute: 'MUTE SOUND',
  ctrl_aim: 'LOOK CONTROL',
  aim_keys_t: 'WITH MOVEMENT', aim_keys_d: 'the lantern swings where you walk',
  aim_mouse_t: 'WITH MOUSE', aim_mouse_d: 'look at the cursor \u00b7 move on WASD',
  aimset_mouse: 'THE LANTERN NOW FOLLOWS THE CURSOR',
  aimset_keys: 'THE LANTERN FOLLOWS YOUR STEPS AGAIN',
  ep_pick: 'CHOOSE YOUR PART',
  ep1_t: 'PART I \u00b7 THE LONE PATH', ep1_d: 'the crash, the camp, five notes and one car',
  ep_ready: 'READY', ep_soon: 'SOON',
  ep_locked: 'THE NEXT PART IS STILL BEING WRITTEN IN THE FOREST',
  cr_creator_t: 'GAME CREATOR', cr_creator_v: 'MARLEN',
  cr_writer_t: 'SCREENWRITER', cr_designer_t: 'GAME DESIGNER',
  cr_agent_t: 'GAME CREATION', cr_agent_v: 'AGENTS CLAUDE & CHATGPT',
  end_thanks: 'Thank you for playing this game \u2014 expect the next part.',
  dev_pick: 'HOW WILL YOU PLAY?',
  dev_pc: 'COMPUTER', dev_pc_d: 'WASD to walk \u00b7 F flashlight \u00b7 E act \u00b7 optional mouse aim',
  dev_phone: 'PHONE', dev_phone_d: 'joystick at the left \u00b7 E and F buttons at the right \u00b7 tap the world to look',
  btn_dev: 'DEVICE',
  fs_nope: 'FULLSCREEN IS NOT AVAILABLE HERE',
  hint_stick: 'JOYSTICK \u2014 MOVE', hint_btns: 'E \u2014 ACT \u00b7 F \u2014 LIGHT',
  roll_skip: 'CLICK TO SKIP',
  cr_l1: 'THE LONE PATH', cr_l2: 'a small interactive story about silence,', cr_l2b: 'light, and what stands inside it.',
  cr_l3: 'Art, world and sound are generated in code \u2014', cr_l3b: 'no external assets, no engines.', cr_l4: 'Made with HTML5 Canvas.',
  intro: ['I don\u2019t remember coming here.', 'But I remember the forest.', 'Find out what happened.'],
  hint_flash: 'F \u2014 FLASHLIGHT', hint_move: 'WASD / \u2190\u2191\u2193\u2192 \u2014 MOVE',
  obj_first: 'OBJECTIVE \u00B7 FIND FIVE NOTES',
  obj_search: 'OBJECTIVE \u00B7 SEARCH THE HOUSE',
  hud_notes: 'NOTES', hud_things: 'THINGS', hud_chapter: 'CHAPTER',
  read: 'READ', examine: 'EXAMINE', take: 'TAKE', enter: 'ENTER', leave: 'LEAVE', close: 'CLOSE',
  note_word: 'NOTE',
  ch: ['THE CAMP', 'THE HOUSE', 'THE QUARRY', 'THE RADIO TOWER', 'THE FOGGY LAKE'],
  ch_obj: ['Explore the camp. Find the first note.', 'Find the old house. Search it from the inside.', 'The quarry keeps what it swallowed: its note, and a toolbox.', 'Something deeper in the forest still blinks: the tower note, a fuel can.', 'The last note waits by the foggy lake \u2014 and a spare wheel with it.'],
  ret_cabin: 'OBJECTIVE \u00B7 RETURN TO THE HOUSE',
  ch_toast: ['CHAPTER II \u00B7 THE HOUSE', 'CHAPTER III \u00B7 THE QUARRY', 'CHAPTER IV \u00B7 THE RADIO TOWER', 'CHAPTER V \u00B7 THE FOGGY LAKE'],
  lbl_cabin: 'HOUSE', lbl_door_out: 'THE HOUSE', lbl_leave: 'STEP OUT',
  never_alone: 'YOU WERE NEVER ALONE.', the_end: 'THE END',
  end_title: 'THE\u00A0LONE\u00A0PATH', found_notes: '5 / 5 NOTES FOUND', found_things: '3 / 3 THINGS FOUND',
  toast_found: ['You took the photograph.', 'You took the matches.', 'You took a small iron key.'],
  cab_title: 'WOODEN CABINET',
  cab_word: 'READ PAGES',
  cabinet_locked: 'A wooden cabinet, shut tight. A rusted lock plate. Someone hid pages in there, and took the key.',
  cabinet_open: 'The key turns. The doors groan open. Loose pages wait on the shelf.',
  door_dark: 'The door stands open into darkness. Something in there needs finding.',
  door_back: 'The night air closes behind you. The house keeps its silence.',
  int_photo: 'THE PHOTOGRAPH', int_matches: 'THE MATCHES', int_key: 'THE IRON KEY', int_cabinet: 'THE CABINET',
  gate_house: 'Locked tight. Read what the camp left behind first.',
  gate_quarry: 'Fallen trees bar the path. The house has not told you all it knows.',
  gate_radio: 'The road to the tower is blocked with timber. The quarry still keeps its note.',
  gate_lake: 'Logs across the trail. The tower note is still lying up there.',
  gate_open: 'Somewhere in the dark, a road lets go.',
  parts_label: 'PARTS', end_parts: '3 / 3 CAR PARTS FOUND',
  ret_car: 'OBJECTIVE \u00B7 DRIVE OUT OF HERE',
  lbl_car: 'THE CAR', act_fix: 'FIX THE CAR',
  item_tools: 'THE TOOLBOX', item_fuel: 'THE FUEL CAN', item_wheel: 'THE SPARE WHEEL',
  toast_parts: ['You took the toolbox.', 'A jerry can \u2014 half-full, still smelling of summer.', 'You dragged the spare wheel free of the mud.'],
  car_need: 'Three things are missing before she rolls again.',
  car_ready: 'Everything is here. Turn the key.',
  car_have: 'FOUND', car_missing: 'MISSING',
  car_drive: 'The engine catches on the third cough. The forest keeps its silence \u2014 you do not.',
  notes: [
    { lines: [
      'We arrived here three days ago.',
      'We made camp beside the old house. Everything seemed ordinary.',
      'But last night we heard steps walking around the camp while we slept.',
      'Slow steps. Round and round. Nobody in our group left the tent.'] },
    { lines: [
      'In the morning we found tracks in the mud around the house.',
      'They went into the forest. None came back.',
      'There is a symbol carved on an old tree near the door:',
      'three lines and an eye. None of us carved it.'] },
    { lines: [
      'We are not alone here. I am sure of it now.',
      'Every night a fire is lit beside the house. Warm ash at midnight.',
      'Every morning we ask who did it. Nobody admits anything.',
      'By sunrise the fire is always cold again.',
      'I keep these pages in the cabinet, where nobody would think to look.'] },
    { lines: [
      'The others are gone. I woke up and the camp was empty.',
      'Not a single sign of a struggle. Only the cold fire pit.',
      'I tried to leave. Every path through the trees brought me back',
      'to the same house, the same door, the same window watching me.'] },
    { lines: [
      'I understand one thing now. I write it with a shaking hand.',
      'The carvings on that tree are old. Older than this forest.',
      'We came here looking for something. We were not the first ones.',
      'It does not hunt us. It is simply waiting for us to notice that&mdash;',
      '<span class="torn">[the rest of the page is torn away]</span>'] }
  ],
  ex: {
    win_look: { t: 'THE WINDOW', l: ['The forest, seen from inside. The trees stand too close to the house.'] },
    hearth_look: { t: 'THE HEARTH', l: ['Cold ash. Someone swept it into a careful circle. Recently.'] },
    bed_look: { t: 'THE COT', l: ['A blanket pulled back, as if its owner got up in the middle of a thought.'] },
    campfire: { t: 'CAMPFIRE', l: ['Cold ash. The stones are stacked in a careful, quiet circle.', 'Whatever slept here knew how to keep a fire from crackling.'] },
    smallfire: { t: 'SMALL FIRE', l: ['Fresh scorch marks on these stones.', 'This fire was burning a few hours ago.', 'Nobody here admits to lighting it.'] },
    quarry: { t: 'THE QUARRY', l: ['The gravel pit ran out years ago. The water in it never freezes,', 'and nobody has ever seen a spring feeding it.'] },
    crane: { t: 'THE CRANE', l: ['A rusted loading crane, bent over the water like an abandoned fishing rod.', 'The cable hangs down into the dark. In the wind it hums one single note.'] },
    car: { t: 'THE CAR', l: ['A rusted station wagon, backed to the rim of the quarry and sunk into wet moss.', 'The keys are still in the ignition. The tank is bone dry.', 'The passenger seat is folded down. Someone slept here a long time.'] },
    tower: { t: 'THE RADIO TOWER', l: ['A maintenance mast for a station that went silent years ago.', 'And still its beacon blinks. Someone keeps the generator alive.'] },
    hut: { t: 'THE WORKER HUT', l: ['A lineman\u2019s hut. A kettle on the stove. A chair turned toward the window.', 'On the wall: a maintenance checklist, every box ticked in the same careful hand.'] },
    pier: { t: 'THE PIER', l: ['Planks nailed down by hand, gone grey with weather. The lamp at the end was lit this evening.', 'The lake does not reflect the trees. It takes the light and gives nothing back.'] },
    lake: { t: 'THE FOGGY LAKE', l: ['Fog stands on the water a finger deep, and does not move.', 'The old maps named this lake the place where the last light goes out.'] },
    tent: { t: 'COLLAPSED TENT', l: ['It folded inward, like it caved under someone sitting up in a hurry.', 'Inside: four sleeping bags. Nobody took a single one.'] },
    symbol: { t: 'THE SYMBOL', l: ['Three lines and an eye, carved into the bark.', 'The cuts are old and dark with rain.', 'There are more of them underneath the moss. All deeper. All newer.'] },
    sign: { t: 'SIGNPOST', l: ['Its painted fingers point every direction at once.', 'Every one of them, when you follow it, ends at the house.'] },
    oldtree: { t: 'THE OLD TREE', l: ['Carvings all around the trunk. Names. Dates nobody can read.', 'Some look centuries old. The newest one looks like it was made last night.'] }
  }
},
ru: {
  slogan: 'МАЛЕНЬКИЕ ШАГИ. БОЛЬШАЯ ТИШИНА.',
  btn_start: 'НАЧАТЬ', btn_controls: 'УПРАВЛЕНИЕ', btn_credits: 'ОБ ИГРЕ',
  btn_resume: 'ПРОДОЛЖИТЬ', btn_restart: 'ЗАНОВО', btn_menu: 'ГЛАВНОЕ МЕНЮ',
  btn_again: 'ЕЩЁ РАЗ',
  menu_foot: 'Короткая интерактивная история. 10\u201325 минут.',
  menu_done: 'ЛЕС ПОМНИТ ТВОЙ ПУТЬ.',
  controls: 'УПРАВЛЕНИЕ', credits: 'ОБ ИГРЕ', paused: 'ПАУЗА', click_return: 'КЛИК, ЧТОБЫ ВЕРНУТЬСЯ',
  k_move: 'ДВИЖЕНИЕ', k_flash: 'ФОНАРИК', k_inter: 'ВЗАИМОДЕЙСТВИЕ', k_esc: 'МЕНЮ', k_mute: 'ЗВУК ВКЛ/ВЫКЛ',
  ctrl_aim: 'УПРАВЛЕНИЕ ВЗГЛЯДОМ',
  aim_keys_t: 'ЗА ДВИЖЕНИЕМ', aim_keys_d: 'фонарь смотрит туда, куда идёшь',
  aim_mouse_t: 'ЗА КУРСОРОМ', aim_mouse_d: 'взгляд за мышью \u00b7 движение на WASD',
  aimset_mouse: 'ФОНАРЬ ТЕПЕРЬ СЛЕДУЕТ ЗА КУРСОРОМ',
  aimset_keys: 'ФОНАРЬ СНОВА СЛЕДУЕТ ЗА ШАГАМИ',
  ep_pick: 'ВЫБЕРИТЕ ЧАСТЬ',
  ep1_t: 'ЧАСТЬ I \u00b7 ОДИНОКИЙ ПУТЬ', ep1_d: 'авария, лагерь, пять записок и одна машина',
  ep_ready: 'ДОСТУПНО', ep_soon: 'СКОРО',
  ep_locked: 'СЛЕДУЮЩАЯ ЧАСТЬ ЕЩЁ ПИШЕТСЯ В ЛЕСУ',
  cr_creator_t: 'СОЗДАТЕЛЬ ИГРЫ', cr_creator_v: 'МАРЛЕН',
  cr_writer_t: 'СЦЕНАРИСТ', cr_designer_t: 'ГЕЙМДИЗАЙНЕР',
  cr_agent_t: 'ГЕЙМКРЕАТОР', cr_agent_v: 'АГЕНТЫ CLAUDE & CHATGPT',
  end_thanks: 'Спасибо, что поиграли в эту игру, \u2014 ожидайте следующую часть.',
  dev_pick: 'ЧЕМ БУДЕТЕ ИГРАТЬ?',
  dev_pc: 'КОМПЬЮТЕР', dev_pc_d: 'WASD \u00b7 F фонарик \u00b7 E действие \u00b7 по желанию наведение мышью',
  dev_phone: 'ТЕЛЕФОН', dev_phone_d: 'джойстик слева \u00b7 кнопки E и F справа \u00b7 тап по миру — посмотреть',
  btn_dev: 'УСТРОЙСТВО',
  fs_nope: 'ПОЛНЫЙ ЭКРАН ЗДЕСЬ НЕДОСТУПЕН',
  hint_stick: 'ДЖОЙСТИК \u2014 ДВИЖЕНИЕ', hint_btns: 'E \u2014 ДЕЙСТВИЕ \u00b7 F \u2014 ФОНАРЬ',
  roll_skip: 'НАЖМИТЕ, ЧТОБЫ ПРОПУСТИТЬ',
  cr_l1: 'THE LONE PATH', cr_l2: 'маленькая интерактивная история о тишине,', cr_l2b: 'свете и о том, что стоит внутри него.',
  cr_l3: 'Графика, мир и звук генерируются кодом \u2014', cr_l3b: 'без файлов ассетов и без движков.', cr_l4: 'Сделано на HTML5 Canvas.',
  intro: ['Я не помню, как здесь оказался.', 'Но этот лес я помню.', 'Узнай, что тут случилось.'],
  hint_flash: 'F \u2014 ФОНАРИК', hint_move: 'WASD / \u2190\u2191\u2193\u2192 \u2014 ДВИЖЕНИЕ',
  obj_first: 'ЦЕЛЬ \u00B7 НАЙДИ ПЯТЬ ЗАПИСОК',
  obj_search: 'ЦЕЛЬ \u00B7 ОБЫЩИ ДОМ',
  hud_notes: 'ЗАПИСКИ', hud_things: 'ВЕЩИ', hud_chapter: 'ГЛАВА',
  read: 'ЧИТАТЬ', examine: 'ОСМОТРЕТЬ', take: 'ВЗЯТЬ', enter: 'ВОЙТИ', leave: 'ВЫЙТИ', close: 'ЗАКРЫТЬ',
  note_word: 'ЗАПИСКА',
  ch: ['ЛАГЕРЬ', 'ДОМ', 'КАРЬЕР', 'РАДИОВЫШКА', 'ТУМАННОЕ ОЗЕРО'],
  ch_obj: ['Осмотри лагерь. Найди первую записку.', 'Найди старый дом. Обыщи его изнутри.', 'Карьер держит то, что поглотил: его записку и ящик инструментов.', 'Глубже в лесу что-то до сих пор мигает: записка у вышки и канистра топлива.', 'Последняя записка ждёт у туманного озера \u2014 и запасное колесо тоже.'],
  ret_cabin: 'ЦЕЛЬ \u00B7 ВЕРНИСЬ К ДОМУ',
  ch_toast: ['ГЛАВА II \u00B7 ДОМ', 'ГЛАВА III \u00B7 КАРЬЕР', 'ГЛАВА IV \u00B7 РАДИОВЫШКА', 'ГЛАВА V \u00B7 ТУМАННОЕ ОЗЕРО'],
  lbl_cabin: 'ДОМ', lbl_door_out: 'ДОМ', lbl_leave: 'НА ВЫХОД',
  never_alone: 'ТЫ НИКОГДА НЕ БЫЛ ОДИН.', the_end: 'КОНЕЦ',
  end_title: 'THE\u00A0LONE\u00A0PATH', found_notes: 'ЗАПИСОК: 5 / 5', found_things: 'ВЕЩЕЙ: 3 / 3',
  toast_found: ['Ты взял фотографию.', 'Ты взял коробок спичек.', 'Ты взял маленький железный ключ.'],
  cab_title: 'ДЕРЕВЯННЫЙ ШКАФЧИК',
  cab_word: 'ВЗЯТЬ СТРАНИЦЫ',
  cabinet_locked: 'Деревянный шкафчик, заперт на ржавый замок. Кто-то спрятал здесь записи — и забрал ключ.',
  cabinet_open: 'Ключ поворачивается. Дверцы скрипят, открываясь. На полке лежат собранные страницы.',
  door_dark: 'Дверь открыта в темноту. Внутри нужно что-то найти.',
  door_back: 'Ночной воздух закрывает дверь за спиной. Дом остаётся при своём молчании.',
  int_photo: 'ФОТОГРАФИЯ', int_matches: 'СПИЧКИ', int_key: 'ЖЕЛЕЗНЫЙ КЛЮЧ', int_cabinet: 'ШКАФЧИК',
  gate_house: 'Заперто намертво. Сначала прочти то, что оставил лагерь.',
  gate_quarry: 'Путь завалили деревья. Дом ещё не всё тебе рассказал.',
  gate_radio: 'Дорогу к вышке перегорожили брёвна. В карьере ещё лежит записка.',
  gate_lake: 'На тропе лежат брёвна. Записка с вышки всё ещё там.',
  gate_open: 'Где-то во тьме дорога разжимает пальцы.',
  parts_label: 'ДЕТАЛИ', end_parts: 'ДЕТАЛЕЙ: 3 / 3',
  ret_car: 'ЦЕЛЬ \u00B7 УЕХАТЬ ОТСЮДА',
  lbl_car: 'МАШИНА', act_fix: 'ПОЧИНИТЬ МАШИНУ',
  item_tools: 'ЯЩИК ИНСТРУМЕНТОВ', item_fuel: 'КАНИСТРА ТОПЛИВА', item_wheel: 'ЗАПАСНОЕ КОЛЕСО',
  toast_parts: ['Ты взял ящик инструментов.', 'Канистра — наполовину полная, ещё пахнет летом.', 'Запасное колесо отдалось со скрипом.'],
  car_need: 'Чтобы она поехала снова, не хватает трёх вещей.',
  car_ready: 'Всё на месте. Поворачивай ключ.',
  car_have: 'НАЙДЕНО', car_missing: 'НЕТ',
  car_drive: 'Мотор схватывает с третьего раза. Лес остаётся при своём молчании — а ты нет.',
  notes: [
    { lines: [
      'Мы приехали сюда три дня назад.',
      'Разбили лагерь рядом со старым домом. Всё казалось обычным.',
      'Но прошлой ночью, пока мы спали, кто-то ходил вокруг лагеря.',
      'Медленные шаги. По кругу. Никто из нас не выходил из палатки.'] },
    { lines: [
      'Утром мы нашли следы на грязи вокруг дома.',
      'Они уходят в лес. Обратных нет.',
      'На старом дереве у двери вырезан символ:',
      'три линии и глаз. Никто из нас его не вырезал.'] },
    { lines: [
      'Мы здесь не одни. Теперь я в этом уверен.',
      'Каждую ночь у дома кто-то разжигает костёр. В полночь пепел тёплый.',
      'Каждое утро мы спрашиваем друг друга. Никто не признаётся.',
      'К рассвету костёр снова холодный.',
      'Я храню эти страницы в шкафчике — там, где никто не станет искать.'] },
    { lines: [
      'Остальные исчезли. Я проснулся — лагерь пуст.',
      'Ни следа борьбы. Только остывшее кострище.',
      'Я пытался уйти. Но каждая тропа через лес возвращает меня',
      'к тому же дому, тем же дверям, тому же окну, что смотрит на меня.'] },
    { lines: [
      'Теперь я понял одну вещь. Пишу — рука дрожит.',
      'Резьба на том дереве стара. Старше этого леса.',
      'Мы пришли сюда не первыми.',
      'Оно не охотится за нами. Оно просто ждёт, когда мы это заметим —',
      '<span class="torn">[дальше страница оторвана]</span>'] }
  ],
  ex: {
    win_look: { t: 'ОКНО', l: ['Лес, видимый изнутри. Деревья стоят слишком близко к дому.'] },
    hearth_look: { t: 'ПЕЧЬ', l: ['Холодный пепел. Кто-то недавно сгрёб его в аккуратный круг.'] },
    bed_look: { t: 'КОЙКА', l: ['Одеяло откинуто так, будто хозяин встал посреди мысли.'] },
    campfire: { t: 'КОСТРИЩЕ', l: ['Холодный пепел. Камни сложены в аккуратный, тихий круг.', 'Тот, кто жёг здесь огонь, умел прятать его треск.'] },
    smallfire: { t: 'МАЛЫЙ КОСТЁР', l: ['Свежие подпалины на этих камнях.', 'Этот костёр горел пару часов назад.', 'Никто не признаётся, что зажигал его.'] },
    quarry: { t: 'КАРЬЕР', l: ['Гравийный карьер выработали давно. Вода в нём не замерзает,', 'а источника, который её питает, никто не видел.'] },
    crane: { t: 'КРАН', l: ['Ржавый погрузочный кран наклонён над водой, как заброшенная удочка.', 'Трос уходит в темноту. На ветру он гудит одну-единственную ноту.'] },
    car: { t: 'МАШИНА', l: ['Ржавый универсал, вписанный в мох прямо у края карьера.', 'Ключи всё ещё в замке. Бак сух до дна.', 'Переднее сиденье откинуто. Кто-то спал здесь очень давно.'] },
    tower: { t: 'РАДИОВЫШКА', l: ['Мачта связи при станции, которая замолчала годы назад.', 'Но маяк всё ещё мигает. Кто-то поддерживает генератор.'] },
    hut: { t: 'БЫТОВКА', l: ['Вахтовка линейщиков. Чайник на плите. Стул повёрнут к окну.', 'На стене — чек-лист, все пункты отмечены одним аккуратным почерком.'] },
    pier: { t: 'МОСТКИ', l: ['Доски прибиты вручную и посерели от погоды. Лампа на краю зажжена этим вечером.', 'Озеро не отражает деревья. Оно забирает свет и ничего не отдаёт.'] },
    lake: { t: 'ТУМАННОЕ ОЗЕРО', l: ['Туман стоит над водой на палец и не шевелится.', 'Старые карты называли это озеро местом, где гаснет последний свет.'] },
    tent: { t: 'СЛОМАННАЯ ПАЛАТКА', l: ['Она сложилась внутрь — будто прогнулась от человека, резко севшего.', 'Внутри четыре спальника. Ни одного не забрали.'] },
    symbol: { t: 'СИМВОЛ', l: ['Три линии и глаз, вырезанные на коре.', 'Насечки старые, потемневшие от дождя.', 'Под мхом их больше. Все глубже. Все новее.'] },
    sign: { t: 'УКАЗАТЕЛЬ', l: ['Его крашеные стрелки смотрят во все стороны сразу.', 'Любая из них, если идти по ней, выведет к дому.'] },
    oldtree: { t: 'СТАРОЕ ДЕРЕВО', l: ['Ствол весь в зарубках. Имена. Даты, которые никто не прочтёт.', 'Некоторым — сотни лет. Самая свежая выглядит так, будто её сделали этой ночью.'] }
  }
},
uk: {
  slogan: 'МАЛЕНЬКІ КРОКИ. ВЕЛИКА ТИША.',
  btn_start: 'ПОЧАТИ', btn_controls: 'КЕРУВАННЯ', btn_credits: 'ПРО ГРУ',
  btn_resume: 'ПРОДОВЖИТИ', btn_restart: 'СПОЧАТКУ', btn_menu: 'ГОЛОВНЕ МЕНЮ',
  btn_again: 'ЩЕ РАЗ',
  menu_foot: 'Коротка інтерактивна історія. 10\u201325 хвилин.',
  menu_done: 'ЛІС ПАМ\u2019ЯТАЄ ТВОЇ СТЕЖКИ.',
  controls: 'КЕРУВАННЯ', credits: 'ПРО ГРУ', paused: 'ПАУЗА', click_return: 'КЛІК, ЩОБ ПОВЕРНУТИСЯ',
  k_move: 'РУХ', k_flash: 'ЛІХТАРИК', k_inter: 'ВЗАЄМОДІЯ', k_esc: 'МЕНЮ', k_mute: 'ЗВУК УВІМК/ВИМК',
  ctrl_aim: 'КЕРУВАННЯ ПОГЛЯДОМ',
  aim_keys_t: 'ЗА РУХОМ', aim_keys_d: 'ліхтар дивиться туди, куди йдеш',
  aim_mouse_t: 'ЗА КУРСОРОМ', aim_mouse_d: 'погляд за мишею \u00b7 рух на WASD',
  aimset_mouse: 'ЛІХТАР ТЕПЕР ЙДЕ ЗА КУРСОРОМ',
  aimset_keys: 'ЛІХТАР ЗНОВУ ЙДЕ ЗА КРОКАМИ',
  ep_pick: 'ОБЕРІТЬ ЧАСТИНУ',
  ep1_t: 'ЧАСТИНА I \u00b7 ОДИНАКИЙ ШЛЯХ', ep1_d: 'аварія, табір, п\'ять нотаток та одна машина',
  ep_ready: 'ДОСТУПНО', ep_soon: 'СКОРО',
  ep_locked: 'НАСТУПНА ЧАСТИНА ЩЕ ПИШЕТЬСЯ У ЛІСІ',
  cr_creator_t: 'СТВОРЮВАЧ ГРИ', cr_creator_v: 'МАРЛЕН',
  cr_writer_t: 'СЦЕНАРИСТ', cr_designer_t: 'ГЕЙМДИЗАЙНЕР',
  cr_agent_t: 'ГЕЙМКРЕАТОР', cr_agent_v: 'АГЕНТИ CLAUDE & CHATGPT',
  end_thanks: 'Дякуємо, що пограли в цю гру, \u2014 очікуйте наступну частину.',
  dev_pick: 'ЧИМ БУДЕТЕ ГРАТИ?',
  dev_pc: 'КОМП’ЮТЕР', dev_pc_d: 'WASD \u00b7 F ліхтар \u00b7 E дія \u00b7 за бажанням наведення мишею',
  dev_phone: 'ТЕЛЕФОН', dev_phone_d: 'джойстик зліва \u00b7 кнопки E та F справа \u00b7 тап по світу — подивитись',
  btn_dev: 'ПРИСТРІЙ',
  fs_nope: 'ПОВНИЙ ЕКРАН ТУТ НЕДОСТУПНИЙ',
  hint_stick: 'ДЖОЙСТИК \u2014 РУХ', hint_btns: 'E \u2014 ДІЯ \u00b7 F \u2014 СВІТЛО',
  roll_skip: 'НАТИСНІТЬ, ЩОБ ПРОПУСТИТИ',
  cr_l1: 'THE LONE PATH', cr_l2: 'маленька інтерактивна історія про тишу,', cr_l2b: 'світло і про те, що стоїть у ньому.',
  cr_l3: 'Графіка, світ і звук генеруються кодом \u2014', cr_l3b: 'без файлів і без рушіїв.', cr_l4: 'Зроблено на HTML5 Canvas.',
  intro: ['Я не пам\u2019ятаю, як опинився тут.', 'Але цей ліс я пам\u2019ятаю.', 'Дізнайся, що тут сталося.'],
  hint_flash: 'F \u2014 ЛІХТАРИК', hint_move: 'WASD / \u2190\u2191\u2193\u2192 \u2014 РУХ',
  obj_first: 'ЦІЛЬ \u00B7 ЗНАЙДИ П\u2019ЯТЬ НОТАТОК',
  obj_search: 'ЦІЛЬ \u00B7 ОБШУКАЙ ДІМ',
  hud_notes: 'НОТАТКИ', hud_things: 'РЕЧІ', hud_chapter: 'РОЗДІЛ',
  read: 'ЧИТАТИ', examine: 'ОГЛЯНУТИ', take: 'ВЗЯТИ', enter: 'УВІЙТИ', leave: 'ВИЙТИ', close: 'ЗАКРИТИ',
  note_word: 'НОТАТКА',
  ch: ['ТАБІР', 'ДІМ', 'КАР\u2019ЄР', 'РАДІОВИЖКА', 'ТУМАННЕ ОЗЕРО'],
  ch_obj: ['Оглянь табір. Знайди першу нотатку.', 'Знайди старий дім. Обшукай його зсередини.', 'Кар\u2019єр тримає те, що поглинув: його нотатку та скриньку інструментів.', 'Глибше в лісі щось досі блимає: нотатка біля вишки та каністра пального.', 'Остання нотатка чекає біля туманного озера \u2014 і запасне колесо теж.'],
  ret_cabin: 'ЦІЛЬ \u00B7 ПОВЕРНИСЯ ДО ДОМУ',
  ch_toast: ['РОЗДІЛ II \u00B7 ДІМ', 'РОЗДІЛ III \u00B7 КАР\u2019ЄР', 'РОЗДІЛ IV \u00B7 РАДІОВИЖКА', 'РОЗДІЛ V \u00B7 ТУМАННЕ ОЗЕРО'],
  lbl_cabin: 'ДІМ', lbl_door_out: 'ДІМ', lbl_leave: 'НА ВИХІД',
  never_alone: 'ТИ ЖОДНОГО РАЗУ НЕ БУВ ОДИН.', the_end: 'КІНЕЦЬ',
  end_title: 'THE\u00A0LONE\u00A0PATH', found_notes: 'НОТАТОК: 5 / 5', found_things: 'РЕЧЕЙ: 3 / 3',
  toast_found: ['Ти взяв фотографію.', 'Ти взяв коробок сірників.', 'Ти взяв маленького залізного ключа.'],
  cab_title: 'ДЕРЕВ\u2019ЯНА ШАФКА',
  cab_word: 'ВЗЯТИ СТОРІНКИ',
  cabinet_locked: 'Дерев\u2019яна шафка, замкнена іржавим замком. Хтось сховав сюди записки — і забрав ключа.',
  cabinet_open: 'Ключ повертається. Дверцята зітхають, відчиняючись. На поличці лежать зібрані сторінки.',
  door_dark: 'Двері прочинені в темряву. Всередині є що шукати.',
  door_back: 'Нічне повітря зачиняє двері за спиною. Дім лишається при своїй тиші.',
  int_photo: 'ФОТОГРАФІЯ', int_matches: 'СІРНИКИ', int_key: 'ЗАЛІЗНИЙ КЛЮЧ', int_cabinet: 'ШАФКА',
  gate_house: 'Зачинено намертво. Спершу прочитай те, що залишив табір.',
  gate_quarry: 'Шлях завалили дерева. Дім ще не все тобі розповів.',
  gate_radio: 'Дорогу до вижки перегородили колоди. У кар\u2019єрі ще лежить нотатка.',
  gate_lake: 'На стежці лежать колоди. Нотатка з вижки все ще там.',
  gate_open: 'Десь у темряві дорога розтискає пальці.',
  parts_label: 'ДЕТАЛІ', end_parts: 'ДЕТАЛЕЙ: 3 / 3',
  ret_car: 'ЦІЛЬ \u00B7 ЗЇХАТИ ВІДСИЛЬ',
  lbl_car: 'АВТО', act_fix: 'ПОРЕМОНТУВАТИ АВТО',
  item_tools: 'СКРИНЬКА З ІНСТРУМЕНТАМИ', item_fuel: 'КАНІСТРА Пального'.replace('пального','ПАЛЬНОГО'), item_wheel: 'ЗАПАСНЕ КОЛЕСО',
  toast_parts: ['Ти узяв скриньку з інструментами.', 'Каністра — наполовину повна, ще пахне літом.', 'Запасне колесо віддалося зі скрипом.'],
  car_need: 'Щоб вона поїхала знову, бракує трьох речей.',
  car_ready: 'Усе на місці. Крути ключ.',
  car_have: 'ЗНАЙДЕНО', car_missing: 'НЕМА',
  car_drive: 'Мотор смикає з третього разу. Ліс лишається при своїй тиші — а ти ні.',
  notes: [
    { lines: [
      'Ми приїхали сюди три дні тому.',
      'Розбили табір біля старого дому. Усе здавалося звичайним.',
      'Але вночі, поки ми спали, хтось ходив навколо табору.',
      'Повільні кроки. По колу. Ніхто з нас не виходив з намету.'] },
    { lines: [
      'Вранці ми знайшли сліди на бруді довкола дому.',
      'Вони входять у ліс. Зворотніх немає.',
      'На старому дереві біля дверей вирізьблено символ:',
      'три лінії та око. Ніхто з нас його не різьбив.'] },
    { lines: [
      'Ми тут не самі. Тепер я в цьому певний.',
      'Щовночі біля дому хтось розпалює багаття. Опівночі попіл теплий.',
      'Щоранку питаємо одне одного. Ніхто не зізнається.',
      'До світанку багаття знову холодне.',
      'Я ховаю ці сторінки в шафці — там, де ніхто не шукатиме.'] },
    { lines: [
      'Інші зникли. Я прокинувся — табір порожній.',
      'Жодної ознаки боротьби. Лише холодне багаття.',
      'Я пробував піти. Але стежка в лісі повертає мене',
      'до того ж дому, тих самих дверей, того ж вікна, що дивиться на мене.'] },
    { lines: [
      'Тепер я зрозумів одну річ. Пишу — рука тремтить.',
      'Різіб на тому дереві старі. Старші за цей ліс.',
      'Ми прийшли сюди не першими.',
      'Воно не полює на нас. Воно просто чекає, поки ми це помітимо —',
      '<span class="torn">[далі сторінка відірвана]</span>'] }
  ],
  ex: {
    win_look: { t: 'ВІКНО', l: ['Ліс, бачений зсередини. Дерева стоять надто близько до дому.'] },
    hearth_look: { t: 'ПІЧ', l: ['Холодний попіл. Його щойно згрібали в акуратне коло.'] },
    bed_look: { t: 'ЛІЖКО', l: ['Ковдру відкинуто так, ніби господар встав посеред думки.'] },
    campfire: { t: 'БАГАТТЯ', l: ['Холодний попіл. Каміння складене в акуратне тихе коло.', 'Той, хто тут палив, умів ховати навіть тріск вогню.'] },
    smallfire: { t: 'МАЛЕ БАГАТТЯ', l: ['Свіжі кіптяви на цьому камінні.', 'Це багаття горіло щойно вночі.', 'Ніхто не зізнається, що запалював його.'] },
    quarry: { t: 'КАР\u2019ЄР', l: ['Кар\u2019єр вичерпали давно. Вода в ньому не замерзає,', 'а джерела, що її живить, ніхто не бачив.'] },
    crane: { t: 'КРАН', l: ['Іржавий кран нахилений над водою, наче заброшена вудка.', 'Трос спадає в темряву. На вітрі він гуде одну ноту.'] },
    car: { t: 'АВТІВКА', l: ['Іржавий універсал, що врос у мох просто при краю кар\u2019єру.', 'Ключі досі в замку. Бак сухий до дна.', 'Переднє сидіння відкинуте. Хтось спав тут дуже давно.'] },
    tower: { t: 'РАДІОВИЖКА', l: ['Щогла зв\u2019язку при станції, що замовкла кілька років тому.', 'Але маяк досі блимає. Хтось тримає генератор у справності.'] },
    hut: { t: 'ПОБУТОВКА', l: ['Бригадна хатина. Чайник на плиті. Стілець повернутий до вікна.', 'На стіні — чек-лист, усі пункти відзначені одним акуратним почерком.'] },
    pier: { t: 'МИСТКИ', l: ['Дошки прибиті вручну й посріблені від негоди. Лампа на краю світиться цього вечора.', 'Озеро не відбиває дерев. Воно забирає світло й нічого не віддає.'] },
    lake: { t: 'ТУМАННЕ ОЗЕРО', l: ['Туман стоїть над водою на палець і не рухається.', 'Старі мапи звали це озеро місцем, де гасне останнє світло.'] },
    tent: { t: 'ЗЛОМАНИЙ НАМЕТ', l: ['Він прогнувся всередину — ніби під людиною, що різко сіла.', 'Усередині чотири спальники. Жодного не забрали.'] },
    symbol: { t: 'СИМВОЛ', l: ['Три лінії та око, вирізані на корі.', 'Різьба стара, темна від дощу.', 'Під мохом їх більше. Усі глибші. Усі новіші.'] },
    sign: { t: 'СТРІЛКА', l: ['Її фарбовані стрілки дивляться в усі боки відразу.', 'Кожна з них, якщо йти за нею, приведе до дому.'] },
    oldtree: { t: 'СТаре ДЕРЕВО', l: ['Стовбур у зарубках. Імена. Дати, які ніхто не прочитає.', 'Деяким — сотні років. Найсвіжіша виглядає так, ніби її зроблено цієї ночі.'] }
  }
}
  };

  var I = {};
  I.lang = 'en';
  I.onLang = null;               /* game hook: refresh dynamic labels */
  I.has = function (key) { var d = D[I.lang] || D.en; return d[key] !== undefined; };
  I.set = function (l) {
    if (!D[l]) l = 'en';
    I.lang = l;
    try { localStorage.setItem('tlp_lang', l); } catch (e) { }
    I.applyDom();
  };
  I.load = function () {
    var saved = null;
    try { saved = localStorage.getItem('tlp_lang'); } catch (e) { }
    if (!saved) {
      var n = (navigator.language || 'en').toLowerCase();
      saved = n.indexOf('uk') === 0 ? 'uk' : (n.indexOf('ru') === 0 ? 'ru' : 'en');
    }
    I.lang = D[saved] ? saved : 'en';
    I.applyDom();
  };
  I.t = function (key) {
    var d = D[I.lang] || D.en;
    var v = d[key];
    if (v === undefined) v = D.en[key];
    return v;
  };
  I.notes = function () { return (D[I.lang] || D.en).notes; };
  I.ex = function (k) {
    var d = D[I.lang] || D.en;
    return (d.ex && d.ex[k]) || D.en.ex[k];
  };
  I.applyDom = function () {
    var q = document.querySelectorAll('[data-i18n]');
    for (var i = 0; i < q.length; i++) {
      var k = q[i].getAttribute('data-i18n');
      var v = I.t(k);
      if (typeof v === 'string') q[i].textContent = v;
    }
    var f = document.querySelectorAll('.flag');
    for (var j = 0; j < f.length; j++) {
      f[j].classList.toggle('active', f[j].getAttribute('data-lang') === I.lang);
    }
    document.documentElement.lang = I.lang;
    if (I.onLang) I.onLang();
  };
  /* the notes live in the world in file order, but the story collects them
     in its own order: camp, the journal in the house, the quarry, the radio,
     the lake. Number the pages the way the player actually finds them. */
  var NOTE_NUM = [1, 3, 2, 4, 5];
  I.noteNum = function (idx) { return NOTE_NUM[idx] || (idx + 1); };
  I.noteTitle = function (idx) { return I.t('note_word') + ' 0' + I.noteNum(idx); };
  T.I18N = I;
  T.t = function (k) { return I.t(k); };
})(window.TLP);
