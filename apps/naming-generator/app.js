document.addEventListener('DOMContentLoaded', () => {
    let category = null;
    let taste = null;
    let sound = null;

    const catGrid = document.getElementById('catGrid');
    const tasteGrid = document.getElementById('tasteGrid');
    const soundButtons = document.getElementById('soundButtons');
    const generateBtn = document.getElementById('generateBtn');
    const resultSection = document.getElementById('resultSection');
    const resultCat = document.getElementById('resultCat');
    const resultTaste = document.getElementById('resultTaste');
    const resultSound = document.getElementById('resultSound');
    const mainName = document.getElementById('mainName');
    const nameMeaning = document.getElementById('nameMeaning');
    const altList = document.getElementById('altList');
    const catchyFill = document.getElementById('catchyFill');
    const catchyValue = document.getElementById('catchyValue');
    const impactFill = document.getElementById('impactFill');
    const impactValue = document.getElementById('impactValue');
    const memoFill = document.getElementById('memoFill');
    const memoValue = document.getElementById('memoValue');
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

    setupSelection(catGrid, (v) => { category = v; });
    setupSelection(tasteGrid, (v) => { taste = v; });
    setupSelection(soundButtons, (v) => { sound = v; });

    function updateGenerateBtn() {
        generateBtn.disabled = !(category && taste && sound);
    }

    // 響きフィルター：選択された「響き」に名前が合致するか判定
    function matchesSound(name, soundType) {
        if (!soundType) return true;
        const hasLatin = /[a-zA-Z]/.test(name);
        const visibleLen = name.replace(/[\s　・（）\(\)「」『』【】]/g, '').length;
        switch (soundType) {
            case 'japanese': return !hasLatin;
            case 'english': return hasLatin;
            case 'catchy': return visibleLen <= 6;
            case 'impact': return visibleLen >= 7;
            default: return true;
        }
    }

    generateBtn.addEventListener('click', generate);
    retryBtn.addEventListener('click', generate);

    function generate() {
        if (!category || !taste || !sound) return;

        const catData = NAMES_DATA[category];
        if (!catData) return;

        const tasteData = catData[taste];
        if (!tasteData || tasteData.length === 0) return;

        // 響きフィルターでエントリーを絞る
        let filtered = tasteData.filter(e => matchesSound(e.name, sound));
        if (filtered.length === 0) filtered = tasteData;

        const entry = filtered[Math.floor(Math.random() * filtered.length)];

        resultCat.textContent = category;
        resultTaste.textContent = taste;
        resultSound.textContent = SOUND_LABELS[sound];

        mainName.textContent = entry.name;
        nameMeaning.textContent = entry.meaning;

        // altsも響きフィルターで絞る
        let filteredAlts = entry.alts.filter(a => matchesSound(a, sound));

        // 候補が3つ未満なら、同テイストの他エントリーから補充
        if (filteredAlts.length < 3) {
            const pool = [];
            tasteData.forEach(e => {
                if (e.name !== entry.name) {
                    if (matchesSound(e.name, sound)) pool.push(e.name);
                    e.alts.forEach(a => {
                        if (matchesSound(a, sound) && a !== entry.name) pool.push(a);
                    });
                }
            });
            pool.sort(() => Math.random() - 0.5);
            while (filteredAlts.length < 3 && pool.length > 0) {
                const candidate = pool.shift();
                if (!filteredAlts.includes(candidate)) {
                    filteredAlts.push(candidate);
                }
            }
        }

        if (filteredAlts.length === 0) filteredAlts = entry.alts;

        altList.innerHTML = '';
        filteredAlts.forEach(alt => {
            const chip = document.createElement('span');
            chip.className = 'alt-chip';
            chip.textContent = alt;
            chip.addEventListener('click', () => {
                navigator.clipboard.writeText(alt).then(() => {
                    showToast('「' + alt + '」をコピーしました！');
                });
            });
            altList.appendChild(chip);
        });

        const nameLen = entry.name.length;
        const catchyScore = nameLen <= 4 ? 85 + rand(15) : nameLen <= 7 ? 65 + rand(20) : 45 + rand(25);
        const impactScore = nameLen >= 6 ? 80 + rand(20) : nameLen >= 4 ? 60 + rand(25) : 50 + rand(20);
        const memoScore = nameLen <= 5 ? 80 + rand(20) : nameLen <= 8 ? 55 + rand(25) : 40 + rand(25);

        setTimeout(() => {
            catchyFill.style.width = catchyScore + '%';
            catchyValue.textContent = catchyScore + '%';
            impactFill.style.width = impactScore + '%';
            impactValue.textContent = impactScore + '%';
            memoFill.style.width = memoScore + '%';
            memoValue.textContent = memoScore + '%';
        }, 100);

        tipText.textContent = '💡 ' + TIPS[Math.floor(Math.random() * TIPS.length)];

        resultSection.style.display = 'block';
        resultSection.style.animation = 'none';
        resultSection.offsetHeight;
        resultSection.style.animation = 'fadeInUp 0.5s ease';
        resultSection.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }

    function rand(max) {
        return Math.floor(Math.random() * max);
    }

    copyBtn.addEventListener('click', () => {
        const text = mainName.textContent;
        navigator.clipboard.writeText(text).then(() => {
            showToast('「' + text + '」をコピーしました！');
        });
    });

    shareXBtn.addEventListener('click', () => {
        const name = mainName.textContent;
        const text = '【AIネーミングジェネレーター】\n' + category + '×' + taste + 'で生成✨\n\n「' + name + '」\n\nあなたも最高の名前を見つけよう👇\nhttps://solodev-lab.github.io/ai-omoshiro-tools/apps/naming-generator/\n\n#AIネーミング #名前 #個人開発';
        window.open('https://twitter.com/intent/tweet?text=' + encodeURIComponent(text), '_blank');
    });

    shareLINEBtn.addEventListener('click', () => {
        const name = mainName.textContent;
        const text = '【AIネーミングジェネレーター】' + category + '×' + taste + 'で生成✨「' + name + '」';
        window.open('https://social-plugins.line.me/lineit/share?url=' + encodeURIComponent('https://solodev-lab.github.io/ai-omoshiro-tools/apps/naming-generator/') + '&text=' + encodeURIComponent(text), '_blank');
    });

    function showToast(message) {
        toast.textContent = message;
        toast.classList.add('show');
        setTimeout(() => toast.classList.remove('show'), 2000);
    }
});
