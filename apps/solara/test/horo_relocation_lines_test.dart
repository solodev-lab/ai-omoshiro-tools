// 拠点ライン近接デルタ (horo_relocation_lines.dart) のテスト。
//
// 検証:
//   - computeRelocationLineDeltas: 7惑星×4アングル=28本・conjunction限定・|delta|降順
//   - 同一地点なら delta≈0、移動すれば非ゼロが出る (= 「変化なし」が消える)
//   - 文の合成 (近づく→強まる / 遠ざかる→やわらぐ・中立表現)
//   - 度合い副詞の閾値 / ハウス変化コメント

import 'package:flutter_test/flutter_test.dart';
import 'package:solara/screens/horoscope/horo_relocation_lines.dart';

void main() {
  // 7惑星の黄経 (任意の現実的な値)。
  const natal = <String, double>{
    'sun': 84.0, 'moon': 200.0, 'mercury': 70.0, 'venus': 110.0,
    'mars': 300.0, 'jupiter': 25.0, 'saturn': 330.0,
    // 外惑星も渡すが対象外 (28本に入らないこと確認用)
    'uranus': 15.0, 'neptune': 280.0, 'pluto': 260.0,
  };
  const natalMc = 280.0;

  group('computeRelocationLineDeltas', () {
    test('7惑星×4アングル=28本・conjunction限定・外惑星除外', () {
      final deltas = computeRelocationLineDeltas(
        natalPlanets: natal, natalMc: natalMc,
        birthLat: 35.42, birthLng: 136.76,
        homeLat: 35.18, homeLng: 136.90,
      );
      expect(deltas.length, 28, reason: '7惑星×4アングル');
      for (final d in deltas) {
        expect(relocationPlanetNature.containsKey(d.planet), isTrue,
            reason: '外惑星は除外 (planet=${d.planet})');
        expect(['mc', 'ic', 'asc', 'dsc'].contains(d.angle), isTrue);
      }
    });

    test('現住所から近い順 (homeKm 昇順) に並ぶ', () {
      // |delta| 順ではない: 近距離移動で地球の裏側の無関係ラインが上位に来るのを防ぐため。
      final deltas = computeRelocationLineDeltas(
        natalPlanets: natal, natalMc: natalMc,
        birthLat: 35.42, birthLng: 136.76,
        homeLat: 40.0, homeLng: 140.0,
      );
      for (var i = 1; i < deltas.length; i++) {
        expect(deltas[i - 1].homeKm <= deltas[i].homeKm, isTrue);
      }
    });

    test('同一地点なら全 delta ≈ 0 (移動なし)', () {
      final deltas = computeRelocationLineDeltas(
        natalPlanets: natal, natalMc: natalMc,
        birthLat: 35.42, birthLng: 136.76,
        homeLat: 35.42, homeLng: 136.76,
      );
      for (final d in deltas) {
        expect(d.deltaKm.abs() < 1.0, isTrue,
            reason: '同一地点は変化なし (${d.planet}/${d.angle}=${d.deltaKm})');
      }
    });

    test('移動すれば非ゼロの delta が出る (変化なしが消える)', () {
      final deltas = computeRelocationLineDeltas(
        natalPlanets: natal, natalMc: natalMc,
        birthLat: 35.42, birthLng: 136.76,
        homeLat: 35.18, homeLng: 136.90,
      );
      expect(deltas.any((d) => d.deltaKm.abs() > 1.0), isTrue,
          reason: '近距離でも非ゼロのデルタが出る (変化なしが消える)');
    });
  });

  group('文の合成', () {
    test('近づく → 「近づきました」「強まる」(中立)', () {
      const d = RelocationLineDelta(
          planet: 'venus', angle: 'mc', birthKm: 300, homeKm: 60);
      final s = relocationLineDeltaSentence(d);
      expect(d.closer, isTrue);
      expect(s.contains('近づきました'), isTrue);
      expect(s.contains('強まる'), isTrue);
      expect(s.contains('金星'), isTrue);
      expect(s.contains('MCライン'), isTrue);
      // 吉凶ワードを使わない
      expect(s.contains('幸運') || s.contains('不運') || s.contains('凶'), isFalse);
    });

    test('遠ざかる → 「遠ざかりました」「やわらい」', () {
      const d = RelocationLineDelta(
          planet: 'mars', angle: 'asc', birthKm: 80, homeKm: 400);
      final s = relocationLineDeltaSentence(d);
      expect(d.closer, isFalse);
      expect(s.contains('遠ざかりました'), isTrue);
      expect(s.contains('やわらい'), isTrue);
      expect(s.contains('火星'), isTrue);
      expect(s.contains('ASCライン'), isTrue);
    });

    test('度合い副詞の閾値', () {
      expect(relocationMagnitudeAdverb(100), 'わずかに');
      expect(relocationMagnitudeAdverb(300), 'はっきりと');
      expect(relocationMagnitudeAdverb(700), '大きく');
    });

    test('ハウス変化コメントが from/to 領域を含む', () {
      final c = relocationHouseChangeComment('venus', 2, 9);
      expect(c.contains('金星'), isTrue);
      expect(c.contains('所有・才能・収入'), isTrue);
      expect(c.contains('探求・遠方・学問'), isTrue);
    });
  });
}
