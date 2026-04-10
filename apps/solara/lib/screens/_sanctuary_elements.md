# Sanctuary Screen — Element Inventory (HTML準拠)
> Source: `apps/solara/mockup/sanctuary.html` (2611 lines)
> Purpose: Flutter移植時の照合用。全CSS値はHTML/shared/styles.cssからの正確な転記。

---

## SHARED CSS TOKENS (from shared/styles.css :root)
```
--bg-deep: #080C14
--bg-mid: #0C1D3A
--bg-body: #0A0A14
--gold: #F9D976
--gold-end: #F6BD60
--cyan: #26D0CE
--cyan-deep: #1A2980
--text-primary: #EAEAEA
--text-secondary: #ACACAC
--text-muted: rgba(172,172,172,0.7)
--glass-bg: rgba(255,255,255,0.05)
--glass-border: rgba(255,255,255,0.1)
--nav-height: 80px
--font-heading: 'Cormorant Garamond', 'Georgia', serif
--font-body: 'DM Sans', 'Segoe UI', sans-serif
--font-mono: 'Courier New', monospace
```

---

## BODY STRUCTURE

### 1. .phone#phone
```
width:100%; min-height:100vh; background:var(--bg-deep) = #080C14;
overflow:hidden; position:relative;
```

### 2. canvas#bgCanvas
```
position:absolute; inset:0; z-index:0; width:100%; height:100%;
```
- JS: animBg() draws radial gradient #0C1D3A→#080C14, plus floating gold nebula glow rgba(249,217,118,0.05)

### 3. #starContainer
```
position:absolute; inset:0; z-index:1; pointer-events:none; overflow:hidden;
```
- JS: makeStars() creates 45 `.star` divs
- Each star: border-radius:50%; background:white; animation:twinkle var(--dur) ease-in-out infinite var(--delay)
- size: random 0.5-2.3px; opacity: 0.1-0.45

### 4. .status-bar (from shared/styles.css)
```
position:fixed; top:0; left:0; right:0; height:44px;
display:flex; justify-content:space-between; align-items:center;
padding:0 28px; z-index:200; font-size:12px; font-weight:700;
color:rgba(234,234,234,0.9); pointer-events:none;
```
Children:
- span: "9:41"
- span: "✦ SOLARA ✦" (letter-spacing:1.5px; font-size:11px)
- span: "87%🔋"

### 5. .main-area.cosmic-bg
```
position:fixed; inset:0; display:flex; flex-direction:column; z-index:10;
```
cosmic-bg (shared/styles.css):
```
background:
  radial-gradient(ellipse at 50% 0%, #0f2850 0%, var(--bg-deep) 55%),
  radial-gradient(ellipse at 30% 100%, #060e20 0%, transparent 65%);
```
cosmic-bg::before — fixed nebula glow layers (7 radial gradients)
cosmic-bg::after — secondary glow layers (4 radial gradients), animation: nebulaShift 18s ease-in-out infinite alternate

---

## 5a. .sanctuary-content (scrollable area)
```
flex:1; overflow-y:auto; padding:56px 20px 100px;
display:flex; flex-direction:column; gap:20px;
max-width:600px; margin:0 auto; width:100%;
position:relative; z-index:10;
scrollbar: hidden (::-webkit-scrollbar { display:none })
```

### 5a-1. .profile-row
```
display:flex; align-items:center; gap:14px;
```

#### .profile-orb
```
width:56px; height:56px; border-radius:50%;
background:radial-gradient(circle, rgba(249,217,118,0.25) 0%, rgba(249,217,118,0.04) 70%);
border:1px solid rgba(249,217,118,0.25);
display:flex; align-items:center; justify-content:center; font-size:24px;
```
Content: "✦"

#### .profile-name-big#profileName
```
font-size:20px; font-weight:700;
```
Default text: "Hayashi Koji"

#### .profile-tier
```
font-size:12px; color:#ACACAC; margin-top:2px;
```
Text: "Free Tier · Cosmic Journey"

---

### 5a-2. .settings-group "Stellar Profile"

#### .section-label (shared/styles.css)
```
font-size:11px; font-weight:700; color:var(--gold) = #F9D976;
letter-spacing:1.8px; text-transform:uppercase;
```
Text: "✦ Stellar Profile"

#### .settings-item.glass (出生情報)
```
display:flex; align-items:center; justify-content:space-between;
padding:14px 18px; border-radius:16px; cursor:pointer;
```
glass (shared/styles.css):
```
background:rgba(255,255,255,0.06); backdrop-filter:blur(20px);
border:1px solid rgba(255,255,255,0.12); border-radius:20px;
box-shadow: inset 0 1px 0 rgba(255,255,255,0.06), inset 0 0 40px rgba(249,217,118,0.02), 0 0 24px rgba(0,0,0,0.3);
```
NOTE: .settings-item overrides border-radius to 16px

##### .settings-left
```
display:flex; align-items:center; gap:12px;
```

##### .settings-icon#si-birth
```
width:36px; height:36px; background:rgba(255,255,255,0.05);
border-radius:10px; display:flex; align-items:center; justify-content:center;
font-size:17px; color:rgba(249,217,118,0.7);
```
SVG from shared/icons.js (I.birth_info), icon svg: width:20px; height:20px

##### .settings-txt
```
font-size:14px;
```
Text: "出生情報"

##### .settings-val#birthInfoVal
```
font-size:13px; color:#ACACAC;
```
Text: "未設定 ›"

