document.addEventListener('DOMContentLoaded', () => {
    let pet = null;
    let vibe = null;
    let style = null;

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

    setupSelection(petGrid, (v) => { pet = v; });
    setupSelection(vibeGrid, (v) => { vibe = v; });
    setupSelection(styleButtons, (v) => { style = v; });

    function updateGenerateBtn() {
        generateBtn.disabled = !(pet && vibe && style);
    }

    generateBtn.addEventListener('click', generate);
    retryBtn.addEventListener('click', generate);

    function generate() {
        if (!pet || !vibe || !style) return;

        const styleData = PET_NAMES[style];
        if (!styleData) return;

        const petData = styleData[pet];
        if (!petData) return;

        const vibeData = petData[vibe];
        if (!vibeData || vibeData.length === 0) return;

        const entry = vibeData[Math.floor(Math.random() * vibeData.length)];

        // Display tags
        resultPet.textContent = pet;
        resultVibe.textContent = vibe;
        resultStyle.textContent = STYLE_LABELS[style];

        // Main name
        mainName.textContent = entry.name;
        nameMeaning.textContent = entry.meaning;

        // Alt names
        altList.innerHTML = '';
        entry.alts.forEach(alt => {
            const chip = document.createElement('span');
            chip.className = 'alt-chip';
            chip.textContent = alt;
            chip.addEventListener('click', () => {
                mainName.textContent = alt;
                nameMeaning.textContent = '「' + alt + '」もいい名前ですね！';
            });
            altList.appendChild(chip);
        });

        // Stats
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

        // Tip
        const tips = TIPS[pet] || TIPS['犬'];
        tipText.textContent = '💡 ' + tips[Math.floor(Math.random() * tips.length)];

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
        const text = mainName.textContent;
        navigator.clipboard.writeText(text).then(() => {
            showToast('「' + text + '」をコピーしました！');
        });
    });

    // Share
    shareBtn.addEventListener('click', () => {
        const text = '【AIペット名づけ】' + pet + 'の名前を「' + mainName.textContent + '」に決めました！（' + vibe + ' × ' + STYLE_LABELS[style] + '）';
        if (navigator.share) {
            navigator.share({ title: 'AIペット名づけ', text: text });
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
