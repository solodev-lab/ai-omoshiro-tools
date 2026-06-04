// ============================================================
// Daily Transit 画面用 データ定義 — 英語版 (その2・大物)
// daily_transit_data.dart から分離 (英語化 Phase 2・HARD7 維持のため)。
// 同一キー・STYLE_VOICE_EN。daily_transit_data.dart の *For アクセサが
// en ロケールで選択する (isEnLocale)。
//
// 含むもの (大物):
//   - categoryTipsIntentEN (5 カテゴリ × 7 アングル = 35 ガイド)
//   - angleDetailContentEN (7 アングル詳細)
//
// 末尾の中立フッター ("This isn't a verdict of good or bad…") は
// 設計思想 (吉凶判定なし・ユーザーが読み取って判断) の定型文。
// ============================================================

import 'daily_transit_data.dart';

/// 「おすすめ行動の例」i ボタン: カテゴリ × アングル別ガイド文 (en)。
const categoryTipsIntentEN = <String, Map<AngleFilter, TitledBody>>{
  'love': {
    AngleFilter.asc: (
      title: 'Example actions for "Love" × ASC',
      body: '[ASC: the moment of beginnings (eastern horizon)]\n'
          'The phase where the theme of connection "rises into the open."\n'
          'A window when new encounters and the first buds of relationship begin to stir.\n\n'
          '· Stay open to new places to meet and openings for conversation\n'
          '· Take the first move to begin a new connection\n'
          '· Reach out with a word to someone you have had in mind\n\n'
          '[ASC → MC (the rising passage)]\n'
          'The connection that has budded gradually comes into the open\n'
          'in the world — a rising window where active, public moves\n'
          'build up little by little.\n\n'
          'This isn\'t a verdict of good or bad.\n'
          'It\'s simply one example of the energy that\'s present.\n'
          'How you move with it, you choose.',
    ),
    AngleFilter.mc: (
      title: 'Example actions for "Love" × MC',
      body: '[MC: the peak of coming into the open (zenith)]\n'
          'The peak where the theme of connection "comes into the open in the world."\n'
          'A window to declare a relationship in public, before others.\n\n'
          '· Express clearly to the other person where you stand in the relationship\n'
          '· Engage actively at public gatherings\n'
          '· Let your appeal show in social settings\n\n'
          '[MC → DSC (the setting passage)]\n'
          'A turning window where the focus descends from a public\n'
          'declaration toward facing and dialogue one to one.\n'
          'From your own appeal, the focus shifts toward engaging with others.\n\n'
          'This isn\'t a verdict of good or bad.\n'
          'It\'s simply one example of the energy that\'s present.\n'
          'How you move with it, you choose.',
    ),
    AngleFilter.dsc: (
      title: 'Example actions for "Love" × DSC',
      body: '[DSC: the turn toward facing (western horizon)]\n'
          'The turn where the theme of connection "descends into others and relationship."\n'
          'A window for deep one-to-one dialogue and tending the relationship.\n\n'
          '· Deepen quiet dialogue with someone who matters\n'
          '· Make time to attend to the other person\'s feelings and inner world\n'
          '· Tend carefully to adjusting and aligning the relationship\n\n'
          '[DSC → IC (the passage underground)]\n'
          'A sinking window where the facing dialogue settles inward,\n'
          'toward intimate time within home and an anchor for the heart.\n'
          'From surface dialogue, the focus moves toward deeper closeness.\n\n'
          'This isn\'t a verdict of good or bad.\n'
          'It\'s simply one example of the energy that\'s present.\n'
          'How you move with it, you choose.',
    ),
    AngleFilter.ic: (
      title: 'Example actions for "Love" × IC',
      body: '[IC: the deepest point of settling inward (directly below)]\n'
          'The deepest point where the theme of connection "settles into your inner ground."\n'
          'A window for intimate time within home and an anchor for the heart.\n\n'
          '· Look back on past relationships and sort through gratitude and forgiveness\n'
          '· Warm the bonds that serve as home and an anchor for the heart\n'
          '· Spend time with the other person in a quiet space\n\n'
          '[IC → ASC (the passage rising again)]\n'
          'A window of renewal, turning from the bonds you warmed at your anchor\n'
          'toward the budding of new encounters.\n'
          'The next cycle begins.\n\n'
          'This isn\'t a verdict of good or bad.\n'
          'It\'s simply one example of the energy that\'s present.\n'
          'How you move with it, you choose.',
    ),
    AngleFilter.ascMc: (
      title: '"Love" × Outward phase (ASC+MC)',
      body: 'A window when the theme of connection "moves outward."\n\n'
          '[ASC: beginnings] New encounters and the first buds of relationship\n'
          '[MC: coming into the open] Declaring a relationship in public, before others\n\n'
          '[Passage: beginnings → the rising phase toward coming into the open]\n'
          'A window where the connection that has budded gradually comes into the open\n'
          'in the world. Active, public moves build up little by little.\n\n'
          'An opening to meet and to build relationships — a time to move from your side.\n'
          'This isn\'t a verdict of good or bad.\n'
          'It\'s simply one example of the energy that\'s present.\n'
          'How you move with it, you choose.',
    ),
    AngleFilter.dscIc: (
      title: '"Love" × Inward phase (DSC+IC)',
      body: 'A window when the theme of connection "moves inward."\n\n'
          '[DSC: facing] Deep one-to-one dialogue and tending the relationship\n'
          '[IC: settling inward] Intimate time within home and an anchor for the heart\n\n'
          '[Passage: facing → the sinking phase toward settling inward]\n'
          'A window where the facing dialogue settles inward,\n'
          'toward intimate time within home and an anchor for the heart.\n'
          'From surface dialogue, the focus moves toward deeper closeness.\n\n'
          'A time to deepen existing bonds and to look at the feelings within.\n'
          'This isn\'t a verdict of good or bad.\n'
          'It\'s simply one example of the energy that\'s present.\n'
          'How you move with it, you choose.',
    ),
    AngleFilter.all: (
      title: 'Example actions for "Love"',
      body: 'The theme of connection. The nature of the movement changes at each angle.\n\n'
          '[ASC: beginnings] New encounters and the first buds of relationship\n'
          '[MC: coming into the open] Declaring a relationship in public\n'
          '[DSC: facing] Deep one-to-one dialogue and tending the relationship\n'
          '[IC: settling inward] Intimate time within home and an anchor for the heart\n\n'
          '[The 24-hour cycle\'s passage]\n'
          'Budding (ASC) → coming into the open (MC) → facing (DSC) → settling inward (IC)\n'
          '→ on to the next budding. The energy of connection moves like a wave.\n\n'
          'This isn\'t a verdict of good or bad.\n'
          'It\'s simply one example of the energy that\'s present.\n'
          'How you move with it, you choose.',
    ),
  },
  'money': {
    AngleFilter.asc: (
      title: 'Example actions for "Abundance" × ASC',
      body: '[ASC: the moment of beginnings (eastern horizon)]\n'
          'The phase where the theme of abundance "rises into the open."\n'
          'A window when new income streams and the first buds of value begin to stir.\n\n'
          '· Set a new income stream or side venture in motion\n'
          '· Set up a place to share the value you offer\n'
          '· Take the first step on a money decision you want to move today\n\n'
          '[ASC → MC (the rising passage)]\n'
          'A rising window that builds from the budding of value\n'
          'toward presenting it to the world. Your skills and track record\n'
          'come into view little by little.\n\n'
          'This isn\'t a verdict of good or bad.\n'
          'It\'s simply one example of the energy that\'s present.\n'
          'How you move with it, you choose.',
    ),
    AngleFilter.mc: (
      title: 'Example actions for "Abundance" × MC',
      body: '[MC: the peak of coming into the open (zenith)]\n'
          'The peak where the theme of abundance "comes into the open in the world."\n'
          'A window to present your skills and track record to the world.\n\n'
          '· Act on a decision about a contract, investment, or major purchase\n'
          '· Present your skills and track record to the world\n'
          '· Bring a major career decision into the open\n\n'
          '[MC → DSC (the setting passage)]\n'
          'A turning window where the focus descends from personal\n'
          'achievement toward sharing and working things out. From one\n'
          'person\'s decision, it moves toward arrangements with others.\n\n'
          'This isn\'t a verdict of good or bad.\n'
          'It\'s simply one example of the energy that\'s present.\n'
          'How you move with it, you choose.',
    ),
    AngleFilter.dsc: (
      title: 'Example actions for "Abundance" × DSC',
      body: '[DSC: the turn toward facing (western horizon)]\n'
          'The turn where the theme of abundance "descends into others and relationship."\n'
          'A window for working out money matters with a partner or co-venturer.\n\n'
          '· Work out money matters with a partner or co-venturer\n'
          '· Talk through arrangements for shared assets\n'
          '· Face the other party in a deal or contract with care\n\n'
          '[DSC → IC (the passage underground)]\n'
          'A sinking window where sharing and working things out settle\n'
          'inward, toward revisiting your values and putting your\n'
          'foundations in order. From surface dealings, the focus moves\n'
          'toward an inner reappraisal.\n\n'
          'This isn\'t a verdict of good or bad.\n'
          'It\'s simply one example of the energy that\'s present.\n'
          'How you move with it, you choose.',
    ),
    AngleFilter.ic: (
      title: 'Example actions for "Abundance" × IC',
      body: '[IC: the deepest point of settling inward (directly below)]\n'
          'The deepest point where the theme of abundance "settles into your inner ground."\n'
          'A window for ordering household finances and existing assets, and revisiting your values.\n\n'
          '· Reflectively put your household finances and existing assets in order\n'
          '· Reaffirm what you truly value\n'
          '· Tend the inner ground of "abundance" with a long view\n\n'
          '[IC → ASC (the passage rising again)]\n'
          'A window of renewal, turning from ordering your values\n'
          'toward the budding of new value. The next cycle begins.\n\n'
          'This isn\'t a verdict of good or bad.\n'
          'It\'s simply one example of the energy that\'s present.\n'
          'How you move with it, you choose.',
    ),
    AngleFilter.ascMc: (
      title: '"Abundance" × Outward phase (ASC+MC)',
      body: 'A window when the theme of abundance "moves outward."\n\n'
          '[ASC: beginnings] New income streams and the first buds of value\n'
          '[MC: coming into the open] Presenting to the world and major decisions\n\n'
          '[Passage: beginnings → the rising phase toward coming into the open]\n'
          'A window that builds from the budding of value\n'
          'toward presenting it to the world. Your skills and track record\n'
          'come into view little by little.\n\n'
          'New income streams and career moves — an outward expansion.\n'
          'This isn\'t a verdict of good or bad.\n'
          'It\'s simply one example of the energy that\'s present.\n'
          'How you move with it, you choose.',
    ),
    AngleFilter.dscIc: (
      title: '"Abundance" × Inward phase (DSC+IC)',
      body: 'A window when the theme of abundance "moves inward."\n\n'
          '[DSC: facing] Working out money matters with a partner\n'
          '[IC: settling inward] Revisiting household finances and values\n\n'
          '[Passage: facing → the sinking phase toward settling inward]\n'
          'A window that descends from sharing and working things out,\n'
          'toward revisiting your values and putting your foundations in order.\n'
          'From surface dealings, the focus moves toward an inner reappraisal.\n\n'
          'Ordering existing assets and household finances — an inward steadying.\n'
          'This isn\'t a verdict of good or bad.\n'
          'It\'s simply one example of the energy that\'s present.\n'
          'How you move with it, you choose.',
    ),
    AngleFilter.all: (
      title: 'Example actions for "Abundance"',
      body: 'The theme of abundance. The nature of the movement changes at each angle.\n\n'
          '[ASC: beginnings] New income streams and the first buds of value\n'
          '[MC: coming into the open] Presenting to the world and major decisions\n'
          '[DSC: facing] Working out money matters with a partner\n'
          '[IC: settling inward] Revisiting household finances and values\n\n'
          '[The 24-hour cycle\'s passage]\n'
          'Budding (ASC) → coming into the open (MC) → facing (DSC) → settling inward (IC)\n'
          '→ on to the next budding. The energy of abundance moves like a wave.\n\n'
          'This isn\'t a verdict of good or bad.\n'
          'It\'s simply one example of the energy that\'s present.\n'
          'How you move with it, you choose.',
    ),
  },
  'work': {
    AngleFilter.asc: (
      title: 'Example actions for "Work" × ASC',
      body: '[ASC: the moment of beginnings (eastern horizon)]\n'
          'The phase where the theme of work "rises into the open."\n'
          'A window for the budding of new projects and new roles.\n\n'
          '· Set a new project in motion\n'
          '· Get a new task or role off the ground\n'
          '· Take the first step on today\'s work\n\n'
          '[ASC → MC (the rising passage)]\n'
          'A rising window that builds from starting out toward presenting\n'
          'results. The project gradually comes into the open.\n\n'
          'This isn\'t a verdict of good or bad.\n'
          'It\'s simply one example of the energy that\'s present.\n'
          'How you move with it, you choose.',
    ),
    AngleFilter.mc: (
      title: 'Example actions for "Work" × MC',
      body: '[MC: the peak of coming into the open (zenith)]\n'
          'The peak where the theme of work "comes into the open in the world."\n'
          'A window for presentations, sharing results, and leadership.\n\n'
          '· Speak up in an important presentation or meeting\n'
          '· Show your results and direction to the world\n'
          '· Step into a moment that calls for leadership\n\n'
          '[MC → DSC (the setting passage)]\n'
          'A turning window where the focus descends from individual shine\n'
          'toward collaboration. From the leader as an individual, the focus\n'
          'moves toward working things out with the people involved.\n\n'
          'This isn\'t a verdict of good or bad.\n'
          'It\'s simply one example of the energy that\'s present.\n'
          'How you move with it, you choose.',
    ),
    AngleFilter.dsc: (
      title: 'Example actions for "Work" × DSC',
      body: '[DSC: the turn toward facing (western horizon)]\n'
          'The turn where the theme of work "descends into others and relationship."\n'
          'A window for working things out and collaborating with colleagues and clients.\n\n'
          '· Deepen the working-out with colleagues and clients\n'
          '· Move along talks about collaboration and dividing the work\n'
          '· Revisit trust and adjust agreements\n\n'
          '[DSC → IC (the passage underground)]\n'
          'A window where working out collaboration settles inward, toward\n'
          'reviewing how you work and firming up your footing. From surface\n'
          'cooperation, the focus moves toward firming up your footing\n'
          'with a long view.\n\n'
          'This isn\'t a verdict of good or bad.\n'
          'It\'s simply one example of the energy that\'s present.\n'
          'How you move with it, you choose.',
    ),
    AngleFilter.ic: (
      title: 'Example actions for "Work" × IC',
      body: '[IC: the deepest point of settling inward (directly below)]\n'
          'The deepest point where the theme of work "settles into your inner ground."\n'
          'A window for reviewing how you work and the footing of your career.\n\n'
          '· Reflectively review how you work and the footing beneath it\n'
          '· Sort through past wins and missteps\n'
          '· Warm your career with a long view\n\n'
          '[IC → ASC (the passage rising again)]\n'
          'A window of renewal, turning from firming up your footing toward\n'
          'a fresh start. The next cycle begins.\n\n'
          'This isn\'t a verdict of good or bad.\n'
          'It\'s simply one example of the energy that\'s present.\n'
          'How you move with it, you choose.',
    ),
    AngleFilter.ascMc: (
      title: '"Work" × Outward phase (ASC+MC)',
      body: 'A window when the theme of work "moves outward."\n\n'
          '[ASC: beginnings] Setting a new project in motion\n'
          '[MC: coming into the open] Presentations and sharing results\n\n'
          '[Passage: beginnings → the rising phase toward coming into the open]\n'
          'A window that builds from starting out toward presenting results.\n'
          'The project gradually comes into the open.\n\n'
          'Launching plans, moving before others, making decisions.\n'
          'This isn\'t a verdict of good or bad.\n'
          'It\'s simply one example of the energy that\'s present.\n'
          'How you move with it, you choose.',
    ),
    AngleFilter.dscIc: (
      title: '"Work" × Inward phase (DSC+IC)',
      body: 'A window when the theme of work "moves inward."\n\n'
          '[DSC: facing] Working things out with colleagues and clients\n'
          '[IC: settling inward] Reviewing how you work and your career\n\n'
          '[Passage: facing → the sinking phase toward settling inward]\n'
          'A window that descends from working out collaboration\n'
          'toward firming up your footing with a long view.\n'
          'From surface cooperation, the focus moves toward an inner review.\n\n'
          'Inner ordering, teamwork, firming up the ground.\n'
          'This isn\'t a verdict of good or bad.\n'
          'It\'s simply one example of the energy that\'s present.\n'
          'How you move with it, you choose.',
    ),
    AngleFilter.all: (
      title: 'Example actions for "Work"',
      body: 'The theme of work. The nature of the movement changes at each angle.\n\n'
          '[ASC: beginnings] Setting a new project in motion\n'
          '[MC: coming into the open] Presentations and sharing results\n'
          '[DSC: facing] Working things out with colleagues and clients\n'
          '[IC: settling inward] Reviewing how you work and your career\n\n'
          '[The 24-hour cycle\'s passage]\n'
          'Budding (ASC) → coming into the open (MC) → facing (DSC) → settling inward (IC)\n'
          '→ on to the next budding. The energy of work moves like a wave.\n\n'
          'Every angle has its value. Choose as your situation calls for.',
    ),
  },
  'healing': {
    AngleFilter.asc: (
      title: 'Example actions for "Healing" × ASC',
      body: '[ASC: the moment of beginnings (eastern horizon)]\n'
          'The phase where the theme of healing "rises into the open."\n'
          'A window for the budding of new practices for health and well-being.\n\n'
          '· Begin a new practice for health or well-being\n'
          '· Take in fresh air and move your body lightly\n'
          '· Visit a restful place you have had in mind (yoga, hot springs, and the like)\n\n'
          '[ASC → MC (the rising passage)]\n'
          'A window that builds from the budding of your intention toward\n'
          'health toward sharing it. The practice gradually shows up in the world.\n\n'
          'This isn\'t a verdict of good or bad.\n'
          'It\'s simply one example of the energy that\'s present.\n'
          'How you move with it, you choose.',
    ),
    AngleFilter.mc: (
      title: 'Example actions for "Healing" × MC',
      body: '[MC: the peak of coming into the open (zenith)]\n'
          'The peak where the theme of healing "comes into the open in the world."\n'
          'A window for caring for the heart and sharing about health.\n\n'
          '· Talk to someone about caring for your own heart\n'
          '· State your intention toward health openly\n'
          '· Stand before others and share around a theme of healing\n\n'
          '[MC → DSC (the setting passage)]\n'
          'A turning window where the focus descends from public healing\n'
          'toward intimate dialogue. From sharing outward, the focus moves\n'
          'toward heartfelt exchange one to one.\n\n'
          'This isn\'t a verdict of good or bad.\n'
          'It\'s simply one example of the energy that\'s present.\n'
          'How you move with it, you choose.',
    ),
    AngleFilter.dsc: (
      title: 'Example actions for "Healing" × DSC',
      body: '[DSC: the turn toward facing (western horizon)]\n'
          'The turn where the theme of healing "descends into others and relationship."\n'
          'A window for heartfelt dialogue with someone you trust.\n\n'
          '· Let someone you trust gently hear what is on your heart\n'
          '· Make time to share feelings one to one\n'
          '· Deepen dialogue that attends to the other person\'s heart\n\n'
          '[DSC → IC (the passage underground)]\n'
          'A window where dialogue settles inward, toward a deep dialogue\n'
          'with yourself. From surface exchange, the focus moves toward\n'
          'an inner healing.\n\n'
          'This isn\'t a verdict of good or bad.\n'
          'It\'s simply one example of the energy that\'s present.\n'
          'How you move with it, you choose.',
    ),
    AngleFilter.ic: (
      title: 'Example actions for "Healing" × IC',
      body: '[IC: the deepest point of settling inward (directly below)]\n'
          'The deepest point where the theme of healing "settles into your inner ground."\n'
          'A window for rest, meditation, and dialogue with yourself.\n\n'
          '· Breathe deeply and meditate in a quiet place\n'
          '· Sort through your feelings by journaling or writing\n'
          '· Be gentle with your body and lean into rest\n\n'
          '[IC → ASC (the passage rising again)]\n'
          'A window of renewal, turning from inner healing toward the\n'
          'budding of a new practice. The next cycle begins.\n\n'
          'This isn\'t a verdict of good or bad.\n'
          'It\'s simply one example of the energy that\'s present.\n'
          'How you move with it, you choose.',
    ),
    AngleFilter.ascMc: (
      title: '"Healing" × Outward phase (ASC+MC)',
      body: 'A window when the theme of healing "moves outward."\n\n'
          '[ASC: beginnings] The budding of a new practice\n'
          '[MC: coming into the open] Caring for the heart and sharing about health\n\n'
          '[Passage: beginnings → the rising phase toward coming into the open]\n'
          'A window where a new practice builds toward sharing it outward.\n'
          'The practice gradually shows itself.\n\n'
          'Moving your body, fresh air, places of healing in the open.\n'
          'This isn\'t a verdict of good or bad.\n'
          'It\'s simply one example of the energy that\'s present.\n'
          'How you move with it, you choose.',
    ),
    AngleFilter.dscIc: (
      title: '"Healing" × Inward phase (DSC+IC)',
      body: 'A window when the theme of healing "moves inward."\n\n'
          '[DSC: facing] Heartfelt dialogue with someone you trust\n'
          '[IC: settling inward] Rest, meditation, and dialogue with yourself\n\n'
          '[Passage: facing → the sinking phase toward settling inward]\n'
          'A window that descends from heartfelt dialogue toward a deep\n'
          'dialogue with yourself. From surface exchange, the focus moves\n'
          'toward an inner healing.\n\n'
          'Deep recovery through rest and reflection — dialogue with yourself.\n'
          'This isn\'t a verdict of good or bad.\n'
          'It\'s simply one example of the energy that\'s present.\n'
          'How you move with it, you choose.',
    ),
    AngleFilter.all: (
      title: 'Example actions for "Healing"',
      body: 'The theme of healing. The nature of the movement changes at each angle.\n\n'
          '[ASC: beginnings] New practices for health and well-being\n'
          '[MC: coming into the open] Caring for the heart and sharing about health\n'
          '[DSC: facing] Heartfelt dialogue with someone you trust\n'
          '[IC: settling inward] Rest, meditation, and dialogue with yourself\n\n'
          '[The 24-hour cycle\'s passage]\n'
          'Budding (ASC) → coming into the open (MC) → facing (DSC) → settling inward (IC)\n'
          '→ on to the next budding. The energy of healing moves like a wave.\n\n'
          'Without forcing anything, let ease come first.',
    ),
  },
  'communication': {
    AngleFilter.asc: (
      title: 'Example actions for "Talk" × ASC',
      body: '[ASC: the moment of beginnings (eastern horizon)]\n'
          'The phase where the theme of dialogue "rises into the open."\n'
          'A window for the budding of reaching out to new people and starting to share.\n\n'
          '· Begin reaching out with a word to someone new\n'
          '· Start posting something new on social media or a blog\n'
          '· Take up a topic that has been on your mind\n\n'
          '[ASC → MC (the rising passage)]\n'
          'A window that builds from new sharing toward sharing on a bigger\n'
          'stage. Reaching out gradually grows into sharing with the wider world.\n\n'
          'This isn\'t a verdict of good or bad.\n'
          'It\'s simply one example of the energy that\'s present.\n'
          'How you move with it, you choose.',
    ),
    AngleFilter.mc: (
      title: 'Example actions for "Talk" × MC',
      body: '[MC: the peak of coming into the open (zenith)]\n'
          'The peak where the theme of dialogue "comes into the open in the world."\n'
          'A window for presentations and sharing on a big stage.\n\n'
          '· Present what you know in a talk or on a big stage\n'
          '· Put your message to the world out at full reach\n'
          '· Share what you have learned publicly\n\n'
          '[MC → DSC (the setting passage)]\n'
          'A turning window where the focus descends from public sharing\n'
          'toward individual dialogue. From sharing with many, the focus\n'
          'moves toward dialogue one to one.\n\n'
          'This isn\'t a verdict of good or bad.\n'
          'It\'s simply one example of the energy that\'s present.\n'
          'How you move with it, you choose.',
    ),
    AngleFilter.dsc: (
      title: 'Example actions for "Talk" × DSC',
      body: '[DSC: the turn toward facing (western horizon)]\n'
          'The turn where the theme of dialogue "descends into others and relationship."\n'
          'A window for deep one-to-one dialogue and meetings.\n\n'
          '· Set up a deep one-to-one talk or consultation\n'
          '· Receive what the other person says with care\n'
          '· Move along a meeting or discussion\n\n'
          '[DSC → IC (the passage underground)]\n'
          'A window where dialogue settles inward, toward putting things\n'
          'into words reflectively. From surface conversation, the focus\n'
          'moves toward deeper inner writing.\n\n'
          'This isn\'t a verdict of good or bad.\n'
          'It\'s simply one example of the energy that\'s present.\n'
          'How you move with it, you choose.',
    ),
    AngleFilter.ic: (
      title: 'Example actions for "Talk" × IC',
      body: '[IC: the deepest point of settling inward (directly below)]\n'
          'The deepest point where the theme of dialogue "settles into your inner ground."\n'
          'A window for reflective writing and dialogue with the voice of your heart.\n\n'
          '· Reflectively order your thoughts through reading and writing\n'
          '· Receive the messages from your heart and the unconscious\n'
          '· Look back and sort through past conversations\n\n'
          '[IC → ASC (the passage rising again)]\n'
          'A window of renewal, turning from reflective ordering toward the\n'
          'budding of new dialogue. The next cycle begins.\n\n'
          'This isn\'t a verdict of good or bad.\n'
          'It\'s simply one example of the energy that\'s present.\n'
          'How you move with it, you choose.',
    ),
    AngleFilter.ascMc: (
      title: '"Talk" × Outward phase (ASC+MC)',
      body: 'A window when the theme of dialogue "moves outward."\n\n'
          '[ASC: beginnings] Reaching out to new people\n'
          '[MC: coming into the open] Presentations and sharing on a big stage\n\n'
          '[Passage: beginnings → the rising phase toward coming into the open]\n'
          'A window where reaching out builds toward sharing on a bigger stage.\n'
          'Individual exchange gradually grows into sharing with the wider world.\n\n'
          'Speaking in public, social media, presentations.\n'
          'This isn\'t a verdict of good or bad.\n'
          'It\'s simply one example of the energy that\'s present.\n'
          'How you move with it, you choose.',
    ),
    AngleFilter.dscIc: (
      title: '"Talk" × Inward phase (DSC+IC)',
      body: 'A window when the theme of dialogue "moves inward."\n\n'
          '[DSC: facing] Deep one-to-one dialogue\n'
          '[IC: settling inward] Reflective writing and dialogue with the voice of your heart\n\n'
          '[Passage: facing → the sinking phase toward settling inward]\n'
          'A window that descends from one-to-one dialogue toward deep\n'
          'reflection and dialogue with the voice of your heart.\n'
          'From surface conversation, the focus moves toward deeper inner writing.\n\n'
          'Deep dialogue, putting your inner world into words, sharing within close bonds.\n'
          'This isn\'t a verdict of good or bad.\n'
          'It\'s simply one example of the energy that\'s present.\n'
          'How you move with it, you choose.',
    ),
    AngleFilter.all: (
      title: 'Example actions for "Talk"',
      body: 'The theme of dialogue. The nature of the movement changes at each angle.\n\n'
          '[ASC: beginnings] Reaching out to new people\n'
          '[MC: coming into the open] Presentations and sharing on a big stage\n'
          '[DSC: facing] Deep one-to-one dialogue\n'
          '[IC: settling inward] Reflective writing\n\n'
          '[The 24-hour cycle\'s passage]\n'
          'Budding (ASC) → coming into the open (MC) → facing (DSC) → settling inward (IC)\n'
          '→ on to the next budding. The energy of dialogue moves like a wave.\n\n'
          'No need to force yourself to speak — at your own pace.',
    ),
  },
};

