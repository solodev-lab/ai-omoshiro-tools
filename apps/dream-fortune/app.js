document.addEventListener('DOMContentLoaded', () => {
    let symbol = null;
    let mood = null;

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
    const shareBtn = document.getElementById('shareBtn');
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

    function generate() {
        if (!symbol || !mood) return;

        // Fortune rank (random but weighted by mood)
        const moodBonus = { '楽しい': 2, '不思議': 1, '懐かしい': 1, '怖い': -1, '悲しい': -1, '焦り': 0 };
        const base = Math.floor(Math.random() * 5) + 1;
        const stars = Math.max(1, Math.min(5, base + (moodBonus[mood] || 0)));

        const ranks = { 1: '凶', 2: '末吉', 3: '小吉', 4: '吉', 5: '大吉' };
        fortuneStars.textContent = '⭐'.repeat(stars) + '☆'.repeat(5 - stars);
        fortuneRank.textContent = ranks[stars];

        // Tags
        resultSymbol.textContent = symbol;
        resultMood.textContent = mood;

        // Interpretation
        const interp = INTERPRETATIONS[symbol];
        if (interp && interp[mood]) {
            const options = interp[mood];
            interpretationText.textContent = options[Math.floor(Math.random() * options.length)];
        } else {
            interpretationText.textContent = 'この夢は、あなたの深層心理が変化を求めているサインです。新しいことに挑戦してみましょう。';
        }

        // Psychology
        psychologyText.textContent = PSYCHOLOGY[symbol] || 'あなたの無意識が何かを伝えようとしています。心の声に耳を傾けてみましょう。';

        // Lucky items
        luckyColor.textContent = LUCKY_COLORS[Math.floor(Math.random() * LUCKY_COLORS.length)];
        luckyNumber.textContent = Math.floor(Math.random() * 99) + 1;
        luckyAction.textContent = LUCKY_ACTIONS[Math.floor(Math.random() * LUCKY_ACTIONS.length)];

        // Tip
        tipText.textContent = '💡 ' + TIPS[Math.floor(Math.random() * TIPS.length)];

        // Show
        resultSection.style.display = 'block';
        resultSection.style.animation = 'none';
        resultSection.offsetHeight;
        resultSection.style.animation = 'fadeInUp 0.5s ease';
        resultSection.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }

    // Copy
    copyBtn.addEventListener('click', () => {
        const text = `【夢占い結果】\n夢: ${symbol}（${mood}）\n運勢: ${fortuneRank.textContent}\n\n${interpretationText.textContent}\n\nラッキーカラー: ${luckyColor.textContent}\nラッキーナンバー: ${luckyNumber.textContent}`;
        navigator.clipboard.writeText(text).then(() => {
            showToast('コピーしました！');
        });
    });

    // Share
    shareBtn.addEventListener('click', () => {
        const text = `【AI夢占い】${symbol}の夢を見ました（${mood}）→ 運勢: ${fortuneRank.textContent} ${fortuneStars.textContent}`;
        if (navigator.share) {
            navigator.share({ title: 'AI夢占い', text: text });
        } else {
            const url = 'https://twitter.com/intent/tweet?text=' + encodeURIComponent(text);
            window.open(url, '_blank');
        }
    });

    function showToast(message) {
        toast.textContent = message;
        toast.classList.add('show');
        setTimeout(() => toast.classList.remove('show'), 2000);
    }
});
