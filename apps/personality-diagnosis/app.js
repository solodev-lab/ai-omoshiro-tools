const API_URL = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
    ? 'http://localhost:8787'
    : 'https://ai-omoshiro-api.kojifo369.workers.dev';

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
    const choiceA = document.getElementById('choiceA');
    const choiceB = document.getElementById('choiceB');
    const choiceAEmoji = document.getElementById('choiceAEmoji');
    const choiceALabel = document.getElementById('choiceALabel');
    const choiceBEmoji = document.getElementById('choiceBEmoji');
    const choiceBLabel = document.getElementById('choiceBLabel');
    const analyzingStatus = document.getElementById('analyzingStatus');
    const resultEmoji = document.getElementById('resultEmoji');
    const resultCode = document.getElementById('resultCode');
    const resultCatchphrase = document.getElementById('resultCatchphrase');
    const resultDescription = document.getElementById('resultDescription');
    const resultStrengths = document.getElementById('resultStrengths');
    const resultWeaknesses = document.getElementById('resultWeaknesses');
    const compatibilityText = document.getElementById('compatibilityText');
    const resultCard = document.getElementById('resultCard');
    const shareXBtn = document.getElementById('shareXBtn');
    const shareLINEBtn = document.getElementById('shareLINEBtn');
    const copyBtn = document.getElementById('copyBtn');
    const retryBtn = document.getElementById('retryBtn');
    const toast = document.getElementById('toast');

    // 状態
    let currentQuestion = 0;
    let scores = { E: 0, I: 0, S: 0, N: 0, T: 0, F: 0, J: 0, P: 0 };

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

        questionText.textContent = q.text;
        choiceAEmoji.textContent = q.choiceA.emoji;
        choiceALabel.textContent = q.choiceA.label;
        choiceBEmoji.textContent = q.choiceB.emoji;
        choiceBLabel.textContent = q.choiceB.label;

        // アニメーションリセット
        const card = document.getElementById('questionCard');
        card.style.animation = 'none';
        card.offsetHeight;
        card.style.animation = 'fadeInUp 0.4s ease';
    }

    // 選択処理
    function handleChoice(choice) {
        const q = QUESTIONS[currentQuestion];
        const axis = q.axis;

        if (choice === 'A') {
            scores[axis[0]] += 1;
        } else {
            scores[axis[1]] += 1;
        }

        if (currentQuestion + 1 < QUESTIONS.length) {
            showQuestion(currentQuestion + 1);
        } else {
            progressFill.style.width = '100%';
            showAnalyzing();
        }
    }

    choiceA.addEventListener('click', () => handleChoice('A'));
    choiceB.addEventListener('click', () => handleChoice('B'));

    // 分析演出
    function showAnalyzing() {
        questionSection.style.display = 'none';
        analyzingSection.style.display = 'block';

        const type = getType();

        const statuses = [
            '回答パターンを解析しています',
            '性格特性をマッピング中...',
            '16タイプと照合しています',
            '個別分析レポートを作成中...',
            'あなたのタイプが判明しました！'
        ];

        // Start AI call in parallel with animation
        const aiPromise = analyzeWithAI(type);

        let i = 0;
        const interval = setInterval(() => {
            i++;
            if (i < statuses.length) {
                analyzingStatus.textContent = statuses[i];
            }
            if (i >= statuses.length) {
                clearInterval(interval);
                // Wait for AI result (or fallback) before showing result
                aiPromise.then(aiData => {
                    setTimeout(() => showResult(type, aiData), 500);
                }).catch(() => {
                    setTimeout(() => showResult(type, null), 500);
                });
            }
        }, 600);
    }

    // AI分析
    async function analyzeWithAI(type) {
        try {
            const controller = new AbortController();
            const timeoutId = setTimeout(() => controller.abort(), 15000);

            const response = await fetch(API_URL + '/api/generate', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    app: 'personality-diagnosis',
                    params: { type, scores }
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
    function showResult(type, aiData) {
        analyzingSection.style.display = 'none';
        resultSection.style.display = 'block';

        // タイプ判定（typeは引数から受け取る、typeDataは常に必要）
        const typeData = TYPES[type];

        let catchphrase, description, strengths, weaknesses, compatibility, compatibilityName;

        if (aiData) {
            // AI結果を使用
            catchphrase = aiData.catchphrase;
            description = aiData.description;
            strengths = aiData.strengths;
            weaknesses = aiData.weaknesses;
            compatibility = aiData.compatibility;
            compatibilityName = aiData.compatibilityName;
        } else {
            // 静的データにフォールバック
            catchphrase = typeData.catchphrases[Math.floor(Math.random() * typeData.catchphrases.length)];
            description = typeData.description;
            strengths = typeData.strengths;
            weaknesses = typeData.weaknesses;
            compatibility = typeData.compatibility;
            compatibilityName = typeData.compatibilityName;
        }

        // DOM更新（emoji, name, colorは常にtypeDataから）
        resultEmoji.textContent = typeData.emoji;
        resultCode.textContent = typeData.name;
        resultCatchphrase.textContent = catchphrase;
        resultCatchphrase.style.color = typeData.color;
        resultDescription.textContent = description;

        resultStrengths.innerHTML = '';
        strengths.forEach(s => {
            const li = document.createElement('li');
            li.textContent = s;
            resultStrengths.appendChild(li);
        });

        resultWeaknesses.innerHTML = '';
        weaknesses.forEach(w => {
            const li = document.createElement('li');
            li.textContent = w;
            resultWeaknesses.appendChild(li);
        });

        compatibilityText.textContent = compatibility + '（' + compatibilityName + '）';

        // 結果カードのボーダー色
        resultCard.style.borderColor = typeData.color + '40';

        resultSection.scrollIntoView({ behavior: 'smooth' });

        // シェア・コピー用データを保存
        resultSection.dataset.type = type;
        resultSection.dataset.catchphrase = catchphrase;
    }

    // タイプ判定
    function getType() {
        let type = '';
        type += scores.E >= scores.I ? 'E' : 'I';
        type += scores.S >= scores.N ? 'S' : 'N';
        type += scores.T >= scores.F ? 'T' : 'F';
        type += scores.J >= scores.P ? 'J' : 'P';
        return type;
    }

    // シェアテキスト生成
    function getShareText() {
        const type = resultSection.dataset.type;
        const catchphrase = resultSection.dataset.catchphrase;
        return 'AI性格診断の結果、私は【' + catchphrase + '】（' + type + '）タイプでした！\n\nあなたも診断してみて👇\nhttps://solodev-lab.github.io/ai-omoshiro-tools/apps/personality-diagnosis/\n\n#AI性格診断 #性格タイプ #MBTI';
    }

    // X（Twitter）でシェア
    shareXBtn.addEventListener('click', () => {
        const text = getShareText();
        window.open('https://twitter.com/intent/tweet?text=' + encodeURIComponent(text), '_blank');
    });

    // LINEで送る
    shareLINEBtn.addEventListener('click', () => {
        const text = getShareText();
        window.open('https://social-plugins.line.me/lineit/share?url=' + encodeURIComponent('https://solodev-lab.github.io/ai-omoshiro-tools/apps/personality-diagnosis/') + '&text=' + encodeURIComponent(text), '_blank');
    });

    // コピー
    copyBtn.addEventListener('click', () => {
        const type = resultSection.dataset.type;
        const catchphrase = resultSection.dataset.catchphrase;
        const text = 'AI性格診断の結果、私は【' + catchphrase + '】（' + type + '）タイプでした！';
        navigator.clipboard.writeText(text).then(() => {
            showToast('コピーしました！');
        });
    });

    // リトライ
    retryBtn.addEventListener('click', () => {
        currentQuestion = 0;
        scores = { E: 0, I: 0, S: 0, N: 0, T: 0, F: 0, J: 0, P: 0 };
        resultSection.style.display = 'none';
        startSection.style.display = 'block';
        window.scrollTo({ top: 0, behavior: 'smooth' });
    });

    // トースト
    function showToast(message) {
        toast.textContent = message;
        toast.classList.add('show');
        setTimeout(() => toast.classList.remove('show'), 2000);
    }
});
