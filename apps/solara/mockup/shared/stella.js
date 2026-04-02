/* ===== Solara Stella Message System ===== */
/* Generates contextual daily messages based on vibe score */

(function() {
  const TEMPLATES_HIGH = [
    "Your energy is magnetic today — trust every spark that lights within you.",
    "The cosmos celebrates your momentum. Ride this wave with open arms.",
    "You're perfectly aligned with the stars. Let your light spill into everything you touch.",
    "Radiance is your birthright today. Step boldly into every room.",
    "Your orbit blazes bright — others will feel your warmth from afar.",
    "The universe mirrors your joy back a thousandfold. Shine freely.",
    "Your frequency is golden today. Channel it into what matters most.",
  ];

  const TEMPLATES_MID = [
    "A gentle day unfolds. Observe the quiet rhythms around you.",
    "Balance is your compass today. Neither rush nor retreat — just be.",
    "The stars whisper patience. Small, steady steps create lasting orbits.",
    "Today holds hidden gifts in ordinary moments. Stay present.",
    "Your frequency is calibrating. Trust the process and breathe.",
    "The cosmos asks you to listen before you act. Wisdom comes softly.",
    "A transitional orbit — not every day needs to be extraordinary.",
  ];

  const TEMPLATES_LOW = [
    "Even the brightest stars rest between their shine. Be gentle with yourself.",
    "The moon teaches that darkness holds its own deep beauty.",
    "This quieter frequency is healing you in ways you can't yet see.",
    "Stillness is not emptiness — it's the universe making space for what comes next.",
    "Your inner world deserves your attention today. Go inward, go slowly.",
    "The cosmos holds you even in your heaviest moments. You are never alone.",
    "Rest is not retreat. Your orbit needs this pause to gather strength.",
  ];

  const TEMPLATES_HIGH_JP = [
    "今日のあなたのエネルギーは磁石のよう。内なる閃きを信じて。",
    "宇宙があなたの勢いを祝福している。この波に乗って。",
    "星々と完全に調和している。光を惜しみなく注いで。",
    "今日の輝きは生まれ持った権利。堂々と歩んで。",
    "あなたの軌道は力強く輝いている。遠くの人にも温もりが届くよ。",
  ];

  const TEMPLATES_MID_JP = [
    "穏やかな一日が広がる。周りの静かなリズムに耳を傾けて。",
    "バランスが今日の羅針盤。焦らず、退かず、ただ在ること。",
    "星たちは忍耐を囁いている。小さく確実な一歩が永遠の軌道を作る。",
    "今日は何気ない瞬間に隠された贈り物がある。今ここに集中して。",
  ];

  const TEMPLATES_LOW_JP = [
    "最も明るい星さえ輝きの合間に休む。自分に優しくしてね。",
    "月が教えてくれる、暗闇には暗闇の深い美しさがあると。",
    "この静かな波動が、まだ見えない形であなたを癒している。",
    "静寂は空虚ではない。次に来るもののために宇宙が空間を作っているの。",
  ];

  /**
   * Generate a Stella message based on vibe score and language.
   * @param {number} vibeScore -1.0 to +1.0
   * @param {string} lang 'en' or 'jp'
   * @returns {string} message
   */
  window.generateStellaMessage = function(vibeScore, lang) {
    lang = lang || 'en';
    let pool;
    if (vibeScore > 0.3) {
      pool = lang === 'jp' ? TEMPLATES_HIGH_JP : TEMPLATES_HIGH;
    } else if (vibeScore > -0.3) {
      pool = lang === 'jp' ? TEMPLATES_MID_JP : TEMPLATES_MID;
    } else {
      pool = lang === 'jp' ? TEMPLATES_LOW_JP : TEMPLATES_LOW;
    }
    // Use date as seed for daily consistency
    const today = new Date().toISOString().slice(0, 10);
    let hash = 0;
    for (let i = 0; i < today.length; i++) hash = ((hash << 5) - hash) + today.charCodeAt(i);
    return pool[Math.abs(hash) % pool.length];
  };

  /**
   * Render Stella message into a target element.
   * @param {string} targetId DOM element ID
   * @param {number} vibeScore
   * @param {string} lang
   */
  window.renderStellaMessage = function(targetId, vibeScore, lang) {
    const el = document.getElementById(targetId);
    if (!el) return;
    const msg = generateStellaMessage(vibeScore, lang);
    el.innerHTML = '<div style="font-size:10px;font-weight:700;color:#F9D976;letter-spacing:1.8px;text-transform:uppercase;margin-bottom:7px;">✦ Stella</div>'
      + '<div style="font-size:13px;font-weight:300;color:#EAEAEA;line-height:1.6;">"' + msg + '"</div>';
  };
})();
