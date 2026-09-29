/* ============================================================
   THE LONE PATH — world
   One small hand-made map (1600x1600). No procedural gameplay:
   the forest is scattered with a seeded rng for looks only,
   everything that matters (notes, cabin, fires) is placed by hand.
   ============================================================ */
'use strict';
(function () {
  var T = window.TLP;

  var W = 1600, H = 1600;

  /* story text */
  var NOTES = [
    {
      x: 556, y: 995,
      title: 'NOTE 01',
      lines: [
        'We arrived here three days ago.',
        'We made camp beside the old cabin. Everything seemed ordinary.',
        'But last night we heard steps walking around the camp while we slept.',
        'Slow steps. Round and round. Nobody in our group left the tent.'
      ]
    },
    {
      x: 1104, y: 1032,
      title: 'NOTE 02',
      lines: [
        'In the morning we found tracks in the mud around the cabin.',
        'They went into the forest. None came back.',
        'There is a symbol carved on an old tree near the door:',
        'three lines and an eye. None of us carved it.'
      ]
    },
    {
      x: 698, y: 762,
      title: 'NOTE 03',
      lines: [
        'We are not alone here. I am sure of it now.',
        'Every night a fire is lit beside the cabin. Warm ash at midnight.',
        'Every morning we ask who did it. Nobody admits anything.',
        'By sunrise the fire is always cold again.'
      ]
    },
    {
      x: 445, y: 470,
      title: 'NOTE 04',
      lines: [
        'The others are gone. I woke up and the camp was empty.',
        'Not a single sign of a struggle. Only the cold fire pit.',
        'I tried to leave. Every path through the trees brought me back',
        'to the same cabin, the same door, the same window watching me.'
      ]
    },
    {
      x: 1032, y: 288,
      title: 'NOTE 05',
      lines: [
        'I understand one thing now. I write it with a shaking hand.',
        'The carvings on that tree are old. Older than this forest.',
        'We came here looking for something. We were not the first ones.',
        'It does not hunt us. It is simply waiting for us to notice that&mdash;',
        '<span class="torn">[the rest of the page is torn away]</span>'
      ]
    }
  ];

  /* atmospheric examines (small amount, per spec) */
  var EXAMINES = [
    {
      x: 800, y: 748, r: 52, title: 'THE CABIN', label: 'EXAMINE',
      text: ['The door hangs open on one hinge.', 'A cold hearth inside. One chair, facing the wall.',
             'Someone scratched a symbol into the frame &mdash; three lines and an eye.']
    },
    {
      x: 505, y: 937, r: 40, title: 'CAMPFIRE', label: 'EXAMINE',
      text: ['Cold ash. The stones are stacked in a careful, quiet circle.',
             'Whatever slept here knew how to keep a fire from crackling.']
    },
    {
      x: 866, y: 808, r: 40, title: 'SMALL FIRE', label: 'EXAMINE',
      text: ['Fresh scorch marks on these stones.', 'This fire was burning a few hours ago.', 'Nobody here admits to lighting it.']
    },
    {
      x: 1148, y: 966, r: 48, title: 'THE CAR', label: 'EXAMINE',
      text: ['A rusted station wagon, sunk into wet moss.', 'The keys are still in the ignition. The tank is bone dry.',
             'The passenger seat is folded down. Someone slept here a long time.']
    },
    {
      x: 452, y: 908, r: 44, title: 'COLLAPSED TENT', label: 'EXAMINE',
      text: ['It folded inward, like it caved under someone sitting up in a hurry.', 'Inside: four sleeping bags. Nobody took a single one.']
    },
    {
      x: 736, y: 590, r: 40, title: 'THE SYMBOL', label: 'READ',
      text: ['Three lines and an eye, carved into the bark.', 'The cuts are old and dark with rain.',
             'There are more of them underneath the moss. All deeper. All newer.']
    },
    {
      x: 706, y: 1046, r: 38, title: 'SIGNPOST', label: 'READ',
      text: ['Its painted fingers point every direction at once.', 'Every one of them, when you follow it, ends at the cabin.']
    },
    {
      x: 1052, y: 214, r: 46, title: 'THE OLD TREE', label: 'EXAMINE',
      text: ['Carvings all around the trunk. Names. Dates nobody can read.',
             'Some look centuries old. The newest one looks like it was made last night.']
    }
  ];

  /* zones used for fog/darkness + clearing the scatter */
  var ZONES = {
    start:  { x: 800, y: 1180, r: 150 },
    camp:   { x: 520, y: 950,  r: 140 },
    cabin:  { x: 800, y: 700,  r: 170 },
    wreck:  { x: 1160, y: 980, r: 110 },
    deep:   { x: 430, y: 430,  r: 360 },
    final:  { x: 1050, y: 260, r: 120 }
  };

  /* walking paths (drawn onto ground + kept clear of trees) */
  var PATHS = [
    [[800, 1180], [720, 1075], [640, 1010], [556, 995], [505, 950]],
    [[505, 950], [600, 880], [700, 815], [790, 770], [800, 745]],
    [[800, 745], [812, 640], [790, 520], [830, 430], [930, 350], [1010, 305], [1032, 288]],
    [[1032, 288], [1150, 380], [1205, 560], [1200, 800], [1160, 940], [1120, 1010]],
    [[1120, 1010], [980, 1090], [870, 1140], [800, 1180]],
    [[445, 470], [540, 520], [700, 600], [760, 660]]
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

  function densityAt(x, y) {
    var d = 0.06; /* default thin woods */
    function add(z, v) { var dd = T.dist2(x, y, z.x, z.y); if (dd < z.r * z.r) d += v * (1 - Math.sqrt(dd) / z.r); }
    add(ZONES.deep, 0.85);
    add({ x: 1300, y: 420, r: 320 }, 0.5);
    add({ x: 260, y: 1240, r: 420 }, 0.55);
    add({ x: 1340, y: 1320, r: 420 }, 0.5);
    add({ x: 800, y: 150, r: 420 }, 0.42);
    add({ x: 60, y: 700, r: 300 }, 0.5);
    add({ x: 1560, y: 700, r: 260 }, 0.4);
    /* wall of trees near the world edge */
    var edge = Math.min(x, y, W - x, W - y);
    if (edge < 170) d += 0.95 * (1 - edge / 170);
    /* open up near the important places */
    ['start', 'camp', 'cabin', 'wreck', 'final'].forEach(function (k) {
      var z = ZONES[k];
      var dd = Math.sqrt(T.dist2(x, y, z.x, z.y));
      if (dd < z.r * 1.25) d *= Math.min(1, dd / (z.r * 1.25));
    });
    /* paths stay walkable */
    if (distToPaths(x, y) < 46) d = Math.min(d, 0.10);
    return T.clamp(d, 0.04, 1);
  }

  /* ============================================================ */
  function build() {
    var world = {
      W: W, H: H,
      objs: [],      /* y-sorted renderables (solid + tall) */
      colliders: [], /* circle/rect solids for movement */
      notes: [],     /* 5 notes with taken flags */
      examines: [],  /* atmospheric interaction points */
      fires: [{ x: 505, y: 937, lit: false, r: 20 }, { x: 866, y: 808, lit: false, r: 18 }],
      ground: null,
      cabin: { x: 800, y: 726, w: 100 }
    };

    var mk = function (k, x, y, s, extra) {
      var o = { k: k, x: x, y: y, s: s || 1 };
      if (extra) for (var p in extra) o[p] = extra[p];
      return o;
    };
    var solidC = function (o, r) {
      o.solid = true;
      world.colliders.push({ x: o.x, y: o.y - (o.cUp || 0) * 0, r: r, o: o });
      return o;
    };

    /* ---------- hand-placed props ---------- */
    /* CABIN */
    var cabinObj = mk('cabin', 800, 726, 1);
    cabinObj.ySort = 726;
    world.objs.push(cabinObj);
    world.colliders.push({ x: 800, y: 700, r: 0, rect: { x: 700, y: 678, w: 200, h: 50 } });
    world.colliders.push({ x: 800, y: 664, r: 0, rect: { x: 692, y: 640, w: 216, h: 44 } });

    world.objs.push(solidC(mk('crate', 668, 762, 1), 12));
    world.objs.push(solidC(mk('crate', 694, 778, 0.9), 11));
    world.objs.push(solidC(mk('barrel', 936, 742, 1), 11));
    world.objs.push(mk('barrel', 954, 716, 0.95));
    world.objs.push(solidC(mk('logpile', 652, 700, 1, { rot: 0 }), 20));
    world.objs.push(mk('table', 868, 786, 1));
    world.objs.push(mk('planks', 918, 782, 1, { rot: 0.5 }));
    world.objs.push(mk('planks', 892, 800, 0.8, { rot: -0.3 }));
    world.objs.push(solidC(mk('stump', 856, 742, 1), 8));
    world.objs.push(solidC(mk('signtree', 736, 590, 1.15), 9));
    world.objs.push(mk('firepit', 866, 808, 1, { fireIdx: 1 }));

    /* CAMP */
    world.objs.push(mk('firepit', 505, 937, 1.1, { fireIdx: 0 }));
    world.objs.push(solidC(mk('tent', 452, 908, 1), 0, 'tent'));
    world.colliders.push({ x: 452, y: 890, r: 0, rect: { x: 424, y: 878, w: 58, h: 30 } });
    world.objs.push(solidC(mk('fallen', 560, 972, 0.8, { rot: 0.4 }), 0));
    world.colliders.push({ x: 560, y: 972, r: 12 });
    world.objs.push(mk('logpile', 574, 918, 0.85));
    world.objs.push(solidC(mk('crate', 588, 946, 0.85), 11));
    world.objs.push(mk('stump', 462, 986, 0.9));
    world.objs.push(mk('rock', 540, 1008, 0.8));
    world.objs.push(solidC(mk('dry', 610, 900, 1), 8));

    /* WRECK */
    var car = mk('car', 1152, 982, 1, { rot: -0.45 });
    car.ySort = 1000;
    world.objs.push(car);
    world.colliders.push({ x: 1152, y: 982, r: 34 });
    world.objs.push(mk('rock', 1082, 1032, 1.1));
    world.objs.push(solidC(mk('rock', 1214, 1020, 1.3), 13));
    world.objs.push(mk('bush', 1092, 940, 1));
    world.objs.push(mk('bush', 1216, 946, 1.2));
    world.objs.push(solidC(mk('fallen', 1230, 1052, 0.9, { rot: 1.2 }), 0));
    world.colliders.push({ x: 1230, y: 1052, r: 14 });
    world.objs.push(mk('planks', 1104, 990, 0.7, { rot: 1.1 }));

    /* START clearing */
    world.objs.push(solidC(mk('rock', 842, 1206, 1), 10));
    world.objs.push(mk('rock', 764, 1216, 0.75));
    world.objs.push(solidC(mk('dry', 858, 1142, 0.9), 8));
    world.objs.push(mk('stump', 742, 1150, 0.8));
    world.objs.push(mk('sign', 706, 1046, 1, { dir: -0.9 }));
    world.objs.push(mk('bush', 770, 1230, 0.9));
    world.objs.push(mk('bush', 856, 1188, 1.05));

    /* DEEP FOREST */
    world.objs.push(solidC(mk('rock', 508, 428, 1.7), 17));
    world.objs.push(solidC(mk('rock', 372, 528, 1.2), 13));
    world.objs.push(mk('fence', 398, 566, 1, { rot: 0.2 }));
    world.objs.push(mk('fence', 486, 542, 0.85, { rot: -1.15 }));
    world.objs.push(solidC(mk('dry', 470, 418, 1.15), 8));
    world.objs.push(solidC(mk('stump', 404, 452, 1.4), 10));
    world.objs.push(mk('fallen', 520, 486, 1, { rot: -0.5 }));
    world.colliders.push({ x: 520, y: 486, r: 15 });
    world.objs.push(solidC(mk('sign', 560, 630, 1, { dir: 0.5, rot: 0 }), 6));

    /* FINAL POINT */
    world.objs.push(solidC(mk('bigtree', 1052, 200, 1), 17));
    world.objs.push(mk('cross', 1090, 262, 1));
    world.objs.push(solidC(mk('rock', 1006, 252, 1.2), 12));
    world.objs.push(mk('stump', 1096, 322, 1.1));
    world.objs.push(solidC(mk('dry', 998, 330, 1.05), 7));
    world.objs.push(mk('fence', 1120, 220, 0.8, { rot: 1.35 }));

    /* ---------- scattered forest (visual only, seeded) ---------- */
    var r = T.rng(1337);
    var types = [
      ['pine', 0.34, 12], ['fir', 0.56, 10], ['small', 0.72, 7],
      ['dry', 0.85, 6], ['stump', 1.0, 7]
    ];
    var placed = [];
    function tooClose(x, y, d2) {
      var n = d2 * d2;
      for (var i = 0; i < placed.length; i++) {
        if (T.dist2(x, y, placed[i][0], placed[i][1]) < n) return true;
      }
      /* also keep away from hand props */
      for (var j = 0; j < world.objs.length; j++) {
        var o = world.objs[j];
        if (T.dist2(x, y, o.x, o.y) < 4096) return true;
      }
      for (var k = 0; k < NOTES.length; k++) {
        if (T.dist2(x, y, NOTES[k].x, NOTES[k].y) < 3200) return true;
      }
      return false;
    }
    var tries = 0;
    while (placed.length < 430 && tries < 12000) {
      tries++;
      var x = 50 + r() * (W - 100);
      var y = 50 + r() * (H - 100);
      if (r() > densityAt(x, y)) continue;
      if (tooClose(x, y, 44)) continue;
      var tr = r();
      var kind = 'pine', trunk = 12;
      for (var ti = 0; ti < types.length; ti++) {
        if (tr <= types[ti][1]) { kind = types[ti][0]; trunk = types[ti][2]; break; }
      }
      var s = 0.75 + r() * 0.62 + (kind === 'pine' ? r() * 0.2 : 0);
      var o = mk(kind, x, y, s);
      if (trunk > 0) world.colliders.push({ x: x, y: y, r: trunk * s * 0.62 });
      world.objs.push(o);
      placed.push([x, y]);
      /* occasional companion clutter near a tree */
      if (r() < 0.16) {
        var bx = x + (r() - 0.5) * 70, by = y + 18 + r() * 26;
        if (distToPaths(bx, by) > 34)
          world.objs.push(mk(r() < 0.5 ? 'bush' : (r() < 0.7 ? 'rock' : 'stump'), bx, by, 0.6 + r() * 0.5, { comp: 1 }));
      }
    }
    /* light bushes everywhere else (never solid) */
    for (var i = 0; i < 120; i++) {
      var bx2 = 40 + r() * (W - 80), by2 = 40 + r() * (H - 80);
      if (distToPaths(bx2, by2) < 26) continue;
      world.objs.push(mk('bush', bx2, by2, 0.55 + r() * 0.7, { comp: 1 }));
    }

    /* ---------- notes ---------- */
    for (var n = 0; n < NOTES.length; n++) {
      var nd = NOTES[n];
      world.notes.push({
        x: nd.x, y: nd.y, idx: n, taken: false,
        title: nd.title, lines: nd.lines,
        rot: (r() - 0.5) * 0.7
      });
    }
    for (var e = 0; e < EXAMINES.length; e++) world.examines.push(EXAMINES[e]);

    /* y-sort static objects once */
    world.objs.sort(function (a, b) { return (a.ySort || a.y) - (b.ySort || b.y); });

    /* ---------- ground bake ---------- */
    world.ground = bakeGround(r);
    return world;
  }

  function bakeGround(r) {
    var c = T.canvas(W, H);
    var g = c.getContext('2d');
    var C = T.Assets.C;
    g.fillStyle = '#18241d';
    g.fillRect(0, 0, W, H);

    /* large tonal blotches */
    for (var i = 0; i < 260; i++) {
      var x = r() * W, y = r() * H, rad = 40 + r() * 160;
      var cols = ['#203026', '#15211a', '#26382c', '#1a2a21', '#2c4133'];
      var grd = g.createRadialGradient(x, y, rad * 0.15, x, y, rad);
      var col = cols[Math.floor(r() * cols.length)];
      grd.addColorStop(0, col);
      grd.addColorStop(1, 'rgba(0,0,0,0)');
      g.globalAlpha = 0.5 + r() * 0.5;
      g.fillStyle = grd;
      g.beginPath();
      g.ellipse(x, y, rad, rad * (0.5 + r() * 0.5), r() * 3, 0, T.TAU);
      g.fill();
    }
    g.globalAlpha = 1;

    /* paths */
    for (var p = 0; p < PATHS.length; p++) {
      var pl = PATHS[p];
      for (var s2 = 0; s2 < pl.length - 1; s2++) {
        var ax = pl[s2][0], ay = pl[s2][1], bx = pl[s2 + 1][0], by = pl[s2 + 1][1];
        var len = Math.hypot(bx - ax, by - ay);
        var steps = Math.ceil(len / 9);
        for (var k = 0; k <= steps; k++) {
          var t2 = k / steps;
          var px = ax + (bx - ax) * t2 + (r() - 0.5) * 9;
          var py = ay + (by - ay) * t2 + (r() - 0.5) * 9;
          var pr = 11 + r() * 12;
          var gr2 = g.createRadialGradient(px, py, 1, px, py, pr);
          gr2.addColorStop(0, 'rgba(62,60,46,0.6)');
          gr2.addColorStop(0.7, 'rgba(50,48,38,0.32)');
          gr2.addColorStop(1, 'rgba(0,0,0,0)');
          g.fillStyle = gr2;
          g.beginPath();
          g.ellipse(px, py, pr, pr * 0.62, r() * 3, 0, T.TAU);
          g.fill();
        }
      }
    }

    /* wet puddles — subtle sheen */
    for (var u = 0; u < 26; u++) {
      var ux = r() * W, uy = r() * H, ur = 14 + r() * 30;
      g.fillStyle = 'rgba(84,112,120,0.2)';
      g.beginPath();
      g.ellipse(ux, uy, ur, ur * 0.42, r() * 3, 0, T.TAU);
      g.fill();
      g.fillStyle = 'rgba(190,210,208,0.07)';
      g.beginPath();
      g.ellipse(ux - ur * 0.2, uy - ur * 0.1, ur * 0.5, ur * 0.16, r() * 3, 0, T.TAU);
      g.fill();
    }

    /* grass tufts, leaves, twigs */
    for (var gg = 0; gg < 2600; gg++) {
      var gx = r() * W, gy = r() * H;
      var kind = r();
      if (kind < 0.62) {
        g.strokeStyle = 'rgba(66,98,72,' + (0.28 + r() * 0.35).toFixed(2) + ')';
        g.lineWidth = 0.8 + r();
        g.beginPath();
        for (var b = 0; b < 3; b++) {
          var bxx = gx + (r() - 0.5) * 4, t3 = 3 + r() * 4;
          g.moveTo(bxx, gy);
          g.quadraticCurveTo(bxx + (r() - 0.5) * 3, gy - t3 * 0.6, bxx + (r() - 0.5) * 5, gy - t3);
        }
        g.stroke();
      } else if (kind < 0.85) {
        g.fillStyle = r() < 0.5 ? 'rgba(92,74,38,0.4)' : 'rgba(52,80,54,0.45)';
        g.beginPath();
        g.ellipse(gx, gy, 1.4 + r() * 2, 1 + r() * 1.4, r() * 3, 0, T.TAU);
        g.fill();
      } else {
        g.strokeStyle = 'rgba(58,46,32,0.55)';
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

  T.World = { build: build, ZONES: ZONES, distToPaths: distToPaths, PATHS: PATHS };
})();
