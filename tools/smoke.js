/* ============================================================
   THE LONE PATH — headless regression harness.
   Boots the real game in jsdom with @napi-rs/canvas pixels, then
   walks the whole story: picker -> play -> 5 notes -> 3 parts ->
   gates -> finale -> end credits, plus i18n, aim modes and the
   device (touch/fullscreen) layer.  Run: node tools/smoke.js [--png]
   ============================================================ */
'use strict';
const fs = require('fs');
const path = require('path');
const { JSDOM } = require('jsdom');
const napi = require('@napi-rs/canvas');

const GAME = path.resolve(__dirname, '..', 'the-lone-path');
const WANT_PNG = process.argv.indexOf('--png') >= 0;
const SHOTS = path.join(__dirname, 'shots');
if (WANT_PNG) fs.mkdirSync(SHOTS, { recursive: true });

/* ---------- browser plumbing: rAF queue, canvas shim ---------- */
let rafQ = [], frameT = 0;

function patchCanvas(el) {
  if (!el.__napi) el.__napi = napi.createCanvas(300, 150);
  return el;
}
const proto = napi.createCanvas(8, 8).getContext('2d');
const CTX = Object.getPrototypeOf(proto);
const origDI = CTX.drawImage;
CTX.drawImage = function (img, ...a) {
  if (img && typeof img === 'object' && img.__napi) img = img.__napi;
  return origDI.call(this, img, ...a);
};

function boot() {
  const html = fs.readFileSync(path.join(GAME, 'index.html'), 'utf8');
  const dom = new JSDOM(html, {
    runScripts: 'outside-only',
    url: 'http://tlp.test/index.html',
    pretendToBeVisual: false,
  });
  const win = dom.window;

  const p = win.HTMLCanvasElement.prototype;
  ['width', 'height'].forEach((k) => {
    Object.defineProperty(p, k, {
      get() { return this.__napi ? this.__napi[k] : (k === 'width' ? 300 : 150); },
      set(v) { patchCanvas(this); this.__napi[k] = Math.max(1, Math.floor(v)); },
      configurable: true,
    });
  });
  p.getContext = function (kind) {
    patchCanvas(this);
    if (kind !== '2d') return null;
    if (!this.__ctxwrap) {
      const g = this.__napi.getContext('2d');
      const el = this;
      this.__ctxwrap = new Proxy(g, {
        get(t, key) {
          const v = t[key];
          if (typeof v === 'function') return v.bind(t);
          if (key === 'canvas') return el;
          return v;
        },
        set(t, key, v) { t[key] = v; return true; },
      });
    }
    return this.__ctxwrap;
  };
  Object.defineProperty(win, 'devicePixelRatio', { value: 1, configurable: true });
  win.requestAnimationFrame = (cb) => { rafQ.push(cb); return rafQ.length; };
  win.cancelAnimationFrame = () => {};
  win.AudioContext = undefined;
  win.webkitAudioContext = undefined;
  return win;
}

