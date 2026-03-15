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

        const statuses = [
            '回答パターンを解析しています',
            '性格特性をマッピング中...',
            '16タイプと照合しています',
            'あなたのタイプが判明しました！'
        ];

        let i = 0;
        const interval = setInterval(() => {
            i++;
            if (i < statuses.length) {
                analyzingStatus.textContent = statuses[i];
            }
            if (i >= statuses.length) {
                clearInterval(interval);
                setTimeout(showResult, 500);
            }
        }, 600);
    }

    // 結果表示
    function showResult() {
        analyzingSection.style.display = 'none';
        resultSection.style.display = 'block';

        // タイプ判定
        const type = getType();
        const typeData = TYPES[type];

        // ランダムキャッチコピー
        const catchphrase = typeData.catchphrases[Math.floor(Math.random() * typeData.catchphrases.length)];

        // DOM更新
        resultEmoji.textContent = typeData.emoji;
        resultCode.textContent = typeData.name;
        resultCatchphrase.textContent = catchphrase;
        resultCatchphrase.style.color = typeData.color;
        resultDescription.textContent = typeData.description;

        resultStrengths.innerHTML = '';
        typeData.strengths.forEach(s => {
            const li = document.createElement('li');
            li.textContent = s;
            resultStrengths.appendChild(li);
        });

        resultWeaknesses.innerHTML = '';
        typeData.weaknesses.forEach(w => {
            const li = document.createElement('li');
            li.textContent = w;
            resultWeaknesses.appendChild(li);
        });

        compatibilityText.textContent = typeData.compatibility + '（' + typeData.compatibilityName + '）';

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
