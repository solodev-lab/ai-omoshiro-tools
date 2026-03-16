const API_URL = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
    ? 'http://localhost:8787'
    : 'https://ai-omoshiro-api.kojifo369.workers.dev';

const SHARE_URL = 'https://solodev-lab.github.io/ai-omoshiro-tools/apps/compatibility/';

document.addEventListener('DOMContentLoaded', () => {
    // DOM要素
    const inputSection = document.getElementById('inputSection');
    const analyzingSection = document.getElementById('analyzingSection');
    const resultSection = document.getElementById('resultSection');
    const historySection = document.getElementById('historySection');
    const name1Input = document.getElementById('name1');
    const name2Input = document.getElementById('name2');
    const diagnoseBtn = document.getElementById('diagnoseBtn');
    const analyzingStatus = document.getElementById('analyzingStatus');
    const resultNames = document.getElementById('resultNames');
    const gaugeNumber = document.getElementById('gaugeNumber');
    const gaugeFill = document.getElementById('gaugeFill');
    const resultRank = document.getElementById('resultRank');
    const resultAnalysis = document.getElementById('resultAnalysis');
    const resultAdvice = document.getElementById('resultAdvice');
    const shareXBtn = document.getElementById('shareXBtn');
    const shareLINEBtn = document.getElementById('shareLINEBtn');
    const copyBtn = document.getElementById('copyBtn');
    const retryBtn = document.getElementById('retryBtn');
    const historyList = document.getElementById('historyList');
    const toast = document.getElementById('toast');

    // SVGグラデーション定義を追加
    const svg = document.querySelector('.circle-gauge svg');
    const defs = document.createElementNS('http://www.w3.org/2000/svg', 'defs');
    const gradient = document.createElementNS('http://www.w3.org/2000/svg', 'linearGradient');
    gradient.setAttribute('id', 'gaugeGradient');
    gradient.setAttribute('x1', '0%');
    gradient.setAttribute('y1', '0%');
    gradient.setAttribute('x2', '100%');
    gradient.setAttribute('y2', '0%');
    const stop1 = document.createElementNS('http://www.w3.org/2000/svg', 'stop');
    stop1.setAttribute('offset', '0%');
    stop1.setAttribute('stop-color', '#ff6b9d');
    const stop2 = document.createElementNS('http://www.w3.org/2000/svg', 'stop');
    stop2.setAttribute('offset', '100%');
    stop2.setAttribute('stop-color', '#c44569');
    gradient.appendChild(stop1);
    gradient.appendChild(stop2);
    defs.appendChild(gradient);
    svg.insertBefore(defs, svg.firstChild);

    // 現在の結果データ
    let currentResult = null;

    // 初期化: 履歴表示
    renderHistory();

    // 診断ボタン
    diagnoseBtn.addEventListener('click', startDiagnosis);

    // Enterキーで診断開始
    name1Input.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') name2Input.focus();
    });
    name2Input.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') startDiagnosis();
    });

    function startDiagnosis() {
        const name1 = name1Input.value.trim();
        const name2 = name2Input.value.trim();

        if (!name1 || !name2) {
            showToast('2人の名前を入力してください');
            return;
        }

        diagnoseBtn.disabled = true;
        inputSection.style.display = 'none';
        historySection.style.display = 'none';
        analyzingSection.style.display = 'block';

        // 静的スコア計算
        const staticScore = calcStaticScore(name1, name2);
        const staticResult = buildStaticResult(name1, name2, staticScore);

        // AI呼び出し（並行実行）
        const aiPromise = analyzeWithAI(name1, name2);

        const statuses = [
            '2人の相性を解析しています',
            '名前の響きを分析中...',
            '相性パターンを照合しています',
            '診断レポートを作成中...',
            '結果が出ました！'
        ];

        let i = 0;
        const interval = setInterval(() => {
            i++;
            if (i < statuses.length) {
                analyzingStatus.textContent = statuses[i];
            }
            if (i >= statuses.length) {
                clearInterval(interval);
                aiPromise.then(aiData => {
                    const result = aiData
                        ? { name1, name2, score: aiData.score || staticScore, rank: aiData.rank, analysis: aiData.analysis, advice: aiData.advice }
                        : staticResult;
                    setTimeout(() => showResult(result), 500);
                }).catch(() => {
                    setTimeout(() => showResult(staticResult), 500);
                });
            }
        }, 600);
    }

    // 静的スコア計算（名前のcharCodeから決定論的に算出）
    function calcStaticScore(name1, name2) {
        let hash = 0;
        const combined = name1 + name2;
        for (let i = 0; i < combined.length; i++) {
            hash = ((hash << 5) - hash + combined.charCodeAt(i)) | 0;
        }
        // 40〜99の範囲にマッピング
        const score = 40 + (Math.abs(hash) % 60);
        return score;
    }

    // ランク判定
    function getRank(score) {
        if (score >= 90) return { rank: '最高の相性', color: '#ff4d8d', emoji: '\u2728' };
        if (score >= 80) return { rank: '素晴らしい相性', color: '#ff6b9d', emoji: '\u{1F496}' };
        if (score >= 70) return { rank: '良い相性', color: '#ff8fb1', emoji: '\u{1F60A}' };
        if (score >= 60) return { rank: 'まあまあの相性', color: '#ffb3c6', emoji: '\u{1F914}' };
        if (score >= 50) return { rank: '普通の相性', color: '#ccc', emoji: '\u{1F643}' };
        return { rank: '努力次第の相性', color: '#aaa', emoji: '\u{1F4AA}' };
    }

    // 静的結果生成
    function buildStaticResult(name1, name2, score) {
        const rankInfo = getRank(score);

        const analysisTemplates = {
            90: name1 + 'さんと' + name2 + 'さんは、まるで運命の糸で結ばれているような最高の相性です。お互いの長所を引き出し合い、一緒にいるだけで自然とエネルギーが湧いてくる関係です。',
            80: name1 + 'さんと' + name2 + 'さんは、とても息の合った素晴らしいコンビです。価値観が近く、お互いを理解し合える信頼関係を築けるでしょう。',
            70: name1 + 'さんと' + name2 + 'さんは、バランスの取れた良い相性です。時に意見が異なることもありますが、それが新しい発見につながる関係です。',
            60: name1 + 'さんと' + name2 + 'さんは、お互いの違いを楽しめる関係です。歩み寄りの姿勢があれば、より深い絆を築いていけるでしょう。',
            50: name1 + 'さんと' + name2 + 'さんは、まだお互いを知る余地がある関係です。共通の話題や体験を増やすことで、距離がぐっと縮まるでしょう。',
            0: name1 + 'さんと' + name2 + 'さんは、異なるタイプだからこそ刺激し合える関係です。違いを認め合い、尊重することで素晴らしいパートナーシップが生まれます。'
        };

        const adviceTemplates = {
            90: '最高の相性を活かして、一緒に新しいことにチャレンジしてみましょう。2人なら何でも乗り越えられるはずです！',
            80: '定期的にお互いの気持ちを伝え合うことで、さらに絆が深まります。感謝の言葉を忘れずに！',
            70: 'お互いの趣味や興味を共有する時間を作りましょう。新しい共通点が見つかるかもしれません。',
            60: '相手の話にじっくり耳を傾けることを意識しましょう。理解し合えるポイントがきっと見つかります。',
            50: '一緒に楽しめるアクティビティを見つけることがカギです。小さな成功体験を積み重ねていきましょう。',
            0: '違いを「面白い」と思える心の余裕が大切です。相手の良いところを3つ見つけることから始めてみましょう。'
        };

        function getTemplate(templates, score) {
            if (score >= 90) return templates[90];
            if (score >= 80) return templates[80];
            if (score >= 70) return templates[70];
            if (score >= 60) return templates[60];
            if (score >= 50) return templates[50];
            return templates[0];
        }

        return {
            name1,
            name2,
            score,
            rank: rankInfo.rank,
            analysis: getTemplate(analysisTemplates, score),
            advice: getTemplate(adviceTemplates, score)
        };
    }

    // AI分析
    async function analyzeWithAI(name1, name2) {
        try {
            const controller = new AbortController();
            const timeoutId = setTimeout(() => controller.abort(), 15000);

            const response = await fetch(API_URL + '/api/generate', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    app: 'compatibility',
                    params: { name1, name2 }
                }),
                signal: controller.signal
            });

            clearTimeout(timeoutId);

            if (!response.ok) throw new Error('API error: ' + response.status);

            const json = await response.json();
            if (!json.success || !json.data) throw new Error('Invalid response');
            return json.data;
        } catch (e) {
            console.log('AI analysis failed, using static fallback:', e.message);
            return null;
        }
    }

    // 結果表示
    function showResult(result) {
        currentResult = result;
        analyzingSection.style.display = 'none';
        resultSection.style.display = 'block';

        const rankInfo = getRank(result.score);

        resultNames.textContent = result.name1 + ' \u2764 ' + result.name2;
        resultRank.textContent = rankInfo.emoji + ' ' + result.rank;
        resultRank.style.color = rankInfo.color;
        resultAnalysis.textContent = result.analysis;
        resultAdvice.textContent = result.advice;

        // 円形ゲージアニメーション
        animateGauge(result.score);

        // 履歴に保存
        saveHistory(result);

        resultSection.scrollIntoView({ behavior: 'smooth' });
    }

    // 円形ゲージアニメーション
    function animateGauge(targetScore) {
        const circumference = 2 * Math.PI * 85; // 534.07
        const offset = circumference - (circumference * targetScore / 100);

        // リセット
        gaugeFill.style.transition = 'none';
        gaugeFill.style.strokeDashoffset = circumference;
        gaugeNumber.textContent = '0';

        // アニメーション開始
        requestAnimationFrame(() => {
            requestAnimationFrame(() => {
                gaugeFill.style.transition = 'stroke-dashoffset 1.5s ease-out';
                gaugeFill.style.strokeDashoffset = offset;
            });
        });

        // 数字カウントアップ
        let current = 0;
        const duration = 1500;
        const start = performance.now();

        function updateNumber(now) {
            const elapsed = now - start;
            const progress = Math.min(elapsed / duration, 1);
            // easeOutCubic
            const eased = 1 - Math.pow(1 - progress, 3);
            current = Math.round(eased * targetScore);
            gaugeNumber.textContent = current;

            if (progress < 1) {
                requestAnimationFrame(updateNumber);
            }
        }

        requestAnimationFrame(updateNumber);
    }

    // 履歴保存
    function saveHistory(result) {
        let history = JSON.parse(localStorage.getItem('compatibilityHistory') || '[]');

        history.unshift({
            name1: result.name1,
            name2: result.name2,
            score: result.score,
            rank: result.rank,
            analysis: result.analysis,
            advice: result.advice,
            date: new Date().toISOString()
        });

        // 最大10件
        if (history.length > 10) {
            history = history.slice(0, 10);
        }

        localStorage.setItem('compatibilityHistory', JSON.stringify(history));
    }

    // 履歴表示
    function renderHistory() {
        const history = JSON.parse(localStorage.getItem('compatibilityHistory') || '[]');

        if (history.length === 0) {
            historySection.style.display = 'none';
            return;
        }

        historySection.style.display = 'block';
        historyList.innerHTML = '';

        history.forEach((item, index) => {
            const div = document.createElement('div');
            div.className = 'history-item';
            div.innerHTML = '<div class="history-names">' + item.name1 + ' \u2764 ' + item.name2 + '</div>' +
                '<div class="history-right">' +
                '<span class="history-rank">' + item.rank + '</span>' +
                '<span class="history-score">' + item.score + '%</span>' +
                '</div>';

            div.addEventListener('click', () => {
                // 履歴から結果を再表示
                inputSection.style.display = 'none';
                historySection.style.display = 'none';
                showResult({
                    name1: item.name1,
                    name2: item.name2,
                    score: item.score,
                    rank: item.rank,
                    analysis: item.analysis,
                    advice: item.advice
                });
            });

            historyList.appendChild(div);
        });
    }

    // シェアテキスト生成
    function getShareText() {
        if (!currentResult) return '';
        const rankInfo = getRank(currentResult.score);
        return '\u3010AI\u76F8\u6027\u8A3A\u65AD\u3011\n' +
            currentResult.name1 + '\u3068' + currentResult.name2 + '\u306E\u76F8\u6027\u306F' + currentResult.score + '%\uFF01\n' +
            '\u300C' + currentResult.rank + '\u300D\n\n' +
            '#AI\u76F8\u6027\u8A3A\u65AD #AI\u304A\u3082\u3057\u308D\u30C4\u30FC\u30EB';
    }

    // X（Twitter）でシェア
    shareXBtn.addEventListener('click', () => {
        const text = getShareText() + '\n' + SHARE_URL;
        window.open('https://twitter.com/intent/tweet?text=' + encodeURIComponent(text), '_blank');
    });

    // LINEで送る
    shareLINEBtn.addEventListener('click', () => {
        const text = getShareText();
        window.open('https://social-plugins.line.me/lineit/share?url=' + encodeURIComponent(SHARE_URL) + '&text=' + encodeURIComponent(text), '_blank');
    });

    // コピー
    copyBtn.addEventListener('click', () => {
        if (!currentResult) return;
        const text = getShareText() + '\n' + SHARE_URL;
        navigator.clipboard.writeText(text).then(() => {
            showToast('\u30B3\u30D4\u30FC\u3057\u307E\u3057\u305F\uFF01');
        });
    });

    // リトライ
    retryBtn.addEventListener('click', () => {
        currentResult = null;
        resultSection.style.display = 'none';
        inputSection.style.display = 'block';
        name1Input.value = '';
        name2Input.value = '';
        diagnoseBtn.disabled = false;
        renderHistory();
        window.scrollTo({ top: 0, behavior: 'smooth' });
    });

    // トースト
    function showToast(message) {
        toast.textContent = message;
        toast.classList.add('show');
        setTimeout(() => toast.classList.remove('show'), 2000);
    }
});
