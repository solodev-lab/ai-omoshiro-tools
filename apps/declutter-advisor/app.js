document.addEventListener('DOMContentLoaded', () => {
    let category = null;
    let time = null;
    let reason = null;

    // Worker API URL
    const API_URL = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
        ? 'http://localhost:8787'
        : 'https://ai-omoshiro-api.kojifo369.workers.dev';

    const categoryGrid = document.getElementById('categoryGrid');
    const timeButtons = document.getElementById('timeButtons');
    const reasonGrid = document.getElementById('reasonGrid');
    const generateBtn = document.getElementById('generateBtn');
    const resultSection = document.getElementById('resultSection');
    const verdictArea = document.getElementById('verdictArea');
    const verdictEmoji = document.getElementById('verdictEmoji');
    const verdictText = document.getElementById('verdictText');
    const verdictSubtitle = document.getElementById('verdictSubtitle');
    const resultCategory = document.getElementById('resultCategory');
    const resultTime = document.getElementById('resultTime');
    const resultReason = document.getElementById('resultReason');
    const adviceText = document.getElementById('adviceText');
    const throwFill = document.getElementById('throwFill');
    const throwValue = document.getElementById('throwValue');
    const regretFill = document.getElementById('regretFill');
    const regretValue = document.getElementById('regretValue');
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

    setupSelection(categoryGrid, (v) => { category = v; });
    setupSelection(timeButtons, (v) => { time = v; });
    setupSelection(reasonGrid, (v) => { reason = v; });

    function updateGenerateBtn() {
        generateBtn.disabled = !(category && time && reason);
    }

    generateBtn.addEventListener('click', generate);
    retryBtn.addEventListener('click', generate);

    let isGenerating = false;

    async function generate() {
        if (!category || !time || !reason) return;
        if (isGenerating) return;
        isGenerating = true;

        generateBtn.disabled = true;
        generateBtn.textContent = '考え中… 🧹';
        retryBtn.disabled = true;

        try {
            await generateWithAI();
        } catch (err) {
            console.warn('AI生成失敗、フォールバック:', err.message);
            generateFromStatic();
        } finally {
            isGenerating = false;
            generateBtn.disabled = false;
            generateBtn.textContent = '断捨離診断する ✨';
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
                    app: 'declutter-advisor',
                    params: { category, time, reason }
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
            const verdict = d.verdict || 'maybe';
            const emojiMap = { throw: '🗑️', keep: '💎', maybe: '🤔' };

            verdictArea.className = 'verdict-area ' + verdict;
            verdictEmoji.textContent = emojiMap[verdict] || '🤔';
            verdictEmoji.style.animation = 'none';
            verdictEmoji.offsetHeight;
            verdictEmoji.style.animation = 'popIn 0.5s ease';
            verdictText.textContent = d.verdict_title || VERDICTS[verdict].titles[0];
            verdictSubtitle.textContent = d.verdict_subtitle || VERDICTS[verdict].subtitles[0];

            resultCategory.textContent = category;
            resultTime.textContent = TIME_LABELS[time];
            resultReason.textContent = reason;

            adviceText.textContent = d.advice || '断捨離は自分との対話です。本当に必要かどうか、心に聞いてみましょう。';

            const throwVal = Math.max(0, Math.min(100, d.throw_score || 50));
            const regretVal = Math.max(0, Math.min(100, d.regret_score || 50));

            setTimeout(() => {
                throwFill.style.width = throwVal + '%';
                throwValue.textContent = throwVal + '%';
                regretFill.style.width = regretVal + '%';
                regretValue.textContent = regretVal + '%';
            }, 100);

            tipText.textContent = '💡 ' + (d.tip || TIPS[Math.floor(Math.random() * TIPS.length)]);

            showResult();
        } catch (err) {
            clearTimeout(timeout);
            throw err;
        }
    }

    // ── 静的データからのフォールバック生成 ──
    function generateFromStatic() {
        let score = 50;
        score += TIME_SCORES[time] || 0;
        score += REASON_SCORES[reason] || 0;
        score += CATEGORY_SCORES[category] || 0;
        score += Math.floor(Math.random() * 20) - 10;
        score = Math.max(0, Math.min(100, score));

        let verdict;
        if (score >= 65) verdict = 'throw';
        else if (score <= 35) verdict = 'keep';
        else verdict = 'maybe';

        const vData = VERDICTS[verdict];

        verdictArea.className = 'verdict-area ' + verdict;
        verdictEmoji.textContent = vData.emoji;
        verdictEmoji.style.animation = 'none';
        verdictEmoji.offsetHeight;
        verdictEmoji.style.animation = 'popIn 0.5s ease';
        verdictText.textContent = vData.titles[Math.floor(Math.random() * vData.titles.length)];
        verdictSubtitle.textContent = vData.subtitles[Math.floor(Math.random() * vData.subtitles.length)];

        resultCategory.textContent = category;
        resultTime.textContent = TIME_LABELS[time];
        resultReason.textContent = reason;

        const catAdvice = ADVICE[category];
        if (catAdvice && catAdvice[verdict]) {
            const options = catAdvice[verdict];
            adviceText.textContent = options[Math.floor(Math.random() * options.length)];
        } else {
            adviceText.textContent = '断捨離は自分との対話です。本当に必要かどうか、心に聞いてみましょう。';
        }

        const throwVal = score;
        const regretVal = Math.max(5, 100 - score + Math.floor(Math.random() * 15) - 7);

        setTimeout(() => {
            throwFill.style.width = throwVal + '%';
            throwValue.textContent = throwVal + '%';
            regretFill.style.width = regretVal + '%';
            regretValue.textContent = regretVal + '%';
        }, 100);

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
        const v = verdictText.textContent;
        const text = `【AI断捨離アドバイザー】${category}を断捨離判定した結果 → ${v}（捨て度: ${throwValue.textContent}）\nhttps://solodev-lab.github.io/ai-omoshiro-tools/apps/declutter-advisor/`;
        navigator.clipboard.writeText(text).then(() => {
            showToast('コピーしました！');
        });
    });

    // Share X
    shareXBtn.addEventListener('click', () => {
        const v = verdictText.textContent;
        const text = `【AI断捨離アドバイザー】${category}を断捨離判定した結果 → ${v}（捨て度: ${throwValue.textContent}）`;
        const appUrl = 'https://solodev-lab.github.io/ai-omoshiro-tools/apps/declutter-advisor/';
        const hashtags = '断捨離,AI,個人開発';
        const xUrl = `https://twitter.com/intent/tweet?text=${encodeURIComponent(text)}&url=${encodeURIComponent(appUrl)}&hashtags=${encodeURIComponent(hashtags)}`;
        window.open(xUrl, '_blank');
    });

    // Share LINE
    shareLINEBtn.addEventListener('click', () => {
        const v = verdictText.textContent;
        const text = `【AI断捨離アドバイザー】${category}を断捨離判定した結果 → ${v}（捨て度: ${throwValue.textContent}）\nhttps://solodev-lab.github.io/ai-omoshiro-tools/apps/declutter-advisor/`;
        const lineUrl = `https://social-plugins.line.me/lineit/share?url=${encodeURIComponent('https://solodev-lab.github.io/ai-omoshiro-tools/apps/declutter-advisor/')}&text=${encodeURIComponent(text)}`;
        window.open(lineUrl, '_blank');
    });

    function showToast(message) {
        toast.textContent = message;
        toast.classList.add('show');
        setTimeout(() => toast.classList.remove('show'), 2000);
    }
});
