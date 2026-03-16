var API_URL = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
    ? 'http://localhost:8787'
    : 'https://ai-omoshiro-api.kojifo369.workers.dev';

var SHARE_URL = 'https://solodev-lab.github.io/ai-omoshiro-tools/apps/love-type/';
var HISTORY_KEY = 'loveTypeHistory';

document.addEventListener('DOMContentLoaded', function() {
    // DOM要素
    var startSection = document.getElementById('startSection');
    var questionSection = document.getElementById('questionSection');
    var analyzingSection = document.getElementById('analyzingSection');
    var resultSection = document.getElementById('resultSection');
    var startBtn = document.getElementById('startBtn');
    var progressFill = document.getElementById('progressFill');
    var progressText = document.getElementById('progressText');
    var questionText = document.getElementById('questionText');
    var choicesContainer = document.getElementById('choicesContainer');
    var analyzingStatus = document.getElementById('analyzingStatus');
    var resultEmoji = document.getElementById('resultEmoji');
    var resultName = document.getElementById('resultName');
    var resultSubtitle = document.getElementById('resultSubtitle');
    var resultDescription = document.getElementById('resultDescription');
    var resultTraits = document.getElementById('resultTraits');
    var resultAdvice = document.getElementById('resultAdvice');
    var compatibilityText = document.getElementById('compatibilityText');
    var resultCard = document.getElementById('resultCard');
    var shareXBtn = document.getElementById('shareXBtn');
    var shareLINEBtn = document.getElementById('shareLINEBtn');
    var copyBtn = document.getElementById('copyBtn');
    var retryBtn = document.getElementById('retryBtn');
    var toast = document.getElementById('toast');
    var historySection = document.getElementById('historySection');
    var historyList = document.getElementById('historyList');

    // 状態
    var currentQuestion = 0;
    var answers = [];

    // スタートボタン
    startBtn.addEventListener('click', function() {
        startSection.style.display = 'none';
        questionSection.style.display = 'block';
        showQuestion(0);
    });

    // 質問表示
    function showQuestion(index) {
        var q = QUESTIONS[index];
        currentQuestion = index;

        progressFill.style.width = ((index) / QUESTIONS.length * 100) + '%';
        progressText.textContent = (index + 1) + ' / ' + QUESTIONS.length;

        questionText.textContent = 'Q' + (index + 1) + '. ' + q.q;

        // 選択肢を動的に生成
        choicesContainer.innerHTML = '';
        q.choices.forEach(function(choice, i) {
            var btn = document.createElement('button');
            btn.className = 'choice-btn';
            btn.textContent = choice;
            btn.addEventListener('click', function() { handleChoice(i); });
            choicesContainer.appendChild(btn);
        });

        // アニメーションリセット
        var card = document.getElementById('questionCard');
        card.style.animation = 'none';
        card.offsetHeight;
        card.style.animation = 'fadeInUp 0.4s ease';
    }

    // 選択処理
    function handleChoice(choiceIndex) {
        answers.push(choiceIndex);

        if (currentQuestion + 1 < QUESTIONS.length) {
            showQuestion(currentQuestion + 1);
        } else {
            progressFill.style.width = '100%';
            showAnalyzing();
        }
    }

    // 分析演出
    function showAnalyzing() {
        questionSection.style.display = 'none';
        analyzingSection.style.display = 'block';

        var typeId = determineLoveType(answers);

        var statuses = [
            '回答パターンを解析しています',
            '恋愛傾向をマッピング中...',
            '12タイプの恋愛スタイルと照合しています',
            '個別分析レポートを作成中...',
            'あなたの恋愛タイプが判明しました！'
        ];

        // AI呼び出しを並行実行
        var aiPromise = analyzeWithAI(typeId);

        var i = 0;
        var interval = setInterval(function() {
            i++;
            if (i < statuses.length) {
                analyzingStatus.textContent = statuses[i];
            }
            if (i >= statuses.length) {
                clearInterval(interval);
                aiPromise.then(function(aiData) {
                    setTimeout(function() { showResult(typeId, aiData); }, 500);
                }).catch(function() {
                    setTimeout(function() { showResult(typeId, null); }, 500);
                });
            }
        }, 600);
    }

    // AI分析
    function analyzeWithAI(typeId) {
        return new Promise(function(resolve, reject) {
            try {
                var controller = new AbortController();
                var timeoutId = setTimeout(function() { controller.abort(); }, 15000);

                fetch(API_URL + '/api/generate', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        app: 'love-type',
                        params: { answers: answers, typeId: typeId }
                    }),
                    signal: controller.signal
                }).then(function(response) {
                    clearTimeout(timeoutId);
                    if (!response.ok) throw new Error('API error: ' + response.status);
                    return response.json();
                }).then(function(json) {
                    if (!json.success || !json.data) throw new Error('Invalid response');
                    resolve(json.data);
                }).catch(function(e) {
                    console.log('AI analysis failed, using static fallback:', e.message);
                    resolve(null);
                });
            } catch (e) {
                console.log('AI analysis failed, using static fallback:', e.message);
                resolve(null);
            }
        });
    }

    // 結果表示
    function showResult(typeId, aiData) {
        analyzingSection.style.display = 'none';
        resultSection.style.display = 'block';

        var typeData = LOVE_TYPES[typeId];

        var description, traits, compatibility, advice;

        if (aiData) {
            description = aiData.description || typeData.description;
            traits = aiData.traits || typeData.traits;
            compatibility = aiData.compatibility || typeData.compatibility;
            advice = aiData.advice || typeData.advice;
        } else {
            description = typeData.description;
            traits = typeData.traits;
            compatibility = typeData.compatibility;
            advice = typeData.advice;
        }

        // DOM更新
        resultEmoji.textContent = typeData.emoji;
        resultName.textContent = typeData.name;
        resultSubtitle.textContent = typeData.subtitle;
        resultDescription.textContent = description;

        resultTraits.innerHTML = '';
        traits.forEach(function(t) {
            var li = document.createElement('li');
            li.textContent = t;
            resultTraits.appendChild(li);
        });

        resultAdvice.textContent = advice;
        compatibilityText.textContent = compatibility;

        resultCard.style.borderColor = 'rgba(225, 29, 72, 0.3)';

        resultSection.scrollIntoView({ behavior: 'smooth' });

        // シェア用データを保存
        resultSection.dataset.typeId = typeId;
        resultSection.dataset.emoji = typeData.emoji;
        resultSection.dataset.name = typeData.name;
        resultSection.dataset.subtitle = typeData.subtitle;

        // 履歴保存
        saveHistory(typeId, typeData);

        // 履歴表示
        renderHistory();
    }

    // シェアテキスト生成
    function getShareText() {
        var emoji = resultSection.dataset.emoji;
        var name = resultSection.dataset.name;
        var subtitle = resultSection.dataset.subtitle;
        return '\u3010AI\u604B\u611B\u30BF\u30A4\u30D7\u8A3A\u65AD\u3011\n\u79C1\u306F\u300C' + emoji + name + '\u300D\u3067\u3057\u305F\uFF01\n' + subtitle + '\n\n' + SHARE_URL + '\n\n#AI\u604B\u611B\u8A3A\u65AD #AI\u304A\u3082\u3057\u308D\u30C4\u30FC\u30EB';
    }

    // X（Twitter）でシェア
    shareXBtn.addEventListener('click', function() {
        var text = getShareText();
        window.open('https://twitter.com/intent/tweet?text=' + encodeURIComponent(text), '_blank');
    });

    // LINEで送る
    shareLINEBtn.addEventListener('click', function() {
        var text = getShareText();
        window.open('https://social-plugins.line.me/lineit/share?url=' + encodeURIComponent(SHARE_URL) + '&text=' + encodeURIComponent(text), '_blank');
    });

    // コピー
    copyBtn.addEventListener('click', function() {
        var text = getShareText();
        navigator.clipboard.writeText(text).then(function() {
            showToast('\u30B3\u30D4\u30FC\u3057\u307E\u3057\u305F\uFF01');
        });
    });

    // リトライ
    retryBtn.addEventListener('click', function() {
        currentQuestion = 0;
        answers = [];
        resultSection.style.display = 'none';
        startSection.style.display = 'block';
        window.scrollTo({ top: 0, behavior: 'smooth' });
    });

    // 履歴保存
    function saveHistory(typeId, typeData) {
        var history = JSON.parse(localStorage.getItem(HISTORY_KEY) || '[]');
        history.unshift({
            typeId: typeId,
            emoji: typeData.emoji,
            name: typeData.name,
            subtitle: typeData.subtitle,
            date: new Date().toISOString()
        });
        if (history.length > 10) history = history.slice(0, 10);
        localStorage.setItem(HISTORY_KEY, JSON.stringify(history));
    }

    // 履歴表示
    function renderHistory() {
        var history = JSON.parse(localStorage.getItem(HISTORY_KEY) || '[]');
        if (history.length === 0) {
            historySection.style.display = 'none';
            return;
        }

        historySection.style.display = 'block';
        historyList.innerHTML = '';

        history.forEach(function(item) {
            var div = document.createElement('div');
            div.className = 'history-item';

            var d = new Date(item.date);
            var dateStr = d.getFullYear() + '/' + (d.getMonth() + 1) + '/' + d.getDate() + ' ' + d.getHours() + ':' + String(d.getMinutes()).padStart(2, '0');

            div.innerHTML = '<span class="history-emoji">' + item.emoji + '</span>'
                + '<div class="history-info">'
                + '<p class="history-name">' + item.name + ' - ' + item.subtitle + '</p>'
                + '<p class="history-date">' + dateStr + '</p>'
                + '</div>';

            historyList.appendChild(div);
        });
    }

    // トースト
    function showToast(message) {
        toast.textContent = message;
        toast.classList.add('show');
        setTimeout(function() { toast.classList.remove('show'); }, 2000);
    }
});
