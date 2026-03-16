var API_URL = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
    ? 'http://localhost:8787'
    : 'https://ai-omoshiro-api.kojifo369.workers.dev';

var SHARE_URL = 'https://solodev-lab.github.io/ai-omoshiro-tools/apps/charm-level/';

document.addEventListener('DOMContentLoaded', function() {
    // DOM要素
    var startSection = document.getElementById('startSection');
    var questionSection = document.getElementById('questionSection');
    var analyzingSection = document.getElementById('analyzingSection');
    var resultSection = document.getElementById('resultSection');
    var startBtn = document.getElementById('startBtn');
    var progressFill = document.getElementById('progressFill');
    var progressText = document.getElementById('progressText');
    var questionCard = document.getElementById('questionCard');
    var questionText = document.getElementById('questionText');
    var choicesContainer = document.getElementById('choicesContainer');
    var analyzingStatus = document.getElementById('analyzingStatus');
    var resultCard = document.getElementById('resultCard');
    var scoreNumber = document.getElementById('scoreNumber');
    var rankBadge = document.getElementById('rankBadge');
    var rankGrade = document.getElementById('rankGrade');
    var rankLabel = document.getElementById('rankLabel');
    var resultDescription = document.getElementById('resultDescription');
    var charmPointsList = document.getElementById('charmPointsList');
    var adviceText = document.getElementById('adviceText');
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
        currentQuestion = 0;
        answers = [];
        showQuestion(0);
    });

    // 質問表示
    function showQuestion(index) {
        var q = QUESTIONS[index];
        currentQuestion = index;

        progressFill.style.width = (index / QUESTIONS.length * 100) + '%';
        progressText.textContent = (index + 1) + ' / ' + QUESTIONS.length;

        questionText.textContent = q.q;

        // 選択肢を動的生成
        choicesContainer.innerHTML = '';
        q.choices.forEach(function(choice, i) {
            var btn = document.createElement('button');
            btn.className = 'choice-btn';
            btn.textContent = choice;
            btn.addEventListener('click', function() { handleChoice(i); });
            choicesContainer.appendChild(btn);
        });

        // アニメーションリセット
        questionCard.style.animation = 'none';
        questionCard.offsetHeight;
        questionCard.style.animation = 'fadeInUp 0.4s ease';
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

    // スコア計算
    function calculateScore() {
        var totalWeight = 0;
        var maxScore = 0;
        for (var i = 0; i < QUESTIONS.length; i++) {
            totalWeight += QUESTIONS[i].weights[answers[i]];
            var maxW = 0;
            for (var j = 0; j < QUESTIONS[i].weights.length; j++) {
                if (QUESTIONS[i].weights[j] > maxW) {
                    maxW = QUESTIONS[i].weights[j];
                }
            }
            maxScore += maxW;
        }
        return Math.round((totalWeight / maxScore) * 100);
    }

    // 分析演出
    function showAnalyzing() {
        questionSection.style.display = 'none';
        analyzingSection.style.display = 'block';

        var score = calculateScore();
        var rankInfo = getRankByScore(score);

        var statuses = [
            '回答パターンを解析しています',
            'モテ要素を分析中...',
            'スコアを算出しています',
            'レポートを作成中...',
            'あなたのモテ度が判明しました！'
        ];

        // AI呼び出しをアニメーションと並行実行
        var aiPromise = analyzeWithAI(score, rankInfo);

        var i = 0;
        var interval = setInterval(function() {
            i++;
            if (i < statuses.length) {
                analyzingStatus.textContent = statuses[i];
            }
            if (i >= statuses.length) {
                clearInterval(interval);
                aiPromise.then(function(aiData) {
                    setTimeout(function() { showResult(score, rankInfo, aiData); }, 500);
                }).catch(function() {
                    setTimeout(function() { showResult(score, rankInfo, null); }, 500);
                });
            }
        }, 600);
    }

    // AI分析
    function analyzeWithAI(score, rankInfo) {
        var controller = new AbortController();
        var timeoutId = setTimeout(function() { controller.abort(); }, 15000);

        return fetch(API_URL + '/api/generate', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                app: 'charm-level',
                params: { answers: answers, score: score, rank: rankInfo.grade }
            }),
            signal: controller.signal
        }).then(function(response) {
            clearTimeout(timeoutId);
            if (!response.ok) throw new Error('API error: ' + response.status);
            return response.json();
        }).then(function(json) {
            if (!json.success || !json.data) throw new Error('Invalid response');
            return json.data;
        }).catch(function(e) {
            clearTimeout(timeoutId);
            console.log('AI analysis failed, using static fallback:', e.message);
            return null;
        });
    }

    // 結果表示
    function showResult(score, rankInfo, aiData) {
        analyzingSection.style.display = 'none';
        resultSection.style.display = 'block';

        // スコアアニメーション（0からscoreまで1.5秒でカウントアップ）
        var duration = 1500;
        var startTime = null;

        function easeOutCubic(t) {
            return 1 - Math.pow(1 - t, 3);
        }

        function animateScore(timestamp) {
            if (!startTime) startTime = timestamp;
            var elapsed = timestamp - startTime;
            var progress = Math.min(elapsed / duration, 1);
            var easedProgress = easeOutCubic(progress);
            var currentScore = Math.round(easedProgress * score);
            scoreNumber.textContent = currentScore;
            if (progress < 1) {
                requestAnimationFrame(animateScore);
            }
        }

        requestAnimationFrame(animateScore);

        // ランクバッジ
        rankGrade.textContent = rankInfo.grade;
        rankLabel.textContent = rankInfo.label;

        // 説明・モテポイント・アドバイス
        var description, charmPoints, advice;

        if (aiData) {
            description = aiData.description || rankInfo.description;
            charmPoints = aiData.charmPoints || rankInfo.charmPoints;
            advice = aiData.advice || rankInfo.advice;
        } else {
            description = rankInfo.description;
            charmPoints = rankInfo.charmPoints;
            advice = rankInfo.advice;
        }

        resultDescription.textContent = description;

        // モテポイントリスト
        charmPointsList.innerHTML = '';
        charmPoints.forEach(function(point) {
            var li = document.createElement('li');
            li.textContent = point;
            charmPointsList.appendChild(li);
        });

        // アドバイス
        adviceText.textContent = advice;

        resultSection.scrollIntoView({ behavior: 'smooth' });

        // シェア用データ保存
        resultSection.dataset.score = score;
        resultSection.dataset.grade = rankInfo.grade;
        resultSection.dataset.label = rankInfo.label;

        // 履歴に保存・表示
        saveToHistory(score, rankInfo);
        renderHistory();
    }

    // シェアテキスト生成
    function getShareText() {
        var score = resultSection.dataset.score;
        var grade = resultSection.dataset.grade;
        var label = resultSection.dataset.label;
        return '【AIモテ度診断】\n私のモテ度は ' + score + '点（' + grade + 'ランク: ' + label + '）でした！\n\n#AIモテ度診断 #AIおもしろツール\n' + SHARE_URL;
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
            showToast('コピーしました！');
        });
    });

    // リトライ
    retryBtn.addEventListener('click', function() {
        currentQuestion = 0;
        answers = [];
        resultSection.style.display = 'none';
        historySection.style.display = 'none';
        startSection.style.display = 'block';
        window.scrollTo({ top: 0, behavior: 'smooth' });
    });

    // 履歴保存
    function saveToHistory(score, rankInfo) {
        var history = JSON.parse(localStorage.getItem('charmLevelHistory') || '[]');
        history.unshift({
            score: score,
            grade: rankInfo.grade,
            label: rankInfo.label,
            color: rankInfo.color,
            date: new Date().toISOString()
        });
        if (history.length > 20) {
            history.length = 20;
        }
        localStorage.setItem('charmLevelHistory', JSON.stringify(history));
    }

    // 履歴表示
    function renderHistory() {
        var history = JSON.parse(localStorage.getItem('charmLevelHistory') || '[]');

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
            var dateStr = d.getFullYear() + '/' + (d.getMonth() + 1) + '/' + d.getDate();

            div.innerHTML =
                '<span class="history-item-score" style="color:' + item.color + '">' + item.score + '点</span>' +
                '<div class="history-item-info">' +
                    '<div class="history-item-name">' + item.grade + ' - ' + item.label + '</div>' +
                    '<div class="history-item-date">' + dateStr + '</div>' +
                '</div>';

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
