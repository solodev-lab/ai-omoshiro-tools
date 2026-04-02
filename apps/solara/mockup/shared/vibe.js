/* ===== Solara Vibe Score System ===== */

/**
 * Calculate vibe score from components.
 * S = Tarot×0.4 + Mood×0.1 + Transit×0.3 + Progressed×0.2
 * All inputs should be in -1.0 to +1.0 range.
 */
function calcVibeScore({ tarot = 0, mood = 0, transit = 0, progressed = 0 }) {
  return Math.max(-1, Math.min(1, tarot * 0.4 + mood * 0.1 + transit * 0.3 + progressed * 0.2));
}

/**
 * Map vibe score (-1 to +1) to RGBA color string.
 * deep-blue → cyan → gold gradient
 */
function vibeToColor(vibe, alpha) {
  if (vibe > 0.3) {
    const t = (vibe - 0.3) / 0.7;
    return `rgba(${Math.round(246 + t * 9)},${Math.round(189 + t * 28)},${Math.round(96 - t * 96)},${alpha})`;
  } else if (vibe > -0.3) {
    const t = (vibe + 0.3) / 0.6;
    return `rgba(${Math.round(38 + t * 208)},${Math.round(208 - t * 19)},${Math.round(206 - t * 110)},${alpha})`;
  } else {
    const t = (vibe + 1.0) / 0.7;
    return `rgba(${Math.round(26 + t * 12)},${Math.round(41 + t * 167)},${Math.round(128 + t * 78)},${alpha})`;
  }
}

/** Save today's vibe to localStorage */
function saveVibe(score) {
  const today = new Date().toISOString().slice(0, 10);
  localStorage.setItem('solara_vibe_today', JSON.stringify({ date: today, score }));
}

/** Load today's vibe from localStorage (returns null if stale) */
function loadVibe() {
  try {
    const data = JSON.parse(localStorage.getItem('solara_vibe_today'));
    if (data && data.date === new Date().toISOString().slice(0, 10)) return data.score;
  } catch (e) {}
  return null;
}

/** Save mood value */
function saveMood(val) {
  localStorage.setItem('solara_mood', JSON.stringify(val));
}

/** Load mood value (default 0) */
function loadMood() {
  try { return JSON.parse(localStorage.getItem('solara_mood')) || 0; } catch (e) { return 0; }
}
