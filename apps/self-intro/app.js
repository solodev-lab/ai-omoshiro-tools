const API_URL = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
    ? 'http://localhost:8787'
    : 'https://ai-omoshiro-api.kojifo369.workers.dev';

document.addEventListener('DOMContentLoaded', () => {
    let scene = null;
    let chara = null;
    let impression = null;
    let isGenerating = false;

    const sceneGrid = document.getElementById('sceneGrid');
    const charaGrid = document.getElementById('charaGrid');
    const impressionButtons = document.getElementById('impressionButtons');
    const generateBtn = document.getElementById('generateBtn');
    const resultSection = document.getElementById('resultSection');
    const resultScene = document.getElementById('resultScene');
    const resultChara = document.getElementById('resultChara');
    const resultImpression = document.getElementById('resultImpression');
    const introText = document.getElementById('introText');
    const introSubtitle = document.getElementById('introSubtitle');
    const altList = document.getElementById('altList');
    const impactFill = document.getElementById('impactFill');
    const impactValue = document.getElementById('impactValue');
    const likableFill = document.getElementById('likableFill');
    const likableValue = document.getElementById('likableValue');
    const memorableFill = document.getElementById('memorableFill');
    const memorableValue = document.getElementById('memorableValue');
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

    setupSelection(sceneGrid, (v) => { scene = v; });
    setupSelection(charaGrid, (v) => { chara = v; });
    setupSelection(impressionButtons, (v) => { impression = v; });

    function updateGenerateBtn() {
        generateBtn.disabled = !(scene && chara && impression);
    }

    generateBtn.addEventListener('click', generate);
    retryBtn.addEventListener('click', generate);

    async function generate() {
        if (!scene || !chara || !impression) return;
        if (isGenerating) return;
        isGenerating = true;

        generateBtn.disabled = true;
        generateBtn.textContent = '考え中… 🎤';

        // Display tags
        resultScene.textContent = scene;
        resultChara.textContent = chara;
        resultImpression.textContent = IMPRESSION_LABELS[impression];

        try {
            await generateWithAI();
        } catch (e) {
            console.log('AI generation failed, using static fallback:', e.message);
            generateFromStatic();
        } finally {
            isGenerating = false;
            generateBtn.disabled = false;
            generateBtn.textContent = '自己紹介を生成する ✨';
        }

        // Show result
        resultSection.style.display = 'block';
        resultSection.style.animation = 'none';
        resultSection.offsetHeight;
        resultSection.style.animation = 'fadeInUp 0.5s ease';
        resultSection.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }

    async function generateWithAI() {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 15000);

        const response = await fetch(API_URL + '/api/generate', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                app: 'self-intro',
                params: { scene, chara, impression }
            }),
            signal: controller.signal
        });

        clearTimeout(timeoutId);

        if (!response.ok) throw new Error('API error: ' + response.status);

        const json = await response.json();
        if (!json.success || !json.data) throw new Error('Invalid response');
        const data = json.data;

        // Main intro text
        introText.textContent = data.text;
        introSubtitle.textContent = data.subtitle;

        // Alt intros
        altList.innerHTML = '';
        if (data.alts && data.alts.length > 0) {
            data.alts.forEach(alt => {
                const chip = document.createElement('span');
                chip.className = 'alt-chip';
                chip.textContent = alt.length > 30 ? alt.substring(0, 30) + '…' : alt;
                chip.title = alt;
                chip.addEventListener('click', () => {
                    introText.textContent = alt;
                    introSubtitle.textContent = '別パターン';
                });
                altList.appendChild(chip);
            });
        }

        // Stats (clamp 20-99)
        const impactScore = clamp(data.impact, 20, 99);
        const likableScore = clamp(data.likable, 20, 99);
        const memorableScore = clamp(data.memorable, 20, 99);

        setTimeout(() => {
            impactFill.style.width = impactScore + '%';
            impactValue.textContent = impactScore + '%';
            likableFill.style.width = likableScore + '%';
            likableValue.textContent = likableScore + '%';
            memorableFill.style.width = memorableScore + '%';
            memorableValue.textContent = memorableScore + '%';
        }, 100);

        // Tip
        tipText.textContent = '💡 ' + data.tip;
    }

    function generateFromStatic() {
        const sceneData = INTROS[scene];
        if (!sceneData) return;

        const charaData = sceneData[chara];
        if (!charaData || charaData.length === 0) return;

        const entry = charaData[Math.floor(Math.random() * charaData.length)];

        // Main intro text
        introText.textContent = entry.text;
        introSubtitle.textContent = entry.subtitle;

        // Alt intros
        altList.innerHTML = '';
        entry.alts.forEach(alt => {
            const chip = document.createElement('span');
            chip.className = 'alt-chip';
            chip.textContent = alt.length > 30 ? alt.substring(0, 30) + '…' : alt;
            chip.title = alt;
            chip.addEventListener('click', () => {
                introText.textContent = alt;
                introSubtitle.textContent = '別パターン';
            });
            altList.appendChild(chip);
        });

        // Stats
        const impactScore = chara === '中二病' || chara === 'おもしろ' ? 70 + rand(30) : 40 + rand(40);
        const likableScore = chara === '天然' || chara === '陽キャ' ? 70 + rand(25) : chara === '陰キャ' ? 30 + rand(30) : 50 + rand(35);
        const memorableScore = chara === '中二病' || chara === 'ギャップ萌え' || chara === 'ミステリアス' ? 70 + rand(30) : 40 + rand(40);

        setTimeout(() => {
            impactFill.style.width = impactScore + '%';
            impactValue.textContent = impactScore + '%';
            likableFill.style.width = likableScore + '%';
            likableValue.textContent = likableScore + '%';
            memorableFill.style.width = memorableScore + '%';
            memorableValue.textContent = memorableScore + '%';
        }, 100);

        // Tip
        tipText.textContent = '💡 ' + TIPS[Math.floor(Math.random() * TIPS.length)];
    }

    function clamp(value, min, max) {
        return Math.max(min, Math.min(max, value));
    }

    function rand(max) {
        return Math.floor(Math.random() * max);
    }

    // Copy
    copyBtn.addEventListener('click', () => {
        const text = introText.textContent;
        navigator.clipboard.writeText(text).then(() => {
            showToast('コピーしました！');
        });
    });

    // Share on X (Twitter)
    shareXBtn.addEventListener('click', () => {
        const appUrl = 'https://solodev-lab.github.io/ai-omoshiro-tools/apps/self-intro/';
        const text = '【AI自己紹介メーカー】' + scene + 'で' + chara + 'キャラの自己紹介🎤\n\n' + introText.textContent;
        const url = 'https://twitter.com/intent/tweet?text=' + encodeURIComponent(text) + '&url=' + encodeURIComponent(appUrl) + '&hashtags=' + encodeURIComponent('自己紹介,AI,個人開発');
        window.open(url, '_blank');
    });

    // Share on LINE
    shareLINEBtn.addEventListener('click', () => {
        const appUrl = 'https://solodev-lab.github.io/ai-omoshiro-tools/apps/self-intro/';
        const text = '【AI自己紹介メーカー】' + scene + 'で' + chara + 'キャラの自己紹介🎤\n\n' + introText.textContent + '\n' + appUrl;
        const url = 'https://social-plugins.line.me/lineit/share?url=' + encodeURIComponent(appUrl) + '&text=' + encodeURIComponent(text);
        window.open(url, '_blank');
    });

    function showToast(message) {
        toast.textContent = message;
        toast.classList.add('show');
        setTimeout(() => toast.classList.remove('show'), 2000);
    }
});