#### .settings-item.glass (自宅)
Same structure as above.
- Icon: #si-home (I.home)
- Text: "自宅（現住所）"
- Val: #homeVal "未設定 ›"

---

### 5a-3. .settings-group "Title Diagnosis" #titleSection

#### .section-label
Text: "✦ Title Diagnosis"

#### #titleResultWrapper (display:none initially)
```
class: td-result-card-wrapper
perspective:1200px; cursor:pointer;
onclick: toggle 'flipped' class
```

##### .td-result-card-inner
```
position:relative; transition:transform 0.7s ease;
transform-style:preserve-3d; height:480px;
```
When .flipped: transform:rotateY(180deg)

##### .td-result-face.td-vcard (LIGHT face)
```
backface-visibility:hidden; position:absolute; inset:0;
border-radius:16px; overflow:hidden;
display:flex; flex-direction:column; justify-content:center; align-items:center;
padding:28px 20px 24px; box-sizing:border-box; text-align:center;
border:1px solid rgba(249,217,118,0.15);
box-shadow:0 4px 30px rgba(0,0,0,0.5), 0 0 60px rgba(249,217,118,0.05);
```

###### .td-vcard-bg#vcardBgLight
```
position:absolute; inset:0; z-index:0;
background-size:cover; background-position:center;
```
(JS sets background-image to zodiac bg)

###### .td-vcard-overlay#vcardOverlayLight
```
position:absolute; inset:0; z-index:1;
```
(JS sets: linear-gradient(180deg, rgba(0,0,0,0.55) 0%, rgba(0,0,0,0.7) 100%), radial-gradient(ellipse at 50% 40%, [axisGlow] 0%, transparent 70%))

###### .td-vcard-content
```
position:relative; z-index:2; width:100%;
```

###### .td-vcard-label (LIGHT)
```
font-size:10px; letter-spacing:3px; margin-bottom:6px;
text-shadow:0 0 8px rgba(249,217,118,0.2), 0 1px 2px rgba(0,0,0,0.8);
font-weight:300;
```
Inline style: color:rgba(249,217,118,0.5)
Text: "✦ LIGHT ✦"

###### .td-vcard-zodiac#vcardZodiacLight
```
display:flex; justify-content:center; gap:48px; margin-bottom:12px;
```
Contains 2x .td-vcard-zodiac-item (Sun + Moon):

.td-vcard-zodiac-item:
```
display:flex; flex-direction:column; align-items:center;
```
img:
```
width:72px; height:72px;
filter:brightness(2) drop-shadow(0 0 12px rgba(249,217,118,0.5)) drop-shadow(0 0 24px rgba(249,217,118,0.2));
border-radius:50%;
background:radial-gradient(circle, rgba(249,217,118,0.12) 0%, transparent 70%);
padding:6px;
```
.td-vcard-zodiac-label:
```
font-size:10px; color:rgba(234,234,234,0.7); margin-top:5px; letter-spacing:1px; font-weight:300;
```

###### .td-vcard-line
```
width:70%; height:1px; margin:10px auto 12px;
background:linear-gradient(90deg, transparent, rgba(249,217,118,0.6), transparent);
```

###### .td-vcard-title#vcardLightTitle
```
font-size:19px; font-weight:700; color:#F9D976; line-height:1.6;
text-shadow:0 0 20px rgba(249,217,118,0.4), 0 0 40px rgba(249,217,118,0.15), 0 2px 4px rgba(0,0,0,0.9);
margin:4px 0 10px; letter-spacing:0.5px;
```

###### .td-vcard-class-icon-frame
```
position:relative; width:148px; height:148px; margin:8px auto 10px;
display:flex; align-items:center; justify-content:center;
background:radial-gradient(circle, #0a0a14 60%, rgba(10,10,20,0.9) 75%, transparent 85%);
border-radius:50%;
```
::before (conic ring):
```
content:''; position:absolute; inset:-6px; border-radius:50%;
background:conic-gradient(from 0deg, #F9D976, #E8A840, #C8862A, #E8A840, #F9D976, #E8A840, #C8862A, #E8A840, #F9D976);
mask:radial-gradient(farthest-side, transparent calc(100% - 3px), #000 calc(100% - 3px));
filter:drop-shadow(0 0 6px rgba(249,217,118,0.4));
```
::after (inner glow ring):
```
content:''; position:absolute; inset:2px; border-radius:50%;
border:1px solid rgba(249,217,118,0.25);
box-shadow:0 0 40px rgba(249,217,118,0.15), 0 0 80px rgba(249,217,118,0.05),
           inset 0 0 30px rgba(249,217,118,0.08);
```

###### .td-vcard-class-icon#vcardClassIconLight
```
width:100px; height:100px; display:block; position:relative; z-index:1;
border-radius:50%; object-fit:cover; background:#0a0a14;
filter:brightness(2) drop-shadow(0 0 16px rgba(249,217,118,0.5)) drop-shadow(0 0 32px rgba(249,217,118,0.2));
```

###### .td-vcard-class-name#vcardLightClassName
```
font-size:15px; font-weight:700; color:#EAEAEA; letter-spacing:2px;
text-shadow:0 0 8px rgba(234,234,234,0.2), 0 2px 4px rgba(0,0,0,0.8);
```

###### .td-vcard-desc#vcardLightDesc
```
font-size:12px; color:rgba(234,234,234,0.75); margin-top:10px; line-height:1.7;
text-shadow:0 1px 3px rgba(0,0,0,0.9); letter-spacing:0.3px;
```

