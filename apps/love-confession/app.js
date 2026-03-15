document.addEventListener('DOMContentLoaded', () => {
    let relationship = null;
    let mood = null;
    let situation = null;

    const relGrid = document.getElementById('relGrid');
    const moodGrid = document.getElementById('moodGrid');
    const sitButtons = document.getElementById('sitButtons');
    const generateBtn = document.getElementById('generateBtn');
    const resultSection = document.getElementById('resultSection');
    const resultRel = document.getElementById('resultRel');
    const resultMood = document.getElementById('resultMood');
    const resultSit = document.getElementById('resultSit');
    const confessionText = document.getElementById('confessionText');
    const confessionSubtitle = document.getElementById('confessionSubtitle');
    const altList = document.getElementById('altList');
    const successFill = document.getElementById('successFill');
    const successValue = document.getElementById('successValue');
    const seriousFill = document.getElementById('seriousFill');
    const seriousValue = document.getElementById('seriousValue');
    const powerFill = document.getElementById('powerFill');
    const powerValue = document.getElementById('powerValue');
    const tipText = document.getElementById('tipText');
    const copyBtn = document.getElementById('copyBtn');
    const shareBtn = document.getElementById('shareBtn');
    const retryBtn = document.getElementById('retryBtn');
    const toast = document.getElementById('toast');

    let currentText = '';

    function setupSelection(container, callback) {
        container.addEventListener('click', (e) => {
            const btn = e.target.closest('button');
            if (!btn) return;
            container.querySelectorAll('button').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            callback(btn.dataset.value);
            updateGenerateBtn();
        });
    }

    setupSelection(relGrid, (v) => { relationship = v; });
    setupSelection(moodGrid, (v) => { mood = v; });
    setupSelection(sitButtons, (v) => { situation = v; });

    function updateGenerateBtn() {
        generateBtn.disabled = !(relationship && mood && situation);
    }

    generateBtn.addEventListener('click', generate);
    retryBtn.addEventListener('click', generate);

    function generate() {
        if (!relationship || !mood || !situation) return;

        const relData = CONFESSIONS[relationship];
        if (!relData) return;

        const moodData = relData[mood];
        if (!moodData || moodData.length === 0) return;

        const entry = moodData[Math.floor(Math.random() * moodData.length)];
        const prefix = SITUATION_PREFIX[situation] || '';

        currentText = prefix + entry.text;

        resultRel.textContent = relationship;
        resultMood.textContent = mood;
        resultSit.textContent = SITUATION_LABELS[situation];

        confessionText.textContent = currentText;
        confessionSubtitle.textContent = '— ' + entry.subtitle;

        altList.innerHTML = '';
        entry.alts.forEach(alt => {
            const chip = document.createElement('span');
            chip.className = 'alt-chip';
            chip.textContent = alt.length > 20 ? alt.substring(0, 20) + '…' : alt;
            chip.addEventListener('click', () => {
                currentText = prefix + alt;
                confessionText.textContent = currentText;
                confessionSubtitle.textContent = '— 別パターン';
            });
            altList.appendChild(chip);
        });

        const successScore = 10 + rand(90);
        const seriousScore = 60 + rand(41);
        const powerScore = 40 + rand(61);

        setTimeout(() => {
            successFill.style.width = successScore + '%';
            successValue.textContent = successScore + '%';
            seriousFill.style.width = seriousScore + '%';
            seriousValue.textContent = seriousScore + '%';
            powerFill.style.width = powerScore + '%';
            powerValue.textContent = powerScore + '%';
        }, 100);

        tipText.textContent = TIPS[Math.floor(Math.random() * TIPS.length)];

        resultSection.style.display = 'block';
        resultSection.style.animation = 'none';
        resultSection.offsetHeight;
        resultSection.style.animation = 'fadeInUp 0.5s ease';
        resultSection.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }

    function rand(max) {
        return Math.floor(Math.random() * max);
    }

    copyBtn.addEventListener('click', () => {
        navigator.clipboard.writeText(currentText).then(() => {
            showToast('告白文をコピーしました！');
        });
    });

    shareBtn.addEventListener('click', () => {
        const text = '【AI告白文ジェネレーター】' + relationship + 'への' + mood + 'な告白💌\n\n' + currentText;
        if (navigator.share) {
            navigator.share({ title: 'AI告白文ジェネレーター', text: text });
        } else {
            const url = 'https://twitter.com/intent/tweet?text=' + encodeURIComponent(text);
            window.open(url, '_blank');
        }
    });

    function showToast(message) {
        toast.textContent = message;
        toast.classList.add('show');
        setTimeout(() => toast.classList.remove('show'), 2000);
    }
});