/// アングル詳細 popup の内容 (en・7 アングル)。
const angleDetailContentEN = <AngleFilter, TitledBody>{
  AngleFilter.asc: (
    title: '🌅 ASC (Eastern horizon · Beginnings)',
    body: '[The ASC moment]\n'
        'The moment a planet rises right on the eastern horizon.\n'
        'The phase where that theme newly stirs and rises outward.\n'
        'It can be read as a time of beginnings, setting out, and showing yourself.\n\n'
        '[ASC → MC (the rising passage)]\n'
        'After the ASC pass, the planet keeps rising toward the zenith (MC).\n'
        'This passage is the rising phase where a theme "starts to come out\n'
        'and gradually comes into the open in the world." Active, public moves\n'
        'build up little by little.\n\n'
        'Next step: choose MC in the dropdown to see\n'
        'the peak of coming into the open and the shift toward DSC.',
  ),
  AngleFilter.mc: (
    title: '☀ MC (Zenith · Coming into the open)',
    body: '[The MC moment]\n'
        'The moment a planet passes directly overhead (the zenith).\n'
        'The peak phase where that theme comes most into the open in the world.\n'
        'It can be read as a time of leadership, a public role,\n'
        'and sharing results.\n\n'
        '[MC → DSC (the setting passage)]\n'
        'After the MC pass, the planet descends toward\n'
        'the western horizon (DSC).\n'
        'This passage is the turning phase where a theme "descends from\n'
        'coming into the open in the world toward the context of\n'
        'relationship and dialogue." The focus moves from individual shine\n'
        'toward engaging with others.\n\n'
        'Next step: choose DSC in the dropdown to see\n'
        'the moment of facing and the shift toward IC.',
  ),
  AngleFilter.dsc: (
    title: '🌇 DSC (Western horizon · Facing)',
    body: '[The DSC moment]\n'
        'The moment a planet sets right on the western horizon.\n'
        'The turning phase where that theme descends into relationship\n'
        'and facing others. It can be read as a time of one-to-one\n'
        'dialogue, tending the relationship, and partnership.\n\n'
        '[DSC → IC (the passage underground)]\n'
        'After the DSC pass, the planet travels underground\n'
        'toward the point directly below (IC).\n'
        'This passage is the sinking phase where a theme "settles from\n'
        'relationship into your inner ground and the unconscious." From\n'
        'surface dialogue, the focus moves toward deep reflection and\n'
        'ordering the heart.\n\n'
        'Next step: choose IC in the dropdown to see\n'
        'the deepest point and the shift toward the next ASC.',
  ),
  AngleFilter.ic: (
    title: '🌑 IC (Directly below · Settling inward)',
    body: '[The IC moment]\n'
        'The moment a planet passes directly below (the nadir, the far side of the Earth).\n'
        'The deepest phase where that theme settles most deeply\n'
        'into your inner ground, the unconscious, and your roots.\n'
        'It can be read as a time of rest, reflection, home,\n'
        'and self-acceptance.\n\n'
        '[IC → ASC (the passage rising again)]\n'
        'After the IC pass, the planet begins to rise once more\n'
        'toward the eastern horizon (ASC).\n'
        'This passage is the phase of renewal, where a theme turns "from\n'
        'the deepest settling toward the start of a newly budding cycle."\n'
        'What you warmed within ripens toward\n'
        'the next beginning.\n\n'
        'Next step: choose ASC in the dropdown to see\n'
        'the next moment of beginnings (the 24-hour cycle).',
  ),
  AngleFilter.ascMc: (
    title: 'Outward phase (ASC+MC)',
    body: 'The phase where a planet passes above the surface.\n'
        'The energy where a theme comes into the open and shows outward.\n\n'
        '[ASC: the moment of beginnings] Newly budding on the eastern horizon\n'
        '[MC: the peak of coming into the open] Shining most in the world at the zenith\n\n'
        'Choose an individual angle (ASC / MC) to see\n'
        'a fuller account of each moment and its passage.',
  ),
  AngleFilter.dscIc: (
    title: 'Inward phase (DSC+IC)',
    body: 'The phase where a planet passes below the surface.\n'
        'The energy where a theme settles into dialogue, relationship, reflection, and the unconscious.\n\n'
        '[DSC: the turn toward facing] Descending into the context of others on the western horizon\n'
        '[IC: the deepest point of settling inward] Settling most deeply into your inner ground directly below\n\n'
        'Choose an individual angle (DSC / IC) to see\n'
        'a fuller account of each moment and its passage.',
  ),
  AngleFilter.all: (
    title: 'All four angles (the 24-hour cycle)',
    body: 'As a planet circles the Earth over the course of a day,\n'
        'it passes four angles against the sky of your reference point.\n\n'
        '🌅 ASC (eastern horizon) — the moment of beginnings\n'
        '☀ MC  (directly overhead = zenith) — the peak of coming into the open\n'
        '🌇 DSC (western horizon) — the turn toward facing\n'
        '🌑 IC  (directly below = underground) — the deepest point of settling inward\n\n'
        'Choose an individual angle in the dropdown to see\n'
        'the reading of that moment and its "passage" toward the next angle\n'
        'in fuller detail.',
  ),
};
