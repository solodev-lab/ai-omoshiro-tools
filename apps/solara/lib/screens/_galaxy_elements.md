# Galaxy Screen - Element Inventory (galaxy.html)

> Source: `apps/solara/mockup/galaxy.html` (~1861 lines)
> Created for Flutter porting verification.
> Every CSS value is copied EXACTLY from the HTML/CSS source.

---

## CSS Variables (from shared/styles.css :root)

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

### * (global reset)
```
margin: 0; padding: 0; box-sizing: border-box
```

### body
```
background: radial-gradient(ellipse at center, #0a1220 0%, #020408 100%)
min-height: 100vh
font-family: var(--font-body)  /* 'DM Sans', 'Segoe UI', sans-serif */
color: #EAEAEA
margin: 0
padding: 0
overflow: hidden
```

---

## 1. .phone.cosmic-bg #phone (root container)

### .phone (shared/styles.css)
```
width: 100%; min-height: 100vh; background: var(--bg-deep) /* #080C14 */
overflow: hidden; position: relative
```

### .cosmic-bg (shared/styles.css)
```
position: relative
background:
  radial-gradient(ellipse at 50% 0%, #0f2850 0%, var(--bg-deep) 55%),
  radial-gradient(ellipse at 30% 100%, #060e20 0%, transparent 65%)
```

### .cosmic-bg::before (CSS pseudo - nebula layer 1)
```
content: ''
position: fixed; inset: 0
background:
  radial-gradient(ellipse at 10% 15%, rgba(38,208,206,0.22) 0%, transparent 40%),
  radial-gradient(ellipse at 90% 20%, rgba(249,217,118,0.16) 0%, transparent 35%),
  radial-gradient(ellipse at 45% 65%, rgba(100,70,200,0.18) 0%, transparent 45%),
  radial-gradient(ellipse at 75% 55%, rgba(180,140,255,0.10) 0%, transparent 30%),
  radial-gradient(circle at 20% 85%, rgba(249,217,118,0.10) 0%, transparent 25%),
  radial-gradient(circle at 85% 80%, rgba(38,208,206,0.08) 0%, transparent 20%),
  radial-gradient(ellipse at 50% 30%, rgba(255,255,255,0.025) 0%, transparent 35%)
z-index: 0; pointer-events: none
```

### .cosmic-bg::after (CSS pseudo - nebula layer 2)
```
content: ''
position: fixed; inset: 0
background:
  radial-gradient(ellipse at 65% 8%, rgba(220,200,255,0.07) 0%, transparent 35%),
  radial-gradient(ellipse at 15% 45%, rgba(38,208,206,0.10) 0%, transparent 30%),
  radial-gradient(ellipse at 80% 65%, rgba(249,217,118,0.08) 0%, transparent 25%),
  radial-gradient(circle at 50% 50%, rgba(255,255,255,0.015) 0%, transparent 50%)
z-index: 0; pointer-events: none
animation: nebulaShift 18s ease-in-out infinite alternate
```

---

## 2. canvas#bgCanvas (background canvas - JS animated)
```
position: absolute; inset: 0
z-index: 0
width: 100%; height: 100%
```
**JS renders:**
- Radial gradient center: #0C1D3A -> #080C14 (radius = max(w,h)*0.6)
- Nebula 1: moves with sin(t*0.6)/cos(t*0.4), radius 220, colors: rgba(38,208,206,0.07), rgba(26,41,128,0.05), transparent
- Nebula 2: moves with cos(t*0.35)/sin(t*0.5), radius 160, colors: rgba(249,217,118,0.06), transparent
- Animation speed: bgT += 0.004 per frame

---

## 3. #starContainer (star field - JS generated)
```
position: absolute; inset: 0; z-index: 1; pointer-events: none; overflow: hidden
```
**JS creates 65 .star divs:**
- Size: random * 1.8 + 0.5 px
- Position: random left/top %
- CSS vars: --dur (2+random*4)s, --delay (random*5)s, --op (0.1+random*0.35)

### .star (shared/styles.css)
```
position: absolute; border-radius: 50%; background: white; z-index: 1
animation: twinkle var(--dur,3s) ease-in-out infinite var(--delay,0s)
```

