# Sanctuary（サンクチュアリ・プロフィール）

**ソースファイル**: `mockup/sanctuary.html`
**HTML行数**: 2611行（うちJS約1727行）
**イベント数**: 28個
**API呼び出し**: 4箇所

---
## この画面の説明（日本語メモ）

> ここにオーナーが日本語で画面の説明を書く。
> 例：「世界地図が表示される。タップした場所の運勢が見れる。」

---
## 要素一覧（HTML上から順）

1. `<div #phone>`
  CSS: width:100%; min-height:100vh; background:#080C14; position:relative; overflow:hidden
  2. `<canvas #bgCanvas>`
    CSS: width:100%; height:100%; position:absolute; z-index:0
  3. `<div #starContainer>`
  4. `<div .status-bar>`
    CSS: height:44px; font-size:12px; font-weight:700; color:rgba(234,234,234,0.9); padding:0 28px; position:fixed
    5. `<span>` — テキスト:「9:41」
    6. `<span>` — テキスト:「✦ SOLARA ✦」
    7. `<span>` — テキスト:「87%🔋」
  8. `<div .main-area>`
    CSS: background:radial-gradient(ellipse at 50% 0%, #0f2850 0%, #080C14 55%),
    radial-gradient(ellipse at 30% 100%, #060e20 0%, transparent 65%); position:relative; display:flex; flex-direction:column; z-index:10
    9. `<div .sanctuary-content>`
      CSS: width:100%; max-width:600px; padding:56px 20px 100px; margin:0 auto; position:relative; display:flex
      10. `<div .profile-row>`
        CSS: display:flex; gap:14px
        11. `<div .profile-orb>` — テキスト:「✦」
          CSS: width:56px; height:56px; font-size:24px; background:radial-gradient(circle,rgba(249,217,118,0.25) 0%,rgba(249,217,118,0.04) 70%); border-radius:50%; display:flex
        12. `<div>`
          13. `<div #profileName>` — テキスト:「Hayashi Koji」
            CSS: font-size:20px; font-weight:700
          14. `<div .profile-tier>` — テキスト:「Free Tier · Cosmic Journey」
            CSS: font-size:12px; color:#ACACAC
      15. `<div .settings-group>`
        CSS: display:flex; flex-direction:column; gap:10px
        16. `<div .section-label>` — テキスト:「✦ Stellar Profile」
          CSS: font-size:11px; font-weight:700; color:#F9D976
        17. `<div .settings-item>`
          CSS: background:rgba(255,255,255,0.06); padding:14px 18px; border-radius:20px; display:flex
          18. `<div .settings-left>`
            CSS: display:flex; gap:12px
            19. `<div #si-birth>`
              CSS: width:36px; height:36px; font-size:17px; color:rgba(249,217,118,0.7); background:rgba(255,255,255,0.05); border-radius:10px
            20. `<div .settings-txt>` — テキスト:「出生情報」
              CSS: font-size:14px
          21. `<div #birthInfoVal>` — テキスト:「未設定 ›」
            CSS: font-size:13px; color:#ACACAC
        22. `<div .settings-item>`
          CSS: background:rgba(255,255,255,0.06); padding:14px 18px; border-radius:20px; display:flex
          23. `<div .settings-left>`
            CSS: display:flex; gap:12px
            24. `<div #si-home>`
              CSS: width:36px; height:36px; font-size:17px; color:rgba(249,217,118,0.7); background:rgba(255,255,255,0.05); border-radius:10px
            25. `<div .settings-txt>` — テキスト:「自宅（現住所）」
              CSS: font-size:14px
          26. `<div #homeVal>` — テキスト:「未設定 ›」
            CSS: font-size:13px; color:#ACACAC
      27. `<div #titleSection>`
        CSS: display:flex; flex-direction:column; gap:10px
        28. `<div .section-label>` — テキスト:「✦ Title Diagnosis」
          CSS: font-size:11px; font-weight:700; color:#F9D976
        29. `<div #titleResultWrapper>`
          30. `<div .td-result-card-inner>`
            CSS: height:480px; position:relative
            31. `<div .td-result-face>`
              CSS: padding:28px 20px 24px; border-radius:16px; display:flex; flex-direction:column; overflow:hidden
              32. `<div #vcardBgLight>`
                CSS: position:absolute; z-index:0
              33. `<div #vcardOverlayLight>`
                CSS: position:absolute; z-index:1
              34. `<div .td-vcard-content>`
                CSS: width:100%; position:relative; z-index:2
                35. `<div .td-vcard-label>` — テキスト:「✦ LIGHT ✦」
                  CSS: font-size:10px; font-weight:300
                36. `<div #vcardZodiacLight>`
                  CSS: display:flex; gap:48px
                37. `<div .td-vcard-line>`
                  CSS: width:70%; height:1px; background:linear-gradient(90deg, transparent, rgba(249,217,118,0.6), transparent); margin:10px auto 12px
                38. `<div #vcardLightTitle>`
                  CSS: font-size:19px; font-weight:700; color:#F9D976; margin:4px 0 10px
                39. `<div .td-vcard-class-icon-frame>`
                  CSS: width:148px; height:148px; background:radial-gradient(circle, #0a0a14 60%, rgba(10,10,20,0.9) 75%, transparent 85%); margin:8px auto 10px; border-radius:50%; position:relative
                  40. `<img #vcardClassIconLight>`
                    CSS: width:100px; height:100px; background:#0a0a14; border-radius:50%; position:relative; display:block
                  41. `<div #vcardLightClassName>`
                    CSS: font-size:15px; font-weight:700; color:#EAEAEA
                  42. `<div #vcardLightDesc>`
                    CSS: font-size:12px; color:rgba(234,234,234,0.75)
              43. `<div .td-result-back>`
                CSS: padding:28px 20px 24px; border-radius:16px; display:flex; flex-direction:column; overflow:hidden
                44. `<div #vcardBgShadow>`
                  CSS: position:absolute; z-index:0
                45. `<div #vcardOverlayShadow>`
                  CSS: position:absolute; z-index:1
                46. `<div .td-vcard-content>`
                  CSS: width:100%; position:relative; z-index:2
                  47. `<div .td-vcard-label>` — テキスト:「✦ SHADOW ✦」
                    CSS: font-size:10px; font-weight:300
                  48. `<div #vcardZodiacShadow>`
                    CSS: display:flex; gap:48px
                  49. `<div .td-vcard-line>`
                    CSS: width:70%; height:1px; background:linear-gradient(90deg, transparent, rgba(249,217,118,0.6), transparent); margin:10px auto 12px
                  50. `<div #vcardShadowTitle>`
                    CSS: font-size:19px; font-weight:700; color:#F9D976; margin:4px 0 10px
                  51. `<div .td-vcard-class-icon-frame>`
                    CSS: width:148px; height:148px; background:radial-gradient(circle, #0a0a14 60%, rgba(10,10,20,0.9) 75%, transparent 85%); margin:8px auto 10px; border-radius:50%; position:relative
                    52. `<img #vcardClassIconShadow>`
                      CSS: width:100px; height:100px; background:#0a0a14; border-radius:50%; position:relative; display:block
                    53. `<div #vcardShadowClassName>`
                      CSS: font-size:15px; font-weight:700; color:#EAEAEA
                    54. `<div #vcardShadowDesc>`
                      CSS: font-size:12px; color:rgba(234,234,234,0.75)
              55. `<div .td-flip-hint>` — テキスト:「tap to flip」
                CSS: font-size:10px; color:rgba(172,172,172,0.4)
            56. `<div #titleStartBtn>`
              57. `<button .gold-btn>` — テキスト:「✦ あなたの称号を受け取る」
                CSS: width:100%; font-size:15px; font-weight:700; font-family:inherit; color:#0C1D3A; background:linear-gradient(135deg, #F9D976, #F6BD60)
            58. `<div #titleNeedProfile>` — テキスト:「まず出生情報を設定してください」
            59. `<div #titleRediagnose>`
              60. `<button>` — テキスト:「再診断する（Cosmic Pro）」
          61. `<div .settings-group>`
            CSS: display:flex; flex-direction:column; gap:10px
            62. `<div .section-label>` — テキスト:「✦ Cosmic Pro」
              CSS: font-size:11px; font-weight:700; color:#F9D976
            63. `<div .pro-banner>`
              CSS: background:linear-gradient(135deg,rgba(249,217,118,0.09),rgba(249,217,118,0.04)); padding:22px; border-radius:22px; display:flex; flex-direction:column; gap:12px
              64. `<div .pro-title>` — テキスト:「Upgrade to Cosmic Pro」
                CSS: font-size:18px; font-weight:700; background:linear-gradient(135deg,#F9D976,#F6BD60)
              65. `<div .pro-sub>` — テキスト:「Aether shaders · Galaxy Archiv」
                CSS: font-size:13px; color:#ACACAC
              66. `<div>`
                67. `<span>` — テキスト:「$9.99」
                68. `<span>` — テキスト:「/month」
              69. `<button .pro-btn>` — テキスト:「Unlock Cosmic Pro ✦」
                CSS: font-size:14px; font-weight:700; font-family:inherit; color:#0C1D3A; background:linear-gradient(135deg,#F9D976,#F6BD60); padding:13px 30px
              70. `<div>` — テキスト:「$49.99/year · Cancel anytime」
          71. `<div .settings-group>`
            CSS: display:flex; flex-direction:column; gap:10px
            72. `<div .section-label>` — テキスト:「✦ Astrology」
              CSS: font-size:11px; font-weight:700; color:#F9D976
            73. `<div #houseSystemRow>`
              CSS: background:rgba(255,255,255,0.06); padding:14px 18px; border-radius:20px; display:flex
              74. `<div .settings-left>`
                CSS: display:flex; gap:12px
                75. `<div #si-house>`
                  CSS: width:36px; height:36px; font-size:17px; color:rgba(249,217,118,0.7); background:rgba(255,255,255,0.05); border-radius:10px
                76. `<div .settings-txt>` — テキスト:「House System」
                  CSS: font-size:14px
              77. `<div #houseSystemVal>` — テキスト:「Placidus ›」
                CSS: font-size:13px; color:#ACACAC
            78. `<div #houseSelectPanel>`
              79. `<div .settings-item>`
                CSS: background:rgba(255,255,255,0.06); padding:14px 18px; border-radius:20px; display:flex
                80. `<div .settings-left>`
                  CSS: display:flex; gap:12px
                  81. `<div .settings-txt>` — テキスト:「Placidus」
                    CSS: font-size:14px
                82. `<div #houseCheck_placidus>` — テキスト:「✓」
              83. `<div .settings-item>`
                CSS: background:rgba(255,255,255,0.06); padding:14px 18px; border-radius:20px; display:flex
                84. `<div .settings-left>`
                  CSS: display:flex; gap:12px
                  85. `<div .settings-txt>` — テキスト:「Whole Sign」
                    CSS: font-size:14px
                86. `<div #houseCheck_whole_sign>` — テキスト:「✓」
            87. `<div .settings-item>`
              CSS: background:rgba(255,255,255,0.06); padding:14px 18px; border-radius:20px; display:flex
              88. `<div .settings-left>`
                CSS: display:flex; gap:12px
                89. `<div #si-telescope>`
                  CSS: width:36px; height:36px; font-size:17px; color:rgba(249,217,118,0.7); background:rgba(255,255,255,0.05); border-radius:10px
                90. `<div .settings-txt>` — テキスト:「Aspect Orbs」
                  CSS: font-size:14px
              91. `<div #orbSummaryVal>` — テキスト:「All 2° ›」
                CSS: font-size:13px; color:#ACACAC
          92. `<div .settings-group>`
            CSS: display:flex; flex-direction:column; gap:10px
            93. `<div .section-label>` — テキスト:「✦ App」
              CSS: font-size:11px; font-weight:700; color:#F9D976
            94. `<div .settings-item>`
              CSS: background:rgba(255,255,255,0.06); padding:14px 18px; border-radius:20px; display:flex
              95. `<div .settings-left>`
                CSS: display:flex; gap:12px
                96. `<div #si-globe>`
                  CSS: width:36px; height:36px; font-size:17px; color:rgba(249,217,118,0.7); background:rgba(255,255,255,0.05); border-radius:10px
                97. `<div .settings-txt>` — テキスト:「Language」
                  CSS: font-size:14px
              98. `<div .settings-val>` — テキスト:「English ›」
                CSS: font-size:13px; color:#ACACAC
            99. `<div .settings-item>`
              CSS: background:rgba(255,255,255,0.06); padding:14px 18px; border-radius:20px; display:flex
              100. `<div .settings-left>`
                CSS: display:flex; gap:12px
                101. `<div #si-bell>`
                  CSS: width:36px; height:36px; font-size:17px; color:rgba(249,217,118,0.7); background:rgba(255,255,255,0.05); border-radius:10px
                102. `<div .settings-txt>` — テキスト:「Notifications」
                  CSS: font-size:14px
              103. `<div .toggle>`
                CSS: width:44px; height:26px; background:rgba(255,255,255,0.12); border-radius:13px; position:relative
                104. `<div .toggle-thumb>`
                  CSS: width:20px; height:20px; background:white; border-radius:50%; position:absolute; top:3px
            105. `<div .settings-item>`
              CSS: background:rgba(255,255,255,0.06); padding:14px 18px; border-radius:20px; display:flex
              106. `<div .settings-left>`
                CSS: display:flex; gap:12px
                107. `<div #si-doc>`
                  CSS: width:36px; height:36px; font-size:17px; color:rgba(249,217,118,0.7); background:rgba(255,255,255,0.05); border-radius:10px
                108. `<div .settings-txt>` — テキスト:「Terms & Privacy」
                  CSS: font-size:14px
              109. `<div .settings-val>` — テキスト:「›」
                CSS: font-size:13px; color:#ACACAC
          110. `<div .version-txt>` — テキスト:「Solara v1.0.0 · Made with ✦」
            CSS: font-size:11px; color:rgba(172,172,172,0.35); padding:8px 0
        111. `<div .bottom-nav>`
          CSS: height:80px; background:linear-gradient(180deg, rgba(6,10,18,0.80) 0%, rgba(4,6,14,0.95) 100%); padding:10px 4px 0; position:fixed; left:0; right:0
      112. `<div #birthOverlay>`
        CSS: background:rgba(4,8,16,0.95); position:fixed; display:none; z-index:500
        113. `<div .birth-card>`
          CSS: width:92%; max-width:420px; background:rgba(255,255,255,0.05); padding:24px 20px 32px; margin:40px auto; border-radius:24px
          114. `<div .birth-header>`
            CSS: display:flex
            115. `<div .birth-title>` — テキスト:「✦ 出生情報」
              CSS: font-size:16px; font-weight:700; color:#F9D976
            116. `<button .birth-close>` — テキスト:「✕」
              CSS: width:32px; height:32px; font-size:18px; color:#ACACAC; background:rgba(255,255,255,0.08); border-radius:50%
          117. `<div .birth-section>`
            118. `<div .birth-label>` — テキスト:「氏名」
              CSS: font-size:12px; color:#ACACAC
            119. `<input #biName>`
              CSS: width:100%; font-size:14px; font-family:inherit; color:#EAEAEA; background:rgba(255,255,255,0.06); padding:12px 14px
            120. `<div .birth-section>`
              121. `<div .birth-label>` — テキスト:「生年月日」
                CSS: font-size:12px; color:#ACACAC
              122. `<input #biBirthDate>`
                CSS: width:100%; font-size:14px; font-family:inherit; color:#EAEAEA; background:rgba(255,255,255,0.06); padding:12px 14px
              123. `<div .birth-section>`
                124. `<div .birth-label>` — テキスト:「出生時刻」
                  CSS: font-size:12px; color:#ACACAC
                125. `<input #biBirthTime>`
                  CSS: width:100%; font-size:14px; font-family:inherit; color:#EAEAEA; background:rgba(255,255,255,0.06); padding:12px 14px
                  126. `<div .time-unknown-row>`
                    CSS: display:flex; gap:8px
                    127. `<input #biTimeUnknown>`
                      CSS: width:18px; height:18px
                      128. `<label .time-unknown-label>` — テキスト:「出生時刻が分からない」
                        CSS: font-size:12px; color:#ACACAC
                    129. `<div #biNoonHint>` — テキスト:「鑑定には惑星配置とアスペクト情報を使用します。ハウス・ASC」
                      CSS: font-size:11px; color:#F9D976; background:rgba(249,217,118,0.08); padding:6px 10px; border-radius:8px; display:none
                  130. `<div .birth-section>`
                    131. `<div .birth-label>` — テキスト:「出生地」
                      CSS: font-size:12px; color:#ACACAC
                    132. `<div .map-search-row>`
                      CSS: display:flex; gap:8px
                      133. `<input #biBirthPlace>`
                        CSS: width:100%; font-size:14px; font-family:inherit; color:#EAEAEA; background:rgba(255,255,255,0.06); padding:12px 14px
                        134. `<button #biMapSearchBtn>` — テキスト:「検索」
                          CSS: font-size:13px; font-weight:600; color:#0A0A14; background:linear-gradient(135deg,#F9D976,#E8A840); padding:0 16px; border-radius:12px
                      135. `<div #biMapResult>`
                        CSS: font-size:11px; color:#6CC070; display:none
                      136. `<div #birthMap>`
                        CSS: width:100%; height:200px; border-radius:12px
                      137. `<div .map-coords>`
                        CSS: display:flex; gap:8px
                        138. `<input #biBirthLat>`
                          CSS: width:100%; font-size:14px; font-family:inherit; color:#EAEAEA; background:rgba(255,255,255,0.06); padding:12px 14px
                          139. `<input #biBirthLng>`
                            CSS: width:100%; font-size:14px; font-family:inherit; color:#EAEAEA; background:rgba(255,255,255,0.06); padding:12px 14px
                        140. `<button .birth-save-btn>` — テキスト:「保存する」
                          CSS: width:100%; font-size:15px; font-weight:700; color:#0A0A14; background:linear-gradient(135deg,#F9D976,#E8A840); padding:14px
                    141. `<div #orbOverlay>`
                      CSS: background:rgba(4,8,16,0.95); position:fixed; display:none; z-index:500
                      142. `<div .birth-card>`
                        CSS: width:92%; max-width:420px; background:rgba(255,255,255,0.05); padding:24px 20px 32px; margin:40px auto; border-radius:24px
                        143. `<div .birth-header>`
                          CSS: display:flex
                          144. `<div .birth-title>` — テキスト:「🔭 Aspect Orbs」
                            CSS: font-size:16px; font-weight:700; color:#F9D976
                          145. `<div>`
                            146. `<button>` — テキスト:「リセット」
                            147. `<button .birth-close>` — テキスト:「✕」
                              CSS: width:32px; height:32px; font-size:18px; color:#ACACAC; background:rgba(255,255,255,0.08); border-radius:50%
                        148. `<div .birth-section>`
                          149. `<div .birth-label>` — テキスト:「Major Aspects」
                            CSS: font-size:12px; color:#ACACAC
                          150. `<div #orbMajor>`
                            CSS: display:flex; flex-direction:column; gap:6px
                        151. `<div .birth-section>`
                          152. `<div .birth-label>` — テキスト:「Minor Aspects」
                            CSS: font-size:12px; color:#ACACAC
                          153. `<div #orbMinor>`
                            CSS: display:flex; flex-direction:column; gap:6px
                        154. `<div .birth-section>`
                          155. `<div .birth-label>` — テキスト:「Patterns」
                            CSS: font-size:12px; color:#ACACAC
                          156. `<div #orbPatterns>`
                            CSS: display:flex; flex-direction:column; gap:6px
                        157. `<button .birth-save-btn>` — テキスト:「保存する」
                          CSS: width:100%; font-size:15px; font-weight:700; color:#0A0A14; background:linear-gradient(135deg,#F9D976,#E8A840); padding:14px
                    158. `<div #homeOverlay>`
                      CSS: background:rgba(4,8,16,0.95); position:fixed; display:none; z-index:500
                      159. `<div .birth-card>`
                        CSS: width:92%; max-width:420px; background:rgba(255,255,255,0.05); padding:24px 20px 32px; margin:40px auto; border-radius:24px
                        160. `<div .birth-header>`
                          CSS: display:flex
                          161. `<div .birth-title>` — テキスト:「🏠 自宅（現住所）」
                            CSS: font-size:16px; font-weight:700; color:#F9D976
                          162. `<button .birth-close>` — テキスト:「✕」
                            CSS: width:32px; height:32px; font-size:18px; color:#ACACAC; background:rgba(255,255,255,0.08); border-radius:50%
                        163. `<div .birth-section>`
                          164. `<div .birth-label>` — テキスト:「住所・地名」
                            CSS: font-size:12px; color:#ACACAC
                          165. `<div .map-search-row>`
                            CSS: display:flex; gap:8px
                            166. `<input #hiHomeName>`
                              CSS: width:100%; font-size:14px; font-family:inherit; color:#EAEAEA; background:rgba(255,255,255,0.06); padding:12px 14px
                              167. `<button #hiMapSearchBtn>` — テキスト:「検索」
                                CSS: font-size:13px; font-weight:600; color:#0A0A14; background:linear-gradient(135deg,#F9D976,#E8A840); padding:0 16px; border-radius:12px
                            168. `<div #hiMapResult>`
                              CSS: font-size:11px; color:#6CC070; display:none
                            169. `<div #homeMap>`
                            170. `<div .map-coords>`
                              CSS: display:flex; gap:8px
                              171. `<input #hiHomeLat>`
                                CSS: width:100%; font-size:14px; font-family:inherit; color:#EAEAEA; background:rgba(255,255,255,0.06); padding:12px 14px
                                172. `<input #hiHomeLng>`
                                  CSS: width:100%; font-size:14px; font-family:inherit; color:#EAEAEA; background:rgba(255,255,255,0.06); padding:12px 14px
                              173. `<button .birth-save-btn>` — テキスト:「保存する」
                                CSS: width:100%; font-size:15px; font-weight:700; color:#0A0A14; background:linear-gradient(135deg,#F9D976,#E8A840); padding:14px
                          174. `<div #titleDiagOverlay>`
                            CSS: background:rgba(4,8,16,0.95); position:fixed; display:none; z-index:500; overflow:hidden
                            175. `<div #tdScreenIntro>`
                              CSS: padding:20px 20px; position:absolute; display:flex; flex-direction:column
                              176. `<div .td-intro-card>`
                                CSS: max-width:340px; background:rgba(255,255,255,0.06); padding:40px 28px; border-radius:20px
                                177. `<div>` — テキスト:「✦」
                                178. `<div>` — テキスト:「称号の儀式」
                                179. `<div>` — テキスト:「カードがあなたを映し出します。」
                                  180. `<br>` — テキスト:「28の問いに、直感で答えてください。」
                                  181. `<button .birth-save-btn>` — テキスト:「始める」
                                    CSS: width:100%; font-size:15px; font-weight:700; color:#0A0A14; background:linear-gradient(135deg,#F9D976,#E8A840); padding:14px
                                  182. `<div>` — テキスト:「あとで」
                              183. `<div #tdScreenRound>`
                                CSS: padding:20px 20px; position:absolute; display:flex; flex-direction:column
                                184. `<div .td-progress-bar>`
                                  CSS: height:3px; background:rgba(255,255,255,0.08); position:absolute; top:0; left:0; right:0
                                  185. `<div #tdProgressFill>`
                                    CSS: width:0%; height:100%; background:linear-gradient(90deg,#F9D976,#E8A840)
                                186. `<div #tdProgressText>` — テキスト:「1 / 28」
                                  CSS: font-size:14px; font-weight:600; color:rgba(249,217,118,0.8)
                                187. `<div #tdPartLabel>`
                                  CSS: font-size:11px; color:#F9D976; opacity:0.7
                                188. `<div #tdQuestion>`
                                  CSS: max-width:320px; font-size:17px; font-weight:700; color:#EAEAEA
                                189. `<div #tdQuestionEN>`
                                  CSS: max-width:320px; font-size:12px; color:rgba(172,172,172,0.5)
                                190. `<div #tdCards>`
                                  CSS: width:100%; max-width:520px; padding:0 8px; display:flex; gap:12px
                              191. `<div #tdScreenPartTrans>`
                                CSS: padding:20px 20px; position:absolute; display:flex; flex-direction:column
                                192. `<div #tdPartTransText>`
                                  CSS: font-size:22px; font-weight:700; color:#F9D976; opacity:0
                              193. `<div #tdScreenForging>`
                                CSS: padding:20px 20px; position:absolute; display:flex; flex-direction:column
                                194. `<div .td-forge-container>`
                                  CSS: position:relative
                                  195. `<div #tdForgeOrb>`
                                    CSS: width:120px; height:120px; background:radial-gradient(circle, rgba(249,217,118,0.6) 0%, rgba(249,217,118,0.1) 60%, transparent 80%); margin:0 auto 24px; border-radius:50%
                                  196. `<div .td-forge-text>` — テキスト:「Forging your title...」
                                    CSS: font-size:14px; color:#ACACAC
                                  197. `<div #tdForgeParticles>`
                                    CSS: position:absolute
                              198. `<div #tdScreenReveal>`
                                CSS: padding:20px 20px; position:absolute; display:flex; flex-direction:column
                                199. `<div .td-reveal-container>`
                                  CSS: max-width:340px
                                  200. `<div #tdRevealMain>`
                                    CSS: font-size:24px; font-weight:700; color:#F9D976; opacity:0
                                  201. `<div #tdRevealMainEN>`
                                    CSS: font-size:13px; color:rgba(249,217,118,0.5); opacity:0
                                  202. `<div .td-reveal-line>`
                                    CSS: width:0; height:1px; background:linear-gradient(90deg,transparent,#F9D976,transparent); margin:16px auto
                                  203. `<div #tdRevealClass>`
                                    CSS: font-size:20px; font-weight:700; color:#EAEAEA; opacity:0
                                  204. `<div #tdRevealLight>`
                                    CSS: font-size:13px; color:#ACACAC; opacity:0
                                  205. `<div #tdRevealShadow>`
                                    CSS: font-size:13px; color:#ACACAC; opacity:0
                                  206. `<div #tdRevealActions>`
                                    CSS: opacity:0
                                    207. `<button .birth-save-btn>` — テキスト:「これでいく」
                                      CSS: width:100%; font-size:15px; font-weight:700; color:#0A0A14; background:linear-gradient(135deg,#F9D976,#E8A840); padding:14px
                                    208. `<div #tdRetryBtn>` — テキスト:「もう一度診断する」
                                      CSS: font-size:12px; color:#ACACAC
                                    209. `<div .td-share-btn>` — テキスト:「Share Your Title ✦」
                                      CSS: font-size:13px; color:#F9D976
                              210. `<canvas #tdShareCanvas>`

**要素総数（depth≤20）**: 210個

---
## インタラクション一覧（イベントハンドラ）

1. **bgCanvas** の `resize` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

2. **window** の `resize` イベント
   > 動作メモ:（ここに日本語で何が起きるか書く）

3. **(HTML属性)** の `click` イベント → `openBirthInfo()`
   > 動作メモ:（ここに日本語で何が起きるか書く）

---
## 関数一覧（インラインJS）

1. `animBg()` — 説明:（ここに日本語で書く）
2. `makeStars()` — 説明:（ここに日本語で書く）
3. `loadProfile()` — 説明:（ここに日本語で書く）
4. `saveProfileData(p)` — 説明:（ここに日本語で書く）
5. `renderProfileDisplay()` — 説明:（ここに日本語で書く）
6. `formatDate(d)` — 説明:（ここに日本語で書く）
7. `syncHomeToStorage(key, profile)` — 説明:（ここに日本語で書く）
8. `syncHomeToVP(profile)` — 説明:（ここに日本語で書く）
9. `openBirthInfo()` — 説明:（ここに日本語で書く）
10. `closeBirthInfo()` — 説明:（ここに日本語で書く）
11. `toggleTimeUnknown()` — 説明:（ここに日本語で書く）
12. `setBirthMapLocation(lat, lng, doReverse)` — 説明:（ここに日本語で書く）
13. `searchBirthPlace()` — 説明:（ここに日本語で書く）
14. `saveBirthInfo()` — 説明:（ここに日本語で書く）
15. `openHomeInfo()` — 説明:（ここに日本語で書く）
16. `closeHomeInfo()` — 説明:（ここに日本語で書く）
17. `setHomeMapLocation(lat, lng, doReverse)` — 説明:（ここに日本語で書く）
18. `searchHomePlace()` — 説明:（ここに日本語で書く）
19. `saveHomeInfo()` — 説明:（ここに日本語で書く）
20. `initHouseUI()` — 説明:（ここに日本語で書く）
21. `toggleHouseSelect()` — 説明:（ここに日本語で書く）
22. `setHouseSystem(val)` — 説明:（ここに日本語で書く）
23. `buildOrbRows(container, items, store, storeKey)` — 説明:（ここに日本語で書く）
24. `formatOrbVal(v)` — 説明:（ここに日本語で書く）
25. `resetOrbs()` — 説明:（ここに日本語で書く）
26. `stepOrb(storeKey, key, delta)` — 説明:（ここに日本語で書く）
27. `openOrbOverlay()` — 説明:（ここに日本語で書く）
28. `positionDefaultMarks()` — 説明:（ここに日本語で書く）
29. `closeOrbOverlay()` — 説明:（ここに日本語で書く）
30. `updateOrbVal(storeKey, key, val)` — 説明:（ここに日本語で書く）
31. `saveOrbOverlay()` — 説明:（ここに日本語で書く）
32. `updateOrbSummary()` — 説明:（ここに日本語で書く）
33. `getSunSign(dateStr)` — 説明:（ここに日本語で書く）
34. `getMoonSign(dateStr, timeStr)` — 説明:（ここに日本語で書く）
35. `resetTD()` — 説明:（ここに日本語で書く）
36. `showTDScreen(id)` — 説明:（ここに日本語で書く）
37. `startDiagnosis()` — 説明:（ここに日本語で書く）
38. `closeDiagnosis()` — 説明:（ここに日本語で書く）
39. `beginRounds()` — 説明:（ここに日本語で書く）
40. `showRound(idx)` — 説明:（ここに日本語で書く）
41. `renderRound(idx, r, displayNum)` — 説明:（ここに日本語で書く）
42. `animateCardsIn()` — 説明:（ここに日本語で書く）
43. `selectCard(roundIdx, cardIdx)` — 説明:（ここに日本語で書く）
44. `getLeadingAxis()` — 説明:（ここに日本語で書く）
45. `applyWildcard()` — 説明:（ここに日本語で書く）
46. `determineFinalAxis()` — 説明:（ここに日本語で書く）
47. `determineCourt()` — 説明:（ここに日本語で書く）
48. `computeResults()` — 説明:（ここに日本語で書く）
49. `saveTitleData()` — 説明:（ここに日本語で書く）
50. `loadTitleData()` — 説明:（ここに日本語で書く）
51. `startForging()` — 説明:（ここに日本語で書く）
52. `startReveal()` — 説明:（ここに日本語で書く）
53. `acceptTitle()` — 説明:（ここに日本語で書く）
54. `retryDiagnosis()` — 説明:（ここに日本語で書く）
55. `loadShareImage(src)` — 説明:（ここに日本語で書く）
56. `shareTitle()` — 説明:（ここに日本語で書く）
57. `renderShareCard(bgImg, classImg, sunImg, moonImg, info)` — 説明:（ここに日本語で書く）
58. `renderShareCardFallback(data, cls, txt, axis, sunSign, moonSign, axisStyle)` — 説明:（ここに日本語で書く）
59. `drawCover(ctx, img, w, h)` — 説明:（ここに日本語で書く）
60. `downloadCanvas(canvas)` — 説明:（ここに日本語で書く）
61. `determineFinalAxisFromScores(scores)` — 説明:（ここに日本語で書く）
62. `renderTitleDisplay()` — 説明:（ここに日本語で書く）

---
## API呼び出し

1. `https://nominatim.openstreetmap.org/reverse?format=json&lat=`
   > 用途:（ここに日本語で書く）

2. `https://nominatim.openstreetmap.org/search?format=json&q=`
   > 用途:（ここに日本語で書く）

3. `https://nominatim.openstreetmap.org/reverse?format=json&lat=`
   > 用途:（ここに日本語で書く）

4. `https://nominatim.openstreetmap.org/search?format=json&q=`
   > 用途:（ここに日本語で書く）

---
## 使用CSS変数

| 変数名 | 値 |
|--------|-----|
| `--font-body` | `'DM Sans', 'Segoe UI', sans-serif` |