##### .td-result-back.td-vcard (SHADOW face)
Same structure as LIGHT face. Differences:
- transform:rotateY(180deg)
- .td-vcard-label: color:rgba(172,172,172,0.5), text "✦ SHADOW ✦"
- .td-vcard-title has extra class .shadow-face:
```
color:#EAEAEA;
text-shadow:0 0 15px rgba(234,234,234,0.2), 0 2px 4px rgba(0,0,0,0.9);
```
- .td-vcard-desc: inline font-style:italic

##### .td-flip-hint
```
font-size:10px; color:rgba(172,172,172,0.4); text-align:center; margin-top:8px;
letter-spacing:0.5px;
```
Text: "tap to flip"

#### #titleStartBtn
Contains button (inline styles):
```
width:100%; padding:14px; border-radius:14px; border:none;
background:linear-gradient(135deg,#F9D976,#E8A840); color:#0A0A14;
font-size:15px; font-weight:700; cursor:pointer; letter-spacing:0.5px;
```
Text: "✦ あなたの称号を受け取る"

#### #titleNeedProfile (display:none)
```
text-align:center; color:#ACACAC; font-size:13px; padding:10px;
```
Text: "まず出生情報を設定してください"

#### #titleRediagnose (display:none)
Button:
```
width:100%; padding:12px; border-radius:14px;
border:1px solid rgba(249,217,118,0.3); background:none;
color:#F9D976; font-size:13px; cursor:pointer;
```
Text: "再診断する（Cosmic Pro）"

---

### 5a-4. .settings-group "Cosmic Pro"

#### .section-label
Text: "✦ Cosmic Pro"

#### .pro-banner (shared/styles.css + inline overrides)
```
padding:16px; gap:10px; (inline overrides shared defaults of padding:22px; gap:12px)
background:linear-gradient(135deg,rgba(249,217,118,0.09),rgba(249,217,118,0.04));
border:1px solid rgba(249,217,118,0.18); border-radius:22px;
display:flex; flex-direction:column; align-items:center; text-align:center;
```

##### .pro-title (inline font-size:16px overrides shared 18px)
```
font-weight:700;
background:linear-gradient(135deg,var(--gold),var(--gold-end));
-webkit-background-clip:text; -webkit-text-fill-color:transparent;
```
Text: "Upgrade to Cosmic Pro"

##### .pro-sub (inline font-size:12px overrides shared 13px)
```
color:var(--text-secondary) = #ACACAC; line-height:1.55;
```
Text: "Aether shaders · Galaxy Archive · Advanced astrology"

##### Price row (flex container)
```
display:flex; align-items:baseline; gap:6px;
```
- span: font-size:24px; font-weight:700; color:#F9D976; text "$9.99"
- span: font-size:12px; color:#ACACAC; text "/month"

##### .pro-btn (inline overrides)
```
padding:10px 24px; font-size:13px; (shared: padding:13px 30px; font-size:14px)
background:linear-gradient(135deg,var(--gold),var(--gold-end)); border:none;
border-radius:14px; font-weight:700; color:var(--bg-mid); cursor:pointer;
```
Text: "Unlock Cosmic Pro ✦"

##### Yearly price text
```
font-size:11px; color:rgba(172,172,172,0.45);
```
Text: "$49.99/year · Cancel anytime"

---

### 5a-5. .settings-group "Astrology"

#### .section-label
Text: "✦ Astrology"

#### .settings-item.glass#houseSystemRow (House System)
Same structure as other settings-items. cursor:pointer
- Icon: #si-house (I.house_system)
- Text: "House System"
- Val: #houseSystemVal "Placidus ›"

#### #houseSelectPanel (display:none)
```
padding:0 8px;
```
Contains 2 sub .settings-item.glass rows:

##### Placidus option
```
cursor:pointer; padding:10px 18px;
```
- Text: "Placidus"
- #houseCheck_placidus: color:#F9D976; font-size:16px; text "✓"

##### Whole Sign option
```
cursor:pointer; padding:10px 18px; margin-top:6px;
```
- Text: "Whole Sign"
- #houseCheck_whole_sign: color:#F9D976; font-size:16px; opacity:0; text "✓"

#### .settings-item.glass (Aspect Orbs)
- Icon: #si-telescope (I.telescope)
- Text: "Aspect Orbs"
- Val: #orbSummaryVal "All 2° ›"

---

### 5a-6. .settings-group "App"

#### .section-label
Text: "✦ App"

#### .settings-item.glass (Language)
- Icon: #si-globe (I.globe)
- Text: "Language"
- Val: "English ›"

#### .settings-item.glass (Notifications)
- Icon: #si-bell (I.bell)
- Text: "Notifications"
- .toggle.on (instead of val):
```
width:44px; height:26px; border-radius:13px;
background:rgba(255,255,255,0.12); position:relative;
cursor:pointer; transition:background 0.3s;
```
When .on: background:rgba(249,217,118,0.55)

.toggle-thumb:
```
position:absolute; top:3px; left:3px; width:20px; height:20px;
border-radius:50%; background:white; transition:transform 0.3s;
```
When .on: transform:translateX(18px)

#### .settings-item.glass (Terms & Privacy)
- Icon: #si-doc (I.document)
- Text: "Terms & Privacy"
- Val: "›"

---

### 5a-7. .version-txt
```
text-align:center; font-size:11px; color:rgba(172,172,172,0.35); padding:8px 0;
```
Text: "Solara v1.0.0 · Made with ✦"

