document.addEventListener('DOMContentLoaded', () => {
    let scene = null;
    let chara = null;
    let impression = null;

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

    function generate() {
        if (!scene || !chara || !impression) return;

        const sceneData = INTROS[scene];
        if (!sceneData) return;

        const charaData = sceneData[chara];
        if (!charaData || charaData.length === 0) return;

        const entry = charaData[Math.floor(Math.random() * charaData.length)];

        // Display tags
        resultScene.textContent = scene;
        resultChara.textContent = chara;
        resultImpression.textContent = IMPRESSION_LABELS[impression];

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
        const isChara = chara;
        const impactScore = isChara === '中二病' || isChara === 'おもしろ' ? 70 + rand(30) : 40 + rand(40);
        const likableScore = isChara === '天然' || isChara === '陽キャ' ? 70 + rand(25) : isChara === '陰キャ' ? 30 + rand(30) : 50 + rand(35);
        const memorableScore = isChara === '中二病' || isChara === 'ギャップ萌え' || isChara === 'ミステリアス' ? 70 + rand(30) : 40 + rand(40);

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

        // Show result
        resultSection.style.display = 'block';
        resultSection.style.animation = 'none';
        resultSection.offsetHeight;
        resultSection.style.animation = 'fadeInUp 0.5s ease';
        resultSection.scrollIntoView({ behavior: 'smooth', block: 'center' });
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
