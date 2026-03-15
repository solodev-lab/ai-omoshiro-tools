document.addEventListener('DOMContentLoaded', () => {
    let category = null;
    let time = null;
    let reason = null;

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

    setupSelection(categoryGrid, (v) => { category = v; });
    setupSelection(timeButtons, (v) => { time = v; });
    setupSelection(reasonGrid, (v) => { reason = v; });

    function updateGenerateBtn() {
        generateBtn.disabled = !(category && time && reason);
    }

    generateBtn.addEventListener('click', generate);
    retryBtn.addEventListener('click', generate);

    function generate() {
        if (!category || !time || !reason) return;

        // Calculate score
        let score = 50;
        score += TIME_SCORES[time] || 0;
        score += REASON_SCORES[reason] || 0;
        score += CATEGORY_SCORES[category] || 0;
        score += Math.floor(Math.random() * 20) - 10;
        score = Math.max(0, Math.min(100, score));

        // Determine verdict
        let verdict;
        if (score >= 65) verdict = 'throw';
        else if (score <= 35) verdict = 'keep';
        else verdict = 'maybe';

        const vData = VERDICTS[verdict];

        // Display verdict
        verdictArea.className = 'verdict-area ' + verdict;
        verdictEmoji.textContent = vData.emoji;
        verdictEmoji.style.animation = 'none';
        verdictEmoji.offsetHeight;
        verdictEmoji.style.animation = 'popIn 0.5s ease';
        verdictText.textContent = vData.titles[Math.floor(Math.random() * vData.titles.length)];
        verdictSubtitle.textContent = vData.subtitles[Math.floor(Math.random() * vData.subtitles.length)];

        // Tags
        resultCategory.textContent = category;
        resultTime.textContent = TIME_LABELS[time];
        resultReason.textContent = reason;

        // Advice
        const catAdvice = ADVICE[category];
        if (catAdvice && catAdvice[verdict]) {
            const options = catAdvice[verdict];
            adviceText.textContent = options[Math.floor(Math.random() * options.length)];
        } else {
            adviceText.textContent = '断捨離は自分との対話です。本当に必要かどうか、心に聞いてみましょう。';
        }

        // Meters
        const throwVal = score;
        const regretVal = Math.max(5, 100 - score + Math.floor(Math.random() * 15) - 7);

        setTimeout(() => {
            throwFill.style.width = throwVal + '%';
            throwValue.textContent = throwVal + '%';
            regretFill.style.width = regretVal + '%';
            regretValue.textContent = regretVal + '%';
        }, 100);

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
        navigator.clipboard.writeText(adviceText.textContent).then(() => {
            showToast('コピーしました！');
        });
    });

    // Share
    shareBtn.addEventListener('click', () => {
        const v = verdictText.textContent;
        const text = `【AI断捨離アドバイザー】${category}を断捨離判定した結果 → ${v}（捨て度: ${throwValue.textContent}）`;
        if (navigator.share) {
            navigator.share({ title: 'AI断捨離アドバイザー', text: text });
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
