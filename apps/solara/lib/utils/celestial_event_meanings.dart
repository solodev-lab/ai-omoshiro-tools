/// 天体イベントの占星術的意味辞書
/// key: "${type}_${planet}" or "${type}_${planet}_${sign}"
/// 惑星×タイプで汎用解説。星座固有の意味が必要な場合は planet_sign キーで上書き。
library;

import 'solara_i18n.dart';

const Map<String, String> eventMeaningsJP = {
  // ── Ingress (惑星移行) ──
  'ingress_mercury': '水星がサインを移ると、思考やコミュニケーションのスタイルが変化します。新しい視点で物事を捉え、情報の受け取り方が切り替わるタイミングです。',
  'ingress_venus': '金星のサイン移動は、愛情表現や美意識、価値観のシフトを示します。人間関係や創造性に新しい風が吹き込む時期です。',
  'ingress_mars': '火星がサインを移ると、行動力やエネルギーの向かう先が変わります。モチベーションの源泉が切り替わり、新たな挑戦への意欲が湧くタイミングです。',
  'ingress_jupiter': '木星のサイン移動は約1年に一度の大きな転機。拡大と成長のテーマが切り替わり、新しい領域にエネルギーが注がれます。',
  'ingress_saturn': '土星のサイン移動は約2.5年に一度。責任と試練のテーマが変わり、社会全体の構造が再編される長期的な転換点です。',
  'ingress_uranus': '天王星のサイン移動は約7年に一度の時代的な変革。常識が覆され、テクノロジーや社会の在り方が根本から変わり始めます。',
  'ingress_neptune': '海王星のサイン移動は約14年に一度。集合的な夢や理想、スピリチュアリティのテーマが世代レベルで変化する大きな潮流の転換です。',
  'ingress_chiron': 'キロンのサイン移動は、集合的な癒しのテーマが変わることを意味します。社会全体が向き合うべき傷と、その克服の方向性が示されます。',

  // ── Retrograde (逆行) ──
  'retrograde_mercury': '水星逆行は通信・交通・契約の見直し期間。過去の未完了事項を整理する好機ですが、新しい契約や大きな購入は慎重に。誤解が生じやすいので、丁寧な確認を心がけましょう。',
  'retrograde_venus': '金星逆行は人間関係と価値観の振り返り期間。過去の恋愛や友情を見つめ直し、本当に大切なものを再確認する時期です。衝動的な買い物や美容の大きな変更も、立ち止まって見つめ直しやすいエネルギーです。',
  'retrograde_mars': '火星逆行は行動力とエネルギーの内省期間。外に向かう衝動が弱まり、内面的な強さを培う時期です。怒りのコントロールが課題になることも。',
  'retrograde_jupiter': '木星逆行は成長と信念の見直し期間。外的な拡大より内的な成長に焦点が移ります。過去の決断を振り返り、本当に信じるものを再確認するタイミングです。',
  'retrograde_saturn': '土星逆行は責任と制限の再評価期間。自分に課してきたルールや義務が本当に必要か問い直す時期。古い構造を手放し、より本質的な規律を見つけるチャンスです。',
  'retrograde_uranus': '天王星逆行は変革エネルギーが内向する期間。外的な反抗より、内面的な自由を追求する時期です。過去に起こした変化の意味を深く理解できるタイミングです。',
  'retrograde_neptune': '海王星逆行は幻想と現実の境界が明確になる期間。曖昧にしてきた事柄の真実が見えやすくなります。スピリチュアルな気づきが深まる一方、夢見がちな計画の現実性を検証する時です。',
  'retrograde_pluto': '冥王星逆行は深層の変容が内面で進む期間。表面的には穏やかでも、無意識レベルで大きな変化が準備されています。手放すべきものと真に求めるものの区別がつきやすくなります。',

  // ── Retrograde End (順行) ──
  'retrograde_end_mercury': '水星が順行に戻ります。滞っていた通信やプロジェクトが動き出し、誤解が解消されやすくなります。逆行中に見直したことを実行に移す好機です。',
  'retrograde_end_venus': '金星が順行に戻ります。人間関係の停滞が解消され、愛情や創造性が再び外に向かって流れ始めます。逆行中に再確認した価値観を基に、新たな一歩を踏み出せます。',
  'retrograde_end_saturn': '土星が順行に戻ります。再評価してきた責任や構造に対する新たな理解を持って、具体的な行動に移せるタイミングです。',
  'retrograde_end_neptune': '海王星が順行に戻ります。逆行中に得た現実的な視点を保ちつつ、再び理想や直感に従って前進できる時期が始まります。',
  'retrograde_end_pluto': '冥王星が順行に戻ります。内面で準備されてきた深い変容が、外的な現実として現れ始めるタイミングです。',

  // ── Eclipse (食) ──
  'eclipse_sun': '日食は強力な新月。通常の新月の数倍のエネルギーで新しいサイクルが始まります。運命的な出来事や重要な転機が起こりやすく、その影響は半年以上続くことも。',
  'eclipse_moon': '月食は強力な満月。隠されていた真実が明るみに出たり、感情的な解放が起こりやすい時期です。終わりと完成のエネルギーが増幅されます。',

  // ── Conjunction (合) ──
  'conjunction_saturn': '土星と海王星の合は約36年に一度の稀有な配置。現実（土星）と理想（海王星）が融合し、夢を具体的な形にする大きな社会的転換点です。新しい時代の構造が生まれます。',

  // ── Node Shift ──
  'node_shift_moon': 'ノースノードの移動は、集合的な運命の方向転換を示します。社会全体が目指すべきテーマが切り替わり、個人の成長の方向性にも影響を与えます。約18ヶ月ごとの大きな転換です。',
};