---

## 4. .screen.active (main screen wrapper)
```
/* from galaxy.html */
position: fixed; inset: 0; z-index: 5
/* inline: flex-direction: column */

/* from shared/styles.css .screen */
position: absolute; inset: 0; z-index: 10; display: none; flex-direction: column
/* .screen.active => display: flex */
```

---

## 5. .main-area
```
position: fixed
top: 0; left: 0; right: 0; bottom: 80px
display: flex; flex-direction: column
overflow: hidden; z-index: 10
```

---

## 6. .inner-tabs (tab bar: Cycle / Star Atlas)
```
display: flex; gap: 0
padding: 0 20px
margin-bottom: 8px
```

### .inner-tab-btn (x2 buttons)
```
flex: 1
padding: 10px 0
background: none; border: none; cursor: pointer
font-family: var(--font-body)
font-size: 12px; font-weight: 700
letter-spacing: 1px; text-transform: uppercase
color: rgba(255,255,255,0.35)
border-bottom: 2px solid transparent
transition: all 0.3s
```

### .inner-tab-btn.active
```
color: #F9D976
border-bottom-color: #F9D976
```

Button text: "Cycle" (with emoji), "Star Atlas" (with emoji)

---

## 7. #panel-cycle.tab-panel (Cycle tab)

### .tab-panel
```
display: none; flex: 1; flex-direction: column; overflow: hidden
```
### .tab-panel.active
```
display: flex
```

### .cycle-content
```
flex: 1; position: relative
display: flex; flex-direction: column; overflow: hidden
```

---

## 8. .moon-badge #moonBadge (top-left badge)
```
position: absolute
top: 8px; left: 20px
background: rgba(192,200,224,0.10)
border: 1px solid rgba(192,200,224,0.22)
border-radius: 22px
padding: 8px 14px
display: flex; flex-direction: column; align-items: center
z-index: 20
```

### .moon-emoji #moonEmoji
```
font-size: 20px; line-height: 1
```
Default text: moon phase emoji (JS: getMoonPhaseInfo().emoji)

### .moon-lbl #moonLabel
```
font-size: 9px
color: rgba(192,200,224,0.65)
letter-spacing: 1px; text-transform: uppercase
margin-top: 2px
```
Default text: "First Quarter" (JS: getMoonPhaseInfo().label)

---

## 9. .day-badge (top-right badge)
```
position: absolute
top: 8px; right: 20px
background: rgba(249,217,118,0.12)
border: 1px solid rgba(249,217,118,0.28)
border-radius: 22px
padding: 8px 14px
display: flex; flex-direction: column; align-items: center
z-index: 20
```

### .day-num #dayNum
```
font-size: 22px; font-weight: 700
color: #F9D976; line-height: 1
```
Text: ACTIVE (current moon cycle day)

### .day-lbl #dayLbl
```
font-size: 9px
color: rgba(249,217,118,0.65)
letter-spacing: 1.2px; text-transform: uppercase
```
Text: "of {TOTAL}" (e.g. "of 30")

---

## 10. .spiral-area (spiral canvas container)
```
flex: 1; position: relative
```

### canvas#spiralCanvas
```
width: 100%; height: 100%; display: block
```
**JS sets:** cursor: grab (grabbing while dragging)
**Canvas renders (see JS section 16 below for full detail):**
- Ghost spiral path (500 points, 4.6 PI turns)
- Spiral anchor dots (TOTAL dots)
- Reading dots at Golden Angle positions with 3D z-layers
- Connection threads (dashed: 3,6)
- Stella core glow at center

---

## 11. .dot-popup #dotPopup (tooltip on spiral dots)
```
position: absolute
background: rgba(8,12,20,0.95)
backdrop-filter: blur(20px)
border: 1px solid rgba(255,255,255,0.15)
border-radius: 18px
padding: 14px 16px
width: 200px
z-index: 60; pointer-events: none
opacity: 0; transition: opacity 0.2s
```
### .dot-popup.visible
```
opacity: 1
```

### .popup-day #popupDay
```
font-size: 10px; font-weight: 700
color: #F9D976
letter-spacing: 1.5px; text-transform: uppercase
margin-bottom: 8px
```

