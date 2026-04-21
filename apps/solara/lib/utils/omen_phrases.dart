import 'dart:math' as math;

/// Map 画面のタップボタンに表示するフレーズ。
/// ホロスコープから得た「今日の最も強いスコア」を受け取り、自分の力にする
/// という誘いを10種の文言で表現し、毎回ランダムで1つ選ぶ。
class OmenPhrase {
  final String title;
  final String sub;
  final String cta;
  const OmenPhrase({
    required this.title,
    required this.sub,
    required this.cta,
  });
}

const List<OmenPhrase> omenPhrases = [
  OmenPhrase(
    title: '今日の導き',
    sub: '星が贈る今日の力を、その手にそっと受け取って',
    cta: '✦  受け取る  ✦',
  ),
  OmenPhrase(
    title: '星からの便り',
    sub: '今日あなたに向けられた一筋の光を、自分の力へ',
    cta: '✦  受け取る  ✦',
  ),
  OmenPhrase(
    title: '今日の恵み',
    sub: '星々が送り出す今日の追い風を、そっと身に纏って',
    cta: '✦  纏う  ✦',
  ),
  OmenPhrase(
    title: '星々の加護',
    sub: '星々から届く今日の支えを、あなたの中へ',
    cta: '✦  纏う  ✦',
  ),
  OmenPhrase(
    title: '星の力',
    sub: '天の輝きは、受け取った人の歩みを強くします',
    cta: '✦  受け取る  ✦',
  ),
  OmenPhrase(
    title: '星からの贈り物',
    sub: '今日、あなたに差し出された一粒の光を迎え入れて',
    cta: '✧  迎える  ✧',
  ),
  OmenPhrase(
    title: '星の応援',
    sub: '天空があなたに託した今日の力を、胸にそっと宿しましょう',
    cta: '✶  宿す  ✶',
  ),
  OmenPhrase(
    title: '今日の祝福',
    sub: '星があなたに与える今日の後押しを、しっかり受け取って',
    cta: '✦  受け取る  ✦',
  ),
  OmenPhrase(
    title: '星のしずく',
    sub: '宇宙の星々からあなたの元にとどいた今日の一滴を、あなた自身の力に',
    cta: '✶  宿す  ✶',
  ),
  OmenPhrase(
    title: '惑星の導き',
    sub: '今日の星があなたに差し出すもの — 受け取れば、力になる',
    cta: '✦  受け取る  ✦',
  ),
];

OmenPhrase pickRandomOmenPhrase([math.Random? rng]) {
  final r = rng ?? math.Random();
  return omenPhrases[r.nextInt(omenPhrases.length)];
}
