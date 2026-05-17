// astro_lines.dart の Pro 機能契約 (120 本アスペクト線) 回帰テスト。
//
// 公開時の Pro 訴求 = 「アスペクトライン 120 本」(Free=40)。
// _aspectPasses や _planetKeys が変更されると静かに本数が崩れるため、
// 「10 惑星 × 4 アングル × 3 パス = 120」「conjunction だけで 40」を
// テストでロックする。
//
// 関連: docs/pro_candidates.md §7.2 / project_solara_pro_candidates.md
// 関連: lib/screens/map_screen.dart `_proDescForAstroKey('aspectLines')`

import 'package:flutter_test/flutter_test.dart';
import 'package:solara/utils/astro_lines.dart';

const _planets = {
  'sun', 'moon', 'mercury', 'venus', 'mars',
  'jupiter', 'saturn', 'uranus', 'neptune', 'pluto',
};

// natal フレームと同じ shape の任意の黄経マップ。値は実天体に近い順序で
// バラけさせる (declination が両極端な配置で horizon line がゼロ点になる
// ような天体も含む)。テストは「AstroLine オブジェクトの本数」を検証する
// ので、segments が空でもオブジェクト 1 本としてカウントされること自体を
// 確認する (UI 側で segments.isEmpty を空表示するのは描画責務)。
const _samplePlanets = <String, double>{
  'sun': 0.0,
  'moon': 30.0,
  'mercury': 60.0,
  'venus': 95.0,
  'mars': 130.0,
  'jupiter': 175.0,
  'saturn': 210.0,
  'uranus': 245.0,
  'neptune': 290.0,
  'pluto': 325.0,
};

