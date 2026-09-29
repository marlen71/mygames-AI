/* ============================================================
   THE LONE PATH — utils
   ============================================================ */
'use strict';
window.TLP = window.TLP || {};
(function (T) {
  T.TAU = Math.PI * 2;

  T.clamp = function (v, a, b) { return v < a ? a : (v > b ? b : v); };
  T.lerp = function (a, b, t) { return a + (b - a) * t; };
  T.smooth = function (a, b, dt, rate) { return T.lerp(a, b, 1 - Math.pow(1 - rate, dt * 60)); };

  /* deterministic rng (mulberry32) */
  T.rng = function (seed) {
    var s = seed >>> 0;
    return function () {
      s |= 0; s = (s + 0x6D2B79F5) | 0;
      var t = Math.imul(s ^ (s >>> 15), 1 | s);
      t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  };

  T.dist2 = function (ax, ay, bx, by) {
    var dx = ax - bx, dy = ay - by;
    return dx * dx + dy * dy;
  };

  /* shortest angle lerp */
  T.angleLerp = function (a, b, t) {
    var d = ((b - a + Math.PI) % T.TAU + T.TAU) % T.TAU - Math.PI;
    return a + d * t;
  };

  T.canvas = function (w, h) {
    var c = document.createElement('canvas');
    c.width = w; c.height = h;
    return c;
  };
})(window.TLP);
