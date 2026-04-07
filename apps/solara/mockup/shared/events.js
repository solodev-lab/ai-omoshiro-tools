/* ===== Solara Moon Event Overlays — 3-Beat Intention System ===== */
/* New Moon → Full Moon → Crystallization cycle with selectable themes */

(function() {

  /* ───── Embedded Celestial Events 2026 (fallback) ───── */
  const CELESTIAL_2026 = [
    {
      month: 1,
      newMoonSign: "Capricorn", newMoonSignJP: "山羊座",
      fullMoonName: "Wolf Moon", fullMoonNameJP: "狼の月",
      events: [
        {type:"ingress", descJP:"海王星が牡羊座へ移行（1/26）"}
      ],
      themes: {
        en: ["over-planning without acting","fear of starting fresh","clinging to outdated structures"],
        jp: ["行動せずに計画ばかりすること","新しい始まりへの恐れ","古い枠組みへの執着"]
      }
    },
    {
      month: 2,
      newMoonSign: "Aquarius", newMoonSignJP: "水瓶座",
      fullMoonName: "Snow Moon", fullMoonNameJP: "雪の月",
      events: [
        {type:"ingress", descJP:"土星が牡羊座へ移行（2/13）"},
        {type:"conjunction", descJP:"土星・海王星が牡羊座で合（2/20）"},
        {type:"eclipse", descJP:"水瓶座の日食（2/17）"},
        {type:"retrograde", descJP:"水星逆行・魚座（2/25〜3/20）"}
      ],
      themes: {
        en: ["rigid thinking about the future","resistance to collective change","miscommunication from assumptions"],
        jp: ["未来に対する硬い考え方","変化への抵抗感","思い込みによる伝達ミス"]
      }
    },
    {
      month: 3,
      newMoonSign: "Pisces", newMoonSignJP: "魚座",
      fullMoonName: "Worm Moon", fullMoonNameJP: "芽吹きの月",
      events: [
        {type:"eclipse", descJP:"乙女座の月食（3/3）"},
        {type:"retrograde_end", descJP:"水星順行へ（3/20）"}
      ],
      themes: {
        en: ["perfectionism that blocks flow","escaping into fantasy","over-analyzing emotions"],
        jp: ["流れを止める完璧主義","空想への逃避","感情の過剰分析"]
      }
    },
    {
      month: 4,
      newMoonSign: "Aries", newMoonSignJP: "牡羊座",
      fullMoonName: "Pink Moon", fullMoonNameJP: "桃色の月",
      events: [
        {type:"ingress", descJP:"天王星が双子座へ移行（4/25）"}
      ],
      themes: {
        en: ["impatience with slow progress","ego-driven decisions","avoiding vulnerability"],
        jp: ["遅い進歩への焦り","エゴに基づく判断","弱さを見せることへの回避"]
      }
    },
    {
      month: 5,
      newMoonSign: "Taurus", newMoonSignJP: "牡牛座",
      fullMoonName: "Flower Moon", fullMoonNameJP: "花の月",
      events: [
        {type:"retrograde", descJP:"冥王星逆行・水瓶座（5/6〜10/15）"}
      ],
      themes: {
        en: ["attachment to material comfort","resisting necessary transformation","stubbornness disguised as stability"],
        jp: ["物質的安楽への執着","必要な変容への抵抗","安定を装った頑固さ"]
      }
    },
    {
      month: 6,
      newMoonSign: "Gemini", newMoonSignJP: "双子座",
      fullMoonName: "Strawberry Moon", fullMoonNameJP: "苺の月",
      events: [
        {type:"ingress", descJP:"キロンが牡牛座へ移行（6/19）"},
        {type:"ingress", descJP:"木星が獅子座へ移行（6/29）"},
        {type:"retrograde", descJP:"水星逆行・蟹座（6/29〜7/23）"}
      ],
      themes: {
        en: ["scattered energy and distraction","superficial connections over depth","avoiding deep wounds by staying busy"],
        jp: ["エネルギーの分散と気の散り","深い繋がりより表面的な付き合い","忙しさで深い傷から目を逸らすこと"]
      }
    },
    {
      month: 7,
      newMoonSign: "Cancer", newMoonSignJP: "蟹座",
      fullMoonName: "Buck Moon", fullMoonNameJP: "雄鹿の月",
      events: [
        {type:"retrograde_end", descJP:"水星順行へ（7/23）"},
        {type:"retrograde", descJP:"土星逆行開始（7/26）"},
        {type:"node_shift", descJP:"ノースノードが水瓶座へ（7/26）"}
      ],
      themes: {
        en: ["emotional walls that block intimacy","carrying others' burdens as your own","nostalgic clinging to the past"],
        jp: ["親密さを阻む感情の壁","他人の荷物を自分のものにすること","過去への郷愁的な執着"]
      }
    },
    {
      month: 8,
      newMoonSign: "Leo", newMoonSignJP: "獅子座",
      fullMoonName: "Sturgeon Moon", fullMoonNameJP: "チョウザメの月",
      events: [
        {type:"eclipse", descJP:"獅子座の日食（8/12）"},
        {type:"eclipse", descJP:"魚座の月食（8/27）"},
        {type:"retrograde", descJP:"海王星逆行・牡羊座（7/7〜12/12）"}
      ],
      themes: {
        en: ["need for external validation","creative blocks from self-doubt","drama as a substitute for substance"],
        jp: ["外部からの承認欲求","自己疑念による創造性の停滞","中身の代わりにドラマを求めること"]
      }
    },
    {
      month: 9,
      newMoonSign: "Virgo", newMoonSignJP: "乙女座",
      fullMoonName: "Harvest Moon", fullMoonNameJP: "収穫の月",
      events: [],
      themes: {
        en: ["self-criticism masked as high standards","anxiety about imperfection","neglecting rest for productivity"],
        jp: ["高い基準を装った自己批判","不完全さへの不安","生産性のために休息を犠牲にすること"]
      }
    },
    {
      month: 10,
      newMoonSign: "Libra", newMoonSignJP: "天秤座",
      fullMoonName: "Hunter's Moon", fullMoonNameJP: "狩人の月",
      events: [
        {type:"retrograde", descJP:"金星逆行・蠍座/天秤座（10/3〜11/13）"},
        {type:"retrograde", descJP:"水星逆行・蠍座（10/24〜11/13）"}
      ],
      themes: {
        en: ["people-pleasing at your own expense","reopening old relationship wounds","avoiding conflict to keep false peace"],
        jp: ["自分を犠牲にした八方美人","過去の関係の傷を掘り返すこと","偽りの平和のために対立を避けること"]
      }
    },
    {
      month: 11,
      newMoonSign: "Scorpio", newMoonSignJP: "蠍座",
      fullMoonName: "Beaver Moon", fullMoonNameJP: "ビーバーの月",
      events: [
        {type:"retrograde_end", descJP:"水星順行へ（11/13）"},
        {type:"retrograde_end", descJP:"金星順行へ（11/13）"},
        {type:"retrograde", descJP:"木星逆行・獅子座（12/12〜4/12）"}
      ],
      themes: {
        en: ["secrets kept out of fear","obsessive control over outcomes","refusing to trust after betrayal"],
        jp: ["恐怖から守る秘密","結果への執着的な支配","裏切り後の信頼拒否"]
      }
    },
    {
      month: 12,
      newMoonSign: "Sagittarius", newMoonSignJP: "射手座",
      fullMoonName: "Cold Moon", fullMoonNameJP: "寒月",
      events: [
        {type:"retrograde_end", descJP:"土星順行へ（12/10）"},
        {type:"retrograde_end", descJP:"海王星順行へ（12/12）"},
        {type:"retrograde", descJP:"木星逆行開始（12/12）"}
      ],
      themes: {
        en: ["restlessness disguised as ambition","preaching wisdom you don't practice","running from commitment"],
        jp: ["野心を装った落ち着きのなさ","実践しない知恵を説くこと","コミットメントからの逃走"]
      }
    }
  ];

  /* ───── Helper: get data for current month ───── */
  function getMonthData(month) {
    return CELESTIAL_2026.find(function(m) { return m.month === month; }) || CELESTIAL_2026[0];
  }

  /* ───── LocalStorage helpers ───── */
  var LS_INTENTION = 'solara_lunar_intention';
  var LS_SHOWN_PREFIX = 'solara_moon_shown_';

  function getCurrentCycleId() {
    var d = new Date();
    var y = d.getFullYear();
    var m = String(d.getMonth() + 1).padStart(2, '0');
    return y + '-' + m;
  }

  function loadIntention() {
    try {
      var raw = localStorage.getItem(LS_INTENTION);
      if (!raw) return null;
      var obj = JSON.parse(raw);
      if (obj && obj.cycleId === getCurrentCycleId()) return obj;
      return null;
    } catch(e) { return null; }
  }

  // Load intention regardless of cycleId (for catching uncrystallized previous cycles)
  function loadAnyIntention() {
    try {
      var raw = localStorage.getItem(LS_INTENTION);
      if (!raw) return null;
      return JSON.parse(raw);
    } catch(e) { return null; }
  }

  function saveIntention(intention) {
    try { localStorage.setItem(LS_INTENTION, JSON.stringify(intention)); } catch(e) {}
  }

  function wasShownToday(type) {
    try {
      var today = new Date().toISOString().slice(0, 10);
      return localStorage.getItem(LS_SHOWN_PREFIX + type) === today;
    } catch(e) { return false; }
  }

  function markShown(type) {
    try {
      var today = new Date().toISOString().slice(0, 10);
      localStorage.setItem(LS_SHOWN_PREFIX + type, today);
    } catch(e) {}
  }

  /* ───── Shared overlay CSS (injected once) ───── */
  function injectOverlayStyles() {
    if (document.getElementById('solara-moon-overlay-styles')) return;
    var style = document.createElement('style');
    style.id = 'solara-moon-overlay-styles';
    style.textContent = [
      '.moon-overlay-screen {',
      '  position:fixed; top:0; left:0; width:100%; height:100%; z-index:9999;',
      '  background:rgba(4,8,16,0.98); display:flex; flex-direction:column;',
      '  align-items:center; justify-content:center; opacity:0; pointer-events:none;',
      '  transition:opacity 0.5s ease; overflow-y:auto;',
      '}',
      '.moon-overlay-screen.visible { opacity:1 !important; pointer-events:auto !important; }',
      '.moon-overlay-inner {',
      '  width:100%; max-width:380px; padding:36px 24px; display:flex;',
      '  flex-direction:column; gap:18px; align-items:center; text-align:center;',
      '}',
      '.moon-overlay-emoji { font-size:48px; animation:moonPulse 2.5s ease-in-out infinite; }',
      '@keyframes moonPulse { 0%,100%{transform:scale(1);opacity:1;} 50%{transform:scale(1.08);opacity:0.85;} }',
      '.moon-overlay-title {',
      '  font-size:20px; font-weight:700; color:#EAEAEA;',
      '  font-family:'DM Sans',"Noto Sans JP",sans-serif; line-height:1.4;',
      '}',
      '.moon-overlay-sub {',
      '  font-size:12px; color:#ACACAC; line-height:1.5;',
      '  font-family:'DM Sans',"Noto Sans JP",sans-serif;',
      '}',
      '.moon-overlay-events {',
      '  width:100%; padding:10px 14px; border-radius:12px;',
      '  background:rgba(8,12,20,0.95); backdrop-filter:blur(12px);',
      '  -webkit-backdrop-filter:blur(12px); border:1px solid rgba(249,217,118,0.1);',
      '  text-align:left;',
      '}',
      '.moon-overlay-events-title {',
      '  font-size:10px; font-weight:700; color:rgba(249,217,118,0.7);',
      '  letter-spacing:1.2px; text-transform:uppercase; margin-bottom:6px;',
      '  font-family:'DM Sans',sans-serif;',
      '}',
      '.moon-overlay-event-item {',
      '  font-size:11px; color:#ACACAC; line-height:1.6;',
      '  font-family:"Noto Sans JP",'DM Sans',sans-serif;',
      '}',
      '.moon-overlay-prompt {',
      '  font-size:14px; color:#EAEAEA; font-weight:600;',
      '  font-family:"Noto Sans JP",'DM Sans',sans-serif; line-height:1.5;',
      '}',
      '.moon-choice-list { width:100%; display:flex; flex-direction:column; gap:10px; }',
      '.moon-choice-btn {',
      '  width:100%; padding:14px 16px; border-radius:14px;',
      '  background:rgba(8,12,20,0.95); backdrop-filter:blur(8px);',
      '  -webkit-backdrop-filter:blur(8px); border:1px solid rgba(255,255,255,0.06);',
      '  color:#EAEAEA; font-size:13px; font-family:"Noto Sans JP",'DM Sans',sans-serif;',
      '  text-align:left; cursor:pointer; transition:all 0.25s ease;',
      '  line-height:1.5; outline:none;',
      '}',
      '.moon-choice-btn:hover { border-color:rgba(249,217,118,0.25); }',
      '.moon-choice-btn.selected {',
      '  background:rgba(249,217,118,0.12); border-color:rgba(249,217,118,0.5);',
      '  box-shadow:0 0 16px rgba(249,217,118,0.08);',
      '}',
      '.moon-choice-btn .choice-jp { display:block; font-size:14px; font-weight:600; }',
      '.moon-choice-btn .choice-en { display:block; font-size:11px; color:#ACACAC; margin-top:2px; }',
      '.moon-gold-btn {',
      '  padding:14px 36px; border:none; border-radius:28px; cursor:pointer;',
      '  font-size:14px; font-weight:700; color:#1A1A2E;',
      '  font-family:"Noto Sans JP",'DM Sans',sans-serif;',
      '  background:linear-gradient(135deg,#F9D976 0%,#F4C542 100%);',
      '  box-shadow:0 4px 20px rgba(249,217,118,0.3);',
      '  transition:all 0.3s ease; opacity:0; pointer-events:none;',
      '  transform:translateY(8px);',
      '}',
      '.moon-gold-btn.active { opacity:1; pointer-events:auto; transform:translateY(0); }',
      '.moon-gold-btn:hover { box-shadow:0 6px 28px rgba(249,217,118,0.45); transform:translateY(-1px); }',
      '.moon-ghost-btn {',
      '  padding:10px 24px; border:1px solid rgba(255,255,255,0.1); border-radius:20px;',
      '  background:transparent; color:#ACACAC; font-size:12px; cursor:pointer;',
      '  font-family:"Noto Sans JP",'DM Sans',sans-serif; transition:all 0.2s ease;',
      '}',
      '.moon-ghost-btn:hover { border-color:rgba(255,255,255,0.25); color:#EAEAEA; }',
      '.moon-gold-btn {',
      '  padding:14px 32px; border:none; border-radius:24px; cursor:pointer;',
      '  background:linear-gradient(135deg,#F9D976,#F6BD60); color:#0C1D3A;',
      '  font-size:14px; font-weight:700; font-family:"Noto Sans JP",'DM Sans',sans-serif;',
      '  letter-spacing:1px; transition:all 0.2s ease;',
      '}',
      '.moon-gold-btn:hover { transform:scale(1.03); box-shadow:0 0 20px rgba(249,217,118,0.3); }',
      '.moon-two-btn-row { display:flex; gap:12px; width:100%; }',
      '.moon-big-btn {',
      '  flex:1; padding:20px 12px; border-radius:16px; cursor:pointer;',
      '  background:rgba(8,12,20,0.95); backdrop-filter:blur(8px);',
      '  -webkit-backdrop-filter:blur(8px); border:1px solid rgba(255,255,255,0.08);',
      '  color:#EAEAEA; font-size:13px; text-align:center;',
      '  font-family:"Noto Sans JP",'DM Sans',sans-serif;',
      '  transition:all 0.25s ease; outline:none; line-height:1.5;',
      '}',
      '.moon-big-btn:hover { border-color:rgba(249,217,118,0.3); }',
      '.moon-big-btn .big-emoji { font-size:28px; display:block; margin-bottom:8px; }',
      '.moon-big-btn .big-jp { display:block; font-size:14px; font-weight:600; }',
      '.moon-big-btn .big-en { display:block; font-size:11px; color:#ACACAC; margin-top:3px; }',
      '.moon-intention-recall {',
      '  width:100%; padding:12px 16px; border-radius:12px;',
      '  background:rgba(249,217,118,0.06); border:1px solid rgba(249,217,118,0.15);',
      '  text-align:left;',
      '}',
      '.moon-intention-recall-label {',
      '  font-size:10px; font-weight:700; color:rgba(249,217,118,0.6);',
      '  letter-spacing:1px; text-transform:uppercase; margin-bottom:4px;',
      '  font-family:'DM Sans',sans-serif;',
      '}',
      '.moon-intention-recall-text {',
      '  font-size:13px; color:#EAEAEA; line-height:1.5;',
      '  font-family:"Noto Sans JP",'DM Sans',sans-serif;',
      '}',
      '.moon-midpoint-badge {',
      '  display:inline-block; padding:3px 10px; border-radius:10px;',
      '  background:rgba(249,217,118,0.1); border:1px solid rgba(249,217,118,0.2);',
      '  font-size:11px; color:#F9D976; margin-top:6px;',
      '  font-family:"Noto Sans JP",'DM Sans',sans-serif;',
      '}',
    ].join('\n');
    document.head.appendChild(style);
  }

  /* ───── NEW MOON OVERLAY ───── */
  window.showNewMoonOverlay = function() {
    injectOverlayStyles();
    // Remove old overlay if present
    var old = document.getElementById('overlayNewMoon');
    if (old) old.remove();

    var now = new Date();
    var data = getMonthData(now.getMonth() + 1);
    var container = document.querySelector('.phone') || document.body;

    // Build events list HTML
    var eventsHTML = '';
    if (data.events && data.events.length > 0) {
      eventsHTML = '<div class="moon-overlay-events">' +
        '<div class="moon-overlay-events-title">✦ Celestial Events</div>' +
        data.events.map(function(e) {
          return '<div class="moon-overlay-event-item">• ' + e.descJP + '</div>';
        }).join('') +
        '</div>';
    }

    // Build 3 choice buttons
    var choicesHTML = '<div class="moon-choice-list" id="nmChoiceList">';
    for (var i = 0; i < 3; i++) {
      var jp = data.themes.jp[i] || '';
      var en = data.themes.en[i] || '';
      choicesHTML += '<button class="moon-choice-btn" data-idx="' + i + '" ' +
        'data-en="' + en.replace(/"/g, '&quot;') + '" ' +
        'data-jp="' + jp.replace(/"/g, '&quot;') + '">' +
        '<span class="choice-jp">' + jp + '</span>' +
        '<span class="choice-en">' + en + '</span>' +
        '</button>';
    }
    choicesHTML += '</div>';

    var html = '<div class="moon-overlay-screen" id="overlayNewMoon">' +
      '<div class="moon-overlay-inner">' +
        '<div class="moon-overlay-emoji">🌑</div>' +
        '<div class="moon-overlay-title">New Moon in ' + data.newMoonSign +
          '<br><span style="font-size:15px;color:#ACACAC;">' + data.newMoonSignJP + 'の新月</span></div>' +
        eventsHTML +
        '<div class="moon-overlay-prompt">この周期で何を手放しますか？<br>' +
          '<span style="font-size:12px;color:#ACACAC;">What will you release this cycle?</span></div>' +
        choicesHTML +
        '<button class="moon-gold-btn" id="nmSetBtn">Set Intention ✦</button>' +
        '<button class="moon-ghost-btn" id="nmSkipBtn">Not today</button>' +
      '</div>' +
    '</div>';

    container.insertAdjacentHTML('beforeend', html);

    // Bind events
    var selectedIdx = -1;
    var choiceList = document.getElementById('nmChoiceList');
    var setBtn = document.getElementById('nmSetBtn');

    choiceList.addEventListener('click', function(ev) {
      var btn = ev.target.closest('.moon-choice-btn');
      if (!btn) return;
      // Deselect all
      var all = choiceList.querySelectorAll('.moon-choice-btn');
      for (var j = 0; j < all.length; j++) all[j].classList.remove('selected');
      btn.classList.add('selected');
      selectedIdx = parseInt(btn.getAttribute('data-idx'), 10);
      setBtn.classList.add('active');
    });

    setBtn.addEventListener('click', function() {
      if (selectedIdx < 0) return;
      var chosen = choiceList.querySelector('.moon-choice-btn[data-idx="' + selectedIdx + '"]');
      var intention = {
        cycleId: getCurrentCycleId(),
        chosenText: chosen.getAttribute('data-en'),
        chosenTextJP: chosen.getAttribute('data-jp'),
        chosenAt: new Date().toISOString(),
        newMoonSign: data.newMoonSign,
        midpoint: null,
        crystallization: null
      };
      saveIntention(intention);
      closeOverlay('overlayNewMoon');
    });

    document.getElementById('nmSkipBtn').addEventListener('click', function() {
      closeOverlay('overlayNewMoon');
    });

    // Show with slight delay for transition
    var nmEl = document.getElementById('overlayNewMoon');
    setTimeout(function() { if (nmEl) nmEl.classList.add('visible'); }, 50);
  };

  /* ───── FULL MOON OVERLAY ───── */
  window.showFullMoonOverlay = function() {
    injectOverlayStyles();
    var old = document.getElementById('overlayFullMoon');
    if (old) old.remove();

    var now = new Date();
    var data = getMonthData(now.getMonth() + 1);
    var intention = loadIntention();
    var container = document.querySelector('.phone') || document.body;

    // Recall intention panel
    var recallHTML = '';
    if (intention) {
      recallHTML = '<div class="moon-intention-recall">' +
        '<div class="moon-intention-recall-label">✦ Your Intention</div>' +
        '<div class="moon-intention-recall-text">' + intention.chosenTextJP +
          '<br><span style="font-size:11px;color:#ACACAC;">' + intention.chosenText + '</span></div>' +
        '</div>';
    }

    // 3 midpoint choices
    var midChoices = [
      { emoji: '🌊', jp: 'まだ取り組んでいる', en: 'Still working on it', val: 1 },
      { emoji: '✨', jp: '進展あり', en: 'Making progress', val: 2 },
      { emoji: '🌟', jp: '軽くなってきた', en: 'Feeling lighter', val: 3 }
    ];

    var choicesHTML = '<div class="moon-choice-list" id="fmChoiceList">';
    midChoices.forEach(function(c) {
      choicesHTML += '<button class="moon-choice-btn" data-val="' + c.val + '">' +
        '<span class="choice-jp">' + c.emoji + ' ' + c.jp + '</span>' +
        '<span class="choice-en">' + c.en + '</span>' +
        '</button>';
    });
    choicesHTML += '</div>';

    var html = '<div class="moon-overlay-screen" id="overlayFullMoon">' +
      '<div class="moon-overlay-inner">' +
        '<div class="moon-overlay-emoji">🌕</div>' +
        '<div class="moon-overlay-title">' + data.fullMoonName +
          '<br><span style="font-size:15px;color:#ACACAC;">' + data.fullMoonNameJP + '</span></div>' +
        recallHTML +
        '<div class="moon-overlay-prompt">今どう感じていますか？<br>' +
          '<span style="font-size:12px;color:#ACACAC;">How does it feel now?</span></div>' +
        choicesHTML +
        '<button class="moon-ghost-btn" id="fmSkipBtn">Not today</button>' +
      '</div>' +
    '</div>';

    container.insertAdjacentHTML('beforeend', html);

    // Bind events
    var choiceList = document.getElementById('fmChoiceList');
    choiceList.addEventListener('click', function(ev) {
      var btn = ev.target.closest('.moon-choice-btn');
      if (!btn) return;
      var val = parseInt(btn.getAttribute('data-val'), 10);
      // Save midpoint
      if (intention) {
        intention.midpoint = val;
        saveIntention(intention);
      }
      // Brief highlight then close
      var all = choiceList.querySelectorAll('.moon-choice-btn');
      for (var j = 0; j < all.length; j++) all[j].classList.remove('selected');
      btn.classList.add('selected');
      setTimeout(function() { closeOverlay('overlayFullMoon'); }, 600);
    });

    document.getElementById('fmSkipBtn').addEventListener('click', function() {
      closeOverlay('overlayFullMoon');
    });

    var fmEl = document.getElementById('overlayFullMoon');
    setTimeout(function() { if (fmEl) fmEl.classList.add('visible'); }, 50);
  };

  /* ───── CRYSTALLIZATION OVERLAY (振り返り演出 → 星座形成) ───── */

  // Month-specific warm messages based on celestial events (~100 chars JP)
  var CRYSTAL_MESSAGES = {
    1: '新しい年の始まり。海王星が牡羊座へ動き出すように、あなたの内側にも新しい流れが生まれています。この周期の経験はすべて、次の一歩への糧になります。',
    2: '土星と海王星が牡羊座で出会うこの特別な月。夢と現実の境界が溶け、あなたが手放そうとしたものは静かに形を変えています。焦らなくて大丈夫。',
    3: '乙女座の月食が照らしたのは、完璧でなくていいという真実。手放す旅に正解はありません。あなたのペースで、あなたの星が輝いています。',
    4: '牡羊座の新月から始まったこの周期。天王星が双子座へ移る風の中で、古いものが自然と手を離れていきます。変化を信じてください。',
    5: '冥王星が逆行を始めるこの時期、深い変容は目に見えない場所で進んでいます。花の月のように、あなたの内側でも何かが静かに咲き始めています。',
    6: '木星が獅子座へ、キロンが牡牛座へ。星たちが大きく動くこの月、あなたもまた新しい場所へ向かっています。この周期で得た光を忘れないで。',
    7: '土星の逆行が始まり、ノースノードが水瓶座へ。大きな転換期の中で、あなたが向き合ったことには深い意味があります。星座に刻みましょう。',
    8: '獅子座の日食と魚座の月食。ふたつの食が照らすのは、あなたの創造性と直感です。この周期の軌跡は、あなただけの星座として永遠に残ります。',
    9: '大きな天体イベントのない静かな月。でも、静けさの中にこそ深い癒しがあります。収穫の月のように、あなたの内側にも実りが訪れています。',
    10: '金星と水星がともに逆行するこの月。人間関係やコミュニケーションの見直しの中で、あなたは大切なことに気づいたはず。その気づきが星になります。',
    11: '水星と金星が順行に戻るこの月。滞っていたものが再び流れ始めます。あなたが取り組んだことは、たとえ途中でも、確かな一歩です。',
    12: '土星と海王星が順行に戻り、年の終わりへ。この一年で最も深い学びを、あなたの星座に結晶化しましょう。新しい年が、新しい光を連れてきます。'
  };

  window.showCrystallizationOverlay = function() {
    injectOverlayStyles();
    var old = document.getElementById('overlayCrystal');
    if (old) old.remove();

    var intention = loadIntention();
    var container = document.querySelector('.phone') || document.body;
    var month = new Date().getMonth() + 1;
    var data = getMonthData(month);
    var warmMsg = CRYSTAL_MESSAGES[month] || CRYSTAL_MESSAGES[1];

    // Recall intention + midpoint
    var recallHTML = '';
    if (intention) {
      var midLabels = { 1: '🌊 まだ取り組んでいた', 2: '✨ 進展あり', 3: '🌟 軽くなってきた' };
      var midBadge = intention.midpoint && intention.midpoint.rating
        ? '<div class="moon-midpoint-badge">' + (midLabels[intention.midpoint.rating] || '') + '</div>'
        : '';
      recallHTML = '<div class="moon-intention-recall">' +
        '<div class="moon-intention-recall-label">✦ Your Intention</div>' +
        '<div class="moon-intention-recall-text">' + (intention.chosenTextJP || '') +
          '<br><span style="font-size:11px;color:#ACACAC;">' + (intention.chosenText || '') + '</span>' +
          midBadge +
        '</div>' +
      '</div>';
    }

    var html = '<div class="moon-overlay-screen" id="overlayCrystal">' +
      '<div class="moon-overlay-inner">' +
        '<div class="moon-overlay-emoji">💎</div>' +
        '<div class="moon-overlay-title">Crystallization' +
          '<br><span style="font-size:15px;color:#ACACAC;">結晶化</span></div>' +
        recallHTML +
        '<div style="font-size:13px;color:#EAEAEA;line-height:1.8;max-width:310px;text-align:center;' +
          'font-weight:300;font-family:'DM Sans',sans-serif;padding:8px 0;">' +
          warmMsg +
        '</div>' +
        '<div style="font-size:11px;color:rgba(172,172,172,0.45);text-align:center;margin-top:2px;">' +
          'この周期の軌跡が星座になります' +
        '</div>' +
        '<button class="moon-gold-btn active" id="crystalProceedBtn">✦ 星座を結晶化する</button>' +
        '<button class="moon-ghost-btn" id="crystalSkipBtn">Not now</button>' +
      '</div>' +
    '</div>';

    container.insertAdjacentHTML('beforeend', html);

    // Bind proceed button → constellation formation
    document.getElementById('crystalProceedBtn').addEventListener('click', function() {
      if (intention) {
        intention.crystallization = { at: new Date().toISOString() };
        saveIntention(intention);
      }
      closeOverlay('overlayCrystal');
      if (typeof triggerConstellationFormation === 'function') {
        triggerConstellationFormation();
      }
    });

    document.getElementById('crystalSkipBtn').addEventListener('click', function() {
      closeOverlay('overlayCrystal');
    });

    var overlayEl = document.getElementById('overlayCrystal');
    setTimeout(function() {
      if (overlayEl) overlayEl.classList.add('visible');
    }, 50);
  };

  /* ───── Close overlay helper ───── */
  function closeOverlay(id) {
    var el = document.getElementById(id);
    if (!el) return;
    el.classList.remove('visible');
    setTimeout(function() { if (el.parentNode) el.parentNode.removeChild(el); }, 600);
  }

  // Legacy compat
  window.closeNewMoonOverlay = function() { closeOverlay('overlayNewMoon'); };
  window.closeFullMoonOverlay = function() { closeOverlay('overlayFullMoon'); };

  /* ───── Moon Phase Calculation (Metonic cycle — unchanged) ───── */
  function getMoonPhase() {
    var now = new Date();
    // Known new moon: Jan 6 2000 18:14 UTC
    var knownNew = new Date(2000, 0, 6, 18, 14, 0);
    var daysSince = (now - knownNew) / 86400000;
    var synodicMonth = 29.53059;
    var phase = ((daysSince % synodicMonth) + synodicMonth) % synodicMonth;
    return Math.floor(phase);
  }

  /* ───── Moon Phase Info (unchanged) ───── */
  window.getMoonPhaseInfo = function() {
    var phase = getMoonPhase();
    if (phase <= 1) return { phase: 'new', emoji: '🌑', label: 'New Moon' };
    if (phase <= 6) return { phase: 'waxing-crescent', emoji: '🌒', label: 'Waxing Crescent' };
    if (phase <= 8) return { phase: 'first-quarter', emoji: '🌓', label: 'First Quarter' };
    if (phase <= 13) return { phase: 'waxing-gibbous', emoji: '🌔', label: 'Waxing Gibbous' };
    if (phase <= 16) return { phase: 'full', emoji: '🌕', label: 'Full Moon' };
    if (phase <= 21) return { phase: 'waning-gibbous', emoji: '🌖', label: 'Waning Gibbous' };
    if (phase <= 23) return { phase: 'last-quarter', emoji: '🌗', label: 'Last Quarter' };
    return { phase: 'waning-crescent', emoji: '🌘', label: 'Waning Crescent' };
  };

  /* ───── Check Moon Events — 3-beat trigger logic ───── */
  window.checkMoonEvents = function() {
    var phase = getMoonPhase();

    // New moon (phase 0-1)
    if (phase <= 1) {
      // First check: previous cycle has uncrystallized intention?
      var prevIntention = loadAnyIntention();
      if (prevIntention && prevIntention.cycleId !== getCurrentCycleId() && !prevIntention.crystallization) {
        // Previous cycle wasn't crystallized — show crystallization first
        setTimeout(function() {
          showCrystallizationOverlay();
        }, 2000);
        return;
      }
      // Normal new moon flow
      var intention = loadIntention();
      if (!intention && !wasShownToday('new_moon')) {
        setTimeout(function() {
          showNewMoonOverlay();
          markShown('new_moon');
        }, 2000);
      }
    }
    // Full moon (phase 14-15)
    else if (phase >= 14 && phase <= 15) {
      var intention2 = loadIntention();
      if (intention2 && !intention2.midpoint && !wasShownToday('full_moon')) {
        setTimeout(function() {
          showFullMoonOverlay();
          markShown('full_moon');
        }, 2000);
      }
    }
    // Crystallization (phase 28-29, day before new moon)
    else if (phase >= 28) {
      var intention3 = loadIntention();
      if (intention3 && !intention3.crystallization && !wasShownToday('crystallization')) {
        setTimeout(function() {
          showCrystallizationOverlay();
          markShown('crystallization');
        }, 2000);
      }
    }
  };

  /* ───── Expose helpers for external use ───── */
  window.loadLunarIntention = loadIntention;
  window.saveLunarIntention = saveIntention;
  window.getCurrentLunarCycleId = getCurrentCycleId;
  window.getLunarMonthData = getMonthData;

})();
