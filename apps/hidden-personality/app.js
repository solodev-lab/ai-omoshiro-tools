var API_URL = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
    ? 'http://localhost:8787'
    : 'https://ai-omoshiro-api.kojifo369.workers.dev';

var SHARE_URL = 'https://solodev-lab.github.io/ai-omoshiro-tools/apps/hidden-personality/';

document.addEventListener('DOMContentLoaded', function() {
    // DOM elements
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
    var flipCard = document.getElementById('flipCard');
    var frontEmoji = document.getElementById('frontEmoji');
    var frontTitle = document.getElementById('frontTitle');
    var frontDesc = document.getElementById('frontDesc');
    var backEmoji = document.getElementById('backEmoji');
    var backTitle = document.getElementById('backTitle');
    var backDesc = document.getElementById('backDesc');
    var revealBtn = document.getElementById('revealBtn');
    var gapMeter = document.getElementById('gapMeter');
    var gapFill = document.getElementById('gapFill');
    var gapScore = document.getElementById('gapScore');
    var adviceBox = document.getElementById('adviceBox');
    var adviceText = document.getElementById('adviceText');
    var aiAnalysisBox = document.getElementById('aiAnalysisBox');
    var aiAnalysisText = document.getElementById('aiAnalysisText');
    var shareButtons = document.getElementById('shareButtons');
    var retryButtons = document.getElementById('retryButtons');
    var shareXBtn = document.getElementById('shareXBtn');
    var shareLINEBtn = document.getElementById('shareLINEBtn');
    var copyBtn = document.getElementById('copyBtn');
    var retryBtn = document.getElementById('retryBtn');
    var historyList = document.getElementById('historyList');
    var toast = document.getElementById('toast');

    // State
    var currentQuestion = 0;
    var answers = [];
    var currentResult = null;
    var aiResult = null;

    // Start button
    startBtn.addEventListener('click', function() {
        startSection.style.display = 'none';
        questionSection.style.display = 'block';
        currentQuestion = 0;
        answers = [];
        showQuestion(0);
    });

    // Show question
    function showQuestion(index) {
        currentQuestion = index;
        var q = QUESTIONS[index];

        progressFill.style.width = (index / QUESTIONS.length * 100) + '%';
        progressText.textContent = (index + 1) + ' / ' + QUESTIONS.length;
        questionNumber.textContent = 'Q' + (index + 1);
        questionText.textContent = q.q;

        // Generate choice buttons
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

        // Reset animation
        var card = document.getElementById('questionCard');
        card.style.animation = 'none';
        card.offsetHeight;
        card.style.animation = 'fadeInUp 0.4s ease';
    }

    // Handle choice
    function handleChoice(choiceIndex) {
        answers.push(choiceIndex);

        if (currentQuestion + 1 < QUESTIONS.length) {
            showQuestion(currentQuestion + 1);
        } else {
            progressFill.style.width = '100%';
            showAnalyzing();
        }
    }

    // Show analyzing section
    function showAnalyzing() {
        questionSection.style.display = 'none';
        analyzingSection.style.display = 'block';

        var typeData = determineType(answers);

        var statuses = [
            '\u8868\u306E\u9854\u30C7\u30FC\u30BF\u3092\u53CE\u96C6\u3057\u3066\u3044\u307E\u3059',
            '\u88CF\u306E\u611F\u60C5\u30D1\u30BF\u30FC\u30F3\u3092\u89E3\u6790\u4E2D...',
            '\u30AE\u30E3\u30C3\u30D7\u5EA6\u3092\u8A08\u7B97\u3057\u3066\u3044\u307E\u3059',
            '\u6DF1\u5C64\u5FC3\u7406\u3092\u30B9\u30AD\u30E3\u30F3\u4E2D...',
            '\u8A3A\u65AD\u7D50\u679C\u304C\u51FA\u307E\u3057\u305F\uFF01'
        ];

        // Start AI call in parallel
        var aiPromise = analyzeWithAI(typeData.id);

        var i = 0;
        var interval = setInterval(function() {
            i++;
            if (i < statuses.length) {
                analyzingStatus.textContent = statuses[i];
            }
            if (i >= statuses.length) {
                clearInterval(interval);
                aiPromise.then(function(data) {
                    aiResult = data;
                    setTimeout(function() {
                        showResult(typeData);
                    }, 500);
                }).catch(function() {
                    aiResult = null;
                    setTimeout(function() {
                        showResult(typeData);
                    }, 500);
                });
            }
        }, 600);
    }

    // AI analysis
    function analyzeWithAI(typeId) {
        return new Promise(function(resolve, reject) {
            var controller = new AbortController();
            var timeoutId = setTimeout(function() {
                controller.abort();
            }, 15000);

            fetch(API_URL + '/api/generate', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    app: 'hidden-personality',
                    params: {
                        answers: answers,
                        typeId: typeId
                    }
                }),
                signal: controller.signal
            }).then(function(response) {
                clearTimeout(timeoutId);
                if (!response.ok) {
                    throw new Error('API error: ' + response.status);
                }
                return response.json();
            }).then(function(json) {
                if (!json.success || !json.data) {
                    throw new Error('Invalid response');
                }
                resolve(json.data);
            }).catch(function(e) {
                clearTimeout(timeoutId);
                console.log('AI analysis failed, using static fallback:', e.message);
                resolve(null);
            });
        });
    }

    // Show result
    function showResult(typeData) {
        analyzingSection.style.display = 'none';
        resultSection.style.display = 'block';

        currentResult = typeData;

        // Front card
        frontEmoji.textContent = typeData.frontEmoji;
        frontTitle.textContent = typeData.frontTitle;
        frontDesc.textContent = typeData.frontDesc;

        // Back card
        backEmoji.textContent = typeData.backEmoji;
        backTitle.textContent = typeData.backTitle;
        backDesc.textContent = aiResult && aiResult.shadowDesc ? aiResult.shadowDesc : typeData.backDesc;

        // Reset flip card
        flipCard.classList.remove('flipped');
        revealBtn.classList.remove('hidden');
        revealBtn.style.display = 'block';

        // Hide post-reveal elements
        gapMeter.style.display = 'none';
        adviceBox.style.display = 'none';
        aiAnalysisBox.style.display = 'none';
        shareButtons.style.display = 'none';
        retryButtons.style.display = 'none';

        resultSection.scrollIntoView({ behavior: 'smooth' });

        // Save to history
        saveToHistory(typeData);

        // Render history
        renderHistory();
    }

    // Reveal button - flip card
    revealBtn.addEventListener('click', function() {
        flipCard.classList.add('flipped');
        revealBtn.classList.add('hidden');

        var percent = currentResult.gapPercent;

        // Show gap meter after flip
        setTimeout(function() {
            revealBtn.style.display = 'none';
            gapMeter.style.display = 'block';

            // Set bar color based on percentage
            var color;
            if (percent >= 90) {
                color = 'linear-gradient(90deg, #ef4444, #a855f7)';
            } else if (percent >= 80) {
                color = 'linear-gradient(90deg, #f59e0b, #a855f7)';
            } else if (percent >= 70) {
                color = 'linear-gradient(90deg, #3b82f6, #a855f7)';
            } else {
                color = 'linear-gradient(90deg, #22c55e, #a855f7)';
            }
            gapFill.style.background = color;

            // Animate bar fill
            setTimeout(function() {
                gapFill.style.width = percent + '%';
            }, 100);

            gapScore.textContent = percent + '%';
        }, 600);

        // Show advice
        setTimeout(function() {
            adviceBox.style.display = 'block';
            adviceText.textContent = aiResult && aiResult.advice ? aiResult.advice : currentResult.advice;
        }, 1200);

        // Show AI analysis if available
        setTimeout(function() {
            if (aiResult && aiResult.analysis) {
                aiAnalysisBox.style.display = 'block';
                aiAnalysisText.textContent = aiResult.analysis;
            }
        }, 1600);

        // Show share and retry buttons
        setTimeout(function() {
            shareButtons.style.display = 'grid';
            retryButtons.style.display = 'grid';
        }, 1800);
    });

    // Share text generator
    function getShareText() {
        var text = '\u3010AI\u88CF\u6027\u683C\u8A3A\u65AD\u3011' +
            '\u8868\u306E\u9854\u306F\u300C' + currentResult.frontTitle + '\u300D\u3001' +
            '\u88CF\u306E\u9854\u306F\u300C' + currentResult.backTitle + '\u300D\u3067\u3057\u305F\uFF01' +
            '\u30AE\u30E3\u30C3\u30D7\u5EA6' + currentResult.gapPercent + '%' +
            '\n\n#AI\u88CF\u6027\u683C\u8A3A\u65AD #AI\u304A\u3082\u3057\u308D\u30C4\u30FC\u30EB';
        return text;
    }

    // Share on X
    shareXBtn.addEventListener('click', function() {
        var text = getShareText() + '\n' + SHARE_URL;
        window.open('https://twitter.com/intent/tweet?text=' + encodeURIComponent(text), '_blank');
    });

    // Share on LINE
    shareLINEBtn.addEventListener('click', function() {
        var text = getShareText();
        window.open('https://social-plugins.line.me/lineit/share?url=' + encodeURIComponent(SHARE_URL) + '&text=' + encodeURIComponent(text), '_blank');
    });

    // Copy
    copyBtn.addEventListener('click', function() {
        var text = getShareText() + '\n' + SHARE_URL;
        navigator.clipboard.writeText(text).then(function() {
            showToast('\u30B3\u30D4\u30FC\u3057\u307E\u3057\u305F\uFF01');
        });
    });

    // Retry
    retryBtn.addEventListener('click', function() {
        currentQuestion = 0;
        answers = [];
        currentResult = null;
        aiResult = null;
        flipCard.classList.remove('flipped');
        resultSection.style.display = 'none';
        historySection.style.display = 'none';
        startSection.style.display = 'block';
        window.scrollTo({ top: 0, behavior: 'smooth' });
    });

    // Toast notification
    function showToast(message) {
        toast.textContent = message;
        toast.classList.add('show');
        setTimeout(function() {
            toast.classList.remove('show');
        }, 2000);
    }

    // Save to history
    function saveToHistory(typeData) {
        var history = JSON.parse(localStorage.getItem('hiddenPersonalityHistory') || '[]');
        history.unshift({
            typeId: typeData.id,
            frontTitle: typeData.frontTitle,
            backTitle: typeData.backTitle,
            frontEmoji: typeData.frontEmoji,
            backEmoji: typeData.backEmoji,
            gapPercent: typeData.gapPercent,
            date: new Date().toISOString()
        });
        // Keep max 10
        if (history.length > 10) {
            history = history.slice(0, 10);
        }
        localStorage.setItem('hiddenPersonalityHistory', JSON.stringify(history));
    }

    // Render history
    function renderHistory() {
        var history = JSON.parse(localStorage.getItem('hiddenPersonalityHistory') || '[]');
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
            emojiSpan.textContent = item.frontEmoji + '\u2192' + item.backEmoji;

            var infoDiv = document.createElement('div');
            infoDiv.className = 'history-info';

            var typeSpan = document.createElement('div');
            typeSpan.className = 'history-type';
            typeSpan.textContent = item.frontTitle + ' \u2192 ' + item.backTitle;

            var shadowSpan = document.createElement('div');
            shadowSpan.className = 'history-shadow';
            shadowSpan.textContent = '\u30AE\u30E3\u30C3\u30D7\u5EA6: ' + item.gapPercent + '%';

            infoDiv.appendChild(typeSpan);
            infoDiv.appendChild(shadowSpan);

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

    // Show history on initial load if exists
    renderHistory();
});
