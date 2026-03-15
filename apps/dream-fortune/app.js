document.addEventListener('DOMContentLoaded', () => {
    let symbol = null;
    let mood = null;

    // Worker API URL
    const API_URL = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
        ? 'http://localhost:8787'
        : 'https://ai-omoshiro-api.kojifo369.workers.dev';

    const symbolGrid = document.getElementById('symbolGrid');
    const moodButtons = document.getElementById('moodButtons');
    const generateBtn = document.getElementById('generateBtn');
    const resultSection = document.getElementById('resultSection');
    const fortuneStars = document.getElementById('fortuneStars');
    const fortuneRank = document.getElementById('fortuneRank');
    const resultSymbol = document.getElementById('resultSymbol');
    const resultMood = document.getElementById('resultMood');
    const interpretationText = document.getElementById('interpretationText');
    const psychologyText = document.getElementById('psychologyText');
    const luckyColor = document.getElementById('luckyColor');
    const luckyNumber = document.getElementById('luckyNumber');
    const luckyAction = document.getElementById('luckyAction');
    const tipText = document.getElementById('tipText');
    const copyBtn = document.getElementById('copyBtn');
    const shareXBtn = document.getElementById('shareXBtn');
    const shareLINEBtn = document.getElementById('shareLINEBtn');
    const retryBtn = document.getElementById('retryBtn');
    const toast = document.getElementById('toast');

    function setupSelection(container, callback) {
        container.addEventListener('click', (e) => {
            const btn = e.target.closest('button');
            if (!btn) return;
            container.querySelectorAll('button').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            callback(btn.dataset.value);
            updateGenerateBtn();
        });
    }

    setupSelection(symbolGrid, (v) => { symbol = v; });
    setupSelection(moodButtons, (v) => { mood = v; });

    function updateGenerateBtn() {
        generateBtn.disabled = !(symbol && mood);
    }

    generateBtn.addEventListener('click', generate);
    retryBtn.addEventListener('click', generate);

    let isGenerating = false;

    async function generate() {
        if (!symbol || !mood) return;
        if (isGenerating) return;
        isGenerating = true;

        generateBtn.disabled = true;
        generateBtn.textContent = '考え中… 🔮';
        retryBtn.disabled = true;

        try {
            await generateWithAI();
        } catch (err) {
            console.warn('AI生成失敗、フォールバック:', err.message);
            generateFromStatic();
        } finally {
            isGenerating = false;
            generateBtn.disabled = false;
            generateBtn.textContent = '夢を占う ✨';
            retryBtn.disabled = false;
        }
    }

    // ── AI生成 ──
    async function generateWithAI() {
        const controller = new AbortController();
        const timeout = setTimeout(() => controller.abort(), 15000);

        try {
            const res = await fetch(API_URL + '/api/generate', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    app: 'dream-fortune',
                    params: { symbol, mood }
                }),
                signal: controller.signal
            });

            clearTimeout(timeout);

            if (!res.ok) {
                const err = await res.json().catch(() => ({}));
                throw new Error(err.error || 'API error ' + res.status);
            }

            const json = await res.json();
            if (!json.success || !json.data) throw new Error('Invalid response');

            const d = json.data;
            const ranks = { 1: '凶', 2: '末吉', 3: '小吉', 4: '吉', 5: '大吉' };
            const stars = Math.max(1, Math.min(5, d.fortune_score || 3));

            fortuneStars.textContent = '⭐'.repeat(stars) + '☆'.repeat(5 - stars);
            fortuneRank.textContent = ranks[stars];

            resultSymbol.textContent = symbol;
            resultMood.textContent = mood;

            interpretationText.textContent = d.interpretation || 'この夢は、あなたの深層心理が変化を求めているサインです。新しいことに挑戦してみましょう。';
            psychologyText.textContent = d.psychology || 'あなたの無意識が何かを伝えようとしています。心の声に耳を傾けてみましょう。';

            luckyColor.textContent = d.lucky_color || LUCKY_COLORS[Math.floor(Math.random() * LUCKY_COLORS.length)];
            luckyNumber.textContent = d.lucky_number || (Math.floor(Math.random() * 99) + 1);
            luckyAction.textContent = d.lucky_action || LUCKY_ACTIONS[Math.floor(Math.random() * LUCKY_ACTIONS.length)];

            tipText.textContent = '💡 ' + (d.tip || TIPS[Math.floor(Math.random() * TIPS.length)]);

            showResult();
        } catch (err) {
            clearTimeout(timeout);
            throw err;
        }
    }

    // ── 静的データからのフォールバック生成 ──
    function generateFromStatic() {
        const moodBonus = { '楽しい': 2, '不思議': 1, '懐かしい': 1, '怖い': -1, '悲しい': -1, '焦り': 0 };
        const base = Math.floor(Math.random() * 5) + 1;
        const stars = Math.max(1, Math.min(5, base + (moodBonus[mood] || 0)));

        const ranks = { 1: '凶', 2: '末吉', 3: '小吉', 4: '吉', 5: '大吉' };
        fortuneStars.textContent = '⭐'.repeat(stars) + '☆'.repeat(5 - stars);
        fortuneRank.textContent = ranks[stars];

        resultSymbol.textContent = symbol;
        resultMood.textContent = mood;

        const interp = INTERPRETATIONS[symbol];
        if (interp && interp[mood]) {
            const options = interp[mood];
            interpretationText.textContent = options[Math.floor(Math.random() * options.length)];
        } else {
            interpretationText.textContent = 'この夢は、あなたの深層心理が変化を求めているサインです。新しいことに挑戦してみましょう。';
        }

        psychologyText.textContent = PSYCHOLOGY[symbol] || 'あなたの無意識が何かを伝えようとしています。心の声に耳を傾けてみましょう。';

        luckyColor.textContent = LUCKY_COLORS[Math.floor(Math.random() * LUCKY_COLORS.length)];
        luckyNumber.textContent = Math.floor(Math.random() * 99) + 1;
        luckyAction.textContent = LUCKY_ACTIONS[Math.floor(Math.random() * LUCKY_ACTIONS.length)];

        tipText.textContent = '💡 ' + TIPS[Math.floor(Math.random() * TIPS.length)];

        showResult();
    }

    // ── 結果表示（共通） ──
    function showResult() {
        resultSection.style.display = 'block';
        resultSection.style.animation = 'none';
        resultSection.offsetHeight;
        resultSection.style.animation = 'fadeInUp 0.5s ease';
        resultSection.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }

    // Copy
    copyBtn.addEventListener('click', () => {
        const text = `【夢占い結果】\n夢: ${symbol}（${mood}）\n運勢: ${fortuneRank.textContent}\n\n${interpretationText.textContent}\n\nラッキーカラー: ${luckyColor.textContent}\nラッキーナンバー: ${luckyNumber.textContent}\n\nhttps://solodev-lab.github.io/ai-omoshiro-tools/apps/dream-fortune/`;
        navigator.clipboard.writeText(text).then(() => {
            showToast('コピーしました！');
        });
    });

    // Share to X (Twitter)
    shareXBtn.addEventListener('click', () => {
        const appUrl = 'https://solodev-lab.github.io/ai-omoshiro-tools/apps/dream-fortune/';
        const text = `【AI夢占い】${symbol}の夢を見ました（${mood}）→ 運勢: ${fortuneRank.textContent} ${fortuneStars.textContent}`;
        const hashtags = '夢占い,AI,個人開発';
        const url = `https://twitter.com/intent/tweet?text=${encodeURIComponent(text)}&url=${encodeURIComponent(appUrl)}&hashtags=${encodeURIComponent(hashtags)}`;
        window.open(url, '_blank');
    });

    // Share to LINE
    shareLINEBtn.addEventListener('click', () => {
        const appUrl = 'https://solodev-lab.github.io/ai-omoshiro-tools/apps/dream-fortune/';
        const text = `【AI夢占い】${symbol}の夢を見ました（${mood}）→ 運勢: ${fortuneRank.textContent} ${fortuneStars.textContent}\n${appUrl}`;
        const url = `https://social-plugins.line.me/lineit/share?url=${encodeURIComponent(appUrl)}&text=${encodeURIComponent(text)}`;
        window.open(url, '_blank');
    });

    function showToast(message) {
        toast.textContent = message;
        toast.classList.add('show');
        setTimeout(() => toast.classList.remove('show'), 2000);
    }
});