void main() {
  group('buildAstroLinesAt — Pro 機能本数契約', () {
    test('natal フレームで丁度 120 本生成される (10 惑星 × 4 アングル × 3 パス)', () {
      final lines = buildAstroLinesAt(
        planets: _samplePlanets,
        gmstHours: 6.0,
        frame: AstroFrame.natal,
      );
      expect(lines.length, 120,
          reason: 'Pro 訴求「アスペクトライン 120 本」の契約。'
              '_aspectPasses (3) × _planetKeys (10) × angles (4) = 120');
    });

    test('conjunction だけで 40 本 (Free 表示分)', () {
      final lines = buildAstroLinesAt(
        planets: _samplePlanets,
        gmstHours: 6.0,
        frame: AstroFrame.natal,
      );
      final conjs = lines.where((l) => l.aspect == 'conjunction').toList();
      expect(conjs.length, 40,
          reason: 'Free ユーザーが見える本数 = 10 惑星 × 4 アングル = 40');
      expect(conjs.every((l) => !l.isAspectLine), isTrue);
    });

    test('aspect 線は 80 本 (square 40 + trine 20 + sextile 20)', () {
      final lines = buildAstroLinesAt(
        planets: _samplePlanets,
        gmstHours: 6.0,
        frame: AstroFrame.natal,
      );
      final byAspect = <String, int>{};
      for (final l in lines) {
        byAspect[l.aspect] = (byAspect[l.aspect] ?? 0) + 1;
      }
      // 設計: _aspectPasses
      //   pass1 shift  0° → conjunction × 4 angles
      //   pass2 shift +90° → square × 4 angles
      //   pass3 shift +120° → trine (mc/asc) + sextile (ic/dsc)
      // 各 pass × 10 惑星 = pass1:40 / pass2:40 / pass3 内訳:trine 20 + sextile 20
      expect(byAspect['conjunction'], 40);
      expect(byAspect['square'], 40);
      expect(byAspect['trine'], 20);
      expect(byAspect['sextile'], 20);
      // 全て足して 120
      expect(byAspect.values.reduce((a, b) => a + b), 120);
    });

    test('全 10 惑星 × 4 アングルが過不足なく現れる', () {
      final lines = buildAstroLinesAt(
        planets: _samplePlanets,
        gmstHours: 6.0,
        frame: AstroFrame.natal,
      );
      final planets = <String>{};
      final angles = <String>{};
      final perPair = <String, int>{};
      for (final l in lines) {
        planets.add(l.planet);
        angles.add(l.angle);
        final k = '${l.planet}_${l.angle}';
        perPair[k] = (perPair[k] ?? 0) + 1;
      }
      expect(planets, _planets);
      expect(angles, {'mc', 'ic', 'asc', 'dsc'});
      // 1 惑星 × 1 アングルに対し 3 パス (= conjunction/square/trine|sextile)
      for (final k in perPair.keys) {
        expect(perPair[k], 3, reason: '$k は 3 パス分必要 (conj/square/120°)');
      }
      expect(perPair.length, 40);
    });

    test('zenith / nadir は conjunction MC / IC のみ非 null', () {
      final lines = buildAstroLinesAt(
        planets: _samplePlanets,
        gmstHours: 6.0,
        frame: AstroFrame.natal,
      );
      final zenithLines = lines.where((l) => l.zenith != null).toList();
      final nadirLines = lines.where((l) => l.nadir != null).toList();
      // 10 惑星 × 1 アングル × 1 パス = 10
      expect(zenithLines.length, 10);
      expect(nadirLines.length, 10);
      expect(
          zenithLines
              .every((l) => l.angle == 'mc' && l.aspect == 'conjunction'),
          isTrue);
      expect(
          nadirLines
              .every((l) => l.angle == 'ic' && l.aspect == 'conjunction'),
          isTrue);
    });

    test('isAspectLine は conjunction 以外で true', () {
      final lines = buildAstroLinesAt(
        planets: _samplePlanets,
        gmstHours: 6.0,
        frame: AstroFrame.natal,
      );
      final aspectLines = lines.where((l) => l.isAspectLine).toList();
      expect(aspectLines.length, 80,
          reason: 'Pro 限定で開放される「追加 80 本」');
      // Free→Pro で +80 になる
      expect(lines.length - aspectLines.length, 40);
    });

    test('全 4 フレームで同じ 120 本契約が保たれる (CCG Tier A #5)', () {
      for (final frame in AstroFrame.values) {
        final lines = buildAstroLinesAt(
          planets: _samplePlanets,
          gmstHours: 3.0,
          frame: frame,
        );
        expect(lines.length, 120,
            reason: '$frame フレームでも 120 本 (4 フレーム × 120 = 480 本上限)');
        expect(lines.every((l) => l.frame == frame), isTrue);
      }
    });

    test('惑星マップに欠損があるとその惑星分 (12 本) だけ減る', () {
      // pluto を抜く → 9 惑星 × 4 × 3 = 108
      final partial = Map<String, double>.from(_samplePlanets)..remove('pluto');
      final lines = buildAstroLinesAt(
        planets: partial,
        gmstHours: 6.0,
        frame: AstroFrame.natal,
      );
      expect(lines.length, 108);
      expect(lines.any((l) => l.planet == 'pluto'), isFalse);
    });
  });

  group('buildAstroLines (natal 既存 API)', () {
    test('baseline 経路でも 120 本生成される (後方互換)', () {
      // baseline は実天測値風: MC=120°, lng=139.7 (Tokyo 風) で GMST 逆算
      final lines = buildAstroLines(
        natal: _samplePlanets,
        baselineMc: 120.0,
        baselineLng: 139.7,
      );
      expect(lines.length, 120);
      expect(lines.every((l) => l.frame == AstroFrame.natal), isTrue);
    });
  });

  group('AstroLine.key — UI 参照キーの後方互換', () {
    test('conjunction は従来形式 frame_planet_angle', () {
      final lines = buildAstroLinesAt(
        planets: _samplePlanets,
        gmstHours: 6.0,
        frame: AstroFrame.natal,
      );
      final conj = lines.firstWhere(
          (l) => l.aspect == 'conjunction' && l.planet == 'sun' && l.angle == 'mc');
      expect(conj.key, 'natal_sun_mc');
    });

    test('aspect は frame_planet_angle_aspect 形式', () {
      final lines = buildAstroLinesAt(
        planets: _samplePlanets,
        gmstHours: 6.0,
        frame: AstroFrame.natal,
      );
      final sq = lines.firstWhere(
          (l) => l.aspect == 'square' && l.planet == 'sun' && l.angle == 'mc');
      expect(sq.key, 'natal_sun_mc_square');
      // 同じ planet/angle の別 aspect は別キー
      final tr = lines.firstWhere(
          (l) => l.aspect == 'trine' && l.planet == 'sun' && l.angle == 'mc');
      expect(tr.key, 'natal_sun_mc_trine');
      expect(sq.key, isNot(tr.key));
    });
  });
}
