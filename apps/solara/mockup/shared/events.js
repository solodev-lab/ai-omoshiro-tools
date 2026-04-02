/* ===== Solara Moon Event Overlays ===== */
/* Dynamically injects overlay HTML and handles show/hide/effects */

(function() {
  /** Inject overlay HTML into current page if not already present */
  function ensureOverlays() {
    if (document.getElementById('overlayNewMoon')) return;

    const container = document.querySelector('.phone') || document.body;
    const html = `
    <!-- NEW MOON OVERLAY -->
    <div class="overlay-screen" id="overlayNewMoon">
      <div style="width:100%;padding:40px 28px;display:flex;flex-direction:column;gap:22px;align-items:center;">
        <div class="stella-orb" style="width:72px;height:72px;font-size:32px;background:radial-gradient(circle,rgba(26,41,128,0.8) 0%,rgba(38,208,206,0.15) 70%);border-color:rgba(38,208,206,0.3);box-shadow:0 0 40px rgba(38,208,206,0.2);">🌑</div>
        <div style="font-size:22px;font-weight:700;text-align:center;color:#EAEAEA;">New Moon Intentions</div>
        <div style="font-size:13px;color:rgba(172,172,172,0.75);text-align:center;line-height:1.6;">"A new cycle begins. Plant your three seeds of intention."</div>
        <div style="width:100%;display:flex;flex-direction:column;gap:12px;">
          <div>
            <div style="font-size:10px;font-weight:700;color:rgba(38,208,206,0.8);letter-spacing:1.5px;text-transform:uppercase;margin-bottom:4px;">✦ Intention I — What to Create</div>
            <input class="glass-input" type="text" placeholder="e.g. Build something that matters…" id="nmIntent1" />
          </div>
          <div>
            <div style="font-size:10px;font-weight:700;color:rgba(38,208,206,0.8);letter-spacing:1.5px;text-transform:uppercase;margin-bottom:4px;">✦ Intention II — What to Release</div>
            <input class="glass-input" type="text" placeholder="e.g. Let go of self-doubt…" id="nmIntent2" />
          </div>
          <div>
            <div style="font-size:10px;font-weight:700;color:rgba(38,208,206,0.8);letter-spacing:1.5px;text-transform:uppercase;margin-bottom:4px;">✦ Intention III — What to Become</div>
            <input class="glass-input" type="text" placeholder="e.g. Radiate calm clarity…" id="nmIntent3" />
          </div>
        </div>
        <button class="gold-btn" onclick="sealIntentions()" style="margin-top:4px;">Seal my Intentions ✦</button>
        <button class="ghost-btn" onclick="closeNewMoonOverlay()">Not today</button>
      </div>
    </div>

    <!-- FULL MOON OVERLAY -->
    <div class="overlay-screen" id="overlayFullMoon" style="background:rgba(4,8,16,0.98);">
      <div style="width:100%;padding:40px 28px;display:flex;flex-direction:column;gap:20px;align-items:center;text-align:center;">
        <div style="font-size:42px;animation:orbPulse 2s ease-in-out infinite;">🌕</div>
        <div style="font-size:22px;font-weight:700;color:#EAEAEA;">Full Moon — Day 14</div>
        <div style="font-size:13px;color:rgba(172,172,172,0.75);line-height:1.6;">"Your cycle reaches its peak. Watch your intentions transform."</div>
        <canvas id="fullMoonCanvas" width="280" height="120" style="border-radius:16px;"></canvas>
        <button class="gold-btn" onclick="startDisintegrateEffect()" style="width:220px;">✨ Ignite the Release</button>
        <button class="ghost-btn" onclick="closeFullMoonOverlay()" style="width:220px;">Close</button>
      </div>
    </div>`;

    container.insertAdjacentHTML('beforeend', html);
  }

  /** Show New Moon overlay */
  window.showNewMoonOverlay = function() {
    ensureOverlays();
    // Load saved intentions
    try {
      const saved = JSON.parse(localStorage.getItem('solara_intentions') || '{}');
      if (saved.i1) document.getElementById('nmIntent1').value = saved.i1;
      if (saved.i2) document.getElementById('nmIntent2').value = saved.i2;
      if (saved.i3) document.getElementById('nmIntent3').value = saved.i3;
    } catch(e) {}
    document.getElementById('overlayNewMoon').classList.add('visible');
  };

  /** Seal intentions and close */
  window.sealIntentions = function() {
    const i1 = document.getElementById('nmIntent1').value.trim();
    const i2 = document.getElementById('nmIntent2').value.trim();
    const i3 = document.getElementById('nmIntent3').value.trim();
    if (i1 || i2 || i3) {
      localStorage.setItem('solara_intentions', JSON.stringify({ i1, i2, i3, date: new Date().toISOString() }));
    }
    closeNewMoonOverlay();
  };

  /** Close New Moon overlay */
  window.closeNewMoonOverlay = function() {
    const el = document.getElementById('overlayNewMoon');
    if (el) el.classList.remove('visible');
  };

  /** Show Full Moon overlay */
  window.showFullMoonOverlay = function() {
    ensureOverlays();
    document.getElementById('overlayFullMoon').classList.add('visible');
    drawFullMoonText();
  };

  /** Close Full Moon overlay */
  window.closeFullMoonOverlay = function() {
    const el = document.getElementById('overlayFullMoon');
    if (el) el.classList.remove('visible');
  };

  /** Draw text on Full Moon canvas */
  function drawFullMoonText() {
    const canvas = document.getElementById('fullMoonCanvas');
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    ctx.clearRect(0, 0, 280, 120);
    // Load intentions for display
    let text = '"My intentions have bloomed"';
    try {
      const saved = JSON.parse(localStorage.getItem('solara_intentions') || '{}');
      if (saved.i1) text = `"${saved.i1}"`;
    } catch(e) {}
    ctx.fillStyle = 'rgba(249,217,118,0.85)';
    ctx.font = 'bold 18px Lato, sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText(text.length > 35 ? text.slice(0, 35) + '…"' : text, 140, 45);
    ctx.font = '300 13px Lato, sans-serif';
    ctx.fillStyle = 'rgba(172,172,172,0.7)';
    ctx.fillText('Tap Ignite to release them to the cosmos', 140, 80);
  }

  /** Full Moon disintegrate particle effect */
  let disintegrateRAF = null;
  window.startDisintegrateEffect = function() {
    const canvas = document.getElementById('fullMoonCanvas');
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    const W = 280, H = 120;
    const img = ctx.getImageData(0, 0, W, H);
    const particles = [];
    for (let y = 0; y < H; y += 2) {
      for (let x = 0; x < W; x += 2) {
        const idx = (y * W + x) * 4;
        const a = img.data[idx + 3];
        if (a > 40) {
          particles.push({
            x, y, vx: (Math.random() - 0.5) * 1.2,
            vy: -Math.random() * 1.8 - 0.4,
            r: img.data[idx], g: img.data[idx + 1], b: img.data[idx + 2],
            life: 1.0, decay: 0.008 + Math.random() * 0.018,
          });
        }
      }
    }
    function anim() {
      ctx.clearRect(0, 0, W, H);
      let alive = false;
      particles.forEach(p => {
        if (p.life <= 0) return;
        p.life -= p.decay; alive = true;
        p.x += p.vx; p.y += p.vy;
        p.vy -= 0.012;
        p.vx += Math.sin(p.y * 0.1) * 0.05;
        const t = 1 - p.life;
        ctx.fillStyle = `rgba(${Math.round(p.r + t * (255 - p.r))},${Math.round(p.g + t * (100 - p.g))},${Math.round(p.b * (1 - t))},${p.life * 0.9})`;
        ctx.beginPath(); ctx.arc(p.x, p.y, 1.1, 0, Math.PI * 2); ctx.fill();
      });
      if (alive) disintegrateRAF = requestAnimationFrame(anim);
      else {
        ctx.fillStyle = 'rgba(249,217,118,0.4)';
        ctx.font = '300 13px Lato, sans-serif';
        ctx.textAlign = 'center';
        ctx.fillText('Released to the cosmos ✦', 140, 60);
      }
    }
    if (disintegrateRAF) cancelAnimationFrame(disintegrateRAF);
    anim();
  };

  /**
   * Simple moon phase calculation (Metonic cycle approximation).
   * Returns phase 0-29 (0=new moon, 14-15=full moon).
   */
  function getMoonPhase() {
    const now = new Date();
    // Known new moon: Jan 6 2000 18:14 UTC
    const knownNew = new Date(2000, 0, 6, 18, 14, 0);
    const daysSince = (now - knownNew) / 86400000;
    const synodicMonth = 29.53059;
    const phase = ((daysSince % synodicMonth) + synodicMonth) % synodicMonth;
    return Math.floor(phase);
  }

  /**
   * Check moon phase and auto-trigger overlay if appropriate.
   * Call from any page that loads events.js.
   * Only triggers once per day (uses localStorage).
   */
  window.checkMoonEvents = function() {
    const today = new Date().toISOString().slice(0, 10);
    const key = 'solara_moon_event_shown';
    try {
      if (localStorage.getItem(key) === today) return;
    } catch(e) {}

    const phase = getMoonPhase();
    if (phase === 0 || phase === 1) {
      // New Moon: show overlay after short delay
      setTimeout(function() {
        showNewMoonOverlay();
        try { localStorage.setItem(key, today); } catch(e) {}
      }, 2000);
    } else if (phase === 14 || phase === 15) {
      // Full Moon: show overlay after short delay
      setTimeout(function() {
        showFullMoonOverlay();
        try { localStorage.setItem(key, today); } catch(e) {}
      }, 2000);
    }
  };

  /** Get current moon phase info for display */
  window.getMoonPhaseInfo = function() {
    const phase = getMoonPhase();
    if (phase <= 1) return { phase: 'new', emoji: '🌑', label: 'New Moon' };
    if (phase <= 6) return { phase: 'waxing-crescent', emoji: '🌒', label: 'Waxing Crescent' };
    if (phase <= 8) return { phase: 'first-quarter', emoji: '🌓', label: 'First Quarter' };
    if (phase <= 13) return { phase: 'waxing-gibbous', emoji: '🌔', label: 'Waxing Gibbous' };
    if (phase <= 16) return { phase: 'full', emoji: '🌕', label: 'Full Moon' };
    if (phase <= 21) return { phase: 'waning-gibbous', emoji: '🌖', label: 'Waning Gibbous' };
    if (phase <= 23) return { phase: 'last-quarter', emoji: '🌗', label: 'Last Quarter' };
    return { phase: 'waning-crescent', emoji: '🌘', label: 'Waning Crescent' };
  };
})();
