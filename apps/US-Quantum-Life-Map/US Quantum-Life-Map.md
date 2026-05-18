# 🌌 Quantum Life Map: The Comprehensive Blueprint (Project Bible)

This document is the master specification for "Quantum Life Map," a high-end Flutter native application designed for the US market. It integrates sacred geometry, Western astrology, and the philosophy of "All-Acceptance (全肯定)."

---

## 1. Core Concept & Philosophy
- **Identity:** A life-tracking app that visualizes daily existence as a 28-day cosmic spiral.
- **Guidance:** Managed by "Stella," a spirit of light who provides "All-Acceptance" feedback.
- **The 28-Day Cycle:** Synchronized with lunar and biological rhythms. Life is seen as an ascending spiral, not a linear calendar.

---

## 2. Logic: The Vibe Score Calculation
The app's behavior is driven by the daily "Vibe Score" ($S$).
- **The Formula:** $$S = (Tarot \times 0.7) + (Mood \times 0.1) + (Astrology \times 0.2)$$
- **Components:**
    - **Tarot (70%):** A daily draw of one of the 22 Major Arcana. Each card has a fixed constant from -1.0 (Static/Winter) to +1.0 (Dynamic/Summer).
    - **Mood (10%):** User's conscious feeling (5% of human consciousness).
    - **Astrology (20%):** Real-time Sun and Moon transit calculations based on GPS location and user's birth data (Date, Time, City).

---

## 3. Visual System: 5-Element Shaders
The UI uses custom Fragment Shaders to create an immersive, "living" background.

### 3.1 The Five Elements
1. **Fire (Ignite):** Upward sparks, warm golden glow. (e.g., The Sun, The Magician)
2. **Water (Flow):** Deep ripples, sinking light. (e.g., The Moon, The High Priestess)
3. **Air (Breathe):** Swirling wind particles, high transparency. (e.g., The Lovers, The Star)
4. **Earth (Root):** Heavy crystalline textures, grounded dust. (e.g., The Hermit, The Hierophant)
5. **Aether (Prism):** **[CORE ELEMENT]** Translucent rainbow refractions, warping space. (Used for The Fool, The Tower, The World)

### 3.2 Visual Logic
- **Maturation (28-day Gradation):** The element evolves over 4 weeks (Seed → Flame → Embers → Ash).
- **Marriage (Mixing):** The "Cycle Seed" element (70%) blends with the "Daily Vibe" element (20%) (e.g., Fire + Water creates a "Mystical Steam" effect).

---

## 4. Functional Specifications

### 4.1 Spiral Plotting & Ascension
- **Spiral Equation:** Archimedean spiral ($r = a + b\theta$).
- **Blank Days:** Missed days are connected via smooth Spline Curves (Catmull-Rom). Stella interprets these as "Perfect Rest."
- **Day 28 Ritual:** Dots connect into a unique constellation. The map "Ascends" into the **Private Galaxy (Archive)**, and the cycle resets immediately to Day 0.

### 4.2 Task Downgrade (Stella's Intervention)
- **Trigger:** If $S < -0.5$ (Deep Winter).
- **Action:** Stella proposes a "Downgrade" (e.g., "Gym" becomes "Just put on your shoes"). 
- **User Choice:** User must approve the downgrade. Once approved, completion is logged as a standard "Success."

### 4.3 Sanctuary Sleep
- **Silent Hours:** Default 11 PM – 7 AM. Stella goes silent.
- **OS Sync:** Must strictly follow OS settings (Silent mode = No sound/haptics. Vibrate mode = Haptics only).

---

## 5. Technical Implementation (Flutter Native)

### 5.1 Fragment Shader (`stella_bg.frag`)
```glsl
// Logic for Aether warping and Element Marriage
#version 460 core
#include <flutter/the_shader.glsl>

uniform float uTime;
uniform vec2 uSize;
uniform vec4 uElementColor;  // Base Seed Element
uniform vec4 uVibeColor;     // Daily Vibe
uniform float uProgress;     // 28-day cycle progress
uniform float uAetherMix;    // Aether activation (0 or 1)

out vec4 fragColor;

mat2 rotate(float a) { return mat2(cos(a), -sin(a), sin(a), cos(a)); }

void main() {
    vec2 uv = (gl_FragCoord.xy * 2.0 - uSize.xy) / min(uSize.x, uSize.y);
    
    // Aether Prismatic effect
    vec3 aether = vec3(0.0);
    for(float i = 1.0; i < 3.0; i++){
        uv = rotate(uTime * 0.1) * uv;
        aether.r += abs(0.04 / sin(uv.x + uTime * 0.2));
        aether.b += abs(0.04 / sin(uv.y + uTime * 0.3));
    }

    vec3 base = mix(uElementColor.rgb, uVibeColor.rgb, 0.3);
    vec3 final = mix(base * (0.5 + uProgress), aether, uAetherMix * 0.5);
    fragColor = vec4(final, 1.0);
}