/// 英語版 (英語化Phase 2)。eventMeaningsJP を正典に、STYLE_VOICE_EN で書き起こし。
/// 吉凶/予測語は使わず、叙述(plain)＋寄り添い(gentle)・中立で再表現。
const Map<String, String> eventMeaningsEN = {
  // ── Ingress (惑星移行) ──
  'ingress_mercury':
      'When Mercury changes signs, the style of thought and communication shifts. It is a moment to see things from a fresh angle, and the way information reaches you changes.',
  'ingress_venus':
      'Venus changing signs marks a shift in how affection is expressed, in your sense of beauty, and in what you value. A fresh wind moves through relationships and creativity.',
  'ingress_mars':
      'When Mars changes signs, the direction your drive and energy reach for turns. The source of your motivation shifts, and an appetite for new challenges begins to stir.',
  'ingress_jupiter':
      'Jupiter changing signs is a major turning point that comes roughly once a year. The themes of expansion and growth change over, and energy pours into a new area of life.',
  'ingress_saturn':
      'Saturn changes signs about once every two and a half years. The themes of responsibility and testing shift, and the structures of society are reshaped — a long-term turning point.',
  'ingress_uranus':
      'Uranus changing signs is an era-defining shift that comes about once every seven years. Familiar assumptions are overturned, and the shape of technology and society begins to change at its roots.',
  'ingress_neptune':
      'Neptune changes signs about once every fourteen years. The collective dreams, ideals, and spirituality of an age shift at a generational level — a turning of the larger tide.',
  'ingress_chiron':
      'Chiron changing signs means the collective theme of healing is changing. It points to the wound a society is invited to face, and the direction in which it may move through it.',

  // ── Retrograde (逆行) ──
  'retrograde_mercury':
      'Mercury retrograde is a season for reviewing communication, travel, and agreements. A good time to tie up unfinished threads from the past, while new contracts and large purchases ask for a little more care. Misunderstandings come easily here, so gentle, thorough confirmation helps.',
  'retrograde_venus':
      'Venus retrograde is a season for looking back over relationships and values. Past loves and friendships come up for another look, and you reconfirm what truly matters to you. It is also an energy that makes it natural to pause before impulsive spending or big changes to your appearance.',
  'retrograde_mars':
      'Mars retrograde turns drive and energy inward. The impulse to push outward softens, and it becomes a time to cultivate inner strength. Working with anger can become one of its themes.',
  'retrograde_jupiter':
      'Jupiter retrograde is a season for re-examining growth and belief. Focus moves from outward expansion to inner growth. You look back over past decisions and reconfirm what you genuinely believe in.',
  'retrograde_saturn':
      'Saturn retrograde is a season for reappraising responsibility and limits. You question whether the rules and duties you have placed on yourself are truly needed — an opening to let go of old structures and find a more essential kind of discipline.',
  'retrograde_uranus':
      'Uranus retrograde draws the energy of change inward. Rather than outward rebellion, it is a time to seek inner freedom. The meaning of the changes you once set in motion can be understood more deeply now.',
  'retrograde_neptune':
      'Neptune retrograde is a season when the line between illusion and reality grows clearer. The truth of things you have kept vague becomes easier to see. Spiritual insight can deepen, and it is also a time to test how grounded your dreamier plans really are.',
  'retrograde_pluto':
      'Pluto retrograde is a season when deep transformation moves quietly within. On the surface things may feel calm, yet at an unconscious level a large change is being prepared. It becomes easier to tell apart what is yours to release and what you truly seek.',

  // ── Retrograde End (順行) ──
  'retrograde_end_mercury':
      'Mercury returns to direct motion. Communication and projects that had stalled begin to move again, and misunderstandings clear more easily. A natural moment to put into action what you reviewed during the retrograde.',
  'retrograde_end_venus':
      'Venus returns to direct motion. Stalls in relationships ease, and affection and creativity flow outward again. Standing on the values you reconfirmed during the retrograde, you can take a new step.',
  'retrograde_end_saturn':
      'Saturn returns to direct motion. Carrying a new understanding of the responsibilities and structures you have reappraised, you can move into concrete action.',
  'retrograde_end_neptune':
      'Neptune returns to direct motion. Holding the grounded perspective you gained during the retrograde, you enter a time to move forward again by your ideals and intuition.',
  'retrograde_end_pluto':
      'Pluto returns to direct motion. The deep transformation that has been preparing within begins to show itself in outer reality.',

  // ── Eclipse (食) ──
  'eclipse_sun':
      'A solar eclipse is a powerful new moon. A new cycle begins with several times the energy of an ordinary new moon. Significant, life-shaping turning points tend to gather around it, and its influence can carry on for half a year or more.',
  'eclipse_moon':
      'A lunar eclipse is a powerful full moon. Hidden truths tend to come to light, and emotional release comes more easily. The energy of endings and completion is amplified.',

  // ── Conjunction (合) ──
  'conjunction_saturn':
      'The conjunction of Saturn and Neptune is a rare alignment that comes roughly once every thirty-six years. Reality (Saturn) and the ideal (Neptune) merge — a major social turning point for giving dreams a concrete form. The structures of a new era are born.',

  // ── Node Shift ──
  'node_shift_moon':
      'A shift of the North Node points to a change in collective direction. The theme a whole society moves toward changes over, and it touches the direction of personal growth as well. A major turn that comes roughly every eighteen months.',
};

/// CelestialEvent から意味を取得するヘルパー (ロケール連動)。
/// en ロケールでは eventMeaningsEN、それ以外は eventMeaningsJP を引く。
String getEventMeaning(String type, String planet) {
  final map = isEnLocale() ? eventMeaningsEN : eventMeaningsJP;
  return map['${type}_$planet'] ?? map[type] ?? '';
}

