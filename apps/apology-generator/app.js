document.addEventListener('DOMContentLoaded', () => {
    let target = null;
    let situation = null;
    let severity = null;
    let format = 'business';

    // Worker API URL
    const API_URL = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
        ? 'http://localhost:8787'
        : 'https://ai-omoshiro-api.kojifo369.workers.dev';

    const targetGrid = document.getElementById('targetGrid');
    const situationGrid = document.getElementById('situationGrid');
    const severityButtons = document.getElementById('severityButtons');
    const formatButtons = document.getElementById('formatButtons');
    const generateBtn = document.getElementById('generateBtn');
    const resultSection = document.getElementById('resultSection');
    const resultTarget = document.getElementById('resultTarget');
    const resultSituation = document.getElementById('resultSituation');
    const resultSeverity = document.getElementById('resultSeverity');
    const resultFormat = document.getElementById('resultFormat');
    const apologyText = document.getElementById('apologyText');
    const sincerityFill = document.getElementById('sincerityFill');
    const sincerityValue = document.getElementById('sincerityValue');
    const tipText = document.getElementById('tipText');
    const copyBtn = document.getElementById('copyBtn');
    const shareXBtn = document.getElementById('shareXBtn');
    const shareLINEBtn = document.getElementById('shareLINEBtn');
    const retryBtn = document.getElementById('retryBtn');
    const toast = document.getElementById('toast');

    const severityLabels = { light: '軽め', medium: 'そこそこ', heavy: 'かなりヤバい', critical: '人生終了レベル' };
    const formatLabels = { business: 'ビジネスメール', line: 'LINE', letter: '手紙' };

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

    setupSelection(targetGrid, (v) => { target = v; });
    setupSelection(situationGrid, (v) => { situation = v; });
    setupSelection(severityButtons, (v) => { severity = v; });
    setupSelection(formatButtons, (v) => { format = v; });

    function updateGenerateBtn() {
        generateBtn.disabled = !(target && situation && severity);
    }

    generateBtn.addEventListener('click', generate);
    retryBtn.addEventListener('click', generate);

    let isGenerating = false;

    async function generate() {
        if (!target || !situation || !severity) return;
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
            generateBtn.textContent = '謝罪文を生成する ✨';
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
                    app: 'apology-generator',
                    params: { target, situation, severity, format }
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
                text: d.text,
                sincerity: clamp(d.sincerity || 70, 10, 99),
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
        const text = getApologyText();

        const sincerityMap = { light: 40, medium: 65, heavy: 85, critical: 99 };
        const base = sincerityMap[severity];
        const sincerity = base + Math.floor(Math.random() * 10) - 5;

        const tips = TIPS[target] || TIPS["友達"];
        const tip = tips[Math.floor(Math.random() * tips.length)];

        return {
            text: text,
            sincerity: sincerity,
            tip: tip,
            source: 'static'
        };
    }

    // ── 結果表示（共通） ──
    function displayResult(result) {
        resultTarget.textContent = target;
        resultSituation.textContent = situation;
        resultSeverity.textContent = severityLabels[severity];
        resultFormat.textContent = formatLabels[format];
        apologyText.textContent = result.text;

        // Sincerity meter
        setTimeout(() => {
            sincerityFill.style.width = result.sincerity + '%';
            sincerityValue.textContent = result.sincerity + '%';
        }, 100);

        // Tip
        if (result.tip) {
            tipText.textContent = '💡 ' + result.tip;
        } else {
            const tips = TIPS[target] || TIPS["友達"];
            tipText.textContent = '💡 ' + tips[Math.floor(Math.random() * tips.length)];
        }

        // Show
        resultSection.style.display = 'block';
        resultSection.style.animation = 'none';
        resultSection.offsetHeight;
        resultSection.style.animation = 'fadeInUp 0.5s ease';
        resultSection.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }

    function clamp(val, min, max) {
        return Math.min(max, Math.max(min, val));
    }

    function getApologyText() {
        // Try to find exact match
        let formatKey = format;
        if (format === 'letter') formatKey = 'business'; // letter uses business as base

        const formatData = APOLOGY_DATA[formatKey];
        if (!formatData) return getFallbackText();

        const targetData = formatData[target];
        if (!targetData) return getFallbackText();

        const situationData = targetData[situation];
        if (!situationData) return getFallbackText();

        const severityData = situationData[severity];
        if (!severityData || severityData.length === 0) {
            // Try fallback to medium
            const fallback = situationData['medium'] || situationData['light'];
            if (fallback) return fallback[Math.floor(Math.random() * fallback.length)];
            return getFallbackText();
        }

        let text = severityData[Math.floor(Math.random() * severityData.length)];

        // Letter format: add formal header/footer
        if (format === 'letter') {
            text = convertToLetter(text);
        }

        return text;
    }

    function convertToLetter(text) {
        const lines = text.split('\n').filter(l => l.trim());
        // Remove casual greetings and rebuild as letter
        const body = lines.filter(l => !l.startsWith('いつもお世話') && !l.startsWith('お疲れ様')).join('\n');

        return `拝啓\n\n時下ますますご清祥のこととお慶び申し上げます。\n\n${body}\n\n何卒ご容赦くださいますよう、伏してお願い申し上げます。\n\n敬具`;
    }

    function getFallbackText() {
        const casual = format === 'line';
        if (casual) {
            const texts = [
                `${situation}の件、本当にごめん。反省してる。これからは気をつける。`,
                `ごめんなさい。${situation}して迷惑かけて。二度としないから許して。`,
                `${situation}のこと、本当に申し訳ないと思ってる。ちゃんと話したい。`
            ];
            return texts[Math.floor(Math.random() * texts.length)];
        } else {
            const texts = [
                `この度は${situation}の件でご迷惑をおかけし、誠に申し訳ございません。\n\n深く反省しており、今後このようなことがないよう再発防止に努めてまいります。\n\n重ねてお詫び申し上げます。`,
                `${situation}の件について、心よりお詫び申し上げます。\n\n自身の不注意により、ご迷惑をおかけしましたこと、弁解の余地もございません。\n\n今後は十分に注意し、信頼回復に努めてまいります。`
            ];
            return texts[Math.floor(Math.random() * texts.length)];
        }
    }

    // Copy
    copyBtn.addEventListener('click', () => {
        navigator.clipboard.writeText(apologyText.textContent).then(() => {
            showToast('コピーしました！');
        });
    });

    // Share on X (Twitter)
    shareXBtn.addEventListener('click', () => {
        const appUrl = 'https://solodev-lab.github.io/ai-omoshiro-tools/apps/apology-generator/';
        const text = `【AI謝罪文ジェネレーター】で${target}への${situation}の謝罪文を作りました（誠意レベル: ${sincerityValue.textContent}）\n${appUrl}`;
        const hashtags = 'AI謝罪文,個人開発';
        const url = `https://twitter.com/intent/tweet?text=${encodeURIComponent(text)}&hashtags=${encodeURIComponent(hashtags)}`;
        window.open(url, '_blank');
    });

    // Share on LINE
    shareLINEBtn.addEventListener('click', () => {
        const appUrl = 'https://solodev-lab.github.io/ai-omoshiro-tools/apps/apology-generator/';
        const text = `【AI謝罪文ジェネレーター】で${target}への${situation}の謝罪文を作りました（誠意レベル: ${sincerityValue.textContent}）\n${appUrl}`;
        const url = `https://social-plugins.line.me/lineit/share?url=${encodeURIComponent(appUrl)}&text=${encodeURIComponent(text)}`;
        window.open(url, '_blank');
    });

    function showToast(message) {
        toast.textContent = message;
        toast.classList.add('show');
        setTimeout(() => toast.classList.remove('show'), 2000);
    }
});
