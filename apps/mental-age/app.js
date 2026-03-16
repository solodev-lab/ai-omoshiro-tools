var API_URL = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
    ? 'http://localhost:8787'
    : 'https://ai-omoshiro-api.kojifo369.workers.dev';

var SHARE_URL = 'https://solodev-lab.github.io/ai-omoshiro-tools/apps/mental-age/';

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
    var ageNumber = document.getElementById('ageNumber');
    var ageEmoji = document.getElementById('ageEmoji');
    var ageTypeLabel = document.getElementById('ageTypeLabel');
    var resultLabel = document.getElementById('resultLabel');
    var resultDescription = document.getElementById('resultDescription');
    var resultTraits = document.getElementById('resultTraits');
    var resultAdvice = document.getElementById('resultAdvice');
    var resultCard = document.getElementById('resultCard');
    var shareXBtn = document.getElementById('shareXBtn');
    var shareLINEBtn = document.getElementById('shareLINEBtn');
    var copyBtn = document.getElementById('copyBtn');
    var retryBtn = document.getElementById('retryBtn');
    var historySection = document.getElementById('historySection');
    var historyList = document.getElementById('historyList');
    var toast = document.getElementById('toast');

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

        questionText.textContent = q.q;

        // 選択肢を生成
        choicesContainer.innerHTML = '';
        for (var i = 0; i < q.choices.length; i++) {
            (function(choiceIndex) {
                var btn = document.createElement('button');
                btn.className = 'choice-btn';
                btn.textContent = q.choices[choiceIndex];
                btn.addEventListener('click', function() {
                    handleChoice(choiceIndex);
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

        var mentalAge = calculateMentalAge(answers);
        var desc = getAgeDescription(mentalAge);

        var statuses = [
            '回答パターンを解析しています',
            'メンタル成熟度を計測中...',
            '心理パターンを分析しています',
            '精神年齢を算出中...',
            'あなたのメンタル年齢が判明しました！'
        ];

        // AI呼び出し（並列）
        var aiPromise = analyzeWithAI(mentalAge, answers);

        var i = 0;
        var interval = setInterval(function() {
            i++;
            if (i < statuses.length) {
                analyzingStatus.textContent = statuses[i];
            }
            if (i >= statuses.length) {
                clearInterval(interval);
                aiPromise.then(function(aiData) {
                    setTimeout(function() { showResult(mentalAge, desc, aiData); }, 500);
                }).catch(function() {
                    setTimeout(function() { showResult(mentalAge, desc, null); }, 500);
                });
            }
        }, 600);
    }

    // AI分析
    function analyzeWithAI(mentalAge, answerList) {
        return new Promise(function(resolve, reject) {
            var controller = new AbortController();
            var timeoutId = setTimeout(function() { controller.abort(); }, 15000);

            fetch(API_URL + '/api/generate', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    app: 'mental-age',
                    params: {
                        answers: answerList,
                        mentalAge: mentalAge
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

    // 年齢カウントアップアニメーション
    function animateAge(target) {
        var duration = 2000;
        var startTime = performance.now();

        function update(currentTime) {
            var elapsed = currentTime - startTime;
            var progress = Math.min(elapsed / duration, 1);

            // easeOutExpo
            var eased = progress === 1 ? 1 : 1 - Math.pow(2, -10 * progress);
            var current = Math.round(eased * target);

            ageNumber.textContent = current;

            if (progress < 1) {
                requestAnimationFrame(update);
            }
        }

        requestAnimationFrame(update);
    }

    // 結果表示
    function showResult(mentalAge, desc, aiData) {
        analyzingSection.style.display = 'none';
        resultSection.style.display = 'block';

        var description, traits, advice;

        if (aiData) {
            description = aiData.description || desc.description;
            traits = aiData.traits || desc.traits;
            advice = aiData.advice || desc.advice;
        } else {
            description = desc.description;
            traits = desc.traits;
            advice = desc.advice;
        }

        // 年齢カウントアップアニメーション
        ageNumber.textContent = '0';
        animateAge(mentalAge);

        // バッジ表示
        ageEmoji.textContent = desc.emoji;
        ageTypeLabel.textContent = desc.label;

        // 説明文
        resultDescription.textContent = description;

        // 特徴リスト
        resultTraits.innerHTML = '';
        for (var i = 0; i < traits.length; i++) {
            var li = document.createElement('li');
            li.textContent = traits[i];
            resultTraits.appendChild(li);
        }

        // アドバイス
        resultAdvice.textContent = advice;

        // シェア用データ
        resultSection.dataset.mentalAge = mentalAge;
        resultSection.dataset.emoji = desc.emoji;
        resultSection.dataset.label = desc.label;

        resultSection.scrollIntoView({ behavior: 'smooth' });

        // 履歴保存
        saveHistory(mentalAge, desc);

        // 履歴表示
        renderHistory();
    }

    // シェアテキスト生成
    function getShareText() {
        var age = resultSection.dataset.mentalAge;
        var label = resultSection.dataset.label;
        return '【AIメンタル年齢診断】\n私の精神年齢は' + age + '歳でした！\n' + label + '\n\n#AIメンタル年齢 #AIおもしろツール';
    }

    // X（Twitter）でシェア
    shareXBtn.addEventListener('click', function() {
        var text = getShareText();
        window.open('https://twitter.com/intent/tweet?text=' + encodeURIComponent(text + '\n' + SHARE_URL), '_blank');
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
            showToast('コピーしました！');
        });
    });

    // リトライ
    retryBtn.addEventListener('click', function() {
        currentQuestion = 0;
        answers = [];
        ageNumber.textContent = '0';
        resultSection.style.display = 'none';
        startSection.style.display = 'block';
        window.scrollTo({ top: 0, behavior: 'smooth' });
    });

    // 履歴保存
    function saveHistory(mentalAge, desc) {
        try {
            var history = JSON.parse(localStorage.getItem('mentalAgeHistory') || '[]');
            history.unshift({
                date: new Date().toISOString(),
                mentalAge: mentalAge,
                emoji: desc.emoji,
                label: desc.label
            });
            // 最大10件
            if (history.length > 10) {
                history = history.slice(0, 10);
            }
            localStorage.setItem('mentalAgeHistory', JSON.stringify(history));
        } catch (e) {
            console.log('Failed to save history:', e.message);
        }
    }

    // 履歴表示
    function renderHistory() {
        try {
            var history = JSON.parse(localStorage.getItem('mentalAgeHistory') || '[]');
            if (history.length <= 1) {
                historySection.style.display = 'none';
                return;
            }

            historySection.style.display = 'block';
            historyList.innerHTML = '';

            for (var i = 0; i < history.length; i++) {
                var item = history[i];
                var div = document.createElement('div');
                div.className = 'history-item';

                var d = new Date(item.date);
                var dateStr = d.getFullYear() + '/' + (d.getMonth() + 1) + '/' + d.getDate() + ' ' + d.getHours() + ':' + String(d.getMinutes()).padStart(2, '0');

                div.innerHTML =
                    '<div class="history-info">' +
                        '<span class="history-date">' + dateStr + '</span>' +
                        '<span class="history-age">' + item.mentalAge + '歳</span>' +
                    '</div>' +
                    '<span class="history-label">' + item.emoji + ' ' + item.label + '</span>';

                historyList.appendChild(div);
            }
        } catch (e) {
            historySection.style.display = 'none';
        }
    }

    // トースト
    function showToast(message) {
        toast.textContent = message;
        toast.classList.add('show');
        setTimeout(function() { toast.classList.remove('show'); }, 2000);
    }
});
