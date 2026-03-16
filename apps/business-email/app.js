document.addEventListener('DOMContentLoaded', () => {
    let selectedScene = null;
    let selectedTarget = null;
    let selectedTone = 'polite';
    let history = JSON.parse(localStorage.getItem('emailHistory') || '[]');

    // Worker API URL
    const API_URL = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
        ? 'http://localhost:8787'
        : 'https://ai-omoshiro-api.kojifo369.workers.dev';

    const sceneGrid = document.getElementById('sceneGrid');
    const targetSection = document.getElementById('targetSection');
    const targetGrid = document.getElementById('targetGrid');
    const toneSection = document.getElementById('toneSection');
    const toneButtons = document.getElementById('toneButtons');
    const detailSection = document.getElementById('detailSection');
    const detailInput = document.getElementById('detailInput');
    const charCount = document.getElementById('charCount');
    const generateBtn = document.getElementById('generateBtn');
    const resultSection = document.getElementById('resultSection');
    const resultScene = document.getElementById('resultScene');
    const resultTarget = document.getElementById('resultTarget');
    const subjectText = document.getElementById('subjectText');
    const bodyText = document.getElementById('bodyText');
    const politeBar = document.getElementById('politeBar');
    const politeValue = document.getElementById('politeValue');
    const clarityBar = document.getElementById('clarityBar');
    const clarityValue = document.getElementById('clarityValue');
    const likableBar = document.getElementById('likableBar');
    const likableValue = document.getElementById('likableValue');
    const tipBlock = document.getElementById('tipBlock');
    const tipText = document.getElementById('tipText');
    const copySubjectBtn = document.getElementById('copySubjectBtn');
    const copyBodyBtn = document.getElementById('copyBodyBtn');
    const copyAllBtn = document.getElementById('copyAllBtn');
    const shareXBtn = document.getElementById('shareXBtn');
    const shareLINEBtn = document.getElementById('shareLINEBtn');
    const retryBtn = document.getElementById('retryBtn');
    const historySection = document.getElementById('historySection');
    const historyList = document.getElementById('historyList');
    const toast = document.getElementById('toast');

    // Scene selection
    sceneGrid.addEventListener('click', (e) => {
        const btn = e.target.closest('.scene-btn');
        if (!btn) return;
        document.querySelectorAll('.scene-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        selectedScene = btn.dataset.scene;
        targetSection.style.display = 'block';
        targetSection.style.animation = 'none';
        targetSection.offsetHeight;
        targetSection.style.animation = 'fadeInUp 0.4s ease';
        updateGenerateBtn();
    });

    // Target selection
    targetGrid.addEventListener('click', (e) => {
        const btn = e.target.closest('.target-btn');
        if (!btn) return;
        document.querySelectorAll('.target-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        selectedTarget = btn.dataset.target;
        toneSection.style.display = 'block';
        detailSection.style.display = 'block';
        toneSection.style.animation = 'none';
        toneSection.offsetHeight;
        toneSection.style.animation = 'fadeInUp 0.4s ease';
        detailSection.style.animation = 'none';
        detailSection.offsetHeight;
        detailSection.style.animation = 'fadeInUp 0.4s ease';
        updateGenerateBtn();
    });

    // Tone selection
    toneButtons.addEventListener('click', (e) => {
        const btn = e.target.closest('.tone-btn');
        if (!btn) return;
        document.querySelectorAll('.tone-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        selectedTone = btn.dataset.tone;
    });

    // Detail input char count
    detailInput.addEventListener('input', () => {
        charCount.textContent = detailInput.value.length + '/100';
    });

    function updateGenerateBtn() {
        generateBtn.disabled = !(selectedScene && selectedTarget);
    }

    // Generate
    generateBtn.addEventListener('click', generateEmail);
    retryBtn.addEventListener('click', generateEmail);

    let isGenerating = false;

    async function generateEmail() {
        if (!selectedScene || !selectedTarget) return;
        if (isGenerating) return;
        isGenerating = true;

        generateBtn.disabled = true;
        generateBtn.textContent = '生成中… ✉️';
        retryBtn.disabled = true;

        try {
            const result = await generateWithAI();
            displayResult(result);
        } catch (err) {
            console.warn('AI生成失敗、フォールバック:', err.message);
            const result = generateFromStatic();
            displayResult(result);
        } finally {
            isGenerating = false;
            generateBtn.disabled = false;
            generateBtn.textContent = 'メールを生成する ✉️';
            retryBtn.disabled = false;
        }
    }

    // AI generation
    async function generateWithAI() {
        const controller = new AbortController();
        const timeout = setTimeout(() => controller.abort(), 15000);

        try {
            const res = await fetch(API_URL + '/api/generate', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    app: 'business-email',
                    params: {
                        scene: selectedScene,
                        target: selectedTarget,
                        tone: selectedTone,
                        detail: detailInput.value.trim()
                    }
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
            return {
                subject: d.subject || '件名なし',
                body: d.body || '本文なし',
                polite: clamp(d.polite || 70, 1, 99),
                clarity: clamp(d.clarity || 70, 1, 99),
                likable: clamp(d.likable || 70, 1, 99),
                tip: d.tip || '',
                source: 'ai'
            };
        } catch (err) {
            clearTimeout(timeout);
            throw err;
        }
    }

    // Static fallback
    function generateFromStatic() {
        const sceneData = EMAIL_TEMPLATES[selectedScene];
        const targetData = sceneData ? sceneData[selectedTarget] : null;
        const toneData = targetData ? targetData[selectedTone] : null;

        let email;
        if (toneData && toneData.length > 0) {
            email = toneData[Math.floor(Math.random() * toneData.length)];
        } else {
            email = { subject: selectedScene + 'のメール', body: '○○様\n\n○○の件についてご連絡いたします。\n\nよろしくお願いいたします。' };
        }

        const stats = TONE_STATS[selectedTone] || TONE_STATS.normal;
        return {
            subject: email.subject,
            body: email.body,
            polite: randomInRange(stats.polite[0], stats.polite[1]),
            clarity: randomInRange(stats.clarity[0], stats.clarity[1]),
            likable: randomInRange(stats.likable[0], stats.likable[1]),
            tip: '',
            source: 'static'
        };
    }

    // Display result
    function displayResult(result) {
        resultScene.textContent = selectedScene;
        resultTarget.textContent = selectedTarget;
        subjectText.textContent = result.subject;
        bodyText.textContent = result.body;

        setTimeout(() => {
            politeBar.style.width = result.polite + '%';
            politeValue.textContent = result.polite + '%';
            clarityBar.style.width = result.clarity + '%';
            clarityValue.textContent = result.clarity + '%';
            likableBar.style.width = result.likable + '%';
            likableValue.textContent = result.likable + '%';
        }, 100);

        if (result.tip) {
            tipBlock.style.display = 'flex';
            tipText.textContent = result.tip;
        } else {
            tipBlock.style.display = 'none';
        }

        resultSection.style.display = 'block';
        resultSection.style.animation = 'none';
        resultSection.offsetHeight;
        resultSection.style.animation = 'fadeInUp 0.5s ease';
        resultSection.scrollIntoView({ behavior: 'smooth', block: 'center' });

        addToHistory(selectedScene, selectedTarget, result.subject);
    }

    function clamp(val, min, max) {
        return Math.min(max, Math.max(min, val));
    }

    function randomInRange(min, max) {
        return Math.floor(Math.random() * (max - min + 1)) + min;
    }

    // Copy buttons
    copySubjectBtn.addEventListener('click', () => {
        navigator.clipboard.writeText(subjectText.textContent).then(() => showToast('件名をコピーしました！'));
    });

    copyBodyBtn.addEventListener('click', () => {
        navigator.clipboard.writeText(bodyText.textContent).then(() => showToast('本文をコピーしました！'));
    });

    copyAllBtn.addEventListener('click', () => {
        const text = '件名: ' + subjectText.textContent + '\n\n' + bodyText.textContent;
        navigator.clipboard.writeText(text).then(() => showToast('全文をコピーしました！'));
    });

    // Share
    const appUrl = 'https://solodev-lab.github.io/ai-omoshiro-tools/apps/business-email/';

    shareXBtn.addEventListener('click', () => {
        const text = '【AIビジネスメール生成】\n' + selectedScene + '×' + selectedTarget + ' のメールをAIが自動作成！\n\n件名: ' + subjectText.textContent + '\n\n#AIビジネスメール #AIおもしろツール\n' + appUrl;
        window.open('https://twitter.com/intent/tweet?text=' + encodeURIComponent(text), '_blank');
    });

    shareLINEBtn.addEventListener('click', () => {
        const text = '【AIビジネスメール生成】\n' + selectedScene + '×' + selectedTarget + ' のメールをAIが自動作成！';
        window.open('https://social-plugins.line.me/lineit/share?url=' + encodeURIComponent(appUrl) + '&text=' + encodeURIComponent(text), '_blank');
    });

    // History
    function addToHistory(scene, target, subject) {
        history.unshift({
            scene: scene,
            target: target,
            subject: subject,
            time: new Date().toLocaleTimeString('ja-JP', { hour: '2-digit', minute: '2-digit' })
        });
        if (history.length > 10) history = history.slice(0, 10);
        localStorage.setItem('emailHistory', JSON.stringify(history));
        renderHistory();
    }

    function renderHistory() {
        if (history.length === 0) {
            historySection.style.display = 'none';
            return;
        }
        historySection.style.display = 'block';
        historyList.innerHTML = history.map(item => `
            <div class="history-item">
                <span class="history-text">${item.subject}</span>
                <span class="history-tag">${item.scene}→${item.target}</span>
            </div>
        `).join('');
    }

    function showToast(message) {
        toast.textContent = message;
        toast.classList.add('show');
        setTimeout(() => toast.classList.remove('show'), 2000);
    }

    renderHistory();
});