---

### 5b. .bottom-nav (from shared/styles.css)
```
position:fixed; bottom:0; left:0; right:0; height:var(--nav-height) = 80px;
background:linear-gradient(180deg, rgba(6,10,18,0.80) 0%, rgba(4,6,14,0.95) 100%);
backdrop-filter:blur(28px);
border-top:1px solid rgba(249,217,118,0.06);
box-shadow:0 -4px 30px rgba(0,0,0,0.4), inset 0 1px 0 rgba(255,255,255,0.04);
display:flex; justify-content:space-around; align-items:flex-start;
padding:10px 4px 0; z-index:150;
```
Populated by JS: renderNav('sanctuary') from shared/nav.js

.nav-item:
```
display:flex; flex-direction:column; align-items:center; gap:4px;
background:none; border:none; cursor:pointer; padding:6px 12px;
border-radius:14px; transition:all 0.3s;
```
.nav-icon: width:24px; height:24px; color:rgba(255,255,255,0.35)
.nav-icon (active): color:var(--gold); filter:drop-shadow(0 0 8px var(--gold)) drop-shadow(0 0 16px rgba(249,217,118,0.3))
.nav-label: font-size:9px; color:rgba(255,255,255,0.35); letter-spacing:0.5px; text-transform:uppercase
.nav-label (active): color:var(--gold); text-shadow:0 0 10px rgba(249,217,118,0.4)
.nav-item.active::after (glow dot): width:4px; height:4px; border-radius:50%; background:var(--gold); box-shadow:0 0 8px 2px rgba(249,217,118,0.5), 0 0 20px 4px rgba(249,217,118,0.15)

---

## OVERLAY: #birthOverlay (出生情報)

### .birth-overlay
```
display:none; position:fixed; inset:0; z-index:500;
background:rgba(4,8,16,0.95); backdrop-filter:blur(12px);
justify-content:center; align-items:flex-start; overflow-y:auto;
```
When .open: display:flex

### .birth-card
```
max-width:420px; width:92%; padding:24px 20px 32px; margin:40px auto;
background:rgba(255,255,255,0.05); border:1px solid rgba(255,255,255,0.1);
border-radius:24px;
```

### .birth-header
```
display:flex; justify-content:space-between; align-items:center; margin-bottom:20px;
```

### .birth-title
```
font-size:16px; font-weight:700; color:#F9D976; letter-spacing:1px;
```
Text: "✦ 出生情報"

### .birth-close
```
width:32px; height:32px; border-radius:50%; border:none;
background:rgba(255,255,255,0.08); color:#ACACAC;
font-size:18px; cursor:pointer; display:flex; align-items:center; justify-content:center;
```
Text: "✕"

### .birth-section (氏名)
```
margin-bottom:18px;
```
.birth-label:
```
font-size:12px; color:#ACACAC; margin-bottom:6px; letter-spacing:0.5px; text-transform:uppercase;
```
Text: "氏名"

.birth-input#biName:
```
width:100%; padding:12px 14px; background:rgba(255,255,255,0.06);
border:1px solid rgba(255,255,255,0.12); border-radius:12px;
color:#EAEAEA; font-size:14px; outline:none; font-family:inherit;
```
:focus → border-color:rgba(249,217,118,0.4)
:disabled → opacity:0.35; cursor:not-allowed
placeholder: "氏名を入力"

### .birth-section (生年月日)
- .birth-label: "生年月日"
- .birth-input#biBirthDate: type="date" max="9999-12-31"

### .birth-section (出生時刻)
- .birth-label: "出生時刻"
- .birth-input#biBirthTime: type="time" step="60"
- .time-unknown-row:
```
display:flex; align-items:center; gap:8px; margin-top:8px;
```
  - .time-unknown-cb#biTimeUnknown:
```
width:18px; height:18px; accent-color:#F9D976; cursor:pointer;
```
  - .time-unknown-label:
```
font-size:12px; color:#ACACAC; cursor:pointer;
```
Text: "出生時刻が分からない"

- .time-noon-hint#biNoonHint:
```
display:none; font-size:11px; color:#F9D976;
margin-top:6px; padding:6px 10px;
background:rgba(249,217,118,0.08); border-radius:8px;
```
When .show: display:block

### .birth-section (出生地)
- .birth-label: "出生地"
- .map-search-row:
```
display:flex; gap:8px; margin-bottom:8px;
```
  - .birth-input#biBirthPlace: flex:1; placeholder "例: 岐阜県岐阜市"
  - .map-search-btn#biMapSearchBtn:
```
padding:0 16px; border-radius:12px; border:none;
background:linear-gradient(135deg,#F9D976,#E8A840);
color:#0A0A14; font-size:13px; font-weight:600; cursor:pointer; white-space:nowrap;
```
:disabled → opacity:0.4; cursor:default
Text: "検索"

- .map-result-info#biMapResult:
```
font-size:11px; color:#6CC070; margin-top:6px; display:none;
```
When .show: display:block
When .error: color:#E87070

- #birthMap:
```
width:100%; height:200px; border-radius:12px;
margin-top:8px; border:1px solid rgba(255,255,255,0.1);
```

- .map-coords:
```
display:flex; gap:8px; margin-top:8px;
```
  - .birth-input#biBirthLat: flex:1; type="number" step="0.0001" placeholder="緯度" readonly
  - .birth-input#biBirthLng: flex:1; type="number" step="0.0001" placeholder="経度" readonly