### .popup-card (flex row)
```
display: flex; align-items: center; gap: 8px
margin-bottom: 8px
```

### .popup-card-emoji #popupEmoji
```
font-size: 22px
```

### .popup-card-name #popupCardName
```
font-size: 12px; font-weight: 700; color: #EAEAEA
```

### .popup-planet #popupPlanet
```
font-size: 11px; color: rgba(172,172,172,0.8)
margin-bottom: 4px
```

### .popup-keyword #popupKeyword
```
font-size: 11px; font-weight: 300; color: rgba(249,217,118,0.7)
```

### .popup-quote #popupQuote
```
font-size: 11px; font-weight: 300
color: rgba(172,172,172,0.7)
line-height: 1.5; margin-top: 6px; font-style: italic
```

---

## 12. #panel-atlas.tab-panel (Star Atlas tab)

### .atlas-content
```
flex: 1; overflow-y: auto
padding: 0 16px 100px
display: flex; flex-direction: column; gap: 20px
```
### .atlas-content::-webkit-scrollbar
```
display: none
```

### div wrapper (inline padding)
```
padding: 0 4px
```

### .screen-h1 (shared/styles.css)
```
font-size: 24px; font-weight: 700
color: var(--text-primary) /* #EAEAEA */
font-family: var(--font-heading) /* 'Cormorant Garamond', 'Georgia', serif */
```
Text: "Star Atlas"

### .screen-h2 (shared/styles.css)
```
font-size: 13px; font-weight: 300
color: var(--text-secondary) /* #ACACAC */
margin-top: 4px
font-family: var(--font-body) /* 'DM Sans' */
```
Text: "Your completed cosmic cycles"

---

## 13. .constellation-grid #galaxyGrid (JS-generated cards)
```
display: grid
grid-template-columns: repeat(auto-fill, minmax(160px, 1fr))
gap: 12px
```

### .const-card (JS-generated per cycle)
```
border-radius: 20px
padding: 14px
aspect-ratio: 0.75
display: flex; flex-direction: column; justify-content: space-between
cursor: pointer
transition: transform 0.2s, box-shadow 0.2s
```
**Inline style (JS):**
```
background: linear-gradient(135deg, {cycle.bgGrad[0]}, {cycle.bgGrad[1]})
border: 1px solid {cycle.borderColor}
```
### .const-card:hover
```
transform: scale(1.03)
```

### .const-mini (canvas container)
```
flex: 1; display: flex; align-items: center; justify-content: center
```
Contains: canvas (width=80, height=80, border-radius: 10px)

### .const-date (shape type label)
```
font-size: 10px; color: #ACACAC
```

### .const-seed (constellation name)
```
font-size: 12px; font-weight: 700; color: #EAEAEA; margin-top: 2px
```

### Inline elements in card meta:
- Name JP: font-size: 11px; color: #ACACAC
- Stats: font-size: 10px; color: rgba(172,172,172,0.6); margin-top: 2px
- Rarity stars: letter-spacing: 2px, colors: >=4 stars=#F9D976, >=3=#B080FF, else=#888

---

## 14. .stella-msg.glass (Stella message bubble)

### .stella-msg
```
margin: 0 16px 6px
padding: 12px 16px 14px
border-radius: 20px
position: relative; flex-shrink: 0
```
Inline: flex-shrink: 0

### .glass (shared/styles.css)
```
background: rgba(255,255,255,0.06)
backdrop-filter: blur(20px); -webkit-backdrop-filter: blur(20px)
border: 1px solid rgba(255,255,255,0.12)
border-radius: 20px
box-shadow: inset 0 1px 0 rgba(255,255,255,0.06),
            inset 0 0 40px rgba(249,217,118,0.02),
            0 0 24px rgba(0,0,0,0.3)
```

### .bubble-by
```
font-size: 10px; font-weight: 700
color: #F9D976
letter-spacing: 1.8px; text-transform: uppercase
margin-bottom: 7px
```
Text: "Stella" (with star emoji)

### .bubble-msg
```
font-size: 13px; font-weight: 300
color: #EAEAEA; line-height: 1.6
```
Text: JS-generated via generateStellaMessage()

