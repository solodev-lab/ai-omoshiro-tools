const API_URL = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
    ? 'http://localhost:8787'
    : 'https://ai-omoshiro-api.kojifo369.workers.dev';

const SHARE_URL = 'https://solodev-lab.github.io/ai-omoshiro-tools/apps/animal-type/';
const HISTORY_KEY = 'animalTypeHistory';

document.addEventListener('DOMContentLoaded', () => {
    // DOM要素
    const startSection = document.getElementById('startSection');
    const questionSection = document.getElementById('questionSection');
    const analyzingSection = document.getElementById('analyzingSection');
    const resultSection = document.getElementById('resultSection');
    const startBtn = document.getElementById('startBtn');
    const progressFill = document.getElementById('progressFill');
    const progressText = document.getElementById('progressText');
    const questionText = document.getElementById('questionText');
    const choicesContainer = document.getElementById('choicesContainer');
    const analyzingStatus = document.getElementById('analyzingStatus');
    const resultEmoji = document.getElementById('resultEmoji');
    const resultName = document.getElementById('resultName');
    const resultSubtitle = document.getElementById('resultSubtitle');
    const resultDescription = document.getElementById('resultDescription');
    const resultTraits = document.getElementById('resultTraits');
    const resultAdvice = document.getElementById('resultAdvice');
    const compatibilityText = document.getElementById('compatibilityText');
    const resultCard = document.getElementById('resultCard');
    const shareXBtn = document.getElementById('shareXBtn');
    const shareLINEBtn = document.getElementById('shareLINEBtn');
    const copyBtn = document.getElementById('copyBtn');
    const retryBtn = document.getElementById('retryBtn');
    const toast = document.getElementById('toast');
    const historySection = document.getElementById('historySection');
    const historyList = document.getElementById('historyList');

    // 状態
    let currentQuestion = 0;
    let answers = [];

    // スタートボタン
    startBtn.addEventListener('click', () => {
        startSection.style.display = 'none';
        questionSection.style.display = 'block';
        showQuestion(0);
    });

    // 質問表示
    function showQuestion(index) {
        const q = QUESTIONS[index];
        currentQuestion = index;

        progressFill.style.width = ((index) / QUESTIONS.length * 100) + '%';
        progressText.textContent = (index + 1) + ' / ' + QUESTIONS.length;

        questionText.textContent = 'Q' + (index + 1) + '. ' + q.q;

        // 選択肢を動的に生成（4択）
        choicesContainer.innerHTML = '';
        q.choices.forEach((choice, i) => {
            const btn = document.createElement('button');
            btn.className = 'choice-btn';
            btn.textContent = choice;
            btn.addEventListener('click', () => handleChoice(i));
            choicesContainer.appendChild(btn);
        });

        // アニメーションリセット
        const card = document.getElementById('questionCard');
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

    // 動物タイプ判定ロジック
    function determineAnimal() {
        // スコアリング: 各質問の回答インデックスを軸ごとに集計
        // 軸1: 社交性 (0=内向, 高=外向)
        // 軸2: リーダーシップ (0=フォロワー, 高=リーダー)
        // 軸3: 感性 (0=論理, 高=感性)

        let social = 0;    // 社交性スコア
        let leader = 0;    // リーダーシップスコア
        let sensory = 0;   // 感性スコア
        let energy = 0;    // エネルギースコア

        // Q1: 休日の過ごし方 (0:内向, 1:外向, 2:外向活発, 3:内向集中)
        if (answers[0] === 1 || answers[0] === 2) social += 2;
        if (answers[0] === 2) energy += 2;
        if (answers[0] === 3) sensory += 1;

        // Q2: グループでの役割 (0:リーダー, 1:ムードメーカー, 2:参謀, 3:マイペース)
        if (answers[1] === 0) leader += 3;
        if (answers[1] === 1) { social += 2; energy += 1; }
        if (answers[1] === 2) { leader += 1; sensory += 1; }
        if (answers[1] === 3) sensory += 2;

        // Q3: 好きな食べ物 (0:肉, 1:魚, 2:野菜, 3:スイーツ)
        if (answers[2] === 0) energy += 2;
        if (answers[2] === 1) sensory += 1;
        if (answers[2] === 2) { sensory += 1; leader += 1; }
        if (answers[2] === 3) social += 1;

        // Q4: 朝型夜型 (0:超朝型, 1:やや朝型, 2:やや夜型, 3:超夜型)
        if (answers[3] === 0) { energy += 2; leader += 1; }
        if (answers[3] === 1) energy += 1;
        if (answers[3] === 2) sensory += 1;
        if (answers[3] === 3) sensory += 2;

        // Q5: ストレス発散 (0:寝る, 1:話す, 2:運動, 3:没頭)
        if (answers[4] === 0) sensory += 1;
        if (answers[4] === 1) social += 2;
        if (answers[4] === 2) energy += 2;
        if (answers[4] === 3) sensory += 1;

        // Q6: 恋愛 (0:一途, 1:笑い, 2:信頼, 3:ドキドキ)
        if (answers[5] === 0) leader += 1;
        if (answers[5] === 1) social += 2;
        if (answers[5] === 2) { leader += 1; sensory += 1; }
        if (answers[5] === 3) energy += 2;

        // Q7: 人生で大切なもの (0:家族, 1:友情, 2:成功, 3:自由)
        if (answers[6] === 0) { social += 1; leader += 1; }
        if (answers[6] === 1) social += 2;
        if (answers[6] === 2) { leader += 2; energy += 1; }
        if (answers[6] === 3) sensory += 2;

        // スコアに基づいて動物タイプを判定
        // 合計スコアレンジを12タイプにマッピング
        if (leader >= 4 && energy >= 3) return 'lion';
        if (leader >= 3 && social >= 3) return 'dolphin';
        if (social >= 4 && energy >= 2) return 'dog';
        if (social >= 3 && sensory >= 2) return 'butterfly';
        if (sensory >= 4 && social <= 2) return 'owl';
        if (sensory >= 3 && energy <= 1) return 'cat';
        if (energy >= 4 && leader >= 2) return 'hawk';
        if (energy >= 3 && sensory >= 2) return 'wolf';
        if (leader >= 2 && sensory >= 2) return 'fox';
        if (social <= 2 && sensory >= 2) return 'panda';
        if (social >= 2 && leader <= 1) return 'rabbit';
        return 'bear';
    }

    // 分析演出
    function showAnalyzing() {
        questionSection.style.display = 'none';
        analyzingSection.style.display = 'block';

        const animalId = determineAnimal();

        const statuses = [
            '回答パターンを解析しています',
            '性格特性をマッピング中...',
            '12タイプの動物と照合しています',
            '個別分析レポートを作成中...',
            'あなたの動物タイプが判明しました！'
        ];

        // Start AI call in parallel with animation
        const aiPromise = analyzeWithAI(animalId);

        let i = 0;
        const interval = setInterval(() => {
            i++;
            if (i < statuses.length) {
                analyzingStatus.textContent = statuses[i];
            }
            if (i >= statuses.length) {
                clearInterval(interval);
                aiPromise.then(aiData => {
                    setTimeout(() => showResult(animalId, aiData), 500);
                }).catch(() => {
                    setTimeout(() => showResult(animalId, null), 500);
                });
            }
        }, 600);
    }

    // AI分析
    async function analyzeWithAI(animalId) {
        try {
            const controller = new AbortController();
            const timeoutId = setTimeout(() => controller.abort(), 15000);

            const response = await fetch(API_URL + '/api/generate', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    app: 'animal-type',
                    params: { answers: answers, animalId: animalId }
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
    function showResult(animalId, aiData) {
        analyzingSection.style.display = 'none';
        resultSection.style.display = 'block';

        const typeData = ANIMAL_TYPES[animalId];

        let description, traits, compatibility, advice;

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
        traits.forEach(t => {
            const li = document.createElement('li');
            li.textContent = t;
            resultTraits.appendChild(li);
        });

        resultAdvice.textContent = advice;
        compatibilityText.textContent = compatibility;

        resultCard.style.borderColor = 'rgba(39, 174, 96, 0.3)';

        resultSection.scrollIntoView({ behavior: 'smooth' });

        // シェア・コピー用データを保存
        resultSection.dataset.animalId = animalId;
        resultSection.dataset.emoji = typeData.emoji;
        resultSection.dataset.name = typeData.name;
        resultSection.dataset.subtitle = typeData.subtitle;

        // 履歴保存
        saveHistory(animalId, typeData);

        // 履歴表示
        renderHistory();
    }

    // シェアテキスト生成
    function getShareText() {
        const emoji = resultSection.dataset.emoji;
        const name = resultSection.dataset.name;
        const subtitle = resultSection.dataset.subtitle;
        return '【AI動物タイプ診断】\n私は「' + emoji + name + '」でした！\n' + subtitle + '\n\n' + SHARE_URL + '\n\n#AI動物診断 #AIおもしろツール';
    }

    // X（Twitter）でシェア
    shareXBtn.addEventListener('click', () => {
        const text = getShareText();
        window.open('https://twitter.com/intent/tweet?text=' + encodeURIComponent(text), '_blank');
    });

    // LINEで送る
    shareLINEBtn.addEventListener('click', () => {
        const text = getShareText();
        window.open('https://social-plugins.line.me/lineit/share?url=' + encodeURIComponent(SHARE_URL) + '&text=' + encodeURIComponent(text), '_blank');
    });

    // コピー
    copyBtn.addEventListener('click', () => {
        const text = getShareText();
        navigator.clipboard.writeText(text).then(() => {
            showToast('コピーしました！');
        });
    });

    // リトライ
    retryBtn.addEventListener('click', () => {
        currentQuestion = 0;
        answers = [];
        resultSection.style.display = 'none';
        startSection.style.display = 'block';
        window.scrollTo({ top: 0, behavior: 'smooth' });
    });

    // 履歴保存
    function saveHistory(animalId, typeData) {
        let history = JSON.parse(localStorage.getItem(HISTORY_KEY) || '[]');
        history.unshift({
            animalId: animalId,
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
        const history = JSON.parse(localStorage.getItem(HISTORY_KEY) || '[]');
        if (history.length === 0) {
            historySection.style.display = 'none';
            return;
        }

        historySection.style.display = 'block';
        historyList.innerHTML = '';

        history.forEach(item => {
            const div = document.createElement('div');
            div.className = 'history-item';

            const d = new Date(item.date);
            const dateStr = d.getFullYear() + '/' + (d.getMonth() + 1) + '/' + d.getDate() + ' ' + d.getHours() + ':' + String(d.getMinutes()).padStart(2, '0');

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
        setTimeout(() => toast.classList.remove('show'), 2000);
    }
});
