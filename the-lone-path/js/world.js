/* ============================================================
   THE LONE PATH — world v3
   One engine, two hand-made areas, five places of interest:
   · OUTDOOR 1600x1600 — camp, house, quarry, radio tower, foggy lake
   · INTERIOR of the house — search for 3 things, unlock the cabinet
   All texts resolve through i18n keys at runtime.
   ============================================================ */
'use strict';
(function () {
  var T = window.TLP;

  var W = 1600, H = 1600;
  var GATES_OUT = null;

  /* chapters: I camp, II house+interior, III quarry, IV radio tower, V foggy lake */
  var CHAPTER_NOTE = [0, 2, 1, 3, 4];

  /* notes: idx 0 camp, 1 quarry, 2 INSIDE (journal in the cabinet), 3 radio, 4 lake */
  var NOTES = [
    { x: 556, y: 995, chapter: 0 },
    { x: 1120, y: 1018, chapter: 2 },
    { x: 52, y: 292, chapter: 1, interior: true, hidden: true },   /* lives in the cabinet */
    { x: 446, y: 472, chapter: 3 },
    { x: 1002, y: 332, chapter: 4 }
  ];

  var EXAMINES = [
    { x: 505, y: 937, r: 40, ikey: 'campfire', label: 'examine' },
    { x: 866, y: 808, r: 40, ikey: 'smallfire', label: 'examine' },
    { x: 452, y: 908, r: 44, ikey: 'tent', label: 'examine' },
    { x: 736, y: 590, r: 40, ikey: 'symbol', label: 'read' },
    { x: 706, y: 1046, r: 38, ikey: 'sign', label: 'read' },
    { x: 1114, y: 952, r: 46, ikey: 'car', label: 'examine', special: 'car' },
    { x: 1215, y: 978, r: 52, ikey: 'quarry', label: 'examine' },
    { x: 1284, y: 868, r: 46, ikey: 'crane', label: 'examine' },
    { x: 430, y: 425, r: 46, ikey: 'tower', label: 'examine' },
    { x: 492, y: 498, r: 42, ikey: 'hut', label: 'examine' },
    { x: 990, y: 335, r: 48, ikey: 'pier', label: 'examine' },
    { x: 1152, y: 262, r: 44, ikey: 'lake', label: 'examine' },
    { x: 1150, y: 330, r: 46, ikey: 'oldtree', label: 'examine' }
  ];

  var ZONES = {
    start: { x: 800, y: 1180, r: 150 },
    camp: { x: 520, y: 950, r: 140 },
    cabin: { x: 800, y: 700, r: 170 },
    quarry: { x: 1150, y: 940, r: 175 },
    radio: { x: 430, y: 430, r: 240 },
    lake: { x: 1010, y: 290, r: 230 }
  };

  /* dark standing water; also baked into the ground and rippled at runtime */
  var WATERS = [
    { x: 990, y: 225, rx: 158, ry: 108, kind: 'lake' },
    { x: 1215, y: 915, rx: 112, ry: 78, kind: 'quarry' }
  ];
  /* the pier of the lake, baked into the ground; player can walk on it */
  var PIER = { x0: 1095, y0: 390, x1: 990, y1: 330, w: 24 };

  var PATHS = [
    [[800, 1180], [720, 1075], [640, 1010], [556, 995], [505, 950]],          /* start -> camp */
    [[505, 950], [600, 880], [700, 815], [790, 770], [800, 745]],             /* camp  -> house */
    [[800, 745], [812, 640], [822, 540], [862, 452], [922, 382], [992, 334]], /* house -> pier */
    [[800, 745], [880, 810], [960, 870], [1040, 930], [1104, 988], [1122, 1012]], /* house -> quarry */
    [[1122, 1012], [980, 1090], [870, 1140], [800, 1180]],                    /* quarry -> start */
    [[505, 950], [432, 862], [398, 722], [404, 572], [432, 468]],             /* camp  -> radio */
    [[448, 456], [540, 540], [660, 600], [760, 660]]                          /* radio -> house road */
  ];

  function distToPaths(x, y) {
    var best = 1e9;
    for (var p = 0; p < PATHS.length; p++) {
      var pl = PATHS[p];
      for (var i = 0; i < pl.length - 1; i++) {
        var ax = pl[i][0], ay = pl[i][1], bx = pl[i + 1][0], by = pl[i + 1][1];
        var dx = bx - ax, dy = by - ay;
        var t = T.clamp(((x - ax) * dx + (y - ay) * dy) / (dx * dx + dy * dy || 1), 0, 1);
        var px2 = ax + dx * t - x, py2 = ay + dy * t - y;
        var d2 = px2 * px2 + py2 * py2;
        if (d2 < best) best = d2;
      }
    }
    return Math.sqrt(best);
  }

  function inEllipse(x, y, e, pad) {
    var dx = (x - e.x) / (e.rx + (pad || 0)), dy = (y - e.y) / (e.ry + (pad || 0));
    return dx * dx + dy * dy < 1;
  }

  function densityAt(x, y) {
    var d = 0.06;
    function add(z, v) {
      var dd = T.dist2(x, y, z.x, z.y);
      if (dd < z.r * z.r) d += v * (1 - Math.sqrt(dd) / z.r);
    }
    add({ x: 750, y: 250, r: 380 }, 0.5);      /* far north woods */
    add({ x: 1350, y: 420, r: 320 }, 0.5);
    add({ x: 260, y: 1240, r: 420 }, 0.55);
    add({ x: 1340, y: 1320, r: 420 }, 0.5);
    add({ x: 100, y: 300, r: 380 }, 0.5);
    add({ x: 1560, y: 700, r: 260 }, 0.4);
    add({ x: 940, y: 620, r: 200 }, 0.3);
    /* darker woods narrow the open meadows into valleys between places */
    add({ x: 985, y: 690, r: 190 }, 0.92);
    add({ x: 700, y: 630, r: 150 }, 0.88);
    add({ x: 300, y: 620, r: 170 }, 0.88);
    add({ x: 566, y: 546, r: 150 }, 0.88);
    add({ x: 812, y: 236, r: 170 }, 0.92);
    add({ x: 1250, y: 610, r: 210 }, 0.88);
    add({ x: 620, y: 1180, r: 150 }, 0.85);
    add({ x: 1096, y: 1190, r: 140 }, 0.8);
    add({ x: 214, y: 940, r: 150 }, 0.85);
    var edge = Math.min(x, y, W - x, W - y);
    if (edge < 170) d += 0.95 * (1 - edge / 170);
    /* open ground around every place of interest */
    for (var k in ZONES) {
      var z = ZONES[k];
      var dd = Math.sqrt(T.dist2(x, y, z.x, z.y));
      if (dd < z.r * 1.25) d *= Math.min(1, dd / (z.r * 1.25));
    }
    /* nothing grows in standing water */
    if (inEllipse(x, y, WATERS[0], 26) || inEllipse(x, y, WATERS[1], 22)) d = 0;
    if (distToPaths(x, y) < 46) d = Math.min(d, 0.10);
    return T.clamp(d, 0.04, 1);
  }

  function mk(k, x, y, s, extra) {
    var o = { k: k, x: x, y: y, s: s || 1 };
    if (extra) for (var p in extra) o[p] = extra[p];
    return o;
  }

  /* ============================================================
     OUTDOOR
     ============================================================ */
  function buildOutdoor() {
    var world = {
      id: 'out', W: W, H: H,
      objs: [], colliders: [], notes: [], examines: [],
      items: [], water: WATERS,
      fires: [
        { x: 505, y: 937, lit: false, kind: 'fire' },
        { x: 866, y: 808, lit: false, kind: 'fire' },
        { x: 742, y: 708, lit: true, kind: 'lamp' },   /* the house window keeps burning */
        { x: 992, y: 328, lit: true, kind: 'lamp' }   /* pier lamp, lit this evening */
      ],
      beacon: { x: 430, y: 221 },                        /* red tower light */
      ground: null, fx: [], dark: null
    };
    function solidR(x, y, r) { world.colliders.push({ x: x, y: y, r: r }); }
    function solidRect(x, y, w, h) { world.colliders.push({ x: x, y: y, r: 0, rect: { x: x - w / 2, y: y - h / 2, w: w, h: h } }); }
    /* deep water: round solid patches so the player cannot cross the dark middle */
    function waterBars(cx, cy, bars) {
      for (var i = 0; i < bars.length; i++) solidR(cx + bars[i][0], cy + bars[i][1], bars[i][2]);
    }
    waterBars(0, 0, [[925, 205, 50], [995, 190, 56], [1065, 205, 46], [952, 258, 44], [1028, 252, 40]]);
    waterBars(0, 0, [[1180, 895, 40], [1250, 890, 42], [1215, 945, 46], [1155, 930, 26]]);

    /* -- the house -- */
    var cabinObj = mk('cabin', 800, 726, 1, { warm: true });
    cabinObj.ySort = 726;
    world.objs.push(cabinObj);
    solidRect(800, 700, 200, 50);
    solidRect(800, 664, 216, 44);

    /* door: interactable that lets you ENTER (game.js switches the world) */
    world.examines.push({ x: 800, y: 748, r: 46, ikey: 'door_out', label: 'enter', special: 'enter', yLock: 748 });

    world.objs.push(mk('crate', 668, 762, 1), mk('crate', 694, 778, 0.9));
    solidR(668, 762, 12); solidR(694, 778, 11);
    world.objs.push(mk('barrel', 936, 742, 1), mk('barrel', 954, 716, 0.95));
    solidR(936, 742, 11);
    world.objs.push(mk('logpile', 652, 700, 1));
    world.objs.push(mk('table', 868, 786, 1), mk('planks', 918, 782, 1, { rot: 0.5 }));
    world.objs.push(mk('planks', 892, 800, 0.8, { rot: -0.3 }));
    world.objs.push(mk('stump', 856, 742, 1));
    solidR(856, 742, 8);
    world.objs.push(mk('signtree', 736, 590, 1.15));
    solidR(736, 590, 9);
    world.objs.push(mk('firepit', 866, 808, 1, { fireIdx: 1 }));

    /* -- camp -- */
    world.objs.push(mk('firepit', 505, 937, 1.1, { fireIdx: 0 }));
    world.objs.push(mk('tent', 452, 908, 1));
    solidRect(452, 890, 58, 30);
    world.objs.push(mk('fallen', 560, 972, 0.8, { rot: 0.4 }));
    solidR(560, 972, 12);
    world.objs.push(mk('logpile', 574, 918, 0.85));
    world.objs.push(mk('crate', 588, 946, 0.85));
    solidR(588, 946, 11);
    world.objs.push(mk('stump', 462, 986, 0.9), mk('rock', 540, 1008, 0.8));
    world.objs.push(mk('dry', 610, 900, 1));
    solidR(610, 900, 8);

    /* -- the quarry: water pit, the car on the rim, a crane bent over the edge -- */
    var car = mk('car', 1152, 982, 1, { rot: -0.45 });
    car.ySort = 1000;
    world.objs.push(car);
    world.carObj = car;
    solidR(1152, 982, 34);
    var crane = mk('crane', 1292, 836, 1);
    crane.ySort = 842;
    world.objs.push(crane);
    solidR(1292, 840, 14);
    world.objs.push(mk('crate', 1354, 880, 1), mk('barrel', 1336, 946, 0.9));
    solidR(1354, 880, 11);
    world.objs.push(mk('rock', 1082, 1032, 1.1), mk('rock', 1300, 1016, 1.3));
    solidR(1300, 1016, 13);
    world.objs.push(mk('bush', 1092, 940, 1), mk('bush', 1330, 958, 1.2));
    world.objs.push(mk('fallen', 1240, 1052, 0.9, { rot: 1.2 }));
    solidR(1240, 1052, 14);
    world.objs.push(mk('planks', 1104, 990, 0.7, { rot: 1.1 }));
    /* warning fences on the west rim, clear of the water */
    world.objs.push(mk('fence', 1104, 864, 0.9, { rot: -0.9 }), mk('fence', 1072, 892, 0.8, { rot: -0.9 }));

    /* -- start clearing -- */
    world.objs.push(mk('rock', 842, 1206, 1), mk('rock', 764, 1216, 0.75));
    solidR(842, 1206, 10);
    world.objs.push(mk('dry', 858, 1142, 0.9), mk('stump', 742, 1150, 0.8));
    solidR(858, 1142, 8);
    world.objs.push(mk('sign', 706, 1046, 1, { dir: -0.9 }));
    world.objs.push(mk('bush', 770, 1230, 0.9), mk('bush', 856, 1188, 1.05));

    /* -- radio tower clearing (former deep forest): mast, hut, old camp leftovers -- */
    var tower = mk('tower', 430, 395, 1, { ph: 0.4 });
    tower.ySort = 400;
    world.objs.push(tower);
    solidR(430, 398, 12);
    var hut = mk('hut', 492, 470, 1);
    hut.ySort = 474;
    world.objs.push(hut);
    solidRect(492, 470, 60, 36);
    world.objs.push(mk('crate', 534, 500, 0.9), mk('barrel', 456, 508, 0.8));
    solidR(534, 500, 10);
    world.objs.push(mk('rock', 508, 428, 1.7), mk('rock', 372, 528, 1.2));
    solidR(508, 428, 17); solidR(372, 528, 13);
    world.objs.push(mk('fence', 398, 566, 1, { rot: 0.2 }), mk('fence', 486, 542, 0.85, { rot: -1.15 }));
    world.objs.push(mk('dry', 470, 418, 1.15), mk('stump', 404, 452, 1.4));
    solidR(470, 418, 8); solidR(404, 452, 10);
    world.objs.push(mk('fallen', 520, 486, 1, { rot: -0.5 }));
    solidR(520, 486, 15);
    world.objs.push(mk('sign', 560, 630, 1, { dir: 0.5 }));
    /* little altar of stones, kept from the old camp days */
    world.objs.push(mk('rock', 462, 522, 0.8), mk('cross', 462, 522, 0.7));

    /* -- foggy lake shore: pier, lamp, the old tree, a cross -- */
    world.objs.push(mk('bigtree', 1150, 330, 1.15));
    solidR(1150, 330, 17);
    world.objs.push(mk('cross', 1192, 352, 1));
    world.objs.push(mk('rock', 1186, 296, 1.2), mk('stump', 1216, 372, 1.1));
    solidR(1186, 296, 12);
    world.objs.push(mk('dry', 1200, 408, 1.05));
    solidR(1200, 408, 7);
    world.objs.push(mk('fence', 1230, 318, 0.8, { rot: 1.35 }));
    var lamp = mk('lamp', 992, 328, 1);
    lamp.ySort = 330;
    world.objs.push(lamp);
    solidR(992, 328, 6);

    /* -- scattered forest -- */
    var r = T.rng(1337);
    var types = [['pine', 0.34, 12], ['fir', 0.56, 10], ['small', 0.72, 7], ['dry', 0.85, 6], ['stump', 1.0, 7]];
    var placed = [];
    function tooClose(x, y, d2) {
      var n = d2 * d2;
      for (var i = 0; i < placed.length; i++)
        if (T.dist2(x, y, placed[i][0], placed[i][1]) < n) return true;
      for (var j = 0; j < world.objs.length; j++) {
        var o = world.objs[j];
        if (T.dist2(x, y, o.x, o.y) < 4600) return true;
      }
      for (var k = 0; k < NOTES.length; k++) {
        if (NOTES[k].interior) continue;
        if (T.dist2(x, y, NOTES[k].x, NOTES[k].y) < 3200) return true;
      }
      return false;
    }
    var tries = 0;
    while (placed.length < 430 && tries < 14000) {
      tries++;
      var x = 50 + r() * (W - 100), y = 50 + r() * (H - 100);
      if (densityAt(x, y) <= 0.041) continue;             /* open ground and water stay clear */
      if (r() > densityAt(x, y)) continue;
      if (tooClose(x, y, 44)) continue;
      var tr = r();
      var kind = 'pine', trunk = 12;
      for (var ti = 0; ti < types.length; ti++)
        if (tr <= types[ti][1]) { kind = types[ti][0]; trunk = types[ti][2]; break; }
      var s = 0.75 + r() * 0.62 + (kind === 'pine' ? r() * 0.2 : 0);
      var o = mk(kind, x, y, s);
      /* in the deep thickets trunks grow wide: those woods become a wall */
      if (trunk > 0) solidR(x, y, trunk * s * (densityAt(x, y) > 0.5 ? 1.3 : 0.62));
      world.objs.push(o);
      placed.push([x, y]);
      if (r() < 0.18) {
        var bx = x + (r() - 0.5) * 70, by = y + 18 + r() * 26;
        if (distToPaths(bx, by) > 34 && densityAt(bx, by) > 0.12)
          world.objs.push(mk(r() < 0.5 ? 'bush' : (r() < 0.7 ? 'rock' : 'stump'), bx, by, 0.6 + r() * 0.5, { comp: 1 }));
      }
    }
    for (var i2 = 0; i2 < 130; i2++) {
      var bx2 = 40 + r() * (W - 80), by2 = 40 + r() * (H - 80);
      if (distToPaths(bx2, by2) < 26) continue;
      world.objs.push(mk('bush', bx2, by2, 0.55 + r() * 0.7, { comp: 1 }));
    }

    /* -- note objects (view refs; the taken state lives in game's master S.notes) -- */
    for (var n = 0; n < NOTES.length; n++) {
      if (NOTES[n].interior) continue;   /* the journal lives in the cabinet */
      world.notes.push({
        x: NOTES[n].x, y: NOTES[n].y, idx: n, taken: false, rot: (r() - 0.5) * 0.7
      });
    }
    /* -- atmospheric examines -- */
    for (var e = 0; e < EXAMINES.length; e++) world.examines.push(EXAMINES[e]);

    /* -- three car parts: what the chapters trade a note for -- */
    world.items.push(
      { id: 0, kind: 'tools', x: 1348, y: 972, r: 14, part: true, label: 'item_tools' },
      { id: 1, kind: 'fuel', x: 546, y: 438, r: 14, part: true, label: 'item_fuel' },
      { id: 2, kind: 'wheel', x: 1236, y: 392, r: 15, part: true, label: 'item_wheel' }
    );

    /* -- fallen trees across the trails: they mark the chapters that are not
       yours yet. The strict lock lives in game.js (notes and parts refuse an
       unearned hand), so a wandering shortcut never breaks the story order. -- */
    function gateWall(gate, cx, cy, crossAng) {
      var ux = Math.cos(crossAng), uy = Math.sin(crossAng);
      for (var i = -2; i <= 2; i++) {
        var bx = cx + ux * i * 37, by = cy + uy * i * 37;
        world.colliders.push({ x: bx, y: by, r: 15, kind: 'log', gate: gate });
        world.objs.push({ k: 'bush', x: bx, y: by + 4, s: 1.5 + ((i + 2) * 7 % 3) * 0.16, comp: 1, gate: gate });
        if (i % 2 === 0)
          world.objs.push({ k: 'fence', x: bx, y: by - 2, s: 1.05, rot: crossAng, gate: gate });
        if (i === 0)
          world.objs.push({ k: 'fallen', x: cx - uy * 14, y: cy + ux * 14 - 2, s: 1.0, rot: crossAng + 1.9, gate: gate });
      }
      return { sealed: true, bars: 5 };
    }
    world.gateReport = {
      house: gateWall('house', 690, 858, 0.776),
      quarry: gateWall('quarry', 960, 870, 2.214),
      /* the east road to the car belongs to the quarry chapter as well */
      car: gateWall('quarry', 1010, 988, 1.571),
      radio: gateWall('radio', 401, 648, 0.0398),
      lake: gateWall('lake', 957, 358, 0.9696)
    };

    /* pines along the escape route: the last drive runs through woods, not void */
    var DRIVE = [[1010, 1000], [880, 920], [792, 846], [640, 900], [470, 1010], [260, 1110], [-60, 1180]];
    var dr = T.rng(4242);
    for (var di = 0; di < DRIVE.length - 1; di++) {
      var pa = DRIVE[di], pb = DRIVE[di + 1];
      var segL = Math.hypot(pb[0] - pa[0], pb[1] - pa[1]);
      var nxx = -(pb[1] - pa[1]) / segL, nyy = (pb[0] - pa[0]) / segL;
      for (var ki = 0; ki < 3; ki++) {
        var tt = (ki + 0.5) / 3;
        var qx = pa[0] + (pb[0] - pa[0]) * tt, qy = pa[1] + (pb[1] - pa[1]) * tt;
        for (var side = -1; side <= 1; side += 2) {
          var off = 118 + dr() * 150;
          var tx = qx + nxx * off * side, ty = qy + nyy * off * side;
          if (tx < 34 || tx > W - 34 || ty < 34 || ty > H - 34) continue;
          if (Math.hypot(tx - 556, ty - 995) < 210) continue;      /* the camp keeps its clearing */
          if (Math.hypot(tx - 800, ty - 762) < 185) continue;       /* the house front is his stage */
          if (ty < 1010 && tx > 930) continue;                      /* keep the quarry wall free */
          if (Math.hypot(tx - 1152, ty - 982) < 95) continue;       /* the car sits in its own clearing */
          var ts = 1.05 + dr() * 0.55;
          world.objs.push(mk(dr() < 0.55 ? 'pine' : 'fir', tx, ty, ts));
          world.colliders.push({ x: tx, y: ty, r: 9 * ts });
        }
      }
    }
    GATES_OUT = {
      house: { x: 800, y: 774 },
      quarry: { x: 960, y: 870 },
      radio: { x: 401, y: 648 },
      lake: { x: 957, y: 358 }
    };

    world.objs.sort(function (a, b) { return (a.ySort || a.y) - (b.ySort || b.y); });
    world.ground = bakeOutdoor(r);

    /* fireflies: near the camp, the radio clearing, the lake, the house, the quarry rim */
    var fr = T.rng(777);
    var spots = [[505, 950, 130], [430, 440, 180], [1010, 330, 150], [800, 720, 110], [1140, 990, 110]];
    for (var ff = 0; ff < 26; ff++) {
      var sp = spots[ff % spots.length];
      world.fx.push({
        x: sp[0] + (fr() - 0.5) * sp[2] * 2,
        y: sp[1] + (fr() - 0.5) * sp[2] * 1.4,
        r: 3.4 + fr() * 3, ph: fr() * T.TAU, sp: 0.5 + fr() * 0.9
      });
    }
    return world;
  }

  /* ---------- the baked ground: tone, paths, water, pier, details ---------- */
  function bakeOutdoor(r) {
    var c = T.canvas(W, H);
    var g = c.getContext('2d');
    g.fillStyle = '#18241d';
    g.fillRect(0, 0, W, H);

    /* large tonal blotches */
    var cols = ['#203026', '#15211a', '#26382c', '#1a2a21', '#2c4133', '#131e18'];
    for (var i = 0; i < 320; i++) {
      var x = r() * W, y = r() * H, rad = 40 + r() * 170;
      var grd = g.createRadialGradient(x, y, rad * 0.12, x, y, rad);
      grd.addColorStop(0, cols[Math.floor(r() * cols.length)]);
      grd.addColorStop(1, 'rgba(0,0,0,0)');
      g.globalAlpha = 0.45 + r() * 0.55;
      g.fillStyle = grd;
      g.beginPath();
      g.ellipse(x, y, rad, rad * (0.5 + r() * 0.5), r() * 3, 0, T.TAU);
      g.fill();
    }
    /* moss clusters */
    for (var m = 0; m < 140; m++) {
      var mx = r() * W, my = r() * H;
      g.globalAlpha = 0.2 + r() * 0.25;
      g.fillStyle = r() < 0.5 ? '#31543a' : '#27452e';
      for (var mb = 0; mb < 4; mb++) {
        g.beginPath();
        g.ellipse(mx + (r() - 0.5) * 26, my + (r() - 0.5) * 16, 6 + r() * 14, 4 + r() * 8, r() * 3, 0, T.TAU);
        g.fill();
      }
    }
    g.globalAlpha = 1;

    /* paths with worn edges */
    for (var p = 0; p < PATHS.length; p++) {
      var pl = PATHS[p];
      for (var s2 = 0; s2 < pl.length - 1; s2++) {
        var ax = pl[s2][0], ay = pl[s2][1], bx = pl[s2 + 1][0], by = pl[s2 + 1][1];
        var len = Math.hypot(bx - ax, by - ay);
        var steps = Math.ceil(len / 8);
        for (var k = 0; k <= steps; k++) {
          var t2 = k / steps;
          var px = ax + (bx - ax) * t2 + (r() - 0.5) * 9;
          var py = ay + (by - ay) * t2 + (r() - 0.5) * 9;
          var pr = 11 + r() * 12;
          var gr2 = g.createRadialGradient(px, py, 1, px, py, pr);
          gr2.addColorStop(0, 'rgba(64,60,44,0.55)');
          gr2.addColorStop(0.7, 'rgba(52,49,38,0.3)');
          gr2.addColorStop(1, 'rgba(0,0,0,0)');
          g.fillStyle = gr2;
          g.beginPath();
          g.ellipse(px, py, pr, pr * 0.62, r() * 3, 0, T.TAU);
          g.fill();
          /* pebbles on the edges */
          if (r() < 0.3) {
            g.fillStyle = 'rgba(128,134,124,' + (0.2 + r() * 0.25).toFixed(2) + ')';
            var pa = r() * T.TAU;
            g.beginPath();
            g.ellipse(px + Math.cos(pa) * pr, py + Math.sin(pa) * pr * 0.7, 1.4 + r() * 1.8, 1 + r(), pa, 0, T.TAU);
            g.fill();
          }
        }
      }
    }

    /* ---- standing water: the lake and the quarry pit ---- */
    for (var wi = 0; wi < WATERS.length; wi++) {
      var wt = WATERS[wi];
      /* drowned shoreline — tight, so the shore never looks like open water */
      var ring = g.createRadialGradient(wt.x, wt.y, Math.min(wt.rx, wt.ry) * 0.6, wt.x, wt.y, wt.rx + 18);
      ring.addColorStop(0, 'rgba(0,0,0,0)');
      ring.addColorStop(0.86, wt.kind === 'lake' ? 'rgba(12,18,17,0.6)' : 'rgba(17,15,12,0.55)');
      ring.addColorStop(1, 'rgba(0,0,0,0)');
      g.fillStyle = ring;
      g.beginPath(); g.ellipse(wt.x, wt.y, wt.rx + 18, wt.ry + 15, 0, 0, T.TAU); g.fill();
      /* the water body */
      var wg = g.createRadialGradient(wt.x - wt.rx * 0.25, wt.y - wt.ry * 0.35, 8, wt.x, wt.y, Math.max(wt.rx, wt.ry));
      wg.addColorStop(0, wt.kind === 'lake' ? '#111d22' : '#131619');
      wg.addColorStop(0.55, '#0a1116');
      wg.addColorStop(1, '#05090c');
      g.fillStyle = wg;
      g.beginPath(); g.ellipse(wt.x, wt.y, wt.rx, wt.ry, 0, 0, T.TAU); g.fill();
      /* crisp dark edge + a cold glint on the far bank */
      g.strokeStyle = 'rgba(5,9,11,0.9)';
      g.lineWidth = 2.4;
      g.beginPath(); g.ellipse(wt.x, wt.y, wt.rx, wt.ry, 0, 0, T.TAU); g.stroke();
      g.strokeStyle = 'rgba(130,162,166,0.06)';
      g.lineWidth = 1.2;
      g.beginPath(); g.ellipse(wt.x, wt.y, wt.rx - 3, wt.ry - 3, 0, Math.PI * 1.08, Math.PI * 1.92); g.stroke();
      /* faint still sheen, a couple of long strokes */
      g.strokeStyle = 'rgba(140,170,175,0.055)';
      g.lineWidth = 1.4;
      for (var sh = 0; sh < 10; sh++) {
        var sy0 = wt.y - wt.ry * 0.7 + sh * wt.ry * 0.16;
        var half = wt.rx * Math.sqrt(Math.max(0, 1 - Math.pow((sy0 - wt.y) / wt.ry, 2))) * (0.35 + r() * 0.4);
        var sx0 = wt.x - half * (0.2 + r() * 0.6);
        g.beginPath();
        g.moveTo(sx0, sy0);
        g.lineTo(sx0 + half * (1 + r()), sy0 + (r() - 0.5) * 2);
        g.stroke();
      }
      /* stones and reeds on the near shore */
      for (var re = 0; re < (wt.kind === 'lake' ? 90 : 44); re++) {
        var ang = r() * T.TAU;
        var rr3 = 1.0 + r() * 0.12;
        var rx3 = wt.x + Math.cos(ang) * wt.rx * rr3, ry3 = wt.y + Math.sin(ang) * wt.ry * rr3;
        if (wt.kind === 'lake' && rx3 > 950 && ry3 > 290 && r() < 0.7) continue; /* keep the pier mouth clean */
        g.strokeStyle = 'rgba(66,90,64,' + (0.25 + r() * 0.3).toFixed(2) + ')';
        g.lineWidth = 0.9;
        for (var st = 0; st < 3; st++) {
          var shx = rx3 + (r() - 0.5) * 5, hh = 5 + r() * 8;
          g.beginPath();
          g.moveTo(shx, ry3);
          g.quadraticCurveTo(shx + (r() - 0.5) * 4, ry3 - hh * 0.6, shx + (r() - 0.5) * 7, ry3 - hh);
          g.stroke();
        }
        if (r() < 0.3) {
          g.fillStyle = 'rgba(120,116,104,0.3)';
          g.beginPath(); g.ellipse(rx3 + 4, ry3 + 2, 2.2 + r() * 2, 1.4 + r(), r() * 3, 0, T.TAU); g.fill();
        }
      }
    }

    /* ---- the pier: hand-nailed planks from shore to the lamp ---- */
    (function () {
      var dx = PIER.x1 - PIER.x0, dy = PIER.y1 - PIER.y0;
      var len = Math.hypot(dx, dy), nx = -dy / len, ny = dx / len;
      /* the dark shadow the pier drops on the water */
      g.save();
      g.globalAlpha = 0.5;
      g.fillStyle = '#02060a';
      g.beginPath();
      g.moveTo(PIER.x0 + nx * PIER.w / 2 + 5, PIER.y0 + ny * PIER.w / 2 + 8);
      g.lineTo(PIER.x1 + nx * PIER.w / 2 + 5, PIER.y1 + ny * PIER.w / 2 + 8);
      g.lineTo(PIER.x1 - nx * PIER.w / 2 + 5, PIER.y1 - ny * PIER.w / 2 + 8);
      g.lineTo(PIER.x0 - nx * PIER.w / 2 + 5, PIER.y0 - ny * PIER.w / 2 + 8);
      g.closePath();
      g.fill();
      g.restore();
      var n2 = Math.round(len / 7.5);
      for (var pb = 0; pb <= n2; pb++) {
        var tt = pb / n2;
        var cx2 = PIER.x0 + dx * tt, cy2 = PIER.y0 + dy * tt;
        var tone = pb % 2 ? '#312718' : '#2a2113';
        g.save();
        g.translate(cx2, cy2);
        g.rotate(Math.atan2(dy, dx));
        g.fillStyle = tone;
        g.fillRect(-3.2, -PIER.w / 2, 6.4, PIER.w);
        g.strokeStyle = 'rgba(8,6,3,0.7)';
        g.lineWidth = 1;
        g.strokeRect(-3.2, -PIER.w / 2, 6.4, PIER.w);
        g.fillStyle = 'rgba(200,196,170,0.10)';
        g.fillRect(-1, -PIER.w / 2 + 1.6, 1.4, 1.4);
        g.fillRect(-1, PIER.w / 2 - 3, 1.4, 1.4);
        g.restore();
      }
      /* rails: two stringers running the whole length */
      g.strokeStyle = 'rgba(24,18,10,0.85)';
      g.lineWidth = 2;
      g.beginPath();
      g.moveTo(PIER.x0 + nx * (PIER.w / 2 - 2), PIER.y0 + ny * (PIER.w / 2 - 2));
      g.lineTo(PIER.x1 + nx * (PIER.w / 2 - 2), PIER.y1 + ny * (PIER.w / 2 - 2));
      g.moveTo(PIER.x0 - nx * (PIER.w / 2 - 2), PIER.y0 - ny * (PIER.w / 2 - 2));
      g.lineTo(PIER.x1 - nx * (PIER.w / 2 - 2), PIER.y1 - ny * (PIER.w / 2 - 2));
      g.stroke();
    })();

    /* wet puddles with sheen */
    for (var u = 0; u < 30; u++) {
      var ux = r() * W, uy = r() * H, ur = 14 + r() * 32;
      if (inEllipse(ux, uy, WATERS[0], -10) || inEllipse(ux, uy, WATERS[1], -10)) continue;
      g.fillStyle = 'rgba(84,112,120,0.2)';
      g.beginPath(); g.ellipse(ux, uy, ur, ur * 0.42, r() * 3, 0, T.TAU); g.fill();
      g.fillStyle = 'rgba(200,220,218,0.08)';
      g.beginPath(); g.ellipse(ux - ur * 0.2, uy - ur * 0.12, ur * 0.5, ur * 0.14, r() * 3, 0, T.TAU); g.fill();
      g.strokeStyle = 'rgba(30,40,42,0.35)';
      g.lineWidth = 1;
      g.beginPath(); g.ellipse(ux, uy, ur * 0.94, ur * 0.38, 0, 0, T.TAU); g.stroke();
    }

    /* grass, tiny flowers, leaves, twigs */
    for (var gg = 0; gg < 3200; gg++) {
      var gx = r() * W, gy = r() * H;
      if (inEllipse(gx, gy, WATERS[0], -4) || inEllipse(gx, gy, WATERS[1], -4)) continue;
      var kind = r();
      if (kind < 0.58) {
        g.strokeStyle = 'rgba(74,108,78,' + (0.22 + r() * 0.34).toFixed(2) + ')';
        g.lineWidth = 0.8 + r();
        g.beginPath();
        for (var b = 0; b < 3; b++) {
          var bxx = gx + (r() - 0.5) * 4, t3 = 3 + r() * 4.4;
          g.moveTo(bxx, gy);
          g.quadraticCurveTo(bxx + (r() - 0.5) * 3, gy - t3 * 0.6, bxx + (r() - 0.5) * 5, gy - t3);
        }
        g.stroke();
      } else if (kind < 0.66) {
        /* rare pale flowers */
        g.fillStyle = 'rgba(206,210,192,' + (0.14 + r() * 0.16).toFixed(2) + ')';
        g.beginPath(); g.arc(gx, gy, 0.9 + r() * 0.8, 0, T.TAU); g.fill();
        g.fillStyle = 'rgba(150,158,130,0.3)';
        g.beginPath(); g.arc(gx + 1.6, gy + 1.2, 0.7, 0, T.TAU); g.fill();
      } else if (kind < 0.86) {
        g.fillStyle = r() < 0.5 ? 'rgba(96,76,40,0.42)' : 'rgba(54,84,54,0.46)';
        g.beginPath();
        g.ellipse(gx, gy, 1.4 + r() * 2.2, 1 + r() * 1.4, r() * 3, 0, T.TAU);
        g.fill();
      } else {
        g.strokeStyle = 'rgba(46,36,24,0.5)';
        g.lineWidth = 1;
        g.beginPath();
        var a3 = r() * 3;
        g.moveTo(gx, gy);
        g.lineTo(gx + Math.cos(a3) * (6 + r() * 10), gy + Math.sin(a3) * (2 + r() * 5));
        g.stroke();
      }
    }
    return c;
  }

  /* ============================================================
     INTERIOR  (a single room; origin top-left, door at bottom)
     ============================================================ */
  var RW = 660, RH = 460;
  function buildInterior() {
    var world = {
      id: 'in', W: RW, H: RH,
      objs: [], colliders: [], notes: [], examines: [], items: [],
      water: [],
      fires: [{ x: RW - 108, y: 148, lit: true, kind: 'lamp' }],  /* the lantern keeps burning */
      lantern: { x: RW - 108, y: 148 },
      ground: null, fx: [], dark: 0.88
    };
    function solidR(x, y, r) { world.colliders.push({ x: x, y: y, r: r }); }
    function solidRect(cx, cy, w, h) { world.colliders.push({ x: cx, y: cy, r: 0, rect: { x: cx - w / 2, y: cy - h / 2, w: w, h: h } }); }

    var wallT = 46;
    /* walls; the south wall is open at the doorway on purpose (world clamp keeps you in) */
    world.objs.push(mk('wallH', RW / 2, wallT, 1, { w: RW + 40, h: wallT }));
    world.objs.push(mk('wallH', RW / 2, RH, 1, { w: RW + 40, h: 26, side: 'south' }));
    world.objs.push(mk('wallV', 20, RH / 2, 1, { w: 40, h: RH }));
    world.objs.push(mk('wallV', RW - 20, RH / 2, 1, { w: 40, h: RH, side: 'left' }));
    /* window onto the north wall */
    world.objs.push(mk('windowIn', RW * 0.62, 18, 1));
    world.examines.push({ x: RW * 0.62, y: 44, r: 46, ikey: 'win_look', label: 'examine' });
    /* north + side wall colliders only */
    solidRect(RW / 2, 20, RW, 40);
    solidRect(18, RH / 2, 36, RH);
    solidRect(RW - 18, RH / 2, 36, RH);

    /* doorway (south, centered): LEAVE */
    world.examines.push({ x: RW / 2, y: RH - 16, r: 42, ikey: 'door_back', label: 'leave', special: 'exit' });
    world.objs.push(mk('doorIn', RW / 2, RH - 2, 1));

    /* furniture */
    world.objs.push(mk('hearthIn', 92, 128, 1, { lit: false, fireIdx: -1 }));
    world.examines.push({ x: 92, y: 150, r: 40, ikey: 'hearth_look', label: 'examine' });
    solidRect(92, 116, 62, 44);
    world.objs.push(mk('shelf', RW / 2 - 60, 86, 1));
    world.objs.push(mk('bed', 560, 300, 1, { rot: 0 }));
    solidRect(560, 300, 54, 68);
    world.examines.push({ x: 560, y: 330, r: 40, ikey: 'bed_look', label: 'examine' });
    world.objs.push(mk('table', 330, 300, 1.5));
    solidRect(330, 300, 56, 16);
    world.objs.push(mk('chair', 272, 320, 1.1));
    solidR(272, 320, 8);
    world.objs.push(mk('crate', 632, 420, 1.1), mk('crate', 610, 432, 0.9));
    solidR(632, 420, 13);
    world.objs.push(mk('barrel', 470, 402, 1.1));
    solidR(470, 402, 12);
    /* lantern on a peg near the hearth wall corner */
    world.objs.push(mk('lanternPeg', RW - 108, 118, 1));
    /* cabinet, west wall: the journal waits behind its lock */
    var cab = mk('cabinet', 52, 300, 1, { open: false, journal: true, journalTaken: false });
    cab.ySort = 310;
    world.objs.push(cab);
    solidRect(52, 296, 46, 60);
    world.examines.push({ x: 58, y: 322, r: 48, ikey: 'cabinet_locked', label: 'examine', special: 'cabinet', data: cab });

    /* three things to find */
    world.items.push({ id: 0, kind: 'photo', x: 330, y: 288, taken: false, seed: 1 });  /* on the table */
    world.items.push({ id: 1, kind: 'matches', x: RW / 2 - 44, y: 78, taken: false, seed: 2 });  /* on the shelf */
    world.items.push({ id: 2, kind: 'key', x: 606, y: 246, taken: false, seed: 3 });   /* on the bedside plank */

    world.objs.sort(function (a, b) { return (a.ySort || a.y) - (b.ySort || b.y); });
    world.ground = bakeInterior(T.rng(99));
    /* dust motes near the lantern */
    for (var d = 0; d < 14; d++) {
      world.fx.push({
        x: RW - 108 + (Math.sin(d * 7.3) * 90),
        y: 148 + (Math.cos(d * 3.1) * 70),
        r: 0.8 + (d % 3) * 0.5, ph: d * 0.9, sp: 0.22 + (d % 4) * 0.07, dust: 1
      });
    }
    world.cabinet = cab;
    return world;
  }

  function bakeInterior(r) {
    var c = T.canvas(RW, RH);
    var g = c.getContext('2d');
    g.fillStyle = '#241708';
    g.fillRect(0, 0, RW, RH);
    /* planks running horizontally */
    for (var y = 44; y < RH - 20; y += 13) {
      var tone = 24 + Math.floor(r() * 10);
      g.fillStyle = 'rgb(' + (tone + 24) + ',' + (tone + 12) + ',' + Math.floor(tone * 0.55) + ')';
      g.fillRect(18, y, RW - 36, 11.6);
      g.fillStyle = 'rgba(12,8,4,0.55)';
      g.fillRect(18, y + 11.6, RW - 36, 1.4);
      /* seam joints */
      var jx = 60 + r() * (RW - 140);
      g.fillStyle = 'rgba(10,6,3,0.5)';
      g.fillRect(jx, y, 1.6, 11.6);
      /* nail glints */
      g.fillStyle = 'rgba(210,200,170,0.10)';
      g.fillRect(26, y + 2, 1.6, 1.6);
      g.fillRect(RW - 28, y + 2, 1.6, 1.6);
    }
    /* wall base shadow on the floor */
    var gb = g.createLinearGradient(0, 44, 0, 130);
    gb.addColorStop(0, 'rgba(0,0,0,0.65)');
    gb.addColorStop(1, 'rgba(0,0,0,0)');
    g.fillStyle = gb;
    g.fillRect(18, 44, RW - 36, 90);
    g.save();
    g.translate(RW - 20, 0);
    var gl = g.createLinearGradient(-90, 0, 0, 0);
    gl.addColorStop(0, 'rgba(0,0,0,0.4)');
    gl.addColorStop(1, 'rgba(0,0,0,0)');
    g.fillStyle = gl;
    g.fillRect(-90, 44, 72, RH - 80);
    g.restore();
    g.save();
    g.translate(20, 0);
    var gr2 = g.createLinearGradient(18, 0, 110, 0);
    gr2.addColorStop(0, 'rgba(0,0,0,0.4)');
    gr2.addColorStop(1, 'rgba(0,0,0,0)');
    g.fillStyle = gr2;
    g.fillRect(18, 44, 90, RH - 80);
    g.restore();
    /* rug under the table */
    g.fillStyle = '#3c2118';
    g.beginPath();
    g.ellipse(330, 316, 96, 52, 0, 0, T.TAU);
    g.fill();
    g.fillStyle = '#47281c';
    g.beginPath();
    g.ellipse(330, 316, 82, 42, 0, 0, T.TAU);
    g.fill();
    g.strokeStyle = 'rgba(190,150,90,0.16)';
    g.lineWidth = 2;
    g.beginPath();
    g.ellipse(330, 316, 70, 33, 0, 0, T.TAU);
    g.stroke();
    g.beginPath();
    g.ellipse(330, 316, 40, 18, 0, 0, T.TAU);
    g.stroke();
    /* diamond pattern */
    g.fillStyle = 'rgba(200,160,100,0.07)';
    for (var dx = -84; dx <= 84; dx += 24)
      for (var dy = -44; dy <= 44; dy += 22) {
        g.beginPath();
        g.moveTo(330 + dx, 316 + dy - 4);
        g.lineTo(330 + dx + 7, 316 + dy);
        g.lineTo(330 + dx, 316 + dy + 4);
        g.lineTo(330 + dx - 7, 316 + dy);
        g.fill();
      }
    /* moonlight streak from the window */
    var gw = g.createLinearGradient(RW * 0.62, 60, RW * 0.52, 260);
    gw.addColorStop(0, 'rgba(160,180,200,0.14)');
    gw.addColorStop(1, 'rgba(160,180,200,0)');
    g.fillStyle = gw;
    g.beginPath();
    g.moveTo(RW * 0.62 - 46, 58);
    g.lineTo(RW * 0.62 + 46, 58);
    g.lineTo(RW * 0.62 + 14, 280);
    g.lineTo(RW * 0.62 - 78, 280);
    g.closePath();
    g.fill();
    /* lantern warm pool baked faintly */
    var gp = g.createRadialGradient(RW - 108, 170, 8, RW - 108, 170, 130);
    gp.addColorStop(0, 'rgba(214,150,72,0.10)');
    gp.addColorStop(1, 'rgba(214,150,72,0)');
    g.fillStyle = gp;
    g.fillRect(RW - 240, 40, 220, 260);
    /* scratches, crumbs, dust */
    for (var i = 0; i < 420; i++) {
      var sx = 30 + r() * (RW - 60), sy = 60 + r() * (RH - 110);
      if (r() < 0.7) {
        g.strokeStyle = 'rgba(16,10,5,' + (0.2 + r() * 0.3).toFixed(2) + ')';
        g.lineWidth = 0.8;
        g.beginPath();
        var a = r() * 3;
        g.moveTo(sx, sy);
        g.lineTo(sx + Math.cos(a) * (3 + r() * 9), sy + Math.sin(a) * (2 + r() * 4));
        g.stroke();
      } else {
        g.fillStyle = 'rgba(150,120,70,' + (0.1 + r() * 0.12).toFixed(2) + ')';
        g.fillRect(sx, sy, 1.2, 1.2);
      }
    }
    return c;
  }

  T.World = {
    buildAll: function () { return { out: buildOutdoor(), int: buildInterior() }; },
    ZONES: ZONES, NOTES_META: NOTES, CHAPTER_NOTE: CHAPTER_NOTE,
    distToPaths: distToPaths, PATHS: PATHS,
    WATERS: WATERS, PIER: PIER,
    get GATES() { return GATES_OUT; },
    RW: RW, RH: RH
  };
})();