(async () => {
  let STEP = 'boot';
  let LAST = Date.now();
  const wd = setInterval(() => {
    if (Date.now() - LAST > 25000) { console.log('WATCHDOG stuck at:', STEP); process.exit(3); }
  }, 2000);
  const mark = (n) => { STEP = n; LAST = Date.now(); };
  const errors = [];
  const win = boot();
  for (const f of ['utils', 'audio', 'i18n', 'assets', 'world', 'game'])
    win.eval(fs.readFileSync(path.join(GAME, 'js', f + '.js'), 'utf8'), { filename: f });

  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  async function frames(n, msBetween = 0, dt = 16.7) {
    for (let i = 0; i < n; i++) {
      frameT += dt;
      const q = rafQ; rafQ = [];
      for (const cb of q) { try { cb(frameT); } catch (e) { errors.push('frame: ' + (e.stack || e)); } }
      if (msBetween) await sleep(msBetween); else await sleep(0);
    }
  }
  /* keep the clock honest between real-time waits (timeouts, intro fades) */
  async function wait(ms, fps = 30) { const n = Math.max(1, Math.round(ms / 1000 * fps)); await frames(n, 1000 / fps); }
  const key = (code, type = 'keydown') => win.dispatchEvent(new win.KeyboardEvent(type, { code, bubbles: true }));
  const click = (id) => win.document.getElementById(id).dispatchEvent(new win.MouseEvent('click', { bubbles: true }));
  const text = (id) => win.document.getElementById(id).textContent;
  const vis = (id) => !win.document.getElementById(id).classList.contains('hidden');
  async function press() { key('KeyE'); await frames(2); key('KeyE', 'keyup'); await frames(2); }
  /* world changes run on real setTimeouts (360 ms + 720 ms unlock) */
  async function pressTravel() {
    await press();
    await sleep(500); await frames(8);
    await sleep(800); await frames(6);
  }
  let png = 0;
  function snap(name) {
    if (!WANT_PNG) return;
    const cv = win.document.getElementById('scene').__napi;
    fs.writeFileSync(path.join(SHOTS, name + '.png'), cv.toBuffer('image/png'));
  }

  const T = win.TLP;
  const I = T.I18N;
  const G = T.game;
  const S = G.S;
  const player = G.player;
  const doc = win.document;
  const toastEl = doc.getElementById('toast');

  /* frame errors: game.js console.error-shields the loop */
  try {
    win.console.error = (...a) => {
      const s0 = a.map((x) => String((x && x.stack) || x)).join(' ');
      if (/frame error/i.test(s0)) errors.push(s0.slice(0, 400));
    };
  } catch (e) {}

  await sleep(400); await frames(8);
  if (S.mode !== 'menu') errors.push('mode after boot: ' + S.mode);

    mark('world');
  /* ---------- world structure ---------- */
  {
    const w = G._ws.out;
    if (w.objs.length < 300) errors.push('world too empty: ' + w.objs.length);
    if (w.notes.length !== 4) errors.push('outdoor notes != 4');
    if (w.items.length !== 3) errors.push('outdoor parts != 3');
    if (T.World.GATES && !T.World.GATES.house) errors.push('house gate not exported');
    const bars = w.colliders.filter((c) => c.gate).length;
    if (bars !== 25) errors.push('gate bars != 25 (got ' + bars + ')');
    for (const g of ['house', 'quarry', 'car', 'radio', 'lake'])
      if (!(w.gateReport[g] && w.gateReport[g].sealed)) errors.push('barrier missing: ' + g);
    if (Object.values(S.gates).some((v) => v)) errors.push('gates not closed at start');
    const want = ['NOTE 01', 'NOTE 03', 'NOTE 02', 'NOTE 04', 'NOTE 05'];
    for (let i2 = 0; i2 < 5; i2++)
      if (I.noteTitle(i2) !== want[i2]) errors.push('note number ' + i2 + ': ' + I.noteTitle(i2));
  }

    mark('picker');
  /* ---------- start: part picker -> device picker ---------- */
  click('btn-start'); await frames(2);
  if (vis('ep-screen') === false) errors.push('part picker did not open');
  if (S.mode !== 'menu') errors.push('picker changed the mode');
  const locks = doc.querySelectorAll('#ep-screen .ep.lock');
  if (locks.length !== 4) errors.push('locked parts != 4');
  locks[1].dispatchEvent(new win.MouseEvent('click', { bubbles: true }));
  await frames(2);
  if (!toastEl.classList.contains('vis')) errors.push('locked part gave no toast');
  if (!vis('ep-screen')) errors.push('locked click closed the picker');
  click('ep-1'); await frames(2);
  if (!vis('dev-screen')) errors.push('device picker did not open');
  if (vis('ep-screen')) errors.push('part picker stays over the device picker (it would block the start)');
  if (S.mode !== 'menu') errors.push('device picker changed the mode');
  doc.getElementById('dev-screen').dispatchEvent(new win.MouseEvent('click', { bubbles: true }));
  await frames(2);
  if (vis('dev-screen')) errors.push('device picker did not close on background');
  if (!vis('ep-screen')) errors.push('back to picker failed');
  click('ep-1'); await frames(2); click('dev-pc');
  await sleep(1000); await frames(4);
  if (vis('dev-screen')) errors.push('dev screen stayed open after choosing the device');
  if (vis('ep-screen')) errors.push('part picker stayed open after the start');
  if (S.mode !== 'intro') errors.push('expected intro, got ' + S.mode);
  key('Enter'); await frames(20); key('Enter', 'keyup'); await frames(4);
  if (S.mode !== 'play') errors.push('expected play after intro');
  snap('start');

    mark('gate refuse');
  /* ---------- gates refuse an unearned hand ---------- */
  const w = G._ws.out;
  player.x = 812; player.y = 786; await frames(2);      /* at the door, note 0 missing */
  await press();
  if (S.world !== 'out') errors.push('door opened without the camp note');
  if (!toastEl.classList.contains('vis')) errors.push('no refusal toast at the door');

    mark('chapter1');
  /* ---------- chapter I: the camp note ---------- */
  player.x = 556; player.y = 995; await frames(2);
  await press();
  if (S.mode !== 'note') errors.push('camp note did not open');
  if (!/01/.test(text('note-title'))) errors.push('camp note title wrong: ' + text('note-title'));
  click('note-close'); await frames(2);
  if (!S.gates.house) errors.push('house gate did not open after note 0');
  snap('after_note1');

    mark('chapter2');
  /* ---------- chapter II: the house, the key, the journal ---------- */
  player.x = 806; player.y = 770; await frames(2);
  await pressTravel();                             /* enter the house */
  if (S.world !== 'in') errors.push('entering the house failed');
  player.x = 600; player.y = 252; await frames(2);/* the iron key on the plank */
  await press();
  if (S.things < 1) errors.push('key not taken: things=' + S.things);
  player.x = 58; player.y = 322; await frames(2);
  await press();                                   /* cabinet: unlocked now */
  await frames(2);
  if (S.mode === 'note' || S.mode === 'play') { click('note-close'); await frames(2); }
  await press();                                   /* the journal inside */
  if (S.mode === 'note') {
    if (!/02/.test(text('note-title'))) errors.push('journal should be NOTE 02: ' + text('note-title'));
    click('note-close'); await frames(2);
  }
  if (S.collected < 2) errors.push('journal not collected (collected=' + S.collected + ')');
  player.x = 330; player.y = 444; await frames(2); /* the table: one of the three things */
  await press(); if (S.mode === 'note') { click('note-close'); await frames(2); }
  player.x = T.World.RW / 2; player.y = T.World.RH - 22; await frames(2);
  await pressTravel();                             /* leave */
  if (S.world !== 'out') errors.push('could not leave the house');
  if (!S.gates.quarry) errors.push('quarry gate not open after the journal');

    mark('chapter3');
  /* ---------- chapter III: the quarry, note 03, the toolbox ---------- */
  player.x = 1120; player.y = 1018; await frames(2);
  await press();
  if (S.mode !== 'note') errors.push('quarry note did not open');
  if (!/03/.test(text('note-title'))) errors.push('quarry note should be NOTE 03');
  click('note-close'); await frames(2);
  player.x = 1348 - 26; player.y = 972 + 8; await frames(2);
  await press();
  if (S.parts !== 1) errors.push('toolbox not taken (parts=' + S.parts + ')');
  if (!S.gates.radio) errors.push('radio gate not open after the quarry note');

    mark('chapter4');
  /* ---------- chapter IV: the tower, note 04, the fuel can ---------- */
  player.x = 446; player.y = 472; await frames(2);
  await press();
  if (S.mode !== 'note') errors.push('radio note did not open');
  if (!/04/.test(text('note-title'))) errors.push('radio note should be NOTE 04');
  click('note-close'); await frames(2);
  player.x = 546 - 24; player.y = 438 + 10; await frames(2);
  await press();
  if (S.parts !== 2) errors.push('fuel can not taken (parts=' + S.parts + ')');
  if (!S.gates.lake) errors.push('lake gate not open after the radio note');

    mark('chapter5');
  /* ---------- chapter V: the lake, note 05, the wheel ---------- */
  player.x = 1002; player.y = 332; await frames(2);
  await press();
  if (S.mode !== 'note') errors.push('lake note did not open');
  if (!/05/.test(text('note-title'))) errors.push('lake note should be NOTE 05');
  click('note-close'); await frames(2);
  if (S.collected !== 5) errors.push('notes collected != 5 (' + S.collected + ')');
  player.x = 1236 - 26; player.y = 392 + 10; await frames(2);
  await press();
  if (S.parts !== 3) errors.push('spare wheel not taken (parts=' + S.parts + ')');
  snap('lake');

    mark('barriers');
  /* ---------- the car is already reachable: all gates fell ---------- */
  {
    const blocked = w.colliders.filter((c) => c.gate && !S.gates[c.gate]).length;
    if (blocked !== 0) errors.push('barriers still sealed after the story: ' + blocked);
  }

    mark('aim');
  /* ---------- aim modes (mouse) ---------- */
  {
    const xh = doc.getElementById('xhair');
    if (xh.classList.contains('hidden')) errors.push('reticle hidden during play');
    key('KeyA'); await frames(22); key('KeyA', 'keyup'); await frames(12);
    const dAng = Math.abs(((player.fa - Math.PI + 3 * Math.PI) % (2 * Math.PI)) - Math.PI);
    if (dAng > 0.6) errors.push('keys aim did not follow movement');
    click('btn-controls'); await frames(2);
    doc.getElementById('aim-mouse').dispatchEvent(new win.MouseEvent('click', { bubbles: true }));
    await frames(2);
    if (S.aimMode !== 'mouse') errors.push('aim row click did not switch');
    if (!vis('controls-screen')) errors.push('aim row click closed the controls screen');
    if (win.localStorage.getItem('tlp_aim') !== 'mouse') errors.push('aim mode not persisted');
    click('controls-screen'); await frames(2);
    win.dispatchEvent(new win.MouseEvent('mousemove', { clientX: 900, clientY: 120 }));
    await frames(26);
    if (!(Math.cos(player.fa) > 0 && Math.sin(player.fa) < 0)) errors.push('mouse aim did not track the cursor');
    const lx = parseFloat(xh.style.left), ly = parseFloat(xh.style.top);
    if (Math.abs(lx - 900) > 3 || Math.abs(ly - 120) > 3) errors.push('reticle off the cursor: ' + lx + ',' + ly);
    T.game.setAimMode('keys');
  }

    mark('device');
  /* ---------- device layer: fullscreen, phone controls ---------- */
  {
    const html = doc.documentElement;
    if (S.inputKind !== 'pc') errors.push('device should be pc');
    if (html.classList.contains('touch')) errors.push('touch class on pc');
    click('btn-fs'); await frames(2);
    if (!toastEl.classList.contains('vis')) errors.push('unsupported fullscreen should toast');
    key('Escape'); await frames(2); key('Escape', 'keyup'); await frames(3, 1);
    if (S.mode !== 'pause') errors.push('esc pause failed');
    click('btn-device'); await frames(2);
    if (!vis('dev-screen')) errors.push('device screen not shown from pause');
    click('dev-phone'); await frames(3, 1);
    if (S.mode !== 'play') errors.push('phone pick did not resume, got ' + S.mode);
    if (!html.classList.contains('touch')) errors.push('touch class missing');
    if (win.localStorage.getItem('tlp_dev') !== 'phone') errors.push('device not persisted');
    if (doc.getElementById('touch-ui').style.visibility !== 'visible') errors.push('touch ui hidden during phone play');
    /* phone fit: the viewport adapts, the whole zone stays visible */
    const W0 = win.innerWidth, H0 = win.innerHeight;
    const setVP = (w, h) => {
      Object.defineProperty(win, 'innerWidth', { value: w, configurable: true });
      Object.defineProperty(win, 'innerHeight', { value: h, configurable: true });
      win.dispatchEvent(new win.Event('resize'));
    };
    setVP(844, 390); await frames(2);
    let zfit = G.zoom;
    if (!(zfit > 0.58 && zfit < 0.68)) errors.push('landscape phone zoom should fit ~0.63, got ' + zfit);
    if (!doc.getElementById('rot-hint').classList.contains('hidden')) errors.push('rot hint shown in landscape');
    setVP(390, 844); await frames(2);
    zfit = G.zoom;
    if (!(zfit > 0.36 && zfit < 0.44)) errors.push('portrait phone zoom should open up the view ~0.40, got ' + zfit);
    if (doc.getElementById('rot-hint').classList.contains('hidden')) errors.push('rot hint missing in portrait');
    setVP(W0, H0); await frames(2);
    /* the stick walks */
    player.x = 700; player.y = 1050; await frames(2);
    T.touch.active = true; T.touch.x = -1; T.touch.y = 0;
    const x0 = player.x;
    await frames(30);
    T.touch.active = false; T.touch.x = 0; T.touch.y = 0;
    if (!(player.x < x0 - 20)) errors.push('stick did not walk (' + Math.round(x0) + '->' + Math.round(player.x) + ')');
    /* E button interacts */
    player.x = 505; player.y = 940; await frames(2);
    doc.getElementById('tbtn-e').dispatchEvent(new win.Event('pointerdown', { bubbles: true }));
    await frames(3);
    if (S.mode !== 'note') errors.push('touch E did not interact, mode ' + S.mode);
    click('note-close'); await frames(2);
    /* F button toggles the light */
    const f0 = G.flash;
    doc.getElementById('tbtn-f').dispatchEvent(new win.Event('pointerdown', { bubbles: true }));
    await frames(3);
    if (G.flash !== !f0) errors.push('touch F did not toggle the light');
    /* a tap on the world turns the head */
    player.fa = 0;
    const ev = new win.Event('pointerdown', { bubbles: true });
    ev.clientX = 200; ev.clientY = 700;
    doc.getElementById('scene').dispatchEvent(ev);
    await frames(22);
    if (!(Math.cos(player.fa) < 0 && Math.sin(player.fa) > 0)) errors.push('tap-to-look failed: ' + player.fa.toFixed(2));
    /* the pause roundtrip */
    doc.getElementById('tbtn-pause').dispatchEvent(new win.Event('pointerdown', { bubbles: true }));
    await frames(3);
    if (S.mode !== 'pause') errors.push('touch pause failed');
    click('btn-resume'); await frames(2);
    if (S.mode !== 'play') errors.push('resume after touch pause failed');
    /* back to pc */
    key('Escape'); await frames(2); key('Escape', 'keyup'); await frames(3, 1);
    click('btn-device'); await frames(2); click('dev-pc'); await frames(3, 1);
    if (S.inputKind !== 'pc' || html.classList.contains('touch')) errors.push('device did not switch back to pc');
    if (S.mode !== 'play') errors.push('pc switch did not resume');
  }

    mark('lang');
  /* ---------- the language flag rewires everything ---------- */
  {
    click('btn-tomenu'); await frames(4, 2);
    const ru = doc.querySelector('#menu .flag[data-lang="ru"]');
    ru.dispatchEvent(new win.MouseEvent('click', { bubbles: true }));
    await frames(4, 2);
    if (I.lang !== 'ru') errors.push('lang not ru');
    if (text('btn-start') !== 'НАЧАТЬ') errors.push('menu not localized');
    if (I.ex('cabinet_locked') === undefined && I.t('gate_open') === 'gate_open') errors.push('missing ru keys');
    const ep = I.t('ep_pick'); if (typeof ep !== 'string' || !ep.length) errors.push('ep_pick missing in ru');
    const dev = I.t('dev_phone'); if (!/ТЕЛЕФОН/.test(dev)) errors.push('dev_phone missing in ru');
    doc.querySelector('#menu .flag[data-lang="en"]').dispatchEvent(new win.MouseEvent('click', { bubbles: true }));
    await frames(3, 2);
    if (text('btn-start') !== 'START') errors.push('switch back to en failed');
    if (I.noteTitle(1) !== 'NOTE 03') errors.push('note numbers broke after relanguage');
  }

    mark('finale');
  /* ---------- the finale: repair, figure at 3 s, drive, credits ---------- */
  {
    click('btn-start'); await frames(2);
    click('ep-1'); await frames(2); click('dev-pc'); await sleep(900); await frames(4);
    key('Enter'); await frames(13); key('Enter', 'keyup'); await frames(4);
    if (S.mode !== 'play') errors.push('second run did not start');
    /* notes+parts persist? no: resetRun wipes — fast-forward the story state */
    S.notes = [true, true, true, true, true]; S.collected = 5;
    S.parts = 3; S.partsMask = 7; S.itemsMask = 7; S.things = 3;
    for (const g in S.gates) S.gates[g] = true;
    player.x = 1114; player.y = 968; await frames(3);
    await press();
    if (S.mode !== 'final') errors.push('car E did not start the finale, mode ' + S.mode);
    let guard = 0;
    while (guard++ < 300 && !S._fig && S.mode === 'final') await frames(10, 0, 50);
    if (!S._fig) errors.push('the figure never appeared');
    if (S.figX !== 828 || S.figY !== 814) errors.push('the figure is not by the house: ' + S.figX + ',' + S.figY);
    if (S.figA < 0.4) errors.push('the figure is invisible: figA=' + S.figA.toFixed(2));
    snap('figure');
    guard = 0;
    while (guard++ < 300 && S.mode === 'final' && !S._figPass) await frames(10, 0, 50);
    if (!S._figPass) errors.push('the car never passed the house');
    guard = 0;
    while (guard++ < 320 && S.mode === 'final' && !S._roll) await frames(10, 0, 50);
    if (!S._roll) errors.push('the credits roll never started, mode ' + S.mode);
    await sleep(700); await frames(3);
    if (S.mode !== 'roll') errors.push('mode during the roll: ' + S.mode);
    if (!vis('roll-screen')) errors.push('roll screen not shown');
    const rollTxt = doc.querySelector('#roll-screen .roll-in').textContent;
    if (!/MARLEN/i.test(rollTxt)) errors.push('creator missing from the roll');
    if (!doc.querySelector('.roll-in').classList.contains('run')) errors.push('the roll is not scrolling');
    snap('roll');
    doc.getElementById('roll-screen').dispatchEvent(new win.MouseEvent('click', { bubbles: true }));
    await sleep(300); await frames(3);
    if (S.mode !== 'end') errors.push('skipping the roll did not reach the end: ' + S.mode);
    if (!vis('end-screen')) errors.push('end screen missing');
    if (vis('roll-screen')) errors.push('the roll stayed open');
    if (!win.localStorage.getItem('tlp_done')) errors.push('tlp_done not stored');
    await sleep(1100); await frames(2);
    if (!doc.getElementById('end-btns').classList.contains('vis')) errors.push('end buttons never showed');
    snap('end');
  }

  clearInterval(wd);
  if (errors.length) {
    console.log('\n===== ' + errors.length + ' ERROR(S) =====');
    errors.forEach((e) => console.log('- ' + String(e).slice(0, 500)));
    process.exit(1);
  }
  clearInterval(wd);
  console.log('\nALL SMOKE TESTS PASSED (v5: picker, device, touch, finale)');
  process.exit(0);
})().catch((e) => { console.error('harness crash', e); process.exit(2); });

