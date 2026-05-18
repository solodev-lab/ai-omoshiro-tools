// 名占（なうら）— メインロジック

document.addEventListener('DOMContentLoaded', () => {
    console.log('[名占] app.js loaded');
    // DOM要素
    const inputSection = document.getElementById('inputSection');
    const analyzingSection = document.getElementById('analyzingSection');
    const resultSection = document.getElementById('resultSection');
    const seiInput = document.getElementById('seiInput');
    const meiInput = document.getElementById('meiInput');
    const uranauBtn = document.getElementById('uranauBtn');
    const errorMsg = document.getElementById('errorMsg');
    const toast = document.getElementById('toast');

    // ── ひらがな変換テーブル ──

    // 濁音・半濁音→清音
    const DAKUTEN_MAP = {
        'が':'か','ぎ':'き','ぐ':'く','げ':'け','ご':'こ',
        'ざ':'さ','じ':'し','ず':'す','ぜ':'せ','ぞ':'そ',
        'だ':'た','ぢ':'ち','づ':'つ','で':'て','ど':'と',
        'ば':'は','び':'ひ','ぶ':'ふ','べ':'へ','ぼ':'ほ',
        'ぱ':'は','ぴ':'ひ','ぷ':'ふ','ぺ':'へ','ぽ':'ほ'
    };

    // 小文字→大文字
    const KOMOJI_MAP = {
        'ぁ':'あ','ぃ':'い','ぅ':'う','ぇ':'え','ぉ':'お',
        'っ':'つ','ゃ':'や','ゅ':'ゆ','ょ':'よ','ゎ':'わ'
    };

    // カタカナ→ひらがな変換（ユーザー便宜）
    function katakanaToHiragana(str) {
        return str.replace(/[\u30A1-\u30F6]/g, ch =>
            String.fromCharCode(ch.charCodeAt(0) - 0x60)
        ).replace(/\u30F3/g, 'ん'); // ン→ん
    }

    // 文字の正規化（濁音→清音、小文字→大文字）
    function normalize(ch) {
        if (DAKUTEN_MAP[ch]) ch = DAKUTEN_MAP[ch];
        if (KOMOJI_MAP[ch]) ch = KOMOJI_MAP[ch];
        return ch;
    }

    // 母音値（あ段=1, い段=2, う段=3, え段=4, お段=5）
    const VOWEL_MAP = {
        'あ':1,'い':2,'う':3,'え':4,'お':5,
        'か':1,'き':2,'く':3,'け':4,'こ':5,
        'さ':1,'し':2,'す':3,'せ':4,'そ':5,
        'た':1,'ち':2,'つ':3,'て':4,'と':5,
        'な':1,'に':2,'ぬ':3,'ね':4,'の':5,
        'は':1,'ひ':2,'ふ':3,'へ':4,'ほ':5,
        'ま':1,'み':2,'む':3,'め':4,'も':5,
        'や':1,'ゆ':3,'よ':5,
        'ら':1,'り':2,'る':3,'れ':4,'ろ':5,
        'わ':1,'を':5
    };

    // 行オフセット（あ行=0, か行=1, ... わ行=9）
    const ROW_MAP = {
        'あ':0,'い':0,'う':0,'え':0,'お':0,
        'か':1,'き':1,'く':1,'け':1,'こ':1,
        'さ':2,'し':2,'す':2,'せ':2,'そ':2,
        'た':3,'ち':3,'つ':3,'て':3,'と':3,
        'な':4,'に':4,'ぬ':4,'ね':4,'の':4,
        'は':5,'ひ':5,'ふ':5,'へ':5,'ほ':5,
        'ま':6,'み':6,'む':6,'め':6,'も':6,
        'や':7,'ゆ':7,'よ':7,
        'ら':8,'り':8,'る':8,'れ':8,'ろ':8,
        'わ':9,'を':9
    };

    // 1文字→数値変換
    function charToNumber(ch) {
        if (ch === 'ん') return 9;
        const norm = normalize(ch);
        const vowel = VOWEL_MAP[norm];
        const row = ROW_MAP[norm];
        if (vowel === undefined || row === undefined) return null;
        const val = (vowel + row) % 9;
        return val === 0 ? 9 : val;
    }

    // 合計を一桁に圧縮
    function reduceToSingle(num) {
        while (num > 9) {
            num = String(num).split('').reduce((s, d) => s + parseInt(d), 0);
        }
        return num;
    }

    // ── 鑑定ロジック ──

    // 総数→守護カード名（画像ファイル名用）
    const CARD_NAMES = {
        1: '魔術師', 2: '女教皇', 3: '女帝', 4: '皇帝', 5: '教皇',
        6: '恋人', 7: '戦車', 8: '正義', 9: '隠者'
    };

    // 行名ラベル
    const ROW_LABELS = ['あ','か','さ','た','な','は','ま','や','ら','わ'];
    const VOWEL_LABELS = ['','あ','い','う','え','お'];

    function divine(sei, mei) {
        // 姓数（各文字の内訳も記録）
        let seiSum = 0;
        const seiDetail = [];
        for (const ch of sei) {
            const n = charToNumber(ch);
            if (n === null) return { error: `「${ch}」は変換できない文字です` };
            const norm = ch === 'ん' ? 'ん' : normalize(ch);
            const row = ch === 'ん' ? null : ROW_MAP[norm];
            const vowel = ch === 'ん' ? null : VOWEL_MAP[norm];
            seiDetail.push({
                ch,
                norm,
                row: row !== null ? `${ROW_LABELS[row]}行(+${row})` : null,
                vowel: vowel !== null ? `${VOWEL_LABELS[vowel]}段(${vowel})` : null,
                formula: ch === 'ん' ? 'ん = 9' : `(${vowel}+${row}) mod 9`,
                value: n
            });
            seiSum += n;
        }
        const seiNum = reduceToSingle(seiSum);

        // 名数（各文字の内訳も記録）
        let meiSum = 0;
        const meiDetail = [];
        for (const ch of mei) {
            const n = charToNumber(ch);
            if (n === null) return { error: `「${ch}」は変換できない文字です` };
            const norm = ch === 'ん' ? 'ん' : normalize(ch);
            const row = ch === 'ん' ? null : ROW_MAP[norm];
            const vowel = ch === 'ん' ? null : VOWEL_MAP[norm];
            meiDetail.push({
                ch,
                norm,
                row: row !== null ? `${ROW_LABELS[row]}行(+${row})` : null,
                vowel: vowel !== null ? `${VOWEL_LABELS[vowel]}段(${vowel})` : null,
                formula: ch === 'ん' ? 'ん = 9' : `(${vowel}+${row}) mod 9`,
                value: n
            });
            meiSum += n;
        }
        const meiNum = reduceToSingle(meiSum);

        // 総数
        const totalNum = reduceToSingle(seiSum + meiSum);

        // 陰陽（全文字数）
        const totalChars = sei.length + mei.length;
        const polarity = totalChars % 2 === 1 ? 'yang' : 'yin';
        const polarityLabel = polarity === 'yang' ? '陽' : '陰';

        // タイプ特定
        const typeKey = `${totalNum}_${polarity}`;
        const typeData = NAURA_TYPES[typeKey];

        // 姓数サブタイプ（外面）
        const seiTypeKey = `${seiNum}_${polarity}`;
        const seiTypeData = SEI_TYPES[seiTypeKey];

        // 名数サブタイプ（内面）
        const meiTypeKey = `${meiNum}_${polarity}`;
        const meiTypeData = MEI_TYPES[meiTypeKey];

        // 81の二つ名（姓数×名数）
        const futatsunaKey = `${seiNum}_${meiNum}`;
        const futatsuna = FUTATSUNA[futatsunaKey] || typeData.name;

        // 二つ名カード画像パス（81枚）
        const cardName = CARD_NAMES[reduceToSingle(seiNum + meiNum)];
        const cardImagePath = `card-images/${seiNum}_${meiNum}_${cardName}.png`;

        // 守護カード画像パス（18枚）
        const guardianImagePath = `card-images/guardian_${totalNum}_${polarity}.png`;

        return {
            sei, mei,
            seiNum, seiSum, seiDetail, seiTypeData,
            meiNum, meiSum, meiDetail, meiTypeData,
            totalNum,
            totalChars, polarity, polarityLabel,
            typeKey, typeData,
            futatsuna,
            cardImagePath,
            guardianImagePath
        };
    }

    // ── バリデーション ──

    function validateInput(str) {
        if (!str || str.trim() === '') return '入力してください';
        // ひらがな＋「ー」のみ許可
        if (!/^[\u3041-\u3096\u30FC]+$/.test(str)) {
            return 'ひらがなで入力してください';
        }
        return null;
    }

    // ── UI制御 ──

    function showSection(section) {
        [inputSection, analyzingSection, resultSection].forEach(s => s.style.display = 'none');
        section.style.display = 'block';
    }

    function showError(msg) {
        errorMsg.textContent = msg;
        errorMsg.style.display = 'block';
    }

    function hideError() {
        errorMsg.style.display = 'none';
    }

    function showToast(msg) {
        toast.textContent = msg;
        toast.classList.add('show');
        setTimeout(() => toast.classList.remove('show'), 2500);
    }

    // ── 結果表示 ──

    function renderResult(result) {
        const t = result.typeData;

        document.getElementById('resultCard').innerHTML = `
            <div class="result-name">${result.sei} ${result.mei}</div>
            <div class="guardian-card">
                <img src="${result.cardImagePath}" alt="${result.futatsuna}" class="card-image" onerror="this.style.display='none';this.nextElementSibling.style.display='block';">
                <div class="card-emoji" style="display:none;">${t.cardEmoji}</div>
            </div>
            <h2 class="type-title">${result.futatsuna}</h2>
            <div class="type-badge">姓数${result.seiNum} × 名数${result.meiNum} → 総数${result.totalNum}（${result.polarityLabel}）</div>
            <div class="keyword-tag">${t.keyword}</div>
        `;

        // 守護カード専用セクション（C案ストーリー型）
        document.getElementById('guardianSection').innerHTML = `
            <div class="guardian-heading">✦ あなたの守護タロットカード ✦</div>
            <img src="${result.guardianImagePath}" alt="${t.guardianCard}" class="guardian-card-image" onerror="this.style.display='none';this.nextElementSibling.style.display='block';">
            <div class="guardian-emoji-fallback" style="display:none;">${t.cardEmoji}</div>
            <div class="guardian-card-name">${t.guardianCard}</div>
            <div class="guardian-type-name">「${t.name}」</div>
            <p class="guardian-message">${t.guardianCard.replace(/（.*）/, '')}はあなたに語りかけます——${t.personality.split('。').slice(0, 2).join('。')}。この守護カードと二つ名「${result.futatsuna}」の力が合わさる時、あなたの名前に宿る本質が最も輝きます。</p>
        `;

        // 文字ごとの計算テーブルを生成
        function renderCharTable(detail) {
            const rows = detail.map(d => `
                <tr>
                    <td class="calc-char">${d.ch}</td>
                    <td>${d.row || '—'}</td>
                    <td>${d.vowel || '—'}</td>
                    <td class="calc-formula">${d.formula}</td>
                    <td class="calc-value">${d.value}</td>
                </tr>
            `).join('');
            return `
                <table class="calc-table">
                    <thead><tr><th>文字</th><th>行</th><th>段</th><th>計算</th><th>値</th></tr></thead>
                    <tbody>${rows}</tbody>
                </table>
            `;
        }
        function renderSumLine(detail, sum, reduced) {
            const values = detail.map(d => d.value).join(' + ');
            let line = `${values} = ${sum}`;
            if (sum !== reduced) {
                line += ` → ${sum.toString().split('').join(' + ')} = ${reduced}`;
            }
            return line;
        }

        document.getElementById('nameBreakdown').innerHTML = `
            <div class="breakdown-grid">
                <div class="breakdown-item">
                    <span class="breakdown-label">姓数</span>
                    <span class="breakdown-value">${result.seiNum}</span>
                    <span class="breakdown-name">${result.sei}</span>
                </div>
                <div class="breakdown-item">
                    <span class="breakdown-label">名数</span>
                    <span class="breakdown-value">${result.meiNum}</span>
                    <span class="breakdown-name">${result.mei}</span>
                </div>
                <div class="breakdown-item">
                    <span class="breakdown-label">総数</span>
                    <span class="breakdown-value">${result.totalNum}</span>
                    <span class="breakdown-sub">${result.totalChars}文字（${result.polarityLabel}）</span>
                </div>
            </div>
            <div class="breakdown-detail">
                <div class="detail-row">
                    <span class="detail-heading">姓の計算</span>
                    ${renderCharTable(result.seiDetail)}
                    <span class="detail-sum">姓数：${renderSumLine(result.seiDetail, result.seiSum, result.seiNum)}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-heading">名の計算</span>
                    ${renderCharTable(result.meiDetail)}
                    <span class="detail-sum">名数：${renderSumLine(result.meiDetail, result.meiSum, result.meiNum)}</span>
                </div>
                <div class="detail-row">
                    <span class="detail-heading">総数の計算</span>
                    <span class="detail-sum">総数：${result.seiSum} + ${result.meiSum} = ${result.seiSum + result.meiSum}${(result.seiSum + result.meiSum) !== result.totalNum ? ` → ${result.totalNum}` : ''}</span>
                </div>
                <details class="conversion-details">
                    <summary>📖 50音変換テーブルを見る</summary>
                    <p class="conversion-note">各文字 = (母音値 + 行値) mod 9 （0は9に）</p>
                    <div class="conversion-table-wrap">
                        <table class="conversion-table">
                            <thead>
                                <tr><th></th><th>あ段<br>(1)</th><th>い段<br>(2)</th><th>う段<br>(3)</th><th>え段<br>(4)</th><th>お段<br>(5)</th></tr>
                            </thead>
                            <tbody>
                                <tr><td class="row-label">あ行(0)</td><td>1</td><td>2</td><td>3</td><td>4</td><td>5</td></tr>
                                <tr><td class="row-label">か行(1)</td><td>2</td><td>3</td><td>4</td><td>5</td><td>6</td></tr>
                                <tr><td class="row-label">さ行(2)</td><td>3</td><td>4</td><td>5</td><td>6</td><td>7</td></tr>
                                <tr><td class="row-label">た行(3)</td><td>4</td><td>5</td><td>6</td><td>7</td><td>8</td></tr>
                                <tr><td class="row-label">な行(4)</td><td>5</td><td>6</td><td>7</td><td>8</td><td>9</td></tr>
                                <tr><td class="row-label">は行(5)</td><td>6</td><td>7</td><td>8</td><td>9</td><td>1</td></tr>
                                <tr><td class="row-label">ま行(6)</td><td>7</td><td>8</td><td>9</td><td>1</td><td>2</td></tr>
                                <tr><td class="row-label">や行(7)</td><td>8</td><td>—</td><td>9</td><td>—</td><td>3</td></tr>
                                <tr><td class="row-label">ら行(8)</td><td>9</td><td>1</td><td>2</td><td>3</td><td>4</td></tr>
                                <tr><td class="row-label">わ行(9)</td><td>1</td><td>—</td><td>—</td><td>—</td><td>5</td></tr>
                            </tbody>
                        </table>
                    </div>
                    <p class="conversion-note">※ 濁音・半濁音は清音に、小文字は大文字に変換して計算<br>※「ん」は常に 9</p>
                </details>
            </div>
        `;

        // 外面・内面タイプ
        document.getElementById('subTypes').innerHTML = `
            <div class="sub-type-grid">
                <div class="sub-type-card outer">
                    <span class="sub-type-label">🌐 外面（姓数 ${result.seiNum}）</span>
                    <span class="sub-type-name">${result.seiTypeData.name}</span>
                    <p class="sub-type-desc">${result.seiTypeData.desc}</p>
                </div>
                <div class="sub-type-card inner">
                    <span class="sub-type-label">💎 内面（名数 ${result.meiNum}）</span>
                    <span class="sub-type-name">${result.meiTypeData.name}</span>
                    <p class="sub-type-desc">${result.meiTypeData.desc}</p>
                </div>
            </div>
        `;

        document.getElementById('personality').innerHTML = `<p>${t.personality}</p>`;

        document.getElementById('strengths').innerHTML = `
            <h3>💪 強み</h3>
            <div class="tag-list">${t.strengths.map(s => `<span class="tag good">${s}</span>`).join('')}</div>
            <h3>⚠️ 弱み</h3>
            <div class="tag-list">${t.weaknesses.map(w => `<span class="tag warn">${w}</span>`).join('')}</div>
        `;

        document.getElementById('fortunes').innerHTML = `
            <div class="fortune-item">
                <div class="fortune-icon">❤️</div>
                <div class="fortune-label">恋愛運</div>
                <p>${t.love}</p>
            </div>
            <div class="fortune-item">
                <div class="fortune-icon">💼</div>
                <div class="fortune-label">仕事運</div>
                <p>${t.work}</p>
            </div>
            <div class="fortune-item">
                <div class="fortune-icon">💰</div>
                <div class="fortune-label">金運</div>
                <p>${t.money}</p>
            </div>
        `;
    }

    // ── イベントハンドラ ──

    uranauBtn.addEventListener('click', () => {
        console.log('[名占] ボタンクリック検知');
        hideError();

        let sei = seiInput.value.trim();
        let mei = meiInput.value.trim();
        console.log('[名占] 入力値:', sei, mei);

        // カタカナ→ひらがな自動変換
        sei = katakanaToHiragana(sei);
        mei = katakanaToHiragana(mei);

        // バリデーション
        const seiErr = validateInput(sei);
        if (seiErr) { showError(`姓: ${seiErr}`); return; }
        const meiErr = validateInput(mei);
        if (meiErr) { showError(`名: ${meiErr}`); return; }

        // 鑑定実行
        const result = divine(sei, mei);
        if (result.error) { showError(result.error); return; }

        // 分析演出
        showSection(analyzingSection);

        setTimeout(() => {
            renderResult(result);
            showSection(resultSection);

            // 非表示だった広告スロットを動的にpush
            try {
                document.querySelectorAll('.ad-deferred ins.adsbygoogle').forEach(ad => {
                    if (!ad.dataset.adsbygoogleStatus) {
                        (adsbygoogle = window.adsbygoogle || []).push({});
                    }
                });
            } catch(e) { /* AdSense not loaded */ }

            // シェア用データをボタンに保存
            setupShare(result);
        }, 2500);
    });

    // もう一度占う
    document.getElementById('retryBtn').addEventListener('click', () => {
        seiInput.value = '';
        meiInput.value = '';
        hideError();
        showSection(inputSection);
    });

    // ── シェア機能 ──

    function setupShare(result) {
        const t = result.typeData;
        const shareText = `【名占】${result.sei} ${result.mei}さんは「${result.futatsuna}」\n\n${t.cardEmoji} 守護カード：${t.guardianCard}\nキーワード：${t.keyword}\n\nあなたも名前で占ってみよう👇`;
        const shareUrl = 'https://solodev-lab.com/apps/naura/';

        document.getElementById('shareXBtn').onclick = () => {
            const url = `https://twitter.com/intent/tweet?text=${encodeURIComponent(shareText)}&url=${encodeURIComponent(shareUrl)}`;
            window.open(url, '_blank');
        };

        document.getElementById('shareLINEBtn').onclick = () => {
            const url = `https://social-plugins.line.me/lineit/share?url=${encodeURIComponent(shareUrl)}&text=${encodeURIComponent(shareText)}`;
            window.open(url, '_blank');
        };

        document.getElementById('copyBtn').onclick = () => {
            navigator.clipboard.writeText(`${shareText}\n${shareUrl}`).then(() => {
                showToast('コピーしました！');
            }).catch(() => {
                showToast('コピーに失敗しました');
            });
        };
    }

    // Enterキーで占う
    [seiInput, meiInput].forEach(input => {
        input.addEventListener('keydown', (e) => {
            if (e.key === 'Enter') uranauBtn.click();
        });
    });
});
