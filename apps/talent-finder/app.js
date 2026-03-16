var API_URL = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
    ? 'http://localhost:8787'
    : 'https://ai-omoshiro-api.kojifo369.workers.dev';

var SHARE_URL = 'https://solodev-lab.github.io/ai-omoshiro-tools/apps/talent-finder/';

document.addEventListener('DOMContentLoaded', function() {
    // DOM要素
    var startSection = document.getElementById('startSection');
    var questionSection = document.getElementById('questionSection');
    var analyzingSection = document.getElementById('analyzingSection');
    var resultSection = document.getElementById('resultSection');
    var historySection = document.getElementById('historySection');
    var startBtn = document.getElementById('startBtn');
    var progressFill = document.getElementById('progressFill');
    var progressText = document.getElementById('progressText');
    var questionNumber = document.getElementById('questionNumber');
    var questionText = document.getElementById('questionText');
    var choicesContainer = document.getElementById('choicesContainer');
    var analyzingStatus = document.getElementById('analyzingStatus');
    var resultEmoji = document.getElementById('resultEmoji');
    var resultName = document.getElementById('resultName');
    var resultSubtitle = document.getElementById('resultSubtitle');
    var resultDescription = document.getElementById('resultDescription');
    var resultTraits = document.getElementById('resultTraits');
    var resultAdvice = document.getElementById('resultAdvice');
    var resultCompatibility = document.getElementById('resultCompatibility');
    var aiAnalysisBox = document.getElementById('aiAnalysisBox');
    var aiAnalysisText = document.getElementById('aiAnalysisText');
    var shareXBtn = document.getElementById('shareXBtn');
    var shareLINEBtn = document.getElementById('shareLINEBtn');
    var copyBtn = document.getElementById('copyBtn');
    var retryBtn = document.getElementById('retryBtn');
    var toast = document.getElementById('toast');
    var historyList = document.getElementById('historyList');

    // 状態
    var currentQuestion = 0;
    var answers = [];
    var currentResult = null;

    // スタートボタン
    startBtn.addEventListener('click', function() {
        startSection.style.display = 'none';
        questionSection.style.display = 'block';
        currentQuestion = 0;
        answers = [];
        showQuestion(0);
    });

    // 質問表示
    function showQuestion(index) {
        currentQuestion = index;
        var q = QUESTIONS[index];

        progressFill.style.width = (index / QUESTIONS.length * 100) + '%';
        progressText.textContent = (index + 1) + ' / ' + QUESTIONS.length;
        questionNumber.textContent = 'Q' + (index + 1);
        questionText.textContent = q.q;

        choicesContainer.innerHTML = '';
        for (var i = 0; i < q.choices.length; i++) {
            (function(choiceIndex) {
                var btn = document.createElement('button');
                btn.className = 'choice-btn';
                btn.textContent = q.choices[choiceIndex];
                btn.addEventListener('click', function() {
                    handleChoice(index, choiceIndex);
                });
                choicesContainer.appendChild(btn);
            })(i);
        }

        // アニメーションリセット
        var card = document.getElementById('questionCard');
        card.style.animation = 'none';
        card.offsetHeight;
        card.style.animation = 'fadeInUp 0.4s ease';
    }

    // 選択処理
    function handleChoice(qIndex, choiceIndex) {
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

        var talentId = determineTalent(answers);
        var talentData = TALENT_TYPES[talentId];

        var statuses = [
            '回答データを収集しています',
            '才能パターンを解析中...',
            '隠れた才能をスキャン中...',
            '相性を計算しています',
            '診断結果が出ました！'
        ];

        // AI呼び出しを並行で開始
        var aiPromise = analyzeWithAI(talentId, talentData);

        var i = 0;
        var interval = setInterval(function() {
            i++;
            if (i < statuses.length) {
                analyzingStatus.textContent = statuses[i];
            }
            if (i >= statuses.length) {
                clearInterval(interval);
                aiPromise.then(function(aiData) {
                    setTimeout(function() { showResult(talentId, talentData, aiData); }, 500);
                }).catch(function() {
                    setTimeout(function() { showResult(talentId, talentData, null); }, 500);
                });
            }
        }, 600);
    }

    // AI分析
    function analyzeWithAI(talentId, talentData) {
        return new Promise(function(resolve, reject) {
            var controller = new AbortController();
            var timeoutId = setTimeout(function() { controller.abort(); }, 15000);

            fetch(API_URL + '/api/generate', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    app: 'talent-finder',
                    params: {
                        answers: answers,
                        talentId: talentId
                    }
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
                clearTimeout(timeoutId);
                console.log('AI analysis failed, using static fallback:', e.message);
                resolve(null);
            });
        });
    }

    // 結果表示
    function showResult(talentId, talentData, aiData) {
        analyzingSection.style.display = 'none';
        resultSection.style.display = 'block';

        currentResult = {
            talentId: talentId,
            talentData: talentData,
            aiData: aiData
        };

        // 結果カードの内容を設定
        resultEmoji.textContent = talentData.emoji;
        resultName.textContent = talentData.name;
        resultSubtitle.textContent = talentData.subtitle;
        resultDescription.textContent = aiData && aiData.description ? aiData.description : talentData.description;

        // 特徴リスト
        resultTraits.innerHTML = '';
        var traits = aiData && aiData.traits ? aiData.traits : talentData.traits;
        for (var i = 0; i < traits.length; i++) {
            var li = document.createElement('li');
            li.textContent = traits[i];
            resultTraits.appendChild(li);
        }

        // アドバイス
        resultAdvice.textContent = aiData && aiData.advice ? aiData.advice : talentData.advice;

        // 相性
        resultCompatibility.textContent = aiData && aiData.compatibility ? aiData.compatibility : talentData.compatibility;

        // AI深層分析
        if (aiData && aiData.analysis) {
            aiAnalysisBox.style.display = 'block';
            aiAnalysisText.textContent = aiData.analysis;
        } else {
            aiAnalysisBox.style.display = 'none';
        }

        resultSection.scrollIntoView({ behavior: 'smooth' });

        // 履歴に保存
        saveToHistory(talentId, talentData);

        // 履歴表示
        renderHistory();
    }

    // シェアテキスト生成
    function getShareText() {
        var talentData = currentResult.talentData;
        return '\u3010AI\u624d\u80fd\u8a3a\u65ad\u3011\u79c1\u306e\u96a0\u308c\u305f\u624d\u80fd\u306f\u300c' + talentData.emoji + ' ' + talentData.name + '\u300d\u3067\u3057\u305f\uff01\n' + talentData.subtitle + '\n\n#AI\u624d\u80fd\u8a3a\u65ad #AI\u304a\u3082\u3057\u308d\u30c4\u30fc\u30eb';
    }

    // Xでシェア
    shareXBtn.addEventListener('click', function() {
        var text = getShareText() + '\n' + SHARE_URL;
        window.open('https://twitter.com/intent/tweet?text=' + encodeURIComponent(text), '_blank');
    });

    // LINEで送る
    shareLINEBtn.addEventListener('click', function() {
        var text = getShareText();
        window.open('https://social-plugins.line.me/lineit/share?url=' + encodeURIComponent(SHARE_URL) + '&text=' + encodeURIComponent(text), '_blank');
    });

    // コピー
    copyBtn.addEventListener('click', function() {
        var text = getShareText() + '\n' + SHARE_URL;
        navigator.clipboard.writeText(text).then(function() {
            showToast('\u30b3\u30d4\u30fc\u3057\u307e\u3057\u305f\uff01');
        });
    });

    // リトライ
    retryBtn.addEventListener('click', function() {
        currentQuestion = 0;
        answers = [];
        currentResult = null;
        resultSection.style.display = 'none';
        historySection.style.display = 'none';
        startSection.style.display = 'block';
        window.scrollTo({ top: 0, behavior: 'smooth' });
    });

    // トースト
    function showToast(message) {
        toast.textContent = message;
        toast.classList.add('show');
        setTimeout(function() { toast.classList.remove('show'); }, 2000);
    }

    // 履歴保存
    function saveToHistory(talentId, talentData) {
        var history = JSON.parse(localStorage.getItem('talentFinderHistory') || '[]');
        history.unshift({
            talentId: talentId,
            emoji: talentData.emoji,
            name: talentData.name,
            subtitle: talentData.subtitle,
            date: new Date().toISOString()
        });
        if (history.length > 10) {
            history = history.slice(0, 10);
        }
        localStorage.setItem('talentFinderHistory', JSON.stringify(history));
    }

    // 履歴描画
    function renderHistory() {
        var history = JSON.parse(localStorage.getItem('talentFinderHistory') || '[]');
        if (history.length === 0) {
            historySection.style.display = 'none';
            return;
        }

        historySection.style.display = 'block';
        historyList.innerHTML = '';

        for (var i = 0; i < history.length; i++) {
            var item = history[i];

            var div = document.createElement('div');
            div.className = 'history-item';

            var emojiSpan = document.createElement('span');
            emojiSpan.className = 'history-emoji';
            emojiSpan.textContent = item.emoji;

            var infoDiv = document.createElement('div');
            infoDiv.className = 'history-info';

            var nameDiv = document.createElement('div');
            nameDiv.className = 'history-name';
            nameDiv.textContent = item.name;

            var subtitleDiv = document.createElement('div');
            subtitleDiv.className = 'history-subtitle';
            subtitleDiv.textContent = item.subtitle;

            infoDiv.appendChild(nameDiv);
            infoDiv.appendChild(subtitleDiv);

            var dateSpan = document.createElement('span');
            dateSpan.className = 'history-date';
            var d = new Date(item.date);
            dateSpan.textContent = (d.getMonth() + 1) + '/' + d.getDate();

            div.appendChild(emojiSpan);
            div.appendChild(infoDiv);
            div.appendChild(dateSpan);
            historyList.appendChild(div);
        }
    }

    // 初期表示時に履歴があれば表示
    renderHistory();
});
