// ============================================================
// Daily Transit 画面用 データ定義 — 英語版 (その1)
// daily_transit_data.dart から分離 (英語化 Phase 2・HARD7 維持のため)。
// 同一キー・STYLE_VOICE_EN。daily_transit_data.dart の *For アクセサが
// en ロケールで選択する (isEnLocale)。
//
// 含むもの (短〜中):
//   - angleFilterLabelsEN
//   - angleFilterShortMeaningEN
//   - angleIndividualSubLabelsEN
//   - categoryFilterTipsEN
//   - planetAngleBaseTextEN
//   - categoryAppendixEN
//   - categoryAngleAppendixEN
// 大物 (categoryTipsIntentEN / angleDetailContentEN) は _en2.dart。
//
// Solara 設計思想: 両面思想・吉凶判定なし・ユーザーが読み取って判断。
// ============================================================

import 'daily_transit_data.dart';

/// アングルフィルタのラベル (en)。ASC/MC 等のコードは共通、all のみ英語化。
const angleFilterLabelsEN = <AngleFilter, String>{
  AngleFilter.asc: 'ASC',
  AngleFilter.mc: 'MC',
  AngleFilter.dsc: 'DSC',
  AngleFilter.ic: 'IC',
  AngleFilter.ascMc: 'ASC+MC',
  AngleFilter.dscIc: 'DSC+IC',
  AngleFilter.all: 'All angles',
};

/// アングルフィルタの「意味」1行テキスト (en)。
const angleFilterShortMeaningEN = <AngleFilter, String>{
  AngleFilter.asc:
      'ASC: the moment a planet rises on the eastern horizon — the phase of beginnings, where a theme rises into the open.',
  AngleFilter.mc:
      'MC: the moment a planet reaches the zenith — the peak phase, where a theme comes into the open in the world.',
  AngleFilter.dsc:
      'DSC: the moment a planet sets on the western horizon — the turning phase, where a theme descends into relationship.',
  AngleFilter.ic:
      'IC: the moment a planet passes directly below — the deepest phase, where a theme settles into your inner ground and the unconscious.',
  AngleFilter.ascMc:
      'Outward phase: the energy of beginnings, surfacing, and showing up in the world.',
  AngleFilter.dscIc:
      'Inward phase: the energy of dialogue, relationship, reflection, and settling into the unconscious.',
  AngleFilter.all:
      'Every event across 24 hours. Each angle carries a different nature.',
};

/// 個別アングル別の表示用サブラベル (en)。
const angleIndividualSubLabelsEN = <AngleFilter, String>{
  AngleFilter.asc: 'ASC: the moment of beginnings',
  AngleFilter.mc: 'MC: the peak of coming into the open',
  AngleFilter.dsc: 'DSC: the turn toward facing',
  AngleFilter.ic: 'IC: the deepest point of settling inward',
};

