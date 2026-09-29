/* ============================================================
   THE LONE PATH — game core
   Components: GameState · Movement · Camera · Lighting
   Interaction · Notes · UI · Audio glue
   ============================================================ */
'use strict';
(function () {
  var T = window.TLP;
  var game = {};
  T.game = game;

  /* ---------- DOM ---------- */
  var $ = function (id) { return document.getElementById(id); };
  var scene = $('scene'), ctx = scene.getContext('2d');
  var hud = $('hud'), notesCount = $('notes-count'), prompt = $('prompt'), promptLabel = $('prompt-label');
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

  /* ---------- world ---------- */
  var world = null;
  var grid = {}, CELL = 96;
  function buildGrid() {
    grid = {};
    for (var i = 0; i < world.colliders.length; i++) {
      var c = world.colliders[i];
      var x0, x1, y0, y1;
      if (c.rect) { x0 = c.rect.x - 16; x1 = c.rect.x + c.rect.w + 16; y0 = c.rect.y - 16; y1 = c.rect.y + c.rect.h + 16; }
      else { x0 = c.x - c.r - 16; x1 = c.x + c.r + 16; y0 = c.y - c.r - 16; y1 = c.y + c.r + 16; }
      for (var gx = Math.floor(x0 / CELL); gx <= Math.floor(x1 / CELL); gx++)
        for (var gy = Math.floor(y0 / CELL); gy <= Math.floor(y1 / CELL); gy++)
          (grid[gx + ':' + gy] || (grid[gx + ':' + gy] = [])).push(c);
    }
  }
  var drawMap = {
    pine: T.Assets.pine, fir: T.Assets.fir, small: T.Assets.small, dry: T.Assets.dry,
    stump: T.Assets.stump, rock: T.Assets.rock, fallen: T.Assets.fallen, bush: T.Assets.bush,
    crate: T.Assets.crate, barrel: T.Assets.barrel, logpile: T.Assets.logpile, table: T.Assets.table,
    planks: T.Assets.planks, tent: T.Assets.tent, firepit: T.Assets.firepit, cabin: T.Assets.cabin,
    car: T.Assets.car, sign: T.Assets.sign, bigtree: T.Assets.bigtree, signtree: T.Assets.signtree,
    cross: T.Assets.cross, fence: T.Assets.fence
  };

  /* ---------- state ---------- */
  var S = {
    mode: 'menu',           /* menu | controls | credits | intro | play | note | pause | final | end */
    t: 0, modeT: 0,
    darkness: 0.87,
    targetDark: 0.87,
    collected: 0,
    finalStarted: false, finalT: -1, _t1: false, _t2: false, _t3: false,
    figA: 0, figTarget: 0,
    flick: 0,
    mx: 0, my: 0, emx: 0, emy: 0,
    rain: [],
    promptHide: -1,
    interactTarget: null,
    hints: null,
    introStep: -1,
    letterbox: 0
  };
  game.S = S;

  var player = { x: 800, y: 1195, vx: 0, vy: 0, fa: -Math.PI / 2, walk: 0, moving: false };
  var cam = { x: 800, y: 1195 };
  var flash = false;
  game.flash = false;
  game.player = player; /* handy for debugging / automated tests */
  game.cam = cam;

  /* ---------- input ---------- */
  var keys = {};
  var wantInteract = false, wantClose = false, wantToggleFlash = false, skipIntro = false;

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
  var wantEscape = false;
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
    [menuEl, $('controls-screen'), $('credits-screen'), $('pause-screen'), $('end-screen')].forEach(hide);
  }
  function showScreen(el) { show(el); }

  function gotoMenu() {
    hideScreenAll();
    show(menuEl);
    hide(hud); hide(prompt); hide(bigtext); hide(toast);
    TLP.Audio.quiet(true);
    setMode('menu');
    black(false);
    S.promptHide = -1;
    try {
      if (localStorage.getItem('tlp_done')) {
        $('menu-foot').textContent = 'THE PATH REMEMBERS YOU.';
        $('menu-foot').classList.add('complete');
      }
    } catch (e) { }
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

  var introLines = [
    'I don\u2019t remember coming here.',
    'But I remember the forest.',
    'Find out what happened.'
  ];
  function updateIntro(dt) {
    if (skipIntro) { beginPlay(); return; }
    var step = Math.floor(S.modeT / 3.1);
    if (step !== S.introStep && step < 3) {
      S.introStep = step;
      bigtextInner.textContent = introLines[step];
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
    updateNotesHud();
    $('prompt').classList.remove('vis');
    S.hints = [
      { t: 1.8, text: 'F \u2014 FLASHLIGHT', dur: 2300 },
      { t: 4.8, text: 'WASD / \u2190\u2191\u2193\u2192 \u2014 MOVE', dur: 2300 },
      { t: 8.2, text: 'OBJECTIVE \u00B7 FIND FIVE NOTES', dur: 3200 }
    ];
  }

  function resetRun() {
    player.x = 800; player.y = 1195; player.vx = 0; player.vy = 0;
    player.fa = -Math.PI / 2; player.walk = 0; player.moving = false;
    cam.x = player.x; cam.y = player.y;
    flash = false; game.flash = false;
    S.collected = 0;
    S.finalStarted = false; S.finalT = -1;
    S.figA = 0; S.figTarget = 0; S.flick = 0;
    S._t1 = S._t2 = S._t3 = false;
    S.letterbox = 0;
    S.darkness = 0.87; S.targetDark = 0.87;
    world.notes.forEach(function (n) { n.taken = false; });
    world.fires.forEach(function (f) { f.lit = false; });
    TLP.Audio.setFire(false, 0);
    updateNotesHud();
    compassLabel.textContent = '';
    objective = null;
  }

  /* ---------- objective / compass ---------- */
  var objective = null;
  function findObjective() {
    if (S.collected >= 5) { objective = { x: 800, y: 700, label: 'CABIN' }; return; }
    var best = null, bd = 1e18;
    for (var i = 0; i < world.notes.length; i++) {
      var n = world.notes[i];
      if (n.taken) continue;
      var d = T.dist2(player.x, player.y, n.x, n.y);
      if (d < bd) { bd = d; best = n; }
    }
    objective = best ? { x: best.x, y: best.y, label: 'NOTE 0' + (best.idx + 1) } : null;
  }

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
    /* distance ring: full circle close, tiny arc far */
    var d = Math.sqrt(T.dist2(player.x, player.y, objective.x, objective.y));
    var fr = T.clamp(1 - d / 760, 0.08, 1);
    c.strokeStyle = 'rgba(215,208,183,0.5)';
    c.lineWidth = 1.6;
    c.beginPath(); c.arc(cx, cy, r + 3, -Math.PI / 2, -Math.PI / 2 + fr * T.TAU); c.stroke();
  }

  /* ---------- movement + collision ---------- */
  function collide(x, y) {
    var pr = 8;
    var gx = Math.floor(x / CELL), gy = Math.floor(y / CELL);
    for (var ix = gx - 1; ix <= gx + 1; ix++) {
      for (var iy = gy - 1; iy <= gy + 1; iy++) {
        var arr = grid[ix + ':' + iy];
        if (!arr) continue;
        for (var i = 0; i < arr.length; i++) {
          var c = arr[i];
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
    var d = 0.855;
    var z = T.World.ZONES;
    var dd = Math.sqrt(T.dist2(x, y, z.deep.x, z.deep.y));
    if (dd < 520) d += 0.035 * (1 - dd / 520);
    var df = Math.sqrt(T.dist2(x, y, 1050, 260));
    if (df < 300) d += 0.025 * (1 - df / 300);
    var ds = Math.sqrt(T.dist2(x, y, z.start.x, z.start.y));
    if (ds < 260) d -= 0.015 * (1 - ds / 260);
    return T.clamp(d, 0.8, 0.93);
  }

  /* ---------- interaction ---------- */
  function nearestInteract() {
    var best = null, bd = 1e9, bType = null;
    for (var i = 0; i < world.notes.length; i++) {
      var n = world.notes[i];
      if (n.taken) continue;
      var d = Math.sqrt(T.dist2(player.x, player.y, n.x, n.y));
      if (d < 44 && d < bd) { bd = d; best = n; bType = 'note'; }
    }
    for (var j = 0; j < world.examines.length; j++) {
      var e = world.examines[j];
      var dd = Math.sqrt(T.dist2(player.x, player.y, e.x, e.y));
      if (dd < e.r && dd < bd) { bd = dd; best = e; bType = 'examine'; }
    }
    return best ? { kind: bType, data: best } : null;
  }

  function openPanel(title, lines) {
    noteTitle.textContent = title;
    noteBody.innerHTML = lines.join('<br>');
    prompt.classList.remove('vis');
    hide(prompt);
    S.promptHide = -1;
    show(noteModal);
    setMode('note');
  }
  function closePanel() {
    hide(noteModal);
    setMode('play');
    if (S.collected >= 5 && !S.finalStarted) {
      showToast('OBJECTIVE \u00B7 RETURN TO THE CABIN', 3600);
      compassLabel.textContent = 'CABIN';
    }
  }
  function takeNote(n) {
    n.taken = true;
    S.collected++;
    updateNotesHud();
    TLP.Audio.noteGet();
  }
  function updateNotesHud() {
    notesCount.innerHTML = S.collected + '&nbsp;/&nbsp;5';
    notesCount.classList.remove('pop');
    void notesCount.offsetWidth;
    notesCount.classList.add('pop');
  }

  /* ---------- update: play ---------- */
  function updatePlay(dt) {
    var ax = 0, ay = 0;
    if (keys['KeyW'] || keys['ArrowUp']) ay -= 1;
    if (keys['KeyS'] || keys['ArrowDown']) ay += 1;
    if (keys['KeyA'] || keys['ArrowLeft']) ax -= 1;
    if (keys['KeyD'] || keys['ArrowRight']) ax += 1;
    var len = Math.hypot(ax, ay);
    if (len > 0) { ax /= len; ay /= len; }
    var speed = 150;
    player.vx = T.smooth(player.vx, ax * speed, dt, 0.22);
    player.vy = T.smooth(player.vy, ay * speed, dt, 0.22);
    player.x += player.vx * dt;
    player.y += player.vy * dt;
    var res = collide(player.x, player.y);
    player.x = T.clamp(res[0], 26, world.W - 26);
    player.y = T.clamp(res[1], 26, world.H - 26);
    player.moving = len > 0 && Math.hypot(player.vx, player.vy) > 12;
    if (player.moving) {
      player.walk = (player.walk + dt * 2.6) % 1;
      player.fa = T.angleLerp(player.fa, Math.atan2(ay, ax), 1 - Math.pow(0.000001, dt));
    }

    if (wantToggleFlash) {
      flash = !flash;
      game.flash = flash;
      audioClick(false);
    }

    if (wantInteract && S.interactTarget) {
      var tg = S.interactTarget;
      if (tg.kind === 'note') { takeNote(tg.data); openPanel(tg.data.title, tg.data.lines); }
      else { openPanel(tg.data.title, tg.data.text); audioClick(false); }
    }

    var near = nearestInteract();
    S.interactTarget = near;
    if (near) {
      promptLabel.textContent = near.kind === 'note' ? 'READ' : (near.data.label || 'EXAMINE');
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
      showToast(h.text, h.dur);
    }

    cam.x = T.smooth(cam.x, player.x, dt, 0.10);
    cam.y = T.smooth(cam.y, player.y, dt, 0.10);

    findObjective();
    if (objective && S.collected < 5) compassLabel.textContent = objective.label;

    S.targetDark = darknessAt(player.x, player.y);

    var nearFire = 0;
    for (var f = 0; f < world.fires.length; f++) {
      var ff = world.fires[f];
      if (!ff.lit) continue;
      var fd = Math.sqrt(T.dist2(player.x, player.y, ff.x, ff.y));
      nearFire = Math.max(nearFire, T.clamp(1 - fd / 260, 0, 1));
    }
    TLP.Audio.setFire(nearFire > 0.01, nearFire);

    if (S.collected >= 5 && !S.finalStarted) {
      if (T.dist2(player.x, player.y, 800, 716) < 100 * 100) startFinal();
    }
  }

  /* ---------- final sequence ---------- */
  function startFinal() {
    S.finalStarted = true;
    S.finalT = 0;
    setMode('final');
    prompt.classList.remove('vis');
    hide(prompt);
    hide(toast);
    compassLabel.textContent = '';
    TLP.Audio.swell();
    TLP.Audio.setFire(true, 0.55);
  }
  function updateFinal(dt) {
    S.finalT += dt;
    var ft = S.finalT;
    S.targetDark = T.clamp(0.945 + ft * 0.02, 0.945, 0.99);
    if (ft > 1.2) { world.fires[1].lit = true; world.fires[0].lit = true; }
    if (ft > 2.2) S.figTarget = 1;
    S.figA = T.smooth(S.figA, S.figTarget, dt, 0.06);
    S.flick = ft > 4.4 && ft < 7.4 ? 1 : 0;
    player.vx = T.smooth(player.vx, 0, dt, 0.3);
    player.vy = T.smooth(player.vy, 0, dt, 0.3);
    var res = collide(player.x + player.vx * dt, player.y + player.vy * dt);
    player.x = res[0]; player.y = res[1];
    player.moving = false;
    cam.x = T.smooth(cam.x, player.x, dt, 0.05);
    cam.y = T.smooth(cam.y, player.y, dt, 0.05);
    S.letterbox = T.smooth(S.letterbox, 1, dt, 0.03);

    if (ft > 6.2) S.darkness = T.smooth(S.darkness, 1, dt, 0.045);
    else S.darkness = T.smooth(S.darkness, S.targetDark, dt, 0.05);

    if (ft > 7.3) { black(true); hide(hud); }
    if (ft > 8.1 && !S._t1) {
      S._t1 = true;
      TLP.Audio.sting();
      TLP.Audio.heartbeat();
      show(bigtext);
      bigtextInner.textContent = 'YOU WERE NEVER ALONE.';
      bigtextInner.classList.add('warn');
      setTimeout(function () { bigtextInner.classList.add('vis'); }, 150);
    }
    if (ft > 13.4 && S._t1) { bigtextInner.classList.remove('vis'); }
    if (ft > 14.9 && S._t1 && !S._t2) {
      S._t2 = true;
      setTimeout(function () {
        bigtextInner.textContent = 'THE END';
        bigtextInner.classList.add('vis');
      }, 400);
    }
    if (ft > 18.6 && S._t2 && !S._t3) {
      S._t3 = true;
      bigtextInner.classList.remove('vis');
      setTimeout(function () {
        hide(bigtext);
        black(false);
        showScreen($('end-screen'));
        try { localStorage.setItem('tlp_done', '1'); } catch (e) { }
        setTimeout(function () { endBtns.classList.add('vis'); }, 2200);
        setMode('end');
      }, 1600);
    }
  }

  /* ---------- render ---------- */
  function renderScene(t) {
    ctx.setTransform(DPR, 0, 0, DPR, 0, 0);
    ctx.globalAlpha = 1;
    ctx.globalCompositeOperation = 'source-over';
    ctx.fillStyle = '#07090a';
    ctx.fillRect(0, 0, CW, CH);

    var vw = CW / zoom, vh = CH / zoom;
    var swayX = S.mode === 'play' ? Math.sin(t * 0.24) * 1.6 : 0;
    var swayY = Math.cos(t * 0.19) * 1.1;

    ctx.save();
    ctx.translate(CW / 2 + swayX, CH / 2 + swayY);
    ctx.scale(zoom, zoom);
    ctx.translate(-cam.x, -cam.y);

    /* ground: draw only the visible slice */
    var vx0 = T.clamp(Math.floor(cam.x - vw / 2 - 40), 0, world.W - 8);
    var vy0 = T.clamp(Math.floor(cam.y - vh / 2 - 40), 0, world.H - 8);
    var vw2 = Math.min(Math.ceil(vw + 80), world.W - vx0);
    var vh2 = Math.min(Math.ceil(vh + 80), world.H - vy0);
    ctx.drawImage(world.ground, vx0, vy0, vw2, vh2, vx0, vy0, vw2, vh2);

    /* y-sorted scene with player + notes interleaved */
    var objs = world.objs;
    var noteList = world.notes;
    var cx0 = cam.x - vw / 2 - 160, cx1 = cam.x + vw / 2 + 160;
    var cy0 = cam.y - vh / 2 - 240, cy1 = cam.y + vh / 2 + 90;
    var drawnPlayer = false;
    var notesLeft = [];
    for (var nk = 0; nk < noteList.length; nk++) if (!noteList[nk].taken) notesLeft.push(noteList[nk]);
    notesLeft.sort(function (a, b) { return a.y - b.y; });
    var nIdx = 0;
    var py = player.y;

    for (var i = 0; i < objs.length; i++) {
      var o = objs[i];
      var oy = o.ySort || o.y;
      if (!drawnPlayer && oy > py) {
        while (nIdx < notesLeft.length && notesLeft[nIdx].y <= oy) { T.Assets.note(ctx, notesLeft[nIdx], t); nIdx++; }
        T.Assets.player(ctx, player, t);
        drawnPlayer = true;
      }
      if (o.x < cx0 || o.x > cx1 || oy < cy0 || oy > cy1) continue;
      if (o.k === 'firepit' && o.fireIdx != null) o.lit = world.fires[o.fireIdx].lit;
      var fn = drawMap[o.k];
      if (fn) fn(ctx, o, t);
    }
    if (!drawnPlayer) {
      while (nIdx < notesLeft.length) { T.Assets.note(ctx, notesLeft[nIdx], t); nIdx++; }
      T.Assets.player(ctx, player, t);
    }

    /* the figure, near the sign tree */
    if (S.figA > 0.01) T.Assets.figure(ctx, 722, 622, S.figA * 0.94);

    /* fog in world space (goes under darkness so it glows only near light) */
    var fogA = T.clamp((S.darkness - 0.86) * 3, 0.35, 1);
    for (var g = 0; g < 7; g++) {
      var fxx = ((g * 431 + t * (6 + g * 2.3)) % (world.W + 512)) - 256;
      var fyy = (g * 233 + Math.sin(t * 0.04 + g * 2.2) * 80 + t * 2) % world.H;
      ctx.globalAlpha = (0.05 + 0.02 * Math.sin(t * 0.11 + g)) * (1 + fogA);
      ctx.drawImage(T.Assets.fogPuff, fxx, fyy, 560, 260);
    }
    ctx.globalAlpha = 1;
    ctx.restore();

    /* ---------- lighting ---------- */
    lctx.setTransform(DPR, 0, 0, DPR, 0, 0);
    lctx.globalCompositeOperation = 'source-over';
    lctx.globalAlpha = 1;
    lctx.fillStyle = 'rgba(4,6,7,' + S.darkness.toFixed(3) + ')';
    lctx.fillRect(0, 0, CW, CH);
    lctx.globalCompositeOperation = 'destination-out';

    var psx = CW / 2 + swayX + (player.x - cam.x) * zoom;
    var psy = CH / 2 + swayY + (player.y - cam.y) * zoom;

    var flickN = 1;
    if (S.flick) flickN = 0.3 + 0.7 * Math.abs(Math.sin(t * 17) * Math.sin(t * 5.3) + 0.35);

    lctx.globalAlpha = flash ? 1 : 0.72;
    var ambR = (flash ? 88 : 52) * zoom * (S.flick ? flickN : 1);
    lctx.drawImage(T.Assets.circleSprite, psx - ambR, psy - ambR + 4, ambR * 2, ambR * 2);

    if (flash || S.flick) {
      var coneLen = 310 * zoom * (S.flick ? flickN : 0.9 + 0.06 * Math.sin(t * 3.1));
      lctx.save();
      lctx.translate(psx, psy - 8 * zoom);
      lctx.rotate(player.fa);
      lctx.globalAlpha = 1 * (S.flick ? flickN : 1);
      var cs = coneLen / 320;
      lctx.drawImage(T.Assets.cone.canvas, 0, -320 * cs, 320 * cs, 640 * cs);
      lctx.restore();
    }

    for (var fi = 0; fi < world.fires.length; fi++) {
      var fr = world.fires[fi];
      if (!fr.lit) continue;
      var fl = 0.78 + 0.22 * Math.sin(t * 9 + fi * 3.3) * Math.sin(t * 3.7 + fi);
      var fsx = CW / 2 + swayX + (fr.x - cam.x) * zoom;
      var fsy = CH / 2 + swayY + (fr.y - cam.y) * zoom;
      var frr = 150 * zoom * fl;
      lctx.globalAlpha = 0.95;
      lctx.drawImage(T.Assets.circleSprite, fsx - frr, fsy - frr * 0.74, frr * 2, frr * 1.48);
    }
    lctx.globalAlpha = 1;

    ctx.setTransform(1, 0, 0, 1, 0, 0);
    ctx.globalAlpha = 1;
    ctx.globalCompositeOperation = 'source-over';
    ctx.drawImage(light, 0, 0);

    /* ---------- warm addititive glows ---------- */
    ctx.setTransform(DPR, 0, 0, DPR, 0, 0);
    ctx.globalCompositeOperation = 'lighter';
    if (flash || S.flick) {
      ctx.save();
      ctx.translate(psx, psy - 8 * zoom);
      ctx.rotate(player.fa);
      var bs = (300 * zoom) / 320 * (S.flick ? flickN : 1);
      ctx.globalAlpha = 0.62 * (S.flick ? flickN : 1);
      ctx.drawImage(T.Assets.beam.canvas, 0, -320 * bs, 320 * bs, 640 * bs);
      ctx.restore();
    }
    for (var fj = 0; fj < world.fires.length; fj++) {
      var fr2 = world.fires[fj];
      if (!fr2.lit) continue;
      var fl2 = 0.75 + 0.25 * Math.sin(t * 8.3 + fj);
      var wx = CW / 2 + swayX + (fr2.x - cam.x) * zoom;
      var wy = CH / 2 + swayY + (fr2.y - cam.y) * zoom;
      ctx.globalAlpha = 0.4 * fl2;
      var wr = 140 * zoom;
      ctx.drawImage(T.Assets.warmCircle, wx - wr, wy - wr, wr * 2, wr * 2);
    }
    /* note beacons — a faint pulse so nothing stays lost forever */
    ctx.save();
    ctx.translate(CW / 2 + swayX, CH / 2 + swayY);
    ctx.scale(zoom, zoom);
    ctx.translate(-cam.x, -cam.y);
    for (var fk = 0; fk < noteList.length; fk++) {
      var nt = noteList[fk];
      if (nt.taken) continue;
      var pulse = 0.5 + 0.5 * Math.sin(t * 1.7 + fk * 1.3);
      ctx.globalAlpha = 0.05 + 0.05 * pulse;
      var rr2 = 24 + 5 * pulse;
      ctx.drawImage(T.Assets.warmCircle, nt.x - rr2, nt.y - rr2, rr2 * 2, rr2 * 2);
    }
    /* CABIN marker after all notes */
    if (S.collected >= 5 && (S.mode === 'play' || S.mode === 'note')) {
      var mp = 0.5 + 0.5 * Math.sin(t * 2);
      ctx.globalAlpha = 0.5 + 0.25 * mp;
      ctx.fillStyle = '#A7ACA8';
      ctx.beginPath();
      ctx.moveTo(800, 616 + mp * 3);
      ctx.lineTo(793, 604 + mp * 3);
      ctx.lineTo(807, 604 + mp * 3);
      ctx.closePath();
      ctx.fill();
      ctx.font = '300 11px "Segoe UI", sans-serif';
      ctx.textAlign = 'center';
      ctx.fillText('CABIN', 800, 597 + mp * 3);
    }
    ctx.restore();

    /* ---------- light rain ---------- */
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
  for (var i = 0; i < 46; i++) {
    S.rain.push({ x: Math.random() * 2200, y: Math.random() * 1400, v: 4.5 + Math.random() * 3.5, l: 7 + Math.random() * 8 });
  }

  /* ---------- main loop ---------- */
  var last = 0;
  function loop(ts) {
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
    requestAnimationFrame(loop);
  }

  /* ---------- UI wiring ---------- */
  $('btn-start').addEventListener('click', startGame);
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

  /* ---------- boot ---------- */
  function boot() {
    resize();
    world = T.World.build();
    buildGrid();
    game.world = world;
    game._light = light; /* debug hook */
    requestAnimationFrame(loop);
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
  else boot();
})();
