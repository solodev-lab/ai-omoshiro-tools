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
    const choicesContainer = document.getElementById('choicesContainer');
    const analyzingStatus = document.getElementById('analyzingStatus');
    const resultEmoji = document.getElementById('resultEmoji');
    const resultName = document.getElementById('resultName');
    const resultEra = document.getElementById('resultEra');
    const resultDescription = document.getElementById('resultDescription');
    const resultTraits = document.getElementById('resultTraits');
    const resultLuckyItem = document.getElementById('resultLuckyItem');
    const rarityBadge = document.getElementById('rarityBadge');
    const resultCard = document.getElementById('resultCard');
    const shareXBtn = document.getElementById('shareXBtn');
    const shareLINEBtn = document.getElementById('shareLINEBtn');
    const copyBtn = document.getElementById('copyBtn');
    const retryBtn = document.getElementById('retryBtn');
    const historyBtn = document.getElementById('historyBtn');
    const historySection = document.getElementById('historySection');
    const historyList = document.getElementById('historyList');
    const toast = document.getElementById('toast');

    // 状態
    let currentQuestion = 0;
    let answers = [];

    // スタートボタン
    startBtn.addEventListener('click', () => {
        startSection.style.display = 'none';
        questionSection.style.display = 'block';
        currentQuestion = 0;
        answers = [];
        showQuestion(0);
    });

    // 質問表示
    function showQuestion(index) {
        const q = QUESTIONS[index];
        currentQuestion = index;

        progressFill.style.width = ((index) / QUESTIONS.length * 100) + '%';
        progressText.textContent = (index + 1) + ' / ' + QUESTIONS.length;

        questionText.textContent = q.q;

        // 選択肢を動的生成
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

    // タイプ判定（回答のハッシュから16タイプへマッピング）
    function getTypeIndex() {
        let hash = 0;
        for (let i = 0; i < answers.length; i++) {
            hash = hash * 4 + answers[i];
        }
        return hash % PAST_LIFE_TYPES.length;
    }

    // 分析演出
    function showAnalyzing() {
        questionSection.style.display = 'none';
        analyzingSection.style.display = 'block';

        const typeIndex = getTypeIndex();
        const typeData = PAST_LIFE_TYPES[typeIndex];

        const statuses = [
            '魂の記憶にアクセスしています',
            '前世の時代を特定中...',
            '過去の記憶を再構成しています',
            '魂の本質を解読中...',
            'あなたの前世が判明しました！'
        ];

        // AI呼び出しをアニメーションと並行実行
        const aiPromise = analyzeWithAI(typeData);

        let i = 0;
        const interval = setInterval(() => {
            i++;
            if (i < statuses.length) {
                analyzingStatus.textContent = statuses[i];
            }
            if (i >= statuses.length) {
                clearInterval(interval);
                aiPromise.then(aiData => {
                    setTimeout(() => showResult(typeData, aiData), 500);
                }).catch(() => {
                    setTimeout(() => showResult(typeData, null), 500);
                });
            }
        }, 600);
    }

    // AI分析
    async function analyzeWithAI(typeData) {
        try {
            const controller = new AbortController();
            const timeoutId = setTimeout(() => controller.abort(), 15000);

            const response = await fetch(API_URL + '/api/generate', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    app: 'past-life',
                    params: { answers: answers, typeId: typeData.id }
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
    function showResult(typeData, aiData) {
        analyzingSection.style.display = 'none';
        resultSection.style.display = 'block';

        let description, traits, luckyItem;

        if (aiData) {
            description = aiData.description || typeData.description;
            traits = aiData.traits || typeData.traits;
            luckyItem = aiData.luckyItem || typeData.luckyItem;
        } else {
            description = typeData.description;
            traits = typeData.traits;
            luckyItem = typeData.luckyItem;
        }

        // DOM更新
        resultEmoji.textContent = typeData.emoji;
        resultName.textContent = typeData.name;
        resultEra.textContent = typeData.era;
        resultDescription.textContent = description;

        // レア度バッジ
        rarityBadge.textContent = typeData.rarityRank;
        rarityBadge.className = 'rarity-badge rarity-' + typeData.rarityRank.toLowerCase();

        // 特徴
        resultTraits.innerHTML = '';
        traits.forEach(t => {
            const li = document.createElement('li');
            li.textContent = t;
            resultTraits.appendChild(li);
        });

        // ラッキーアイテム
        resultLuckyItem.textContent = luckyItem;

        resultSection.scrollIntoView({ behavior: 'smooth' });

        // シェア用データ保存
        resultSection.dataset.name = typeData.name;
        resultSection.dataset.rarity = typeData.rarityRank;

        // 履歴に保存
        saveToHistory(typeData);
    }

    // 履歴保存
    function saveToHistory(typeData) {
        const history = JSON.parse(localStorage.getItem('pastLifeHistory') || '[]');
        history.unshift({
            name: typeData.name,
            emoji: typeData.emoji,
            rarityRank: typeData.rarityRank,
            date: new Date().toISOString()
        });
        // 最大20件保持
        if (history.length > 20) {
            history.length = 20;
        }
        localStorage.setItem('pastLifeHistory', JSON.stringify(history));
    }

    // 履歴表示
    function renderHistory() {
        const history = JSON.parse(localStorage.getItem('pastLifeHistory') || '[]');
        historyList.innerHTML = '';

        if (history.length === 0) {
            historyList.innerHTML = '<p class="history-empty">まだ診断履歴がありません</p>';
            return;
        }

        history.forEach(item => {
            const div = document.createElement('div');
            div.className = 'history-item';

            const d = new Date(item.date);
            const dateStr = d.getFullYear() + '/' + (d.getMonth() + 1) + '/' + d.getDate();

            const rarityClass = 'rarity-' + item.rarityRank.toLowerCase();

            div.innerHTML =
                '<span class="history-item-emoji">' + item.emoji + '</span>' +
                '<div class="history-item-info">' +
                    '<div class="history-item-name">' + item.name + '</div>' +
                    '<div class="history-item-date">' + dateStr + '</div>' +
                '</div>' +
                '<span class="history-item-rarity ' + rarityClass + '">' + item.rarityRank + '</span>';

            historyList.appendChild(div);
        });
    }

    // シェアテキスト生成
    function getShareText() {
        const name = resultSection.dataset.name;
        const rarity = resultSection.dataset.rarity;
        return '【AI前世診断】\n私の前世は「' + name + '」でした！\nレア度: ' + rarity + '\n\n#AI前世診断 #AIおもしろツール\nhttps://solodev-lab.github.io/ai-omoshiro-tools/apps/past-life/';
    }

    // X（Twitter）でシェア
    shareXBtn.addEventListener('click', () => {
        const text = getShareText();
        window.open('https://twitter.com/intent/tweet?text=' + encodeURIComponent(text), '_blank');
    });

    // LINEで送る
    shareLINEBtn.addEventListener('click', () => {
        const text = getShareText();
        window.open('https://social-plugins.line.me/lineit/share?url=' + encodeURIComponent('https://solodev-lab.github.io/ai-omoshiro-tools/apps/past-life/') + '&text=' + encodeURIComponent(text), '_blank');
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
        historySection.style.display = 'none';
        startSection.style.display = 'block';
        window.scrollTo({ top: 0, behavior: 'smooth' });
    });

    // 履歴ボタン
    historyBtn.addEventListener('click', () => {
        if (historySection.style.display === 'none') {
            historySection.style.display = 'block';
            renderHistory();
            historySection.scrollIntoView({ behavior: 'smooth' });
        } else {
            historySection.style.display = 'none';
        }
    });

    // トースト
    function showToast(message) {
        toast.textContent = message;
        toast.classList.add('show');
        setTimeout(() => toast.classList.remove('show'), 2000);
    }
});