/// カテゴリ × アングル別の「行動の参考になる事柄」(en)。中立表現。
const categoryFilterTipsEN = <String, CategoryTips>{
  'love': (
    headline: 'A window when the energy of connection is in motion.',
    tipsAsc: [
      'Stay open to new places to meet and openings for conversation.',
      'Take the first move to begin a new connection.',
      'Reach out with a word to someone you have had in mind.',
    ],
    tipsMc: [
      'Express clearly to the other person where you stand in the relationship.',
      'Engage actively at public gatherings.',
      'Let your appeal show in social settings.',
    ],
    tipsDsc: [
      'Deepen quiet dialogue with someone who matters.',
      'Make time to attend to the other person\'s feelings and inner world.',
      'Tend carefully to adjusting and aligning the relationship.',
    ],
    tipsIc: [
      'Look back on past relationships and sort through gratitude and forgiveness.',
      'Warm the bonds that serve as home and an anchor for the heart.',
      'Spend time with the other person in a quiet space.',
    ],
    tipsAscMc: [
      'Stay open to new places to meet and openings for conversation.',
      'Set up moments to express your appeal and your feelings.',
      'Express clearly to the other person where you stand in the relationship.',
      'Engage actively at public gatherings.',
    ],
    tipsDscIc: [
      'Deepen quiet dialogue with someone who matters.',
      'Make time to attend to the other person\'s feelings and inner world.',
      'Look back on past relationships and sort through gratitude and forgiveness.',
      'Warm the bonds that serve as home and an anchor for the heart.',
    ],
  ),
  'money': (
    headline: 'A window when the energy of material abundance is flowing.',
    tipsAsc: [
      'Set a new income stream or side venture in motion.',
      'Set up a place to share the value you offer.',
      'Take the first step on a money decision you want to move today.',
    ],
    tipsMc: [
      'Act on a decision about a contract, investment, or major purchase.',
      'Present your skills and track record to the wider world.',
      'Bring a major career decision into the open.',
    ],
    tipsDsc: [
      'Work out money matters with a partner or co-venturer.',
      'Talk through arrangements for shared assets.',
      'Face the other party in a deal or contract with care.',
    ],
    tipsIc: [
      'Reflectively put your household finances and existing assets in order.',
      'Reaffirm what you truly value.',
      'Tend the inner ground of "abundance" with a long view.',
    ],
    tipsAscMc: [
      'Put an important money decision into action.',
      'Present your value and skills to the wider world.',
      'Get ready on a decision about a contract, investment, or major purchase.',
      'Reach actively toward more income and new opportunities.',
    ],
    tipsDscIc: [
      'Revisit your values and reappraise what truly matters.',
      'Reflectively put your existing assets and household finances in order.',
      'Deepen the money matters worked out with a partner or family.',
      'Tend the inner ground of "abundance."',
    ],
  ),
  'work': (
    headline: 'A window when the energy of your social role is in motion.',
    tipsAsc: [
      'Set a new project in motion.',
      'Get a new task or role off the ground.',
      'Take the first step on today\'s work.',
    ],
    tipsMc: [
      'Speak up in an important presentation or meeting.',
      'Show your results and direction to the wider world.',
      'Step into a moment that calls for leadership.',
    ],
    tipsDsc: [
      'Deepen the working-out with colleagues and clients.',
      'Move along talks about collaboration and dividing the work.',
      'Revisit trust and adjust agreements.',
    ],
    tipsIc: [
      'Reflectively review how you work and the footing beneath it.',
      'Sort through past wins and missteps.',
      'Warm your career with a long view.',
    ],
    tipsAscMc: [
      'Carry out an important presentation, meeting, or first move.',
      'Plan a public announcement or release of results.',
      'Take the lead on a new project.',
      'Show the direction of your career to the wider world.',
    ],
    tipsDscIc: [
      'Deepen dialogue with teammates and colleagues.',
      'Reflectively review how you work and its foundation.',
      'Look back and sort through past wins and missteps.',
      'Move along a review of trust and agreements.',
    ],
  ),
  'healing': (
    headline: 'A window when the energy of reflection and integration is flowing.',
    tipsAsc: [
      'Begin a new practice for health or well-being.',
      'Take in fresh air and move your body lightly.',
      'Visit a restful place you have had in mind (yoga, hot springs, and the like).',
    ],
    tipsMc: [
      'Talk to someone about caring for your own heart.',
      'State your intention toward health openly.',
      'Stand before others and share around a theme of healing.',
    ],
    tipsDsc: [
      'Let someone you trust gently hear what is on your heart.',
      'Make time to share feelings one to one.',
      'Deepen dialogue that attends to the other person\'s heart.',
    ],
    tipsIc: [
      'Breathe deeply and meditate in a quiet place.',
      'Sort through your feelings by journaling or writing.',
      'Be gentle with your body and lean into rest.',
    ],
    tipsAscMc: [
      'Express and share your feelings in an affirming way.',
      'Visit a restful place (yoga, a meditation class, and the like).',
      'Bring into the open your wish to ask someone for support.',
      'Take active steps for your health and well-being.',
    ],
    tipsDscIc: [
      'Breathe deeply, meditate, and reflect in a quiet place.',
      'Deepen the sorting of feelings through journaling or writing.',
      'Let someone you trust gently hear what is on your heart.',
      'Be gentle with your body and lean into rest.',
    ],
  ),
  'communication': (
    headline: 'A window when the energy of dialogue and the mind is in motion.',
    tipsAsc: [
      'Begin reaching out with a word to someone new.',
      'Start posting something new on social media or a blog.',
      'Take up a topic that has been on your mind.',
    ],
    tipsMc: [
      'Present what you know in a talk or on a big stage.',
      'Put your message to the world out at full reach.',
      'Share what you have learned publicly.',
    ],
    tipsDsc: [
      'Set up a deep one-to-one talk or consultation.',
      'Receive what the other person says with care.',
      'Move along a meeting or discussion.',
    ],
    tipsIc: [
      'Reflectively order your thoughts through reading and writing.',
      'Receive the messages from your heart and the unconscious.',
      'Look back and sort through past conversations.',
    ],
    tipsAscMc: [
      'Actively open a dialogue with someone close or a client.',
      'Share through writing, social media, a blog, and the like.',
      'Present what you know in a talk or meeting.',
      'Share what you have learned or found with the wider world.',
    ],
    tipsDscIc: [
      'Set up a deep one-to-one talk or consultation.',
      'Reflectively order your thoughts through reading and writing.',
      'Look back and sort through past misunderstandings and conversations.',
      'Receive the messages from your heart and the unconscious.',
    ],
  ),
};

