document.addEventListener('DOMContentLoaded', () => {
    let reason = null;
    let tenure = null;
    let stance = null;
    let currentTab = 'tatemae';

    const reasonGrid = document.getElementById('reasonGrid');
    const tenureButtons = document.getElementById('tenureButtons');
    const stanceButtons = document.getElementById('stanceButtons');
    const generateBtn = document.getElementById('generateBtn');
    const resultSection = document.getElementById('resultSection');
    const resultReason = document.getElementById('resultReason');
    const resultTenure = document.getElementById('resultTenure');
    const resultStance = document.getElementById('resultStance');
    const tatemaeText = document.getElementById('tatemaeText');
    const honneText = document.getElementById('honneText');
    const tatemaeArea = document.getElementById('tatemaeArea');
    const honneArea = document.getElementById('honneArea');
    const tabTatemae = document.getElementById('tabTatemae');
    const tabHonne = document.getElementById('tabHonne');
    const peacefulFill = document.getElementById('peacefulFill');
    const peacefulValue = document.getElementById('peacefulValue');
    const honneFill = document.getElementById('honneFill');
    const honneValue = document.getElementById('honneValue');
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

    setupSelection(reasonGrid, (v) => { reason = v; });
    setupSelection(tenureButtons, (v) => { tenure = v; });
    setupSelection(stanceButtons, (v) => { stance = v; });

    function updateGenerateBtn() {
        generateBtn.disabled = !(reason && tenure && stance);
    }

    // Tab switching
    tabTatemae.addEventListener('click', () => switchTab('tatemae'));
    tabHonne.addEventListener('click', () => switchTab('honne'));

    function switchTab(tab) {
        currentTab = tab;
        tabTatemae.classList.toggle('active', tab === 'tatemae');
        tabHonne.classList.toggle('active', tab === 'honne');
        tatemaeArea.style.display = tab === 'tatemae' ? 'block' : 'none';
        honneArea.style.display = tab === 'honne' ? 'block' : 'none';
    }

    generateBtn.addEventListener('click', generate);
    retryBtn.addEventListener('click', generate);

    function generate() {
        if (!reason || !tenure || !stance) return;

        // Get texts
        const tatemae = getRandomText(TATEMAE, reason, stance);
        const honne = getRandomText(HONNE, reason, stance);

        // Add date formatting
        const today = new Date();
        const dateStr = `${today.getFullYear()}年${today.getMonth() + 1}月${today.getDate()}日`;

        const tatemaeFormatted = `${dateStr}\n\n${tatemae}`;
        const honneFormatted = `${dateStr}\n\n${honne}`;

        // Display
        resultReason.textContent = reason;
        resultTenure.textContent = TENURE_LABELS[tenure];
        resultStance.textContent = STANCE_LABELS[stance];
        tatemaeText.textContent = tatemaeFormatted;
        honneText.textContent = honneFormatted;

        // Meters
        const peacefulMap = { gentle: 95, normal: 70, firm: 40, explosive: 5 };
        const honneMap = { gentle: 30, normal: 55, firm: 80, explosive: 100 };
        const pVal = peacefulMap[stance] + Math.floor(Math.random() * 10) - 5;
        const hVal = honneMap[stance] + Math.floor(Math.random() * 10) - 5;

        setTimeout(() => {
            peacefulFill.style.width = pVal + '%';
            peacefulValue.textContent = pVal + '%';
            honneFill.style.width = hVal + '%';
            honneValue.textContent = hVal + '%';
        }, 100);

        // Tip
        const tips = TIPS[reason] || TIPS["なんとなく"];
        tipText.textContent = "💡 " + tips[Math.floor(Math.random() * tips.length)];

        // Reset to tatemae tab
        switchTab('tatemae');

        // Show
        resultSection.style.display = 'block';
        resultSection.style.animation = 'none';
        resultSection.offsetHeight;
        resultSection.style.animation = 'fadeInUp 0.5s ease';
        resultSection.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }

    function getRandomText(data, reason, stance) {
        const reasonData = data[reason];
        if (!reasonData) return getDefaultText(stance);

        const stanceData = reasonData[stance];
        if (!stanceData || stanceData.length === 0) {
            // fallback to normal
            const fallback = reasonData['normal'] || reasonData['gentle'];
            if (fallback) return fallback[Math.floor(Math.random() * fallback.length)];
            return getDefaultText(stance);
        }

        return stanceData[Math.floor(Math.random() * stanceData.length)];
    }

    function getDefaultText(stance) {
        const defaults = {
            gentle: "一身上の都合により、退職させていただきたく存じます。\n\nこれまで大変お世話になりました。心より感謝申し上げます。",
            normal: "一身上の都合により、退職いたします。\n\n引き継ぎは責任をもって行います。",
            firm: "退職届を提出いたします。\n\n本決意は固く、撤回の予定はございません。",
            explosive: "辞めます。以上。\n\nもう限界です。さようなら。"
        };
        return defaults[stance] || defaults['normal'];
    }

    // Copy
    copyBtn.addEventListener('click', () => {
        const text = currentTab === 'tatemae' ? tatemaeText.textContent : honneText.textContent;
        navigator.clipboard.writeText(text).then(() => {
            const label = currentTab === 'tatemae' ? '建前をコピーしました！' : '本音をコピーしました！（提出しないでね）';
            showToast(label);
        });
    });

    // Share
    shareBtn.addEventListener('click', () => {
        const text = `【AI退職届メーカー】で「${reason}」が理由の退職届を作成しました（円満度: ${peacefulValue.textContent}）`;
        if (navigator.share) {
            navigator.share({ title: 'AI退職届メーカー', text: text });
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