### .birth-save-btn
```
width:100%; padding:14px; border-radius:14px; border:none;
background:linear-gradient(135deg,#F9D976,#E8A840);
color:#0A0A14; font-size:15px; font-weight:700;
cursor:pointer; margin-top:8px; letter-spacing:0.5px;
```
Text: "保存する"

---

## OVERLAY: #orbOverlay (Aspect Orbs)

### Container
Same .birth-overlay as birth. .birth-card with max-width:440px (override).

### .birth-header
- .birth-title: "🔭 Aspect Orbs"
- Reset button:
```
padding:4px 10px; border-radius:8px;
border:1px solid rgba(255,255,255,0.15); background:none;
color:#ACACAC; font-size:11px; cursor:pointer;
```
Text: "リセット"
- .birth-close: "✕"

### .birth-section "Major Aspects"
- .birth-label: "Major Aspects"
- #orbMajor .orb-category:
```
display:flex; flex-direction:column; gap:6px;
```

### .orb-row (dynamically built)
```
display:flex; align-items:center; padding:8px 10px;
border-radius:10px; background:rgba(255,255,255,0.03);
```

#### .orb-name
```
font-size:12px; color:#ACACAC; min-width:120px;
```

#### .orb-pm (minus/plus buttons)
```
width:26px; height:26px; border-radius:50%;
border:1px solid rgba(249,217,118,0.3); background:none;
color:#F9D976; font-size:16px; cursor:pointer;
display:flex; align-items:center; justify-content:center; flex-shrink:0;
```
:active → background:rgba(249,217,118,0.15)

#### .orb-slider-wrap
```
flex:1; margin:0 4px; position:relative; height:26px;
display:flex; align-items:center;
```
input[type="range"]: width:100%; margin:0; accent-color:#F9D976
min:0.5 max:8 step:0.5

#### .orb-default-mark
```
position:absolute; top:2px; bottom:2px; width:1px;
background:rgba(249,217,118,0.25); pointer-events:none; z-index:2;
```

#### .orb-val
```
font-size:13px; color:#F9D976; min-width:36px; text-align:center;
```

### Aspect data (Major):
- Conjunction 0° def:2
- Opposition 180° def:2
- Trine 120° def:2
- Square 90° def:2
- Sextile 60° def:2

### .birth-section "Minor Aspects"
- Quincunx 150° def:2
- Semi-Sextile 30° def:1
- Semi-Square 45° def:1

### .birth-section "Patterns"
- Grand Trine 120° def:3
- T-Square (Opp) 180° def:3
- T-Square (Sq) 90° def:2.5
- Yod (Sextile) 60° def:2.5
- Yod (Quincunx) 150° def:1.5

### .birth-save-btn
Text: "保存する"

---

## OVERLAY: #homeOverlay (自宅)

Same .birth-overlay structure.

### .birth-header
- .birth-title: "🏠 自宅（現住所）"
- .birth-close: "✕"

### .birth-section (住所)
- .birth-label: "住所・地名"
- .map-search-row with .birth-input#hiHomeName + .map-search-btn#hiMapSearchBtn
- .map-result-info#hiMapResult
- #homeMap:
```
width:100%; height:200px; border-radius:12px;
margin-top:8px; border:1px solid rgba(255,255,255,0.1);
```
- .map-coords with #hiHomeLat, #hiHomeLng (readonly)

### .birth-save-btn
Text: "保存する"

---

