document.addEventListener('DOMContentLoaded', () => {
    const API_URL = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
        ? 'http://localhost:8787'
        : 'https://ai-omoshiro-api.kojifo369.workers.dev';

    let relationship = null;
    let mood = null;
    let situation = null;
    let isGenerating = false;

    const relGrid = document.getElementById('relGrid');
    const moodGrid = document.getElementById('moodGrid');
    const sitButtons = document.getElementById('sitButtons');
    const generateBtn = document.getElementById('generateBtn');
    const resultSection = document.getElementById('resultSection');
    const resultRel = document.getElementById('resultRel');
    const resultMood = document.getElementById('resultMood');
    const resultSit = document.getElementById('resultSit');
    const confessionText = document.getElementById('confessionText');
    const confessionSubtitle = document.getElementById('confessionSubtitle');
    const altList = document.getElementById('altList');
    const successFill = document.getElementById('successFill');
    const successValue = document.getElementById('successValue');
    const seriousFill = document.getElementById('seriousFill');
    const seriousValue = document.getElementById('seriousValue');
    const powerFill = document.getElementById('powerFill');
    const powerValue = document.getElementById('powerValue');
    const tipText = document.getElementById('tipText');
    const copyBtn = document.getElementById('copyBtn');
    const shareXBtn = document.getElementById('shareXBtn');
    const shareLINEBtn = document.getElementById('shareLINEBtn');
    const retryBtn = document.getElementById('retryBtn');
    const toast = document.getElementById('toast');

    let currentText = '';

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

    setupSelection(relGrid, (v) => { relationship = v; });
    setupSelection(moodGrid, (v) => { mood = v; });
    setupSelection(sitButtons, (v) => { situation = v; });

    function updateGenerateBtn() {
        generateBtn.disabled = !(relationship && mood && situation);
    }

    generateBtn.addEventListener('click', generate);
    retryBtn.addEventListener('click', generate);

    async function generate() {
        if (!relationship || !mood || !situation) return;
        if (isGenerating) return;

        isGenerating = true;
        generateBtn.disabled = true;
        generateBtn.textContent = '考え中… \u{1F495}';

        try {
            await generateWithAI();
        } catch (err) {
            console.warn('AI generation failed, using static fallback:', err);
            generateFromStatic();
        } finally {
            isGenerating = false;
            generateBtn.textContent = '告白文を生成する \u{1F48C}';
            generateBtn.disabled = !(relationship && mood && situation);
        }
    }

    async function generateWithAI() {
        const res = await fetch(API_URL + '/api/generate', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                app: 'love-confession',
                params: { relationship, mood, situation }
            })
        });

        if (!res.ok) throw new Error('API response ' + res.status);

        const json = await res.json();
        if (!json.success || !json.data) throw new Error('Invalid response');
        const data = json.data;
        if (!data.text) throw new Error('No text in response');

        currentText = data.text;

        resultRel.textContent = relationship;
        resultMood.textContent = mood;
        resultSit.textContent = SITUATION_LABELS[situation];

        confessionText.textContent = currentText;
        confessionSubtitle.textContent = data.subtitle ? ('— ' + data.subtitle) : '';

        altList.innerHTML = '';
        if (data.alts && Array.isArray(data.alts)) {
            data.alts.forEach(alt => {
                const chip = document.createElement('span');
                chip.className = 'alt-chip';
                chip.textContent = alt.length > 20 ? alt.substring(0, 20) + '\u2026' : alt;
                chip.addEventListener('click', () => {
                    currentText = alt;
                    confessionText.textContent = currentText;
                    confessionSubtitle.textContent = '— \u5225\u30D1\u30BF\u30FC\u30F3';
                });
                altList.appendChild(chip);
            });
        }

        const successScore = clamp(data.success, 5, 99);
        const seriousScore = clamp(data.serious, 5, 99);
        const powerScore = clamp(data.power, 5, 99);

        setTimeout(() => {
            successFill.style.width = successScore + '%';
            successValue.textContent = successScore + '%';
            seriousFill.style.width = seriousScore + '%';
            seriousValue.textContent = seriousScore + '%';
            powerFill.style.width = powerScore + '%';
            powerValue.textContent = powerScore + '%';
        }, 100);

        tipText.textContent = data.tip || TIPS[Math.floor(Math.random() * TIPS.length)];

        showResult();
    }

    function generateFromStatic() {
        const relData = CONFESSIONS[relationship];
        if (!relData) return;

        const moodData = relData[mood];
        if (!moodData || moodData.length === 0) return;

        const entry = moodData[Math.floor(Math.random() * moodData.length)];
        const prefix = SITUATION_PREFIX[situation] || '';

        currentText = prefix + entry.text;

        resultRel.textContent = relationship;
        resultMood.textContent = mood;
        resultSit.textContent = SITUATION_LABELS[situation];

        confessionText.textContent = currentText;
        confessionSubtitle.textContent = '— ' + entry.subtitle;

        altList.innerHTML = '';
        entry.alts.forEach(alt => {
            const chip = document.createElement('span');
            chip.className = 'alt-chip';
            chip.textContent = alt.length > 20 ? alt.substring(0, 20) + '\u2026' : alt;
            chip.addEventListener('click', () => {
                currentText = prefix + alt;
                confessionText.textContent = currentText;
                confessionSubtitle.textContent = '— \u5225\u30D1\u30BF\u30FC\u30F3';
            });
            altList.appendChild(chip);
        });

        const successScore = 10 + rand(90);
        const seriousScore = 60 + rand(41);
        const powerScore = 40 + rand(61);

        setTimeout(() => {
            successFill.style.width = successScore + '%';
            successValue.textContent = successScore + '%';
            seriousFill.style.width = seriousScore + '%';
            seriousValue.textContent = seriousScore + '%';
            powerFill.style.width = powerScore + '%';
            powerValue.textContent = powerScore + '%';
        }, 100);

        tipText.textContent = TIPS[Math.floor(Math.random() * TIPS.length)];

        showResult();
    }

    function showResult() {
        resultSection.style.display = 'block';
        resultSection.style.animation = 'none';
        resultSection.offsetHeight;
        resultSection.style.animation = 'fadeInUp 0.5s ease';
        resultSection.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }

    function clamp(val, min, max) {
        const n = parseInt(val, 10);
        if (isNaN(n)) return min + Math.floor(Math.random() * (max - min));
        return Math.max(min, Math.min(max, n));
    }

    function rand(max) {
        return Math.floor(Math.random() * max);
    }

    copyBtn.addEventListener('click', () => {
        navigator.clipboard.writeText(currentText).then(() => {
            showToast('\u544A\u767D\u6587\u3092\u30B3\u30D4\u30FC\u3057\u307E\u3057\u305F\uFF01');
        });
    });

    shareXBtn.addEventListener('click', () => {
        const appUrl = 'https://solodev-lab.github.io/ai-omoshiro-tools/apps/love-confession/';
        const text = '\u3010AI\u544A\u767D\u6587\u30B8\u30A7\u30CD\u30EC\u30FC\u30BF\u30FC\u3011' + relationship + '\u3078\u306E' + mood + '\u306A\u544A\u767D\u{1F48C}\n\n' + currentText + '\n\n' + appUrl;
        const hashtags = 'AI\u544A\u767D\u6587,\u500B\u4EBA\u958B\u767A';
        const url = 'https://twitter.com/intent/tweet?text=' + encodeURIComponent(text) + '&hashtags=' + encodeURIComponent(hashtags);
        window.open(url, '_blank');
    });

    shareLINEBtn.addEventListener('click', () => {
        const appUrl = 'https://solodev-lab.github.io/ai-omoshiro-tools/apps/love-confession/';
        const text = '\u3010AI\u544A\u767D\u6587\u30B8\u30A7\u30CD\u30EC\u30FC\u30BF\u30FC\u3011' + relationship + '\u3078\u306E' + mood + '\u306A\u544A\u767D\u{1F48C}\n\n' + currentText + '\n\n' + appUrl;
        const url = 'https://social-plugins.line.me/lineit/share?url=' + encodeURIComponent(appUrl) + '&text=' + encodeURIComponent(text);
        window.open(url, '_blank');
    });

    function showToast(message) {
        toast.textContent = message;
        toast.classList.add('show');
        setTimeout(() => toast.classList.remove('show'), 2000);
    }
});
