/* ============================================================
   THE LONE PATH — procedural assets
   Everything is drawn in code: one consistent style, zero files.
   Pseudo-3D top-down: shadows + vertically "extruded" bodies,
   y-sorted so the player can hide behind tall objects.
   ============================================================ */
'use strict';
(function () {
  var T = window.TLP;
  var A = {};
  T.Assets = A;

  /* palette */
  var C = {
    void: '#0B0D0D',
    g0: '#111A16',
    g1: '#1B2921',
    g2: '#344039',
    gray: '#626965',
    lite: '#A7ACA8',
    lamp: '#D7D0B7',
    fire: '#c9793d'
  };
  A.C = C;

  /* ---------- helpers ---------- */
  function shadow(ctx, x, y, rx, ry, a) {
    ctx.save();
    ctx.globalAlpha = a == null ? 0.42 : a;
    ctx.fillStyle = '#000';
    ctx.beginPath();
    ctx.ellipse(x + 3, y + 2, rx, ry, 0, 0, T.TAU);
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
  /* rounded rect path */
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
  /* deterministic jitter from an object's position */
  function sj(o, salt) {
    var n = Math.sin(o.x * 12.9898 + o.y * 78.233 + (salt || 0) * 37.71) * 43758.5453;
    return n - Math.floor(n);
  }

  function conifer(ctx, o, layers, w, hgt, top, bot) {
    var s = o.s || 1;
    var by = o.y;
    /* trunk */
    ctx.fillStyle = grad(ctx, 0, by - 34 * s, 0, by, [[0, '#2c251b'], [1, '#120e09']]);
    ctx.fillRect(o.x - 3.4 * s, by - 34 * s, 6.8 * s, 34 * s);
    for (var i = 0; i < layers; i++) {
      var p = i / (layers - 1 || 1);
      var ly = by - (26 + p * (hgt - 26)) * s;
      var lw = w * (1 - p * 0.62) * s;
      ctx.fillStyle = grad(ctx, 0, ly - lw, 0, ly + lw * 0.5, [[0, top], [1, bot]]);
      ctx.beginPath();
      ctx.moveTo(o.x - lw, ly + lw * 0.22);
      ctx.quadraticCurveTo(o.x - lw * 0.5, ly - lw * 0.1, o.x, ly - lw * 0.95);
      ctx.quadraticCurveTo(o.x + lw * 0.5, ly - lw * 0.1, o.x + lw, ly + lw * 0.22);
      ctx.quadraticCurveTo(o.x, ly + lw * 0.5, o.x - lw, ly + lw * 0.22);
      ctx.fill();
    }
  }

  /* ---------- trees ---------- */
  A.pine = function (ctx, o) {
    var s = o.s || 1;
    shadow(ctx, o.x, o.y, 24 * s, 9 * s);
    conifer(ctx, o, 3, 30, 86, '#2c4a37', '#152619');
  };
  A.fir = function (ctx, o) {
    var s = o.s || 1;
    shadow(ctx, o.x, o.y, 21 * s, 8 * s);
    conifer(ctx, o, 4, 25, 92, '#26483a', '#12241b');
  };
  A.small = function (ctx, o) {
    var s = o.s || 1;
    shadow(ctx, o.x, o.y, 15 * s, 6 * s);
    ctx.fillStyle = '#251e16';
    ctx.fillRect(o.x - 2.2 * s, o.y - 26 * s, 4.4 * s, 26 * s);
    var cx = o.x, cy = o.y - 36 * s;
    ell(ctx, cx - 6 * s, cy + 3 * s, 12 * s, 10 * s, '#26402e');
    ell(ctx, cx + 5 * s, cy, 11 * s, 9 * s, '#1e3324');
    ell(ctx, cx, cy - 5 * s, 11 * s, 9 * s, grad(ctx, 0, cy - 15 * s, 0, cy + 4 * s, [[0, '#33513c'], [1, '#1a2f20']]));
  };
  A.dry = function (ctx, o) {
    var s = o.s || 1;
    shadow(ctx, o.x, o.y, 16 * s, 6 * s);
    ctx.strokeStyle = '#2e261d';
    ctx.lineCap = 'round';
    var n = 5 + Math.floor(sj(o, 1) * 3);
    for (var i = 0; i < n; i++) {
      var a = -Math.PI / 2 + (i / (n - 1) - 0.5) * 2.1 + (sj(o, i) - 0.5) * 0.5;
      var len = (24 + sj(o, i + 9) * 26) * s;
      ctx.lineWidth = (3.4 - 2.6 * (i % 2)) * s;
      ctx.beginPath();
      ctx.moveTo(o.x, o.y - 12 * s);
      var mx = o.x + Math.cos(a) * len * 0.5;
      var my = o.y - 12 * s + Math.sin(a) * len * 0.5;
      ctx.quadraticCurveTo(mx, my, o.x + Math.cos(a) * len, o.y - 12 * s + Math.sin(a) * len);
      ctx.stroke();
    }
    ctx.fillStyle = grad(ctx, 0, o.y - 20 * s, 0, o.y, [[0, '#39302a'], [1, '#17120c']]);
    ctx.fillRect(o.x - 4 * s, o.y - 20 * s, 8 * s, 20 * s);
  };
  A.stump = function (ctx, o) {
    var s = o.s || 1;
    shadow(ctx, o.x, o.y, 11 * s, 4.5 * s, 0.4);
    ctx.fillStyle = '#2a2012';
    ctx.fillRect(o.x - 7 * s, o.y - 10 * s, 14 * s, 10 * s);
    ell(ctx, o.x, o.y - 10 * s, 7 * s, 3.4 * s, '#493a20');
    ctx.strokeStyle = 'rgba(150,120,72,0.5)';
    ctx.lineWidth = 0.8;
    ctx.beginPath();
    ctx.ellipse(o.x, o.y - 10 * s, 4 * s, 1.9 * s, 0, 0, T.TAU);
    ctx.stroke();
  };
  A.bigtree = function (ctx, o) {
    shadow(ctx, o.x, o.y, 42, 14, 0.5);
    ctx.fillStyle = grad(ctx, 0, o.y - 60, 0, o.y, [[0, '#372c1d'], [1, '#161009']]);
    ctx.beginPath();
    ctx.moveTo(o.x - 11, o.y);
    ctx.quadraticCurveTo(o.x - 7, o.y - 40, o.x - 8, o.y - 64);
    ctx.lineTo(o.x + 8, o.y - 64);
    ctx.quadraticCurveTo(o.x + 7, o.y - 40, o.x + 11, o.y);
    ctx.fill();
    /* carvings */
    ctx.strokeStyle = 'rgba(210,200,160,0.5)';
    ctx.lineWidth = 1;
    for (var i = 0; i < 5; i++) {
      var yy = o.y - 16 - i * 9;
      ctx.beginPath();
      ctx.moveTo(o.x - 6 + (i % 2) * 3, yy);
      ctx.lineTo(o.x - 1 + (i % 3) * 2, yy + 2);
      ctx.stroke();
    }
    ell(ctx, o.x - 20, o.y - 78, 34, 24, '#203a29');
    ell(ctx, o.x + 22, o.y - 70, 30, 22, '#1a3022');
    ell(ctx, o.x, o.y - 92, 36, 24, grad(ctx, 0, o.y - 118, 0, o.y - 66, [[0, '#2f5039'], [1, '#17281c']]));
  };
  A.signtree = function (ctx, o) {
    A.small(ctx, o);
    /* symbol carved on trunk: three lines + an eye */
    ctx.save();
    ctx.translate(o.x, o.y - 14 * (o.s || 1));
    ctx.strokeStyle = 'rgba(190,185,160,0.5)';
    ctx.lineWidth = 1.2;
    ctx.beginPath();
    for (var i = 0; i < 3; i++) { ctx.moveTo(-4, -5 + i * 3.4); ctx.lineTo(4, -5 + i * 3.4); }
    ctx.stroke();
    ctx.beginPath();
    ctx.ellipse(0, 5, 3.6, 2, 0, 0, T.TAU);
    ctx.stroke();
    ctx.fillStyle = 'rgba(190,185,160,0.5)';
    ctx.fillRect(-0.7, 4.2, 1.4, 1.6);
    ctx.restore();
  };

  /* ---------- ground clutter ---------- */
  A.rock = function (ctx, o) {
    var s = o.s || 1;
    shadow(ctx, o.x, o.y, 12 * s, 5 * s, 0.4);
    ctx.fillStyle = grad(ctx, 0, o.y - 16 * s, 0, o.y + 2, [[0, '#727c74'], [0.6, '#454e49'], [1, '#262c28']]);
    ctx.beginPath();
    ctx.moveTo(o.x - 12 * s, o.y);
    ctx.lineTo(o.x - 9 * s, o.y - 9 * s);
    ctx.lineTo(o.x - 1 * s, o.y - 13 * s);
    ctx.lineTo(o.x + 8 * s, o.y - 8 * s);
    ctx.lineTo(o.x + 12 * s, o.y);
    ctx.quadraticCurveTo(o.x, o.y + 4 * s, o.x - 12 * s, o.y);
    ctx.fill();
    ctx.fillStyle = 'rgba(43,64,48,0.8)';
    ctx.beginPath();
    ctx.moveTo(o.x - 12 * s, o.y);
    ctx.quadraticCurveTo(o.x - 4 * s, o.y - 3 * s, o.x + 12 * s, o.y);
    ctx.quadraticCurveTo(o.x, o.y + 4 * s, o.x - 12 * s, o.y);
    ctx.fill();
  };
  A.fallen = function (ctx, o) {
    var s = o.s || 1;
    ctx.save();
    ctx.translate(o.x, o.y);
    ctx.rotate(o.rot || 0);
    shadow(ctx, 0, 4 * s, 34 * s, 7 * s, 0.35);
    ctx.fillStyle = grad(ctx, 0, -8 * s, 0, 4 * s, [[0, '#443621'], [1, '#1c150c']]);
    rr(ctx, -34 * s, -7 * s, 68 * s, 11 * s, 5 * s);
    ctx.fill();
    ell(ctx, 34 * s, -1.5 * s, 3.4 * s, 5.5 * s, '#57452a');
    ctx.strokeStyle = 'rgba(120,96,56,0.6)';
    ctx.beginPath(); ctx.ellipse(34 * s, -1.5 * s, 1.6 * s, 3 * s, 0, 0, T.TAU); ctx.stroke();
    ctx.restore();
  };
  A.bush = function (ctx, o) {
    var s = o.s || 1;
    shadow(ctx, o.x, o.y, 13 * s, 4 * s, 0.3);
    ell(ctx, o.x - 5 * s, o.y - 5 * s, 9 * s, 7 * s, '#22392a');
    ell(ctx, o.x + 5 * s, o.y - 4 * s, 8 * s, 6 * s, '#1b2f22');
    ell(ctx, o.x, o.y - 9 * s, 9 * s, 7 * s, grad(ctx, 0, o.y - 16 * s, 0, o.y - 3 * s, [[0, '#2f4d38'], [1, '#182a1e']]));
  };

  /* ---------- camp & cabin props ---------- */
  A.crate = function (ctx, o) {
    var s = o.s || 1, w = 20 * s, h = 18 * s;
    shadow(ctx, o.x, o.y, 14 * s, 5 * s, 0.4);
    ctx.fillStyle = '#2c2110';
    ctx.fillRect(o.x - w / 2, o.y - h, w, h);
    ctx.fillStyle = '#403014';
    ctx.fillRect(o.x - w / 2, o.y - h - 6 * s, w, 6 * s);
    ctx.strokeStyle = 'rgba(150,116,62,0.45)';
    ctx.lineWidth = 1;
    ctx.strokeRect(o.x - w / 2 + 2, o.y - h + 2, w - 4, h - 4);
    ctx.beginPath();
    ctx.moveTo(o.x - w / 2 + 2, o.y - h + 2); ctx.lineTo(o.x + w / 2 - 2, o.y - 2);
    ctx.moveTo(o.x + w / 2 - 2, o.y - h + 2); ctx.lineTo(o.x - w / 2 + 2, o.y - 2);
    ctx.stroke();
  };
  A.barrel = function (ctx, o) {
    var s = o.s || 1;
    shadow(ctx, o.x, o.y, 11 * s, 4.5 * s, 0.4);
    ctx.fillStyle = grad(ctx, 0, o.y - 26 * s, 0, o.y, [[0, '#4a3a1f'], [1, '#1a130a']]);
    rr(ctx, o.x - 9 * s, o.y - 26 * s, 18 * s, 26 * s, 4 * s);
    ctx.fill();
    ctx.fillStyle = 'rgba(170,140,84,0.25)';
    ctx.fillRect(o.x - 9 * s, o.y - 19 * s, 18 * s, 2.4 * s);
    ctx.fillRect(o.x - 9 * s, o.y - 9 * s, 18 * s, 2.4 * s);
    ell(ctx, o.x, o.y - 26 * s, 9 * s, 3.4 * s, '#5c4726');
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
        ell(ctx, x, y, r, r, '#241a0c');
        ell(ctx, x, y, r * 0.62, r * 0.62, '#54401f');
      }
    }
  };
  A.table = function (ctx, o) {
    var s = o.s || 1;
    shadow(ctx, o.x, o.y, 20 * s, 6 * s, 0.35);
    ctx.fillStyle = '#1f1810';
    ctx.fillRect(o.x - 14 * s, o.y - 12 * s, 3 * s, 12 * s);
    ctx.fillRect(o.x + 11 * s, o.y - 12 * s, 3 * s, 12 * s);
    ctx.fillStyle = grad(ctx, 0, o.y - 20 * s, 0, o.y - 10 * s, [[0, '#4c3a1e'], [1, '#291f10']]);
    rr(ctx, o.x - 18 * s, o.y - 18 * s, 36 * s, 9 * s, 2 * s);
    ctx.fill();
  };
  A.planks = function (ctx, o) {
    var s = o.s || 1;
    shadow(ctx, o.x, o.y, 18 * s, 5 * s, 0.3);
    ctx.save();
    ctx.translate(o.x, o.y);
    ctx.rotate((o.rot || 0));
    for (var i = 0; i < 3; i++) {
      ctx.fillStyle = i % 2 ? '#3c2d17' : '#2c2010';
      ctx.fillRect(-16 * s + i * 3 * s, -3 * s + i * 3 * s, 32 * s, 4 * s);
    }
    ctx.restore();
  };
  A.tent = function (ctx, o) {
    var s = o.s || 1;
    shadow(ctx, o.x, o.y, 30 * s, 9 * s, 0.45);
    ctx.fillStyle = grad(ctx, 0, o.y - 40 * s, 0, o.y, [[0, '#41564a'], [1, '#1d2921']]);
    ctx.beginPath();
    ctx.moveTo(o.x - 28 * s, o.y);
    ctx.lineTo(o.x - 3 * s, o.y - 40 * s);
    ctx.lineTo(o.x + 30 * s, o.y - 2);
    ctx.closePath();
    ctx.fill();
    ctx.fillStyle = 'rgba(10,16,13,0.9)';
    ctx.beginPath();
    ctx.moveTo(o.x + 2 * s, o.y - 1);
    ctx.lineTo(o.x - 6 * s, o.y - 26 * s);
    ctx.lineTo(o.x - 14 * s, o.y - 1);
    ctx.closePath();
    ctx.fill();
    ctx.strokeStyle = 'rgba(190,196,190,0.2)';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(o.x - 3 * s, o.y - 40 * s);
    ctx.lineTo(o.x + 30 * s, o.y - 2);
    ctx.stroke();
  };
  A.sign = function (ctx, o) {
    var s = o.s || 1;
    shadow(ctx, o.x, o.y, 8 * s, 3.5 * s, 0.35);
    ctx.fillStyle = '#322512';
    ctx.fillRect(o.x - 2 * s, o.y - 34 * s, 4 * s, 34 * s);
    ctx.save();
    ctx.translate(o.x, o.y - 30 * s);
    ctx.rotate(o.dir || -0.2);
    ctx.fillStyle = '#43321a';
    ctx.beginPath();
    ctx.moveTo(-14 * s, -4 * s); ctx.lineTo(10 * s, -4 * s); ctx.lineTo(16 * s, 0);
    ctx.lineTo(10 * s, 4 * s); ctx.lineTo(-14 * s, 4 * s);
    ctx.closePath(); ctx.fill();
    ctx.strokeStyle = 'rgba(200,204,198,0.4)';
    ctx.beginPath(); ctx.moveTo(-11 * s, 0); ctx.lineTo(4 * s, 0); ctx.stroke();
    ctx.restore();
    ctx.save();
    ctx.translate(o.x, o.y - 18 * s);
    ctx.rotate(-(o.dir || -0.2) + 0.35);
    ctx.fillStyle = '#372915';
    ctx.beginPath();
    ctx.moveTo(12 * s, -3.4 * s); ctx.lineTo(-8 * s, -3.4 * s); ctx.lineTo(-14 * s, 0);
    ctx.lineTo(-8 * s, 3.4 * s); ctx.lineTo(12 * s, 3.4 * s);
    ctx.closePath(); ctx.fill();
    ctx.restore();
  };
  A.fence = function (ctx, o) {
    var s = o.s || 1;
    ctx.save();
    ctx.translate(o.x, o.y);
    ctx.rotate(o.rot || 0);
    shadow(ctx, 0, 2 * s, 26 * s, 5 * s, 0.3);
    ctx.fillStyle = '#2c2010';
    ctx.fillRect(-22 * s, -34 * s, 4.4 * s, 34 * s);
    ctx.fillRect(16 * s, -30 * s, 4.4 * s, 30 * s);
    ctx.save();
    ctx.rotate(-0.12);
    ctx.fillStyle = '#3b2b15';
    ctx.fillRect(-24 * s, -28 * s, 46 * s, 4.6 * s);
    ctx.fillRect(-24 * s, -14 * s, 46 * s, 4.2 * s);
    ctx.restore();
    ctx.restore();
  };

  /* ---------- fire ---------- */
  A.firepit = function (ctx, o, t) {
    shadow(ctx, o.x, o.y, 24, 9, 0.35);
    for (var i = 0; i < 7; i++) {
      var a = i / 7 * T.TAU + sj(o, 3);
      var x = o.x + Math.cos(a) * 17, y = o.y + Math.sin(a) * 8.4;
      ell(ctx, x, y, 5.2, 3.6, i % 2 ? '#4b534d' : '#3c433e');
      ell(ctx, x, y - 1.2, 5.2, 3.6, i % 2 ? '#727b73' : '#626b63');
    }
    ell(ctx, o.x, o.y, 13, 6.4, '#1f1e1a');
    ell(ctx, o.x, o.y - 1, 11, 5.2, '#3c3b34');
    ctx.fillStyle = '#2b2114';
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
      var cols = [C.fire, '#e0a45c', '#f2d9a2'];
      ctx.fillStyle = cols[i];
      ctx.globalAlpha = [0.22, 0.3, 0.5][i];
      ctx.beginPath();
      ctx.moveTo(fx - w, y);
      ctx.quadraticCurveTo(fx - w * 0.6, y - h * 0.55, fx + f * 1.4, y - h);
      ctx.quadraticCurveTo(fx + w * 0.7, y - h * 0.5, fx + w, y);
      ctx.closePath();
      ctx.fill();
    }
    /* embers */
    ctx.globalAlpha = 0.5;
    ctx.fillStyle = '#e6a75f';
    for (var e = 0; e < 6; e++) {
      var ph = (t * 0.6 + e * 0.37) % 1;
      var ex = x + Math.sin(e * 3.7 + t * 2.4) * 8 * s;
      var ey = y - ph * 34 * s;
      ctx.globalAlpha = 0.5 * (1 - ph);
      ctx.fillRect(ex, ey, 1.4, 1.4);
    }
    ctx.restore();
  };

  /* ---------- cabin ---------- */
  A.cabin = function (ctx, o, t) {
    var w = 100, wallH = 46, roof = 58;
    shadow(ctx, o.x, o.y, w + 12, 16, 0.5);
    /* front wall */
    ctx.fillStyle = grad(ctx, 0, o.y - wallH, 0, o.y, [[0, '#4c3d2a'], [1, '#241b10']]);
    ctx.fillRect(o.x - w, o.y - wallH, w * 2, wallH);
    /* plank lines */
    ctx.strokeStyle = 'rgba(20,14,8,0.55)';
    ctx.lineWidth = 1;
    for (var i = 1; i < 5; i++) {
      ctx.beginPath();
      ctx.moveTo(o.x - w, o.y - wallH + i * 9.4);
      ctx.lineTo(o.x + w, o.y - wallH + i * 9.4);
      ctx.stroke();
    }
    /* door */
    ctx.fillStyle = '#120d08';
    rr(ctx, o.x - 13, o.y - 34, 26, 34, 2);
    ctx.fill();
    ctx.strokeStyle = 'rgba(196,186,150,0.3)';
    ctx.strokeRect(o.x - 13, o.y - 34, 26, 34);
    /* symbol scratched on the doorframe */
    ctx.save();
    ctx.translate(o.x + 19, o.y - 24);
    ctx.strokeStyle = 'rgba(200,195,170,0.4)';
    ctx.lineWidth = 1.1;
    ctx.beginPath();
    for (var g = 0; g < 3; g++) { ctx.moveTo(-4, -6 + g * 3); ctx.lineTo(4, -6 + g * 3); }
    ctx.stroke();
    ctx.beginPath(); ctx.ellipse(0, 4, 3.6, 2, 0, 0, T.TAU); ctx.stroke();
    ctx.fillStyle = 'rgba(200,195,170,0.4)';
    ctx.fillRect(-0.7, 3.2, 1.4, 1.7);
    ctx.restore();
    /* window — faint reflection */
    ctx.fillStyle = '#0a0f13';
    ctx.fillRect(o.x - 62, o.y - 32, 24, 17);
    ctx.fillStyle = 'rgba(215,208,183,0.13)';
    ctx.fillRect(o.x - 62, o.y - 32, 24, 3);
    ctx.strokeStyle = 'rgba(170,158,126,0.35)';
    ctx.strokeRect(o.x - 62, o.y - 32, 24, 17);
    ctx.beginPath();
    ctx.moveTo(o.x - 50, o.y - 32); ctx.lineTo(o.x - 50, o.y - 15);
    ctx.stroke();
    /* side boards / damage */
    ctx.fillStyle = 'rgba(0,0,0,0.45)';
    ctx.fillRect(o.x + w - 16, o.y - 8, 16, 8);
    ctx.strokeStyle = 'rgba(167,172,168,0.07)';
    ctx.beginPath();
    ctx.moveTo(o.x + w - 30, o.y - wallH); ctx.lineTo(o.x + w - 18, o.y);
    ctx.stroke();
    /* roof: two slopes, ridge offset up */
    var topY = o.y - wallH - roof;
    ctx.fillStyle = grad(ctx, 0, topY, 0, o.y - wallH, [[0, '#2c2a20'], [1, '#15140e']]);
    ctx.beginPath();
    ctx.moveTo(o.x - w - 12, o.y - wallH + 2);
    ctx.lineTo(o.x - 10, topY);
    ctx.lineTo(o.x + w + 12, o.y - wallH + 2);
    ctx.closePath();
    ctx.fill();
    ctx.fillStyle = grad(ctx, 0, topY, 0, o.y - wallH, [[0, '#3d3a2c'], [1, '#1e1d14']]);
    ctx.beginPath();
    ctx.moveTo(o.x - w - 12, o.y - wallH + 2);
    ctx.lineTo(o.x - 10, topY);
    ctx.lineTo(o.x - 8, topY + 3);
    ctx.lineTo(o.x - w - 6, o.y - wallH + 5);
    ctx.closePath();
    ctx.fill();
    /* ridge line */
    ctx.strokeStyle = 'rgba(206,210,200,0.3)';
    ctx.lineWidth = 1.4;
    ctx.beginPath();
    ctx.moveTo(o.x - 10, topY);
    ctx.lineTo(o.x + w + 12, o.y - wallH + 2);
    ctx.stroke();
    /* eaves overhang */
    ctx.fillStyle = '#1c1810';
    ctx.fillRect(o.x - w - 12, o.y - wallH + 2, (w + 12) * 2, 4);
  };

  /* ---------- the car ---------- */
  A.car = function (ctx, o) {
    ctx.save();
    ctx.translate(o.x, o.y);
    ctx.rotate(o.rot || 0);
    shadow(ctx, 0, 6, 44, 16, 0.5);
    /* wheels */
    ctx.fillStyle = '#080908';
    [[-26, -18], [-26, 18], [26, -18], [26, 18]].forEach(function (p) {
      rr(ctx, p[0] - 7, p[1] - 4.5, 14, 9, 3); ctx.fill();
    });
    /* body */
    ctx.fillStyle = grad(ctx, 0, -22, 0, 22, [[0, '#5c675f'], [0.5, '#39443e'], [1, '#1c2321']]);
    rr(ctx, -40, -16, 80, 32, 9);
    ctx.fill();
    /* rust patches */
    var r = T.rng(Math.floor(o.x) * 31 + Math.floor(o.y));
    for (var i = 0; i < 9; i++) {
      ctx.fillStyle = 'rgba(84,52,28,' + (0.14 + r() * 0.16).toFixed(3) + ')';
      ctx.beginPath();
      ctx.ellipse(-36 + r() * 72, -13 + r() * 26, 2 + r() * 5, 1.6 + r() * 3, r() * 3, 0, T.TAU);
      ctx.fill();
    }
    /* cabin + windshield */
    ctx.fillStyle = '#232b28';
    rr(ctx, -14, -13, 24, 26, 5); ctx.fill();
    ctx.fillStyle = 'rgba(175,200,210,0.22)';
    rr(ctx, 10, -12, 8, 24, 3); ctx.fill();   /* back glass */
    ctx.fillStyle = 'rgba(175,200,210,0.12)';
    ctx.beginPath();
    ctx.moveTo(-14, -13); ctx.lineTo(-22, -9); ctx.lineTo(-22, 9); ctx.lineTo(-14, 13);
    ctx.closePath(); ctx.fill(); /* cracked windshield */
    /* hood line + broken headlight */
    ctx.strokeStyle = 'rgba(200,205,198,0.3)';
    ctx.lineWidth = 1;
    ctx.beginPath(); ctx.moveTo(-38, -3); ctx.lineTo(-24, -3); ctx.stroke();
    ctx.fillStyle = '#0a0c0c';
    rr(ctx, 24, -14, 8, 7, 2); ctx.fill();
    ctx.fillStyle = 'rgba(225,216,175,0.4)';
    rr(ctx, 24, 7, 8, 7, 2); ctx.fill();
    ctx.restore();
  };

  /* ---------- final point ---------- */
  A.cross = function (ctx, o) {
    shadow(ctx, o.x, o.y, 12, 5, 0.4);
    ell(ctx, o.x, o.y - 2, 11, 5, '#4d5650');
    ell(ctx, o.x - 2, o.y - 4, 8, 3.4, '#6c766e');
    ctx.save();
    ctx.translate(o.x, o.y - 4);
    ctx.rotate(0.12);
    ctx.fillStyle = '#332410';
    ctx.fillRect(-2.2, -30, 4.4, 30);
    ctx.fillRect(-10, -22, 20, 3.6);
    ctx.restore();
  };

  /* ---------- the note on the ground ---------- */
  A.note = function (ctx, o, t) {
    var bob = Math.sin(t * 1.6 + o.idx) * 0.6;
    ctx.save();
    ctx.translate(o.x, o.y + bob);
    ctx.rotate(o.rot);
    ctx.globalAlpha = 0.9;
    ctx.fillStyle = '#000';
    ctx.globalAlpha = 0.3;
    ctx.fillRect(-8.4, -5.4, 19, 13);
    ctx.globalAlpha = 1;
    ctx.fillStyle = '#ddd6ba';
    rr(ctx, -9, -6, 18, 12, 1.4); ctx.fill();
    ctx.fillStyle = 'rgba(90,84,60,0.5)';
    for (var i = 0; i < 3; i++) ctx.fillRect(-6, -3 + i * 3, 12 - i * 3, 0.9);
    ctx.fillStyle = 'rgba(60,55,40,0.35)';
    ctx.fillRect(-9, -6, 18, 1.6);
    ctx.restore();
  };

  /* ---------- player ---------- */
  A.player = function (ctx, p, t) {
    var s = 1;
    var moving = p.moving;
    var cyc = p.walk * T.TAU;
    shadow(ctx, p.x, p.y, 9, 3.6, 0.5);
    var bob = moving ? Math.sin(cyc * 2) * 0.9 : 0;
    var fx = Math.cos(p.fa), fy = Math.sin(p.fa);
    var bx = -fy, by = fx; /* perpendicular */
    ctx.save();
    ctx.translate(p.x, p.y - bob);
    /* legs */
    for (var i = 0; i < 2; i++) {
      var sw = moving ? Math.sin(cyc + i * Math.PI) * 3.4 : 0;
      var lx = (i ? 2.4 : -2.4) * bx + sw * fx;
      var ly = (i ? 2.4 : -2.4) * by + sw * fy;
      ctx.fillStyle = '#1e2422';
      ctx.beginPath();
      ctx.ellipse(lx, ly - 2.5, 2.5, 3.1, 0, 0, T.TAU);
      ctx.fill();
      ctx.fillStyle = '#0c0f0e'; /* boot */
      ctx.beginPath();
      ctx.ellipse(lx + fx * 1.6, ly - 2.5 + fy * 1.6, 2.0, 1.6, 0, 0, T.TAU);
      ctx.fill();
    }
    /* body — dark jacket */
    ctx.fillStyle = grad(ctx, 0, -14, 0, -2, [[0, '#454f49'], [1, '#232a26']]);
    ctx.beginPath();
    ctx.ellipse(fx * 0.6, -8, 5.6 * s, 6.6 * s, 0, 0, T.TAU);
    ctx.fill();
    /* backpack */
    ctx.fillStyle = '#33271a';
    ctx.beginPath();
    ctx.ellipse(-fx * 4.2, -9 - fy * 1.2, 3.4, 4.2, Math.atan2(fy, fx), 0, T.TAU);
    ctx.fill();
    ctx.fillStyle = 'rgba(200,204,196,0.3)';
    ctx.fillRect(-fx * 4.2 - 2, -11, 4, 1.2);
    /* head (face barely visible) */
    ctx.fillStyle = '#333b36';
    ctx.beginPath();
    ctx.ellipse(fx * 1.4, -16.4 + fy * 0.5, 3.6, 3.4, 0, 0, T.TAU);
    ctx.fill();
    ctx.fillStyle = '#151a17';
    ctx.beginPath();
    ctx.ellipse(fx * 2.6, -16.2 + fy * 1.1, 2.0, 1.7, 0, 0, T.TAU);
    ctx.fill();
    /* arm + lantern */
    var lx2 = fx * 6.2, ly2 = -11 + fy * 3;
    ctx.strokeStyle = '#3d4742';
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(fx * 2.5, -10);
    ctx.lineTo(lx2, ly2);
    ctx.stroke();
    ctx.fillStyle = '#5a615c';
    rr(ctx, lx2 - 1.7, ly2 - 1, 3.4, 4.2, 1);
    ctx.fill();
    if (TLP.game && TLP.game.flash) {
      ctx.fillStyle = '#f4e9c0';
      ctx.beginPath();
      ctx.arc(lx2 + fx * 1.6, ly2 + 1, 1.7, 0, T.TAU);
      ctx.fill();
    }
    ctx.restore();
  };

  /* ---------- the figure ---------- */
  A.figure = function (ctx, x, y, alpha) {
    ctx.save();
    ctx.globalAlpha = alpha;
    shadow(ctx, x, y, 9, 4, 0.5);
    ctx.fillStyle = '#04070a';
    /* legs */
    ctx.fillRect(x - 3.4, y - 13, 2.8, 13);
    ctx.fillRect(x + 0.6, y - 13, 2.8, 13);
    /* long torso */
    ctx.beginPath();
    ctx.moveTo(x - 5.4, y - 11);
    ctx.quadraticCurveTo(x - 5.0, y - 30, x - 2.6, y - 34);
    ctx.lineTo(x + 2.6, y - 34);
    ctx.quadraticCurveTo(x + 5.0, y - 30, x + 5.4, y - 11);
    ctx.closePath();
    ctx.fill();
    /* head, slightly too still */
    ctx.beginPath();
    ctx.arc(x, y - 39, 4.4, 0, T.TAU);
    ctx.fill();
    /* faint eye glints — barely */
    ctx.fillStyle = 'rgba(215,208,183,0.16)';
    ctx.fillRect(x - 1.8, y - 40, 1, 0.9);
    ctx.fillRect(x + 0.8, y - 40, 1, 0.9);
    ctx.restore();
  };

  /* ============================================================
     pre-built sprites for lighting
     ============================================================ */
  function radialSprite(size, stops, color) {
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
  A.circleSprite = radialSprite(128, [[0, 'rgba(255,255,255,1)'], [0.55, 'rgba(255,255,255,0.72)'], [0.85, 'rgba(255,255,255,0.18)'], [1, 'rgba(255,255,255,0)']]);
  A.warmCircle = radialSprite(128, [[0, 'rgba(216,150,84,0.9)'], [0.5, 'rgba(200,120,50,0.42)'], [1, 'rgba(200,120,50,0)']]);

  /* cone sprite built from wedges so edges are soft everywhere */
  A.cone = (function () {
    var SIZE = 320;           /* sprite radius in px  */
    var HALF = 0.44;          /* half-angle, ~25deg   */
    var c = T.canvas(SIZE * 2, SIZE * 2);
    var g = c.getContext('2d');
    g.translate(SIZE, SIZE);
    var gradR = g.createRadialGradient(0, 0, 0, 0, 0, SIZE);
    gradR.addColorStop(0, 'rgba(255,255,255,1)');
    gradR.addColorStop(0.22, 'rgba(255,255,255,1)');
    gradR.addColorStop(0.5, 'rgba(255,255,255,0.82)');
    gradR.addColorStop(0.74, 'rgba(255,255,255,0.45)');
    gradR.addColorStop(0.9, 'rgba(255,255,255,0.14)');
    gradR.addColorStop(1, 'rgba(255,255,255,0)');
    var N = 56;
    for (var i = 0; i < N; i++) {
      var a0 = -HALF + (i / N) * HALF * 2;
      var a1 = -HALF + ((i + 1) / N) * HALF * 2;
      var am = (a0 + a1) / 2;
      var f = Math.cos(am / HALF * Math.PI / 2);
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

  A.beam = (function () {
    var SIZE = 320;
    var HALF = 0.44;
    var c = T.canvas(SIZE * 2, SIZE * 2);
    var g = c.getContext('2d');
    g.translate(SIZE, SIZE);
    var gradR = g.createRadialGradient(0, 0, 0, 0, 0, SIZE);
    gradR.addColorStop(0, 'rgba(215,208,183,0.4)');
    gradR.addColorStop(0.4, 'rgba(215,208,183,0.2)');
    gradR.addColorStop(0.8, 'rgba(215,208,183,0.06)');
    gradR.addColorStop(1, 'rgba(215,208,183,0)');
    var N = 40;
    for (var i = 0; i < N; i++) {
      var a0 = -HALF + (i / N) * HALF * 2;
      var a1 = -HALF + ((i + 1) / N) * HALF * 2;
      var am = (a0 + a1) / 2;
      var f = Math.cos(am / HALF * Math.PI / 2);
      g.globalAlpha = Math.pow(f, 2.4);
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
      gr.addColorStop(0, 'rgba(168,178,170,0.5)');
      gr.addColorStop(0.6, 'rgba(150,160,152,0.16)');
      gr.addColorStop(1, 'rgba(150,160,152,0)');
      g.fillStyle = gr;
      g.fillRect(0, 0, 256, 256);
    }
    return c;
  })();

  /* ============================================================
     menu background: moon, forest silhouettes, lone walker
     ============================================================ */
  var menuStars = null, menuLayers = null;
  function buildMenu(seedw) {
    var r = T.rng(20240607);
    menuStars = [];
    for (var i = 0; i < 90; i++) {
      menuStars.push({ x: r(), y: r() * 0.55, s: r() * 1.3 + 0.3, a: 0.12 + r() * 0.4, tw: r() * 6 });
    }
    menuLayers = [];
    for (var L = 0; L < 3; L++) {
      var layer = [];
      var n = 14 + L * 9;
      for (var j = 0; j < n; j++) {
        layer.push({ x: r(), h: (0.16 + r() * 0.22) * (1 - L * 0.18), w: 0.02 + r() * 0.02 });
      }
      menuLayers.push(layer);
    }
  }
  function pineSil(ctx, x, baseY, h, w) {
    ctx.beginPath();
    ctx.moveTo(x - w, baseY);
    for (var i = 0; i < 4; i++) {
      var p = i / 4;
      var yy = baseY - h * p;
      var ww = w * (1 - p * 0.55);
      ctx.lineTo(x - ww * 0.72, yy - h * 0.12);
      ctx.lineTo(x - ww * 0.5, yy - h * 0.02);
    }
    ctx.lineTo(x, baseY - h);
    for (var i2 = 3; i2 >= 0; i2--) {
      var p2 = i2 / 4;
      var y2 = baseY - h * p2;
      var w2 = w * (1 - p2 * 0.55);
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
    /* sky */
    var sky = ctx.createLinearGradient(0, 0, 0, h);
    sky.addColorStop(0, '#05060b');
    sky.addColorStop(0.55, '#0a0d0f');
    sky.addColorStop(1, '#0B0D0D');
    ctx.fillStyle = sky;
    ctx.fillRect(0, 0, w, h);
    /* stars */
    for (var i = 0; i < menuStars.length; i++) {
      var st = menuStars[i];
      ctx.globalAlpha = st.a * (0.6 + 0.4 * Math.sin(t * 0.7 + st.tw));
      ctx.fillStyle = '#cfd6d2';
      ctx.fillRect(st.x * w + mx * 4, st.y * h + my * 3, st.s, st.s);
    }
    ctx.globalAlpha = 1;
    /* moon */
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
    ctx.beginPath();
    ctx.arc(moonX, moonY, mr, 0, T.TAU);
    ctx.fill();
    ctx.fillStyle = 'rgba(120,120,110,0.18)';
    ctx.beginPath(); ctx.arc(moonX + mr * 0.3, moonY - mr * 0.2, mr * 0.16, 0, T.TAU); ctx.fill();
    ctx.beginPath(); ctx.arc(moonX - mr * 0.25, moonY + mr * 0.3, mr * 0.1, 0, T.TAU); ctx.fill();
    /* forest layers, far -> near */
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
    /* ground */
    var gr2 = ctx.createLinearGradient(0, h * 0.88, 0, h);
    gr2.addColorStop(0, '#0a0e0b');
    gr2.addColorStop(1, '#070908');
    ctx.fillStyle = gr2;
    ctx.fillRect(0, h * 0.88, w, h * 0.12);
    /* clearing + path */
    ctx.fillStyle = 'rgba(30,44,34,0.42)';
    ctx.beginPath();
    ctx.ellipse(w * 0.5, h * 0.93, w * 0.3, h * 0.05, 0, 0, T.TAU);
    ctx.fill();
    /* faint path leading out of the clearing */
    ctx.strokeStyle = 'rgba(120,126,116,0.05)';
    ctx.lineWidth = 7;
    ctx.beginPath();
    ctx.moveTo(w * 0.5, h * 0.94);
    ctx.quadraticCurveTo(w * 0.53, h * 0.9, w * 0.5, h * 0.85);
    ctx.stroke();
    /* the lone walker + faint lantern */
    var px = w * 0.5 + Math.sin(t * 0.11) * 2 + mx * 14;
    var py = h * 0.905;
    var lg = ctx.createRadialGradient(px + 4, py - 8, 1, px + 4, py - 8, 60);
    lg.addColorStop(0, 'rgba(215,208,183,0.20)');
    lg.addColorStop(1, 'rgba(215,208,183,0)');
    ctx.fillStyle = lg;
    ctx.fillRect(px - 60, py - 68, 130, 130);
    ctx.fillStyle = '#020304';
    ctx.beginPath();
    ctx.ellipse(px, py - 8, 3.4, 5.2, 0, 0, T.TAU);
    ctx.fill();
    ctx.beginPath();
    ctx.arc(px, py - 15.4, 2.6, 0, T.TAU);
    ctx.fill();
    ctx.fillStyle = 'rgba(240,230,190,' + (0.5 + 0.2 * Math.sin(t * 2.2)) + ')';
    ctx.beginPath();
    ctx.arc(px + 4.4, py - 8.5, 1.5, 0, T.TAU);
    ctx.fill();
    /* drifting fog */
    ctx.globalAlpha = 0.10;
    for (var f = 0; f < 3; f++) {
      var fx2 = ((t * (6 + f * 4) + f * w / 3) % (w + 512)) - 256;
      ctx.drawImage(A.fogPuff, fx2, h * (0.74 + f * 0.06), 512, 200);
    }
    ctx.globalAlpha = 1;
    /* vignette */
    var v = ctx.createRadialGradient(w / 2, h / 2, Math.min(w, h) * 0.36, w / 2, h / 2, Math.max(w, h) * 0.72);
    v.addColorStop(0, 'rgba(0,0,0,0)');
    v.addColorStop(1, 'rgba(0,0,0,0.72)');
    ctx.fillStyle = v;
    ctx.fillRect(0, 0, w, h);
  };
})();