/// 惑星 × アングル の基本意味 (en・40 パターン)。
const planetAngleBaseTextEN = <String, Map<String, String>>{
  'sun': {
    'ASC': 'The Sun\'s passage over the ASC is the moment the theme of self and will "rises into the open" — a time of beginnings, presenting a new you to those around you.',
    'MC': 'The Sun\'s passage over the MC is the peak where the theme of self and will "comes into the open in the world" — when leadership and a public role shine most.',
    'DSC': 'The Sun\'s passage over the DSC is the turn where the theme of self and will "descends into others and relationship" — coming to know yourself through facing another one to one.',
    'IC': 'The Sun\'s passage over the IC is the deepest point where the theme of self and will "settles into your inner ground" — looking at yourself anew within home and roots.',
  },
  'moon': {
    'ASC': 'The Moon\'s passage over the ASC is the moment the theme of feeling and the unconscious "rises into the open" — when sensitivity newly buds and comes more easily to the surface.',
    'MC': 'The Moon\'s passage over the MC is the peak where the theme of feeling and the unconscious "comes into the open in the world" — when the voice of the heart resounds in public settings.',
    'DSC': 'The Moon\'s passage over the DSC is the turn where the theme of feeling and the unconscious "descends into others and relationship" — when empathy and closeness flow into your dealings with others.',
    'IC': 'The Moon\'s passage over the IC is the deepest point where the theme of feeling and the unconscious "settles into your inner ground" — a time of deep dialogue with comfort and roots.',
  },
  'mercury': {
    'ASC': 'Mercury\'s passage over the ASC is the moment the theme of thought and words "rises into the open" — when new ideas and words begin to bud.',
    'MC': 'Mercury\'s passage over the MC is the peak where the theme of thought and words "comes into the open in the world" — when presenting, negotiating, and sharing ideas land most.',
    'DSC': 'Mercury\'s passage over the DSC is the turn where the theme of thought and words "descends into others and relationship" — when dialogue, agreements, and sorting through the points with another get moving.',
    'IC': 'Mercury\'s passage over the IC is the deepest point where the theme of thought and words "settles into your inner ground" — when reflective writing and the ordering of memory deepen.',
  },
  'venus': {
    'ASC': 'Venus\'s passage over the ASC is the moment the theme of love and harmony "rises into the open" — when charm and a sense of beauty newly come through.',
    'MC': 'Venus\'s passage over the MC is the peak where the theme of love and harmony "comes into the open in the world" — when art, sociability, and public grace shine.',
    'DSC': 'Venus\'s passage over the DSC is the turn where the theme of love and harmony "descends into others and relationship" — when accord and harmony with a partner get moving.',
    'IC': 'Venus\'s passage over the IC is the deepest point where the theme of love and harmony "settles into your inner ground" — when home, self-acceptance, and beautiful rest deepen.',
  },
  'mars': {
    'ASC': 'Mars\'s passage over the ASC is the moment the theme of action and passion "rises into the open" — when drive and the will to break through newly start moving.',
    'MC': 'Mars\'s passage over the MC is the peak where the theme of action and passion "comes into the open in the world" — when decisions, momentum, and public contests get moving.',
    'DSC': 'Mars\'s passage over the DSC is the turn where the theme of action and passion "descends into others and relationship" — when conflict, competition, and balancing strength with others get moving.',
    'IC': 'Mars\'s passage over the IC is the deepest point where the theme of action and passion "settles into your inner ground" — when the struggles within home, roots, and the unconscious get moving.',
  },
  'jupiter': {
    'ASC': 'Jupiter\'s passage over the ASC is the moment the theme of expansion and generosity "rises into the open" — when your view widens and new opportunities begin to bud.',
    'MC': 'Jupiter\'s passage over the MC is the peak where the theme of expansion and generosity "comes into the open in the world" — when worldly success and philosophical growth get moving.',
    'DSC': 'Jupiter\'s passage over the DSC is the turn where the theme of expansion and generosity "descends into others and relationship" — when growth arrives by way of partners and agreements.',
    'IC': 'Jupiter\'s passage over the IC is the deepest point where the theme of expansion and generosity "settles into your inner ground" — when home, roots, and inner abundance deepen.',
  },
  'saturn': {
    'ASC': 'Saturn\'s passage over the ASC is the moment the theme of responsibility and structure "rises into the open" — a time of beginnings, facing a new role or duty.',
    'MC': 'Saturn\'s passage over the MC is the peak where the theme of responsibility and structure "comes into the open in the world" — when career responsibility and a public track record are tested.',
    'DSC': 'Saturn\'s passage over the DSC is the turn where the theme of responsibility and structure "descends into others and relationship" — when responsibility for long-term agreements and bonds comes into question.',
    'IC': 'Saturn\'s passage over the IC is the deepest point where the theme of responsibility and structure "settles into your inner ground" — when giving structure to home, roots, and your foundations deepens.',
  },
  'uranus': {
    'ASC': 'Uranus\'s passage over the ASC is the moment the theme of change and independence "rises into the open" — when sudden insight and an impulse toward freedom begin to bud.',
    'MC': 'Uranus\'s passage over the MC is the peak where the theme of change and independence "comes into the open in the world" — when innovative expression and a public shedding of the old get moving.',
    'DSC': 'Uranus\'s passage over the DSC is the turn where the theme of change and independence "descends into others and relationship" — when renewing a bond and freeing it up with a partner get moving.',
    'IC': 'Uranus\'s passage over the IC is the deepest point where the theme of change and independence "settles into your inner ground" — when an awakening from home and the unconscious deepens.',
  },
  'neptune': {
    'ASC': 'Neptune\'s passage over the ASC is the moment the theme of ideals and the spiritual "rises into the open" — when intuition, dreams, and spirit newly stir.',
    'MC': 'Neptune\'s passage over the MC is the peak where the theme of ideals and the spiritual "comes into the open in the world" — when creative work and a spiritual calling shine publicly.',
    'DSC': 'Neptune\'s passage over the DSC is the turn where the theme of ideals and the spiritual "descends into others and relationship" — when the boundaries between you and another begin to melt together.',
    'IC': 'Neptune\'s passage over the IC is the deepest point where the theme of ideals and the spiritual "settles into your inner ground" — when deep reflection and hints from dreams arrive.',
  },
  'pluto': {
    'ASC': 'Pluto\'s passage over the ASC is the moment the theme of transformation and the depths "rises into the open" — when the energy of fundamental renewal starts to move.',
    'MC': 'Pluto\'s passage over the MC is the peak where the theme of transformation and the depths "comes into the open in the world" — when large-scale change and a remaking of power structures get moving.',
    'DSC': 'Pluto\'s passage over the DSC is the turn where the theme of transformation and the depths "descends into others and relationship" — when deep bonds and a transforming encounter with another get moving.',
    'IC': 'Pluto\'s passage over the IC is the deepest point where the theme of transformation and the depths "settles into your inner ground" — when a fundamental renewal of home, roots, and the unconscious deepens.',
  },
};

