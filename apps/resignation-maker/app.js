document.addEventListener('DOMContentLoaded', () => {
    const API_URL = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
        ? 'http://localhost:8787'
        : 'https://ai-omoshiro-api.kojifo369.workers.dev';

    let reason = null;
    let tenure = null;
    let stance = null;
    let currentTab = 'tatemae';
    let isGenerating = false;

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

    async function generate() {
        if (!reason || !tenure || !stance) return;
        if (isGenerating) return;

        isGenerating = true;
        generateBtn.disabled = true;
        generateBtn.textContent = '考え中… ✨';

        try {
            await generateWithAI();
        } catch (err) {
            console.warn('AI generation failed, using static fallback:', err);
            generateFromStatic();
        } finally {
            isGenerating = false;
            generateBtn.textContent = '退職届を生成する ✨';
            generateBtn.disabled = !(reason && tenure && stance);
        }
    }

    async function generateWithAI() {
        const res = await fetch(API_URL + '/api/generate', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                app: 'resignation-maker',
                params: { reason, tenure, stance }
            })
        });

        if (!res.ok) throw new Error('API response ' + res.status);

        const json = await res.json();
        if (!json.success || !json.data) throw new Error('Invalid response');
        const data = json.data;
        if (!data.tatemae || !data.honne) throw new Error('Missing tatemae/honne in response');

        // Date header
        const today = new Date();
        const dateStr = today.getFullYear() + '年' + (today.getMonth() + 1) + '月' + today.getDate() + '日';

        // Display input summary
        resultReason.textContent = reason;
        resultTenure.textContent = TENURE_LABELS[tenure];
        resultStance.textContent = STANCE_LABELS[stance];

        // Texts with date header
        tatemaeText.textContent = dateStr + '\n\n' + data.tatemae;
        honneText.textContent = dateStr + '\n\n' + data.honne;

        // Meters
        const pVal = clamp(data.peaceful, 5, 99);
        const hVal = clamp(data.honne_score, 5, 99);

        setTimeout(() => {
            peacefulFill.style.width = pVal + '%';
            peacefulValue.textContent = pVal + '%';
            honneFill.style.width = hVal + '%';
            honneValue.textContent = hVal + '%';
        }, 100);

        // Tip
        tipText.textContent = data.tip || ('💡 ' + getRandomTip());

        // Reset to tatemae tab
        switchTab('tatemae');

        showResult();
    }

    function generateFromStatic() {
        // Get texts
        const tatemae = getRandomText(TATEMAE, reason, stance);
        const honne = getRandomText(HONNE, reason, stance);

        // Add date formatting
        const today = new Date();
        const dateStr = today.getFullYear() + '年' + (today.getMonth() + 1) + '月' + today.getDate() + '日';

        const tatemaeFormatted = dateStr + '\n\n' + tatemae;
        const honneFormatted = dateStr + '\n\n' + honne;

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
        tipText.textContent = '💡 ' + getRandomTip();

        // Reset to tatemae tab
        switchTab('tatemae');

        showResult();
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

    function getRandomTip() {
        const tips = TIPS[reason] || TIPS["なんとなく"];
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

    // Copy
    copyBtn.addEventListener('click', () => {
        const text = currentTab === 'tatemae' ? tatemaeText.textContent : honneText.textContent;
        navigator.clipboard.writeText(text).then(() => {
            const label = currentTab === 'tatemae' ? '建前をコピーしました！' : '本音をコピーしました！（提出しないでね）';
            showToast(label);
        });
    });

    // Share on X (Twitter)
    const APP_URL = 'https://solodev-lab.github.io/ai-omoshiro-tools/apps/resignation-maker/';
    shareXBtn.addEventListener('click', () => {
        const text = `【AI退職届メーカー】で「${reason}」が理由の退職届を作成しました（円満度: ${peacefulValue.textContent}）`;
        const hashtags = '退職届,AI,個人開発';
        const url = `https://twitter.com/intent/tweet?text=${encodeURIComponent(text)}&url=${encodeURIComponent(APP_URL)}&hashtags=${encodeURIComponent(hashtags)}`;
        window.open(url, '_blank');
    });

    // Share on LINE
    shareLINEBtn.addEventListener('click', () => {
        const text = `【AI退職届メーカー】で「${reason}」が理由の退職届を作成しました（円満度: ${peacefulValue.textContent}）\n${APP_URL}`;
        const url = `https://social-plugins.line.me/lineit/share?url=${encodeURIComponent(APP_URL)}&text=${encodeURIComponent(text)}`;
        window.open(url, '_blank');
    });

    function showToast(message) {
        toast.textContent = message;
        toast.classList.add('show');
        setTimeout(() => toast.classList.remove('show'), 2000);
    }
});
