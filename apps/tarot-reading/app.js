const API_URL = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
    ? 'http://localhost:8787'
    : 'https://ai-omoshiro-api.kojifo369.workers.dev';

document.addEventListener('DOMContentLoaded', () => {
    // DOM要素
    const modeSection = document.getElementById('modeSection');
    const shuffleSection = document.getElementById('shuffleSection');
    const analyzingSection = document.getElementById('analyzingSection');
    const resultSection = document.getElementById('resultSection');
    const shuffleArea = document.getElementById('shuffleArea');
    const shuffleTitle = document.getElementById('shuffleTitle');
    const shuffleInstruction = document.getElementById('shuffleInstruction');
    const shuffleStatus = document.getElementById('shuffleStatus');
    const analyzingStatus = document.getElementById('analyzingStatus');
    const resultModeLabel = document.getElementById('resultModeLabel');
    const resultTitle = document.getElementById('resultTitle');
    const drawnCards = document.getElementById('drawnCards');
    const readingSection = document.getElementById('readingSection');
    const overallReading = document.getElementById('overallReading');
    const adviceBox = document.getElementById('adviceBox');
    const luckyItems = document.getElementById('luckyItems');
    const shareXBtn = document.getElementById('shareXBtn');
    const shareLINEBtn = document.getElementById('shareLINEBtn');
    const copyBtn = document.getElementById('copyBtn');
    const retryBtn = document.getElementById('retryBtn');
    const toast = document.getElementById('toast');
    const cardSlots = document.getElementById('cardSlots');
    const fiveCardSlots = document.getElementById('fiveCardSlots');

    // 状態
    let currentMode = '';
    let requiredCards = 0;
    let selectedCards = [];
    let shuffledDeck = [];

    // モード選択
    document.querySelectorAll('.mode-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            currentMode = btn.dataset.mode;

            // TODO: 本番では5枚引きはStripe決済後に開始
            // if (currentMode === 'five-card') {
            //     startStripeCheckout();
            //     return;
            // }

            requiredCards = currentMode === 'one-card' ? 1 : (currentMode === 'three-card' ? 3 : 5);
            selectedCards = [];
            startShuffle();
        });
    });

    // Stripe Checkout開始（5枚引き）
    async function startStripeCheckout() {
        try {
            const response = await fetch(API_URL + '/api/stripe/create-checkout', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ app: 'tarot-reading', mode: 'five-card' })
            });

            if (!response.ok) throw new Error('Checkout creation failed');
            const data = await response.json();

            if (data.url) {
                window.location.href = data.url;
            } else {
                throw new Error('No checkout URL');
            }
        } catch (e) {
            console.error('Stripe error:', e);
            showToast('決済の準備に失敗しました。もう一度お試しください。');
        }
    }

    // シャッフル開始
    function startShuffle() {
        modeSection.style.display = 'none';
        shuffleSection.style.display = 'block';

        // デッキをシャッフル
        shuffledDeck = [...ALL_CARDS].sort(() => Math.random() - 0.5);

        const modeNames = { 'one-card': '1枚引き', 'three-card': '3枚引き', 'five-card': '5枚引き' };
        shuffleTitle.textContent = `${modeNames[currentMode]} - カードを選んでください`;

        // カード置き場の表示切替
        cardSlots.style.display = 'none';
        fiveCardSlots.style.display = 'none';

        if (currentMode === 'three-card') {
            cardSlots.style.display = 'flex';
            for (let i = 0; i < 3; i++) {
                const slot = document.getElementById('slotCard' + i);
                slot.innerHTML = '';
                slot.style.border = '2px dashed rgba(155,89,182,0.4)';
                slot.style.background = 'rgba(255,255,255,0.03)';
                slot.style.boxShadow = 'none';
                slot.style.transform = '';
                slot.style.opacity = '';
                slot.style.transition = '';
            }
            shuffleStatus.textContent = '「過去」のカードを選んでください';
        } else if (currentMode === 'five-card') {
            fiveCardSlots.style.display = 'block';
            for (let i = 0; i < 5; i++) {
                const slot = document.getElementById('slotFive' + i);
                slot.innerHTML = '';
                slot.style.border = i === 1 ? '2px dashed rgba(231,76,60,0.4)' : (i === 4 ? '2px dashed rgba(241,196,15,0.3)' : '2px dashed rgba(155,89,182,0.4)');
                slot.style.background = 'rgba(255,255,255,0.03)';
                slot.style.boxShadow = 'none';
                if (i !== 1) { slot.style.transform = ''; }
                slot.style.opacity = '';
                slot.style.transition = '';
            }
            const posNames5 = FIVE_CARD_POSITIONS;
            shuffleStatus.textContent = `「${posNames5[0].name}」のカードを選んでください`;
        } else {
            shuffleStatus.textContent = `あと${requiredCards}枚選んでください`;
        }

        renderShuffleCards();
    }

    // シャッフルエリアにカードを配置
    function renderShuffleCards() {
        shuffleArea.innerHTML = '';
        const totalCards = 20;
        const areaWidth = shuffleArea.offsetWidth || 360;
        const areaHeight = shuffleArea.offsetHeight || 240;
        const cardW = window.innerWidth <= 600 ? 55 : 70;
        const cardH = window.innerWidth <= 600 ? 85 : 105;

        for (let i = 0; i < totalCards; i++) {
            const card = document.createElement('div');
            card.className = 'tarot-card-back';
            card.dataset.index = i;

            // 扇状に配置（20枚対応: 角度を狭めて重なりを増やす）
            const angle = (i - totalCards / 2) * 7;
            const centerX = areaWidth / 2 - cardW / 2;
            const centerY = areaHeight / 2 - cardH / 2 + 20;
            const radius = 120;
            const rad = (angle * Math.PI) / 180;
            const x = centerX + Math.sin(rad) * radius;
            const y = centerY - Math.cos(rad) * (radius * 0.3) + Math.abs(Math.sin(rad)) * 30;

            card.style.left = x + 'px';
            card.style.top = y + 'px';
            card.style.transform = `rotate(${angle}deg)`;
            card.style.zIndex = i;

            // 出現アニメーション
            card.style.opacity = '0';
            card.style.transition = 'all 0.6s cubic-bezier(0.23, 1, 0.32, 1)';
            setTimeout(() => {
                card.style.opacity = '1';
            }, i * 80);

            card.addEventListener('click', () => selectCard(card, i));
            shuffleArea.appendChild(card);
        }
    }

    // カード選択
    function selectCard(cardEl, index) {
        if (cardEl.classList.contains('selected')) return;
        if (selectedCards.length >= requiredCards) return;

        cardEl.classList.add('selected');

        // ランダムにカードを割り当て + 正逆位置
        const deckIndex = index % shuffledDeck.length;
        const cardData = shuffledDeck[deckIndex];
        // 5枚引きの2枚目（障害）は常に正位置
        const isFiveCardObstacle = currentMode === 'five-card' && selectedCards.length === 1;
        const isReversed = isFiveCardObstacle ? false : Math.random() < 0.4;

        const cardInfo = {
            ...cardData,
            isReversed,
            meaning: isReversed ? cardData.reversed : cardData.upright
        };
        selectedCards.push(cardInfo);

        // 3枚引き: カードを一覧から消して置き場に移動
        if (currentMode === 'three-card') {
            // カードをフェードアウト
            cardEl.style.opacity = '0';
            cardEl.style.transform = 'scale(0.8)';
            cardEl.style.pointerEvents = 'none';

            const slotIndex = selectedCards.length - 1;
            const slot = document.getElementById('slotCard' + slotIndex);
            setTimeout(() => {
                cardEl.style.display = 'none';
                // スロットにカード情報を表示
                slot.innerHTML = `
                    <div style="font-size:1.8rem;">${cardInfo.emoji}</div>
                    <div style="font-size:0.65rem;font-weight:700;color:#e0d0f0;margin:4px 0 2px;">${cardInfo.name}</div>
                    <span style="font-size:0.6rem;font-weight:700;padding:2px 6px;border-radius:8px;color:${cardInfo.isReversed ? '#e74c3c' : '#2ecc71'};background:${cardInfo.isReversed ? 'rgba(231,76,60,0.15)' : 'rgba(46,204,113,0.15)'};">
                        ${cardInfo.isReversed ? '逆位置' : '正位置'}
                    </span>
                `;
                slot.style.border = '2px solid rgba(241,196,15,0.6)';
                slot.style.background = 'linear-gradient(135deg, #2c1654, #4a1a7a)';
                slot.style.boxShadow = '0 4px 16px rgba(155,89,182,0.3)';
                slot.style.transform = 'scale(0.5)';
                slot.style.opacity = '0';
                // アニメーション開始
                requestAnimationFrame(() => {
                    slot.style.transition = 'transform 0.4s ease, opacity 0.4s ease';
                    slot.style.transform = 'scale(1)';
                    slot.style.opacity = '1';
                });
            }, 300);

            const posNames = ['過去', '現在', '未来'];
            if (selectedCards.length < requiredCards) {
                shuffleStatus.textContent = `「${posNames[selectedCards.length]}」のカードを選んでください`;
            } else {
                shuffleStatus.textContent = '全てのカードが選ばれました！';
            }
        } else if (currentMode === 'five-card') {
            // 5枚引き: カードを一覧から消して置き場に移動
            cardEl.style.opacity = '0';
            cardEl.style.transform = 'scale(0.8)';
            cardEl.style.pointerEvents = 'none';

            const slotIndex = selectedCards.length - 1;
            const slot = document.getElementById('slotFive' + slotIndex);
            const isObstacle = slotIndex === 1;
            setTimeout(() => {
                cardEl.style.display = 'none';
                const directionHtml = isObstacle ? '' : `
                    <span style="font-size:0.55rem;font-weight:700;padding:1px 5px;border-radius:8px;color:${cardInfo.isReversed ? '#e74c3c' : '#2ecc71'};background:${cardInfo.isReversed ? 'rgba(231,76,60,0.15)' : 'rgba(46,204,113,0.15)'};">
                        ${cardInfo.isReversed ? '逆位置' : '正位置'}
                    </span>`;
                slot.innerHTML = `
                    <div style="font-size:${isObstacle ? '1.2rem' : '1.5rem'};">${cardInfo.emoji}</div>
                    <div style="font-size:0.6rem;font-weight:700;color:#e0d0f0;margin:2px 0 1px;">${cardInfo.name}</div>
                    ${directionHtml}
                `;
                slot.style.border = slotIndex === 4 ? '2px solid rgba(241,196,15,0.7)' : '2px solid rgba(241,196,15,0.5)';
                slot.style.background = 'linear-gradient(135deg, #2c1654, #4a1a7a)';
                slot.style.boxShadow = '0 4px 12px rgba(155,89,182,0.3)';
                const baseTransform = isObstacle ? 'rotate(-12deg)' : '';
                slot.style.transform = baseTransform + ' scale(0.5)';
                slot.style.opacity = '0';
                requestAnimationFrame(() => {
                    slot.style.transition = 'transform 0.4s ease, opacity 0.4s ease';
                    slot.style.transform = baseTransform + ' scale(1)';
                    slot.style.opacity = '1';
                });
            }, 300);

            if (selectedCards.length < requiredCards) {
                const posName = FIVE_CARD_POSITIONS[selectedCards.length].name;
                shuffleStatus.textContent = `「${posName}」のカードを選んでください`;
            } else {
                shuffleStatus.textContent = '全てのカードが選ばれました！';
            }
        } else {
            shuffleStatus.textContent = selectedCards.length < requiredCards
                ? `あと${requiredCards - selectedCards.length}枚選んでください`
                : '全てのカードが選ばれました！';
        }

        if (selectedCards.length >= requiredCards) {
            shuffleInstruction.textContent = '鑑定を開始します...';
            // 3枚引き・5枚引き: スロットアニメーション完了後に間を置く
            const delay = (currentMode === 'three-card' || currentMode === 'five-card') ? 1800 : 800;
            setTimeout(() => startAnalyzing(), delay);
        }
    }

    // 分析中表示
    function startAnalyzing() {
        shuffleSection.style.display = 'none';
        analyzingSection.style.display = 'block';

        const statuses = [
            '星の配置を確認中...',
            'カードの意味を読み取っています...',
            '過去と未来の繋がりを分析中...',
            '宇宙のメッセージを受信中...',
            '鑑定結果をまとめています...'
        ];

        // AI呼び出しを並行で開始
        const aiPromise = callAI();

        let i = 0;
        const interval = setInterval(() => {
            if (i < statuses.length) {
                analyzingStatus.textContent = statuses[i];
            }
            if (i >= statuses.length) {
                clearInterval(interval);
                aiPromise.then(aiData => {
                    setTimeout(() => showResult(aiData), 500);
                }).catch(() => {
                    setTimeout(() => showResult(null), 500);
                });
            }
            i++;
        }, 700);
    }

    // AI API呼び出し
    async function callAI() {
        try {
            const controller = new AbortController();
            const timeoutId = setTimeout(() => controller.abort(), 20000);

            const cardsPayload = selectedCards.map(c => ({
                name: c.name,
                isReversed: c.isReversed,
                meaning: c.meaning
            }));

            const response = await fetch(API_URL + '/api/generate', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    app: 'tarot-reading',
                    params: { mode: currentMode, cards: cardsPayload }
                }),
                signal: controller.signal
            });

            clearTimeout(timeoutId);
            if (!response.ok) throw new Error('API error');

            const json = await response.json();
            if (!json.success || !json.data) throw new Error('Invalid response');
            return json.data;
        } catch (e) {
            console.log('AI analysis failed, using static fallback:', e.message);
            return null;
        }
    }

    // 結果表示
    function showResult(aiData) {
        analyzingSection.style.display = 'none';
        resultSection.style.display = 'block';

        const modeLabels = {
            'one-card': '🎴 ワンオラクル',
            'three-card': '🎴 3枚引き（過去・現在・未来）',
            'five-card': '🎴 5枚引き（ケルト十字簡易版）'
        };

        resultModeLabel.textContent = modeLabels[currentMode];
        resultTitle.textContent = 'タロット鑑定結果';

        // カード表示
        renderDrawnCards();

        // AI鑑定結果表示
        if (currentMode === 'one-card') {
            renderOneCardResult(aiData);
        } else if (currentMode === 'three-card') {
            renderThreeCardResult(aiData);
        } else {
            renderFiveCardResult(aiData);
        }
    }

    // 引いたカード一覧を表示
    function renderDrawnCards() {
        drawnCards.innerHTML = '';
        const positions = currentMode === 'three-card' ? THREE_CARD_POSITIONS
            : currentMode === 'five-card' ? FIVE_CARD_POSITIONS
            : [{ name: '今日のカード', icon: '🔮' }];

        selectedCards.forEach((card, i) => {
            const div = document.createElement('div');
            div.className = 'drawn-card';
            div.style.animationDelay = (i * 0.15) + 's';
            div.innerHTML = `
                <div class="position-label">${positions[i].icon} ${positions[i].name}</div>
                <div class="card-emoji">${card.emoji}</div>
                <div class="card-name">${card.name}</div>
                <span class="card-direction ${card.isReversed ? 'reversed' : 'upright'}">
                    ${card.isReversed ? '逆位置 ↓' : '正位置 ↑'}
                </span>
                <div class="card-meaning">${card.meaning}</div>
            `;
            drawnCards.appendChild(div);
        });
    }

    // 1枚引き結果
    function renderOneCardResult(aiData) {
        readingSection.innerHTML = '';

        const overallMsg = aiData?.overall || getStaticOverall();
        readingSection.innerHTML = `
            <div class="reading-block">
                <div class="block-title">🔮 カードからのメッセージ</div>
                <div class="block-text">${overallMsg}</div>
            </div>
        `;

        const advice = aiData?.advice || getStaticAdvice();
        overallReading.innerHTML = '';
        overallReading.style.display = 'none';
        adviceBox.innerHTML = `
            <div class="advice-label">💡 今日のアドバイス</div>
            <div class="advice-text">${advice}</div>
        `;

        luckyItems.innerHTML = '';
        if (aiData?.lucky_color || aiData?.lucky_number) {
            let html = '';
            if (aiData.lucky_color) {
                html += `<div class="lucky-item"><div class="lucky-label">ラッキーカラー</div><div class="lucky-value">${aiData.lucky_color}</div></div>`;
            }
            if (aiData.lucky_number) {
                html += `<div class="lucky-item"><div class="lucky-label">ラッキーナンバー</div><div class="lucky-value">${aiData.lucky_number}</div></div>`;
            }
            luckyItems.innerHTML = html;
        }
    }

    // 3枚引き結果
    function renderThreeCardResult(aiData) {
        readingSection.innerHTML = '';

        if (aiData) {
            const blocks = [
                { title: '⏪ 過去', text: aiData.past },
                { title: '🔵 現在', text: aiData.present },
                { title: '⏩ 未来', text: aiData.future }
            ];

            blocks.forEach(b => {
                if (b.text) {
                    readingSection.innerHTML += `
                        <div class="reading-block">
                            <div class="block-title">${b.title}</div>
                            <div class="block-text">${b.text}</div>
                        </div>
                    `;
                }
            });
        }

        const overall = aiData?.overall || getStaticOverall();
        overallReading.innerHTML = `
            <div class="overall-title">✨ 総合メッセージ</div>
            <div class="overall-text">${overall}</div>
        `;

        const advice = aiData?.advice || getStaticAdvice();
        adviceBox.innerHTML = `
            <div class="advice-label">💡 アドバイス</div>
            <div class="advice-text">${advice}</div>
        `;

        luckyItems.innerHTML = '';
    }

    // 5枚引き結果
    function renderFiveCardResult(aiData) {
        readingSection.innerHTML = '';

        if (aiData) {
            const blocks = [
                { title: '🔵 現在の状況', text: aiData.current },
                { title: '🔴 障害・課題', text: aiData.obstacle },
                { title: '⏪ 過去の影響', text: aiData.past_influence },
                { title: '⏩ 未来の可能性', text: aiData.future_potential },
                { title: '⭐ 最終結論', text: aiData.conclusion }
            ];

            blocks.forEach(b => {
                if (b.text) {
                    readingSection.innerHTML += `
                        <div class="reading-block">
                            <div class="block-title">${b.title}</div>
                            <div class="block-text">${b.text}</div>
                        </div>
                    `;
                }
            });

            // 障害の扱い方アドバイス
            if (aiData.obstacle_advice) {
                readingSection.innerHTML += `
                    <div class="reading-block" style="border-left:3px solid #f1c40f;background:linear-gradient(135deg,rgba(241,196,15,0.08),rgba(155,89,182,0.08));">
                        <div class="block-title">🔑 最終結論を良き結果にするために</div>
                        <div class="block-text">${aiData.obstacle_advice}</div>
                    </div>
                `;
            }
        }

        const overall = aiData?.overall || getStaticOverall();
        overallReading.innerHTML = `
            <div class="overall-title">✨ 総合鑑定</div>
            <div class="overall-text">${overall}</div>
        `;

        const advice = aiData?.advice || getStaticAdvice();
        adviceBox.innerHTML = `
            <div class="advice-label">💡 具体的なアクションアドバイス</div>
            <div class="advice-text">${advice}</div>
        `;

        luckyItems.innerHTML = '';
        if (aiData?.lucky_item) {
            luckyItems.innerHTML = `
                <div class="lucky-item">
                    <div class="lucky-label">ラッキーアイテム</div>
                    <div class="lucky-value">${aiData.lucky_item}</div>
                </div>
            `;
        }
    }

    // 静的フォールバック
    function getStaticOverall() {
        const card = selectedCards[0];
        return `${card.name}（${card.isReversed ? '逆位置' : '正位置'}）が示すのは「${card.meaning}」です。今のあなたにとって大切なメッセージが込められています。カードの導きに耳を傾けてみてください。`;
    }

    function getStaticAdvice() {
        const advices = [
            '今日は直感を信じて行動してみましょう。',
            '焦らず、一歩ずつ前に進むことが大切です。',
            '周囲の人との繋がりを大切にしてください。',
            '新しいことに挑戦するチャンスが近づいています。',
            '心を落ち着けて、本当に大切なものを見つめ直しましょう。'
        ];
        return advices[Math.floor(Math.random() * advices.length)];
    }

    // シェア機能
    function getShareText() {
        const card = selectedCards[0];
        const modeText = currentMode === 'one-card' ? 'ワンオラクル'
            : currentMode === 'three-card' ? '3枚引き' : '5枚引き';
        return `🔮 AIタロット占い（${modeText}）\n${card.emoji} ${card.name}（${card.isReversed ? '逆位置' : '正位置'}）\n「${card.meaning}」\n`;
    }

    shareXBtn.addEventListener('click', () => {
        const text = getShareText();
        const url = encodeURIComponent(window.location.href);
        window.open(`https://x.com/intent/tweet?text=${encodeURIComponent(text)}&url=${url}`, '_blank');
    });

    shareLINEBtn.addEventListener('click', () => {
        const text = getShareText();
        window.open(`https://line.me/R/msg/text/${encodeURIComponent(text + '\n' + window.location.href)}`, '_blank');
    });

    copyBtn.addEventListener('click', () => {
        const text = getShareText() + window.location.href;
        navigator.clipboard.writeText(text).then(() => showToast('コピーしました！'));
    });

    // もう一度占う
    retryBtn.addEventListener('click', () => {
        resultSection.style.display = 'none';
        modeSection.style.display = 'block';
        selectedCards = [];
        currentMode = '';
        window.scrollTo({ top: 0, behavior: 'smooth' });
    });

    // トースト
    function showToast(msg) {
        toast.textContent = msg;
        toast.classList.add('show');
        setTimeout(() => toast.classList.remove('show'), 2500);
    }
});
