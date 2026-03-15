document.addEventListener('DOMContentLoaded', () => {
    const API_URL = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
        ? 'http://localhost:8787'
        : 'https://ai-omoshiro-api.kojifo369.workers.dev';

    let pet = null;
    let vibe = null;
    let style = null;
    let isGenerating = false;

    const petGrid = document.getElementById('petGrid');
    const vibeGrid = document.getElementById('vibeGrid');
    const styleButtons = document.getElementById('styleButtons');
    const generateBtn = document.getElementById('generateBtn');
    const resultSection = document.getElementById('resultSection');
    const resultPet = document.getElementById('resultPet');
    const resultVibe = document.getElementById('resultVibe');
    const resultStyle = document.getElementById('resultStyle');
    const mainName = document.getElementById('mainName');
    const nameMeaning = document.getElementById('nameMeaning');
    const altList = document.getElementById('altList');
    const callFill = document.getElementById('callFill');
    const callValue = document.getElementById('callValue');
    const memoFill = document.getElementById('memoFill');
    const memoValue = document.getElementById('memoValue');
    const cuteFill = document.getElementById('cuteFill');
    const cuteValue = document.getElementById('cuteValue');
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

    setupSelection(petGrid, (v) => { pet = v; });
    setupSelection(vibeGrid, (v) => { vibe = v; });
    setupSelection(styleButtons, (v) => { style = v; });

    function updateGenerateBtn() {
        generateBtn.disabled = !(pet && vibe && style);
    }

    generateBtn.addEventListener('click', generate);
    retryBtn.addEventListener('click', generate);

    async function generate() {
        if (!pet || !vibe || !style) return;
        if (isGenerating) return;

        isGenerating = true;
        generateBtn.disabled = true;
        generateBtn.textContent = '\u8003\u3048\u4E2D\u2026 \u{1F43E}';

        try {
            await generateWithAI();
        } catch (err) {
            console.warn('AI generation failed, using static fallback:', err);
            generateFromStatic();
        } finally {
            isGenerating = false;
            generateBtn.textContent = '\u540D\u524D\u3092\u8003\u3048\u308B \u{1F43E}';
            generateBtn.disabled = !(pet && vibe && style);
        }
    }

    async function generateWithAI() {
        const res = await fetch(API_URL + '/api/generate', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                app: 'pet-namer',
                params: { pet, vibe, style }
            })
        });

        if (!res.ok) throw new Error('API response ' + res.status);

        const json = await res.json();
        if (!json.success || !json.data) throw new Error('Invalid response');
        const data = json.data;
        if (!data.name) throw new Error('No name in response');

        resultPet.textContent = pet;
        resultVibe.textContent = vibe;
        resultStyle.textContent = STYLE_LABELS[style];

        mainName.textContent = data.name;
        nameMeaning.textContent = data.meaning || '';

        altList.innerHTML = '';
        if (data.alts && Array.isArray(data.alts)) {
            data.alts.forEach(alt => {
                const chip = document.createElement('span');
                chip.className = 'alt-chip';
                chip.textContent = alt;
                chip.addEventListener('click', () => {
                    mainName.textContent = alt;
                    nameMeaning.textContent = '\u300C' + alt + '\u300D\u3082\u3044\u3044\u540D\u524D\u3067\u3059\u306D\uFF01';
                });
                altList.appendChild(chip);
            });
        }

        const callScore = clamp(data.call, 30, 99);
        const memoScore = clamp(data.memo, 30, 99);
        const cuteScore = clamp(data.cute, 30, 99);

        setTimeout(() => {
            callFill.style.width = callScore + '%';
            callValue.textContent = callScore + '%';
            memoFill.style.width = memoScore + '%';
            memoValue.textContent = memoScore + '%';
            cuteFill.style.width = cuteScore + '%';
            cuteValue.textContent = cuteScore + '%';
        }, 100);

        tipText.textContent = data.tip || ('\u{1F4A1} ' + getStaticTip());

        showResult();
    }

    function generateFromStatic() {
        const styleData = PET_NAMES[style];
        if (!styleData) return;

        const petData = styleData[pet];
        if (!petData) return;

        const vibeData = petData[vibe];
        if (!vibeData || vibeData.length === 0) return;

        const entry = vibeData[Math.floor(Math.random() * vibeData.length)];

        resultPet.textContent = pet;
        resultVibe.textContent = vibe;
        resultStyle.textContent = STYLE_LABELS[style];

        mainName.textContent = entry.name;
        nameMeaning.textContent = entry.meaning;

        altList.innerHTML = '';
        entry.alts.forEach(alt => {
            const chip = document.createElement('span');
            chip.className = 'alt-chip';
            chip.textContent = alt;
            chip.addEventListener('click', () => {
                mainName.textContent = alt;
                nameMeaning.textContent = '\u300C' + alt + '\u300D\u3082\u3044\u3044\u540D\u524D\u3067\u3059\u306D\uFF01';
            });
            altList.appendChild(chip);
        });

        const nameLen = entry.name.length;
        const callScore = nameLen <= 3 ? 90 + rand(10) : nameLen <= 5 ? 70 + rand(15) : 50 + rand(20);
        const memoScore = nameLen <= 4 ? 85 + rand(15) : 60 + rand(20);
        const cuteScore = style === 'food' ? 80 + rand(20) : style === 'unique' ? 60 + rand(30) : 70 + rand(25);

        setTimeout(() => {
            callFill.style.width = callScore + '%';
            callValue.textContent = callScore + '%';
            memoFill.style.width = memoScore + '%';
            memoValue.textContent = memoScore + '%';
            cuteFill.style.width = cuteScore + '%';
            cuteValue.textContent = cuteScore + '%';
        }, 100);

        tipText.textContent = '\u{1F4A1} ' + getStaticTip();

        showResult();
    }

    function getStaticTip() {
        const tips = TIPS[pet] || TIPS['\u72AC'];
        return tips[Math.floor(Math.random() * tips.length)];
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

    // Copy
    copyBtn.addEventListener('click', () => {
        const name = mainName.textContent;
        const text = '\u3010AI\u30DA\u30C3\u30C8\u540D\u3065\u3051\u3011' + pet + '\u306E\u540D\u524D\u3092\u300C' + name + '\u300D\u306B\u6C7A\u3081\u307E\u3057\u305F\uFF01\uFF08' + vibe + ' \u00D7 ' + STYLE_LABELS[style] + '\uFF09\n\nhttps://solodev-lab.github.io/ai-omoshiro-tools/apps/pet-namer/';
        navigator.clipboard.writeText(text).then(() => {
            showToast('\u30B3\u30D4\u30FC\u3057\u307E\u3057\u305F\uFF01');
        });
    });

    // Share on X (Twitter)
    shareXBtn.addEventListener('click', () => {
        const appUrl = 'https://solodev-lab.github.io/ai-omoshiro-tools/apps/pet-namer/';
        const text = '\u3010AI\u30DA\u30C3\u30C8\u540D\u3065\u3051\u3011' + pet + '\u306E\u540D\u524D\u3092\u300C' + mainName.textContent + '\u300D\u306B\u6C7A\u3081\u307E\u3057\u305F\uFF01\uFF08' + vibe + ' \u00D7 ' + STYLE_LABELS[style] + '\uFF09';
        const hashtags = '\u30DA\u30C3\u30C8\u540D\u524D,AI,\u500B\u4EBA\u958B\u767A';
        const url = 'https://twitter.com/intent/tweet?text=' + encodeURIComponent(text) + '&url=' + encodeURIComponent(appUrl) + '&hashtags=' + encodeURIComponent(hashtags);
        window.open(url, '_blank');
    });

    // Share on LINE
    shareLINEBtn.addEventListener('click', () => {
        const appUrl = 'https://solodev-lab.github.io/ai-omoshiro-tools/apps/pet-namer/';
        const text = '\u3010AI\u30DA\u30C3\u30C8\u540D\u3065\u3051\u3011' + pet + '\u306E\u540D\u524D\u3092\u300C' + mainName.textContent + '\u300D\u306B\u6C7A\u3081\u307E\u3057\u305F\uFF01\uFF08' + vibe + ' \u00D7 ' + STYLE_LABELS[style] + '\uFF09\n' + appUrl;
        const url = 'https://social-plugins.line.me/lineit/share?url=' + encodeURIComponent(appUrl) + '&text=' + encodeURIComponent(text);
        window.open(url, '_blank');
    });

    function showToast(message) {
        toast.textContent = message;
        toast.classList.add('show');
        setTimeout(() => toast.classList.remove('show'), 2000);
    }
});