/// カテゴリ別の補足文 (en・legacy・カテゴリ単体)。
const categoryAppendixEN = <String, String>{
  'love':
      '[In the context of love] A window when meeting, dialogue, and self-expression land more easily. '
      'Notice how the energy of connection moves, and let it guide your actions.',
  'money':
      '[In the context of abundance] A window when creating value, receiving it, and money decisions come into alignment. '
      'A moment to be mindful of presenting your value to the world, and of contracts and decisions.',
  'work':
      '[In the context of work] A window when decisions, sharing, and practical responsibilities are in motion. '
      'A timing for presentations, first moves, and carrying out a public role.',
  'healing':
      '[In the context of healing] A window when reflection and integration deepen. '
      'A moment to bring in the sorting of feelings, rest, and care for the heart.',
  'communication':
      '[In the context of talk] A window when words and the mind are in motion. '
      'A timing to move dialogue, sharing, learning, and working things out.',
};

/// カテゴリ × アングル の組み合わせ補足文 (en・5 × 4 = 20 パターン)。
const categoryAngleAppendixEN = <String, Map<String, String>>{
  'love': {
    'ASC':
        '[Love × Self (ASC)] The move to begin a relationship from your side grows active. '
        'A time when self-expression, first impressions, and new points of contact come more readily.',
    'MC':
        '[Love × Society (MC)] Meeting in public and social connections get moving. '
        'Turn your attention to ties through work and community.',
    'IC':
        '[Love × Home (IC)] Feelings stir within family and your inner circle. '
        'A moment when roots and childhood emotional patterns echo into love as well.',
    'DSC':
        '[Love × Others (DSC)] Deepening with a partner and existing bonds. '
        'One-to-one dialogue, and the relationship as a mirror reflecting you, grow active.',
  },
  'money': {
    'ASC':
        '[Abundance × Self (ASC)] Investing in yourself, and your value showing through in how you carry yourself. '
        'A timing for personal brand, what you wear, and developing your abilities.',
    'MC':
        '[Abundance × Society (MC)] A season of social results and career harvest. '
        'A moment when contracts, decisions, and public recognition tie directly to material abundance.',
    'IC':
        '[Abundance × Home (IC)] Tending household finances and putting assets in order. '
        'A time for building a base of security, inheritance, and investing in your home.',
    'DSC':
        '[Abundance × Others (DSC)] Sharing within partnership and a team. '
        'Joint ventures, contracts, and value circulating through others get moving.',
  },
  'work': {
    'ASC':
        '[Work × Self (ASC)] Starting out, new projects, and moves you lead yourself. '
        'Leadership and decisions you make on your own initiative come alive.',
    'MC':
        '[Work × Society (MC)] A public role, announcements, and being assessed. '
        'A moment when career progress, releasing your work, and social responsibility come into the open.',
    'IC':
        '[Work × Home (IC)] Building inner foundations and firming up your footing. '
        'A time for behind-the-scenes ordering, working from home, and tending the team\'s base.',
    'DSC':
        '[Work × Others (DSC)] Work through collaboration and dialogue. '
        'Negotiation, partnerships, and joining forces with others bear results.',
  },
  'healing': {
    'ASC':
        '[Healing × Self (ASC)] Noticing your body, and recovering from outward activity. '
        'Movement, fresh air, and resetting your own rhythm.',
    'MC':
        '[Healing × Society (MC)] Release from public burdens and a review of your roles. '
        'A time to ease the social roles you have been straining under.',
    'IC':
        '[Healing × Home (IC)] Reflection, rest, and ease at home. '
        'Time alone, recovery in familiar places, and care for the heart.',
    'DSC':
        '[Healing × Others (DSC)] Heartfelt exchange within your inner circle, and healing within connection. '
        'Deep dialogue, empathy, and mutual support do the restoring.',
  },
  'communication': {
    'ASC':
        '[Talk × Self (ASC)] Sharing from yourself and connecting with new people. '
        'Social media, introductions, and the impression you make on first meeting come alive.',
    'MC':
        '[Talk × Society (MC)] Public messages and speaking out. '
        'A time when presentations, articles, and sharing in public reach more easily.',
    'IC':
        '[Talk × Home (IC)] Putting your inner world into words, and deep conversation with family. '
        'Journaling, keeping records, and talking things over within close bonds.',
    'DSC':
        '[Talk × Others (DSC)] One-to-one dialogue and the back-and-forth of words with a partner. '
        'A time for deep discussion, contract negotiation, and listening to what the other says.',
  },
};