---

## 15. .bottom-nav (shared/styles.css)
```
position: fixed; bottom: 0; left: 0; right: 0
height: var(--nav-height) /* 80px */
background: linear-gradient(180deg, rgba(6,10,18,0.80) 0%, rgba(4,6,14,0.95) 100%)
backdrop-filter: blur(28px)
border-top: 1px solid rgba(249,217,118,0.06)
box-shadow: 0 -4px 30px rgba(0,0,0,0.4), inset 0 1px 0 rgba(255,255,255,0.04)
display: flex; justify-content: space-around; align-items: flex-start
padding: 10px 4px 0; z-index: 150
```

### .nav-item (shared)
```
display: flex; flex-direction: column; align-items: center; gap: 4px
background: none; border: none; cursor: pointer
padding: 6px 12px; border-radius: 14px; transition: all 0.3s
```

### .nav-icon (shared)
```
width: 24px; height: 24px
display: flex; align-items: center; justify-content: center
color: rgba(255,255,255,0.35); transition: all 0.3s
```
### .nav-item.active .nav-icon
```
color: var(--gold) /* #F9D976 */
filter: drop-shadow(0 0 8px var(--gold)) drop-shadow(0 0 16px rgba(249,217,118,0.3))
```

### .nav-label (shared)
```
font-size: 9px; color: rgba(255,255,255,0.35)
letter-spacing: 0.5px; text-transform: uppercase
font-family: var(--font-body)
```
### .nav-item.active .nav-label
```
color: var(--gold)
text-shadow: 0 0 10px rgba(249,217,118,0.4)
```

### .nav-item.active::after (glow dot)
```
content: ''; position: absolute; bottom: -2px; left: 50%
transform: translateX(-50%)
width: 4px; height: 4px; border-radius: 50%
background: var(--gold)
box-shadow: 0 0 8px 2px rgba(249,217,118,0.5), 0 0 20px 4px rgba(249,217,118,0.15)
```

---

## 16. #overlayFormation (constellation formation overlay)

### .overlay-screen (shared/styles.css)
```
position: absolute; inset: 0; z-index: 300
display: none; flex-direction: column; align-items: center; justify-content: center
background: rgba(4,8,16,0.97); backdrop-filter: blur(8px)
animation: fadeIn 0.4s ease-out
```
### .overlay-screen.visible
```
display: flex
```

### #overlayFormation specific override
```
background: rgba(2,4,10,0.98)
```

### canvas#formationCanvas
```
position: absolute; inset: 0; width: 100%; height: 100%
```

### .formation-ui #formationUI
```
position: absolute
bottom: 120px; left: 0; right: 0
display: flex; flex-direction: column; align-items: center; gap: 12px
pointer-events: none
```

### .formation-stage #formationStage
```
font-size: 12px; font-weight: 700
color: rgba(249,217,118,0.6)
letter-spacing: 2px; text-transform: uppercase
```
Text: "CONVERGENCE"

### .formation-symbol #formationSymbol
```
font-size: 44px
```
Inline: opacity: 0 (animated by JS)

### .formation-name #formationName
```
font-size: 28px; font-weight: 700
text-align: center; padding: 0 24px
```
Inline: opacity: 0 (animated by JS)

### .formation-quote #formationQuote
```
font-size: 13px; font-weight: 300
color: rgba(172,172,172,0.8)
line-height: 1.6; text-align: center; padding: 0 28px
```
Inline: opacity: 0 (animated by JS)

### button.formation-close #formationClose
```
position: absolute
bottom: 48px; left: 50%; transform: translateX(-50%)
background: linear-gradient(135deg, #F9D976, #F6BD60)
border: none; border-radius: 16px
padding: 14px 36px
font-family: var(--font-body)
font-size: 15px; font-weight: 700; color: #0C1D3A
cursor: pointer
opacity: 0; pointer-events: none
transition: opacity 0.5s
```
### .formation-close.visible
```
opacity: 1; pointer-events: auto
```
Text: "View in Star Atlas" (with star symbol)

---

