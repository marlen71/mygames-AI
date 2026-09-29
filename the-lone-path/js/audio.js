/* ============================================================
   THE LONE PATH — procedural audio (Web Audio API, no files)
   wind + drone + rare birds + fire crackle + small stings
   ============================================================ */
'use strict';
(function (T) {
  var A = {};
  TLP.Audio = A;

  var ctx = null, master = null, muted = false, started = false;
  var windGain, droneGain, fireGain, fireBursts = null;
  var birdTimer = null;

  A.ok = function () { return !!ctx; };
  A.muted = false;

  A.ensure = function () {
    if (ctx) { if (ctx.state === 'suspended') ctx.resume(); return; }
    var AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return;
    ctx = new AC();
    master = ctx.createGain();
    master.gain.value = muted ? 0 : 0.65;
    master.connect(ctx.destination);
  };

  A.mute = function (m) {
    muted = m;
    A.muted = m;
    if (ctx) master.gain.setTargetAtTime(m ? 0 : 0.65, ctx.currentTime, 0.1);
    return muted;
  };

  /* ---------- noise buffer ---------- */
  function noiseBuffer(seconds) {
    var len = Math.floor(ctx.sampleRate * seconds);
    var buf = ctx.createBuffer(1, len, ctx.sampleRate);
    var d = buf.getChannelData(0);
    var r = TLP.rng(77);
    for (var i = 0; i < len; i++) d[i] = r() * 2 - 1;
    return buf;
  }

  /* ---------- ambient bed ---------- */
  A.startAmbient = function () {
    A.ensure();
    if (!ctx || started) return;
    started = true;
    var t = ctx.currentTime;

    /* WIND: looped noise -> bandpass with slow LFO */
    var wind = ctx.createBufferSource();
    wind.buffer = noiseBuffer(6);
    wind.loop = true;
    var bp = ctx.createBiquadFilter();
    bp.type = 'bandpass'; bp.frequency.value = 300; bp.Q.value = 0.55;
    windGain = ctx.createGain(); windGain.gain.value = 0.035;
    var lfo = ctx.createOscillator(); lfo.frequency.value = 0.06;
    var lfoG = ctx.createGain(); lfoG.gain.value = 0.022;
    lfo.connect(lfoG); lfoG.connect(windGain.gain);
    var lfo2 = ctx.createOscillator(); lfo2.frequency.value = 0.045;
    var lfo2G = ctx.createGain(); lfo2G.gain.value = 130;
    lfo2.connect(lfo2G); lfo2G.connect(bp.frequency);
    wind.connect(bp); bp.connect(windGain); windGain.connect(master);
    wind.start(t); lfo.start(t); lfo2.start(t);

    /* DRONE: two detuned low oscillators, very quiet */
    droneGain = ctx.createGain(); droneGain.gain.value = 0.0;
    droneGain.gain.setTargetAtTime(0.03, t, 8);
    var lp = ctx.createBiquadFilter(); lp.type = 'lowpass'; lp.frequency.value = 220;
    var o1 = ctx.createOscillator(); o1.type = 'sine'; o1.frequency.value = 54.5;
    var o2 = ctx.createOscillator(); o2.type = 'triangle'; o2.frequency.value = 82.4;
    var o2g = ctx.createGain(); o2g.gain.value = 0.35;
    var dlfo = ctx.createOscillator(); dlfo.frequency.value = 0.031;
    var dlfoG = ctx.createGain(); dlfoG.gain.value = 0.014;
    dlfo.connect(dlfoG); dlfoG.connect(droneGain.gain);
    o1.connect(lp); o2.connect(o2g); o2g.connect(lp);
    lp.connect(droneGain); droneGain.connect(master);
    o1.start(t); o2.start(t); dlfo.start(t);

    /* FIRE: crackle bus (only audible when enabled + near) */
    fireGain = ctx.createGain(); fireGain.gain.value = 0;
    fireGain.connect(master);

    /* rare birds */
    scheduleBird();
  };

  function scheduleBird() {
    clearTimeout(birdTimer);
    birdTimer = setTimeout(function () {
      if (ctx && !muted && Math.random() < 0.75) birdChirp();
      scheduleBird();
    }, 9000 + Math.random() * 18000);
  }

  function birdChirp() {
    var t0 = ctx.currentTime + 0.02;
    var g = ctx.createGain();
    g.gain.value = 0.0; g.connect(master);
    var o = ctx.createOscillator(); o.type = 'sine';
    o.connect(g);
    var n = 2 + Math.floor(Math.random() * 3);
    var f = 1900 + Math.random() * 900;
    for (var i = 0; i < n; i++) {
      var t = t0 + i * (0.09 + Math.random() * 0.05);
      o.frequency.setValueAtTime(f * (0.9 + Math.random() * 0.3), t);
      o.frequency.exponentialRampToValueAtTime(f * (1.15 + Math.random() * 0.5), t + 0.05);
      g.gain.setValueAtTime(0.0001, t);
      g.gain.exponentialRampToValueAtTime(0.018, t + 0.015);
      g.gain.exponentialRampToValueAtTime(0.0001, t + 0.09);
    }
    o.start(t0); o.stop(t0 + 0.6);
  }

  /* ---------- fire near-field ---------- */
  A.setFire = function (on, proximity) {
    if (!ctx || !fireGain) return;
    var target = on ? 0.16 * proximity : 0;
    fireGain.gain.setTargetAtTime(target, ctx.currentTime, 0.4);
    if (on && !fireBursts) startFireBursts();
  };
  function startFireBursts() {
    fireBursts = { timer: null };
    var loop = function () {
      if (!ctx) return;
      if (fireGain.gain.value > 0.002) {
        var t = ctx.currentTime + 0.01;
        var src = ctx.createBufferSource();
        src.buffer = noiseBuffer(0.05 + Math.random() * 0.06);
        var f = ctx.createBiquadFilter(); f.type = 'highpass';
        f.frequency.value = 900 + Math.random() * 1800;
        var g = ctx.createGain();
        g.gain.setValueAtTime(0.0001, t);
        g.gain.exponentialRampToValueAtTime(0.05 + Math.random() * 0.07, t + 0.008);
        g.gain.exponentialRampToValueAtTime(0.0001, t + 0.07);
        src.connect(f); f.connect(g); g.connect(fireGain);
        src.start(t);
      }
      fireBursts.timer = setTimeout(loop, 60 + Math.random() * 340);
    };
    loop();
  }

  /* ---------- one-shot stings ---------- */
  A.noteGet = function () {
    if (!ctx || muted) return;
    var t = ctx.currentTime;
    [523.25, 784.0].forEach(function (f, i) {
      var o = ctx.createOscillator(); o.type = 'sine'; o.frequency.value = f;
      var g = ctx.createGain();
      var st = t + i * 0.16;
      g.gain.setValueAtTime(0.0001, st);
      g.gain.exponentialRampToValueAtTime(0.06, st + 0.02);
      g.gain.exponentialRampToValueAtTime(0.0001, st + 1.4);
      o.connect(g); g.connect(master);
      o.start(st); o.stop(st + 1.5);
    });
  };

  A.ui = function (deep) {
    if (!ctx || muted) return;
    var t = ctx.currentTime;
    var o = ctx.createOscillator();
    o.type = deep ? 'sine' : 'square';
    o.frequency.setValueAtTime(deep ? 110 : 210, t);
    o.frequency.exponentialRampToValueAtTime(deep ? 55 : 150, t + 0.09);
    var g = ctx.createGain();
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(deep ? 0.09 : 0.03, t + 0.01);
    g.gain.exponentialRampToValueAtTime(0.0001, t + 0.16);
    o.connect(g); g.connect(master);
    o.start(t); o.stop(t + 0.2);
  };

  /* heartbeat for the final scene */
  A.heartbeat = function () {
    if (!ctx || muted) return;
    var t = ctx.currentTime;
    for (var i = 0; i < 6; i++) {
      var thump = function (st, vol) {
        var o = ctx.createOscillator(); o.type = 'sine';
        o.frequency.setValueAtTime(52, st);
        o.frequency.exponentialRampToValueAtTime(36, st + 0.12);
        var g = ctx.createGain();
        g.gain.setValueAtTime(0.0001, st);
        g.gain.exponentialRampToValueAtTime(vol, st + 0.015);
        g.gain.exponentialRampToValueAtTime(0.0001, st + 0.22);
        o.connect(g); g.connect(master);
        o.start(st); o.stop(st + 0.3);
      };
      thump(t + i * 0.85, 0.10 + i * 0.015);
      thump(t + i * 0.85 + 0.26, 0.06 + i * 0.012);
    }
  };

  /* dark swell for the finale */
  A.swell = function () {
    if (!ctx) return;
    var t = ctx.currentTime;
    droneGain.gain.cancelScheduledValues(t);
    droneGain.gain.setValueAtTime(Math.max(0.03, droneGain.gain.value), t);
    droneGain.gain.linearRampToValueAtTime(0.10, t + 4.5);
    droneGain.gain.linearRampToValueAtTime(0.006, t + 8.5);
    setTimeout(function () {
      if (droneGain) droneGain.gain.setTargetAtTime(0.03, ctx.currentTime, 6);
    }, 10000);
  };

  /* low sting on "you were never alone" */
  A.sting = function () {
    if (!ctx) return;
    var t = ctx.currentTime;
    var o = ctx.createOscillator(); o.type = 'triangle';
    o.frequency.setValueAtTime(140, t);
    o.frequency.exponentialRampToValueAtTime(40, t + 2.2);
    var g = ctx.createGain();
    g.gain.setValueAtTime(0.0001, t);
    g.gain.exponentialRampToValueAtTime(0.12, t + 0.4);
    g.gain.exponentialRampToValueAtTime(0.0001, t + 3.2);
    o.connect(g); g.connect(master);
    o.start(t); o.stop(t + 3.4);
  };

  /* the old engine turning over: two detuned low oscillators behind a filter */
  var eng = null;
  A.engine = function (on, level) {
    if (!ctx) return;
    if (on && !eng) {
      var o1 = ctx.createOscillator(), o2 = ctx.createOscillator();
      var f = ctx.createBiquadFilter(), g = ctx.createGain();
      o1.type = 'sawtooth'; o2.type = 'square';
      o1.frequency.value = 34; o2.frequency.value = 51.5;
      f.type = 'lowpass'; f.frequency.value = 190;
      g.gain.value = 0.0001;
      o1.connect(f); o2.connect(f); f.connect(g); g.connect(master);
      o1.start(); o2.start();
      eng = { o1: o1, o2: o2, g: g };
    }
    if (eng) {
      var lv = on ? TLP.clamp(level, 0, 1) : 0;
      var t = ctx.currentTime;
      eng.o1.frequency.setTargetAtTime(30 + 42 * lv, t, 0.15);
      eng.o2.frequency.setTargetAtTime(45 + 70 * lv, t, 0.15);
      eng.g.gain.setTargetAtTime(muted ? 0.0001 : 0.0001 + lv * 0.05, t, 0.12);
      if (!on) {
        var e2 = eng; eng = null;
        setTimeout(function () { try { e2.o1.stop(); e2.o2.stop(); } catch (e) { } }, 600);
      }
    }
  };
  /* wrench tick on the car */
  A.ratchet = function (heavy) {
    if (!ctx) return;
    var t = ctx.currentTime;
    var src = ctx.createBufferSource();
    src.buffer = noiseBuffer(0.08);
    var f = ctx.createBiquadFilter();
    f.type = 'bandpass'; f.frequency.value = heavy ? 900 : 2400; f.Q.value = 6;
    var g = ctx.createGain();
    g.gain.setValueAtTime(0.16, t);
    g.gain.exponentialRampToValueAtTime(0.0001, t + (heavy ? 0.14 : 0.07));
    src.connect(f); f.connect(g); g.connect(master);
    src.start(t);
  };

  /* fade everything down on leaving the game */
  A.quiet = function (q) {
    if (!ctx) return;
    windGain.gain.setTargetAtTime(q ? 0.004 : 0.035, ctx.currentTime, 0.5);
    droneGain.gain.setTargetAtTime(q ? 0.0 : 0.03, ctx.currentTime, 0.5);
  };
})(window);
