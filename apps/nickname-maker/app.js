document.addEventListener('DOMContentLoaded', () => {
    const API_URL = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
        ? 'http://localhost:8787'
        : 'https://ai-omoshiro-api.kojifo369.workers.dev';

    let traits = [];
    let taste = null;
    let isGenerating = false;

    const nameInput = document.getElementById('nameInput');
    const traitGrid = document.getElementById('traitGrid');
    const tasteButtons = document.getElementById('tasteButtons');
    const generateBtn = document.getElementById('generateBtn');
    const resultSection = document.getElementById('resultSection');
    const resultName = document.getElementById('resultName');
    const resultTraits = document.getElementById('resultTraits');
    const resultTaste = document.getElementById('resultTaste');
    const mainNickname = document.getElementById('mainNickname');
    const nicknameReading = document.getElementById('nicknameReading');
    const altList = document.getElementById('altList');
    const easyFill = document.getElementById('easyFill');
    const easyValue = document.getElementById('easyValue');
    const stickFill = document.getElementById('stickFill');
    const stickValue = document.getElementById('stickValue');
    const reactFill = document.getElementById('reactFill');
    const reactValue = document.getElementById('reactValue');
    const tipText = document.getElementById('tipText');
    const copyBtn = document.getElementById('copyBtn');
    const shareXBtn = document.getElementById('shareXBtn');
    const shareLINEBtn = document.getElementById('shareLINEBtn');
    const retryBtn = document.getElementById('retryBtn');
    const toast = document.getElementById('toast');

    // Trait selection (multi-select)
    traitGrid.addEventListener('click', (e) => {
        const btn = e.target.closest('button');
        if (!btn) return;
        const val = btn.dataset.value;
        if (btn.classList.contains('active')) {
            btn.classList.remove('active');
            traits = traits.filter(t => t !== val);
        } else {
            if (traits.length >= 3) {
                showToast('特徴は3つまで！');
                return;
            }
            btn.classList.add('active');
            traits.push(val);
        }
        updateGenerateBtn();
    });

    // Taste selection (single)
    tasteButtons.addEventListener('click', (e) => {
        const btn = e.target.closest('button');
        if (!btn) return;
        tasteButtons.querySelectorAll('button').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        taste = btn.dataset.value;
        updateGenerateBtn();
    });

    nameInput.addEventListener('input', updateGenerateBtn);

    function updateGenerateBtn() {
        generateBtn.disabled = !(nameInput.value.trim() && traits.length > 0 && taste);
    }

    generateBtn.addEventListener('click', generate);
    retryBtn.addEventListener('click', generate);

    async function generate() {
        const name = nameInput.value.trim();
        if (!name || traits.length === 0 || !taste) return;
        if (isGenerating) return;

        isGenerating = true;
        generateBtn.disabled = true;
        generateBtn.textContent = '考え中… ✨';

        try {
            await generateWithAI();
        } catch (err) {
            console.warn('AI generation failed, using static fallback:', err);
            generateFromStatic();
        } finally {
            isGenerating = false;
            generateBtn.textContent = 'あだ名を生成する ✨';
            generateBtn.disabled = !(nameInput.value.trim() && traits.length > 0 && taste);
        }
    }

    async function generateWithAI() {
        const name = nameInput.value.trim();
        const res = await fetch(API_URL + '/api/generate', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                app: 'nickname-maker',
                params: { name, traits, taste }
            })
        });

        if (!res.ok) throw new Error('API response ' + res.status);

        const json = await res.json();
        if (!json.success || !json.data) throw new Error('Invalid response');
        const data = json.data;
        if (!data.nickname) throw new Error('No nickname in response');

        // Display input summary
        resultName.textContent = name;
        resultTraits.textContent = traits.join('・');
        resultTaste.textContent = TASTE_LABELS[taste];

        // Main nickname
        mainNickname.textContent = data.nickname;
        mainNickname.style.animation = 'none';
        mainNickname.offsetHeight;
        mainNickname.style.animation = 'popIn 0.5s ease';
        nicknameReading.textContent = data.reading || (name + ' → ' + data.nickname);

        // Alt nicknames
        altList.innerHTML = '';
        if (data.alts && Array.isArray(data.alts)) {
            data.alts.forEach(alt => {
                const chip = document.createElement('span');
                chip.className = 'alt-chip';
                chip.textContent = alt;
                chip.addEventListener('click', () => {
                    mainNickname.textContent = alt;
                    mainNickname.style.animation = 'none';
                    mainNickname.offsetHeight;
                    mainNickname.style.animation = 'popIn 0.5s ease';
                    nicknameReading.textContent = name + ' → ' + alt;
                });
                altList.appendChild(chip);
            });
        }

        // Stats
        const easyVal = clamp(data.easy, 20, 99);
        const stickVal = clamp(data.stick, 20, 99);
        const reactVal = clamp(data.react, 20, 99);

        setTimeout(() => {
            easyFill.style.width = easyVal + '%';
            easyValue.textContent = easyVal + '%';
            stickFill.style.width = stickVal + '%';
            stickValue.textContent = stickVal + '%';
            reactFill.style.width = reactVal + '%';
            reactValue.textContent = reactVal + '%';
        }, 100);

        // Tip
        tipText.textContent = data.tip || ('💡 ' + TIPS[Math.floor(Math.random() * TIPS.length)]);

        showResult();
    }

    function generateFromStatic() {
        const name = nameInput.value.trim();
        const nicknames = generateNicknames(name, traits, taste);

        // Display
        resultName.textContent = name;
        resultTraits.textContent = traits.join('・');
        resultTaste.textContent = TASTE_LABELS[taste];

        // Main nickname
        mainNickname.textContent = nicknames[0];
        mainNickname.style.animation = 'none';
        mainNickname.offsetHeight;
        mainNickname.style.animation = 'popIn 0.5s ease';
        nicknameReading.textContent = name + ' → ' + nicknames[0];

        // Alt nicknames
        altList.innerHTML = '';
        for (let i = 1; i < nicknames.length; i++) {
            const chip = document.createElement('span');
            chip.className = 'alt-chip';
            chip.textContent = nicknames[i];
            chip.addEventListener('click', () => {
                mainNickname.textContent = nicknames[i];
                mainNickname.style.animation = 'none';
                mainNickname.offsetHeight;
                mainNickname.style.animation = 'popIn 0.5s ease';
                nicknameReading.textContent = name + ' → ' + nicknames[i];
            });
            altList.appendChild(chip);
        }

        // Stats
        const easyVal = 40 + Math.floor(Math.random() * 50);
        const stickVal = 30 + Math.floor(Math.random() * 60);
        const reactVal = 20 + Math.floor(Math.random() * 70);

        setTimeout(() => {
            easyFill.style.width = easyVal + '%';
            easyValue.textContent = easyVal + '%';
            stickFill.style.width = stickVal + '%';
            stickValue.textContent = stickVal + '%';
            reactFill.style.width = reactVal + '%';
            reactValue.textContent = reactVal + '%';
        }, 100);

        // Tip
        tipText.textContent = '💡 ' + TIPS[Math.floor(Math.random() * TIPS.length)];

        showResult();
    }

    function generateNicknames(name, traits, taste) {
        const results = new Set();
        const patterns = NAME_PATTERNS[taste];

        // Name-based transforms
        patterns.transforms.forEach(fn => {
            results.add(fn(name));
        });

        // Trait-based nicknames
        const traitNicks = TRAIT_NICKNAMES[taste];
        traits.forEach(trait => {
            const nicks = traitNicks[trait];
            if (nicks) {
                nicks.forEach(n => results.add(n));
            }
        });

        // Combine name + trait
        if (traits.length > 0) {
            const mainTrait = traits[0];
            const traitList = traitNicks[mainTrait];
            if (traitList) {
                results.add(name.slice(0, 2) + '(' + traitList[0] + ')');
            }
        }

        // Shuffle and pick up to 6
        const arr = Array.from(results);
        for (let i = arr.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [arr[i], arr[j]] = [arr[j], arr[i]];
        }

        return arr.slice(0, 6);
    }

    function showResult() {
        resultSection.style.display = 'block';
        resultSection.style.animation = 'none';
        resultSection.offsetHeight;
        resultSection.style.animation = 'fadeInUp 0.5s ease';
        resultSection.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }

    function clamp(val, min, max) {
        const n = parseInt(val, 10);
        if (isNaN(n)) return min + Math.floor(Math.random() * (max - min));
        return Math.max(min, Math.min(max, n));
    }

    // Copy
    copyBtn.addEventListener('click', () => {
        const text = `【AIあだ名メーカー】で「${nameInput.value.trim()}」のあだ名を作りました → ${mainNickname.textContent}\nhttps://solodev-lab.github.io/ai-omoshiro-tools/apps/nickname-maker/`;
        navigator.clipboard.writeText(text).then(() => {
            showToast('コピーしました！');
        });
    });

    // Share on X (Twitter)
    shareXBtn.addEventListener('click', () => {
        const appUrl = 'https://solodev-lab.github.io/ai-omoshiro-tools/apps/nickname-maker/';
        const text = `【AIあだ名メーカー】で「${nameInput.value.trim()}」のあだ名を作りました → ${mainNickname.textContent}`;
        const hashtags = 'あだ名,AI,個人開発';
        const url = `https://twitter.com/intent/tweet?text=${encodeURIComponent(text)}&url=${encodeURIComponent(appUrl)}&hashtags=${encodeURIComponent(hashtags)}`;
        window.open(url, '_blank');
    });

    // Share on LINE
    shareLINEBtn.addEventListener('click', () => {
        const appUrl = 'https://solodev-lab.github.io/ai-omoshiro-tools/apps/nickname-maker/';
        const text = `【AIあだ名メーカー】で「${nameInput.value.trim()}」のあだ名を作りました → ${mainNickname.textContent}\n${appUrl}`;
        const url = `https://social-plugins.line.me/lineit/share?url=${encodeURIComponent(appUrl)}&text=${encodeURIComponent(text)}`;
        window.open(url, '_blank');
    });

    function showToast(message) {
        toast.textContent = message;
        toast.classList.add('show');
        setTimeout(() => toast.classList.remove('show'), 2000);
    }
});
