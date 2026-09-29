/* ============================================================
   THE LONE PATH — procedural assets  v2
   Everything drawn in code. Pseudo-3D: base point + extruded
   bodies, soft shadows, y-sorting, wind sway, moon rim-light.
   ============================================================ */
'use strict';
(function () {
  var T = window.TLP;
  var A = {};
  T.Assets = A;

  var C = {
    void: '#0B0D0D', g0: '#111A16', g1: '#1B2921', g2: '#344039',
    gray: '#626965', lite: '#A7ACA8', lamp: '#D7D0B7', fire: '#c9793d'
  };
  A.C = C;

  /* ---------- helpers ---------- */
  function shadow(ctx, x, y, rx, ry, a) {
    ctx.save();
    ctx.globalAlpha = a == null ? 0.42 : a;
    ctx.fillStyle = '#000';
    ctx.beginPath();
    ctx.ellipse(x + 4, y + 3, rx, ry, 0, 0, T.TAU);
    ctx.fill();
    ctx.restore();
  }
  function grad(ctx, x0, y0, x1, y1, stops) {
    var g = ctx.createLinearGradient(x0, y0, x1, y1);
    for (var i = 0; i < stops.length; i++) g.addColorStop(stops[i][0], stops[i][1]);
    return g;
  }
  function ell(ctx, x, y, rx, ry, fill, rot) {
    ctx.fillStyle = fill;
    ctx.beginPath();
    ctx.ellipse(x, y, rx, ry, rot || 0, 0, T.TAU);
    ctx.fill();
  }
  function rr(ctx, x, y, w, h, r) {
    r = Math.min(r, w / 2, h / 2);
    ctx.beginPath();
    ctx.moveTo(x + r, y);
    ctx.arcTo(x + w, y, x + w, y + h, r);
    ctx.arcTo(x + w, y + h, x, y + h, r);
    ctx.arcTo(x, y + h, x, y, r);
    ctx.arcTo(x, y, x + w, y, r);
    ctx.closePath();
  }
  function sj(o, salt) {
    var n = Math.sin(o.x * 12.9898 + o.y * 78.233 + (salt || 0) * 37.71) * 43758.5453;
    return n - Math.floor(n);
  }
  /* gentle wind: phase from world position */
  function sway(o, t, amp) {
    return Math.sin(t * 0.55 + o.x * 0.011 + o.y * 0.017) * (amp || 1.1);
  }
  /* faint cold rim from the moon (upper right) */
  function rim(ctx, x, y, rx, ry) {
    ctx.save();
    ctx.globalCompositeOperation = 'lighter';
    ctx.globalAlpha = 0.05;
    ctx.fillStyle = '#9fc0b4';
    ctx.beginPath();
    ctx.ellipse(x + rx * 0.22, y - ry * 0.3, rx * 0.62, ry * 0.5, -0.5, 0, T.TAU);
    ctx.fill();
    ctx.restore();
  }
  function hsl(base, d, s, l) { /* tiny per-tree tone jitter helper */
    return 'hsl(' + base + ',' + s + '%,' + (l + d) + '%)';
  }

  /* ============================================================
     TREES
     ============================================================ */
  function conifer(ctx, o, t, layers, w, hgt, top1, top2, bot) {
    var s = o.s || 1;
    var by = o.y;
    var sw = sway(o, t, 1.4 * s);
    /* trunk with slight lean */
    ctx.fillStyle = grad(ctx, 0, by - 36 * s, 0, by, [[0, '#33291c'], [1, '#140f09']]);
    ctx.beginPath();
    ctx.moveTo(o.x - 3.6 * s, by);
    ctx.quadraticCurveTo(o.x - 2.8 * s + sw * 0.3, by - 20 * s, o.x - 2.2 * s + sw * 0.6, by - 36 * s);
    ctx.lineTo(o.x + 2.2 * s + sw * 0.6, by - 36 * s);
    ctx.quadraticCurveTo(o.x + 2.8 * s + sw * 0.3, by - 20 * s, o.x + 3.6 * s, by);
    ctx.fill();
    var tone = (sj(o, 5) - 0.5) * 5;
    for (var i = 0; i < layers; i++) {
      var p = i / (layers - 1 || 1);
      var ly = by - (26 + p * (hgt - 26)) * s;
      var lw = w * (1 - p * 0.62) * s;
      var lx = o.x + sw * (0.45 + p * 0.75);
      ctx.fillStyle = grad(ctx, 0, ly - lw * 1.1, 0, ly + lw * 0.5,
        [[0, hsl(148, tone, 26, 21)], [0.5, top1], [1, top2]]);
      ctx.beginPath();
      ctx.moveTo(lx - lw, ly + lw * 0.24);
      ctx.quadraticCurveTo(lx - lw * 0.55, ly - lw * 0.06, lx - lw * 0.12 + sw * 0.4, ly - lw * 0.78);
      ctx.quadraticCurveTo(lx + lw * 0.1, ly - lw * 1.06, lx + lw * 0.28, ly - lw * 0.7);
      ctx.quadraticCurveTo(lx + lw * 0.55, ly - lw * 0.06, lx + lw, ly + lw * 0.24);
      ctx.quadraticCurveTo(lx, ly + lw * 0.52, lx - lw, ly + lw * 0.24);
      ctx.fill();
      /* needle light on the top edge */
      ctx.strokeStyle = 'rgba(190,220,190,0.10)';
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.moveTo(lx - lw * 0.55, ly - lw * 0.28);
      ctx.quadraticCurveTo(lx, ly - lw * 1.02, lx + lw * 0.62, ly - lw * 0.2);
      ctx.stroke();
    }
  }
  A.pine = function (ctx, o, t) {
    var s = o.s || 1;
    shadow(ctx, o.x, o.y, 25 * s, 9 * s);
    conifer(ctx, o, t, 3, 30, 88, '#2c4c38', '#1a3123', '#152619');
  };
  A.fir = function (ctx, o, t) {
    var s = o.s || 1;
    shadow(ctx, o.x, o.y, 22 * s, 8 * s);
    conifer(ctx, o, t, 4, 25, 94, '#265040', '#163327', '#122a1f');
  };
  A.small = function (ctx, o, t) {
    var s = o.s || 1;
    shadow(ctx, o.x, o.y, 15 * s, 6 * s);
    var sw = sway(o, t, 1.6 * s);
    ctx.fillStyle = grad(ctx, 0, o.y - 26 * s, 0, o.y, [[0, '#332a1f'], [1, '#151009']]);
    ctx.fillRect(o.x - 2.2 * s, o.y - 26 * s, 4.4 * s, 26 * s);
    var cx = o.x + sw, cy = o.y - 36 * s;
    var tone = (sj(o, 2) - 0.5) * 4;
    ell(ctx, cx - 6.4 * s, cy + 3 * s, 12 * s, 10 * s, hsl(126, tone, 24, 17));
    ell(ctx, cx + 5.4 * s, cy, 11 * s, 9 * s, hsl(138, tone, 22, 14));
    ell(ctx, cx, cy - 5 * s, 11.6 * s, 9.4 * s, hsl(122, tone, 26, 21));
    ell(ctx, cx + sw * 0.4 + 2 * s, cy - 8 * s, 6 * s, 4 * s, 'rgba(210,235,205,0.06)');
  };
  A.dry = function (ctx, o, t) {
    var s = o.s || 1;
    shadow(ctx, o.x, o.y, 16 * s, 6 * s);
    var sw = sway(o, t, 0.9 * s);
    ctx.lineCap = 'round';
    var n = 5 + Math.floor(sj(o, 1) * 3);
    for (var i = 0; i < n; i++) {
      var a = -Math.PI / 2 + (i / (n - 1) - 0.5) * 2.1 + (sj(o, i) - 0.5) * 0.5;
      var len = (24 + sj(o, i + 9) * 26) * s;
      ctx.strokeStyle = i % 2 ? '#3a2f22' : '#2c241a';
      ctx.lineWidth = (3.2 - 2.3 * (i % 2)) * s;
      ctx.beginPath();
      ctx.moveTo(o.x, o.y - 12 * s);
      var ex = o.x + Math.cos(a) * len + sw, ey = o.y - 12 * s + Math.sin(a) * len;
      var mx = o.x + Math.cos(a) * len * 0.5 + sw * 0.4;
      ctx.quadraticCurveTo(mx, o.y - 12 * s + Math.sin(a) * len * 0.5, ex, ey);
      ctx.stroke();
      /* broken twig tips */
      ctx.lineWidth = 1 * s;
      ctx.beginPath();
      ctx.moveTo(ex, ey);
      ctx.lineTo(ex + Math.cos(a - 0.5) * 5 * s, ey + Math.sin(a - 0.5) * 5 * s);
      ctx.stroke();
    }
    ctx.fillStyle = grad(ctx, 0, o.y - 20 * s, 0, o.y, [[0, '#453725'], [1, '#1b140c']]);
    ctx.fillRect(o.x - 4 * s, o.y - 20 * s, 8 * s, 20 * s);
  };
  A.stump = function (ctx, o) {
    var s = o.s || 1;
    shadow(ctx, o.x, o.y, 11 * s, 4.5 * s, 0.4);
    ctx.fillStyle = grad(ctx, 0, o.y - 11 * s, 0, o.y, [[0, '#332512'], [1, '#160f07']]);
    ctx.fillRect(o.x - 7 * s, o.y - 10 * s, 14 * s, 10 * s);
    /* bark ridges */
    ctx.strokeStyle = 'rgba(20,14,8,0.6)';
    ctx.lineWidth = 1;
    for (var i = 0; i < 3; i++) {
      ctx.beginPath();
      ctx.moveTo(o.x - 6 * s + i * 4.6 * s, o.y - 9 * s);
      ctx.lineTo(o.x - 6 * s + i * 4.6 * s, o.y - 1);
      ctx.stroke();
    }
    ell(ctx, o.x, o.y - 10 * s, 7 * s, 3.4 * s, '#4a3a1f');
    ctx.strokeStyle = 'rgba(150,118,64,0.5)';
    ctx.beginPath(); ctx.ellipse(o.x, o.y - 10 * s, 4.2 * s, 2 * s, 0, 0, T.TAU); ctx.stroke();
    ctx.beginPath(); ctx.ellipse(o.x, o.y - 10 * s, 1.8 * s, 0.9 * s, 0, 0, T.TAU); ctx.stroke();
    /* moss cap */
    ctx.fillStyle = 'rgba(46,84,50,0.55)';
    ctx.beginPath();
    ctx.ellipse(o.x - 4 * s, o.y - 10.8 * s, 3.2 * s, 1.4 * s, -0.3, 0, T.TAU);
    ctx.fill();
  };
  A.bigtree = function (ctx, o, t) {
    shadow(ctx, o.x, o.y, 44, 14, 0.5);
    var sw = sway(o, t, 1.8);
    ctx.fillStyle = grad(ctx, 0, o.y - 62, 0, o.y, [[0, '#3d3122'], [1, '#171008']]);
    ctx.beginPath();
    ctx.moveTo(o.x - 12, o.y);
    ctx.quadraticCurveTo(o.x - 8, o.y - 40, o.x - 8 + sw * 0.4, o.y - 64);
    ctx.lineTo(o.x + 8 + sw * 0.4, o.y - 64);
    ctx.quadraticCurveTo(o.x + 8, o.y - 40, o.x + 12, o.y);
    ctx.fill();
    /* roots */
    ctx.strokeStyle = 'rgba(30,22,12,0.9)';
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.moveTo(o.x - 6, o.y - 4); ctx.quadraticCurveTo(o.x - 16, o.y - 2, o.x - 20, o.y + 2);
    ctx.moveTo(o.x + 6, o.y - 4); ctx.quadraticCurveTo(o.x + 16, o.y - 2, o.x + 19, o.y + 2);
    ctx.stroke();
    ctx.strokeStyle = 'rgba(225,210,170,0.4)';
    ctx.lineWidth = 1.1;
    for (var i = 0; i < 5; i++) {
      var yy = o.y - 16 - i * 9;
      ctx.beginPath();
      ctx.moveTo(o.x - 6 + (i % 2) * 3, yy);
      ctx.lineTo(o.x - 1 + (i % 3) * 2, yy + 2);
      ctx.stroke();
    }
    ell(ctx, o.x - 20 + sw, o.y - 78, 34, 24, '#22412c');
    ell(ctx, o.x + 24 + sw, o.y - 70, 30, 22, '#1c3423');
    ell(ctx, o.x + sw * 1.4, o.y - 94, 38, 25, grad(ctx, 0, o.y - 122, 0, o.y - 66, [[0, '#355940'], [1, '#182a1d']]));
    rim(ctx, o.x + sw, o.y - 94, 34, 22);
  };
  A.signtree = function (ctx, o, t) {
    A.small(ctx, o, t);
    ctx.save();
    ctx.translate(o.x, o.y - 14 * (o.s || 1));
    ctx.strokeStyle = 'rgba(220,212,180,0.6)';
    ctx.lineWidth = 1.2;
    ctx.beginPath();
    for (var i = 0; i < 3; i++) { ctx.moveTo(-4, -5 + i * 3.4); ctx.lineTo(4, -5 + i * 3.4); }
    ctx.stroke();
    ctx.beginPath();
    ctx.ellipse(0, 5, 3.6, 2, 0, 0, T.TAU);
    ctx.stroke();
    ctx.fillStyle = 'rgba(220,212,180,0.6)';
    ctx.fillRect(-0.7, 4.2, 1.4, 1.6);
    ctx.restore();
  };

  /* ============================================================
     GROUND CLUTTER
     ============================================================ */
  A.rock = function (ctx, o) {
    var s = o.s || 1;
    shadow(ctx, o.x, o.y, 12 * s, 5 * s, 0.42);
    ctx.fillStyle = grad(ctx, 0, o.y - 16 * s, 0, o.y + 2, [[0, '#7d867e'], [0.55, '#454e49'], [1, '#222823']]);
    ctx.beginPath();
    ctx.moveTo(o.x - 12 * s, o.y);
    ctx.lineTo(o.x - 9 * s, o.y - 9 * s);
    ctx.lineTo(o.x - 1 * s, o.y - 13.6 * s);
    ctx.lineTo(o.x + 7 * s, o.y - 10 * s);
    ctx.lineTo(o.x + 12 * s, o.y - 2 * s);
    ctx.quadraticCurveTo(o.x, o.y + 4 * s, o.x - 12 * s, o.y);
    ctx.fill();
    /* facet line */
    ctx.strokeStyle = 'rgba(15,18,15,0.5)';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(o.x - 1 * s, o.y - 13.6 * s);
    ctx.lineTo(o.x + 2 * s, o.y - 4 * s);
    ctx.stroke();
    /* highlight */
    ctx.fillStyle = 'rgba(200,215,205,0.14)';
    ctx.beginPath();
    ctx.moveTo(o.x - 8 * s, o.y - 9 * s);
    ctx.lineTo(o.x - 1 * s, o.y - 12.8 * s);
    ctx.lineTo(o.x + 1 * s, o.y - 8 * s);
    ctx.closePath();
    ctx.fill();
    /* moss */
    ctx.fillStyle = 'rgba(43,74,46,0.7)';
    ctx.beginPath();
    ctx.moveTo(o.x - 12 * s, o.y);
    ctx.quadraticCurveTo(o.x - 4 * s, o.y - 3 * s, o.x + 12 * s, o.y - 2 * s);
    ctx.quadraticCurveTo(o.x, o.y + 4 * s, o.x - 12 * s, o.y);
    ctx.fill();
  };
  A.fallen = function (ctx, o) {
    var s = o.s || 1;
    ctx.save();
    ctx.translate(o.x, o.y);
    ctx.rotate(o.rot || 0);
    shadow(ctx, 0, 4 * s, 34 * s, 7 * s, 0.35);
    ctx.fillStyle = grad(ctx, 0, -8 * s, 0, 4 * s, [[0, '#4b3b23'], [0.6, '#332716'], [1, '#17110a']]);
    rr(ctx, -34 * s, -7 * s, 68 * s, 11 * s, 5 * s);
    ctx.fill();
    /* bark cracks */
    ctx.strokeStyle = 'rgba(15,11,7,0.55)';
    ctx.lineWidth = 1;
    for (var i = 0; i < 4; i++) {
      ctx.beginPath();
      var yy = -5.4 * s + i * 2.6 * s;
      ctx.moveTo(-28 * s + i * 5 * s, yy);
      ctx.lineTo(-16 * s + i * 9 * s, yy + 1);
      ctx.stroke();
    }
    /* moss strip on top */
    ctx.fillStyle = 'rgba(52,88,52,0.5)';
    rr(ctx, -22 * s, -7.4 * s, 30 * s, 2.6 * s, 1.3 * s);
    ctx.fill();
    ell(ctx, 34 * s, -1.5 * s, 3.4 * s, 5.5 * s, '#6b5430');
    ctx.strokeStyle = 'rgba(130,100,60,0.7)';
    ctx.beginPath(); ctx.ellipse(34 * s, -1.5 * s, 1.6 * s, 3 * s, 0, 0, T.TAU); ctx.stroke();
    /* broken branch stub */
    ctx.strokeStyle = '#2c2013';
    ctx.lineWidth = 2.4;
    ctx.beginPath(); ctx.moveTo(-8 * s, -6 * s); ctx.lineTo(-13 * s, -13 * s); ctx.stroke();
    ctx.restore();
  };
  A.bush = function (ctx, o, t) {
    var s = o.s || 1;
    shadow(ctx, o.x, o.y, 13 * s, 4 * s, 0.32);
    var sw = sway(o, t, 0.7 * s);
    ell(ctx, o.x - 5 * s, o.y - 5 * s, 9 * s, 7 * s, '#24402c');
    ell(ctx, o.x + 5 * s, o.y - 4 * s, 8 * s, 6 * s, '#1d3423');
    ell(ctx, o.x + sw, o.y - 9 * s, 9.4 * s, 7.4 * s, grad(ctx, 0, o.y - 17 * s, 0, o.y - 3 * s, [[0, '#35583c'], [1, '#1c2f1f']]));
    ctx.fillStyle = 'rgba(215,220,200,0.10)';
    ctx.beginPath();
    ctx.ellipse(o.x + 2 * s + sw, o.y - 13 * s, 3 * s, 1.4 * s, -0.4, 0, T.TAU);
    ctx.fill();
  };

  /* ============================================================
     CAMP / CABIN PROPS
     ============================================================ */
  A.crate = function (ctx, o) {
    var s = o.s || 1, w = 20 * s, h = 18 * s;
    shadow(ctx, o.x, o.y, 14 * s, 5 * s, 0.4);
    ctx.fillStyle = '#312413';
    ctx.fillRect(o.x - w / 2, o.y - h, w, h);
    ctx.fillStyle = '#4a3619';
    ctx.fillRect(o.x - w / 2, o.y - h - 6 * s, w, 6 * s);
    ctx.strokeStyle = 'rgba(24,17,9,0.6)';
    ctx.lineWidth = 1;
    ctx.strokeRect(o.x - w / 2, o.y - h, w, h);
    ctx.strokeStyle = 'rgba(160,124,66,0.4)';
    ctx.beginPath();
    ctx.moveTo(o.x - w / 2 + 2, o.y - h + 2); ctx.lineTo(o.x + w / 2 - 2, o.y - 2);
    ctx.moveTo(o.x + w / 2 - 2, o.y - h + 2); ctx.lineTo(o.x - w / 2 + 2, o.y - 2);
    ctx.stroke();
    ctx.fillStyle = 'rgba(0,0,0,0.25)';
    ctx.fillRect(o.x - w / 2, o.y - 3 * s, w, 3 * s);
  };
  A.barrel = function (ctx, o) {
    var s = o.s || 1;
    shadow(ctx, o.x, o.y, 11 * s, 4.5 * s, 0.4);
    ctx.fillStyle = grad(ctx, o.x - 9 * s, 0, o.x + 9 * s, 0, [[0, '#1d150b'], [0.45, '#4a3820'], [1, '#150f08']]);
    rr(ctx, o.x - 9 * s, o.y - 26 * s, 18 * s, 26 * s, 4 * s);
    ctx.fill();
    ctx.fillStyle = 'rgba(140,150,140,0.22)';
    ctx.fillRect(o.x - 9 * s, o.y - 19 * s, 18 * s, 2.4 * s);
    ctx.fillRect(o.x - 9 * s, o.y - 9 * s, 18 * s, 2.4 * s);
    ell(ctx, o.x, o.y - 26 * s, 9 * s, 3.6 * s, '#5c4826');
    ctx.strokeStyle = 'rgba(20,14,8,0.7)';
    ctx.beginPath(); ctx.ellipse(o.x, o.y - 26 * s, 6 * s, 2.2 * s, 0, 0, T.TAU); ctx.stroke();
  };
  A.logpile = function (ctx, o) {
    var s = o.s || 1;
    shadow(ctx, o.x, o.y, 24 * s, 6 * s, 0.4);
    var r = 5 * s;
    for (var row = 0; row < 2; row++) {
      var n = 4 - row;
      for (var i = 0; i < n; i++) {
        var x = o.x + (i - (n - 1) / 2) * r * 2.3;
        var y = o.y - r - row * r * 1.8;
        ell(ctx, x, y, r, r, '#2b1f10');
        ell(ctx, x - r * 0.18, y - r * 0.18, r * 0.62, r * 0.62, '#54401f');
        ctx.fillStyle = 'rgba(20,14,8,0.6)';
        ctx.fillRect(x + r * 0.2, y - r * 0.5, r * 1.5, r); /* log body peek */
      }
    }
    /* moss on top logs */
    ctx.fillStyle = 'rgba(58,96,56,0.5)';
    ctx.beginPath();
    ctx.ellipse(o.x - 3 * s, o.y - 3.4 * r, 5 * s, 1.8 * s, -0.2, 0, T.TAU);
    ctx.fill();
  };
  A.table = function (ctx, o) {
    var s = o.s || 1;
    shadow(ctx, o.x, o.y, 20 * s, 6 * s, 0.35);
    ctx.fillStyle = '#241809';
    ctx.fillRect(o.x - 14 * s, o.y - 12 * s, 3 * s, 12 * s);
    ctx.fillRect(o.x + 11 * s, o.y - 12 * s, 3 * s, 12 * s);
    ctx.fillStyle = grad(ctx, 0, o.y - 20 * s, 0, o.y - 10 * s, [[0, '#54401f'], [1, '#2c1f0e']]);
    rr(ctx, o.x - 18 * s, o.y - 18 * s, 36 * s, 9 * s, 2 * s);
    ctx.fill();
    ctx.strokeStyle = 'rgba(210,190,150,0.10)';
    ctx.beginPath(); ctx.moveTo(o.x - 16 * s, o.y - 16.4 * s); ctx.lineTo(o.x + 16 * s, o.y - 16.4 * s); ctx.stroke();
  };
  A.planks = function (ctx, o) {
    var s = o.s || 1;
    shadow(ctx, o.x, o.y, 18 * s, 5 * s, 0.3);
    ctx.save();
    ctx.translate(o.x, o.y);
    ctx.rotate(o.rot || 0);
    for (var i = 0; i < 3; i++) {
      ctx.fillStyle = i % 2 ? '#4a381e' : '#382a14';
      ctx.fillRect(-16 * s + i * 3 * s, -3 * s + i * 3 * s, 32 * s, 4 * s);
      ctx.strokeStyle = 'rgba(20,14,8,0.5)';
      ctx.strokeRect(-16 * s + i * 3 * s, -3 * s + i * 3 * s, 32 * s, 4 * s);
    }
    ctx.restore();
  };
  A.tent = function (ctx, o) {
    var s = o.s || 1;
    shadow(ctx, o.x, o.y, 31 * s, 10 * s, 0.45);
    /* guy ropes */
    ctx.strokeStyle = 'rgba(150,158,148,0.22)';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(o.x - 3 * s, o.y - 40 * s); ctx.lineTo(o.x - 40 * s, o.y + 6 * s);
    ctx.moveTo(o.x - 3 * s, o.y - 40 * s); ctx.lineTo(o.x + 26 * s, o.y + 9 * s);
    ctx.stroke();
    ctx.fillStyle = '#0c0f0d';
    ctx.fillRect(o.x - 41 * s, o.y + 4 * s, 3 * s, 3.4 * s);
    ctx.fillRect(o.x + 25 * s, o.y + 7 * s, 3 * s, 3.4 * s);
    /* body */
    ctx.fillStyle = grad(ctx, o.x - 30 * s, 0, o.x + 30 * s, 0, [[0, '#3f5449'], [0.5, '#2c3d33'], [1, '#17221c']]);
    ctx.beginPath();
    ctx.moveTo(o.x - 28 * s, o.y);
    ctx.quadraticCurveTo(o.x - 17 * s, o.y - 22 * s, o.x - 3 * s, o.y - 40 * s);
    ctx.quadraticCurveTo(o.x + 14 * s, o.y - 20 * s, o.x + 30 * s, o.y - 2 * s);
    ctx.lineTo(o.x + 24 * s, o.y + 2 * s);
    ctx.quadraticCurveTo(o.x, o.y + 5 * s, o.x - 28 * s, o.y);
    ctx.fill();
    /* seam + sag */
    ctx.strokeStyle = 'rgba(200,210,198,0.16)';
    ctx.beginPath();
    ctx.moveTo(o.x - 3 * s, o.y - 40 * s);
    ctx.quadraticCurveTo(o.x + 13 * s, o.y - 22 * s, o.x + 30 * s, o.y - 2 * s);
    ctx.stroke();
    ctx.strokeStyle = 'rgba(10,14,10,0.6)';
    ctx.beginPath();
    ctx.moveTo(o.x - 14 * s, o.y - 20 * s);
    ctx.quadraticCurveTo(o.x - 8 * s, o.y - 14 * s, o.x - 2 * s, o.y - 17 * s);
    ctx.stroke();
    /* opening */
    ctx.fillStyle = '#080c0a';
    ctx.beginPath();
    ctx.moveTo(o.x + 2 * s, o.y - 1);
    ctx.lineTo(o.x - 6 * s, o.y - 26 * s);
    ctx.lineTo(o.x - 14 * s, o.y - 1);
    ctx.closePath();
    ctx.fill();
  };
  A.sign = function (ctx, o) {
    var s = o.s || 1;
    var tilt = (sj(o, 8) - 0.5) * 0.14;
    shadow(ctx, o.x, o.y, 8 * s, 3.5 * s, 0.35);
    ctx.save();
    ctx.translate(o.x, o.y);
    ctx.rotate(tilt);
    ctx.fillStyle = grad(ctx, -2 * s, 0, 2 * s, 0, [[0, '#3a2b16'], [1, '#171006']]);
    ctx.fillRect(-2 * s, -34 * s, 4 * s, 34 * s);
    ctx.save();
    ctx.translate(0, -30 * s);
    ctx.rotate(o.dir || -0.2);
    ctx.fillStyle = '#4a3618';
    ctx.beginPath();
    ctx.moveTo(-14 * s, -4 * s); ctx.lineTo(10 * s, -4 * s); ctx.lineTo(16 * s, 0);
    ctx.lineTo(10 * s, 4 * s); ctx.lineTo(-14 * s, 4 * s);
    ctx.closePath(); ctx.fill();
    ctx.strokeStyle = 'rgba(215,210,190,0.4)';
    ctx.beginPath(); ctx.moveTo(-11 * s, 0); ctx.lineTo(4 * s, 0); ctx.stroke();
    ctx.restore();
    ctx.save();
    ctx.translate(0, -18 * s);
    ctx.rotate(-(o.dir || -0.2) + 0.35);
    ctx.fillStyle = '#33250f';
    ctx.beginPath();
    ctx.moveTo(12 * s, -3.4 * s); ctx.lineTo(-8 * s, -3.4 * s); ctx.lineTo(-14 * s, 0);
    ctx.lineTo(-8 * s, 3.4 * s); ctx.lineTo(12 * s, 3.4 * s);
    ctx.closePath(); ctx.fill();
    ctx.restore();
    ctx.restore();
  };
  A.fence = function (ctx, o) {
    var s = o.s || 1;
    ctx.save();
    ctx.translate(o.x, o.y);
    ctx.rotate(o.rot || 0);
    shadow(ctx, 0, 2 * s, 26 * s, 5 * s, 0.3);
    ctx.fillStyle = '#332411';
    ctx.fillRect(-22 * s, -34 * s, 4.4 * s, 34 * s);
    ctx.fillRect(16 * s, -30 * s, 4.4 * s, 30 * s);
    ctx.save();
    ctx.rotate(-0.12);
    ctx.fillStyle = '#452f16';
    ctx.fillRect(-24 * s, -28 * s, 46 * s, 4.6 * s);
    ctx.fillStyle = '#3a2813';
    ctx.fillRect(-24 * s, -14 * s, 46 * s, 4.2 * s);
    ctx.restore();
    ctx.restore();
  };

  /* ---------- fire ---------- */
  A.firepit = function (ctx, o, t) {
    shadow(ctx, o.x, o.y, 25, 10, 0.35);
    for (var i = 0; i < 8; i++) {
      var a = i / 8 * T.TAU + sj(o, 3);
      var x = o.x + Math.cos(a) * 17, y = o.y + Math.sin(a) * 8.4;
      ell(ctx, x, y, 5.2, 3.6, i % 2 ? '#39413b' : '#2c332e');
      ell(ctx, x, y - 1.4, 5.2, 3.6, i % 2 ? '#6a746b' : '#586157');
      if (i % 3 === 0) { ctx.fillStyle = 'rgba(46,74,48,0.5)'; ctx.beginPath(); ctx.ellipse(x - 2, y + 1, 2.4, 1, 0, 0, T.TAU); ctx.fill(); }
    }
    ell(ctx, o.x, o.y, 13.4, 6.6, '#171410');
    ell(ctx, o.x, o.y - 1, 11, 5.2, '#454238');
    ctx.fillStyle = 'rgba(210,205,185,0.10)';
    ctx.beginPath(); ctx.ellipse(o.x - 3, o.y - 2, 4, 1.4, 0.4, 0, T.TAU); ctx.fill();
    ctx.fillStyle = '#332513';
    ctx.save();
    ctx.translate(o.x, o.y - 2);
    for (var k = 0; k < 3; k++) {
      ctx.save();
      ctx.rotate(k * 1.05 + 0.3);
      ctx.fillRect(-10, -1.6, 20, 3.2);
      ctx.restore();
    }
    ctx.restore();
    if (o.lit) A.flames(ctx, o.x, o.y - 4, t, 1);
  };
  A.flames = function (ctx, x, y, t, scale) {
    var s = scale || 1;
    ctx.save();
    ctx.globalCompositeOperation = 'lighter';
    for (var i = 0; i < 3; i++) {
      var f = Math.sin(t * (9 + i * 4) + i * 2.1);
      var fx = x + (i - 1) * 4.6 * s + f * 1.6;
      var h = (15 + f * 3.6 + i * 2) * s * (0.8 + Math.sin(t * 13 + i) * 0.16);
      var w = (5.6 - i * 0.9) * s;
      ctx.fillStyle = [C.fire, '#e0a45c', '#f2d9a2'][i];
      ctx.globalAlpha = [0.22, 0.3, 0.5][i];
      ctx.beginPath();
      ctx.moveTo(fx - w, y);
      ctx.quadraticCurveTo(fx - w * 0.6, y - h * 0.55, fx + f * 1.4, y - h);
      ctx.quadraticCurveTo(fx + w * 0.7, y - h * 0.5, fx + w, y);
      ctx.closePath();
      ctx.fill();
    }
    ctx.fillStyle = '#e6a75f';
    for (var e = 0; e < 6; e++) {
      var ph = (t * 0.6 + e * 0.37) % 1;
      ctx.globalAlpha = 0.5 * (1 - ph);
      ctx.fillRect(x + Math.sin(e * 3.7 + t * 2.4) * 8 * s, y - ph * 34 * s, 1.4, 1.4);
    }
    ctx.restore();
  };

  /* ============================================================
     CABIN  (porch, shingles, chimney)
     ============================================================ */
  A.cabin = function (ctx, o, t) {
    var w = 100, wallH = 46, roof = 58;
    shadow(ctx, o.x, o.y, w + 14, 16, 0.5);
    /* front wall */
    ctx.fillStyle = grad(ctx, 0, o.y - wallH, 0, o.y, [[0, '#50402b'], [0.7, '#3a2e1e'], [1, '#241b10']]);
    ctx.fillRect(o.x - w, o.y - wallH, w * 2, wallH);
    /* plank lines + nail glints */
    ctx.strokeStyle = 'rgba(18,12,6,0.55)';
    ctx.lineWidth = 1;
    for (var i = 1; i < 5; i++) {
      ctx.beginPath();
      ctx.moveTo(o.x - w, o.y - wallH + i * 9.4);
      ctx.lineTo(o.x + w, o.y - wallH + i * 9.4);
      ctx.stroke();
      ctx.fillStyle = 'rgba(220,210,180,0.10)';
      for (var g2 = 0; g2 < 6; g2++) ctx.fillRect(o.x - w + 14 + g2 * 30, o.y - wallH + i * 9.4 - 2.2, 1.4, 1.4);
    }
    /* vertical corner posts */
    ctx.fillStyle = '#2c2213';
    ctx.fillRect(o.x - w, o.y - wallH, 6, wallH);
    ctx.fillRect(o.x + w - 6, o.y - wallH, 6, wallH);
    /* door: ajar, dark inside */
    ctx.fillStyle = '#0c0906';
    rr(ctx, o.x - 13, o.y - 34, 26, 34, 2);
    ctx.fill();
    ctx.fillStyle = 'rgba(5,6,5,0.9)';
    ctx.fillRect(o.x - 11, o.y - 32, 15, 32);
    ctx.save();
    ctx.translate(o.x + 4, o.y - 34);
    ctx.fillStyle = '#3d2c17';
    ctx.beginPath();
    ctx.moveTo(0, 0); ctx.lineTo(9, 2); ctx.lineTo(9, 34); ctx.lineTo(0, 34);
    ctx.closePath(); ctx.fill();
    ctx.fillStyle = 'rgba(215,208,183,0.5)';
    ctx.fillRect(2, 18, 1.6, 1.6);
    ctx.restore();
    /* symbol scratched on the frame */
    ctx.save();
    ctx.translate(o.x + 19, o.y - 24);
    ctx.strokeStyle = 'rgba(230,222,190,0.55)';
    ctx.lineWidth = 1.1;
    ctx.beginPath();
    for (var g = 0; g < 3; g++) { ctx.moveTo(-4, -6 + g * 3); ctx.lineTo(4, -6 + g * 3); }
    ctx.stroke();
    ctx.beginPath(); ctx.ellipse(0, 4, 3.6, 2, 0, 0, T.TAU); ctx.stroke();
    ctx.fillStyle = 'rgba(230,222,190,0.55)';
    ctx.fillRect(-0.7, 3.2, 1.4, 1.7);
    ctx.restore();
    /* window: cold by default, lamplit when somebody keeps a fire inside */
    var wx = o.x - 62, wy = o.y - 32, ww = 24, wh = 17;
    if (o.warm) {
      var wflick = 0.84 + 0.16 * Math.sin(t * 6.3 + 1.2) * Math.sin(t * 2.7);
      ctx.fillStyle = '#2a1b0b';
      ctx.fillRect(wx, wy, ww, wh);
      var mg = ctx.createRadialGradient(wx + ww * 0.42, wy + wh * 0.62, 1.6, wx + ww * 0.42, wy + wh * 0.62, ww);
      mg.addColorStop(0, 'rgba(248,206,128,' + (0.92 * wflick).toFixed(2) + ')');
      mg.addColorStop(0.55, 'rgba(212,138,62,' + (0.6 * wflick).toFixed(2) + ')');
      mg.addColorStop(1, 'rgba(110,62,24,0.28)');
      ctx.fillStyle = mg;
      ctx.fillRect(wx, wy, ww, wh);
      ctx.save();
      ctx.globalCompositeOperation = 'lighter';
      ctx.globalAlpha = 0.12 * wflick;
      ctx.fillStyle = '#d88a3c';
      ctx.beginPath();
      ctx.ellipse(wx + ww / 2, wy + wh / 2, ww * 2, wh * 2.2, 0, 0, T.TAU);
      ctx.fill();
      ctx.restore();
      /* a sliver of the same light out of the ajar door */
      ctx.fillStyle = 'rgba(222,158,88,' + (0.35 * wflick).toFixed(2) + ')';
      ctx.fillRect(o.x + 4, o.y - 32, 1.6, 30);
    } else {
      ctx.fillStyle = '#080c10';
      ctx.fillRect(wx, wy, ww, wh);
      var mgc = ctx.createLinearGradient(wx, wy, wx + ww, wy + wh);
      mgc.addColorStop(0, 'rgba(190,205,220,0.16)');
      mgc.addColorStop(0.5, 'rgba(150,165,180,0.04)');
      mgc.addColorStop(1, 'rgba(0,0,0,0)');
      ctx.fillStyle = mgc;
      ctx.fillRect(wx, wy, ww, wh);
    }
    ctx.strokeStyle = 'rgba(20,15,9,0.9)';
    ctx.strokeRect(o.x - 62, o.y - 32, 24, 17);
    ctx.beginPath();
    ctx.moveTo(o.x - 50, o.y - 32); ctx.lineTo(o.x - 50, o.y - 15);
    ctx.moveTo(o.x - 62, o.y - 23.5); ctx.lineTo(o.x - 38, o.y - 23.5);
    ctx.stroke();
    /* porch: beam + low step */
    ctx.fillStyle = '#1c1509';
    ctx.fillRect(o.x - 34, o.y - 2, 68, 5);
    ctx.fillStyle = '#332716';
    ctx.fillRect(o.x - 34, o.y - 36, 68, 4);
    ctx.fillStyle = '#241a0d';
    ctx.fillRect(o.x - 33, o.y - 36, 3.4, 36);
    ctx.fillRect(o.x + 29.6, o.y - 36, 3.4, 36);
    /* damage: broken boards low right */
    ctx.fillStyle = 'rgba(0,0,0,0.45)';
    ctx.fillRect(o.x + w - 16, o.y - 8, 16, 8);
    ctx.strokeStyle = 'rgba(200,205,196,0.10)';
    ctx.beginPath();
    ctx.moveTo(o.x + w - 30, o.y - wallH); ctx.lineTo(o.x + w - 18, o.y);
    ctx.stroke();
    /* roof with shingle rows */
    var topY = o.y - wallH - roof;
    ctx.fillStyle = grad(ctx, 0, topY, 0, o.y - wallH, [[0, '#2f2d24'], [1, '#15140e']]);
    ctx.beginPath();
    ctx.moveTo(o.x - w - 12, o.y - wallH + 2);
    ctx.lineTo(o.x - 10, topY);
    ctx.lineTo(o.x + w + 12, o.y - wallH + 2);
    ctx.closePath();
    ctx.fill();
    /* shingle rows on the big slope */
    ctx.strokeStyle = 'rgba(10,10,8,0.55)';
    ctx.lineWidth = 1;
    for (var r = 1; r <= 5; r++) {
      var pr = r / 6;
      var ry = topY + (o.y - wallH - 2 - topY) * pr;
      ctx.beginPath();
      ctx.moveTo(o.x - 10 + (o.x - 10 - (o.x - w - 12)) * 0 + (o.x - w - 12 - (o.x - 10)) * pr, ry);
      ctx.lineTo(o.x + w + 12, ry);
      ctx.stroke();
    }
    /* lit side of the roof */
    ctx.fillStyle = grad(ctx, 0, topY, 0, o.y - wallH, [[0, '#413e30'], [1, '#211f16']]);
    ctx.beginPath();
    ctx.moveTo(o.x - w - 12, o.y - wallH + 2);
    ctx.lineTo(o.x - 10, topY);
    ctx.lineTo(o.x - 7, topY + 3);
    ctx.lineTo(o.x - w - 4, o.y - wallH + 6);
    ctx.closePath();
    ctx.fill();
    /* ridge */
    ctx.strokeStyle = 'rgba(210,214,204,0.28)';
    ctx.lineWidth = 1.5;
    ctx.beginPath();
    ctx.moveTo(o.x - 10, topY);
    ctx.lineTo(o.x + w + 12, o.y - wallH + 2);
    ctx.stroke();
    /* eaves shadow line over the wall */
    ctx.fillStyle = '#0e0b07';
    ctx.fillRect(o.x - w - 12, o.y - wallH + 2, (w + 12) * 2, 4);
    /* chimney with smoke hint */
    ctx.fillStyle = '#211b14';
    ctx.fillRect(o.x + 44, topY - 16, 15, 24);
    ctx.fillStyle = '#3a332a';
    ctx.fillRect(o.x + 44, topY - 16, 15, 4);
    ctx.globalAlpha = 0.06;
    ctx.fillStyle = '#b9c4bd';
    for (var sm = 0; sm < 3; sm++) {
      var ph2 = (t * 0.05 + sm * 0.33) % 1;
      ctx.beginPath();
      ctx.ellipse(o.x + 52 + Math.sin(ph2 * 5) * 5, topY - 20 - ph2 * 34, 6 + ph2 * 9, 3.4 + ph2 * 5, 0, 0, T.TAU);
      ctx.fill();
    }
    ctx.globalAlpha = 1;
    /* woodpile against the wall */
    shadow(ctx, o.x - 78, o.y, 16, 5, 0.3);
    for (var lp = 0; lp < 3; lp++) {
      ell(ctx, o.x - 88 + (lp % 2) * 7, o.y - 4 - Math.floor(lp / 2) * 6, 3.4, 3.4, '#2b1f10');
      ell(ctx, o.x - 88 + (lp % 2) * 7 - 0.6, o.y - 4.6 - Math.floor(lp / 2) * 6, 2, 2, '#54401f');
    }
  };

  /* ============================================================
     THE CAR
     ============================================================ */
  A.car = function (ctx, o) {
    ctx.save();
    ctx.translate(o.x, o.y);
    ctx.rotate(o.rot || 0);
    shadow(ctx, 0, 7, 45, 17, 0.5);
    ctx.fillStyle = '#0d0f0e';
    [[-26, -18], [-26, 18], [26, -18], [26, 18]].forEach(function (p) {
      rr(ctx, p[0] - 7, p[1] - 4.5, 14, 9, 3); ctx.fill();
    });
    var body = grad(ctx, 0, -22, 0, 22, [[0, '#69756c'], [0.45, '#414c46'], [0.75, '#262f2b'], [1, '#151b19']]);
    ctx.fillStyle = body;
    rr(ctx, -40, -16, 80, 32, 9);
    ctx.fill();
    /* panel line + door */
    ctx.strokeStyle = 'rgba(15,18,16,0.6)';
    ctx.lineWidth = 1;
    ctx.beginPath(); ctx.moveTo(-40, 0); ctx.lineTo(40, 0); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(-2, -16); ctx.lineTo(-2, 16); ctx.stroke();
    /* moss on roof edge */
    ctx.fillStyle = 'rgba(56,92,56,0.4)';
    ctx.beginPath(); ctx.ellipse(4, -12, 13, 3, 0, 0, T.TAU); ctx.fill();
    /* rust patches */
    var r = T.rng(Math.floor(o.x) * 31 + Math.floor(o.y));
    for (var i = 0; i < 10; i++) {
      ctx.fillStyle = 'rgba(112,66,32,' + (0.16 + r() * 0.2).toFixed(3) + ')';
      ctx.beginPath();
      ctx.ellipse(-36 + r() * 72, -13 + r() * 26, 2 + r() * 5.4, 1.6 + r() * 3, r() * 3, 0, T.TAU);
      ctx.fill();
    }
    /* cabin + glass */
    ctx.fillStyle = '#2c3431';
    rr(ctx, -14, -13, 24, 26, 5); ctx.fill();
    ctx.fillStyle = 'rgba(190,210,222,0.22)';
    rr(ctx, 10, -12, 7, 24, 3); ctx.fill();
    ctx.fillStyle = 'rgba(190,210,222,0.12)';
    ctx.beginPath();
    ctx.moveTo(-14, -13); ctx.lineTo(-23, -9); ctx.lineTo(-23, 9); ctx.lineTo(-14, 13);
    ctx.closePath(); ctx.fill();
    /* cracked windshield lines */
    ctx.strokeStyle = 'rgba(220,230,235,0.3)';
    ctx.lineWidth = 0.7;
    ctx.beginPath();
    ctx.moveTo(-18, -6); ctx.lineTo(-24, -1); ctx.lineTo(-20, 4);
    ctx.moveTo(-21, -8); ctx.lineTo(-17, 2);
    ctx.stroke();
    /* fallen branch across the hood */
    ctx.strokeStyle = '#33261a';
    ctx.lineWidth = 2;
    ctx.beginPath(); ctx.moveTo(20, -18); ctx.lineTo(34, -2); ctx.stroke();
    ctx.lineWidth = 1;
    ctx.beginPath(); ctx.moveTo(27, -9); ctx.lineTo(32, -14); ctx.stroke();
    /* lights */
    ctx.fillStyle = '#0b0d0d';
    rr(ctx, 24, -14, 8, 7, 2); ctx.fill();
    ctx.fillStyle = 'rgba(228,220,182,0.5)';
    rr(ctx, 24, 7, 8, 7, 2); ctx.fill();
    /* sun glint on the fender */
    ctx.strokeStyle = 'rgba(220,230,225,0.18)';
    ctx.lineWidth = 1.4;
    ctx.beginPath(); ctx.moveTo(-36, -13); ctx.lineTo(36, -13); ctx.stroke();
    ctx.restore();
  };

  /* ============================================================
     FINAL POINT
     ============================================================ */
  /* ============================================================
     THE QUARRY CRANE — rusted lattice derrick bent over the water
     ============================================================ */
  A.crane = function (ctx, o, t) {
    t = t || 0;
    var x = o.x, y = o.y;
    shadow(ctx, x, y, 22, 8, 0.5);
    /* pedestal */
    ctx.fillStyle = grad(ctx, 0, y - 26, 0, y, [[0, '#3c403c'], [1, '#141714']]);
    rr(ctx, x - 13, y - 26, 26, 28, 2); ctx.fill();
    ctx.fillStyle = 'rgba(120,116,100,0.14)';
    ctx.fillRect(x - 13, y - 24, 26, 1.4);
    /* the tower: two legs + lattice rungs, leaning toward the pit */
    var topX = x - 26, topY = y - 92;
    ctx.strokeStyle = '#43483f';
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.moveTo(x - 8, y - 26); ctx.lineTo(topX - 5, topY);
    ctx.moveTo(x + 8, y - 26); ctx.lineTo(topX + 5, topY);
    ctx.stroke();
    ctx.strokeStyle = 'rgba(105,110,98,0.75)';
    ctx.lineWidth = 1.4;
    ctx.beginPath();
    for (var i = 0; i < 5; i++) {
      var tA = i / 4;
      var lx = x - 8 + (topX - 5 - (x - 8)) * tA, ly = y - 26 + (topY - (y - 26)) * tA;
      var rx2 = x + 8 + (topX + 5 - (x + 8)) * tA, ry2 = ly;
      ctx.moveTo(lx, ly); ctx.lineTo(rx2, ry2 - 7);
      ctx.moveTo(rx2, ry2); ctx.lineTo(lx, ly - 7);
    }
    ctx.stroke();
    /* jib over the water */
    var jx = x - 96, jy = y - 74;
    ctx.strokeStyle = '#4b5047';
    ctx.lineWidth = 3.2;
    ctx.beginPath();
    ctx.moveTo(topX, topY + 2); ctx.lineTo(jx, jy);
    ctx.moveTo(topX + 2, topY + 9); ctx.lineTo(jx, jy + 6);
    ctx.stroke();
    ctx.strokeStyle = 'rgba(105,110,98,0.6)';
    ctx.lineWidth = 1.1;
    ctx.beginPath();
    for (var j = 0.1; j < 1; j += 0.18) {
      ctx.moveTo(topX + (jx - topX) * j, topY + 2 + (jy - topY - 2) * j);
      ctx.lineTo(topX + (jx - topX) * (j + 0.09), topY + 9 + (jy + 6 - topY - 9) * (j + 0.09));
    }
    ctx.stroke();
    /* counter-jib with a weight */
    ctx.strokeStyle = '#4b5047';
    ctx.lineWidth = 2.4;
    ctx.beginPath();
    ctx.moveTo(topX, topY + 4); ctx.lineTo(x + 26, y - 84);
    ctx.stroke();
    ctx.fillStyle = '#26291f';
    rr(ctx, x + 20, y - 82, 13, 12, 2); ctx.fill();
    /* cable down into the dark + hook */
    ctx.strokeStyle = 'rgba(140,142,130,0.5)';
    ctx.lineWidth = 1;
    var swayC = Math.sin(t * 0.5 + 2) * 1.4;
    ctx.beginPath();
    ctx.moveTo(jx, jy + 3);
    ctx.quadraticCurveTo(jx + swayC, jy + 34, jx + 1 + swayC, jy + 58);
    ctx.stroke();
    ctx.strokeStyle = '#7d8274';
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.arc(jx + 2 + swayC, jy + 62, 4, -0.2, Math.PI * 0.8);
    ctx.stroke();
    /* rust streaks */
    ctx.fillStyle = 'rgba(112,64,32,0.22)';
    ctx.fillRect(x - 4, y - 60, 2.4, 18);
    ctx.fillRect(x - 16, y - 44, 2, 12);
  };

  /* ============================================================
     THE RADIO TOWER — mast, guy wires, a red blinking beacon
     ============================================================ */
  A.tower = function (ctx, o, t) {
    var x = o.x, y = o.y;
    var HGT = 148;
    shadow(ctx, x, y, 26, 8, 0.45);
    /* guy wires */
    ctx.strokeStyle = 'rgba(150,156,146,0.16)';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(x, y - HGT + 26); ctx.lineTo(x - 52, y + 16);
    ctx.moveTo(x, y - HGT + 26); ctx.lineTo(x + 52, y + 16);
    ctx.moveTo(x, y - HGT + 54); ctx.lineTo(x - 44, y + 22);
    ctx.stroke();
    /* three legs, tapering */
    ctx.strokeStyle = '#484d46';
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.moveTo(x - 17, y); ctx.lineTo(x - 3.4, y - HGT);
    ctx.moveTo(x + 17, y); ctx.lineTo(x + 3.4, y - HGT);
    ctx.moveTo(x + 1, y + 4); ctx.lineTo(x, y - HGT);
    ctx.stroke();
    /* lattice rungs + X bracing */
    ctx.strokeStyle = 'rgba(122,128,118,0.6)';
    ctx.lineWidth = 1.2;
    ctx.beginPath();
    for (var i = 0; i < 7; i++) {
      var p = i / 6;
      var ly = y - 8 - p * (HGT - 16);
      var hw = 17 - p * 13.6;
      ctx.moveTo(x - hw, ly); ctx.lineTo(x + hw, ly);
      if (i < 6) {
        var hw2 = 17 - (p + 1 / 6) * 13.6, ly2 = ly - (HGT - 16) / 6;
        ctx.moveTo(x - hw, ly); ctx.lineTo(x + hw2, ly2);
        ctx.moveTo(x + hw, ly); ctx.lineTo(x - hw2, ly2);
      }
    }
    ctx.stroke();
    /* paint bands near the top */
    for (var b = 0; b < 3; b++) {
      ctx.fillStyle = b % 2 ? '#484d46' : '#5c3430';
      ctx.fillRect(x - 4.6, y - HGT + 2 + b * 7, 9.2, 7);
    }
    /* mast head + red beacon */
    ctx.strokeStyle = '#565b52';
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(x, y - HGT); ctx.lineTo(x, y - HGT - 22);
    ctx.stroke();
    ctx.strokeStyle = 'rgba(150,156,146,0.5)';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(x - 5, y - HGT - 16); ctx.lineTo(x + 5, y - HGT - 16);
    ctx.stroke();
    var bl = 0.5 + 0.5 * Math.sin(t * 2.4 + (o.ph || 0));
    var on = bl > 0.72;
    ctx.fillStyle = on ? '#ff5640' : '#5c201c';
    ctx.beginPath();
    ctx.arc(x, y - HGT - 26, 2.4, 0, T.TAU);
    ctx.fill();
    if (on) {
      ctx.save();
      ctx.globalCompositeOperation = 'lighter';
      var ga = (bl - 0.72) / 0.28;
      ctx.globalAlpha = 0.34 * ga;
      var rg = ctx.createRadialGradient(x, y - HGT - 26, 1, x, y - HGT - 26, 34);
      rg.addColorStop(0, 'rgba(255,80,60,0.9)');
      rg.addColorStop(1, 'rgba(255,80,60,0)');
      ctx.fillStyle = rg;
      ctx.fillRect(x - 34, y - HGT - 60, 68, 68);
      ctx.restore();
    }
  };

  /* ============================================================
     THE WORKER HUT by the tower
     ============================================================ */
  A.hut = function (ctx, o) {
    var x = o.x, y = o.y;
    shadow(ctx, x, y + 2, 36, 8, 0.5);
    /* body */
    ctx.fillStyle = grad(ctx, 0, y - 30, 0, y, [[0, '#3f4436'], [1, '#1c2019']]);
    ctx.fillRect(x - 30, y - 30, 60, 32);
    ctx.strokeStyle = 'rgba(14,16,12,0.6)';
    ctx.lineWidth = 1;
    for (var i = 1; i < 4; i++) {
      ctx.beginPath();
      ctx.moveTo(x - 30, y - 30 + i * 8);
      ctx.lineTo(x + 30, y - 30 + i * 8);
      ctx.stroke();
    }
    /* single-slope roof, slightly rusty */
    ctx.fillStyle = grad(ctx, 0, y - 44, 0, y - 28, [[0, '#4a4739'], [1, '#23211a']]);
    ctx.beginPath();
    ctx.moveTo(x - 34, y - 28); ctx.lineTo(x - 28, y - 44);
    ctx.lineTo(x + 34, y - 40); ctx.lineTo(x + 32, y - 28);
    ctx.closePath();
    ctx.fill();
    ctx.strokeStyle = 'rgba(200,206,196,0.16)';
    ctx.beginPath();
    ctx.moveTo(x - 28, y - 44); ctx.lineTo(x + 34, y - 40);
    ctx.stroke();
    /* door and dark window */
    ctx.fillStyle = '#100d08';
    rr(ctx, x - 24, y - 24, 13, 26, 1.4); ctx.fill();
    ctx.fillStyle = 'rgba(180,170,140,0.3)';
    ctx.fillRect(x - 13.6, y - 12, 1.4, 1.4);
    ctx.fillStyle = '#0a0d10';
    ctx.fillRect(x + 6, y - 22, 16, 11);
    ctx.strokeStyle = 'rgba(16,13,8,0.9)';
    ctx.strokeRect(x + 6, y - 22, 16, 11);
    ctx.beginPath();
    ctx.moveTo(x + 14, y - 22); ctx.lineTo(x + 14, y - 11);
    ctx.stroke();
    /* flue + a cable strung to the mast */
    ctx.strokeStyle = '#2d3029';
    ctx.lineWidth = 2.4;
    ctx.beginPath();
    ctx.moveTo(x + 28, y - 40); ctx.lineTo(x + 28, y - 52);
    ctx.stroke();
    ctx.strokeStyle = 'rgba(150,156,146,0.22)';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(x + 28, y - 50);
    ctx.quadraticCurveTo(x + 60, y - 44, x + 96, y - 60);
    ctx.stroke();
    /* crate life */
    ctx.fillStyle = '#2b2113';
    rr(ctx, x + 12, y - 2, 12, 8, 1.4); ctx.fill();
  };

  /* ============================================================
     THE PIER LAMP
     ============================================================ */
  A.lamp = function (ctx, o, t) {
    var x = o.x, y = o.y;
    shadow(ctx, x, y, 7, 3, 0.4);
    /* post, slightly leaned into the lake wind */
    ctx.strokeStyle = '#241c10';
    ctx.lineWidth = 3.4;
    ctx.beginPath();
    ctx.moveTo(x, y);
    ctx.quadraticCurveTo(x - 1.6, y - 18, x - 2, y - 30);
    ctx.stroke();
    ctx.strokeStyle = '#3b2f1a';
    ctx.lineWidth = 1.4;
    ctx.beginPath();
    ctx.moveTo(x - 9, y - 30); ctx.lineTo(x + 5, y - 31);
    ctx.stroke();
    /* lantern head */
    var lx = x - 2, ly = y - 36;
    ctx.fillStyle = '#4c5148';
    ctx.beginPath();
    ctx.moveTo(lx - 4.6, ly - 4); ctx.lineTo(lx + 4.6, ly - 4);
    ctx.lineTo(lx + 3.4, ly + 7); ctx.lineTo(lx - 3.4, ly + 7);
    ctx.closePath();
    ctx.fill();
    ctx.fillStyle = '#20241f';
    ctx.fillRect(lx - 5.2, ly - 5.4, 10.4, 2);
    var fl = 0.78 + 0.22 * Math.sin(t * 8.7) * Math.sin(t * 3.3 + 1);
    ctx.fillStyle = 'rgba(248,214,138,' + (0.9 * fl).toFixed(2) + ')';
    ctx.fillRect(lx - 2.6, ly - 2.4, 5.2, 7.6);
    ctx.save();
    ctx.globalCompositeOperation = 'lighter';
    ctx.globalAlpha = 0.4 * fl;
    var rg = ctx.createRadialGradient(lx, ly + 1, 1, lx, ly + 1, 26);
    rg.addColorStop(0, 'rgba(240,190,110,0.85)');
    rg.addColorStop(1, 'rgba(240,190,110,0)');
    ctx.fillStyle = rg;
    ctx.fillRect(lx - 26, ly - 25, 52, 52);
    ctx.restore();
  };

  A.cross = function (ctx, o) {
    shadow(ctx, o.x, o.y, 12, 5, 0.4);
    ell(ctx, o.x, o.y - 2, 11, 5, '#525b54');
    ell(ctx, o.x - 2, o.y - 4, 8, 3.4, '#78837a');
    ctx.save();
    ctx.translate(o.x, o.y - 4);
    ctx.rotate(0.12);
    ctx.fillStyle = '#332511';
    ctx.fillRect(-2.2, -30, 4.4, 30);
    ctx.fillRect(-10, -22, 20, 3.6);
    ctx.fillStyle = 'rgba(210,205,180,0.2)';
    ctx.fillRect(-2.2, -30, 1.4, 30);
    ctx.restore();
    /* tied rag on the cross arm */
    ctx.fillStyle = 'rgba(180,176,158,0.22)';
    ctx.beginPath();
    ctx.moveTo(o.x + 9, o.y - 26);
    ctx.quadraticCurveTo(o.x + 14, o.y - 22, o.x + 11, o.y - 16);
    ctx.quadraticCurveTo(o.x + 8, o.y - 20, o.x + 9, o.y - 26);
    ctx.fill();
  };

  /* ---------- note on the ground ---------- */
  A.note = function (ctx, o, t) {
    var bob = Math.sin(t * 1.6 + o.idx) * 0.6;
    ctx.save();
    ctx.translate(o.x, o.y + bob);
    ctx.rotate(o.rot);
    ctx.globalAlpha = 0.35;
    ctx.fillStyle = '#000';
    ctx.fillRect(-8.4, -5.4, 19, 13);
    ctx.globalAlpha = 1;
    ctx.fillStyle = '#ddd6ba';
    rr(ctx, -9, -6, 18, 12, 1.4); ctx.fill();
    ctx.fillStyle = 'rgba(90,84,60,0.55)';
    for (var i = 0; i < 3; i++) ctx.fillRect(-6, -3 + i * 3, 12 - i * 3, 0.9);
    ctx.fillStyle = 'rgba(60,55,40,0.3)';
    ctx.fillRect(-9, -6, 18, 1.6);
    ctx.restore();
  };

  /* ============================================================
     PLAYER — detailed little wanderer
     ============================================================ */
  A.player = function (ctx, p, t) {
    var moving = p.moving;
    var cyc = p.walk * T.TAU;
    var fx = Math.cos(p.fa), fy = Math.sin(p.fa);
    var bx = -fy, by = fx;
    var step = moving ? Math.sin(cyc) : 0;
    var bob = moving ? Math.abs(Math.cos(cyc)) * 1.1 : Math.sin(t * 1.4) * 0.22;
    ctx.save();
    /* long soft shadow */
    ctx.globalAlpha = 0.5;
    ctx.fillStyle = '#000';
    ctx.beginPath();
    ctx.ellipse(p.x + 4, p.y + 3, 8.6, 3.4, 0, 0, T.TAU);
    ctx.fill();
    ctx.globalAlpha = 1;
    ctx.translate(p.x, p.y - bob);
    var front = fy > 0.55, back = fy < -0.55; /* walking toward/away */

    /* legs */
    for (var i = 0; i < 2; i++) {
      var sw = step * (i ? 3.2 : -3.2);
      var lx = (i ? 2.5 : -2.5) * bx + sw * fx * 0.8;
      var ly = (i ? 2.5 : -2.5) * by + sw * fy * 0.8;
      ctx.fillStyle = '#232723';
      ctx.beginPath();
      ctx.ellipse(lx, ly - 2.6, 2.6, 3.2, 0, 0, T.TAU);
      ctx.fill();
      ctx.fillStyle = '#0e100f';
      ctx.beginPath();
      ctx.ellipse(lx + fx * 1.7, ly - 2.6 + fy * 1.7, 2.1, 1.6, 0, 0, T.TAU);
      ctx.fill();
    }
    /* torso: jacket, slightly turned */
    ctx.fillStyle = grad(ctx, 0, -15, 0, -3, [[0, '#4c574f'], [0.65, '#333c36'], [1, '#1d2320']]);
    ctx.beginPath();
    ctx.ellipse(fx * 0.8, -8.6, 5.9, 6.8, Math.atan2(fy, fx) * 0.08, 0, T.TAU);
    ctx.fill();
    /* jacket hem + zipper */
    ctx.strokeStyle = 'rgba(15,18,16,0.8)';
    ctx.lineWidth = 0.8;
    ctx.beginPath();
    ctx.ellipse(fx * 0.8, -8.6, 5.9, 6.8, 0, 0.2, Math.PI - 0.2);
    ctx.stroke();
    if (!back) {
      ctx.strokeStyle = 'rgba(190,196,185,0.22)';
      ctx.beginPath();
      ctx.moveTo(fx * 2.4 + bx * 0.2, -14);
      ctx.lineTo(fx * 2.4, -4.2);
      ctx.stroke();
    }
    /* backpack (visible from behind/above) */
    var bpx = -fx * 4.4, bpy = -9.4 - fy * 1.2;
    if (back || Math.abs(fy) > 0.25) {
      ctx.fillStyle = '#2c2114';
      ctx.beginPath();
      ctx.ellipse(bpx, bpy, 3.5, 4.3, Math.atan2(fy, fx), 0, T.TAU);
      ctx.fill();
      ctx.strokeStyle = 'rgba(180,160,110,0.25)';
      ctx.beginPath();
      ctx.ellipse(bpx, bpy, 2.2, 2.8, Math.atan2(fy, fx), 0, T.TAU);
      ctx.stroke();
      ctx.fillStyle = '#c8b98a';
      ctx.fillRect(bpx - 1.4, bpy - 4.6, 2.8, 1.6); /* bedroll */
    }
    if (!back) {
      /* straps on chest */
      ctx.strokeStyle = 'rgba(60,44,26,0.9)';
      ctx.lineWidth = 1.1;
      ctx.beginPath();
      ctx.moveTo(fx * 1.6 + bx * 2.2, -13.2);
      ctx.lineTo(fx * 3 + bx * 1.2, -6.4);
      ctx.moveTo(fx * 1.6 - bx * 2.2, -13.2);
      ctx.lineTo(fx * 3 - bx * 1.2, -6.4);
      ctx.stroke();
    }
    /* head: hood + a sliver of face when walking toward us */
    var hx = fx * 1.5, hy = -16.6 + fy * 0.6;
    ctx.fillStyle = '#37413a';
    ctx.beginPath();
    ctx.ellipse(hx, hy, 3.7, 3.5, 0, 0, T.TAU);
    ctx.fill();
    ctx.fillStyle = '#232b26';
    ctx.beginPath();
    ctx.arc(hx - fx * 1.2, hy - 0.4 - fy * 0.6, 2.9, 0, T.TAU); /* hood bulk behind */
    ctx.fill();
    if (front) {
      ctx.fillStyle = '#8d7f6a';
      ctx.beginPath();
      ctx.ellipse(hx + fx * 1.2, hy + 0.5, 1.8, 1.5, 0, 0, T.TAU);
      ctx.fill();
    } else if (!back) {
      ctx.fillStyle = 'rgba(141,127,106,0.55)';
      ctx.beginPath();
      ctx.ellipse(hx + bx * 1.6 + fx, hy + 0.4, 1.1, 1.3, 0, 0, T.TAU);
      ctx.fill();
    }
    /* hood rim highlight */
    ctx.strokeStyle = 'rgba(200,206,196,0.16)';
    ctx.lineWidth = 0.7;
    ctx.beginPath();
    ctx.arc(hx, hy, 3.6, Math.PI * 0.85, Math.PI * 1.75);
    ctx.stroke();
    /* arms: left tucked, right holds the lantern */
    ctx.strokeStyle = '#2e352f';
    ctx.lineWidth = 1.9;
    ctx.lineCap = 'round';
    var swing = moving ? step * 1.4 : 0;
    ctx.beginPath();
    ctx.moveTo(fx * 1 - bx * 3.4, -11.6);
    ctx.lineTo(fx * 2.4 - bx * 4.6 + swing * fx, -7.4 + Math.abs(swing) * 0.3);
    ctx.stroke();
    var la = 6.6;
    var lx2 = fx * la + bx * 3.6, ly2 = -10.4 + fy * 2.4;
    ctx.beginPath();
    ctx.moveTo(fx * 1.4 + bx * 3.2, -11.8);
    ctx.lineTo(lx2, ly2);
    ctx.stroke();
    /* lantern: body + warm core */
    var lx3 = lx2 + fx * 1.2, ly3 = ly2 + 2.2 + (moving ? Math.sin(cyc * 2) * 0.35 : 0);
    ctx.fillStyle = '#6a716b';
    rr(ctx, lx3 - 1.8, ly3 - 1.2, 3.6, 4.6, 1.1);
    ctx.fill();
    ctx.strokeStyle = 'rgba(20,24,22,0.8)';
    ctx.lineWidth = 0.7;
    ctx.beginPath();
    ctx.moveTo(lx3 - 1.8, ly3 + 0.6); ctx.lineTo(lx3 + 1.8, ly3 + 0.6);
    ctx.moveTo(lx3, ly3 - 1.2); ctx.quadraticCurveTo(lx3 + 1.6, ly3 - 3, lx3 + 0.4, ly3 - 3.4);
    ctx.stroke();
    if (TLP.game && TLP.game.flash) {
      ctx.fillStyle = '#f6ecbf';
      ctx.beginPath();
      ctx.arc(lx3 + fx * 1.5, ly3 + 1.4, 1.9, 0, T.TAU);
      ctx.fill();
      ctx.save();
      ctx.globalCompositeOperation = 'lighter';
      ctx.globalAlpha = 0.5;
      ctx.fillStyle = 'rgba(214,198,140,0.5)';
      ctx.beginPath();
      ctx.arc(lx3 + fx * 1.5, ly3 + 1.4, 5.4, 0, T.TAU);
      ctx.fill();
      ctx.restore();
    }
    ctx.restore();
  };
  A.playerLanternPos = function (p) {
    var fx = Math.cos(p.fa), fy = Math.sin(p.fa);
    return { x: p.x + fx * 7.8 - fy * 3.6 * 0.2, y: p.y - 8.2 + fy * 2.4 };
  };

  /* ---------- the figure ---------- */
  A.figure = function (ctx, x, y, alpha, t) {
    ctx.save();
    ctx.globalAlpha = alpha;
    shadow(ctx, x, y, 9, 4, 0.55);
    ctx.fillStyle = '#04070a';
    ctx.fillRect(x - 3.4, y - 13, 2.8, 13);
    ctx.fillRect(x + 0.6, y - 13, 2.8, 13);
    ctx.beginPath();
    ctx.moveTo(x - 5.4, y - 11);
    ctx.quadraticCurveTo(x - 5.0, y - 30, x - 2.6, y - 34);
    ctx.lineTo(x + 2.6, y - 34);
    ctx.quadraticCurveTo(x + 5.0, y - 30, x + 5.4, y - 11);
    ctx.closePath();
    ctx.fill();
    ctx.beginPath();
    ctx.arc(x, y - 39, 4.4, 0, T.TAU);
    ctx.fill();
    /* rim from the firelight */
    ctx.strokeStyle = 'rgba(214,150,80,0.28)';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.arc(x, y - 39, 4.6, -0.6, 1.2);
    ctx.stroke();
    ctx.fillStyle = 'rgba(215,208,183,0.16)';
    ctx.fillRect(x - 1.8, y - 40, 1, 0.9);
    ctx.fillRect(x + 0.8, y - 40, 1, 0.9);
    ctx.restore();
  };

  /* ============================================================
     INTERIOR — the cabin's single room
     ============================================================ */
  A.wallH = function (ctx, o) {
    var h = o.h || 54, w = o.w;
    var top = o.y - h;
    ctx.fillStyle = grad(ctx, 0, top, 0, o.y, o.side === 'south'
      ? [[0, '#0a0806'], [0.25, '#241a10'], [1, '#3a2c19']]
      : [[0, '#463421'], [0.8, '#2c2013'], [1, '#171008']]);
    ctx.fillRect(o.x - w / 2, top, w, h);
    /* plank seams */
    ctx.strokeStyle = 'rgba(16,11,6,0.65)';
    ctx.lineWidth = 1;
    if (o.side !== 'south') {
      for (var i = 1; i < 4; i++) {
        ctx.beginPath();
        ctx.moveTo(o.x - w / 2, top + i * 14);
        ctx.lineTo(o.x + w / 2, top + i * 14);
        ctx.stroke();
      }
    }
    /* nail glints + top beam */
    ctx.fillStyle = 'rgba(215,208,183,0.12)';
    for (var g3 = 0; g3 < Math.floor(w / 40); g3++) {
      ctx.fillRect(o.x - w / 2 + 20 + g3 * 40, top + 5, 1.6, 1.6);
    }
    ctx.fillStyle = '#120c06';
    ctx.fillRect(o.x - w / 2, top - 3, w, 3.6);
    /* baseboard + floor shadow */
    ctx.fillStyle = 'rgba(0,0,0,0.5)';
    ctx.fillRect(o.x - w / 2, o.y - 3, w, 4);
    ctx.fillStyle = '#2c2012';
    ctx.fillRect(o.x - w / 2, o.y - (o.side === 'south' ? 8 : 4), w, o.side === 'south' ? 8 : 4);
  };
  A.wallV = function (ctx, o) {
    var w2 = o.w || 40, h = o.h;
    var top = o.y - h / 2, left = o.x - w2 / 2;
    ctx.fillStyle = grad(ctx, left, 0, left + w2, 0, o.side === 'left'
      ? [[0, '#3f2e1c'], [1, '#191108']]
      : [[0, '#191108'], [1, '#3c2c1a']]);
    ctx.fillRect(left, top, w2, h);
    ctx.strokeStyle = 'rgba(14,10,6,0.6)';
    for (var i = 1; i < Math.floor(h / 34); i++) {
      ctx.beginPath();
      ctx.moveTo(left, top + i * 34);
      ctx.lineTo(left + w2, top + i * 34);
      ctx.stroke();
    }
    ctx.fillStyle = 'rgba(0,0,0,0.4)';
    ctx.fillRect(o.side === 'left' ? left + w2 - 5 : left, top, 5, h);
  };
  A.windowIn = function (ctx, o, t) {
    var w2 = 84, h2 = 44;
    ctx.fillStyle = '#0a0704';
    rr(ctx, o.x - w2 / 2 - 5, o.y - h2 / 2 - 5, w2 + 10, h2 + 10, 3); ctx.fill();
    var g = ctx.createLinearGradient(o.x - w2 / 2, o.y - h2 / 2, o.x + w2 / 2, o.y + h2 / 2);
    g.addColorStop(0, 'rgba(150,168,182,0.34)');
    g.addColorStop(0.5, 'rgba(96,112,126,0.16)');
    g.addColorStop(1, 'rgba(40,52,64,0.10)');
    ctx.fillStyle = g;
    ctx.fillRect(o.x - w2 / 2, o.y - h2 / 2, w2, h2);
    /* tree silhouettes outside */
    ctx.fillStyle = 'rgba(8,12,12,0.55)';
    for (var i = 0; i < 4; i++) {
      var tx = o.x - w2 / 2 + 12 + i * 20 + Math.sin(t * 0.3 + i) * 0.8;
      ctx.beginPath();
      ctx.moveTo(tx - 5, o.y + h2 / 2);
      ctx.lineTo(tx, o.y - h2 / 2 + 6 + (i % 2) * 5);
      ctx.lineTo(tx + 5, o.y + h2 / 2);
      ctx.fill();
    }
    ctx.strokeStyle = '#130d06';
    ctx.lineWidth = 3;
    ctx.strokeRect(o.x - w2 / 2, o.y - h2 / 2, w2, h2);
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(o.x, o.y - h2 / 2); ctx.lineTo(o.x, o.y + h2 / 2);
    ctx.moveTo(o.x - w2 / 2, o.y); ctx.lineTo(o.x + w2 / 2, o.y);
    ctx.stroke();
  };
  A.bed = function (ctx, o) {
    shadow(ctx, o.x, o.y + 26, 30, 8, 0.4);
    ctx.fillStyle = '#241708';
    rr(ctx, o.x - 26, o.y - 34, 52, 68, 4); ctx.fill();
    ctx.fillStyle = '#3d2c14';
    rr(ctx, o.x - 22, o.y - 30, 44, 60, 3); ctx.fill();
    /* mattress + blanket pulled back */
    ctx.fillStyle = '#5b5546';
    rr(ctx, o.x - 20, o.y - 26, 40, 52, 3); ctx.fill();
    ctx.fillStyle = '#2e3b31';
    rr(ctx, o.x - 20, o.y - 4, 40, 30, 3); ctx.fill();
    ctx.fillStyle = '#3c4d3f';
    ctx.beginPath();
    ctx.moveTo(o.x - 20, o.y - 4); ctx.lineTo(o.x + 20, o.y - 4);
    ctx.lineTo(o.x + 16, o.y - 12); ctx.lineTo(o.x - 16, o.y - 10);
    ctx.fill();
    /* pillow */
    ell(ctx, o.x, o.y - 18, 12, 6.4, '#6d675a');
    ctx.strokeStyle = 'rgba(30,30,24,0.4)';
    ctx.beginPath(); ctx.ellipse(o.x, o.y - 18, 7, 3.4, 0, 0, T.TAU); ctx.stroke();
  };
  A.shelf = function (ctx, o) {
    shadow(ctx, o.x, o.y + 8, 34, 5, 0.35);
    ctx.fillStyle = '#2b1f0f';
    ctx.fillRect(o.x - 32, o.y - 30, 64, 5);
    ctx.fillRect(o.x - 32, o.y - 8, 64, 5);
    ctx.fillStyle = '#241809';
    ctx.fillRect(o.x - 32, o.y - 34, 3.4, 32);
    ctx.fillRect(o.x + 28.6, o.y - 34, 3.4, 32);
    /* cans + bottle */
    ell(ctx, o.x - 20, o.y - 33, 4, 1.8, '#4c5150');
    ctx.fillStyle = '#3c4241';
    ctx.fillRect(o.x - 24, o.y - 42, 8, 9);
    ctx.fillStyle = '#2f3733';
    ctx.fillRect(o.x - 6, o.y - 47, 6, 14);
    ctx.fillStyle = '#232a26';
    ctx.fillRect(o.x - 4.6, o.y - 51, 3.2, 5);
    ell(ctx, o.x + 16, o.y - 11, 5, 2, '#463d2a');
    ctx.fillStyle = '#39321f';
    ctx.fillRect(o.x + 11, o.y - 20, 10, 9);
    /* can glints */
    ctx.fillStyle = 'rgba(220,225,215,0.2)';
    ctx.fillRect(o.x - 23, o.y - 41, 1.4, 6);
    ctx.fillRect(o.x + 12, o.y - 19, 1.2, 5);
  };
  A.cabinet = function (ctx, o) {
    shadow(ctx, o.x, o.y + 30, 26, 7, 0.45);
    ctx.fillStyle = '#241809';
    rr(ctx, o.x - 24, o.y - 66, 48, 96, 3); ctx.fill();
    ctx.fillStyle = grad(ctx, o.x - 24, 0, o.x + 24, 0, [[0, '#4a3519'], [0.5, '#3a2a14'], [1, '#241908']]);
    ctx.fillRect(o.x - 21, o.y - 62, 42, 88);
    if (o.open) {
      ctx.fillStyle = '#0c0905';
      ctx.fillRect(o.x - 18, o.y - 56, 36, 76);
      ctx.fillStyle = '#1c1409';
      ctx.fillRect(o.x - 18, o.y - 20, 36, 3);
      if (o.journal && !o.journalTaken) {
        ctx.save();
        ctx.translate(o.x, o.y - 12);
        ctx.rotate(0.06);
        ctx.fillStyle = '#ddd6ba';
        rr(ctx, -8, -5.4, 16, 11, 1.2); ctx.fill();
        ctx.fillStyle = 'rgba(90,84,60,0.6)';
        for (var l = 0; l < 2; l++) ctx.fillRect(-5, -2.4 + l * 2.6, 10, 0.9);
        ctx.restore();
      }
    } else {
      /* doors */
      ctx.fillStyle = '#3d2b14';
      ctx.fillRect(o.x - 19, o.y - 58, 18, 80);
      ctx.fillRect(o.x + 1, o.y - 58, 18, 80);
      ctx.strokeStyle = 'rgba(18,12,6,0.7)';
      ctx.strokeRect(o.x - 19, o.y - 58, 18, 80);
      ctx.strokeRect(o.x + 1, o.y - 58, 18, 80);
      /* lock plate */
      ctx.fillStyle = '#515a58';
      ctx.fillRect(o.x - 3.4, o.y - 16, 6.8, 8);
      ctx.fillStyle = '#100d08';
      ctx.beginPath(); ctx.arc(o.x, o.y - 12, 1.5, 0, T.TAU); ctx.fill();
      ctx.fillStyle = 'rgba(220,226,220,0.3)';
      ctx.fillRect(o.x - 3.4, o.y - 16, 1, 8);
    }
    /* crown */
    ctx.fillStyle = '#332410';
    ctx.fillRect(o.x - 26, o.y - 70, 52, 5);
  };
  A.chair = function (ctx, o) {
    shadow(ctx, o.x, o.y + 8, 10, 4, 0.3);
    ctx.fillStyle = '#241809';
    ctx.fillRect(o.x - 6, o.y - 8, 12, 10);
    ctx.fillRect(o.x - 6, o.y - 24, 12, 3);
    ctx.fillStyle = '#3a2a13';
    for (var i = 0; i < 2; i++) ctx.fillRect(o.x - 6 + i * 9.4, o.y - 24, 2.4, 16);
  };
  A.hearthIn = function (ctx, o, t) {
    shadow(ctx, o.x, o.y + 12, 30, 8, 0.4);
    /* stone breast */
    ctx.fillStyle = '#2c302d';
    rr(ctx, o.x - 30, o.y - 46, 60, 58, 4); ctx.fill();
    for (var i = 0; i < 9; i++) {
      var sx2 = o.x - 26 + (i % 3) * 19 + sj(o, i) * 5;
      var sy2 = o.y - 42 + Math.floor(i / 3) * 15;
      ctx.fillStyle = ['rgba(110,116,108,0.5)', 'rgba(84,90,84,0.5)', 'rgba(128,132,124,0.35)'][i % 3];
      rr(ctx, sx2, sy2, 15, 11, 3); ctx.fill();
    }
    /* firebox */
    ctx.fillStyle = '#0a0806';
    rr(ctx, o.x - 15, o.y - 22, 30, 26, 3); ctx.fill();
    ctx.fillStyle = o.lit ? '#3c2a14' : '#23221d';
    ctx.beginPath(); ctx.ellipse(o.x, o.y - 1, 12, 4, 0, 0, T.TAU); ctx.fill();
    ctx.fillStyle = 'rgba(200,196,178,0.25)';
    ctx.beginPath(); ctx.ellipse(o.x - 4, o.y - 3, 4, 1.4, 0.3, 0, T.TAU); ctx.fill();
    if (o.lit) A.flames(ctx, o.x, o.y - 4, t, 0.9);
    /* chimney */
    ctx.fillStyle = '#191510';
    ctx.beginPath();
    ctx.moveTo(o.x - 26, o.y - 46); ctx.lineTo(o.x - 17, o.y - 66);
    ctx.lineTo(o.x + 17, o.y - 66); ctx.lineTo(o.x + 26, o.y - 46);
    ctx.fill();
  };
  A.lanternPeg = function (ctx, o, t) {
    ctx.strokeStyle = '#241809';
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.moveTo(o.x, o.y);
    ctx.lineTo(o.x, o.y + 26);
    ctx.stroke();
    var sw = Math.sin(t * 1.1) * 1.2;
    var x = o.x + sw, y = o.y + 30;
    ctx.strokeStyle = 'rgba(180,178,150,0.4)';
    ctx.lineWidth = 1;
    ctx.beginPath(); ctx.moveTo(o.x, o.y + 26); ctx.lineTo(x, y - 4); ctx.stroke();
    ctx.fillStyle = '#5a615c';
    rr(ctx, x - 4, y - 4, 8, 10, 2); ctx.fill();
    ctx.fillStyle = '#39403b';
    ctx.fillRect(x - 4.6, y - 5.4, 9.2, 2);
    ctx.fillRect(x - 4.6, y + 5.4, 9.2, 2);
    ctx.fillStyle = 'rgba(246,220,150,0.85)';
    ctx.fillRect(x - 2, y - 1.4, 4, 5.4);
    ctx.save();
    ctx.globalCompositeOperation = 'lighter';
    ctx.globalAlpha = 0.35 + 0.1 * Math.sin(t * 7.7);
    var gg = ctx.createRadialGradient(x, y + 1, 1, x, y + 1, 26);
    gg.addColorStop(0, 'rgba(230,180,100,0.8)');
    gg.addColorStop(1, 'rgba(230,180,100,0)');
    ctx.fillStyle = gg;
    ctx.fillRect(x - 26, y - 25, 52, 52);
    ctx.restore();
  };
  A.doorIn = function (ctx, o) {
    /* interior doorway with a wedge of night through it */
    ctx.fillStyle = '#0a0805';
    ctx.fillRect(o.x - 17, o.y - 66, 34, 66);
    var g = ctx.createLinearGradient(o.x, o.y - 66, o.x, o.y);
    g.addColorStop(0, 'rgba(70,84,96,0.20)');
    g.addColorStop(1, 'rgba(30,38,44,0.06)');
    ctx.fillStyle = g;
    ctx.fillRect(o.x - 15, o.y - 64, 30, 64);
    ctx.fillStyle = '#2c1f0f';
    ctx.fillRect(o.x + 8, o.y - 64, 9, 64);
    ctx.fillStyle = '#d8d2b6';
    ctx.fillRect(o.x + 9.6, o.y - 34, 1.4, 1.4);
    ctx.strokeStyle = '#1c1308';
    ctx.strokeRect(o.x - 18.4, o.y - 67.4, 36.8, 67.4);
  };
  A.item = function (ctx, o, t) {
    var bob = Math.sin(t * 2 + o.seed) * 0.5;
    ctx.save();
    ctx.translate(o.x, o.y + bob);
    ctx.globalAlpha = 1;
    if (o.kind === 'photo') {
      ctx.rotate(-0.12);
      ctx.fillStyle = '#0c0a07';
      ctx.fillRect(-6.6, -5, 14.4, 11);
      ctx.fillStyle = '#b9b3a2';
      ctx.fillRect(-5.4, -3.8, 12, 8.6);
      ctx.fillStyle = 'rgba(70,64,52,0.8)';
      ctx.beginPath(); ctx.arc(0.6, -0.4, 2, 0, T.TAU); ctx.fill();
      ctx.fillRect(-4, 1.8, 9, 3);
    } else if (o.kind === 'matches') {
      ctx.fillStyle = '#7a2018';
      rr(ctx, -5, -3, 10, 6, 1); ctx.fill();
      ctx.fillStyle = '#c9c2a8';
      ctx.fillRect(-3.4, -3.6, 5.4, 1.4);
      ctx.fillStyle = 'rgba(230,220,190,0.5)';
      ctx.fillRect(-4.4, -1.4, 8.8, 0.8);
    } else { /* key */
      ctx.rotate(0.5);
      ctx.strokeStyle = '#9a9182';
      ctx.lineWidth = 1.6;
      ctx.beginPath(); ctx.arc(-3.4, 0, 2.2, 0, T.TAU); ctx.stroke();
      ctx.beginPath(); ctx.moveTo(-1.2, 0); ctx.lineTo(5.6, 0); ctx.stroke();
      ctx.beginPath(); ctx.moveTo(3.6, 0); ctx.lineTo(3.6, 2.2); ctx.moveTo(5.6, 0); ctx.lineTo(5.6, 2.6); ctx.stroke();
      ctx.strokeStyle = 'rgba(226,222,200,0.5)';
      ctx.lineWidth = 0.6;
      ctx.beginPath(); ctx.moveTo(-1.2, -0.5); ctx.lineTo(5, -0.5); ctx.stroke();
    }
    ctx.restore();
  };

  /* ---------- fireflies (draw one; game loops) ---------- */
  A.firefly = function (ctx, x, y, a, r) {
    ctx.save();
    ctx.globalCompositeOperation = 'lighter';
    ctx.globalAlpha = a;
    var g = ctx.createRadialGradient(x, y, 0.2, x, y, (r || 5) * 3);
    g.addColorStop(0, 'rgba(210,230,160,0.9)');
    g.addColorStop(0.3, 'rgba(180,210,140,0.25)');
    g.addColorStop(1, 'rgba(180,210,140,0)');
    ctx.fillStyle = g;
    ctx.fillRect(x - (r || 5) * 3, y - (r || 5) * 3, (r || 5) * 6, (r || 5) * 6);
    ctx.fillStyle = '#e8f0c8';
    ctx.fillRect(x - 0.8, y - 0.8, 1.6, 1.6);
    ctx.restore();
  };

  /* ============================================================
     LIGHT SPRITES
     ============================================================ */
  function radialSprite(size, stops) {
    var c = T.canvas(size * 2, size * 2);
    var g = c.getContext('2d');
    var gr = g.createRadialGradient(size, size, 0, size, size, size);
    for (var i = 0; i < stops.length; i++) gr.addColorStop(stops[i][0], stops[i][1]);
    g.fillStyle = gr;
    g.beginPath();
    g.arc(size, size, size, 0, T.TAU);
    g.fill();
    return c;
  }
  A.circleSprite = radialSprite(128, [[0, 'rgba(255,255,255,1)'], [0.5, 'rgba(255,255,255,0.9)'], [0.82, 'rgba(255,255,255,0.3)'], [1, 'rgba(255,255,255,0)']]);
  A.warmCircle = radialSprite(128, [[0, 'rgba(222,158,88,0.9)'], [0.5, 'rgba(204,124,52,0.4)'], [1, 'rgba(204,124,52,0)']]);

  A.cone = (function () {
    var SIZE = 320, HALF = 0.46;
    var c = T.canvas(SIZE * 2, SIZE * 2);
    var g = c.getContext('2d');
    g.translate(SIZE, SIZE);
    var gradR = g.createRadialGradient(0, 0, 0, 0, 0, SIZE);
    gradR.addColorStop(0, 'rgba(255,255,255,1)');
    gradR.addColorStop(0.16, 'rgba(255,255,255,1)');
    gradR.addColorStop(0.45, 'rgba(255,255,255,0.86)');
    gradR.addColorStop(0.72, 'rgba(255,255,255,0.5)');
    gradR.addColorStop(0.9, 'rgba(255,255,255,0.16)');
    gradR.addColorStop(1, 'rgba(255,255,255,0)');
    var N = 60;
    for (var i = 0; i < N; i++) {
      var a0 = -HALF + (i / N) * HALF * 2;
      var a1 = -HALF + ((i + 1) / N) * HALF * 2;
      var f = Math.cos(((a0 + a1) / 2) / HALF * Math.PI / 2);
      g.globalAlpha = Math.pow(f, 2.0);
      g.fillStyle = gradR;
      g.beginPath();
      g.moveTo(0, 0);
      g.arc(0, 0, SIZE, a0, a1);
      g.closePath();
      g.fill();
    }
    return { canvas: c, size: SIZE, half: HALF };
  })();

  A.beam = (function () {
    var SIZE = 320, HALF = 0.46;
    var c = T.canvas(SIZE * 2, SIZE * 2);
    var g = c.getContext('2d');
    g.translate(SIZE, SIZE);
    var gradR = g.createRadialGradient(0, 0, 0, 0, 0, SIZE);
    gradR.addColorStop(0, 'rgba(215,208,183,0.42)');
    gradR.addColorStop(0.4, 'rgba(215,208,183,0.16)');
    gradR.addColorStop(0.8, 'rgba(215,208,183,0.05)');
    gradR.addColorStop(1, 'rgba(215,208,183,0)');
    var N = 44;
    for (var i = 0; i < N; i++) {
      var a0 = -HALF + (i / N) * HALF * 2;
      var a1 = -HALF + ((i + 1) / N) * HALF * 2;
      var f = Math.cos(((a0 + a1) / 2) / HALF * Math.PI / 2);
      g.globalAlpha = Math.pow(f, 2.2);
      g.fillStyle = gradR;
      g.beginPath();
      g.moveTo(0, 0);
      g.arc(0, 0, SIZE, a0, a1);
      g.closePath();
      g.fill();
    }
    return { canvas: c, size: SIZE, half: HALF };
  })();

  A.fogPuff = (function () {
    var c = T.canvas(256, 256);
    var g = c.getContext('2d');
    var r = T.rng(42);
    for (var i = 0; i < 5; i++) {
      var x = 128 + (r() - 0.5) * 70, y = 128 + (r() - 0.5) * 46;
      var gr = g.createRadialGradient(x, y, 6, x, y, 66 + r() * 50);
      gr.addColorStop(0, 'rgba(172,182,174,0.5)');
      gr.addColorStop(0.6, 'rgba(152,162,154,0.16)');
      gr.addColorStop(1, 'rgba(152,162,154,0)');
      g.fillStyle = gr;
      g.fillRect(0, 0, 256, 256);
    }
    return c;
  })();

  /* ============================================================
     MENU BACKGROUND
     ============================================================ */
  var menuStars = null, menuLayers = null;
  function buildMenu() {
    var r = T.rng(20240607);
    menuStars = [];
    for (var i = 0; i < 110; i++) {
      menuStars.push({ x: r(), y: r() * 0.55, s: r() * 1.3 + 0.3, a: 0.1 + r() * 0.45, tw: r() * 6 });
    }
    menuLayers = [];
    for (var L = 0; L < 3; L++) {
      var layer = [];
      var n = 14 + L * 9;
      for (var j = 0; j < n; j++) layer.push({ x: r(), h: (0.16 + r() * 0.22) * (1 - L * 0.18), w: 0.02 + r() * 0.02 });
      menuLayers.push(layer);
    }
  }
  function pineSil(ctx, x, baseY, h, w) {
    ctx.beginPath();
    ctx.moveTo(x - w, baseY);
    for (var i = 0; i < 4; i++) {
      var p = i / 4, yy = baseY - h * p, ww = w * (1 - p * 0.55);
      ctx.lineTo(x - ww * 0.72, yy - h * 0.12);
      ctx.lineTo(x - ww * 0.5, yy - h * 0.02);
    }
    ctx.lineTo(x, baseY - h);
    for (var i2 = 3; i2 >= 0; i2--) {
      var p2 = i2 / 4, y2 = baseY - h * p2, w2 = w * (1 - p2 * 0.55);
      ctx.lineTo(x + w2 * 0.5, y2 - h * 0.02);
      ctx.lineTo(x + w2 * 0.72, y2 - h * 0.12);
    }
    ctx.lineTo(x + w, baseY);
    ctx.closePath();
    ctx.fill();
  }
  A.menu = function (ctx, w, h, t, mx, my) {
    if (!menuLayers) buildMenu();
    ctx.clearRect(0, 0, w, h);
    ctx.globalAlpha = 1;
    ctx.globalCompositeOperation = 'source-over';
    var sky = ctx.createLinearGradient(0, 0, 0, h);
    sky.addColorStop(0, '#04060b');
    sky.addColorStop(0.55, '#0a0d0f');
    sky.addColorStop(1, '#0B0D0D');
    ctx.fillStyle = sky;
    ctx.fillRect(0, 0, w, h);
    for (var i = 0; i < menuStars.length; i++) {
      var st = menuStars[i];
      ctx.globalAlpha = st.a * (0.6 + 0.4 * Math.sin(t * 0.7 + st.tw));
      ctx.fillStyle = '#cfd6d2';
      ctx.fillRect(st.x * w + mx * 4, st.y * h + my * 3, st.s, st.s);
    }
    ctx.globalAlpha = 1;
    var moonX = w * 0.74 + mx * 8, moonY = h * 0.24 + my * 6;
    var mr = Math.min(w, h) * 0.075;
    var halo = ctx.createRadialGradient(moonX, moonY, mr * 0.5, moonX, moonY, mr * 5.4);
    halo.addColorStop(0, 'rgba(215,214,196,0.16)');
    halo.addColorStop(0.4, 'rgba(190,195,185,0.05)');
    halo.addColorStop(1, 'rgba(0,0,0,0)');
    ctx.fillStyle = halo;
    ctx.fillRect(0, 0, w, h);
    var mg = ctx.createRadialGradient(moonX - mr * 0.35, moonY - mr * 0.35, mr * 0.1, moonX, moonY, mr);
    mg.addColorStop(0, '#e9e6d4');
    mg.addColorStop(0.75, '#c9c8ba');
    mg.addColorStop(1, '#9a9c93');
    ctx.fillStyle = mg;
    ctx.beginPath(); ctx.arc(moonX, moonY, mr, 0, T.TAU); ctx.fill();
    ctx.fillStyle = 'rgba(120,120,110,0.18)';
    ctx.beginPath(); ctx.arc(moonX + mr * 0.3, moonY - mr * 0.2, mr * 0.16, 0, T.TAU); ctx.fill();
    ctx.beginPath(); ctx.arc(moonX - mr * 0.25, moonY + mr * 0.3, mr * 0.1, 0, T.TAU); ctx.fill();
    var cols = ['#0d1113', '#0a0d0c', '#050707'];
    for (var L = 0; L < 3; L++) {
      ctx.fillStyle = cols[L];
      var baseY = h * (0.72 + L * 0.1);
      var par = (L + 1) * 6;
      for (var j = 0; j < menuLayers[L].length; j++) {
        var tr = menuLayers[L][j];
        var x = tr.x * (w + 160) - 80 + mx * par + (L * 37);
        pineSil(ctx, x, baseY, tr.h * h * (0.8 + L * 0.3), tr.w * w * (0.7 + L * 0.35));
      }
    }
    var gr2 = ctx.createLinearGradient(0, h * 0.88, 0, h);
    gr2.addColorStop(0, '#0a0e0b');
    gr2.addColorStop(1, '#070908');
    ctx.fillStyle = gr2;
    ctx.fillRect(0, h * 0.88, w, h * 0.12);
    ctx.fillStyle = 'rgba(30,44,34,0.42)';
    ctx.beginPath();
    ctx.ellipse(w * 0.5, h * 0.93, w * 0.3, h * 0.05, 0, 0, T.TAU);
    ctx.fill();
    ctx.strokeStyle = 'rgba(120,126,116,0.05)';
    ctx.lineWidth = 7;
    ctx.beginPath();
    ctx.moveTo(w * 0.5, h * 0.94);
    ctx.quadraticCurveTo(w * 0.53, h * 0.9, w * 0.5, h * 0.85);
    ctx.stroke();
    var px = w * 0.5 + Math.sin(t * 0.11) * 2 + mx * 14;
    var py = h * 0.905;
    var lg = ctx.createRadialGradient(px + 4, py - 8, 1, px + 4, py - 8, 60);
    lg.addColorStop(0, 'rgba(215,208,183,0.20)');
    lg.addColorStop(1, 'rgba(215,208,183,0)');
    ctx.fillStyle = lg;
    ctx.fillRect(px - 60, py - 68, 130, 130);
    ctx.fillStyle = '#020304';
    ctx.beginPath(); ctx.ellipse(px, py - 8, 3.4, 5.2, 0, 0, T.TAU); ctx.fill();
    ctx.beginPath(); ctx.arc(px, py - 15.4, 2.6, 0, T.TAU); ctx.fill();
    ctx.fillStyle = 'rgba(240,230,190,' + (0.5 + 0.2 * Math.sin(t * 2.2)) + ')';
    ctx.beginPath(); ctx.arc(px + 4.4, py - 8.5, 1.5, 0, T.TAU); ctx.fill();
    ctx.globalAlpha = 0.10;
    for (var f = 0; f < 3; f++) {
      var fx2 = ((t * (6 + f * 4) + f * w / 3) % (w + 512)) - 256;
      ctx.drawImage(A.fogPuff, fx2, h * (0.74 + f * 0.06), 512, 200);
    }
    ctx.globalAlpha = 1;
    var v = ctx.createRadialGradient(w / 2, h / 2, Math.min(w, h) * 0.36, w / 2, h / 2, Math.max(w, h) * 0.72);
    v.addColorStop(0, 'rgba(0,0,0,0)');
    v.addColorStop(1, 'rgba(0,0,0,0.72)');
    ctx.fillStyle = v;
    ctx.fillRect(0, 0, w, h);
  };
})();
