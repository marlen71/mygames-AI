/* ============================================================
   THE LONE PATH — game core v3
   Components: GameState · Movement · Camera · Lighting
   Interaction · Notes · Chapters · Interior world · UI · i18n
   ============================================================ */
'use strict';
(function () {
  var T = window.TLP;
  var I = T.I18N;
  var game = {};
  T.game = game;
  game.setAimMode = setAimMode;

  /* ---------- DOM ---------- */
  var $ = function (id) { return document.getElementById(id); };
  var scene = $('scene'), ctx = scene.getContext('2d');
  var hud = $('hud'), notesCount = $('notes-count'), thingsCount = $('things-count');
  var thingsBox = $('things-box');
  var partsBox = $('parts-box'), partsCount = $('parts-count');
  var chapterLabel = $('chapter-label'), objectiveLabel = $('objective-label');
  var prompt = $('prompt'), promptLabel = $('prompt-label');
  var toast = $('toast');
  var noteModal = $('note-modal'), noteTitle = $('note-title'), noteBody = $('note-body');
  var fadeEl = $('fade'), bigtext = $('bigtext'), bigtextInner = $('bigtext-inner');
  var menuEl = $('menu'), menuBg = $('menu-bg'), menuBgCtx = menuBg.getContext('2d');
  var compass = $('compass'), compassCtx = compass.getContext('2d');
  var compassLabel = $('compass-label');
  var endBtns = $('end-btns');

  /* ---------- buffers ---------- */
  var light = T.canvas(2, 2), lctx = light.getContext('2d');
  var CW = 0, CH = 0, DPR = 1, zoom = 1;

  /* the tiny reticle: shows where the mouse is, or where the player looks */
  function updateXhair() {
    var el = $('xhair');
    if (!el) return;
    if (S.mode !== 'play') { el.classList.add('hidden'); return; }
    el.classList.remove('hidden');
    var x, y;
    if (S.aimMode === 'mouse') {
      x = (S.mx * 0.5 + 0.5) * CW;
      y = (S.my * 0.5 + 0.5) * CH;
    } else {
      var zz = S.world === 'in' ? zoom * 1.22 : zoom;
      x = CW / 2 + (player.x + Math.cos(player.fa) * 118 - cam.x) * zz;
      y = CH / 2 + (player.y + Math.sin(player.fa) * 118 - cam.y) * zz;
    }
    el.style.left = Math.round(x) + 'px';
    el.style.top = Math.round(y) + 'px';
    var tgt = S.interactTarget;
    el.classList.toggle('hot', !!(tgt && tgt.kind !== 'examine'));
  }

  function resize() {
    DPR = Math.min(window.devicePixelRatio || 1, 1.75);
    CW = window.innerWidth; CH = window.innerHeight;
    scene.width = Math.floor(CW * DPR); scene.height = Math.floor(CH * DPR);
    light.width = scene.width; light.height = scene.height;
    menuBg.width = scene.width; menuBg.height = scene.height;
    var cdpr = Math.min(DPR, 2);
    compass.width = Math.floor(96 * cdpr); compass.height = Math.floor(96 * cdpr);
    zoom = T.clamp(CH / 620, 0.95, 2.3);
  }
  window.addEventListener('resize', resize);

  /* ---------- worlds ---------- */
  var WS = null;                                   /* { out, int } */
  var GRIDS = {};                                  /* collision grid per world */
  var CELL = 96;
  function world() { return S.world === 'in' ? WS.int : WS.out; }
  function buildGrid(w) {
    var grid = {};
    for (var i = 0; i < w.colliders.length; i++) {
      var c = w.colliders[i];
      var x0, x1, y0, y1;
      if (c.rect) { x0 = c.rect.x - 16; x1 = c.rect.x + c.rect.w + 16; y0 = c.rect.y - 16; y1 = c.rect.y + c.rect.h + 16; }
      else { x0 = c.x - c.r - 16; x1 = c.x + c.r + 16; y0 = c.y - c.r - 16; y1 = c.y + c.r + 16; }
      for (var gx = Math.floor(x0 / CELL); gx <= Math.floor(x1 / CELL); gx++)
        for (var gy = Math.floor(y0 / CELL); gy <= Math.floor(y1 / CELL); gy++)
          (grid[gx + ':' + gy] || (grid[gx + ':' + gy] = [])).push(c);
    }
    GRIDS[w.id] = grid;
  }
  var drawMap = {
    pine: T.Assets.pine, fir: T.Assets.fir, small: T.Assets.small, dry: T.Assets.dry,
    stump: T.Assets.stump, rock: T.Assets.rock, fallen: T.Assets.fallen, bush: T.Assets.bush,
    crate: T.Assets.crate, barrel: T.Assets.barrel, logpile: T.Assets.logpile, table: T.Assets.table,
    planks: T.Assets.planks, tent: T.Assets.tent, firepit: T.Assets.firepit, cabin: T.Assets.cabin,
    car: T.Assets.car, sign: T.Assets.sign, bigtree: T.Assets.bigtree, signtree: T.Assets.signtree,
    cross: T.Assets.cross, fence: T.Assets.fence,
    crane: T.Assets.crane, tower: T.Assets.tower, hut: T.Assets.hut, lamp: T.Assets.lamp,
    wallH: T.Assets.wallH, wallV: T.Assets.wallV, windowIn: T.Assets.windowIn,
    bed: T.Assets.bed, shelf: T.Assets.shelf, cabinet: T.Assets.cabinet,
    chair: T.Assets.chair, hearthIn: T.Assets.hearthIn, lanternPeg: T.Assets.lanternPeg,
    doorIn: T.Assets.doorIn
  };

  /* ---------- state ---------- */
  var S = {
    mode: 'menu',           /* menu | controls | credits | intro | play | note | pause | final | end */
    t: 0, modeT: 0,
    darkness: 0.84, targetDark: 0.84,
    world: 'out',
    notes: [false, false, false, false, false],   /* master flags, survive world switches */
    collected: 0, things: 0, itemsMask: 0,
    chapter: -1, chapterToast: null,
    enteredHouse: false, exitHinted: false,
    finalStarted: false, finalT: -1, _t1: false, _t2: false, _t3: false,
    parts: 0, partsMask: 0, carHinted: false,
    gates: { house: false, quarry: false, radio: false, lake: false },
    finalDrive: false, driveDark: 0, shake: 0, sparks: [], ratIdx: 0,
    figA: 0, figTarget: 0, figX: 402, figY: 1250, flick: 0,
    mx: 0, my: 0, emx: 0, emy: 0,
    aimMode: 'keys',
    rain: [],
    promptHide: -1, interactTarget: null,
    hints: null, introStep: -1,
    letterbox: 0, transitioning: 0,
    panel: null
  };
  game.S = S;

  var player = { x: 800, y: 1195, vx: 0, vy: 0, fa: -Math.PI / 2, walk: 0, moving: false, pose: '', poseT: 0 };
  var cam = { x: 800, y: 1195 };
  var flash = false;
  game.flash = false;
  game.player = player;      /* handy for debugging / automated tests */
  game.cam = cam;
  game.worlds = function () { return WS; };

  /* beam dust motes: fixed relative slots, drift with time */
  var DUST = [];
  (function () {
    var r = T.rng(4242);
    for (var i = 0; i < 26; i++)
      DUST.push({ a: r() * 2 - 1, d: 0.14 + r() * 0.86, ph: r() * T.TAU, sp: 0.5 + r() });
  })();

  /* water ripple spots (lake + quarry), world coords */
  var RIP = [[958, 242], [1036, 206], [1200, 904], [1249, 938]];

  /* ---------- input ---------- */
  var keys = {};
  var wantInteract = false, wantClose = false, wantToggleFlash = false, skipIntro = false;
  var wantEscape = false;

  window.addEventListener('keydown', function (e) {
    var k = e.code;
    if (['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'Space'].indexOf(k) >= 0) e.preventDefault();
    if (!keys[k]) {
      if (k === 'KeyF') wantToggleFlash = true;
      if (k === 'KeyE') wantInteract = true;
      if (k === 'Enter' || k === 'Space') wantClose = true;
      if (k === 'Escape') wantEscape = true;
      if (k === 'KeyM') TLP.Audio.mute(!TLP.Audio.muted);
      if (S.mode === 'intro') skipIntro = true;
    }
    keys[k] = true;
  });
  window.addEventListener('keyup', function (e) { keys[e.code] = false; });
  window.addEventListener('blur', function () { keys = {}; });
  window.addEventListener('mousemove', function (e) {
    S.mx = (e.clientX / Math.max(CW, 1) - 0.5) * 2;
    S.my = (e.clientY / Math.max(CH, 1) - 0.5) * 2;
  });

  function audioClick(deep) { TLP.Audio.ui(deep); }

  /* ---------- helpers ---------- */
  function setMode(m) { S.mode = m; S.modeT = 0; }
  function show(el) { el.classList.remove('hidden'); }
  function hide(el) { el.classList.add('hidden'); }
  function black(on) { fadeEl.style.opacity = on ? 1 : 0; }

  var toastTimer = null;
  function showToast(text, dur) {
    toast.innerHTML = text;
    show(toast);
    requestAnimationFrame(function () { toast.classList.add('vis'); });
    clearTimeout(toastTimer);
    toastTimer = setTimeout(function () { toast.classList.remove('vis'); }, dur || 2600);
  }

  /* ---------- screens ---------- */
  function hideScreenAll() {
    [menuEl, $('ep-screen'), $('controls-screen'), $('credits-screen'), $('pause-screen'), $('end-screen')].forEach(hide);
  }
  function showScreen(el) { show(el); }

  function setAimMode(m, silent) {
    S.aimMode = m === 'mouse' ? 'mouse' : 'keys';
    try { localStorage.setItem('tlp_aim', S.aimMode); } catch (e) {}
    document.body.classList.toggle('aim-mouse', S.aimMode === 'mouse');
    var ak = $('aim-keys'), am = $('aim-mouse');
    if (ak) ak.classList.toggle('active', S.aimMode === 'keys');
    if (am) am.classList.toggle('active', S.aimMode === 'mouse');
    if (!silent) {
      TLP.Audio.ui(false);
      showToast(I.t(S.aimMode === 'mouse' ? 'aimset_mouse' : 'aimset_keys'));
    }
  }

  function gotoMenu() {
    hideScreenAll();
    show(menuEl);
    hide(hud); hide(prompt); hide(bigtext); hide(toast);
    hide(noteModal);
    S.panel = null;
    clearTimeout(toastTimer);
    TLP.Audio.engine(false, 0);
    TLP.Audio.quiet(true);
    setMode('menu');
    black(false);
    fadeEl.style.transition = '';
    S.promptHide = -1;
    S.transitioning = 0;
    I.applyDom();
  }

  function startGame() {
    TLP.Audio.ensure();
    TLP.Audio.startAmbient();
    TLP.Audio.quiet(false);
    audioClick(true);
    resetRun();
    hideScreenAll();
    black(true);
    setTimeout(function () {
      show(bigtext);
      setMode('intro');
      S.introStep = -1; skipIntro = false;
      black(false);
    }, 900);
  }

  function updateIntro(dt) {
    var lines = I.t('intro');
    if (skipIntro) { beginPlay(); return; }
    var step = Math.floor(S.modeT / 3.1);
    if (step !== S.introStep && step < lines.length) {
      S.introStep = step;
      bigtextInner.textContent = lines[step];
      bigtextInner.classList.remove('vis');
      setTimeout(function () { if (S.mode === 'intro' && !skipIntro) bigtextInner.classList.add('vis'); }, 60);
      setTimeout(function () { bigtextInner.classList.remove('vis'); }, 2450);
    }
    if (S.modeT > 10.2) beginPlay();
  }

  function beginPlay() {
    hide(bigtext);
    show(hud);
    setMode('play');
    black(false);
    computeChapter(true);
    updateNotesHud();
    prompt.classList.remove('vis');
    S.hints = [
      { t: 1.8, k: 'hint_flash', dur: 2300 },
      { t: 4.8, k: 'hint_move', dur: 2300 },
      { t: 8.2, k: 'obj_first', dur: 3200 }
    ];
  }

  function resetRun() {
    S.world = 'out';
    player.x = 800; player.y = 1195; player.vx = 0; player.vy = 0;
    player.fa = -Math.PI / 2; player.walk = 0; player.moving = false;
    cam.x = player.x; cam.y = player.y;
    flash = false; game.flash = false;
    S.notes = [false, false, false, false, false];
    S.collected = 0; S.things = 0; S.itemsMask = 0;
    S.parts = 0; S.partsMask = 0; S.carHinted = false;
    S.gates = { house: false, quarry: false, radio: false, lake: false };
    S.finalDrive = false; S.driveDark = 0; S.shake = 0; S.sparks = [];
    player.pose = ''; player.poseT = 0;
    var carO = WS.out.carObj;
    if (carO) { carO.x = 1152; carO.y = 982; carO.rot = -0.45; carO.segI = 0; carO.lighted = false; }
    TLP.Audio.engine(false, 0);
    S.chapter = -1; S.chapterToast = null;
    S.enteredHouse = false; S.exitHinted = false;
    S.finalStarted = false; S.finalT = -1;
    S.figA = 0; S.figTarget = 0; S.flick = 0;
    S._t1 = S._t2 = S._t3 = false;
    S._f1 = S._f2 = S._fig = S._figPass = S._gone = false;
    S.letterbox = 0;
    S.darkness = 0.84; S.targetDark = 0.84;
    S.interactTarget = null; S.promptHide = -1;
    S.transitioning = 0;
    hide(prompt); hide(toast); hide(noteModal);
    thingsBox.classList.add('hidden');
    partsBox.classList.add('hidden');
    S.panel = null;
    clearTimeout(toastTimer);
    WS.out.notes.forEach(function (n) { n.taken = false; });
    updateGates(true);
    [WS.out, WS.int].forEach(function (w) {
      w.items.forEach(function (it) { it.taken = false; });
      w.fires.forEach(function (f) { if (f.kind !== 'lamp') f.lit = false; });
    });
    var cab = WS.int.cabinet;
    cab.open = false; cab.journalTaken = false;
    TLP.Audio.setFire(false, 0);
    updateNotesHud();
    computeChapter(true);
    refreshObjective();
  }

  /* ---------- progression: the forest opens in its own order ------------ */
  var GATE_REQ = { house: 0, quarry: 2, radio: 1, lake: 3 };   /* gate <- note that opens it */
  var NOTE_REQ = [null, 2, null, 1, 3];                          /* a note may demand an earlier one */
  var PART_GATE = ['quarry', 'radio', 'lake'];                   /* a part lives behind a gate */
  var NOTE_GATE = [null, 'quarry', null, 'radio', 'lake'];
  function noteLocked(i) { var r = NOTE_REQ[i]; return r != null && !S.notes[r]; }
  function partLocked(id) { return !S.gates[PART_GATE[id]]; }
  function allDone() { return S.collected >= 5 && S.parts >= 3; }
  function updateGates(silent) {
    for (var g in GATE_REQ) {
      var open = S.notes[GATE_REQ[g]];
      if (open !== S.gates[g]) {
        S.gates[g] = open;
        if (open && !silent && g !== 'house') {
          showToast(I.t('gate_open'), 3400);
          TLP.Audio.ui(true);
        }
      }
    }
  }

  /* ---------- chapters ---------- */
  function computeChapter(silent) {
    var CN = T.World.CHAPTER_NOTE;
    var ch = 5;
    for (var i = 0; i < 5; i++) {
      var needPart = i >= 2 && ((S.partsMask >> (i - 2)) & 1) === 0;
      if (!S.notes[CN[i]] || needPart) { ch = i; break; }
    }
    if (ch !== S.chapter) {
      var prev = S.chapter;
      S.chapter = ch;
      if (!silent && prev >= 0 && ch >= 1 && ch <= 4)
        S.chapterToast = I.t('ch_toast')[ch - 1];
    }
    hudTexts();
  }

  function hudTexts() {
    var ch = T.clamp(S.chapter < 0 ? 0 : (S.chapter > 4 ? 4 : S.chapter), 0, 4);
    chapterLabel.textContent = I.t('hud_chapter') + ' ' + ['I', 'II', 'III', 'IV', 'V'][ch] + ' \u00B7 ' + I.t('ch')[ch];
    var objTxt;
    if (allDone()) objTxt = I.t('ret_car');
    else if (S.chapter === 1 && S.world === 'in') objTxt = I.t('obj_search');
    else objTxt = I.t('ch_obj')[ch];
    objectiveLabel.textContent = objTxt;
  }

  /* ---------- objective / compass ---------- */
  var objective = null;
  function refreshObjective() { objective = computeObjective(); }
  function computeObjective() {
    var w = world();
    if (S.world === 'in') {
      if (S.chapter === 1 && S.collected < 5) {
        var best = null, bd = 1e18;
        for (var i = 0; i < w.items.length; i++) {
          var it = w.items[i];
          if (it.taken) continue;
          var d = T.dist2(player.x, player.y, it.x, it.y);
          if (d < bd) { bd = d; best = it; }
        }
        if (best) return { x: best.x, y: best.y, k: 'int_' + best.kind };
        var cab = w.cabinet;
        if (cab.journal && !cab.journalTaken) return { x: cab.x, y: cab.y + 10, k: 'int_cabinet' };
      }
      return { x: w.W / 2, y: w.H - 16, k: 'lbl_leave' };
    }
    if (allDone()) return { x: 1152, y: 968, k: 'lbl_car' };
    if (S.chapter === 1 && !S.notes[2]) return { x: 800, y: 748, k: 'lbl_door_out' };
    var CN = T.World.CHAPTER_NOTE;
    var ch = S.chapter, wants = [];
    if (ch >= 0 && ch <= 4) {
      var ni = CN[ch];
      if (!S.notes[ni]) {
        for (var q = 0; q < w.notes.length; q++) {
          var nq = w.notes[q];
          if (nq.idx === ni && !nq.taken)
            wants.push({ x: nq.x, y: nq.y, k: null, label: I.noteTitle(ni) });
        }
      }
      if (ch >= 2 && ((S.partsMask >> (ch - 2)) & 1) === 0) {
        for (var qq = 0; qq < w.items.length; qq++) {
          var iq = w.items[qq];
          if (iq.part && iq.id === ch - 2 && !iq.taken)
            wants.push({ x: iq.x, y: iq.y, k: null, label: I.t(iq.label) });
        }
      }
      if (wants.length) {
        var bw = null, bdw = 1e18;
        for (var m = 0; m < wants.length; m++) {
          var dd = T.dist2(player.x, player.y, wants[m].x, wants[m].y);
          if (dd < bdw) { bdw = dd; bw = wants[m]; }
        }
        if (bw) return bw;
      }
    }
    /* fallback: any note the forest is willing to show */
    var best2 = null, bd2 = 1e18;
    for (var n2 = 0; n2 < w.notes.length; n2++) {
      var nt2 = w.notes[n2];
      if (nt2.taken || S.notes[nt2.idx] || noteLocked(nt2.idx)) continue;
      var d3 = T.dist2(player.x, player.y, nt2.x, nt2.y);
      if (d3 < bd2) { bd2 = d3; best2 = nt2; }
    }
    if (best2) return { x: best2.x, y: best2.y, k: null, label: I.noteTitle(best2.idx) };
    return null;
  }
  function objectiveLabelFor(o) { return o ? (o.label || I.t(o.k)) : ''; }

  function drawCompass() {
    var c = compassCtx, R = 96, cdpr = c.canvas.width / 96;
    c.setTransform(cdpr, 0, 0, cdpr, 0, 0);
    c.clearRect(0, 0, R, R);
    var cx = R / 2, cy = R / 2, r = 32;
    c.fillStyle = 'rgba(6,8,8,0.55)';
    c.beginPath(); c.arc(cx, cy, r + 5, 0, T.TAU); c.fill();
    c.lineWidth = 1;
    c.strokeStyle = 'rgba(167,172,168,0.22)';
    c.beginPath(); c.arc(cx, cy, r, 0, T.TAU); c.stroke();
    c.strokeStyle = 'rgba(167,172,168,0.07)';
    c.beginPath(); c.arc(cx, cy, r - 8, 0, T.TAU); c.stroke();
    c.fillStyle = 'rgba(167,172,168,0.4)';
    c.font = '8px "Segoe UI", sans-serif';
    c.textAlign = 'center';
    c.fillText('N', cx, 8);
    if (!objective || S.mode !== 'play') return;
    var ang = Math.atan2(objective.y - player.y, objective.x - player.x);
    c.save();
    c.translate(cx, cy);
    c.rotate(ang + Math.PI / 2);
    c.fillStyle = 'rgba(215,208,183,0.85)';
    c.beginPath();
    c.moveTo(0, -15); c.lineTo(4.2, 6); c.lineTo(0, 2.6); c.lineTo(-4.2, 6);
    c.closePath(); c.fill();
    c.restore();
    var d = Math.sqrt(T.dist2(player.x, player.y, objective.x, objective.y));
    var span = S.world === 'in' ? 420 : 760;
    var fr = T.clamp(1 - d / span, 0.08, 1);
    c.strokeStyle = 'rgba(215,208,183,0.5)';
    c.lineWidth = 1.6;
    c.beginPath(); c.arc(cx, cy, r + 3, -Math.PI / 2, -Math.PI / 2 + fr * T.TAU); c.stroke();
  }

  /* ---------- movement + collision ---------- */
  function collide(x, y) {
    var pr = 8;
    var grid = GRIDS[world().id];
    var gx = Math.floor(x / CELL), gy = Math.floor(y / CELL);
    for (var ix = gx - 1; ix <= gx + 1; ix++) {
      for (var iy = gy - 1; iy <= gy + 1; iy++) {
        var arr = grid[ix + ':' + iy];
        if (!arr) continue;
        for (var i = 0; i < arr.length; i++) {
          var c = arr[i];
          if (c.gate && S.gates[c.gate]) continue;
          if (c.rect) {
            var r = c.rect;
            var nx = T.clamp(x, r.x, r.x + r.w), ny = T.clamp(y, r.y, r.y + r.h);
            var dx = x - nx, dy = y - ny;
            var d2 = dx * dx + dy * dy;
            if (d2 < pr * pr) {
              if (d2 > 0.0001) {
                var d = Math.sqrt(d2);
                x = nx + dx / d * pr; y = ny + dy / d * pr;
              } else {
                var cx2 = r.x + r.w / 2, cy2 = r.y + r.h / 2;
                var ox = (pr + r.w / 2) - Math.abs(x - cx2), oy = (pr + r.h / 2) - Math.abs(y - cy2);
                if (ox < oy) x += (x > cx2 ? ox : -ox); else y += (y > cy2 ? oy : -oy);
              }
            }
          } else if (c.r > 0) {
            var dx2 = x - c.x, dy2 = y - c.y;
            var min = c.r + pr, dd = dx2 * dx2 + dy2 * dy2;
            if (dd < min * min && dd > 0.0001) {
              var d3 = Math.sqrt(dd);
              x = c.x + dx2 / d3 * min; y = c.y + dy2 / d3 * min;
            }
          }
        }
      }
    }
    return [x, y];
  }

  function darknessAt(x, y) {
    if (S.world === 'in') return world().dark;
    var d = 0.825;
    var z = T.World.ZONES;
    var dl = Math.sqrt(T.dist2(x, y, z.lake.x, z.lake.y));
    if (dl < 340) d += 0.05 * (1 - dl / 340);          /* fog thickens at the lake */
    var dr = Math.sqrt(T.dist2(x, y, z.radio.x, z.radio.y));
    if (dr < 300) d += 0.03 * (1 - dr / 300);
    var ds = Math.sqrt(T.dist2(x, y, z.start.x, z.start.y));
    if (ds < 260) d -= 0.015 * (1 - ds / 260);
    return T.clamp(d, 0.79, 0.93);
  }

  /* ---------- interaction ---------- */
  function nearestInteract() {
    var w = world();
    var i, d;
    /* notes have priority */
    var best = null, bd = 45;
    for (i = 0; i < w.notes.length; i++) {
      var n = w.notes[i];
      if (n.taken || S.notes[n.idx]) continue;
      d = Math.sqrt(T.dist2(player.x, player.y, n.x, n.y));
      if (d < bd) { bd = d; best = n; }
    }
    if (best) return { kind: 'note', data: best, act: 'note', label: I.t('read') };
    /* items inside the house */
    best = null; bd = 40;
    for (i = 0; i < w.items.length; i++) {
      var it = w.items[i];
      if (it.taken) continue;
      d = Math.sqrt(T.dist2(player.x, player.y, it.x, it.y));
      if (d < bd) { bd = d; best = it; }
    }
    if (best) return { kind: 'item', data: best, act: 'item', label: I.t('take') };
    /* examines */
    best = null; bd = 1e9;
    for (i = 0; i < w.examines.length; i++) {
      var e = w.examines[i];
      if (e.hideWhen && S.notes[e.hideWhen]) continue;
      d = Math.sqrt(T.dist2(player.x, player.y, e.x, e.y));
      if (d < e.r && d < bd) { bd = d; best = e; }
    }
    if (!best) return null;
    var e2 = best;
    var act = e2.special || 'panel';
    var label = act === 'car' && allDone() ? I.t('act_fix') : I.t(e2.label || 'examine');
    if (act === 'cabinet') {
      var cab = e2.data;
      label = (!cab.open) ? I.t('examine')
        : (cab.journal && !cab.journalTaken) ? I.t('cab_word') : I.t('examine');
    }
    return { kind: 'examine', data: e2, act: act, label: label };
  }

  function openPanel(title, lines, src) {
    S.panel = src || null;
    if (!lines || !lines.length) lines = [''];
    noteTitle.textContent = title;
    noteBody.innerHTML = lines.join('<br>');
    player.pose = 'read';
    prompt.classList.remove('vis');
    hide(prompt);
    S.promptHide = -1;
    show(noteModal);
    setMode('note');
  }
  function panelSource() {
    var p = S.panel;
    if (!p) return null;
    if (p.type === 'note') return { title: I.noteTitle(p.idx), lines: I.notes()[p.idx].lines };
    if (p.type === 'car') return { title: I.ex('car').t, lines: carLines() };
    if (p.type === 'ex') { var ex = I.ex(p.key) || { t: I.t('examine'), l: [] }; return { title: ex.t, lines: ex.l }; }
    if (p.type === 'text') return { title: I.t(p.titleKey), lines: [I.t(p.bodyKey)] };
    return null;
  }
  function refreshPanel() {
    var src = panelSource();
    if (src) { noteTitle.textContent = src.title; noteBody.innerHTML = src.lines.join('<br>'); }
  }
  function closePanel() {
    hide(noteModal);
    S.panel = null;
    setMode('play');
    if (S.chapterToast) {
      var s = S.chapterToast;
      S.chapterToast = null;
      showToast(s, 3400);
      audioClick(true);
    }
    player.pose = ''; player.poseT = 0;
    if (allDone() && !S.finalStarted) hintCar();
    refreshObjective();
    hudTexts();
  }

  function hintCar() {
    if (S.carHinted) return;
    S.carHinted = true;
    showToast(I.t('ret_car'), 3600);
    compassLabel.textContent = I.t('lbl_car');
  }
  function takeNote(idx) {
    S.notes[idx] = true;
    S.collected++;
    player.pose = 'pickup'; player.poseT = 1.15;
    var w = world();
    w.notes.forEach(function (n) { if (n.idx === idx) n.taken = true; });
    updateNotesHud();
    TLP.Audio.noteGet();
    computeChapter(false);
    updateGates(false);
    openPanel(I.noteTitle(idx), I.notes()[idx].lines, { type: 'note', idx: idx });
  }
  function updateNotesHud() {
    notesCount.innerHTML = S.collected + '&nbsp;/&nbsp;5';
    notesCount.classList.remove('pop');
    void notesCount.offsetWidth;
    notesCount.classList.add('pop');
    thingsCount.innerHTML = S.things + '&nbsp;/&nbsp;3';
    partsCount.innerHTML = S.parts + '&nbsp;/&nbsp;3';
    partsCount.classList.remove('pop');
    void partsCount.offsetWidth;
    if (S.parts > 0) partsCount.classList.add('pop');
    partsBox.classList.toggle('hidden', !(S.world === 'out' && (S.chapter >= 2 || S.parts > 0)));
  }
  function takePart(it) {
    it.taken = true;
    S.parts++;
    S.partsMask |= (1 << it.id);
    player.pose = 'pickup'; player.poseT = 1.15;
    TLP.Audio.ui(true);
    updateNotesHud();
    showToast(I.t('toast_parts')[it.id], 3200);
    computeChapter(false);
    updateGates(false);
    if (allDone()) hintCar();
    refreshObjective();
    hudTexts();
  }
  function carLines() {
    var lines = [I.t('car_need')];
    var names = ['item_tools', 'item_fuel', 'item_wheel'];
    for (var i = 0; i < 3; i++) {
      var got = ((S.partsMask >> i) & 1) !== 0;
      lines.push(I.t(names[i]) + '  \u2014  <span style="color:' + (got ? '#d8dccd' : '#a06a40') + '">' +
        I.t(got ? 'car_have' : 'car_missing') + '</span>');
    }
    lines.push('<span style="opacity:.55">' + I.ex('car').l.join('<br>') + '</span>');
    return lines;
  }

  function takeItem(it) {
    it.taken = true;
    player.pose = 'pickup'; player.poseT = 1.0;
    S.things++;
    S.itemsMask |= (1 << it.id);
    updateNotesHud();
    TLP.Audio.ui(true);
    showToast(I.t('toast_found')[it.id], 2800);
    refreshObjective();
  }

  /* ---------- world switching (the house) ---------- */
  function goWorld(toIn, x, y, fa) {
    if (S.transitioning) return;
    S.transitioning = 1;
    TLP.Audio.ui(false);
    fadeEl.style.transition = 'opacity .32s ease';
    black(true);
    setTimeout(function () {
      S.world = toIn ? 'in' : 'out';
      var w = world();
      player.x = x; player.y = y; player.vx = 0; player.vy = 0;
      if (fa != null) player.fa = fa;
      cam.x = x; cam.y = y;
      S.interactTarget = null; S.promptHide = -1;
      hide(prompt);
      thingsBox.classList.toggle('hidden', !toIn);
      if (toIn) {
        if (!S.enteredHouse) { S.enteredHouse = true; showToast(I.t('obj_search'), 3600); }
      } else {
        if (!S.exitHinted && S.collected < 5) { S.exitHinted = true; showToast(I.t('door_back'), 3400); }
      }
      refreshObjective();
      hudTexts();
      updateNotesHud();
      black(false);
      setTimeout(function () {
        fadeEl.style.transition = '';
        S.transitioning = 0;
      }, 360);
    }, 380);
  }
  function cabinetAct(cab) {
    if (!cab.open) {
      var hasKey = (S.itemsMask & 4) !== 0;
      if (hasKey) {
        cab.open = true;
        TLP.Audio.ui(true);
        openPanel(I.t('cab_title'), [I.t('cabinet_open')], { type: 'text', titleKey: 'cab_title', bodyKey: 'cabinet_open' });
      } else {
        TLP.Audio.ui(false);
        openPanel(I.t('cab_title'), [I.t('cabinet_locked')], { type: 'text', titleKey: 'cab_title', bodyKey: 'cabinet_locked' });
      }
      return;
    }
    if (cab.journal && !cab.journalTaken) {
      cab.journalTaken = true;
      takeNote(2);                     /* the hidden journal: chapter II's note */
      return;
    }
    openPanel(I.t('cab_title'), [I.t('cabinet_open')], { type: 'text', titleKey: 'cab_title', bodyKey: 'cabinet_open' });
  }

  function doInteract(tg) {
    var d = tg.data;
    if (tg.act === 'note') {
      if (noteLocked(d.idx)) {
        TLP.Audio.ui(false);
        showToast(I.t('gate_' + NOTE_GATE[d.idx]), 3000);
        return;
      }
      takeNote(d.idx); return;
    }
    if (tg.act === 'item') {
      if (d.part) {
        if (partLocked(d.id)) {
          TLP.Audio.ui(false);
          showToast(I.t('gate_' + PART_GATE[d.id]), 3000);
          return;
        }
        takePart(d); return;
      }
      takeItem(d); return;
    }
    if (tg.act === 'enter') {
      if (!S.gates.house) {
        TLP.Audio.ui(false);
        showToast(I.t('gate_house'), 3000);
        return;
      }
      goWorld(true, T.World.RW / 2, T.World.RH - 64, -Math.PI / 2); return;
    }
    if (tg.act === 'exit') { goWorld(false, 800, 784, Math.PI / 2); return; }
    if (tg.act === 'cabinet') { cabinetAct(world().cabinet); return; }
    if (tg.act === 'car') {
      if (allDone()) { startFinal(); return; }
      TLP.Audio.ui(false);
      openPanel(I.ex('car').t, carLines(), { type: 'car' });
      return;
    }
    var ex = I.ex(d.ikey) || { t: I.t('examine'), l: [] };
    TLP.Audio.ui(false);
    openPanel(ex.t, ex.l, { type: 'ex', key: d.ikey });
  }

  /* ---------- update: play ---------- */
  function updatePlay(dt) {
    var w = world();
    var ax = 0, ay = 0;
    if (keys['KeyW'] || keys['ArrowUp']) ay -= 1;
    if (keys['KeyS'] || keys['ArrowDown']) ay += 1;
    if (keys['KeyA'] || keys['ArrowLeft']) ax -= 1;
    if (keys['KeyD'] || keys['ArrowRight']) ax += 1;
    var len = Math.hypot(ax, ay);
    if (len > 0) { ax /= len; ay /= len; }
    var speed = S.world === 'in' ? 128 : 150;
    player.vx = T.smooth(player.vx, ax * speed, dt, 0.22);
    player.vy = T.smooth(player.vy, ay * speed, dt, 0.22);
    player.x += player.vx * dt;
    player.y += player.vy * dt;
    var res = collide(player.x, player.y);
    player.x = T.clamp(res[0], 26, w.W - 26);
    player.y = T.clamp(res[1], 26, w.H - 26);
    player.moving = len > 0 && Math.hypot(player.vx, player.vy) > 12;
    if (player.moving) {
      player.walk = (player.walk + dt * (S.world === 'in' ? 2.4 : 2.6)) % 1;
      if (S.aimMode === 'keys') {
        /* keys mode: the eyes and the lantern follow the stride */
        player.fa = T.angleLerp(player.fa, Math.atan2(ay, ax), 1 - Math.pow(0.000001, dt));
      }
    }
    if (S.aimMode === 'mouse') {
      /* mouse mode: the player looks at the cursor; movement still runs on keys */
      var zz = S.world === 'in' ? zoom * 1.22 : zoom;
      var ax2 = S.mx * CW * 0.5 - (player.x - cam.x) * zz;
      var ay2 = S.my * CH * 0.5 - (player.y - cam.y) * zz;
      if (ax2 * ax2 + ay2 * ay2 > 900) {
        player.fa = T.angleLerp(player.fa, Math.atan2(ay2, ax2), 1 - Math.pow(0.00002, dt));
      }
    }

    if (wantToggleFlash) {
      flash = !flash;
      game.flash = flash;
      audioClick(false);
    }

    if (wantInteract && S.interactTarget && !S.transitioning) doInteract(S.interactTarget);

    var near = nearestInteract();
    S.interactTarget = near;
    if (near) {
      promptLabel.textContent = near.label;
      show(prompt);
      prompt.classList.add('vis');
      S.promptHide = -1;
    } else if (prompt.classList.contains('vis') && S.promptHide < 0) {
      S.promptHide = S.t + 1.0;   /* linger ~1s, then fade out */
    }
    if (S.promptHide > 0 && S.t > S.promptHide) {
      prompt.classList.remove('vis');
      S.promptHide = -2;
    }
    if (S.promptHide === -2 && !S.interactTarget) { hide(prompt); S.promptHide = -1; }

    if (S.hints && S.hints.length && S.modeT > S.hints[0].t) {
      var h = S.hints.shift();
      showToast(I.t(h.k), h.dur);
    }

    /* camera: gentle parallax inside the room, follow outside */
    if (S.world === 'in') {
      var mcx = w.W / 2, mcy = w.H / 2;
      cam.x = T.smooth(cam.x, mcx + (player.x - mcx) * 0.25, dt, 0.08);
      cam.y = T.smooth(cam.y, mcy + (player.y - mcy) * 0.25, dt, 0.08);
    } else {
      cam.x = T.smooth(cam.x, player.x, dt, 0.10);
      cam.y = T.smooth(cam.y, player.y, dt, 0.10);
    }

    objective = computeObjective();
    var lbl = objectiveLabelFor(objective);
    if (compassLabel.textContent !== lbl) compassLabel.textContent = lbl;
    var objTxt = objectiveLabel.textContent;
    hudTexts();
    if (objectiveLabel.textContent !== objTxt) { /* changed while standing — silent */ }

    S.targetDark = darknessAt(player.x, player.y);

    /* fire crackle only near open fires, never indoors */
    var nearFire = 0;
    if (S.world === 'out') {
      for (var f = 0; f < w.fires.length; f++) {
        var ff = w.fires[f];
        if (!ff.lit || ff.kind !== 'fire') continue;
        var fd = Math.sqrt(T.dist2(player.x, player.y, ff.x, ff.y));
        nearFire = Math.max(nearFire, T.clamp(1 - fd / 260, 0, 1));
      }
    }
    TLP.Audio.setFire(nearFire > 0.01, nearFire);

    if (S.world === 'out' && allDone() && !S.finalStarted) hintCar();

    /* the crouch after a pick-up, then back to the lantern */
    if (player.poseT > 0) {
      player.poseT -= dt;
      if (player.poseT <= 0 && player.pose !== 'read') player.pose = '';
    }
  }

  /* ---------- final sequence: fix the car, drive out of the forest ---------- */
  var CAR_PATH = [[1152, 982], [1040, 1060], [840, 1140], [660, 1170], [470, 1215], [260, 1265], [-60, 1310]];
  function startFinal() {
    S.finalStarted = true;
    S.finalT = 0;
    S.finalDrive = false;
    S.figA = 0; S.figTarget = 0; S.flick = 0;
    S._fig = S._figPass = S._gone = S._f1 = S._f2 = false;
    S.sparks = []; S.ratIdx = 0;
    var c = WS.out.carObj;
    c.x = CAR_PATH[0][0]; c.y = CAR_PATH[0][1]; c.rot = -0.45; c.segI = 0; c.lighted = false;
    player.x = 1116; player.y = 1012; player.vx = 0; player.vy = 0;
    player.fa = -2.3; player.pose = ''; player.poseT = 0;
    cam.x = 1150; cam.y = 992;
    setMode('final');
    prompt.classList.remove('vis');
    hide(prompt);
    hide(toast);
    hide(hud);
    TLP.Audio.quiet(false);
    TLP.Audio.setFire(true, 0.45);
  }
  function updateFinal(dt) {
    S.finalT += dt;
    var ft = S.finalT, c = WS.out.carObj;
    S.targetDark = S.finalDrive ? T.clamp(0.955 + (ft - 2.6) * 0.02, 0.94, 0.992) : T.clamp(0.94 + Math.min(ft, 8) * 0.008, 0.94, 0.99);
    if (ft > 0.9 && !S._f1) { S._f1 = true; WS.out.fires[1].lit = true; }
    if (ft > 1.9 && !S._f2) { S._f2 = true; WS.out.fires[0].lit = true; }

    if (ft < 2.6) {
      /* A: under the hood. Ratchet ticks, sparks, the first cough of the engine. */
      var RAT = [0.55, 1.15, 1.75, 2.3];
      if (S.ratIdx < RAT.length && ft > RAT[S.ratIdx]) {
        S.ratIdx++;
        TLP.Audio.ratchet(S.ratIdx % 2 === 0);
        for (var sk = 0; sk < 7; sk++)
          S.sparks.push({ x: 1140 + Math.random() * 26, y: 964 + Math.random() * 12, vx: -60 + Math.random() * 130, vy: -140 - Math.random() * 90, l: 0.6 + Math.random() * 0.5 });
      }
      if (ft > 1.7 && !c.lighted) { c.lighted = true; }
    } else if (!S.finalDrive) {
      /* the engine catches; headlights saw the road awake */
      S.finalDrive = true;
      S.shake = 7;
      c.lighted = true;
      TLP.Audio.engine(true, 0.25);
      TLP.Audio.setFire(false, 0);
      TLP.Audio.ui(true);
    }

    for (var s1 = S.sparks.length - 1; s1 >= 0; s1--) {
      var sp = S.sparks[s1];
      sp.l -= dt * 1.25;
      if (sp.l <= 0) { S.sparks.splice(s1, 1); continue; }
      sp.vy += 420 * dt;
      sp.x += sp.vx * dt; sp.y += sp.vy * dt;
    }

    if (S.finalDrive) {
      /* B: the drive. C: whoever is standing in it. */
      var vt = Math.min(340, 40 + (ft - 2.6) * 150);
      TLP.Audio.engine(true, T.clamp((vt - 40) / 390, 0.2, 1));
      var rem = vt * dt;
      while (rem > 0.001 && c.segI < CAR_PATH.length - 1) {
        var tp = CAR_PATH[c.segI + 1];
        var dx = tp[0] - c.x, dy = tp[1] - c.y;
        var dd = Math.hypot(dx, dy);
        if (dd <= rem) { c.x = tp[0]; c.y = tp[1]; c.segI++; rem -= dd; }
        else { c.x += dx / dd * rem; c.y += dy / dd * rem; rem = 0; }
      }
      if (c.segI < CAR_PATH.length - 1)
        c.rot = T.angleLerp(c.rot, Math.atan2(tp[1] - c.y, tp[0] - c.x), 1 - Math.pow(0.0001, dt));
      player.x = c.x; player.y = c.y;
      cam.x = T.smooth(cam.x, c.x + Math.cos(c.rot) * 92, dt, 0.07);
      cam.y = T.smooth(cam.y, c.y + Math.sin(c.rot) * 92 - 14, dt, 0.07);
      if (!S._fig && ft > 5.6) {
        /* three seconds after the roll starts, he is standing in the road */
        S._fig = true;
        S.figX = c.x - 240; S.figY = c.y + 60;
        S.figTarget = 1;
        S.figA = 0.9;               /* no gentle fade-in — he just IS there */
        TLP.Audio.sting();
        TLP.Audio.heartbeat();
      }
      if (S._fig && !S._figPass && c.x < S.figX + 10) { S._figPass = true; TLP.Audio.sting(); }
      if (S._figPass) S.figTarget = 0;
      if (c.segI >= CAR_PATH.length - 1 && !S._gone) {
        S._gone = true;
        TLP.Audio.engine(false, 0);
      }
    } else {
      player.vx = T.smooth(player.vx, 0, dt, 0.3);
      player.vy = T.smooth(player.vy, 0, dt, 0.3);
      var res = collide(player.x + player.vx * dt, player.y + player.vy * dt);
      player.x = res[0]; player.y = res[1];
      player.fa = T.angleLerp(player.fa, Math.atan2(c.y - 6 - player.y, c.x - 8 - player.x), 1 - Math.pow(0.001, dt));
      cam.x = T.smooth(cam.x, player.x, dt, 0.05);
      cam.y = T.smooth(cam.y, player.y, dt, 0.05);
    }
    player.moving = false;
    S.flick = S._fig && !S._figPass ? 1 : 0;
    S.figA = T.smooth(S.figA, S.figTarget, dt, 0.05);
    S.letterbox = T.smooth(S.letterbox, 1, dt, 0.03);
    S.shake = Math.max(0, S.shake - dt * 11);

    if (ft > 6.9) S.darkness = T.smooth(S.darkness, 1, dt, 0.045);
    else S.darkness = T.smooth(S.darkness, S.targetDark, dt, 0.05);

    if (ft > 7.9) { black(true); hide(hud); }
    if (ft > 8.9 && !S._t1) {
      S._t1 = true;
      show(bigtext);
      bigtextInner.textContent = I.t('never_alone');
      bigtextInner.classList.add('warn');
      setTimeout(function () { bigtextInner.classList.add('vis'); }, 150);
    }
    if (ft > 13.9 && S._t1) { bigtextInner.classList.remove('vis'); }
    if (ft > 15.5 && S._t1 && !S._t2) {
      S._t2 = true;
      setTimeout(function () {
        bigtextInner.textContent = I.t('car_drive');
        bigtextInner.classList.remove('warn');
        bigtextInner.classList.add('vis');
      }, 400);
    }
    if (ft > 19.2 && S._t2 && !S._t3) {
      S._t3 = true;
      bigtextInner.classList.remove('vis');
      setTimeout(function () {
        hide(bigtext);
        black(false);
        bigtextInner.classList.remove('warn');
        showScreen($('end-screen'));
        try { localStorage.setItem('tlp_done', '1'); } catch (e) { }
        I.applyDom();
        $('end-credits').classList.remove('vis');
        $('end-thanks').classList.remove('vis');
        setTimeout(function () {
          $('end-credits').classList.add('vis');
          $('end-thanks').classList.add('vis');
        }, 1400);
        setTimeout(function () { endBtns.classList.add('vis'); }, 2600);
        setMode('end');
      }, 1600);
    }
  }

  /* ---------- render ---------- */
  function renderScene(t) {
    var w = world();
    var inside = S.world === 'in';
    var zI = inside ? zoom * 1.22 : zoom;
    ctx.setTransform(DPR, 0, 0, DPR, 0, 0);
    ctx.globalAlpha = 1;
    ctx.globalCompositeOperation = 'source-over';
    ctx.fillStyle = '#07090a';
    ctx.fillRect(0, 0, CW, CH);

    var vw = CW / zI, vh = CH / zI;
    var swayX = (S.mode === 'play' && !inside) ? Math.sin(t * 0.24) * 1.6 : 0;
    var swayY = Math.cos(t * 0.19) * 1.1;
    if (S.shake) { swayX += Math.sin(t * 57) * S.shake; swayY += Math.cos(t * 49) * S.shake * 0.6; }

    ctx.save();
    ctx.translate(CW / 2 + swayX, CH / 2 + swayY);
    ctx.scale(zI, zI);
    ctx.translate(-cam.x, -cam.y);

    /* ground: draw only the visible slice */
    var vx0 = T.clamp(Math.floor(cam.x - vw / 2 - 40), 0, w.W - 8);
    var vy0 = T.clamp(Math.floor(cam.y - vh / 2 - 40), 0, w.H - 8);
    var vw2 = Math.min(Math.ceil(vw + 80), w.W - vx0);
    var vh2 = Math.min(Math.ceil(vh + 80), w.H - vy0);
    ctx.drawImage(w.ground, vx0, vy0, vw2, vh2, vx0, vy0, vw2, vh2);

    /* water ripples over the baked lakes (dark until light reaches them) */
    if (!inside && S.mode !== 'final') {
      ctx.strokeStyle = '#92b2ba';
      ctx.lineWidth = 1;
      for (var rp = 0; rp < RIP.length; rp++) {
        for (var rk = 0; rk < 2; rk++) {
          var pp = (t * 0.07 + rp * 0.31 + rk * 0.5) % 1;
          ctx.globalAlpha = (1 - pp) * 0.07;
          var rw = 5 + pp * 30;
          ctx.beginPath();
          ctx.ellipse(RIP[rp][0], RIP[rp][1], rw, rw * 0.5, 0, 0, T.TAU);
          ctx.stroke();
        }
      }
      ctx.globalAlpha = 1;
    }

    /* y-sorted scene with player + notes + items interleaved */
    var objs = w.objs;
    var ents = [];
    for (var nk = 0; nk < w.notes.length; nk++)
      if (!w.notes[nk].taken && !S.notes[w.notes[nk].idx])
        ents.push({ y: w.notes[nk].y, note: w.notes[nk] });
    for (var ik = 0; ik < w.items.length; ik++)
      if (!w.items[ik].taken)
        ents.push({ y: w.items[ik].y + 46, item: w.items[ik] });
    ents.sort(function (a, b) { return a.y - b.y; });

    var cx0 = cam.x - vw / 2 - 160, cx1 = cam.x + vw / 2 + 160;
    var cy0 = cam.y - vh / 2 - 240, cy1 = cam.y + vh / 2 + 90;
    var drawnPlayer = false;
    var eIdx = 0;
    var py = player.y;
    var hideP = S.finalDrive && !inside;

    for (var i = 0; i < objs.length; i++) {
      var o = objs[i];
      var oy = o.ySort || o.y;
      if (o.gate && S.gates[o.gate]) continue;
      if (!drawnPlayer && oy > py) {
        while (eIdx < ents.length && ents[eIdx].y <= oy) {
          var en = ents[eIdx++];
          if (en.note) T.Assets.note(ctx, en.note, t);
          else T.Assets.item(ctx, en.item, t);
        }
        if (!hideP) T.Assets.player(ctx, player, t);
        drawnPlayer = true;
      }
      if (o.x < cx0 || o.x > cx1 || oy < cy0 || oy > cy1) continue;
      if ((o.k === 'firepit' || o.k === 'hearthIn') && o.fireIdx >= 0) o.lit = w.fires[o.fireIdx].lit;
      var fn = drawMap[o.k];
      if (fn) fn(ctx, o, t);
    }
    if (!drawnPlayer) {
      while (eIdx < ents.length) {
        var en2 = ents[eIdx++];
        if (en2.note) T.Assets.note(ctx, en2.note, t);
        else T.Assets.item(ctx, en2.item, t);
      }
      if (!hideP) T.Assets.player(ctx, player, t);
    }

    /* the figure: first by the sign tree, then, at the end, on the road */
    if (S.figA > 0.01 && !inside) T.Assets.figure(ctx, S._fig ? S.figX : 722, S._fig ? S.figY : 622, S.figA * 0.94);

    /* fog in world space (only outdoors) */
    if (!inside) {
      var fogA = T.clamp((S.darkness - 0.845) * 3, 0.3, 1);
      for (var g = 0; g < 7; g++) {
        var fxx = ((g * 431 + t * (6 + g * 2.3)) % (w.W + 512)) - 256;
        var fyy = (g * 233 + Math.sin(t * 0.04 + g * 2.2) * 80 + t * 2) % w.H;
        ctx.globalAlpha = (0.05 + 0.02 * Math.sin(t * 0.11 + g)) * (1 + fogA);
        ctx.drawImage(T.Assets.fogPuff, fxx, fyy, 560, 260);
      }
      /* the foggy lake earns its name: a local bank of fog hovers over the water */
      for (var lg = 0; lg < 3; lg++) {
        var lfx = 1010 + Math.cos(t * 0.032 + lg * 2.1) * 170;
        var lfy = 252 + Math.sin(t * 0.026 + lg * 2.9) * 95;
        ctx.globalAlpha = 0.09 + 0.035 * Math.sin(t * 0.09 + lg * 1.7);
        ctx.drawImage(T.Assets.fogPuff, lfx - 280, lfy - 130, 560, 260);
      }
      ctx.globalAlpha = 1;
    }
    ctx.restore();

    /* ---------- lighting ---------- */
    lctx.setTransform(DPR, 0, 0, DPR, 0, 0);
    lctx.globalCompositeOperation = 'source-over';
    lctx.globalAlpha = 1;
    lctx.fillStyle = 'rgba(4,6,7,' + S.darkness.toFixed(3) + ')';
    lctx.fillRect(0, 0, CW, CH);
    lctx.globalCompositeOperation = 'destination-out';

    function scr(wx, wy) {
      return [CW / 2 + swayX + (wx - cam.x) * zI, CH / 2 + swayY + (wy - cam.y) * zI];
    }

    /* the lantern in hand: the cone starts right at the glass */
    var lp = T.Assets.playerLanternPos(player);
    var ls = scr(lp.x, lp.y);
    var ps = scr(player.x, player.y);

    var flickN = 1;
    if (S.flick) flickN = 0.3 + 0.7 * Math.abs(Math.sin(t * 17) * Math.sin(t * 5.3) + 0.35);

    if (!hideP) {
      lctx.globalAlpha = flash ? 1 : 0.72;
      var ambR = (flash ? 96 : 52) * zI * (S.flick ? flickN : 1);
      lctx.drawImage(T.Assets.circleSprite, ps[0] - ambR, ps[1] - ambR + 4, ambR * 2, ambR * 2);
    }

    if ((flash || S.flick) && !hideP) {
      var coneLen = 310 * zI * (S.flick ? flickN : 0.9 + 0.06 * Math.sin(t * 3.1));
      lctx.save();
      lctx.translate(ls[0], ls[1]);
      lctx.rotate(player.fa);
      lctx.globalAlpha = 1 * (S.flick ? flickN : 1);
      var cs = coneLen / 320;
      lctx.drawImage(T.Assets.cone.canvas, -320 * cs, -320 * cs, 640 * cs, 640 * cs);
      lctx.restore();
    }

    /* during the escape the headlights are the fire */
    if (S.finalDrive) {
      var cH = WS.out.carObj;
      var chx = Math.cos(cH.rot), chy = Math.sin(cH.rot);
      var hs = scr(cH.x + chx * 46, cH.y + chy * 46);
      lctx.save();
      lctx.translate(hs[0], hs[1]);
      lctx.rotate(cH.rot);
      lctx.globalAlpha = S.flick ? 0.35 + 0.65 * flickN : 0.95;
      var clen = 470 * zI * (0.94 + 0.06 * Math.sin(t * 3.3));
      var csc = clen / 320;
      lctx.drawImage(T.Assets.cone.canvas, -320 * csc, -320 * csc, 640 * csc, 640 * csc);
      lctx.restore();
      var hr = 84 * zI;
      var hc = scr(cH.x, cH.y);
      lctx.globalAlpha = 0.8;
      lctx.drawImage(T.Assets.circleSprite, hc[0] - hr, hc[1] - hr * 0.78, hr * 2, hr * 1.56);
      lctx.globalAlpha = 1;
    }

    for (var fi = 0; fi < w.fires.length; fi++) {
      var fr = w.fires[fi];
      if (!fr.lit) continue;
      var fl = fr.kind === 'fire'
        ? 0.78 + 0.22 * Math.sin(t * 9 + fi * 3.3) * Math.sin(t * 3.7 + fi)
        : 0.9 + 0.1 * Math.sin(t * 5.1 + fi * 2);
      var frr = (fr.kind === 'fire' ? 150 : 108) * zI * fl;
      var fs = scr(fr.x, fr.y);
      lctx.globalAlpha = fr.kind === 'fire' ? 0.95 : 0.8;
      lctx.drawImage(T.Assets.circleSprite, fs[0] - frr, fs[1] - frr * 0.74, frr * 2, frr * 1.48);
    }
    lctx.globalAlpha = 1;

    ctx.setTransform(1, 0, 0, 1, 0, 0);
    ctx.globalAlpha = 1;
    ctx.globalCompositeOperation = 'source-over';
    ctx.drawImage(light, 0, 0);

    /* ---------- warm additive glows ---------- */
    ctx.setTransform(DPR, 0, 0, DPR, 0, 0);
    ctx.globalCompositeOperation = 'lighter';
    if (flash || S.flick) {
      ctx.save();
      ctx.translate(ls[0], ls[1]);
      ctx.rotate(player.fa);
      var bs = (300 * zI) / 320 * (S.flick ? flickN : 1);
      ctx.globalAlpha = 0.62 * (S.flick ? flickN : 1);
      ctx.drawImage(T.Assets.beam.canvas, -320 * bs, -320 * bs, 640 * bs, 640 * bs);
      ctx.restore();
    }
    for (var fj = 0; fj < w.fires.length; fj++) {
      var fr2 = w.fires[fj];
      if (!fr2.lit) continue;
      var fl2 = fr2.kind === 'fire' ? 0.75 + 0.25 * Math.sin(t * 8.3 + fj) : 0.86 + 0.14 * Math.sin(t * 4.3 + fj);
      var ws = scr(fr2.x, fr2.y);
      ctx.globalAlpha = (fr2.kind === 'fire' ? 0.4 : 0.26) * fl2;
      var wr = (fr2.kind === 'fire' ? 140 : 96) * zI;
      ctx.drawImage(T.Assets.warmCircle, ws[0] - wr, ws[1] - wr, wr * 2, wr * 2);
    }

    /* world-space glows: note beacons, lamps, dust, fireflies, the tower blink */
    ctx.save();
    ctx.translate(CW / 2 + swayX, CH / 2 + swayY);
    ctx.scale(zI, zI);
    ctx.translate(-cam.x, -cam.y);

    if (!inside) {
      for (var fk = 0; fk < w.notes.length; fk++) {
        var nt2 = w.notes[fk];
        if (nt2.taken || S.notes[nt2.idx]) continue;
        var pulse = 0.5 + 0.5 * Math.sin(t * 1.7 + fk * 1.3);
        ctx.globalAlpha = 0.05 + 0.05 * pulse;
        var rr2 = 24 + 5 * pulse;
        ctx.drawImage(T.Assets.warmCircle, nt2.x - rr2, nt2.y - rr2, rr2 * 2, rr2 * 2);
      }
      /* car parts pulse the same soft way, so the dark has small suns to walk to */
      for (var pb = 0; pb < w.items.length; pb++) {
        var pbit = w.items[pb];
        if (!pbit.part || pbit.taken) continue;
        var pbp = 0.5 + 0.5 * Math.sin(t * 2.2 + pb * 2.1);
        ctx.globalAlpha = 0.06 + 0.08 * pbp;
        var pbr = 20 + 7 * pbp;
        ctx.drawImage(T.Assets.warmCircle, pbit.x - pbr, pbit.y - pbr, pbr * 2, pbr * 2);
      }
      /* the warm window spills onto the porch grass */
      var wflick = 0.84 + 0.16 * Math.sin(t * 6.3 + 1.2) * Math.sin(t * 2.7);
      ctx.globalAlpha = 0.07 * wflick;
      ctx.drawImage(T.Assets.warmCircle, 738 - 46, 722 - 30, 92, 60);
      ctx.globalAlpha = 0.05 * wflick;
      ctx.drawImage(T.Assets.warmCircle, 804 - 26, 726 - 18, 52, 36);
      /* red beacon of the radio tower blinks over everything */
      var bl = 0.5 + 0.5 * Math.sin(t * 2.4 + 0.4);
      if (bl > 0.72) {
        var ba = (bl - 0.72) / 0.28;
        var bc = w.beacon || { x: 430, y: 221 };
        var bgr = ctx.createRadialGradient(bc.x, bc.y, 1, bc.x, bc.y, 46);
        bgr.addColorStop(0, 'rgba(255,82,58,' + (0.5 * ba).toFixed(2) + ')');
        bgr.addColorStop(1, 'rgba(255,82,58,0)');
        ctx.globalAlpha = 1;
        ctx.fillStyle = bgr;
        ctx.fillRect(bc.x - 46, bc.y - 46, 92, 92);
      }
      /* fireflies */
      for (var ff2 = 0; ff2 < w.fx.length; ff2++) {
        var fy2 = w.fx[ff2];
        var fa2 = T.clamp(0.5 + 0.5 * Math.sin(t * fy2.sp + fy2.ph) - 0.45, 0, 1) * 1.5;
        if (fa2 < 0.02) continue;
        T.Assets.firefly(ctx,
          fy2.x + Math.sin(t * 0.6 + fy2.ph) * 9,
          fy2.y + Math.cos(t * 0.45 + fy2.ph * 1.7) * 6,
          fa2 * 0.8, fy2.r);
      }
    } else {
      /* dust motes in the lantern light */
      ctx.fillStyle = '#d9d4c2';
      for (var dm = 0; dm < w.fx.length; dm++) {
        var dfx = w.fx[dm];
        ctx.globalAlpha = 0.05 + 0.05 * Math.sin(t * dfx.sp + dfx.ph);
        ctx.fillRect(dfx.x + Math.sin(t * dfx.sp + dfx.ph) * 6, dfx.y + Math.cos(t * dfx.sp * 0.7 + dfx.ph) * 5, dfx.r, dfx.r);
      }
    }
    ctx.globalAlpha = 1;

    /* what the hand can reach right now, drawn over the dark */
    if (S.mode === 'play' && S.interactTarget && !S.finalStarted) {
      var itg = S.interactTarget, tx = itg.data.x, ty = itg.data.y, tr = 15, tw = true;
      if (itg.kind === 'examine') {
        tr = T.clamp((itg.data.r || 30) * 0.55, 17, 34);
        tw = itg.act !== 'panel';
      } else if (itg.kind === 'item') ty += 2;
      T.Assets.selRing(ctx, tx, ty, tr, t, tw);
    }

    /* the escape: headlights bleeding warm light into the dark */
    if (S.finalDrive) {
      var cB = WS.out.carObj;
      var bfx = Math.cos(cB.rot), bfy = Math.sin(cB.rot);
      var bgr2 = ctx.createLinearGradient(cB.x, cB.y, cB.x + bfx * 430, cB.y + bfy * 430);
      bgr2.addColorStop(0, 'rgba(244,226,164,' + (S.flick ? 0.16 : 0.32) + ')');
      bgr2.addColorStop(0.75, 'rgba(244,226,164,0.09)');
      bgr2.addColorStop(1, 'rgba(244,226,164,0)');
      ctx.fillStyle = bgr2;
      ctx.beginPath();
      ctx.moveTo(cB.x + bfx * 42 - bfy * 12, cB.y + bfy * 42 + bfx * 12);
      ctx.lineTo(cB.x + bfx * 440 - bfy * 94, cB.y + bfy * 440 + bfx * 94);
      ctx.lineTo(cB.x + bfx * 440 + bfy * 94, cB.y + bfy * 440 - bfx * 94);
      ctx.lineTo(cB.x + bfx * 42 + bfy * 12, cB.y + bfy * 42 - bfx * 12);
      ctx.closePath();
      ctx.fill();
      ctx.fillStyle = 'rgba(255,244,208,0.95)';
      for (var bh = 0; bh < 2; bh++) {
        var sg2 = bh ? 1 : -1;
        ctx.beginPath();
        ctx.arc(cB.x + bfx * 44 + bfy * 9 * sg2, cB.y + bfy * 44 - bfx * 9 * sg2, 2.7, 0, T.TAU);
        ctx.fill();
      }
    }

    /* sparks under the hood during the repair */
    if (S.finalStarted && !S.finalDrive) {
      ctx.fillStyle = '#eab85e';
      for (var sk2 = 0; sk2 < S.sparks.length; sk2++) {
        var spk = S.sparks[sk2];
        ctx.globalAlpha = T.clamp(spk.l, 0, 1) * 0.9;
        ctx.fillRect(spk.x, spk.y, 1.7, 1.7);
      }
      ctx.globalAlpha = 1;
    }

    /* dust caught in the lantern beam */
    if (flash && !inside) {
      var fdx = Math.cos(player.fa), fdy = Math.sin(player.fa);
      var fpx = -fdy, fpy = fdx;
      ctx.fillStyle = '#d8caa0';
      for (var du = 0; du < DUST.length; du++) {
        var mo = DUST[du];
        var dd2 = mo.d * 300;
        var spread = mo.a * (16 + mo.d * 95) + Math.sin(t * mo.sp + mo.ph) * 3;
        var mx2 = lp.x + fdx * dd2 + fpx * spread;
        var my2 = lp.y + fdy * dd2 + fpy * spread;
        ctx.globalAlpha = 0.12 * (1 - Math.abs(mo.a)) * mo.d;
        ctx.fillRect(mx2, my2, 1.15, 1.15);
      }
      ctx.globalAlpha = 1;
    }

    /* the CAR marker, once everything needed is in hand */
    if (allDone() && !inside && (S.mode === 'play' || S.mode === 'note') && !S.finalStarted) {
      var mp = 0.5 + 0.5 * Math.sin(t * 2);
      ctx.globalAlpha = 0.5 + 0.25 * mp;
      ctx.fillStyle = '#A7ACA8';
      ctx.beginPath();
      ctx.moveTo(1152, 946 + mp * 3);
      ctx.lineTo(1145, 934 + mp * 3);
      ctx.lineTo(1159, 934 + mp * 3);
      ctx.closePath();
      ctx.fill();
      ctx.font = '300 11px "Segoe UI", sans-serif';
      ctx.textAlign = 'center';
      ctx.fillText(I.t('lbl_car'), 1152, 927 + mp * 3);
    }
    ctx.restore();

    /* ---------- light rain (outdoors only) ---------- */
    if (!inside) {
      ctx.globalAlpha = 1;
      ctx.globalCompositeOperation = 'source-over';
      ctx.strokeStyle = 'rgba(172,186,182,0.09)';
      ctx.lineWidth = 1;
      ctx.beginPath();
      for (var q = 0; q < S.rain.length; q++) {
        var dr = S.rain[q];
        dr.y += dr.v;
        dr.x -= 0.7;
        if (dr.y > CH + 10) { dr.y = -12; dr.x = Math.random() * (CW + 40); }
        if (dr.x < -12) dr.x = CW + 8;
        ctx.moveTo(dr.x, dr.y);
        ctx.lineTo(dr.x - 1.4, dr.y + dr.l);
      }
      ctx.stroke();
    }

    /* ---------- vignette ---------- */
    var vg = ctx.createRadialGradient(CW / 2, CH / 2, Math.min(CW, CH) * 0.34, CW / 2, CH / 2, Math.max(CW, CH) * 0.74);
    vg.addColorStop(0, 'rgba(0,0,0,0)');
    vg.addColorStop(1, 'rgba(0,0,0,0.5)');
    ctx.fillStyle = vg;
    ctx.fillRect(0, 0, CW, CH);

    /* ---------- letterbox ---------- */
    if (S.letterbox > 0.01) {
      var bh = 48 * S.letterbox;
      ctx.fillStyle = '#000';
      ctx.fillRect(0, 0, CW, bh);
      ctx.fillRect(0, CH - bh, CW, bh);
    }
  }

  /* ---------- rain init ---------- */
  for (var i0 = 0; i0 < 46; i0++) {
    S.rain.push({ x: Math.random() * 2200, y: Math.random() * 1400, v: 4.5 + Math.random() * 3.5, l: 7 + Math.random() * 8 });
  }

  /* ---------- main loop ---------- */
  var last = 0;
  function loop(ts) {
    /* schedule first: even a thrown error cannot freeze the game again */
    requestAnimationFrame(loop);
    try { frame(ts); }
    catch (err) { if (window.console && console.error) console.error('TLP frame error:', err); }
  }
  function frame(ts) {
    var t = ts / 1000;
    var dt = Math.min(0.05, last ? t - last : 0.016);
    last = t;
    S.t = t; S.modeT += dt;

    if (S.mode === 'play') {
      updatePlay(dt);
      if (wantEscape) { wantEscape = false; showScreen($('pause-screen')); setMode('pause'); audioClick(false); }
    } else if (S.mode === 'intro') {
      updateIntro(dt);
    } else if (S.mode === 'final') {
      updateFinal(dt);
    } else if (S.mode === 'pause') {
      if (wantEscape) { wantEscape = false; resumePause(); }
    }
    if (S.mode === 'note' && (wantClose || wantEscape)) closePanel();

    wantClose = false;
    wantInteract = false;
    wantToggleFlash = false;
    wantEscape = false;

    if (S.mode === 'play' || S.mode === 'note' || S.mode === 'pause' || S.mode === 'final') {
      if (S.mode !== 'final') S.darkness = T.smooth(S.darkness, S.targetDark, dt, 0.05);
      renderScene(t);
      updateXhair();
      drawCompass();
    } else if (S.mode === 'intro') {
      renderScene(t);
    } else if (S.mode === 'menu' || S.mode === 'controls' || S.mode === 'credits') {
      S.emx = T.smooth(S.emx, S.mx, dt, 0.05);
      S.emy = T.smooth(S.emy, S.my, dt, 0.05);
      menuBgCtx.setTransform(DPR, 0, 0, DPR, 0, 0);
      T.Assets.menu(menuBgCtx, CW, CH, t, S.emx, S.emy);
    } else if (S.mode === 'end') {
      /* keep last frame under the black end screen */
    }
  }

  /* ---------- UI wiring ---------- */
  $('btn-start').addEventListener('click', function () { audioClick(false); showScreen($('ep-screen')); });
  $('ep-screen').addEventListener('click', function () { audioClick(false); hideScreenAll(); show(menuEl); });
  $('ep-1').addEventListener('click', function (ev) { ev.stopPropagation(); startGame(); });
  var lockedEps = $('ep-screen').querySelectorAll('.ep.lock');
  for (var li = 0; li < lockedEps.length; li++)
    lockedEps[li].addEventListener('click', function (ev) {
      ev.stopPropagation();
      TLP.Audio.ui(false);
      showToast(I.t('ep_locked'), 2800);
    });
  $('btn-controls').addEventListener('click', function () { audioClick(false); showScreen($('controls-screen')); S.screenBack = 'menu'; });
  $('btn-credits').addEventListener('click', function () { audioClick(false); showScreen($('credits-screen')); S.screenBack = 'menu'; });
  $('controls-screen').addEventListener('click', function () {
    audioClick(false);
    hideScreenAll();
    show(S.screenBack === 'pause' ? $('pause-screen') : menuEl);
  });
  $('credits-screen').addEventListener('click', function () {
    audioClick(false);
    hideScreenAll();
    show(menuEl);
  });
  $('note-close').addEventListener('click', function (e) { e.stopPropagation(); if (S.mode === 'note') closePanel(); });
  noteModal.addEventListener('click', function () { if (S.mode === 'note') closePanel(); });

  $('btn-resume').addEventListener('click', resumePause);
  $('btn-pcontrols').addEventListener('click', function () { showScreen($('controls-screen')); S.screenBack = 'pause'; });
  $('btn-restart').addEventListener('click', function () { hideScreenAll(); resetRun(); beginPlay(); });
  $('btn-tomenu').addEventListener('click', gotoMenu);
  $('btn-again').addEventListener('click', function () {
    audioClick(false);
    endBtns.classList.remove('vis');
    hideScreenAll();
    resetRun();
    beginPlay();
  });
  $('btn-endmenu').addEventListener('click', function () {
    audioClick(false);
    endBtns.classList.remove('vis');
    gotoMenu();
  });

  function resumePause() {
    hideScreenAll();
    setMode('play');
  }

  /* ---------- language flags ---------- */
  function bindAim() {
    var ak = $('aim-keys'), am = $('aim-mouse');
    if (ak) ak.addEventListener('click', function (ev) { ev.stopPropagation(); setAimMode('keys'); });
    if (am) am.addEventListener('click', function (ev) { ev.stopPropagation(); setAimMode('mouse'); });
  }
  function bindFlags(scope) {
    var fl = scope.querySelectorAll('.flag');
    for (var i = 0; i < fl.length; i++) {
      fl[i].addEventListener('click', function (ev) {
        ev.stopPropagation();
        var l = this.getAttribute('data-lang');
        if (l !== I.lang) { I.set(l); }
        TLP.Audio.ui(false);
      });
    }
  }
  I.onLang = function () {
    /* every dynamic string goes through here */
    hudTexts();
    refreshObjective();
    if (objective) compassLabel.textContent = objectiveLabelFor(objective);
    if (S.mode === 'intro') { S.introStep = -1; }
    if (S.mode === 'note') refreshPanel();
    if (S.mode === 'play') {
      var tg = nearestInteract();
      S.interactTarget = tg;
      if (tg) promptLabel.textContent = tg.label;
    }
    updateMenuFoot();
  };
  function updateMenuFoot() {
    var foot = $('menu-foot');
    var done = false;
    try { done = !!localStorage.getItem('tlp_done'); } catch (e) { }
    foot.textContent = done ? I.t('menu_done') : I.t('menu_foot');
    foot.classList.toggle('complete', done);
  }

  /* ---------- boot ---------- */
  function boot() {
    resize();
    WS = T.World.buildAll();
    game._ws = WS;
    buildGrid(WS.out);
    buildGrid(WS.int);
    bindFlags(menuEl);
    bindFlags($('pause-screen'));
    bindAim();
    I.load();
    var __am = null; try { __am = localStorage.getItem('tlp_aim'); } catch (e) {}
    if (__am === 'mouse') setAimMode('mouse', true);
    updateMenuFoot();
    requestAnimationFrame(loop);
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
  else boot();
})();
