// ============================================================
// Solara Astro Glossary — 英語版用語辞書 (英語化 Phase 2)
// astro_glossary.dart から分離 (HARD7 維持のため)。
// 同一キー・STYLE_VOICE_EN。astroGlossaryEntryFor が en ロケールで選択。
// ============================================================

import 'astro_glossary.dart';

/// 英語版用語辞書 (STYLE_VOICE_EN・中立・吉凶回避・英語化 Phase 2)。
/// astroGlossary と同一キー。en ロケールで astroGlossaryEntryFor が選択する。
const Map<String, AstroGlossaryEntry> astroGlossaryEN = {
  // ── 4 angles ──
  'asc': AstroGlossaryEntry(
    title: 'ASC (Ascendant)',
    summary: 'The zodiac point rising on the eastern horizon. The cusp of the 1st house.',
    detail:
        'The point on the ecliptic that was rising on the eastern horizon at the moment of your birth. '
        'As the cusp (starting point) of the 1st house, it governs your outward persona, first impression, and physical traits.\n\n'
        'When you relocate, the sign on the ASC changes — and with it, "how you appear" in that place.',
  ),
  'mc': AstroGlossaryEntry(
    title: 'MC (Midheaven)',
    summary: 'The zodiac point on the meridian. The cusp of the 10th house.',
    detail:
        'The point at the zenith (where the meridian meets the ecliptic) at the moment of your birth. '
        'As the cusp of the 10th house, it governs your social role, career, and public reputation.\n\n'
        'When relocation changes the sign on your MC, your "social standing" in that place shifts. '
        'There is even the idea of activating your MC in a particular city — a "Hollywood MC," for instance.',
  ),
  'dsc': AstroGlossaryEntry(
    title: 'DSC (Descendant)',
    summary: 'The zodiac point setting on the western horizon. The cusp of the 7th house.',
    detail:
        'The point exactly opposite the ASC. As the cusp of the 7th house, '
        'it governs partnership, relationships, and marriage.\n\n'
        'If the ASC is "the self," the DSC is "others, as they are for you." '
        'When relocation changes the DSC, the kind of people you meet tends to change.',
  ),
  'ic': AstroGlossaryEntry(
    title: 'IC (Imum Coeli)',
    summary: 'The zodiac point below the meridian. The cusp of the 4th house.',
    detail:
        'The point exactly opposite the MC. As the cusp of the 4th house, '
        'it governs home, roots, and your inner anchor.\n\n'
        'When relocation changes the IC, your sense of "feeling at home" in that place changes.',
  ),

  // ── Houses (12) ──
  'house_1': AstroGlossaryEntry(
    title: 'The 1st House (House of the Ascendant)',
    summary: 'Self, body, first impression.',
    detail: 'Yourself, your body, how your character shows. The ASC is its starting point. '
        'A planet here lets its nature come to the surface.',
  ),
  'house_2': AstroGlossaryEntry(
    title: 'The 2nd House (House of Money)',
    summary: 'Possessions, money, self-worth.',
    detail: 'Your earning power, belongings, and values. The source of material security and self-esteem.',
  ),
  'house_3': AstroGlossaryEntry(
    title: 'The 3rd House (Communication)',
    summary: 'Conversation, learning, short trips, siblings.',
    detail: 'Everyday conversation, study, the neighborhood, siblings, short journeys. The place of processing information.',
  ),
  'house_4': AstroGlossaryEntry(
    title: 'The 4th House (House of Home)',
    summary: 'Home, roots, inner anchor. The IC is its starting point.',
    detail: 'Home, family, origins, your inner safe base. It also governs the final phase and later years of life.',
  ),
  'house_5': AstroGlossaryEntry(
    title: 'The 5th House (House of Creation)',
    summary: 'Romance, play, creativity, children.',
    detail: 'Romance, artistic expression, risk-taking, raising children. The place that gives rise to joy.',
  ),
  'house_6': AstroGlossaryEntry(
    title: 'The 6th House (Work and Health)',
    summary: 'Daily work, health, service.',
    detail: 'Daily routine work, looking after your health, service to others. The craftsman-like mastering of skills.',
  ),
  'house_7': AstroGlossaryEntry(
    title: 'The 7th House (Partnership)',
    summary: 'Marriage, relationships, contracts. The DSC is its starting point.',
    detail: 'Marriage partners, business partners, open rivals. The one-to-one relationship of facing another.',
  ),
  'house_8': AstroGlossaryEntry(
    title: 'The 8th House (House of the Depths)',
    summary: 'Others\' resources, intimacy, transformation, inheritance.',
    detail: 'A partner\'s assets, intimacy, deep bonds, inheritance, psychological transformation, life and death.',
  ),
  'house_9': AstroGlossaryEntry(
    title: 'The 9th House (The Higher Quest)',
    summary: 'Philosophy, religion, long-distance travel, higher learning.',
    detail: 'Foreign lands, ideas, university, religion, long journeys. The place that widens your horizons.',
  ),
  'house_10': AstroGlossaryEntry(
    title: 'The 10th House (House of Vocation)',
    summary: 'Social role, career, renown. The MC is its starting point.',
    detail: 'Profession, social standing, reputation, goals. How the world sees you.',
  ),
  'house_11': AstroGlossaryEntry(
    title: 'The 11th House (House of Fellowship)',
    summary: 'Friends, circles, ideals, future plans.',
    detail: 'Friends, community, hopes, long-term plans, social change.',
  ),
  'house_12': AstroGlossaryEntry(
    title: 'The 12th House (House of Secrets)',
    summary: 'The unconscious, secrets, seclusion, spirituality.',
    detail: 'The unconscious, hidden adversaries, hospital stays, retreat from the world, spiritual seeking. What stays out of sight.',
  ),

  // ── Phase M2 feature terms ──
  'relocation': AstroGlossaryEntry(
    title: 'Relocation (Relocation Chart)',
    summary: 'Birth time stays the same; the houses are recalculated for a different place.',
    detail:
        'A planet\'s position (ecliptic longitude) is fixed by your birth time and does not change wherever you stand. '
        'The ASC, MC, and the twelve house cusps, however, are set by the observer\'s position and direction — '
        'so they are recalculated when you stand somewhere else.\n\n'
        'Result: the same Sun can fall in the 5th house "in Tokyo" and the 10th "in Hawaii." '
        'The house you experience changes — that is, the way you come across in that place changes.',
  ),
  'relocate_layer': AstroGlossaryEntry(
    title: 'Relocation Layer (Pro)',
    summary: 'Treat a tapped point as a place to move to, and compare moving star lines, ASC/MC, and houses.',
    detail:
        'Solara\'s relocation tool (Cosmic Pro only). Tap the map to see, all at once, '
        'how things would shift if you lived there:\n\n'
        '- Star lines that draw nearer / farther compared with your current home (the moving star lines)\n'
        '- Changes in the sign on the ASC / MC\n'
        '- The 12-house re-placement of all 10 planets\n\n'
        'The comparison base is your current home (your birthplace if unset). '
        'A place where the houses of the personal planets (Sun, Moon, Mercury, Venus, Mars) shift greatly '
        'can be called a place where the direction of your life may change.',
  ),
  'aspect_lines': AstroGlossaryEntry(
    title: 'Aspect Lines (Astro*Carto*Graphy / Natal)',
    summary: 'World-map lines of each natal planet × ASC/MC/DSC/IC.',
    detail:
        'The central method of astrocartography, systematized by Jim Lewis in the 1970s. '
        'It projects the 10 natal planets × 4 angles = 40 lines onto the curve of the globe. '
        'A lifelong "map of your essence."\n\n'
        'On the land beneath a line, that planet\'s energy works strongly through a particular angle.\n'
        '- Venus ASC line → the energy of relationship and harmony shows in how you appear\n'
        '- Jupiter MC line → the energy of expansion and opportunity rides your social role\n'
        '- Saturn IC line → the energy of structure and continuity works at the roots of home\n\n'
        'These are not "good" or "bad" — they are the nature of the energy present in that place. '
        'You read it, and decide for yourself how to meet it.',
  ),
  'transit_acg': AstroGlossaryEntry(
    title: 'Transit Lines (Cyclo*Carto*Graphy)',
    summary: 'The 40 lines drawn for the planetary positions of this very moment. They move daily.',
    detail:
        'CCG (Cyclo*Carto*Graphy), systematized by Jim Lewis in 1982 as the sequel to A*C*G. '
        'Instead of the birth moment, it projects the planetary positions of "now" '
        '(or a time you set with the time slider) onto the world map.\n\n'
        'The lines move with time. With the Earth\'s rotation, MC/IC sweep 360° a day, '
        'while ASC/DSC drift westward, meandering by latitude.\n\n'
        'How to use it:\n'
        '- Where is Jupiter ASC passing now → a spot where the energy of expansion gathers\n'
        '- Saturn MC crosses Tokyo next week → a time for structure and choice\n\n'
        'What a line shows is where energy is. Not "lucky" or "unlucky" — what matters is '
        'how you yourself read the energy present, and how you meet it.',
  ),
  'progressed_acg': AstroGlossaryEntry(
    title: 'Progressed Lines (Secondary Progression)',
    summary: 'The 40 lines drawn for secondary-progressed (1 day = 1 year) positions.',
    detail:
        'The planetary positions advanced by secondary progression (1 day = 1 year), turned into A*C*G lines. '
        'A map of where your long-term life themes appear.\n\n'
        'For someone 30 years from birth, it uses the planetary positions 30 days after birth. '
        'The Sun moves slowly, about 1°/year; the Moon about 12°/year.\n\n'
        'It shows the lands where "the essence of your present self" is activated. '
        'Its motion is gentler than the Natal lines (fixed at birth), and it carries deeper meaning than the Transit lines.',
  ),
  'solar_arc_acg': AstroGlossaryEntry(
    title: 'Solar Arc Lines (Solar Arc Direction)',
    summary: 'Lines for positions where the Sun\'s arc of progression is added equally to every planet.',
    detail:
        'Solar Arc Direction — a classical predictive method that adds the Sun\'s secondary-progressed arc '
        '(arc = progressed Sun − natal Sun) equally to every planet.\n\n'
        'Unlike progressions, every planet moves at the same speed (the Sun\'s), so the aspect structure '
        'between planets stays intact. It has traditionally been valued as a marker for the timing of '
        'life\'s major turning points.\n\n'
        'In CCG, a Solar Arc Jupiter MC passage reads as a year when achievement and expansion gather; '
        'Solar Arc Saturn ASC as a year of responsibility and structure. '
        'Not "success" or "failure" — it shows the nature of the energy present in that span.',
  ),
  'aspect_lines_full': AstroGlossaryEntry(
    title: 'Aspect Lines (120-line extension)',
    summary: 'The 40 conjunction lines plus 80 square / trine / sextile lines — 120 lines in all.',
    detail:
        'The default ACG lines (the main lines) are only the 40 conjunctions where planet and angle overlap '
        '(10 planets × 4 angles).\n\n'
        'Turn this toggle ON and, from each planet, three more kinds of line are drawn:\n'
        '- Square (90°) — Hard energy\n'
        '- Trine (120°) — Soft energy\n'
        '- Sextile (60°) — Soft energy (gentler)\n'
        'The 40 main + 80 extension = 120 lines in all.\n\n'
        'This toggle is a single flag, applied at once to every frame currently ON. '
        'Among Natal / Transit / Prog / S.Arc, each frame with lines ON gets its own 80 extension lines '
        '(you cannot turn them ON/OFF per frame).\n\n'
        'The extension lines are thinner dashes, colored by shifting the planet color toward '
        'Soft/Hard energy hues (never the red-green of "good/bad").\n\n'
        'With all 4 frames (Natal / Transit / Prog / S.Arc) ON, you can reach up to 480 lines, '
        'so narrowing the planets with a FORTUNE category in the 3rd layer keeps things readable.\n\n'
        'Solara\'s design philosophy: Soft and Hard are two independent energies. '
        'Read them not as good or bad, but as the nature of the energy present in that place.',
  ),
  'aspect_square': AstroGlossaryEntry(
    title: 'Square Line (90°)',
    summary: 'A line where a planet sits 90° from an angle. Hard energy.',
    detail:
        'A line passing through the points where a planet and its angle form 90°. '
        'Drawn as a dash thinner than the main (conjunction) line.\n\n'
        'The square is Hard energy — it comes with friction and tension. Yet this is not "bad": '
        'by facing it you meet sides of yourself you didn\'t know, and you get the chance to rebuild '
        'a relationship or a work deeply. It may take some resolve. Whether you can take it in is up to you.\n\n'
        'Solara treats Soft and Hard as two independent energies. '
        'Read not as good or bad, but as the nature of the energy present in that place.',
  ),
  'aspect_trine': AstroGlossaryEntry(
    title: 'Trine Line (120°)',
    summary: 'A line where a planet sits 120° from an angle. Soft energy.',
    detail:
        'A line passing through the points where a planet and its angle form 120°. '
        'Drawn as a dash thinner than the main line.\n\n'
        'The trine is Soft energy — the flow is smooth, and talent and harmony tend to come out naturally. '
        'There is an ease of moving without effort, though things can also settle so comfortably that change is slow to come.\n\n'
        'Solara treats Soft and Hard as two independent energies. '
        'Read not as good or bad, but as the nature of the energy present in that place.',
  ),
  'aspect_sextile': AstroGlossaryEntry(
    title: 'Sextile Line (60°)',
    summary: 'A line where a planet sits 60° from an angle. Soft energy.',
    detail:
        'A line passing through the points where a planet and its angle form 60°. '
        'Drawn as a dash thinner than the main line.\n\n'
        'The sextile is Soft energy — gentler than the trine, with the quality of "opportunity." '
        'Like an invitation: take one step yourself and a door opens. Stay still and it stays quiet.\n\n'
        'Solara treats Soft and Hard as two independent energies. '
        'Read not as good or bad, but as the nature of the energy present in that place.',
  ),
  'zenith_point': AstroGlossaryEntry(
    title: 'Zenith Point',
    summary: 'The one point on Earth where a planet is directly overhead (altitude 90°).',
    detail:
        'The single point on the MC line where latitude = the planet\'s declination δ. '
        'Standing there, the planet is literally "directly overhead" (altitude 90°).\n\n'
        'Jim Lewis taught that the zenith point is "not merely one point, but works along the whole circle of that latitude." '
        'That is, in Lewis\'s reading, cities at the same latitude receive that planet\'s energy regardless of longitude (the latitude effect).\n\n'
        'Against the band-like influence of the MC line, the zenith point is the spot where energy "pours down most vertically." '
        'Not good or bad — what matters is that the energy is present there, and how you receive it.',
  ),
  'nadir_point': AstroGlossaryEntry(
    title: 'Nadir Point',
    summary: 'The point where a planet is directly below (on the far side of the Earth) — symmetric to the zenith point.',
    detail:
        'The point on the IC line where latitude = −δ. Completely symmetric to the zenith point across the Earth\'s center; '
        'to an observer the planet is directly beneath one\'s feet (on the far side of the ground).\n\n'
        'In Lewis\'s theory, the nadir too works along the whole circle of that latitude (the same latitude effect as the zenith). '
        'If the zenith works on "public exposure, career, renown," '
        'the nadir is a field that works on "home, roots, the unconscious, foundations."\n\n'
        'Against the band-like influence of the IC line, the nadir point is the spot that "descends most deeply to the roots." '
        'It works on lineage, memory, and the inner life quietly, yet deeply.',
  ),
  'altitude_event': AstroGlossaryEntry(
    title: 'Altitude and Near-Zenith / Near-Nadir',
    summary: 'The planet\'s altitude at MC/IC passage. The closer to 90°, the more it works from directly above / below.',
    detail:
        'At a Daily Transit MC (zenith passage) / IC (nadir passage) event, the planet\'s altitude at that moment is shown. '
        'It ties directly to Lewis\'s reading:\n\n'
        '- MC passage altitude ≈ 90° → the observer\'s latitude nearly equals the planet\'s declination = '
        'a day it "pours from directly overhead." A strong moment that happens only a few times a year.\n'
        '- IC passage altitude ≈ −90° → the planet passes beneath the observer\'s feet = '
        'a day it "moves from within." It appears paired with the near-zenith day.\n\n'
        'The ★ mark (near-zenith / near-nadir) uses a threshold of ±85° (matching the ACG orb). '
        'An ordinary MC passage is around 30–70° altitude, which means "ordinary in strength, but the direction is zenith."',
  ),
  'latitude_band_now': AstroGlossaryEntry(
    title: 'Your Latitude Band Now',
    summary: 'Planets meeting their zenith/nadir on your latitude line at the observation time.',
    detail:
        'Lewis\'s latitude effect — "the zenith/nadir band works along the whole circle of the same latitude" — '
        'brought onto the time axis.\n\n'
        'When a planet\'s declination (δ) is near the observer\'s latitude (orb ±5°):\n'
        '- δ ≈ observer latitude → the planet is at zenith somewhere on that latitude line; energy along the whole latitude\n'
        '- δ ≈ −observer latitude → the planet is at nadir somewhere on that latitude line; deep energy along the whole latitude\n\n'
        'Even if your own longitude is far from the "directly-overhead point," in Lewis\'s reading simply being '
        'on the same latitude line means you receive that planet\'s energy. '
        'This section projects the ACG Latitude Band concept onto Daily Transit.',
  ),
  'latitude_band': AstroGlossaryEntry(
    title: 'Zenith Latitude Band',
    summary: 'The latitude lines through the zenith and nadir — the Lewis reading that they work along the whole latitude.',
    detail:
        'Jim Lewis taught that "the zenith point activates a planet\'s energy not at that point alone, '
        'but along the whole circle of the same latitude." Regardless of longitude, every city at north latitude δ '
        'receives the zenith effect, and every city at south latitude −δ the nadir effect (the latitude effect).\n\n'
        'Visually, it is drawn as bands extending east–west from each planet\'s zenith and nadir.\n'
        'Zenith band (solid line): the latitudes that work on public exposure and career.\n'
        'Nadir band (dotted line): the latitudes that work on home, roots, and the unconscious.\n\n'
        'Because the information density is high, it is OFF by default. Turn it ON when you want to try the Lewis reading.',
  ),
  'sector_score_16': AstroGlossaryEntry(
    title: '16-Direction Energy',
    summary: 'Shows the two independent energies (Soft, Hard) present in each direction.',
    detail:
        'It projects the combined natal/transit/progressed aspects onto 16 directions (N, NNE, NE…), '
        'and computes "Soft energy" and "Hard energy" independently for each.\n\n'
        '☯ Soft: the power of riding the flow (acceptance, expansion, harmony, stability)\n'
        '☐ Hard: the power of friction and transformation (confrontation, growth, review, choice)\n\n'
        'The two are not the ends of one axis but each a separate, independent energy. '
        'Both can run strong at once, or only one of them.\n\n'
        'You can use this whichever way: when you choose a direction to move, when you head toward a direction '
        'you have no choice but to face, or when you meet what comes toward you. '
        'Solara does not say "here is good" or "here is bad." It conveys the energy present. '
        'Reading it and meeting it is yours.\n\n'
        'This is a separate lineage from the Relocation Layer (the local-space school). '
        'When both are shown, the Relocation Layer takes priority and this is dimmed.',
  ),
  'planet_lines': AstroGlossaryEntry(
    title: 'Planetary Direction Lines (Local Space)',
    summary: 'Radial direction lines of each planet drawn from your birthplace.',
    detail:
        'A local-space method. It draws a "house of directions" centered on your birthplace, '
        'showing with lines which way each planet lies.\n\n'
        'It is a different school from astrocartography (the aspect lines). '
        'The former is "local direction," the latter "world curves."',
  ),
  'placidus': AstroGlossaryEntry(
    title: 'Placidus',
    summary: 'The traditional way of dividing the 12 houses on a time basis.',
    detail:
        'The house system of Placidus de Titis (17th century). '
        'It divides the time the Sun takes to move from ASC to MC into three, setting the house boundaries.\n\n'
        'At high latitudes (|lat| > 66°) the calculation breaks down, so Solara automatically falls back to Equal House.',
  ),
  // ── FORTUNE categories ──
  'fortune_all': AstroGlossaryEntry(
    title: 'Overall (All Categories)',
    summary: 'Shows all 10 planetary lines at 100%. No filter.',
    detail:
        'A mode for taking in the whole field of astrology at a glance. '
        'It shows all 10 planets × 4 angles = 40 aspect lines at the same strength.\n\n'
        'Use it when, rather than a single category, you want to read the overall nature of a place '
        'as a "map of life\'s whole energy."',
  ),
  'fortune_love': AstroGlossaryEntry(
    title: 'Love',
    summary: 'Highlights the Venus, Mars, and Moon lines; the rest dim.',
    detail:
        'A filter that brings out only the planets tied to the themes of relationship and love.\n\n'
        '- Venus: love, beauty, relationship\n'
        '- Mars: passion, action, desire\n'
        '- Moon: emotion, intimacy\n\n'
        'A place or time where these three planets\' lines gather is where relationship energy works on many sides. '
        'Both the soft side and the hard side can appear; whether you ride the flow, meet the friction, '
        'or experience both, the choice is yours.',
  ),
  'fortune_money': AstroGlossaryEntry(
    title: 'Abundance',
    summary: 'Highlights the Jupiter, Venus, and Sun lines; the rest dim.',
    detail:
        'A filter for the planets tied to material abundance and the creation of value.\n\n'
        '- Jupiter: expansion, opportunity, generosity\n'
        '- Venus: value, possession, beauty\n'
        '- Sun: self-realization, public role\n\n'
        'A place or time where these ASC/MC lines pass is where the energy of abundance tends to flow. '
        'At the same time, a hard energy of review can be at work. Read both as present.',
  ),
  'fortune_work': AstroGlossaryEntry(
    title: 'Career',
    summary: 'Highlights the Saturn, Mars, Jupiter, and Sun lines; the rest dim.',
    detail:
        'A filter for the planets tied to career and social role.\n\n'
        '- Saturn: responsibility, discipline, structure\n'
        '- Mars: drive, breakthrough\n'
        '- Jupiter: opportunity, expansion\n'
        '- Sun: leadership, public role\n\n'
        'The MC line (the zenith) matters most — it shows your "social face" in that place. '
        'A more Soft-leaning place reads as a year of riding the flow; a more Hard-leaning place as a year of rebuilding the foundation.',
  ),
  'fortune_communication': AstroGlossaryEntry(
    title: 'Talk',
    summary: 'Highlights the Mercury, Venus, and Moon lines; the rest dim.',
    detail:
        'A filter for the planets tied to communication, intellectual activity, and dialogue.\n\n'
        '- Mercury: thought, language, conveying information\n'
        '- Venus: sociability, harmony, charm\n'
        '- Moon: empathy, conveying feeling\n\n'
        'A place where these lines pass is where the energy of writing, dialogue, teaching, and sharing works. '
        'When it leans Hard, an energy of misunderstanding or dispute can also be present.',
  ),
  'fortune_healing': AstroGlossaryEntry(
    title: 'Healing',
    summary: 'Highlights the Moon, Neptune, and Venus lines; the rest dim.',
    detail:
        'A filter for the planets tied to rest, integration, and reflection.\n\n'
        '- Moon: peace, the unconscious, nurture\n'
        '- Neptune: intuition, dreams, integration\n'
        '- Venus: beauty, joy, self-acceptance\n\n'
        'A place where these lines pass is where the energy of retreat, recovery, and reflection flows. '
        'When the Hard component is strong, an inner theme to face may surface.',
  ),

  // ── Daily Transit (CCG) "Today's TOP" selection logic ──
  'top_category_logic': AstroGlossaryEntry(
    title: 'How "Today\'s TOP" Is Chosen',
    summary: 'The category with the greatest total of (5 categories × assigned planets × aspects) is shown as TOP.',
    detail:
        'Solara compares the total energy of each category for the day and brings the category in greatest motion to the TOP.\n'
        'Not "lucky" or "unlucky," but "the motion of energy is greatest."\n\n'
        '─────────────\n'
        'How it is computed\n'
        '─────────────\n'
        '① Each category has a defined set of assigned planets\n'
        '② Aspects of transiting planets × natal / progressed planets are detected\n'
        '③ An aspect between two assigned planets = ×2; only one side assigned = ×0.5\n'
        '④ The nature of each aspect (soft / hard / neutral) is sorted into Solara\'s two independent axes and summed\n'
        '⑤ Each planet\'s direction is spread to the 16 directions with cos² falloff\n'
        '⑥ Summed over 16 directions × category → category total\n'
        '⑦ The category with the greatest total is TOP\n\n'
        '─────────────\n'
        '🌿 Healing (healing)\n'
        '─────────────\n'
        'Assigned planets: Moon, Neptune, Venus\n'
        '×2 pairs: Moon×Neptune / Moon×Venus / Sun×Neptune\n'
        'Core: the pair of Moon (the flow of feeling) and Neptune (integration, reverie)\n\n'
        '─────────────\n'
        '💰 Abundance (money)\n'
        '─────────────\n'
        'Assigned planets: Jupiter, Venus, Sun\n'
        '×2 pairs: Jupiter×Venus / Jupiter×Sun / Venus×Sun\n'
        'Core: the pair of Jupiter (expansion) and Venus (value)\n\n'
        '─────────────\n'
        '💕 Love (love)\n'
        '─────────────\n'
        'Assigned planets: Venus, Mars, Moon\n'
        '×2 pairs: Venus×Mars / Venus×Moon / Mars×Moon\n'
        'Core: Venus×Mars (the motion of relationship) — the heart of classical astrology\n\n'
        '─────────────\n'
        '💼 Career (work)\n'
        '─────────────\n'
        'Assigned planets: Saturn, Sun, Mars, Jupiter\n'
        '×2 pairs: Saturn×Sun / Saturn×Mars / Jupiter×Sun / Jupiter×Mars\n'
        'Core: the pair of Saturn (responsibility, structure) and the social planets\n\n'
        '─────────────\n'
        '💬 Talk (communication)\n'
        '─────────────\n'
        'Assigned planets: Mercury, Sun, Venus, Moon\n'
        '×2 pairs: Mercury×Sun / Mercury×Venus / Mercury×Moon\n'
        'Core: Mercury (thought, language) is always on one side\n\n'
        '─────────────\n'
        'Note\n'
        '─────────────\n'
        '・"TOP = good" is wrong; "TOP = much motion"\n'
        '・Because it includes both soft and hard amounts, a TOP day simply means both energies tend to work\n'
        '・A day with much Hard component is a day with many chances for reflection and review',
  ),

  // ── Daily Transit (CCG) meaning of the 4 angles ──
  'transit_angles': AstroGlossaryEntry(
    title: 'The Meaning of the 4-Angle Passage',
    summary: 'How to read the moment a planet crosses your home\'s ASC/MC/DSC/IC.',
    detail:
        'The moment a planet meets the horizon or meridian is a time when that planet\'s theme '
        'activates in a particular form.\n\n'
        '🌅 ASC (beginning to rise)\n'
        'The moment that planet\'s theme newly sprouts.\n'
        'An outward beginning, appearing on the eastern horizon.\n\n'
        '☀ MC (zenith)\n'
        'The moment that planet\'s theme becomes most visible.\n'
        'Social, public power reaches its peak.\n\n'
        '🌇 DSC (setting)\n'
        'The moment that planet\'s theme turns inward.\n'
        'Descending on the western horizon, entering the context of relationship.\n\n'
        '🌑 IC (underground)\n'
        'The moment that planet\'s theme works in the unconscious, inner realm.\n'
        'Passing underground, it works in the context of reflection and roots.\n\n'
        '※ Not a "good time" or "bad time" — it shows the moment where energy gathers. '
        'How you meet it, you decide yourself.',
  ),

  // ── Solara design-philosophy keywords ──
  'two_energies': AstroGlossaryEntry(
    title: 'Two Independent Energies (Soft, Hard)',
    summary: 'Soft and Hard are not the ends of one axis but each a separate energy.',
    detail:
        'Solara treats aspect energy as two independent axes, "Soft" and "Hard."\n\n'
        '☯ Soft energy — the power of riding the flow\n'
        'Generosity, expansion, acceptance, harmony, stability. An energy where things move smoothly, '
        'encounters arise, and the heart opens.\n'
        'Underlying aspects: trine (120°), sextile (60°).\n\n'
        '☐ Hard energy — the power of friction and change\n'
        'Challenge, transformation, confrontation, growth. An energy where, within struggle, something comes into view — '
        'where deep learning, and a meeting with yourself, take place.\n'
        'Underlying aspects: square (90°), opposition (180°), quincunx (150°).\n\n'
        '○ Neutral aspect — holding both\n'
        'The conjunction (0°) is two planets overlapping at the same position. '
        'Rather than one or the other, it carries both Soft and Hard natures at once.\n'
        'In the score, its weight is added half and half (50:50) to both the Soft and Hard amounts. '
        'It appears as a field where both energies work at once.\n\n'
        'Both are beautiful energies, each of them. Not plus and minus, but a difference of nature. '
        'Both can run strong at the same time — and then a deep experience happens.',
  ),
  'soft_aspect': AstroGlossaryEntry(
    title: 'Soft Aspect',
    summary: 'Trine (120°), sextile (60°), and the like — aspects that create flow.',
    detail:
        'Aspects where planets form the harmonious angles of 60° or 120°.\n\n'
        'They create Soft energy — flow, acceptance, harmony, expansion, integration. '
        'Things move smoothly, and new encounters and opportunities tend to appear.\n\n'
        'Yet it is not "good," only "easy to flow." Whether you ride the flow as it is, '
        'or consciously choose your direction, is your choice.',
  ),
  'hard_aspect': AstroGlossaryEntry(
    title: 'Hard Aspect',
    summary: 'Square (90°), opposition (180°), and the like — aspects that create friction and transformation.',
    detail:
        'Aspects where planets form the tense angles of 90° or 180°.\n\n'
        'They create Hard energy — friction, confrontation, choice, transformation, growth. '
        'Through discomfort and struggle, what you couldn\'t see comes into view.\n\n'
        'It is not "bad." If anything, it is a time when deep learning happens. '
        'Whether you look again, take action, or step back, you choose.',
  ),

  // ── Daily Transit per-category "example actions" intent ──
  'category_tips_intent': AstroGlossaryEntry(
    title: 'Examples of Suggested Action — How to Use',
    summary: 'These are "hints," not "instructions." A reference for thinking up your own move.',
    detail:
        'The time bands shown by this filter are the moments when the chosen category\'s energy is in motion.\n'
        'The action examples shown are not instructions saying "you must do exactly this."\n\n'
        '─────────────\n'
        'The intent of the examples\n'
        '─────────────\n'
        '・They illustrate the typical way to move for this category × angle phase (outward / inward)\n'
        '・Use them as hints to adapt the move to your own situation\n'
        '・Let them be a spark for thinking "how would I move?"\n\n'
        '─────────────\n'
        'Examples of adapting\n'
        '─────────────\n'
        'If it says "be aware of new encounters or openings for dialogue," for instance,\n'
        'the actual move is free, to fit your own life.\n'
        '・Invite a friend out for a meal\n'
        '・Message an acquaintance you haven\'t reached in a while on social media\n'
        '・Say a word to the person at the next desk at work\n'
        '・Chat a little with the shop staff at a store\n'
        '・Look in on a new community\n'
        'Each is an adaptation of "be aware of an opening for dialogue."\n\n'
        '─────────────\n'
        'Solara\'s stance\n'
        '─────────────\n'
        'Solara only conveys where energy is moving.\n'
        'It does not say "lucky" or "unlucky."\n'
        'How you engage, and what you do, you choose.',
  ),
};
