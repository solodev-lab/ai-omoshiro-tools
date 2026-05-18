const API_URL = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
    ? 'http://localhost:8787'
    : 'https://ai-omoshiro-api.kojifo369.workers.dev';

document.addEventListener('DOMContentLoaded', () => {
    // DOM要素
    const modeSection = document.getElementById('modeSection');
    const consultSection = document.getElementById('consultSection');
    const shuffleSection = document.getElementById('shuffleSection');
    const analyzingSection = document.getElementById('analyzingSection');
    const resultSection = document.getElementById('resultSection');
    const historySection = document.getElementById('historySection');
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
    const twoCardSlots = document.getElementById('twoCardSlots');
    const twoChoiceSlots = document.getElementById('twoChoiceSlots');
    const hexagramSlots = document.getElementById('hexagramSlots');
    const horseshoeSlots = document.getElementById('horseshoeSlots');
    const relCrossSlots = document.getElementById('relCrossSlots');
    const relMirrorSlots = document.getElementById('relMirrorSlots');
    const yesnoSlots = document.getElementById('yesnoSlots');

    // PWAモード検出
    const isPWA = window.matchMedia('(display-mode: standalone)').matches
        || window.navigator.standalone === true;

    if (isPWA) {
        const fiveCardBtn = document.querySelector('.mode-btn[data-mode="five-card"]');
        if (fiveCardBtn) fiveCardBtn.style.display = 'none';
        const homeBtn = document.querySelector('.home-btn');
        if (homeBtn) homeBtn.style.display = 'none';
        const footerNav = document.querySelector('.footer-nav');
        if (footerNav) footerNav.style.display = 'none';
    }

    // 状態
    let currentMode = '';
    let requiredCards = 0;
    let selectedCards = [];
    let shuffledDeck = [];
    let consultationData = { category: '', situation: '', question: '', note: '' };
    let typewriterSkip = false;

    // セクション表示ヘルパー
    function showOnly(sectionId) {
        [modeSection, consultSection, shuffleSection, analyzingSection, resultSection, historySection].forEach(s => {
            if (s) s.style.display = 'none';
        });
        const target = document.getElementById(sectionId);
        if (target) target.style.display = 'block';
    }

    // ========== モード選択 ==========
    document.querySelectorAll('.mode-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            currentMode = btn.dataset.mode;
            requiredCards = currentMode === 'one-card' ? 1 : currentMode === 'two-card' ? 2 : (currentMode === 'three-card' || currentMode === 'yesno') ? 3 : (currentMode === 'five-card' || currentMode === 'rel-cross') ? 5 : currentMode === 'two-choice' ? 6 : (currentMode === 'hexagram' || currentMode === 'horseshoe' || currentMode === 'rel-mirror') ? 7 : 5;
            selectedCards = [];
            consultationData = { category: '', situation: '', question: '', note: '' };
            if (currentMode === 'two-choice') {
                consultationData.question = '2者択一';
            }
            showConsultStep1();
        });
    });

    // 履歴ボタン
    const historyBtn = document.getElementById('historyBtn');
    if (historyBtn) {
        historyBtn.addEventListener('click', () => {
            renderHistoryList();
            showOnly('historySection');
        });
    }

    // ========== 相談内容の選択式UI ==========
    function showConsultStep1() {
        showOnly('consultSection');
        const container = document.getElementById('consultSteps');
        const categories = Object.keys(CONSULTATION_TREE);
        container.innerHTML = `
            <div class="consult-step active">
                <div class="consult-step-label">Step 1 / ${currentMode === 'two-choice' ? '2〜3' : '4'}</div>
                <h3 class="consult-step-title">何について占いますか？</h3>
                <div class="consult-btn-grid">
                    ${categories.map(cat => `<button class="consult-btn" data-value="${cat}">${cat}</button>`).join('')}
                </div>
                <button class="consult-back-btn" id="consultBackToMenu">← モード選択に戻る</button>
            </div>
        `;
        document.getElementById('consultBackToMenu').addEventListener('click', () => {
            showOnly('modeSection');
        });
        container.querySelectorAll('.consult-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                consultationData.category = btn.dataset.value;
                const tree = CONSULTATION_TREE[consultationData.category];
                if (currentMode === 'two-choice') {
                    // 2者択一: カテゴリ選択後、状況があればStep2へ、なければ直接Step4
                    if (tree.situations === null) {
                        consultationData.situation = '';
                        showConsultStep4TwoChoice();
                    } else {
                        showConsultStep2ForTwoChoice();
                    }
                } else if (tree.situations === null) {
                    consultationData.situation = '';
                    showConsultStep3();
                } else {
                    showConsultStep2();
                }
            });
        });
    }

    function showConsultStep2() {
        const container = document.getElementById('consultSteps');
        const tree = CONSULTATION_TREE[consultationData.category];
        container.innerHTML = `
            <div class="consult-step active">
                <div class="consult-step-label">Step 2 / 4</div>
                <h3 class="consult-step-title">${consultationData.category} — 状況は？</h3>
                <div class="consult-btn-grid">
                    ${tree.situations.map(s => `<button class="consult-btn" data-value="${s}">${s}</button>`).join('')}
                </div>
                <button class="consult-back-btn" id="consultBack2">← 戻る</button>
            </div>
        `;
        container.querySelectorAll('.consult-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                consultationData.situation = btn.dataset.value;
                showConsultStep3();
            });
        });
        document.getElementById('consultBack2').addEventListener('click', showConsultStep1);
    }

    // 2者択一モード用Step2: 状況選択後にStep3スキップ→Step4TwoChoiceへ
    function showConsultStep2ForTwoChoice() {
        const container = document.getElementById('consultSteps');
        const tree = CONSULTATION_TREE[consultationData.category];
        container.innerHTML = `
            <div class="consult-step active">
                <div class="consult-step-label">Step 2 / 3</div>
                <h3 class="consult-step-title">${consultationData.category} — 状況は？</h3>
                <div class="consult-btn-grid">
                    ${tree.situations.map(s => `<button class="consult-btn" data-value="${s}">${s}</button>`).join('')}
                </div>
                <button class="consult-back-btn" id="consultBack2tc">← 戻る</button>
            </div>
        `;
        container.querySelectorAll('.consult-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                consultationData.situation = btn.dataset.value;
                showConsultStep4TwoChoice();
            });
        });
        document.getElementById('consultBack2tc').addEventListener('click', showConsultStep1);
    }

    function showConsultStep3() {
        const container = document.getElementById('consultSteps');
        const tree = CONSULTATION_TREE[consultationData.category];
        container.innerHTML = `
            <div class="consult-step active">
                <div class="consult-step-label">Step 3 / 4</div>
                <h3 class="consult-step-title">何が知りたいですか？</h3>
                <div class="consult-btn-grid">
                    ${tree.questions.map(q => `<button class="consult-btn" data-value="${q}">${q}</button>`).join('')}
                </div>
                <button class="consult-back-btn" id="consultBack3">← 戻る</button>
            </div>
        `;
        container.querySelectorAll('.consult-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                consultationData.question = btn.dataset.value;
                showConsultStep4();
            });
        });
        const backTarget = CONSULTATION_TREE[consultationData.category].situations === null ? showConsultStep1 : showConsultStep2;
        document.getElementById('consultBack3').addEventListener('click', backTarget);
    }

    function showConsultStep4() {
        const container = document.getElementById('consultSteps');
        const examples = getSupplementExamples();
        const placeholder = examples[0];
        const displayExamples = examples.slice(1);
        container.innerHTML = `
            <div class="consult-step active">
                <div class="consult-step-label">Step 4 / 4</div>
                <h3 class="consult-step-title">補足があればどうぞ（任意）</h3>
                <p class="consult-summary">${consultationData.category} > ${consultationData.situation || '—'} > ${consultationData.question}</p>
                <textarea class="consult-note" id="consultNote" maxlength="50" placeholder="例: ${placeholder}（50文字以内）"></textarea>
                <div class="consult-note-count"><span id="noteCount">0</span>/50</div>
                <div class="choice-examples">
                    <div class="choice-examples-label">💡 入力例</div>
                    ${displayExamples.map(s => `<div class="choice-example-item">「${s}」</div>`).join('')}
                </div>
                <button class="consult-start-btn" id="consultStartBtn">🔮 カードを引く</button>
                <button class="consult-back-btn" id="consultBack4">← 戻る</button>
            </div>
        `;
        const noteInput = document.getElementById('consultNote');
        const noteCount = document.getElementById('noteCount');
        noteInput.addEventListener('input', () => {
            noteCount.textContent = noteInput.value.length;
        });
        document.getElementById('consultStartBtn').addEventListener('click', () => {
            consultationData.note = noteInput.value.trim();
            startShuffle();
        });
        document.getElementById('consultBack4').addEventListener('click', showConsultStep3);
    }

    // カテゴリ・状況別の補足入力サンプル（通常モード用）
    // [placeholder, 例1, 例2, 例3]
    const SUPPLEMENT_EXAMPLES = {
        '💕 恋愛': {
            '片思い': ['同じ職場の3歳年上の人', '同級生で友達グループが同じ', 'マッチングアプリで知り合った', 'バイト先の先輩'],
            '交際中': ['付き合って半年の彼氏', '遠距離で月1回会える', '同棲中で3年目', '社内恋愛で秘密にしている'],
            '復縁': ['3ヶ月前に別れた元カレ', '自分から振った相手', '5年付き合って別れた', '共通の友人が多い'],
            '不倫': ['職場の上司と半年', '相手は既婚者で子供あり', 'SNSで知り合った', '相手の配偶者は知らない'],
            '配偶者': ['結婚5年目で子供2人', '共働きですれ違いが多い', '最近会話が減った', '義実家との関係が原因']
        },
        '💼 仕事': {
            '同僚': ['入社同期で同じチーム', '年上の同僚と意見が合わない', '最近異動してきた人', 'リモートで顔を合わせない'],
            '上司': ['直属の上司で2年目', '新しく来た部長', 'パワハラ気味の課長', '評価に不満がある'],
            '部下': ['新卒1年目の後輩', '年上の部下を持っている', 'やる気が見えない', 'ミスが多い部下'],
            '別部署': ['プロジェクトで協力中', '以前同じ部署だった', '連携がうまくいかない', '異動希望を出している'],
            '取引先': ['長年の取引先が値上げ要求', '新規取引先との契約', '担当者が変わった', 'クレーム対応中'],
            '客先': ['大口クライアント', '要望が多い客先', '長期契約の更新時期', '競合に乗り換え検討中']
        },
        '🏫 学校': {
            '友達': ['クラスの仲良しグループ', '部活の友達と気まずい', '幼馴染と疎遠になった', 'SNSでのトラブル'],
            '先生': ['担任の先生と合わない', '部活の顧問に不満', '進路指導の先生に相談', '授業についていけない'],
            'クラス': ['クラス替えで友達と離れた', '委員会の仕事が大変', '文化祭の準備中', 'いじめられている子がいる'],
            '進路': ['大学受験を控えている', '文理選択で迷っている', '親と進路が合わない', '浪人するか迷っている']
        },
        '👨‍👩‍👧 家族': {
            '親': ['実家暮らしの社会人', '母親と価値観が合わない', '父親が病気がち', '結婚に反対されている'],
            '兄弟姉妹': ['兄と遺産で揉めている', '妹の世話を頼まれる', '弟が引きこもり', '姉と比較される'],
            '親戚': ['お盆の集まりが憂鬱', '介護の分担で揉めている', '親戚の借金問題', '結婚式に呼ぶか迷う'],
            '嫁姑': ['同居して3年目', '姑が育児に口を出す', '夫が味方してくれない', '帰省の頻度で揉める']
        },
        '🤝 人間関係': {
            '友人': ['10年来の親友', '最近知り合ったママ友', 'お金の貸し借りがある', '趣味のサークル仲間'],
            'ご近所': ['隣の家の騒音問題', '挨拶しても無視される', '町内会の役員を頼まれた', 'ゴミ出しのトラブル'],
            '人付き合い全般': ['人見知りで悩んでいる', '断るのが苦手', '八方美人になってしまう', 'SNS疲れを感じている']
        },
        '💰 金運': {
            '収入': ['手取り25万で貯金できない', 'ボーナスカットされた', '副業を始めたい', '給料交渉を考えている'],
            '投資': ['投資初心者で30万から', 'NISAを始めたい', '株で損失が出ている', '仮想通貨に興味がある'],
            '借金': ['カードローン100万円', '奨学金の返済が苦しい', '住宅ローンの見直し', '家族に内緒の借金'],
            '転職': ['年収アップが目的', '今の会社に不満はないが', '異業種への転職', '40代での転職']
        },
        '🏥 健康': {
            '体調': ['最近疲れやすい', '頭痛が続いている', '健康診断で要再検査', '原因不明の体調不良'],
            'メンタル': ['仕事のストレスが限界', '眠れない日が続く', 'やる気が出ない', 'パニック発作がある'],
            '生活習慣': ['運動不足を自覚している', '食生活が乱れている', '夜更かしが治らない', 'お酒の量が増えた']
        },
        '🌟 総合運': {
            '_default': ['最近ついてない気がする', '転機が来ている気がする', '大きな決断を控えている', '漠然とした不安がある']
        }
    };

    function getSupplementExamples() {
        const cat = consultationData.category;
        const sit = consultationData.situation;
        const catExamples = SUPPLEMENT_EXAMPLES[cat];
        if (!catExamples) return ['具体的な状況を教えてください', '詳しい背景があれば', '気になっていること', '最近あった出来事'];
        const examples = catExamples[sit] || catExamples['_default'] || Object.values(catExamples)[0];
        return examples;
    }

    // カテゴリ・状況別の2者択一サンプル [A, B]
    const TWO_CHOICE_EXAMPLES = {
        '💕 恋愛': {
            '片思い': [['告白する', '様子を見る'], ['デートに誘う', 'LINEで距離を縮める'], ['気持ちを伝える', '諦めて次へ'], ['友達から始める', '直接アプローチ']],
            '交際中': [['同棲する', '別々に暮らす'], ['結婚を切り出す', 'もう少し待つ'], ['本音を話す', '黙っておく'], ['距離を置く', '話し合う']],
            '復縁': [['連絡する', 'このまま待つ'], ['直接会いに行く', 'LINEで伝える'], ['やり直す', '新しい恋へ進む'], ['素直に謝る', '相手の出方を見る']],
            '不倫': [['関係を続ける', 'きっぱり別れる'], ['本気で向き合う', '距離を置く'], ['正直に話す', '秘密にする'], ['家庭を選ぶ', '相手を選ぶ']],
            '配偶者': [['話し合う', '距離を置く'], ['一緒に過ごす', '一人の時間を作る'], ['カウンセリングに行く', '自分たちで解決'], ['許す', '別れを考える']]
        },
        '💼 仕事': {
            '同僚': [['協力する', '距離を置く'], ['正直に指摘する', '上司に相談する'], ['自分から歩み寄る', '相手の出方を待つ'], ['チームを変える', '関係改善を図る']],
            '上司': [['直接相談する', '別の上司に相談'], ['意見を言う', '従っておく'], ['異動を希望する', '今のまま頑張る'], ['転職する', '上司が変わるのを待つ']],
            '部下': [['厳しく指導する', '見守る'], ['直接注意する', '間接的に伝える'], ['任せてみる', '自分でやる'], ['面談する', 'チーム全体で話す']],
            '別部署': [['異動を希望する', '今の部署で頑張る'], ['直接交渉する', '上を通す'], ['協力関係を築く', '最低限の付き合い'], ['合同プロジェクト提案', '現状維持']],
            '取引先': [['条件を交渉する', '受け入れる'], ['別の取引先を探す', '関係を維持'], ['強気で出る', '柔軟に対応'], ['直接訪問する', 'メールで済ませる']],
            '客先': [['要望を受ける', '断る'], ['値引きに応じる', '価格を維持'], ['担当を変える', '自分で対応'], ['長期契約を提案', '都度対応']]
        },
        '🏫 学校': {
            '友達': [['自分から誘う', '誘われるのを待つ'], ['本音を話す', '合わせておく'], ['グループを変える', '今の関係を続ける'], ['距離を置く', '仲直りする']],
            '先生': [['相談する', '自分で解決する'], ['意見を伝える', '従っておく'], ['親に相談する', '自分で対処'], ['担任に言う', '別の先生に言う']],
            'クラス': [['積極的に関わる', 'マイペースでいく'], ['委員に立候補', '裏方で支える'], ['グループに入る', '一人で過ごす'], ['転校する', '今の学校で頑張る']],
            '進路': [['進学する', '就職する'], ['文系に進む', '理系に進む'], ['地元に残る', '都会に出る'], ['やりたいことを優先', '安定を優先']]
        },
        '👨‍👩‍👧 家族': {
            '親': [['実家に帰る', '独立を続ける'], ['正直に話す', '心配させない'], ['親の意見を聞く', '自分の道を行く'], ['同居する', '別々に暮らす']],
            '兄弟姉妹': [['話し合う', '距離を置く'], ['協力する', '別々にやる'], ['仲裁に入る', '放っておく'], ['本音をぶつける', '大人の対応']],
            '親戚': [['付き合いを続ける', '距離を置く'], ['集まりに参加', '欠席する'], ['相談する', '自分で決める'], ['援助を受ける', '自力でやる']],
            '嫁姑': [['話し合いの場を設ける', '夫に任せる'], ['同居する', '別居する'], ['歩み寄る', '一線を引く'], ['我慢する', '言いたいことを言う']]
        },
        '🤝 人間関係': {
            '友人': [['連絡する', 'このまま疎遠に'], ['誘いを受ける', '断る'], ['本音を話す', '表面的に付き合う'], ['許す', '縁を切る']],
            'ご近所': [['挨拶から始める', '最低限の付き合い'], ['相談する', '我慢する'], ['自治会に参加', '不参加'], ['引っ越す', '今の場所に留まる']],
            '人付き合い全般': [['広く浅く付き合う', '狭く深く付き合う'], ['自分から誘う', '誘われるのを待つ'], ['SNSを活用', 'リアルの付き合い重視'], ['新しい出会いを求める', '今の関係を大切に']]
        },
        '💰 金運': {
            '収入': [['副業を始める', '本業に集中'], ['転職する', '今の職場で昇進'], ['スキルアップに投資', '貯金を優先'], ['独立する', '会社員を続ける']],
            '投資': [['投資を始める', '貯金を続ける'], ['株式投資', '不動産投資'], ['積立投資', '一括投資'], ['リスクを取る', '安全運用']],
            '借金': [['一括返済', '分割返済'], ['借り換える', '今のまま返す'], ['専門家に相談', '自力で返す'], ['家族に相談', '一人で対処']],
            '転職': [['転職する', '今の会社に残る'], ['年収アップを狙う', 'やりがいを優先'], ['異業種に挑戦', '同業種で転職'], ['すぐ動く', 'じっくり探す']]
        },
        '🏥 健康': {
            '体調': [['病院に行く', '様子を見る'], ['検査を受ける', 'セルフケア'], ['薬を飲む', '自然治癒を待つ'], ['専門医に行く', 'かかりつけ医']],
            'メンタル': [['カウンセリングに行く', '自分で対処'], ['休職する', '働き続ける'], ['薬に頼る', '生活改善で対処'], ['人に相談する', '一人で向き合う']],
            '生活習慣': [['運動を始める', '食事改善から'], ['朝型に変える', '夜型のまま'], ['ジムに通う', '自宅トレーニング'], ['禁酒する', '量を減らす']]
        },
        '🌟 総合運': {
            '_default': [['積極的に動く', '流れに身を任せる'], ['新しいことを始める', '今あるものを大切に'], ['変化を求める', '安定を守る'], ['直感に従う', '慎重に判断する']]
        }
    };

    function getTwoChoiceExamples() {
        const cat = consultationData.category;
        const sit = consultationData.situation;
        const catExamples = TWO_CHOICE_EXAMPLES[cat];
        if (!catExamples) return [['Aの選択肢', 'Bの選択肢'], ['選択肢1', '選択肢2'], ['こちら', 'あちら'], ['やる', 'やらない']];
        const examples = catExamples[sit] || catExamples['_default'] || Object.values(catExamples)[0];
        return examples || [['Aの選択肢', 'Bの選択肢'], ['選択肢1', '選択肢2'], ['こちら', 'あちら'], ['やる', 'やらない']];
    }

    function showConsultStep4TwoChoice() {
        const container = document.getElementById('consultSteps');
        const examples = getTwoChoiceExamples();
        const placeholder = examples[0];
        const suggestions = examples.slice(1);
        container.innerHTML = `
            <div class="consult-step active">
                <div class="consult-step-label">${consultationData.situation ? 'Step 3 / 3' : 'Step 2 / 2'}</div>
                <h3 class="consult-step-title">2つの選択肢を入力してください</h3>
                <p class="consult-summary">${consultationData.category}${consultationData.situation ? ' > ' + consultationData.situation : ''} > 2者択一</p>
                <div class="two-choice-inputs">
                    <div class="choice-input-group">
                        <label class="choice-label choice-a">🅰️ 選択肢A</label>
                        <input type="text" class="choice-input" id="choiceA" maxlength="30" placeholder="例: ${placeholder[0]}">
                    </div>
                    <div class="choice-input-group">
                        <label class="choice-label choice-b">🅱️ 選択肢B</label>
                        <input type="text" class="choice-input" id="choiceB" maxlength="30" placeholder="例: ${placeholder[1]}">
                    </div>
                </div>
                <div class="choice-examples">
                    <div class="choice-examples-label">💡 入力例</div>
                    ${suggestions.map(s => `<div class="choice-example-item">「${s[0]}」と「${s[1]}」</div>`).join('')}
                </div>
                <button class="consult-start-btn" id="consultStartBtn" disabled>🔮 カードを引く</button>
                <button class="consult-back-btn" id="consultBack4tc">← 戻る</button>
            </div>
        `;
        const choiceA = document.getElementById('choiceA');
        const choiceB = document.getElementById('choiceB');
        const startBtn = document.getElementById('consultStartBtn');
        const checkInputs = () => {
            startBtn.disabled = !(choiceA.value.trim() && choiceB.value.trim());
        };
        choiceA.addEventListener('input', checkInputs);
        choiceB.addEventListener('input', checkInputs);
        startBtn.addEventListener('click', () => {
            consultationData.note = `A: ${choiceA.value.trim()} / B: ${choiceB.value.trim()}`;
            consultationData.choiceA = choiceA.value.trim();
            consultationData.choiceB = choiceB.value.trim();
            startShuffle();
        });
        const backTarget = consultationData.situation ? showConsultStep2ForTwoChoice : showConsultStep1;
        document.getElementById('consultBack4tc').addEventListener('click', backTarget);
    }

    // ========== シャッフル ==========
    function startShuffle() {
        showOnly('shuffleSection');
        shuffledDeck = [...ALL_CARDS].sort(() => Math.random() - 0.5);

        const modeNames = {
            'one-card': '1枚引き', 'two-card': '2枚引き',
            'three-card': '3枚引き', 'five-card': '5枚引き',
            'two-choice': '2者択一（6枚）', 'hexagram': 'ヘキサグラム（7枚）',
            'horseshoe': 'ホースシュー（7枚）', 'rel-cross': 'リレーションシップクロス（5枚）',
            'rel-mirror': 'ミラースプレッド（7枚）', 'yesno': 'Yes/No（3枚）'
        };
        shuffleTitle.textContent = `${modeNames[currentMode]} - カードを選んでください`;

        // カード置き場の表示切替
        cardSlots.style.display = 'none';
        fiveCardSlots.style.display = 'none';
        twoCardSlots.style.display = 'none';
        twoChoiceSlots.style.display = 'none';
        hexagramSlots.style.display = 'none';
        horseshoeSlots.style.display = 'none';
        relCrossSlots.style.display = 'none';
        relMirrorSlots.style.display = 'none';
        yesnoSlots.style.display = 'none';

        if (currentMode === 'two-card') {
            twoCardSlots.style.display = 'flex';
            for (let i = 0; i < 2; i++) {
                const slot = document.getElementById('slotTwoCard' + i);
                slot.innerHTML = '';
                slot.style.border = '2px dashed rgba(155,89,182,0.4)';
                slot.style.background = 'rgba(255,255,255,0.03)';
                slot.style.boxShadow = 'none';
                slot.style.transform = '';
                slot.style.opacity = '';
                slot.style.transition = '';
            }
            shuffleStatus.textContent = '「現在の状況」のカードを選んでください';
        } else if (currentMode === 'three-card') {
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
                if (i !== 1) slot.style.transform = '';
                slot.style.opacity = '';
                slot.style.transition = '';
            }
            shuffleStatus.textContent = `「${FIVE_CARD_POSITIONS[0].name}」のカードを選んでください`;
        } else if (currentMode === 'two-choice') {
            twoChoiceSlots.style.display = 'block';
            for (let i = 0; i < 6; i++) {
                const slot = document.getElementById('slotTwo' + i);
                slot.innerHTML = '';
                slot.style.border = '2px dashed rgba(155,89,182,0.4)';
                slot.style.background = 'rgba(255,255,255,0.03)';
                slot.style.boxShadow = 'none';
                slot.style.transform = '';
                slot.style.opacity = '';
                slot.style.transition = '';
            }
            shuffleStatus.textContent = '「現在」のカードを選んでください';
        } else if (currentMode === 'hexagram') {
            hexagramSlots.style.display = 'block';
            for (let i = 0; i < 7; i++) {
                const slot = document.getElementById('slotHex' + i);
                slot.innerHTML = '';
                slot.style.border = '2px dashed rgba(155,89,182,0.4)';
                slot.style.background = 'rgba(255,255,255,0.03)';
                slot.style.boxShadow = 'none';
                slot.style.transform = '';
                slot.style.opacity = '';
                slot.style.transition = '';
            }
            shuffleStatus.textContent = `「${HEXAGRAM_POSITIONS[0].name}」のカードを選んでください`;
        } else if (currentMode === 'horseshoe') {
            horseshoeSlots.style.display = 'block';
            for (let i = 0; i < 7; i++) {
                const slot = document.getElementById('slotHorse' + i);
                slot.innerHTML = '';
                slot.style.border = '2px dashed rgba(155,89,182,0.4)';
                slot.style.background = 'rgba(255,255,255,0.03)';
                slot.style.boxShadow = 'none';
                slot.style.transform = '';
                slot.style.opacity = '';
                slot.style.transition = '';
            }
            shuffleStatus.textContent = `「${HORSESHOE_POSITIONS[0].name}」のカードを選んでください`;
        } else if (currentMode === 'rel-cross') {
            relCrossSlots.style.display = 'block';
            for (let i = 0; i < 5; i++) {
                const slot = document.getElementById('slotRC' + i);
                slot.innerHTML = '';
                slot.style.border = '2px dashed rgba(155,89,182,0.4)';
                slot.style.background = 'rgba(255,255,255,0.03)';
                slot.style.boxShadow = 'none';
                slot.style.transform = '';
                slot.style.opacity = '';
                slot.style.transition = '';
            }
            shuffleStatus.textContent = `「${REL_CROSS_POSITIONS[0].name}」のカードを選んでください`;
        } else if (currentMode === 'rel-mirror') {
            relMirrorSlots.style.display = 'block';
            for (let i = 0; i < 7; i++) {
                const slot = document.getElementById('slotRM' + i);
                slot.innerHTML = '';
                slot.style.border = '2px dashed rgba(155,89,182,0.4)';
                slot.style.background = 'rgba(255,255,255,0.03)';
                slot.style.boxShadow = 'none';
                slot.style.transform = '';
                slot.style.opacity = '';
                slot.style.transition = '';
            }
            shuffleStatus.textContent = `「${REL_MIRROR_POSITIONS[0].name}」のカードを選んでください`;
        } else if (currentMode === 'yesno') {
            yesnoSlots.style.display = 'flex';
            for (let i = 0; i < 3; i++) {
                const slot = document.getElementById('slotYesno' + i);
                slot.innerHTML = '';
                slot.style.border = '2px dashed rgba(155,89,182,0.4)';
                slot.style.background = 'rgba(255,255,255,0.03)';
                slot.style.boxShadow = 'none';
                slot.style.transform = '';
                slot.style.opacity = '';
                slot.style.transition = '';
            }
            shuffleStatus.textContent = `「${YESNO_POSITIONS[0].name}」のカードを選んでください`;
        } else {
            shuffleStatus.textContent = `あと${requiredCards}枚選んでください`;
        }

        renderShuffleCards();
    }

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

            card.style.opacity = '0';
            card.style.transition = 'all 0.6s cubic-bezier(0.23, 1, 0.32, 1)';
            setTimeout(() => { card.style.opacity = '1'; }, i * 80);

            card.addEventListener('click', () => selectCard(card, i));
            shuffleArea.appendChild(card);
        }
    }

    // ========== カード選択 ==========
    function selectCard(cardEl, index) {
        if (cardEl.classList.contains('selected')) return;
        if (selectedCards.length >= requiredCards) return;
        cardEl.classList.add('selected');

        const deckIndex = index % shuffledDeck.length;
        const cardData = shuffledDeck[deckIndex];
        const isFiveCardObstacle = currentMode === 'five-card' && selectedCards.length === 1;
        const isReversed = isFiveCardObstacle ? false : Math.random() < 0.4;

        const cardInfo = { ...cardData, isReversed, meaning: isReversed ? cardData.reversed : cardData.upright };
        selectedCards.push(cardInfo);

        // カードをフェードアウト
        cardEl.style.opacity = '0';
        cardEl.style.transform = 'scale(0.8)';
        cardEl.style.pointerEvents = 'none';

        if (currentMode === 'two-card') {
            animateSlot('slotTwoCard', selectedCards.length - 1, cardInfo, false);
            if (selectedCards.length < requiredCards) {
                shuffleStatus.textContent = `「${TWO_CARD_POSITIONS[selectedCards.length].name}」のカードを選んでください`;
            } else {
                shuffleStatus.textContent = '全てのカードが選ばれました！';
            }
        } else if (currentMode === 'three-card') {
            animateSlot('slotCard', selectedCards.length - 1, cardInfo, false);
            const posNames = ['過去', '現在', '未来'];
            if (selectedCards.length < requiredCards) {
                shuffleStatus.textContent = `「${posNames[selectedCards.length]}」のカードを選んでください`;
            } else {
                shuffleStatus.textContent = '全てのカードが選ばれました！';
            }
        } else if (currentMode === 'five-card') {
            const slotIndex = selectedCards.length - 1;
            const isObstacle = slotIndex === 1;
            animateSlot('slotFive', slotIndex, cardInfo, isObstacle);
            if (selectedCards.length < requiredCards) {
                shuffleStatus.textContent = `「${FIVE_CARD_POSITIONS[selectedCards.length].name}」のカードを選んでください`;
            } else {
                shuffleStatus.textContent = '全てのカードが選ばれました！';
            }
        } else if (currentMode === 'two-choice') {
            animateSlot('slotTwo', selectedCards.length - 1, cardInfo, false);
            if (selectedCards.length < requiredCards) {
                shuffleStatus.textContent = `「${TWO_CHOICE_POSITIONS[selectedCards.length].name}」のカードを選んでください`;
            } else {
                shuffleStatus.textContent = '全てのカードが選ばれました！';
            }
        } else if (currentMode === 'hexagram') {
            animateSlot('slotHex', selectedCards.length - 1, cardInfo, false);
            if (selectedCards.length < requiredCards) {
                shuffleStatus.textContent = `「${HEXAGRAM_POSITIONS[selectedCards.length].name}」のカードを選んでください`;
            } else {
                shuffleStatus.textContent = '全てのカードが選ばれました！';
            }
        } else if (currentMode === 'horseshoe') {
            animateSlot('slotHorse', selectedCards.length - 1, cardInfo, false);
            if (selectedCards.length < requiredCards) {
                shuffleStatus.textContent = `「${HORSESHOE_POSITIONS[selectedCards.length].name}」のカードを選んでください`;
            } else {
                shuffleStatus.textContent = '全てのカードが選ばれました！';
            }
        } else if (currentMode === 'rel-cross') {
            animateSlot('slotRC', selectedCards.length - 1, cardInfo, false);
            if (selectedCards.length < requiredCards) {
                shuffleStatus.textContent = `「${REL_CROSS_POSITIONS[selectedCards.length].name}」のカードを選んでください`;
            } else {
                shuffleStatus.textContent = '全てのカードが選ばれました！';
            }
        } else if (currentMode === 'rel-mirror') {
            animateSlot('slotRM', selectedCards.length - 1, cardInfo, false);
            if (selectedCards.length < requiredCards) {
                shuffleStatus.textContent = `「${REL_MIRROR_POSITIONS[selectedCards.length].name}」のカードを選んでください`;
            } else {
                shuffleStatus.textContent = '全てのカードが選ばれました！';
            }
        } else if (currentMode === 'yesno') {
            animateSlot('slotYesno', selectedCards.length - 1, cardInfo, false);
            if (selectedCards.length < requiredCards) {
                shuffleStatus.textContent = `「${YESNO_POSITIONS[selectedCards.length].name}」のカードを選んでください`;
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
            const delay = (currentMode === 'one-card') ? 800 : 1800;
            setTimeout(() => startAnalyzing(), delay);
        }
    }

    function animateSlot(prefix, slotIndex, cardInfo, isObstacle) {
        const slot = document.getElementById(prefix + slotIndex);
        setTimeout(() => {
            const directionHtml = isObstacle ? '' : `
                <span style="font-size:0.55rem;font-weight:700;padding:1px 5px;border-radius:8px;color:${cardInfo.isReversed ? '#e74c3c' : '#2ecc71'};background:${cardInfo.isReversed ? 'rgba(231,76,60,0.15)' : 'rgba(46,204,113,0.15)'};">
                    ${cardInfo.isReversed ? '逆位置' : '正位置'}
                </span>`;
            slot.innerHTML = `
                <div style="font-size:${isObstacle ? '1.2rem' : '1.5rem'};">${cardInfo.emoji}</div>
                <div style="font-size:0.6rem;font-weight:700;color:#e0d0f0;margin:2px 0 1px;">${cardInfo.name}</div>
                ${directionHtml}
            `;
            slot.style.border = '2px solid rgba(241,196,15,0.6)';
            slot.style.background = 'linear-gradient(135deg, #2c1654, #4a1a7a)';
            slot.style.boxShadow = '0 4px 16px rgba(155,89,182,0.3)';
            const baseTransform = isObstacle ? 'rotate(-12deg)' : '';
            slot.style.transform = baseTransform + ' scale(0.5)';
            slot.style.opacity = '0';
            requestAnimationFrame(() => {
                slot.style.transition = 'transform 0.4s ease, opacity 0.4s ease';
                slot.style.transform = baseTransform + ' scale(1)';
                slot.style.opacity = '1';
            });
        }, 300);
    }

    // ========== 分析中 ==========
    function startAnalyzing() {
        showOnly('analyzingSection');
        const statuses = [
            '星の配置を確認中...',
            'カードの意味を読み取っています...',
            '過去と未来の繋がりを分析中...',
            '宇宙のメッセージを受信中...',
            '鑑定結果をまとめています...'
        ];
        const aiPromise = callAI();
        let i = 0;
        const interval = setInterval(() => {
            if (i < statuses.length) analyzingStatus.textContent = statuses[i];
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

    // ========== AI API呼び出し ==========
    async function callAI() {
        try {
            const controller = new AbortController();
            const timeoutId = setTimeout(() => controller.abort(), 25000);

            const cardsPayload = selectedCards.map(c => ({
                name: c.name, isReversed: c.isReversed, meaning: c.meaning
            }));

            const payload = {
                app: 'tarot-reading',
                params: {
                    mode: currentMode,
                    cards: cardsPayload,
                    consultation: {
                        category: consultationData.category,
                        situation: consultationData.situation,
                        question: consultationData.question,
                        note: consultationData.note
                    }
                }
            };

            if (currentMode === 'two-choice') {
                payload.params.choiceA = consultationData.choiceA || '';
                payload.params.choiceB = consultationData.choiceB || '';
            }

            const response = await fetch(API_URL + '/api/generate', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload),
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

    // ========== タイプライター演出 ==========
    function typeWriter(element, text, speed = 30) {
        return new Promise(resolve => {
            typewriterSkip = false;
            let i = 0;
            element.textContent = '';
            element.style.cursor = 'pointer';

            const skipHandler = () => {
                typewriterSkip = true;
            };
            element.addEventListener('click', skipHandler, { once: true });

            const timer = setInterval(() => {
                if (typewriterSkip || i >= text.length) {
                    clearInterval(timer);
                    element.textContent = text;
                    element.style.cursor = '';
                    element.removeEventListener('click', skipHandler);
                    resolve();
                    return;
                }
                element.textContent += text[i];
                i++;
            }, speed);
        });
    }

    // ========== 結果表示 ==========
    async function showResult(aiData) {
        showOnly('resultSection');
        window.scrollTo({ top: 0, behavior: 'smooth' });

        const modeLabels = {
            'one-card': '🎴 ワンオラクル',
            'two-card': '🎴 ツーカード（現状・対策）',
            'three-card': '🎴 3枚引き（過去・現在・未来）',
            'five-card': '🎴 5枚引き（ケルト十字簡易版）',
            'two-choice': '🎴 2者択一',
            'hexagram': '✡️ ヘキサグラム（六芒星）',
            'horseshoe': '🧲 ホースシュー（馬蹄形）',
            'rel-cross': '💕 リレーションシップクロス（恋愛）',
            'rel-mirror': '🪞 ミラースプレッド（恋愛深層）',
            'yesno': '⚖️ Yes/Noスプレッド'
        };

        resultModeLabel.textContent = modeLabels[currentMode] || currentMode;
        resultTitle.textContent = 'タロット鑑定結果';

        renderDrawnCards();

        if (currentMode === 'one-card') {
            await renderOneCardResult(aiData);
        } else if (currentMode === 'two-card') {
            await renderTwoCardResult(aiData);
        } else if (currentMode === 'three-card') {
            await renderThreeCardResult(aiData);
        } else if (currentMode === 'two-choice') {
            await renderTwoChoiceResult(aiData);
        } else if (currentMode === 'hexagram') {
            await renderHexagramResult(aiData);
        } else if (currentMode === 'horseshoe') {
            await renderHorseshoeResult(aiData);
        } else if (currentMode === 'rel-cross') {
            await renderRelCrossResult(aiData);
        } else if (currentMode === 'rel-mirror') {
            await renderRelMirrorResult(aiData);
        } else if (currentMode === 'yesno') {
            await renderYesNoResult(aiData);
        } else {
            await renderFiveCardResult(aiData);
        }

        // 履歴保存
        saveToHistory(aiData);
    }

    // ========== カードフリップ表示 ==========
    function renderDrawnCards() {
        drawnCards.innerHTML = '';
        drawnCards.classList.remove('v-shape-layout', 'hexagram-layout', 'horseshoe-layout', 'rel-cross-layout', 'rel-mirror-layout');
        if (currentMode === 'two-choice') {
            drawnCards.classList.add('v-shape-layout');
        } else if (currentMode === 'hexagram') {
            drawnCards.classList.add('hexagram-layout');
        } else if (currentMode === 'horseshoe') {
            drawnCards.classList.add('horseshoe-layout');
        } else if (currentMode === 'rel-cross') {
            drawnCards.classList.add('rel-cross-layout');
        } else if (currentMode === 'rel-mirror') {
            drawnCards.classList.add('rel-mirror-layout');
        }
        const positions = currentMode === 'two-card' ? TWO_CARD_POSITIONS
            : currentMode === 'three-card' ? THREE_CARD_POSITIONS
            : currentMode === 'five-card' ? FIVE_CARD_POSITIONS
            : currentMode === 'two-choice' ? TWO_CHOICE_POSITIONS
            : currentMode === 'hexagram' ? HEXAGRAM_POSITIONS
            : currentMode === 'horseshoe' ? HORSESHOE_POSITIONS
            : currentMode === 'rel-cross' ? REL_CROSS_POSITIONS
            : currentMode === 'rel-mirror' ? REL_MIRROR_POSITIONS
            : currentMode === 'yesno' ? YESNO_POSITIONS
            : [{ name: '今日のカード', icon: '🔮' }];

        selectedCards.forEach((card, i) => {
            const flipContainer = document.createElement('div');
            flipContainer.className = 'drawn-card-flip';
            flipContainer.style.animationDelay = (i * 0.3) + 's';

            const isFiveCardObstacle = currentMode === 'five-card' && i === 1;
            const directionHtml = isFiveCardObstacle ? '' : `
                <span class="card-direction ${card.isReversed ? 'reversed' : 'upright'}">
                    ${card.isReversed ? '逆位置 ↓' : '正位置 ↑'}
                </span>`;

            flipContainer.innerHTML = `
                <div class="position-label">${positions[i].icon} ${positions[i].name}</div>
                <div class="flip-card">
                    <div class="flip-card-inner">
                        <div class="flip-card-back">
                            <span class="flip-back-symbol">✦</span>
                        </div>
                        <div class="flip-card-front">
                            <div class="card-emoji">${card.emoji}</div>
                            <div class="card-name">${card.name}</div>
                            ${directionHtml}
                            <div class="card-meaning">${card.meaning}</div>
                        </div>
                    </div>
                </div>
            `;
            drawnCards.appendChild(flipContainer);

            // Trigger flip after staggered delay
            setTimeout(() => {
                flipContainer.querySelector('.flip-card').classList.add('flipped');
            }, 300 + i * 300);
        });
    }

    // ========== 1枚引き結果 ==========
    async function renderOneCardResult(aiData) {
        readingSection.innerHTML = `
            <div class="reading-block">
                <div class="block-title">🔮 カードからのメッセージ</div>
                <div class="block-text" id="tw-overall"></div>
            </div>
        `;
        const overallMsg = aiData?.overall || getStaticOverall();
        await typeWriter(document.getElementById('tw-overall'), overallMsg);

        const advice = aiData?.advice || getStaticAdvice();
        overallReading.innerHTML = '';
        overallReading.style.display = 'none';
        adviceBox.innerHTML = `
            <div class="advice-label">💡 今日のアドバイス</div>
            <div class="advice-text" id="tw-advice"></div>
        `;
        await typeWriter(document.getElementById('tw-advice'), advice);

        luckyItems.innerHTML = '';
        if (aiData?.lucky_color || aiData?.lucky_number) {
            let html = '';
            if (aiData.lucky_color) html += `<div class="lucky-item"><div class="lucky-label">ラッキーカラー</div><div class="lucky-value">${aiData.lucky_color}</div></div>`;
            if (aiData.lucky_number) html += `<div class="lucky-item"><div class="lucky-label">ラッキーナンバー</div><div class="lucky-value">${aiData.lucky_number}</div></div>`;
            luckyItems.innerHTML = html;
        }
    }

    // ========== 2枚引き結果 ==========
    async function renderTwoCardResult(aiData) {
        readingSection.innerHTML = '';

        if (aiData) {
            const blocks = [
                { title: '🔵 現在の状況', key: 'current' },
                { title: '💡 対策・アドバイス', key: 'countermeasure' },
                { title: '🔗 2枚のカードの関係性', key: 'relationship' }
            ];
            for (const b of blocks) {
                if (aiData[b.key]) {
                    readingSection.innerHTML += `
                        <div class="reading-block">
                            <div class="block-title">${b.title}</div>
                            <div class="block-text" id="tw-2c-${b.key}"></div>
                        </div>
                    `;
                }
            }
            for (const b of blocks) {
                if (aiData[b.key]) {
                    await typeWriter(document.getElementById('tw-2c-' + b.key), aiData[b.key]);
                }
            }
        }

        const overall = aiData?.overall || getStaticOverall();
        overallReading.innerHTML = `
            <div class="overall-title">✨ 総合メッセージ</div>
            <div class="overall-text" id="tw-2c-overall"></div>
        `;
        overallReading.style.display = '';
        await typeWriter(document.getElementById('tw-2c-overall'), overall);

        const advice = aiData?.advice || getStaticAdvice();
        adviceBox.innerHTML = `
            <div class="advice-label">💡 アドバイス</div>
            <div class="advice-text" id="tw-2c-advice"></div>
        `;
        await typeWriter(document.getElementById('tw-2c-advice'), advice);
        luckyItems.innerHTML = '';
    }

    // ========== 3枚引き結果 ==========
    async function renderThreeCardResult(aiData) {
        readingSection.innerHTML = '';

        if (aiData) {
            const blocks = [
                { title: '⏪ 過去', key: 'past' },
                { title: '🔵 現在', key: 'present' },
                { title: '⏩ 未来', key: 'future' }
            ];
            for (const b of blocks) {
                if (aiData[b.key]) {
                    const id = 'tw-' + b.key;
                    readingSection.innerHTML += `
                        <div class="reading-block">
                            <div class="block-title">${b.title}</div>
                            <div class="block-text" id="${id}"></div>
                        </div>
                    `;
                }
            }
            for (const b of blocks) {
                if (aiData[b.key]) {
                    await typeWriter(document.getElementById('tw-' + b.key), aiData[b.key]);
                }
            }
        }

        // 総合メッセージ
        if (isPWA) {
            const overall = aiData?.overall || getStaticOverall();
            overallReading.innerHTML = `
                <div class="overall-title">✨ 総合メッセージ</div>
                <div class="overall-text" id="tw-3overall"></div>
            `;
            overallReading.style.display = '';
            await typeWriter(document.getElementById('tw-3overall'), overall);
        } else {
            overallReading.innerHTML = `
                <div class="overall-title">✨ 総合メッセージ</div>
                <div class="overall-locked" style="text-align:center;padding:24px 16px;background:rgba(155,89,182,0.08);border:1px dashed rgba(155,89,182,0.3);border-radius:12px;margin:8px 0;">
                    <p style="color:#c89cf5;font-size:1rem;margin-bottom:12px;">3枚のカードを通した詳細な総合鑑定をお届けします</p>
                    <button id="unlockOverallBtn" style="background:linear-gradient(135deg,#9b59b6,#8e44ad);color:#fff;border:none;padding:14px 32px;border-radius:8px;font-size:1rem;cursor:pointer;font-weight:bold;transition:transform 0.2s,box-shadow 0.2s;box-shadow:0 4px 15px rgba(155,89,182,0.3);">
                        🔮 総合鑑定を見る：100円
                    </button>
                </div>
            `;
            overallReading.style.display = '';
            document.getElementById('unlockOverallBtn').addEventListener('click', () => {
                startThreeCardCheckout(aiData);
            });
        }

        const advice = aiData?.advice || getStaticAdvice();
        adviceBox.innerHTML = `
            <div class="advice-label">💡 アドバイス</div>
            <div class="advice-text" id="tw-3advice"></div>
        `;
        await typeWriter(document.getElementById('tw-3advice'), advice);
        luckyItems.innerHTML = '';
    }

    // ========== 2者択一結果 ==========
    async function renderTwoChoiceResult(aiData) {
        readingSection.innerHTML = '';

        const choiceALabel = consultationData.choiceA || '選択肢A';
        const choiceBLabel = consultationData.choiceB || '選択肢B';

        if (aiData) {
            const blocks = [
                { title: `🔵 現在の状況`, key: 'current' },
                { title: `🅰️ ${choiceALabel} の展望`, key: 'choice_a' },
                { title: `🅱️ ${choiceBLabel} の展望`, key: 'choice_b' },
                { title: '🔮 どちらが有利か', key: 'recommendation' }
            ];
            for (const b of blocks) {
                if (aiData[b.key]) {
                    readingSection.innerHTML += `
                        <div class="reading-block">
                            <div class="block-title">${b.title}</div>
                            <div class="block-text" id="tw-tc-${b.key}"></div>
                        </div>
                    `;
                }
            }
            for (const b of blocks) {
                if (aiData[b.key]) {
                    await typeWriter(document.getElementById('tw-tc-' + b.key), aiData[b.key]);
                }
            }
        }

        const overall = aiData?.overall || getStaticOverall();
        overallReading.innerHTML = `
            <div class="overall-title">✨ 総合メッセージ</div>
            <div class="overall-text" id="tw-tc-overall"></div>
        `;
        overallReading.style.display = '';
        await typeWriter(document.getElementById('tw-tc-overall'), overall);

        const advice = aiData?.advice || getStaticAdvice();
        adviceBox.innerHTML = `
            <div class="advice-label">💡 アドバイス</div>
            <div class="advice-text" id="tw-tc-advice"></div>
        `;
        await typeWriter(document.getElementById('tw-tc-advice'), advice);
        luckyItems.innerHTML = '';
    }

    // ========== 5枚引き結果 ==========
    async function renderFiveCardResult(aiData) {
        readingSection.innerHTML = '';

        if (aiData) {
            const blocks = [
                { title: '🔵 現在の状況', key: 'current' },
                { title: '🔴 障害・課題', key: 'obstacle' },
                { title: '⏪ 過去の影響', key: 'past_influence' },
                { title: '⏩ 未来の可能性', key: 'future_potential' },
                { title: '⭐ 最終結論', key: 'conclusion' }
            ];
            for (const b of blocks) {
                if (aiData[b.key]) {
                    readingSection.innerHTML += `
                        <div class="reading-block">
                            <div class="block-title">${b.title}</div>
                            <div class="block-text" id="tw-5-${b.key}"></div>
                        </div>
                    `;
                }
            }
            for (const b of blocks) {
                if (aiData[b.key]) {
                    await typeWriter(document.getElementById('tw-5-' + b.key), aiData[b.key]);
                }
            }

            if (aiData.obstacle_advice) {
                readingSection.innerHTML += `
                    <div class="reading-block" style="border-left:3px solid #f1c40f;background:linear-gradient(135deg,rgba(241,196,15,0.08),rgba(155,89,182,0.08));">
                        <div class="block-title">🔑 最終結論を良き結果にするために</div>
                        <div class="block-text" id="tw-5-oa"></div>
                    </div>
                `;
                await typeWriter(document.getElementById('tw-5-oa'), aiData.obstacle_advice);
            }
        }

        const overall = aiData?.overall || getStaticOverall();
        overallReading.innerHTML = `
            <div class="overall-title">✨ 総合鑑定</div>
            <div class="overall-text" id="tw-5-overall"></div>
        `;
        overallReading.style.display = '';
        await typeWriter(document.getElementById('tw-5-overall'), overall);

        const advice = aiData?.advice || getStaticAdvice();
        adviceBox.innerHTML = `
            <div class="advice-label">💡 具体的なアクションアドバイス</div>
            <div class="advice-text" id="tw-5-advice"></div>
        `;
        await typeWriter(document.getElementById('tw-5-advice'), advice);

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

    // ========== ヘキサグラム結果 ==========
    async function renderHexagramResult(aiData) {
        readingSection.innerHTML = '';

        if (aiData) {
            const blocks = [
                { title: '⏪ 過去', key: 'past' },
                { title: '🔵 現在', key: 'present' },
                { title: '⏩ 近未来', key: 'near_future' },
                { title: '🔑 アドバイス・対策', key: 'countermeasure' },
                { title: '🌍 お相手の気持ち・周囲の環境', key: 'environment' },
                { title: '💜 本人の気持ち', key: 'inner_feelings' },
                { title: '⭐ 最終結果', key: 'final_result' }
            ];
            for (const b of blocks) {
                if (aiData[b.key]) {
                    readingSection.innerHTML += `
                        <div class="reading-block">
                            <div class="block-title">${b.title}</div>
                            <div class="block-text" id="tw-hex-${b.key}"></div>
                        </div>
                    `;
                }
            }
            for (const b of blocks) {
                if (aiData[b.key]) {
                    await typeWriter(document.getElementById('tw-hex-' + b.key), aiData[b.key]);
                }
            }
        }

        const overall = aiData?.overall || getStaticOverall();
        overallReading.innerHTML = `
            <div class="overall-title">✨ 総合鑑定</div>
            <div class="overall-text" id="tw-hex-overall"></div>
        `;
        overallReading.style.display = '';
        await typeWriter(document.getElementById('tw-hex-overall'), overall);

        const advice = aiData?.advice || getStaticAdvice();
        adviceBox.innerHTML = `
            <div class="advice-label">💡 具体的なアクションアドバイス</div>
            <div class="advice-text" id="tw-hex-advice"></div>
        `;
        await typeWriter(document.getElementById('tw-hex-advice'), advice);

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

    // ========== ホースシュー結果 ==========
    async function renderHorseshoeResult(aiData) {
        readingSection.innerHTML = '';

        if (aiData) {
            const blocks = [
                { title: '⏪ 過去', key: 'past' },
                { title: '🔵 現在', key: 'present' },
                { title: '⏩ 未来', key: 'future' },
                { title: '💡 アドバイス', key: 'advice_card' },
                { title: '🌍 周囲の影響', key: 'others_influence' },
                { title: '🔴 障害・課題', key: 'obstacles' },
                { title: '⭐ 最終結果', key: 'outcome' }
            ];
            for (const b of blocks) {
                if (aiData[b.key]) {
                    readingSection.innerHTML += `
                        <div class="reading-block">
                            <div class="block-title">${b.title}</div>
                            <div class="block-text" id="tw-hs-${b.key}"></div>
                        </div>
                    `;
                }
            }
            for (const b of blocks) {
                if (aiData[b.key]) {
                    await typeWriter(document.getElementById('tw-hs-' + b.key), aiData[b.key]);
                }
            }
        }

        const overall = aiData?.overall || getStaticOverall();
        overallReading.innerHTML = `
            <div class="overall-title">✨ 総合鑑定</div>
            <div class="overall-text" id="tw-hs-overall"></div>
        `;
        overallReading.style.display = '';
        await typeWriter(document.getElementById('tw-hs-overall'), overall);

        const advice = aiData?.advice || getStaticAdvice();
        adviceBox.innerHTML = `
            <div class="advice-label">💡 具体的なアクションアドバイス</div>
            <div class="advice-text" id="tw-hs-advice"></div>
        `;
        await typeWriter(document.getElementById('tw-hs-advice'), advice);

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

    // ========== リレーションシップ結果 ==========
    async function renderRelCrossResult(aiData) {
        readingSection.innerHTML = '';

        if (aiData) {
            const blocks = [
                { title: '💜 あなた', key: 'you' },
                { title: '💙 お相手', key: 'partner' },
                { title: '⏪ 過去・基盤', key: 'past' },
                { title: '🔗 現在の関係', key: 'present' },
                { title: '⭐ 未来の方向', key: 'future' }
            ];
            for (const b of blocks) {
                if (aiData[b.key]) {
                    readingSection.innerHTML += `
                        <div class="reading-block">
                            <div class="block-title">${b.title}</div>
                            <div class="block-text" id="tw-rc-${b.key}"></div>
                        </div>
                    `;
                }
            }
            for (const b of blocks) {
                if (aiData[b.key]) {
                    await typeWriter(document.getElementById('tw-rc-' + b.key), aiData[b.key]);
                }
            }
        }

        const overall = aiData?.overall || getStaticOverall();
        overallReading.innerHTML = `
            <div class="overall-title">✨ 総合鑑定</div>
            <div class="overall-text" id="tw-rc-overall"></div>
        `;
        overallReading.style.display = '';
        await typeWriter(document.getElementById('tw-rc-overall'), overall);

        const advice = aiData?.advice || getStaticAdvice();
        adviceBox.innerHTML = `
            <div class="advice-label">💡 具体的なアクションアドバイス</div>
            <div class="advice-text" id="tw-rc-advice"></div>
        `;
        await typeWriter(document.getElementById('tw-rc-advice'), advice);

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

    async function renderRelMirrorResult(aiData) {
        readingSection.innerHTML = '';

        if (aiData) {
            const blocks = [
                { title: '🔗 関係のテーマ', key: 'theme' },
                { title: '💭 あなたの思考', key: 'your_thoughts' },
                { title: '💜 あなたの感情', key: 'your_feelings' },
                { title: '🌸 あなたの行動', key: 'your_actions' },
                { title: '💭 お相手の思考', key: 'partner_thoughts' },
                { title: '💙 お相手の感情', key: 'partner_feelings' },
                { title: '🌊 お相手の行動', key: 'partner_actions' }
            ];
            for (const b of blocks) {
                if (aiData[b.key]) {
                    readingSection.innerHTML += `
                        <div class="reading-block">
                            <div class="block-title">${b.title}</div>
                            <div class="block-text" id="tw-rm-${b.key}"></div>
                        </div>
                    `;
                }
            }
            for (const b of blocks) {
                if (aiData[b.key]) {
                    await typeWriter(document.getElementById('tw-rm-' + b.key), aiData[b.key]);
                }
            }
        }

        const overall = aiData?.overall || getStaticOverall();
        overallReading.innerHTML = `
            <div class="overall-title">✨ 総合鑑定</div>
            <div class="overall-text" id="tw-rm-overall"></div>
        `;
        overallReading.style.display = '';
        await typeWriter(document.getElementById('tw-rm-overall'), overall);

        const advice = aiData?.advice || getStaticAdvice();
        adviceBox.innerHTML = `
            <div class="advice-label">💡 具体的なアクションアドバイス</div>
            <div class="advice-text" id="tw-rm-advice"></div>
        `;
        await typeWriter(document.getElementById('tw-rm-advice'), advice);

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

    // ========== Yes/No結果 ==========
    async function renderYesNoResult(aiData) {
        readingSection.innerHTML = '';

        // Yes/No判定バナー
        if (aiData?.verdict) {
            const v = aiData.verdict.toLowerCase();
            const cls = v.includes('yes') ? 'yes' : v.includes('no') ? 'no' : 'maybe';
            const label = v.includes('yes') ? '⭕ YES' : v.includes('no') ? '❌ NO' : '🔮 MAYBE';
            readingSection.innerHTML += `
                <div class="yesno-verdict ${cls}">
                    <div class="verdict-label">${label}</div>
                    <div class="verdict-reason" id="tw-yn-reason"></div>
                </div>
            `;
        }

        if (aiData) {
            const blocks = [
                { title: '⭕ 賛成の力（Yesに導くカード）', key: 'pro' },
                { title: '❌ 反対の力（Noに導くカード）', key: 'con' },
                { title: '⚖️ 結論カードの解釈', key: 'conclusion' }
            ];
            for (const b of blocks) {
                if (aiData[b.key]) {
                    readingSection.innerHTML += `
                        <div class="reading-block">
                            <div class="block-title">${b.title}</div>
                            <div class="block-text" id="tw-yn-${b.key}"></div>
                        </div>
                    `;
                }
            }

            // タイプライター: まず判定理由
            if (aiData.verdict_reason) {
                await typeWriter(document.getElementById('tw-yn-reason'), aiData.verdict_reason);
            }
            for (const b of blocks) {
                if (aiData[b.key]) {
                    await typeWriter(document.getElementById('tw-yn-' + b.key), aiData[b.key]);
                }
            }
        }

        const overall = aiData?.overall || getStaticOverall();
        overallReading.innerHTML = `
            <div class="overall-title">✨ 総合メッセージ</div>
            <div class="overall-text" id="tw-yn-overall"></div>
        `;
        overallReading.style.display = '';
        await typeWriter(document.getElementById('tw-yn-overall'), overall);

        const advice = aiData?.advice || getStaticAdvice();
        adviceBox.innerHTML = `
            <div class="advice-label">💡 アドバイス</div>
            <div class="advice-text" id="tw-yn-advice"></div>
        `;
        await typeWriter(document.getElementById('tw-yn-advice'), advice);
        luckyItems.innerHTML = '';
    }

    // ========== Stripe Checkout（3枚引き） ==========
    async function startThreeCardCheckout(aiData) {
        try {
            const saveData = {
                cards: selectedCards.map(c => ({ name: c.name, emoji: c.emoji, isReversed: c.isReversed, meaning: c.meaning })),
                aiData: { past: aiData?.past || '', present: aiData?.present || '', future: aiData?.future || '', advice: aiData?.advice || '' },
                timestamp: Date.now()
            };
            localStorage.setItem('tarot_three_card_data', JSON.stringify(saveData));

            const response = await fetch(API_URL + '/api/stripe/create-checkout', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ app: 'tarot-reading', mode: 'three-card' })
            });
            if (!response.ok) throw new Error('Checkout creation failed');
            const data = await response.json();
            if (data.url) { window.location.href = data.url; } else { throw new Error('No checkout URL'); }
        } catch (e) {
            console.error('Stripe error:', e);
            showToast('決済の準備に失敗しました。もう一度お試しください。');
        }
    }

    // ========== 静的フォールバック ==========
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

    // ========== 鑑定履歴 ==========
    function saveToHistory(aiData) {
        try {
            const history = JSON.parse(localStorage.getItem('tarot_history') || '[]');
            const entry = {
                id: Date.now(),
                date: new Date().toISOString(),
                mode: currentMode,
                consultation: { ...consultationData },
                cards: selectedCards.map(c => ({ id: c.id, name: c.name, emoji: c.emoji, isReversed: c.isReversed, meaning: c.meaning })),
                aiData: aiData
            };
            history.unshift(entry);
            if (history.length > 20) history.length = 20;
            localStorage.setItem('tarot_history', JSON.stringify(history));
        } catch (e) {
            console.log('History save failed:', e);
        }
    }

    function loadHistory() {
        try {
            return JSON.parse(localStorage.getItem('tarot_history') || '[]');
        } catch (e) {
            return [];
        }
    }

    function renderHistoryList() {
        const container = document.getElementById('historyList');
        const history = loadHistory();
        if (history.length === 0) {
            container.innerHTML = '<p style="color:#999;text-align:center;padding:40px 0;">まだ鑑定履歴がありません</p>';
            return;
        }
        const modeLabels = {
            'one-card': '1枚引き', 'two-card': '2枚引き',
            'three-card': '3枚引き', 'five-card': '5枚引き',
            'two-choice': '2者択一', 'hexagram': 'ヘキサグラム',
            'horseshoe': 'ホースシュー', 'rel-cross': 'Rクロス',
            'rel-mirror': 'ミラー', 'relationship': 'リレーションシップ',
            'yesno': 'Yes/No'
        };
        container.innerHTML = history.map(h => {
            const date = new Date(h.date);
            const dateStr = `${date.getMonth() + 1}/${date.getDate()} ${date.getHours()}:${String(date.getMinutes()).padStart(2, '0')}`;
            const firstCard = h.cards[0];
            const cat = h.consultation?.category || '';
            return `
                <div class="history-item" data-id="${h.id}">
                    <div class="history-date">${dateStr}</div>
                    <div class="history-info">
                        <span class="history-mode">${modeLabels[h.mode] || h.mode}</span>
                        ${cat ? `<span class="history-cat">${cat}</span>` : ''}
                    </div>
                    <div class="history-card">${firstCard.emoji} ${firstCard.name}（${firstCard.isReversed ? '逆' : '正'}）</div>
                </div>
            `;
        }).join('');

        container.querySelectorAll('.history-item').forEach(item => {
            item.addEventListener('click', () => {
                const id = parseInt(item.dataset.id);
                showHistoryDetail(id);
            });
        });
    }

    function showHistoryDetail(id) {
        const history = loadHistory();
        const entry = history.find(h => h.id === id);
        if (!entry) return;

        // 状態を復元して結果を再表示
        currentMode = entry.mode;
        selectedCards = entry.cards;
        consultationData = entry.consultation || { category: '', situation: '', question: '', note: '' };
        requiredCards = selectedCards.length;

        showOnly('resultSection');
        window.scrollTo({ top: 0, behavior: 'smooth' });

        const modeLabels = {
            'one-card': '🎴 ワンオラクル', 'two-card': '🎴 ツーカード',
            'three-card': '🎴 3枚引き', 'five-card': '🎴 5枚引き',
            'two-choice': '🎴 2者択一', 'hexagram': '✡️ ヘキサグラム',
            'horseshoe': '🧲 ホースシュー', 'rel-cross': '💕 Rクロス',
            'rel-mirror': '🪞 ミラースプレッド', 'relationship': '💕 リレーションシップ',
            'yesno': '⚖️ Yes/No'
        };
        resultModeLabel.textContent = modeLabels[currentMode] || currentMode;
        resultTitle.textContent = 'タロット鑑定結果（履歴）';

        renderDrawnCards();

        // 履歴表示はタイプライターなしで即表示
        renderHistoryResult(entry.aiData);
    }

    function renderHistoryResult(aiData) {
        readingSection.innerHTML = '';
        overallReading.innerHTML = '';
        overallReading.style.display = 'none';
        adviceBox.innerHTML = '';
        luckyItems.innerHTML = '';

        if (!aiData) return;

        if (currentMode === 'one-card') {
            if (aiData.overall) readingSection.innerHTML = `<div class="reading-block"><div class="block-title">🔮 カードからのメッセージ</div><div class="block-text">${aiData.overall}</div></div>`;
            if (aiData.advice) adviceBox.innerHTML = `<div class="advice-label">💡 今日のアドバイス</div><div class="advice-text">${aiData.advice}</div>`;
        } else if (currentMode === 'two-card') {
            ['current', 'countermeasure', 'relationship'].forEach(k => {
                const titles = { current: '🔵 現在の状況', countermeasure: '💡 対策・アドバイス', relationship: '🔗 2枚のカードの関係性' };
                if (aiData[k]) readingSection.innerHTML += `<div class="reading-block"><div class="block-title">${titles[k]}</div><div class="block-text">${aiData[k]}</div></div>`;
            });
            if (aiData.overall) { overallReading.innerHTML = `<div class="overall-title">✨ 総合メッセージ</div><div class="overall-text">${aiData.overall}</div>`; overallReading.style.display = ''; }
            if (aiData.advice) adviceBox.innerHTML = `<div class="advice-label">💡 アドバイス</div><div class="advice-text">${aiData.advice}</div>`;
        } else if (currentMode === 'three-card') {
            ['past', 'present', 'future'].forEach((k, i) => {
                const titles = ['⏪ 過去', '🔵 現在', '⏩ 未来'];
                if (aiData[k]) readingSection.innerHTML += `<div class="reading-block"><div class="block-title">${titles[i]}</div><div class="block-text">${aiData[k]}</div></div>`;
            });
            if (aiData.overall) { overallReading.innerHTML = `<div class="overall-title">✨ 総合メッセージ</div><div class="overall-text">${aiData.overall}</div>`; overallReading.style.display = ''; }
            if (aiData.advice) adviceBox.innerHTML = `<div class="advice-label">💡 アドバイス</div><div class="advice-text">${aiData.advice}</div>`;
        } else if (currentMode === 'two-choice') {
            ['current', 'choice_a', 'choice_b', 'recommendation'].forEach(k => {
                const titles = { current: '🔵 現在の状況', choice_a: '🅰️ 選択肢Aの展望', choice_b: '🅱️ 選択肢Bの展望', recommendation: '🔮 どちらが有利か' };
                if (aiData[k]) readingSection.innerHTML += `<div class="reading-block"><div class="block-title">${titles[k]}</div><div class="block-text">${aiData[k]}</div></div>`;
            });
            if (aiData.overall) { overallReading.innerHTML = `<div class="overall-title">✨ 総合メッセージ</div><div class="overall-text">${aiData.overall}</div>`; overallReading.style.display = ''; }
            if (aiData.advice) adviceBox.innerHTML = `<div class="advice-label">💡 アドバイス</div><div class="advice-text">${aiData.advice}</div>`;
        } else if (currentMode === 'hexagram') {
            ['past', 'present', 'near_future', 'countermeasure', 'environment', 'inner_feelings', 'final_result'].forEach(k => {
                const titles = { past: '⏪ 過去', present: '🔵 現在', near_future: '⏩ 近未来', countermeasure: '🔑 アドバイス・対策', environment: '🌍 お相手の気持ち・周囲の環境', inner_feelings: '💜 本人の気持ち', final_result: '⭐ 最終結果' };
                if (aiData[k]) readingSection.innerHTML += `<div class="reading-block"><div class="block-title">${titles[k]}</div><div class="block-text">${aiData[k]}</div></div>`;
            });
            if (aiData.overall) { overallReading.innerHTML = `<div class="overall-title">✨ 総合鑑定</div><div class="overall-text">${aiData.overall}</div>`; overallReading.style.display = ''; }
            if (aiData.advice) adviceBox.innerHTML = `<div class="advice-label">💡 具体的なアクションアドバイス</div><div class="advice-text">${aiData.advice}</div>`;
        } else if (currentMode === 'horseshoe') {
            ['past', 'present', 'future', 'advice_card', 'others_influence', 'obstacles', 'outcome'].forEach(k => {
                const titles = { past: '⏪ 過去', present: '🔵 現在', future: '⏩ 未来', advice_card: '💡 アドバイス', others_influence: '🌍 周囲の影響', obstacles: '🔴 障害・課題', outcome: '⭐ 最終結果' };
                if (aiData[k]) readingSection.innerHTML += `<div class="reading-block"><div class="block-title">${titles[k]}</div><div class="block-text">${aiData[k]}</div></div>`;
            });
            if (aiData.overall) { overallReading.innerHTML = `<div class="overall-title">✨ 総合鑑定</div><div class="overall-text">${aiData.overall}</div>`; overallReading.style.display = ''; }
            if (aiData.advice) adviceBox.innerHTML = `<div class="advice-label">💡 具体的なアクションアドバイス</div><div class="advice-text">${aiData.advice}</div>`;
        } else if (currentMode === 'rel-cross') {
            ['you', 'partner', 'past', 'present', 'future'].forEach(k => {
                const titles = { you: '💜 あなた', partner: '💙 お相手', past: '⏪ 過去・基盤', present: '🔗 現在の関係', future: '⭐ 未来の方向' };
                if (aiData[k]) readingSection.innerHTML += `<div class="reading-block"><div class="block-title">${titles[k]}</div><div class="block-text">${aiData[k]}</div></div>`;
            });
            if (aiData.overall) { overallReading.innerHTML = `<div class="overall-title">✨ 総合鑑定</div><div class="overall-text">${aiData.overall}</div>`; overallReading.style.display = ''; }
            if (aiData.advice) adviceBox.innerHTML = `<div class="advice-label">💡 具体的なアクションアドバイス</div><div class="advice-text">${aiData.advice}</div>`;
        } else if (currentMode === 'rel-mirror') {
            ['theme', 'your_thoughts', 'your_feelings', 'your_actions', 'partner_thoughts', 'partner_feelings', 'partner_actions'].forEach(k => {
                const titles = { theme: '🔗 関係のテーマ', your_thoughts: '💭 あなたの思考', your_feelings: '💜 あなたの感情', your_actions: '🌸 あなたの行動', partner_thoughts: '💭 お相手の思考', partner_feelings: '💙 お相手の感情', partner_actions: '🌊 お相手の行動' };
                if (aiData[k]) readingSection.innerHTML += `<div class="reading-block"><div class="block-title">${titles[k]}</div><div class="block-text">${aiData[k]}</div></div>`;
            });
            if (aiData.overall) { overallReading.innerHTML = `<div class="overall-title">✨ 総合鑑定</div><div class="overall-text">${aiData.overall}</div>`; overallReading.style.display = ''; }
            if (aiData.advice) adviceBox.innerHTML = `<div class="advice-label">💡 具体的なアクションアドバイス</div><div class="advice-text">${aiData.advice}</div>`;
        } else if (currentMode === 'relationship') {
            // 旧リレーションシップ（履歴互換）
            ['your_feelings', 'partner_feelings', 'relationship_status', 'challenges', 'your_desires', 'partner_desires', 'relationship_future'].forEach(k => {
                const titles = { your_feelings: '💜 自分の気持ち', partner_feelings: '💙 相手の気持ち', relationship_status: '🔗 関係の現状', challenges: '🔴 障害・課題', your_desires: '🌸 自分の望み', partner_desires: '🌊 相手の望み', relationship_future: '⭐ 関係の未来' };
                if (aiData[k]) readingSection.innerHTML += `<div class="reading-block"><div class="block-title">${titles[k]}</div><div class="block-text">${aiData[k]}</div></div>`;
            });
            if (aiData.overall) { overallReading.innerHTML = `<div class="overall-title">✨ 総合鑑定</div><div class="overall-text">${aiData.overall}</div>`; overallReading.style.display = ''; }
            if (aiData.advice) adviceBox.innerHTML = `<div class="advice-label">💡 具体的なアクションアドバイス</div><div class="advice-text">${aiData.advice}</div>`;
        } else if (currentMode === 'yesno') {
            if (aiData.verdict) {
                const v = aiData.verdict.toLowerCase();
                const cls = v.includes('yes') ? 'yes' : v.includes('no') ? 'no' : 'maybe';
                const label = v.includes('yes') ? '⭕ YES' : v.includes('no') ? '❌ NO' : '🔮 MAYBE';
                readingSection.innerHTML += `<div class="yesno-verdict ${cls}"><div class="verdict-label">${label}</div><div class="verdict-reason">${aiData.verdict_reason || ''}</div></div>`;
            }
            ['pro', 'con', 'conclusion'].forEach(k => {
                const titles = { pro: '⭕ 賛成の力', con: '❌ 反対の力', conclusion: '⚖️ 結論' };
                if (aiData[k]) readingSection.innerHTML += `<div class="reading-block"><div class="block-title">${titles[k]}</div><div class="block-text">${aiData[k]}</div></div>`;
            });
            if (aiData.overall) { overallReading.innerHTML = `<div class="overall-title">✨ 総合メッセージ</div><div class="overall-text">${aiData.overall}</div>`; overallReading.style.display = ''; }
            if (aiData.advice) adviceBox.innerHTML = `<div class="advice-label">💡 アドバイス</div><div class="advice-text">${aiData.advice}</div>`;
        } else {
            ['current', 'obstacle', 'past_influence', 'future_potential', 'conclusion'].forEach(k => {
                const titles = { current: '🔵 現在の状況', obstacle: '🔴 障害・課題', past_influence: '⏪ 過去の影響', future_potential: '⏩ 未来の可能性', conclusion: '⭐ 最終結論' };
                if (aiData[k]) readingSection.innerHTML += `<div class="reading-block"><div class="block-title">${titles[k]}</div><div class="block-text">${aiData[k]}</div></div>`;
            });
            if (aiData.obstacle_advice) readingSection.innerHTML += `<div class="reading-block" style="border-left:3px solid #f1c40f;"><div class="block-title">🔑 最終結論を良き結果にするために</div><div class="block-text">${aiData.obstacle_advice}</div></div>`;
            if (aiData.overall) { overallReading.innerHTML = `<div class="overall-title">✨ 総合鑑定</div><div class="overall-text">${aiData.overall}</div>`; overallReading.style.display = ''; }
            if (aiData.advice) adviceBox.innerHTML = `<div class="advice-label">💡 具体的なアクションアドバイス</div><div class="advice-text">${aiData.advice}</div>`;
        }
    }

    // ========== シェア機能 ==========
    function getShareText() {
        const card = selectedCards[0];
        const modeText = { 'one-card': 'ワンオラクル', 'two-card': 'ツーカード', 'three-card': '3枚引き', 'five-card': '5枚引き', 'two-choice': '2者択一', 'hexagram': 'ヘキサグラム', 'horseshoe': 'ホースシュー', 'rel-cross': 'Rクロス', 'rel-mirror': 'ミラースプレッド', 'yesno': 'Yes/No' }[currentMode] || currentMode;
        return `🔮 AIタロット占い（${modeText}）\n${card.emoji} ${card.name}（${card.isReversed ? '逆位置' : '正位置'}）\n「${card.meaning}」\n`;
    }

    shareXBtn.addEventListener('click', () => {
        const text = getShareText();
        const url = encodeURIComponent(window.location.href);
        window.open(`https://x.com/intent/tweet?text=${encodeURIComponent(text)}&url=${url}`, '_blank');
    });

    shareLINEBtn.addEventListener('click', () => {
        const text = getShareText();
        const shareUrl = window.location.href;
        window.open(`https://social-plugins.line.me/lineit/share?url=${encodeURIComponent(shareUrl)}&text=${encodeURIComponent(text)}`, '_blank');
    });

    copyBtn.addEventListener('click', async () => {
        try {
            copyBtn.textContent = '📸 保存中...';
            copyBtn.disabled = true;
            const resultCard = document.querySelector('.result-card');
            const canvas = await html2canvas(resultCard, { backgroundColor: '#0a0a1a', scale: 2, useCORS: true });
            canvas.toBlob(blob => {
                const url = URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                a.download = 'tarot-result.png';
                a.click();
                URL.revokeObjectURL(url);
                showToast('画像を保存しました！');
                copyBtn.textContent = '📸 保存';
                copyBtn.disabled = false;
            }, 'image/png');
        } catch (e) {
            console.error('Screenshot failed:', e);
            showToast('保存に失敗しました');
            copyBtn.textContent = '📸 保存';
            copyBtn.disabled = false;
        }
    });

    // もう一度占う
    retryBtn.addEventListener('click', () => {
        showOnly('modeSection');
        selectedCards = [];
        currentMode = '';
        consultationData = { category: '', situation: '', question: '', note: '' };
        window.scrollTo({ top: 0, behavior: 'smooth' });
    });

    // 履歴「戻る」ボタン
    const historyBackBtn = document.getElementById('historyBackBtn');
    if (historyBackBtn) {
        historyBackBtn.addEventListener('click', () => {
            showOnly('modeSection');
        });
    }

    // トースト
    function showToast(msg) {
        toast.textContent = msg;
        toast.classList.add('show');
        setTimeout(() => toast.classList.remove('show'), 2500);
    }
});
