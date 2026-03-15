document.addEventListener('DOMContentLoaded', () => {
    let selectedSituation = null;
    let selectedLevel = 'normal';
    let history = JSON.parse(localStorage.getItem('excuseHistory') || '[]');

    // Worker API URL
    const API_URL = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
        ? 'http://localhost:8787'
        : 'https://ai-omoshiro-api.kojifo369.workers.dev';

    const situationGrid = document.getElementById('situationGrid');
    const levelButtons = document.getElementById('levelButtons');
    const generateBtn = document.getElementById('generateBtn');
    const resultSection = document.getElementById('resultSection');
    const resultCard = document.getElementById('resultCard');
    const resultSituation = document.getElementById('resultSituation');
    const resultLevel = document.getElementById('resultLevel');
    const excuseText = document.getElementById('excuseText');
    const convincingBar = document.getElementById('convincingBar');
    const convincingValue = document.getElementById('convincingValue');
    const creativityBar = document.getElementById('creativityBar');
    const creativityValue = document.getElementById('creativityValue');
    const stealthBar = document.getElementById('stealthBar');
    const stealthValue = document.getElementById('stealthValue');
    const riskBadge = document.getElementById('riskBadge');
    const copyBtn = document.getElementById('copyBtn');
    const shareXBtn = document.getElementById('shareXBtn');
    const shareLINEBtn = document.getElementById('shareLINEBtn');
    const retryBtn = document.getElementById('retryBtn');
    const historySection = document.getElementById('historySection');
    const historyList = document.getElementById('historyList');
    const toast = document.getElementById('toast');

    const levelLabels = {
        normal: '普通',
        creative: 'クリエイティブ',
        genius: '天才',
        chaos: 'カオス'
    };

    // Situation selection
    situationGrid.addEventListener('click', (e) => {
        const btn = e.target.closest('.situation-btn');
        if (!btn) return;

        document.querySelectorAll('.situation-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        selectedSituation = btn.dataset.situation;
        generateBtn.disabled = false;
    });

    // Level selection
    levelButtons.addEventListener('click', (e) => {
        const btn = e.target.closest('.level-btn');
        if (!btn) return;

        document.querySelectorAll('.level-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        selectedLevel = btn.dataset.level;
    });

    // Generate excuse
    generateBtn.addEventListener('click', generateExcuse);
    retryBtn.addEventListener('click', generateExcuse);

    let isGenerating = false;

    async function generateExcuse() {
        if (!selectedSituation) return;
        if (isGenerating) return;
        isGenerating = true;

        // ボタンをローディング状態に
        generateBtn.disabled = true;
        generateBtn.textContent = '考え中… ✨';
        retryBtn.disabled = true;

        try {
            // AI生成を試行
            const result = await generateWithAI();
            displayResult(result);
        } catch (err) {
            console.warn('AI生成失敗、フォールバック:', err.message);
            // フォールバック: 静的データから生成
            const result = generateFromStatic();
            displayResult(result);
        } finally {
            isGenerating = false;
            generateBtn.disabled = false;
            generateBtn.textContent = '言い訳を生成する ✨';
            retryBtn.disabled = false;
        }
    }

    // ── AI生成 ──
    async function generateWithAI() {
        const controller = new AbortController();
        const timeout = setTimeout(() => controller.abort(), 15000); // 15秒タイムアウト

        try {
            const res = await fetch(API_URL + '/api/generate', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    app: 'excuse-generator',
                    params: { situation: selectedSituation, level: selectedLevel }
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

            // Risk mapping from AI response
            const riskMap = {
                low: { label: '🟢 バレにくい', class: 'risk-low' },
                medium: { label: '🟡 ちょっと危険', class: 'risk-medium' },
                high: { label: '🟠 かなり危険', class: 'risk-high' },
                extreme: { label: '🔴 確実にバレる', class: 'risk-extreme' }
            };

            return {
                excuse: d.excuse,
                convincing: clamp(d.convincing || 50, 1, 99),
                creativity: clamp(d.creativity || 50, 1, 99),
                stealth: clamp(d.stealth || 50, 1, 99),
                risk: riskMap[d.risk] || riskMap['medium'],
                tip: d.tip || '',
                source: 'ai'
            };
        } catch (err) {
            clearTimeout(timeout);
            throw err;
        }
    }

    // ── 静的データからのフォールバック生成 ──
    function generateFromStatic() {
        const excuses = EXCUSES[selectedSituation][selectedLevel];
        const excuse = excuses[Math.floor(Math.random() * excuses.length)];
        const stats = generateStats(selectedLevel);
        const risk = RISK_LEVELS[selectedLevel];

        return {
            excuse: excuse,
            convincing: stats.convincing,
            creativity: stats.creativity,
            stealth: stats.stealth,
            risk: risk,
            tip: '',
            source: 'static'
        };
    }

    // ── 結果表示（共通） ──
    function displayResult(result) {
        resultSituation.textContent = selectedSituation;
        resultLevel.textContent = levelLabels[selectedLevel];
        excuseText.textContent = result.excuse;

        // Animate stats
        setTimeout(() => {
            convincingBar.style.width = result.convincing + '%';
            convincingValue.textContent = result.convincing + '%';
            creativityBar.style.width = result.creativity + '%';
            creativityValue.textContent = result.creativity + '%';
            stealthBar.style.width = result.stealth + '%';
            stealthValue.textContent = result.stealth + '%';
        }, 100);

        // Risk badge
        riskBadge.textContent = result.risk.label;
        riskBadge.className = 'risk-badge ' + result.risk.class;

        // Show result with animation
        resultSection.style.display = 'block';
        resultSection.style.animation = 'none';
        resultSection.offsetHeight; // Trigger reflow
        resultSection.style.animation = 'fadeInUp 0.5s ease';

        // Scroll to result
        resultSection.scrollIntoView({ behavior: 'smooth', block: 'center' });

        // Save to history
        addToHistory(selectedSituation, selectedLevel, result.excuse);
    }

    function clamp(val, min, max) {
        return Math.min(max, Math.max(min, val));
    }

    function generateStats(level) {
        const ranges = {
            normal: { convincing: [60, 90], creativity: [20, 50], stealth: [70, 95] },
            creative: { convincing: [50, 80], creativity: [60, 85], stealth: [50, 80] },
            genius: { convincing: [30, 70], creativity: [80, 99], stealth: [20, 60] },
            chaos: { convincing: [5, 30], creativity: [90, 99], stealth: [1, 15] }
        };

        const range = ranges[level];
        return {
            convincing: randomInRange(range.convincing[0], range.convincing[1]),
            creativity: randomInRange(range.creativity[0], range.creativity[1]),
            stealth: randomInRange(range.stealth[0], range.stealth[1])
        };
    }

    function randomInRange(min, max) {
        return Math.floor(Math.random() * (max - min + 1)) + min;
    }

    // Copy
    copyBtn.addEventListener('click', () => {
        const text = excuseText.textContent;
        navigator.clipboard.writeText(text).then(() => {
            showToast('コピーしました！');
        });
    });

    // Share on X (Twitter)
    const appUrl = 'https://solodev-lab.github.io/ai-omoshiro-tools/apps/excuse-generator/';

    shareXBtn.addEventListener('click', () => {
        const text = `【AI言い訳ジェネレーター】\n${selectedSituation}の言い訳（${levelLabels[selectedLevel]}）\n\n「${excuseText.textContent}」\n\n#AI言い訳 #AIおもしろツール\n${appUrl}`;
        window.open('https://twitter.com/intent/tweet?text=' + encodeURIComponent(text), '_blank');
    });

    // Share on LINE
    shareLINEBtn.addEventListener('click', () => {
        const text = `【AI言い訳ジェネレーター】\n${selectedSituation}の言い訳（${levelLabels[selectedLevel]}）\n\n「${excuseText.textContent}」`;
        window.open('https://social-plugins.line.me/lineit/share?url=' + encodeURIComponent(appUrl) + '&text=' + encodeURIComponent(text), '_blank');
    });

    // History
    function addToHistory(situation, level, excuse) {
        history.unshift({
            situation: situation,
            level: levelLabels[level],
            excuse: excuse,
            time: new Date().toLocaleTimeString('ja-JP', { hour: '2-digit', minute: '2-digit' })
        });

        if (history.length > 10) {
            history = history.slice(0, 10);
        }

        localStorage.setItem('excuseHistory', JSON.stringify(history));
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
                <span class="history-text">${item.excuse}</span>
                <span class="history-tag">${item.situation}</span>
            </div>
        `).join('');
    }

    function showToast(message) {
        toast.textContent = message;
        toast.classList.add('show');
        setTimeout(() => toast.classList.remove('show'), 2000);
    }

    // Initial render
    renderHistory();
});