## OVERLAY: #titleDiagOverlay (称号診断 full-screen)
```
position:fixed; inset:0; z-index:600;
background:radial-gradient(ellipse at center, #0a1220 0%, #020408 100%);
display:none; overflow:hidden;
```
NOTE: Uses .birth-overlay class as well (z-index:500, background:rgba(4,8,16,0.95), backdrop-filter:blur(12px))
When .open: display:block (via #titleDiagOverlay.open)

### Screen: #tdScreenIntro
```
.td-screen: position:absolute; inset:0;
display:flex; flex-direction:column; align-items:center; justify-content:center;
padding:20px 20px;
```

#### .td-intro-card.glass
```
max-width:340px; padding:40px 28px; border-radius:20px; text-align:center;
```
(glass styles from shared)

Contents:
- "✦" → font-size:28px; margin-bottom:12px
- "称号の儀式" → font-size:20px; font-weight:700; color:#F9D976; margin-bottom:8px
- Description text → font-size:13px; color:#ACACAC; line-height:1.7; margin-bottom:24px
  "カードがあなたを映し出します。28の問いに、直感で答えてください。"
- .birth-save-btn: "始める"
- "あとで" → margin-top:12px; font-size:11px; color:rgba(172,172,172,0.5); cursor:pointer

### Screen: #tdScreenRound (display:none initially)
```
justify-content:flex-start; padding-top:12px; (override)
```

#### .td-progress-bar
```
position:absolute; top:0; left:0; right:0; height:3px;
background:rgba(255,255,255,0.08);
```

#### .td-progress-fill#tdProgressFill
```
height:100%; background:linear-gradient(90deg,#F9D976,#E8A840);
transition:width 0.4s ease; width:0%;
```

#### .td-progress-text#tdProgressText
```
font-size:14px; color:rgba(249,217,118,0.8); letter-spacing:2px;
margin-top:20px; margin-bottom:4px; font-weight:600;
```
Text: "1 / 28"

#### .td-part-label#tdPartLabel
```
font-size:11px; color:#F9D976; letter-spacing:2px; text-transform:uppercase;
margin-bottom:16px; opacity:0.7;
```

#### .td-question#tdQuestion
```
font-size:17px; font-weight:700; color:#EAEAEA; text-align:center;
line-height:1.5; margin-bottom:4px; max-width:320px;
```

#### .td-question-en#tdQuestionEN
```
font-size:12px; color:rgba(172,172,172,0.5); text-align:center;
margin-bottom:28px; max-width:320px;
```

#### .td-cards#tdCards
```
display:flex; gap:12px; justify-content:center; align-items:center;
flex-wrap:wrap; max-width:520px; width:100%; padding:0 8px;
```

#### .td-card (dynamically created)
```
flex:0 0 calc(50% - 8px); max-width:160px; cursor:pointer; border-radius:10px;
border:2px solid transparent; transition:all 0.3s ease;
opacity:0; transform:scale(0.85); position:relative;
```
States:
- .appear: opacity:1; transform:scale(1)
- :hover: transform:scale(1.05)
- .selected: border-color:#F9D976; box-shadow:0 0 20px rgba(249,217,118,0.4); transform:scale(1.08)
- .dimmed: opacity:0.25; transform:scale(0.92); pointer-events:none
- .exit: opacity:0; transform:translateY(20px) scale(0.9); transition:all 0.4s ease

.td-card img:
```
width:100%; display:block; border-radius:8px; pointer-events:none;
```

### Axis background tinting (on .td-screen during Part 2):
```
.td-axis-power: background:radial-gradient(ellipse at center, rgba(255,68,68,0.08) 0%, transparent 70%) !important
.td-axis-mind:  background:radial-gradient(ellipse at center, rgba(107,181,255,0.08) 0%, transparent 70%) !important
.td-axis-spirit: background:radial-gradient(ellipse at center, rgba(155,107,255,0.08) 0%, transparent 70%) !important
.td-axis-shadow: background:radial-gradient(ellipse at center, rgba(80,0,100,0.1) 0%, transparent 70%) !important
.td-axis-heart: background:radial-gradient(ellipse at center, rgba(249,217,118,0.08) 0%, transparent 70%) !important
```

### Screen: #tdScreenPartTrans (display:none)
```
.td-screen (centered)
```

#### .td-part-trans-text#tdPartTransText
```
font-size:22px; font-weight:700; color:#F9D976;
letter-spacing:3px; text-transform:uppercase;
opacity:0; animation:tdFadeIn 1s ease forwards;
```

### Screen: #tdScreenForging (display:none)

#### .td-forge-container
```
text-align:center; position:relative;
```

#### .td-forge-orb#tdForgeOrb
```
width:120px; height:120px; border-radius:50%; margin:0 auto 24px;
background:radial-gradient(circle, rgba(249,217,118,0.6) 0%, rgba(249,217,118,0.1) 60%, transparent 80%);
animation:tdForgeGlow 2s ease-in-out infinite;
```
(JS overrides background color based on axis)

#### .td-forge-text
```
font-size:14px; color:#ACACAC; letter-spacing:2px;
animation:tdFadeIn 1s ease 0.5s both;
```
Text: "Forging your title..."

#### .td-forge-particles#tdForgeParticles
```
position:absolute; inset:-60px; pointer-events:none;
```

#### .td-forge-particle (dynamically created, 12 particles)
```
position:absolute; width:4px; height:4px; border-radius:50%;
background:#F9D976; opacity:0;
animation:tdParticleIn [1.5-2.5]s ease [random 0-2]s infinite;
```
(JS sets background to axis color)

### Screen: #tdScreenReveal (display:none)

#### .td-reveal-container
```
text-align:center; max-width:340px;
```

#### .td-reveal-main#tdRevealMain
```
font-size:24px; font-weight:700; color:#F9D976;
opacity:0; transform:translateY(20px);
```
When .show: animation:tdRevealUp 1.5s ease forwards

#### .td-reveal-main-en#tdRevealMainEN
```
font-size:13px; color:rgba(249,217,118,0.5); margin-top:4px;
opacity:0; transform:translateY(10px);
```
When .show: animation:tdRevealUp 1.2s ease 0.3s forwards

#### .td-reveal-line
```
width:0; height:1px; margin:16px auto;
background:linear-gradient(90deg,transparent,#F9D976,transparent);
```
When .show: animation:tdLineExpand 1s ease 1.8s forwards (→ width:60%)

#### .td-reveal-class#tdRevealClass
```
font-size:20px; font-weight:700; color:#EAEAEA; letter-spacing:3px;
opacity:0; transform:scale(1.5);
```
When .show: animation:tdStamp 0.8s cubic-bezier(0.175,0.885,0.32,1.275) 2.8s forwards

#### .td-reveal-light#tdRevealLight
```
font-size:13px; color:#ACACAC; margin-top:20px; line-height:1.6;
opacity:0; transform:translateY(10px);
```
When .show: animation:tdRevealUp 1.2s ease 3.8s forwards

#### .td-reveal-shadow#tdRevealShadow
```
font-size:13px; color:#ACACAC; margin-top:6px; line-height:1.6;
font-style:italic; opacity:0;
```
When .show: animation:tdFadeIn 1.2s ease 5s forwards

#### .td-reveal-actions#tdRevealActions
```
margin-top:28px; opacity:0;
```
When .show: animation:tdFadeIn 0.8s ease 6.2s forwards

Contents:
- .birth-save-btn: "これでいく"
- .td-retry-btn#tdRetryBtn:
```
margin-top:12px; font-size:12px; color:#ACACAC; cursor:pointer;
text-decoration:underline; text-underline-offset:3px;
```
Text: "もう一度診断する"
- .td-share-btn:
```
margin-top:16px; font-size:13px; color:#F9D976; cursor:pointer; letter-spacing:1px;
```
Text: "Share Your Title ✦"

### canvas#tdShareCanvas (hidden)
```
display:none; width:1080; height:1920;
```

---

## ANIMATIONS (Keyframes)

### @keyframes twinkle (shared/styles.css)
```
0%,100% { opacity:var(--op,0.3); transform:scale(1); }
50% { opacity:0.8; transform:scale(1.6); }
```

### @keyframes nebulaShift (shared/styles.css)
```
0% { opacity:0.6; transform:translate(-3%,-1.5%) scale(1); }
50% { opacity:1; }
100% { opacity:0.8; transform:translate(3%,1.5%) scale(1.05); }
```

### @keyframes orbPulse (shared/styles.css)
```
0%,100% { transform:scale(1); box-shadow:0 0 40px rgba(249,217,118,0.15); }
50% { transform:scale(1.07); box-shadow:0 0 60px rgba(249,217,118,0.28); }
```

### @keyframes tdFadeIn
```
to { opacity:1; }
```

### @keyframes tdForgeGlow
```
0%,100% { transform:scale(0.9); box-shadow:0 0 40px rgba(249,217,118,0.3); }
50% { transform:scale(1.15); box-shadow:0 0 80px rgba(249,217,118,0.6); }
```

### @keyframes tdRevealUp
```
to { opacity:1; transform:translateY(0); }
```

### @keyframes tdLineExpand
```
to { width:60%; }
```

### @keyframes tdStamp
```
0% { opacity:0; transform:scale(1.5); }
60% { opacity:1; transform:scale(0.95); }
100% { opacity:1; transform:scale(1); }
```

### @keyframes tdParticleIn
```
0% { opacity:0; transform:scale(0); }
30% { opacity:1; transform:scale(1.5); }
70% { opacity:0.8; transform:scale(1); }
100% { opacity:0; transform:scale(0); }
```

---

## JS FUNCTIONS (1-line descriptions)

### Section 1: Background Canvas + Stars
- `animBg()` — Draws animated radial gradient background on bgCanvas with floating gold nebula
- `makeStars()` — Creates 45 star divs with random size/position/animation in #starContainer
- `renderNav('sanctuary')` — Renders bottom nav tabs with sanctuary as active (from shared/nav.js)

### Section 2: Settings SVG Icons
- IIFE — Maps icon IDs (si-birth, si-home, si-house, si-telescope, si-globe, si-bell, si-doc) to SOLARA_ICONS SVGs

### Section 3: Profile Management
- `loadProfile()` — Reads solara_profile from localStorage, returns parsed object or null
- `saveProfileData(p)` — Writes profile object to localStorage
- `renderProfileDisplay()` — Updates profileName, birthInfoVal, homeVal based on stored profile
- `formatDate(d)` — Converts "YYYY-MM-DD" to "YYYY年M月D日"
- `syncHomeToStorage(key, profile)` — Syncs home coords to VP slots / locations in localStorage
- `syncHomeToVP(profile)` — Calls syncHomeToStorage for both solara_vp_slots and solara_locations

### Section 4: Birth Info Overlay
- `openBirthInfo()` — Opens birth overlay, populates form fields from profile, inits Leaflet map
- `closeBirthInfo()` — Closes birth overlay
- `toggleTimeUnknown()` — Toggles birth time input disabled state and noon hint visibility
- `setBirthMapLocation(lat, lng, doReverse)` — Sets marker on map, optionally reverse-geocodes
- `searchBirthPlace()` — Forward geocodes birth place name via Nominatim API
- `saveBirthInfo()` — Validates and saves birth info, auto-updates title if sun/moon changed

### Section 5: Home Info Overlay
- `openHomeInfo()` — Opens home overlay, populates from profile, inits Leaflet map
- `closeHomeInfo()` — Closes home overlay
- `setHomeMapLocation(lat, lng, doReverse)` — Sets marker on home map
- `searchHomePlace()` — Forward geocodes home place name via Nominatim
- `saveHomeInfo()` — Validates and saves home info, syncs to VP slots

### Section 6: House System Setting
- `initHouseUI()` — Sets house system display label and checkmark visibility
- `toggleHouseSelect()` — Toggles house selection panel visibility
- `setHouseSystem(val)` — Sets house system to 'placidus' or 'whole_sign', saves to localStorage
- IIFE — Disables house system row if birthTimeUnknown (opacity:0.35, cursor:default)

### Section 7: Orb Settings Overlay
- `buildOrbRows(container, items, store, storeKey)` — Renders slider rows for aspect orbs
- `formatOrbVal(v)` — Formats number to "N°" or "N.N°"
- `resetOrbs()` — Resets all orbs to default values
- `stepOrb(storeKey, key, delta)` — Increments/decrements orb value by 0.5, clamp 0.5-8
- `openOrbOverlay()` — Opens orb overlay, builds rows, positions default marks
- `positionDefaultMarks()` — Positions default-value indicator marks on sliders
- `closeOrbOverlay()` — Closes orb overlay
- `updateOrbVal(storeKey, key, val)` — Updates orb display value from slider input
- `saveOrbOverlay()` — Saves orb settings to localStorage
- `updateOrbSummary()` — Updates orbSummaryVal to "All N°" or "Custom"

### Section 8: Title Diagnosis System

#### Data Constants
- `IMG_BASE` — Card image base path '../card-images/'
- `SUN_ADJ` — 12 sun sign adjectives (JP/EN)
- `MOON_NOUN` — 12 moon sign nouns (JP/EN)
- `TITLE_144` — 144 sun×moon title combinations (light/shadow JP text)
- `TITLE_CLASSES` — 5 axes × 5 courts = 25 class names
- `CLASS_NAME_JP` — Japanese class names (25 entries)
- `CLASS_TEXT` — Light/shadow descriptions JP/EN for all 25 classes
- `TD_ROUNDS` — 28 question rounds with card options (Part1:R1-R9 Minor, Part2:R10-R24 Major, Part3:R25-R28 Court)
- `PART_NAMES` — {1:'Minor Arcana', 2:'Major Arcana', 3:'Court Cards'}

#### Sign Calculation
- `getSunSign(dateStr)` — Returns zodiac sign from birth date
- `getMoonSign(dateStr, timeStr)` — Approximates moon sign from date/time

#### State Machine
- `TD` — State object: state, round, selections, axisScores, courtSelections, result fields
- `resetTD()` — Resets all TD state to initial values
- `showTDScreen(id)` — Hides all .td-screen, shows the one with given id
- `startDiagnosis()` — Validates profile exists, opens title diagnosis overlay at intro screen
- `closeDiagnosis()` — Closes overlay and resets state
- `beginRounds()` — Starts round phase from round 0
- `showRound(idx)` — Shows round, handles part transitions (1.5s delay)
- `renderRound(idx, r, displayNum)` — Renders progress bar, question text, card grid with preloading
- `animateCardsIn()` — Staggers card .appear class at 120ms intervals
- `selectCard(roundIdx, cardIdx)` — Records selection, scores axis/court, animates exit, advances round

#### Scoring
- `getLeadingAxis()` — Returns the axis with highest score
- `applyWildcard()` — Adds 1 point to lowest-scoring axis
- `determineFinalAxis()` — Returns winning axis (tiebreak: latest selection)
- `determineCourt()` — Returns court rank with 2+ selections, or 'mixed'
- `computeResults()` — Computes final axis/court/class/title, saves, starts forging

#### Persistence
- `saveTitleData()` — Saves title results to localStorage (6 keys + diagnosis count)
- `loadTitleData()` — Loads title main + class from localStorage

#### Forging Animation
- `startForging()` — Shows forging screen, creates 12 colored particles, transitions to reveal after 6s

#### Reveal Animation
- `startReveal()` — Shows reveal screen, populates text, triggers staggered .show animations
- `acceptTitle()` — Closes diagnosis, renders title display
- `retryDiagnosis()` — Clears saved title data, restarts from round 0

### Section 9: Share Card System
- `ZODIAC_GLYPHS` — Unicode zodiac symbols (12 entries)
- `ZODIAC_JP` — Japanese zodiac names (12 entries)
- `CLASS_FILE` — Lowercase filename for each class
- `AXIS_COLORS` — Accent/glow colors per axis (power:#ff4444, mind:#6bb5ff, spirit:#9b6bff, shadow:#c06bff, heart:#F9D976)
- `loadShareImage(src)` — Returns Promise loading an image with cache
- `shareTitle()` — Loads zodiac/class images, calls renderShareCard or fallback
- `renderShareCard(bgImg, classImg, sunImg, moonImg, info)` — Draws 1080x1920 share card on canvas with bg, zodiac icons, title, class
- `renderShareCardFallback(...)` — Text-only fallback share card (no images)
- `drawCover(ctx, img, w, h)` — Cover-fit draws image on canvas
- `downloadCanvas(canvas)` — Triggers download of canvas as PNG
- `determineFinalAxisFromScores(scores)` — Determines final axis from stored scores object

### Section 10: Title Display in Sanctuary
- `renderTitleDisplay()` — Shows/hides title card wrapper, start button, need-profile message, rediagnose button based on profile and saved title state. Populates vcard with zodiac images, class icons, title text, background image.

### Section 11: Init
- `renderTitleDisplay()` — Called on page load

---

## JS-DRIVEN VISIBILITY/STATE CHANGES SUMMARY

| Element | Default State | Shown When |
|---------|---------------|------------|
| #birthOverlay | display:none | .open class added via openBirthInfo() |
| #orbOverlay | display:none | .open class added via openOrbOverlay() |
| #homeOverlay | display:none | .open class added via openHomeInfo() |
| #titleDiagOverlay | display:none | .open class added via startDiagnosis() |
| #titleResultWrapper | display:none | display:block when title data exists |
| #titleStartBtn | display:block | shown when profile exists but no title |
| #titleNeedProfile | display:none | shown when no profile/birthDate |
| #titleRediagnose | display:none | shown when title exists (button below card) |
| #houseSelectPanel | display:none | toggled by toggleHouseSelect() |
| .time-noon-hint | display:none | .show when time-unknown checked |
| .map-result-info | display:none | .show after geocode result |
| #houseSystemRow | normal | opacity:0.35, cursor:default, onclick:null when birthTimeUnknown |
| .td-card states | opacity:0; scale(0.85) | .appear → visible; .selected/.dimmed/.exit |
| Reveal elements | opacity:0 | .show class with staggered animations |
