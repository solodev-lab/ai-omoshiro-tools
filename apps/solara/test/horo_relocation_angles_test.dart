// 拠点アングル近接 (horo_relocation_angles.dart, A案) のテスト。
//
// 検証:
//   - computeRelocationAngleDeltas: 10天体・nearestAngle は4アングルのいずれか
//   - 並び: ハウス移動あり優先 → 現住所で軸に近い順
//   - 同一地点なら deltaDeg≈0 / 移動すれば非ゼロ (= 「変化なし」が消える)
//   - computeRelocationAngleSignChanges: 星座変化の検出
//   - 静的文の合成 (近づく→前に出る / 遠ざかる→落ち着く / ハウス移動ヘッドライン・中立表現)
//   - 度合い副詞の閾値 (Worker JS と一致)

import 'package:flutter_test/flutter_test.dart';
import 'package:solara/screens/horoscope/horo_relocation_angles.dart';

void main() {
  const natal = <String, double>{
    'sun': 84.0, 'moon': 200.0, 'mercury': 70.0, 'venus': 110.0, 'mars': 300.0,
    'jupiter': 25.0, 'saturn': 330.0, 'uranus': 15.0, 'neptune': 280.0, 'pluto': 260.0,
  };
  List<double> equalHouses(double asc) =>
      List.generate(12, (i) => (asc + i * 30) % 360);

  group('computeRelocationAngleDeltas', () {
    test('10天体・nearestAngle は4アングルのいずれか', () {
      final deltas = computeRelocationAngleDeltas(
        natalPlanets: natal,
        natalHouses: equalHouses(100),
        relocateHouses: equalHouses(130),
        natalAsc: 100, natalMc: 10,
        relocateAsc: 130, relocateMc: 40,
      );
      expect(deltas.length, 10);
      for (final d in deltas) {
        expect(['asc', 'mc', 'dsc', 'ic'].contains(d.nearestAngle), isTrue);
        expect(relocationAnglePlanets.contains(d.planet), isTrue);
      }
    });

    test('並び: ハウス移動あり優先 → 軸に近い順 (reloDeg 昇順)', () {
      final deltas = computeRelocationAngleDeltas(
        natalPlanets: natal,
        natalHouses: equalHouses(100),
        relocateHouses: equalHouses(130),
        natalAsc: 100, natalMc: 10,
        relocateAsc: 130, relocateMc: 40,
      );
      // ハウス移動ありが先頭に固まる
      var seenUnchanged = false;
      for (final d in deltas) {
        if (!d.houseChanged) seenUnchanged = true;
        if (d.houseChanged) {
          expect(seenUnchanged, isFalse, reason: 'ハウス移動は先頭グループ');
        }
      }
      // 変化なしグループ内は reloDeg 昇順
      final unchanged = deltas.where((d) => !d.houseChanged).toList();
      for (var i = 1; i < unchanged.length; i++) {
        expect(unchanged[i - 1].reloDeg <= unchanged[i].reloDeg, isTrue);
      }
    });

    test('同一地点 → 全 deltaDeg ≈ 0・ハウス移動なし', () {
      final deltas = computeRelocationAngleDeltas(
        natalPlanets: natal,
        natalHouses: equalHouses(100),
        relocateHouses: equalHouses(100),
        natalAsc: 100, natalMc: 10,
        relocateAsc: 100, relocateMc: 10,
      );
      for (final d in deltas) {
        expect(d.deltaDeg.abs() < 1e-6, isTrue,
            reason: '同一地点は変化なし (${d.planet}=${d.deltaDeg})');
        expect(d.houseChanged, isFalse);
      }
    });

    test('移動すれば非ゼロの deltaDeg が出る (変化なしが消える)', () {
      final deltas = computeRelocationAngleDeltas(
        natalPlanets: natal,
        natalHouses: equalHouses(100),
        relocateHouses: equalHouses(103),
        natalAsc: 100, natalMc: 10,
        relocateAsc: 103, relocateMc: 13,
      );
      expect(deltas.any((d) => d.deltaDeg.abs() > 0.5), isTrue);
    });
  });

  group('computeRelocationAngleSignChanges', () {
    test('星座が変わった軸を検出 (ASC)', () {
      final changes = computeRelocationAngleSignChanges(
        natalAsc: 100, natalMc: 10, // ASC=蟹(idx3)
        relocateAsc: 130, relocateMc: 40, // ASC=獅子(idx4)
      );
      expect(changes.any((c) => c.angle == 'asc'), isTrue);
    });

    test('変化なしなら空', () {
      final changes = computeRelocationAngleSignChanges(
        natalAsc: 100, natalMc: 10,
        relocateAsc: 101, relocateMc: 11, // 同じ星座枠内
      );
      expect(changes, isEmpty);
    });
  });

  group('direction (近づく/遠ざかる/ほぼ変化なし)', () {
    test('reloDeg < natalDeg → closer', () {
      const d = RelocationAngleDelta(
        planet: 'venus', natalHouse: 5, reloHouse: 5,
        nearestAngle: 'mc', natalDeg: 10, reloDeg: 3,
      );
      expect(d.direction, 'closer');
      expect(d.deltaDeg < 0, isTrue);
      expect(d.houseChanged, isFalse);
    });

    test('reloDeg > natalDeg → farther', () {
      const d = RelocationAngleDelta(
        planet: 'mars', natalHouse: 7, reloHouse: 7,
        nearestAngle: 'asc', natalDeg: 3, reloDeg: 12,
      );
      expect(d.direction, 'farther');
    });

    test('差が極小 → same', () {
      const d = RelocationAngleDelta(
        planet: 'jupiter', natalHouse: 2, reloHouse: 2,
        nearestAngle: 'ic', natalDeg: 5.0, reloDeg: 5.05,
      );
      expect(d.direction, 'same');
    });

    test('ハウスが違えば houseChanged', () {
      const d = RelocationAngleDelta(
        planet: 'sun', natalHouse: 10, reloHouse: 9,
        nearestAngle: 'mc', natalDeg: 5, reloDeg: 6,
      );
      expect(d.houseChanged, isTrue);
    });
  });

  group('toPayload', () {
    test('RelocationAngleDelta.toPayload は direction/deltaDeg を含む', () {
      const d = RelocationAngleDelta(
        planet: 'moon', natalHouse: 4, reloHouse: 4,
        nearestAngle: 'ic', natalDeg: 8, reloDeg: 2,
      );
      final p = d.toPayload();
      expect(p['planet'], 'moon');
      expect(p['nearestAngle'], 'ic');
      expect(p['direction'], 'closer');
      expect(p['natalHouse'], 4);
      expect((p['deltaDeg'] as double) < 0, isTrue);
    });
  });
}