## 17. #replayModal (cycle replay modal)
```
position: absolute; inset: 0; z-index: 400
display: none; flex-direction: column; align-items: center; justify-content: center
background: rgba(2,4,10,0.96)
backdrop-filter: blur(12px)
animation: fadeIn 0.3s ease-out
```
### #replayModal.visible
```
display: flex
```

### .replay-inner
```
width: 340px
display: flex; flex-direction: column; align-items: center; gap: 20px
```

### .replay-title #replayTitle
```
font-size: 20px; font-weight: 700; margin-bottom: 4px; text-align: center
```
JS sets innerHTML with name + JP name (font-size: 14px; color: #F9D976; font-weight: 300)

### .replay-sub #replaySubtitle
```
font-size: 12px; color: #ACACAC; text-align: center
```
JS sets innerHTML with stats + rarity stars + rarityLabel (font-size: 11px; color: #ACACAC)

### canvas#replayCanvas
```
border-radius: 20px
border: 1px solid rgba(255,255,255,0.1)
background: rgba(6,10,18,0.8)
```
Attribute: width=300 height=300

### .replay-symbol #replaySymbol
```
font-size: 22px; margin-bottom: 4px; text-align: center
```
JS: opacity animated 0->1

### .replay-name #replayName
```
font-size: 16px; font-weight: 700; color: #EAEAEA; text-align: center
```
JS: opacity animated 0->1

### .replay-date #replayDate
```
font-size: 12px; color: #ACACAC; margin-top: 2px; text-align: center
```
JS: opacity animated 0->1

### button.replay-close
```
background: none
border: 1px solid rgba(255,255,255,0.2)
border-radius: 12px
padding: 10px 28px
font-family: var(--font-body)
font-size: 13px; color: #ACACAC
cursor: pointer
```
Text: "Back to Star Atlas" (with arrow)

---

## ANIMATIONS / KEYFRAMES

### @keyframes fadeIn (galaxy.html)
```
from { opacity: 0; }
to   { opacity: 1; }
```

### @keyframes fadeIn (shared/styles.css - different!)
```
from { opacity: 0; transform: translateY(6px); }
to   { opacity: 1; transform: translateY(0); }
```

### @keyframes nebulaShift (shared/styles.css)
```
0%   { opacity: 0.6; transform: translate(-3%, -1.5%) scale(1); }
50%  { opacity: 1; }
100% { opacity: 0.8; transform: translate(3%, 1.5%) scale(1.05); }
duration: 18s ease-in-out infinite alternate
```

### @keyframes twinkle (shared/styles.css)
```
0%,100% { opacity: var(--op,0.3); transform: scale(1); }
50%     { opacity: 0.8; transform: scale(1.6); }
```

### @keyframes cosmicTwinkle (shared/styles.css)
```
0%,100% { opacity: var(--op, 0.15); transform: scale(1) rotate(0deg); }
50%     { opacity: 0.95; transform: scale(1.8) rotate(var(--rot, 0deg)); }
```

---

## JS CONSTANTS

### PLANET_COLORS
```
sun: #FFD700, moon: #C0C8E0, mercury: #7BE0AD, venus: #FF8FA0,
mars: #FF4444, jupiter: #6B5BFF, saturn: #8B7355, uranus: #00D4FF,
neptune: #9B6BFF, pluto: #2A0030
```

### ELEMENT_COLORS
```
fire: #FF6B35, water: #4DA8DA, air: #B8C4D0, earth: #C4A265
```

### RARITY_LABELS
```
['Common', 'Uncommon', 'Rare', 'Legendary', 'Mythic']
```

### RARITY_COLORS
```
['#888', '#4DA8DA', '#B080FF', '#F9D976', '#FF6B35']
```

### ADJ_COLORS (20 adjective colors)
```
[0] #F9D976, [1] #C4923A,
[2] #C0C8E0, [3] #E8ECF8,
[4] #DC143C, [5] #FF6B35,
[6] #7EB8DA, [7] #B8D8F0,
[8] #9B6BFF, [9] #5A2D82,
[10] #4A4A5A, [11] #6A6A7A,
[12] #68C8E8, [13] #1A3A5A,
[14] #5AA050, [15] #3A5A2A,
[16] #F0F0FF, [17] #D0D8F0,
[18] #FFF4C0, [19] #C8A0FF
```

### Spiral rendering constants
```
sp.rotX: -0.32 (initial)
sp.rotY: 0.4 (initial)
sp.zoom: 1 (initial, range 0.48-3.5)
CAM_ANGLE_55: 55 * PI / 180
GOLDEN_ANGLE: 137.508 * PI / 180
Auto-rotate speed: sp.rotY += 0.0025 per frame
Drag velocity damping: *= 0.90
```

### Spiral visual parameters
```
FOV: 360 * sp.zoom
Center: cx = W/2, cy = H*0.44
Base spiral factor: b = min(W,H) * 0.057
ZSPAN: 55
Ghost spiral: 500 points, PI * 4.6 turns
Spiral dots: PI * 4.2 turns
```

### Dot sizes (reading dots)
```
Major card: baseSize = 8, glowBlur = 12
Minor card: baseSize = 4, glowBlur = 6
Full moon: baseSize *= 1.5
New moon: baseSize *= 0.75
Active day: baseSize = max(baseSize, 6.5)
Breath animation: 0.7 + 0.3 * sin(...)
```

### Ghost spiral path stroke
```
color: rgba(192,200,224,{alpha})
alpha: max(0.05, 0.30 * scale * fade)
lineWidth: max(0.8, 1.4 * scale * fade)
```

### Connection threads (spiral to GA dot)
```
strokeStyle: rgba(249,217,118,0.06)
lineWidth: 0.5
lineDash: [3, 6]
```

### Stella core glow (center of spiral)
```
Outer: radius 20, radialGradient rgba(249,217,118,0.15) -> transparent
Inner: radius 6 (gradient to 8), rgba(249,217,118,0.6) -> transparent
```

### Current day ring
```
radius: 11 * scale
strokeStyle: rgba(249,217,118,{0.5*scale})
lineWidth: 1.5
```

### Full moon ring
```
shadowColor: #FFF0C0, shadowBlur: 18
ring radius: dotR + 4*scale
strokeStyle: rgba(255,240,192,{0.5*scale})
lineWidth: 2
Radial glow: radius dotR + 12*scale, rgba(255,240,192,0.15) -> transparent
```

### New moon dot
```
fillStyle: #2A0030
stroke ring: dotR + 1, rgba(155,107,255,0.4), lineWidth 0.8
```

### 5% random ring (non-fullmoon, non-newmoon)
```
condition: (d * 31 + TOTAL * 7) % 100 < 5
shadowColor: cardColor, shadowBlur: 10
ring radius: dotR + 3*scale
strokeStyle: hexToRgba(col, 0.3*scale), lineWidth: 1.2
```

---

## JS-DRIVEN VISIBILITY / STATE CHANGES

1. **Tab switching**: .inner-tab-btn.active / .tab-panel.active toggled by switchInner('cycle'|'atlas')
2. **Dot popup**: .dot-popup.visible added on click (nearest dot within 28px), auto-hides after 3500ms
3. **Formation overlay**: .overlay-screen#overlayFormation .visible class - currently dead code (triggerConstellationFormation deleted)
4. **Replay modal**: #replayModal.visible toggled by openReplayModal()/closeReplayModal()
5. **Replay animation**: 6500ms total
   - Camera tilt: 0-46% of time, eases from CAM_ANGLE_55 to 0
   - Line drawing: 46%-69% of time
   - Symbol/name/date fade: 69%-100% of time (opacity 0->1)
6. **Spiral auto-rotation**: rotY += 0.0025 per frame when not dragging
7. **Spiral drag**: mouse/touch -> velX/velY with 0.006 sensitivity, 0.90 damping
8. **Spiral zoom**: wheel -> *0.93 or *1.07, clamped 0.48-3.5
9. **Moon badge**: updated from getMoonPhaseInfo() on init
10. **Stella message**: updated from generateStellaMessage() on init
11. **Galaxy cards**: rendered from GALAXY_CYCLES array (61 demo cycles from DEMO_SPECS)

---

## JS FUNCTIONS (1-line descriptions)

### Section 1: Constants
- `PLANET_COLORS` - Map of planet names to hex colors (10 planets)
- `ELEMENT_COLORS` - Map of element names to hex colors (4 elements)
- `MAJOR_PLANETS` - Map of major arcana card_id (0-21) to planet name
- `SUIT_ELEMENTS` - Map of suit name to element name

### Section 2: Data
- `TAROT[]` - Array of 78 tarot cards (22 Major + 56 Minor) with name, emoji, element, keyword

### Section 3: RNG
- `mulberry32(seed)` - Seeded PRNG returning a function that produces deterministic random 0-1

### Section 4: Moon Cycle
- `getMoonCycleInfo()` - Calculates current moon phase day (1-30) from known new moon (2000-01-06)
- `moonCycle/TOTAL/ACTIVE/FULL_MOON_DAY` - Derived moon cycle constants

### Section 5: Days Data
- `generateDaysData(total, active)` - Generates tarot card assignments for each day of the cycle
- `DAYS_DATA` - Pre-computed array of day data for current cycle

### Section 6: Color Functions
- `cardToColor(dd)` - Returns hex color for a day's card (planet color for major, element color for minor)
- `hexToRgba(hex, alpha)` - Converts hex color to rgba string

### Section 7: Name Generation
- `NAME_ADJ_EN/JP[]` - 20 adjectives in EN/JP
- `ADJ_TIERS[]` - Rarity tier (0-2) per adjective
- `NAME_NOUN_EN/JP[]` - 61 nouns in EN/JP
- `NOUN_TIERS[]` - Rarity tier (0-3) per noun
- `rarityStarsHTML(stars)` - Returns HTML string of filled/empty stars with color

### Section 8: Shape System
- `NOUN_SHAPES[]` - Shape type ('loop','linear','radial','open','closed') per noun (61 entries)
- `computeMST(points)` - Prim's minimum spanning tree algorithm on 2D points
- `buildConstellationEdges(points, shapeType)` - Builds constellation edges based on MST + shape rules

### Section 9: Templates
- `NOUN_TEMPLATES{}` - 61 sets of 2D template positions for constellation star placement
- `getTemplatePositions(nounIdx, numAnchors, seed)` - Interpolates/samples template positions with jitter

### Section 10: Adjective Colors
- `ADJ_COLORS[]` - 20 hex colors mapped to adjective indices

### Section 11: Galaxy Cycles
- `GOLDEN_ANGLE` - 137.508 degrees in radians
- `placeCycleDots(majors, minors, nounIdx, seedCard, id)` - Places dots using template (majors) + golden angle (minors)
- `forceNameDemoCycle(id, seedCard, readings, adjIdx, nounIdx)` - Creates a full cycle object with name, colors, dots
- `makeDemoReadings(seedCard, count, seed, minMajor)` - Generates random tarot readings for demo
- `DEMO_SPECS[]` - 61 predefined [nounIdx, adjIdx, seedCard] triples
- `HIGH_ANCHOR_NOUNS{}` - Nouns needing extra anchors (indices: 8,9,10,11,17,27,28,36,40,50,57,60)
- `GALAXY_CYCLES[]` - Pre-built array of 61 demo cycle objects

### Section 12: Constellation Art
- `NOUN_FILENAMES[]` - 61 filenames for constellation art webp images
- `ART_IMAGES{}` - Preloaded Image objects by noun index
- `ART_BASE` - 'share-assets/constellation-art/'
- `NOUN_ART_TRANSFORMS{}` - Flip transforms per noun (only index 4: flipX)

### Section 13: Background
- `animBg()` - Continuous background canvas animation (radial gradient + 2 moving nebulae)
- `makeStars()` - Creates 65 star divs in #starContainer

### Section 14: Moon Badge
- `updateMoonBadge()` - Sets moon emoji/label and day number from cycle info

### Section 15: Inner Tabs
- `switchInner(tab)` - Toggles between 'cycle' and 'atlas' panels, starts/stops spiral animation

### Section 16: 3D Spiral
- `sp` - State object (rotX, rotY, zoom, velocities, drag state, dotPositions)
- `rot3D(x,y,z)` - 3D rotation by sp.rotX/sp.rotY
- `proj3D(x,y,z,fov,cx,cy)` - Perspective projection (fov/(fov+z+260))
- `BREATH_PHASES/PERIODS[]` - Per-dot animation phase/period arrays
- `CYCLE_GA_POSITIONS[]` - Pre-computed golden angle positions + z-layers for current cycle
- `projectGA3D(nx,ny,nz,W,H,cx,cy,camAngle,FOV)` - Anamorphic 3D projection with camera tilt
- `renderSpiral3D()` - Full render pass: ghost path + spiral dots + GA reading dots + core glow
- `startSpiral3D()` - Starts render loop with auto-rotation
- `initSpiral3D()` - Sets up mouse/touch/wheel event handlers for interaction

### Section 17: Dot Popup
- `showDotPopup(day, px, py, canvas)` - Shows tooltip near clicked dot with card info, auto-hides 3500ms
- `hideDotPopup()` - Removes .visible class from popup

### Section 18: Galaxy Cards
- `projectConstellation3D(nx,ny,nz,S,camAngle)` - Simplified 3D projection for card thumbnails
- `drawCycleOnCanvas(canvas, cycle, progress, size, camAngle)` - Renders a constellation on a canvas (bg, art overlay, field stars, edges, anchor dots)
- `renderGalaxyCards()` - Populates #galaxyGrid with .const-card elements for all GALAXY_CYCLES

### Section 19: Replay Modal
- `openReplayModal(cycleId)` - Opens modal, runs 6500ms formation animation on replayCanvas
- `closeReplayModal()` - Closes modal, cancels animation

### Section 20: Formation Overlay
- `closeFormationOverlay()` - Closes overlay, pushes formed cycle to GALAXY_CYCLES, switches to atlas

### Section 21: LocalStorage
- `CYCLE_KEY` = 'solara_galaxy_cycles'
- `DAILY_KEY` = 'solara_daily_vibes'
- `loadDailyVibes()` - Loads daily vibe scores from localStorage
- `saveDailyVibe(score)` - Saves today's vibe score
- `loadSavedCycles()` - Merges saved cycles into GALAXY_CYCLES
- `saveCycles()` - Saves GALAXY_CYCLES to localStorage

### Section 22: Init
- `renderNav('galaxy')` - Renders bottom navigation (from shared/nav.js)
- `renderGalaxyCards()` - Initial render of star atlas grid
- Debug overlay: #debugInfo (position: fixed, top:0, left:0, z-index:99999, bg: rgba(0,0,0,0.9), color: #0f0, font-size:11px)
- `initSpiral3D()` - Initializes spiral interaction
- `startSpiral3D()` - Starts spiral animation
- Stella message update from generateStellaMessage()

---

## EXTERNAL DEPENDENCIES (shared scripts)

- `shared/styles.css` - Global styles (variables, .glass, .bottom-nav, .star, .screen-h1/h2, .overlay-screen)
- `shared/icons.js` - SVG icons for nav
- `shared/nav.js` - renderNav() function
- `shared/vibe.js` - loadVibe() function
- `shared/stella.js` - generateStellaMessage() function
- `shared/events.js` - getMoonPhaseInfo(), checkMoonEvents() functions

---

## ELEMENT COUNT SUMMARY

**DOM elements in body:**
- 1 canvas#bgCanvas
- 1 #starContainer (+ 65 JS-generated .star divs)
- 1 .screen.active container
- 1 .main-area
- 2 .inner-tab-btn buttons
- 1 #panel-cycle with cycle-content, moon-badge, day-badge, spiral-area, spiralCanvas, dot-popup (with 5 child info divs)
- 1 #panel-atlas with atlas-content, headings, galaxy-grid (JS fills with 61 .const-card)
- 1 .stella-msg with bubble-by + bubble-msg
- 1 .bottom-nav (JS-rendered with 5 nav items)
- 1 #overlayFormation with formationCanvas, formation-ui (stage/symbol/name/quote), formation-close button
- 1 #replayModal with replay-inner (title, subtitle, replayCanvas, symbol, name, date, close button)

**Total static DOM elements: ~35 + 65 stars + 61 galaxy cards + 5 nav items = ~166**
