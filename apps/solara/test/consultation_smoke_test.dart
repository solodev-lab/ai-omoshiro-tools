// Smoke test for consultation_engine.dart — 4 候補ケース + リフレッシュ除外。
//
// Synthetic な AstroLine 3 本 (Venus MC / Mars ASC / Moon DSC) を組み立て、
// theme='love' (venus, mars, moon) で各候補生成関数が非自明な結果を返すこと
// (空でない・距離が単調・除外が効く) を検証する。

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:solara/utils/astro_lines.dart' as al;
import 'package:solara/utils/consultation_engine.dart' as ce;
import 'package:solara/utils/world_cities.dart';

List<al.AstroLine> _buildSyntheticLoveLines() {
  // Venus MC (経度 139.7E、Tokyo 直上を通る縦線)
  final venusMc = al.AstroLine(
    planet: 'venus',
    angle: 'mc',
    aspect: 'conjunction',
    frame: al.AstroFrame.natal,
    segments: [
      [
        for (double lat = -60; lat <= 60; lat += 5) LatLng(lat, 139.7),
      ],
    ],
  );
  // Mars ASC (経度 2.3E、Paris 直上を通る縦線)
  final marsAsc = al.AstroLine(
    planet: 'mars',
    angle: 'asc',
    aspect: 'conjunction',
    frame: al.AstroFrame.natal,
    segments: [
      [
        for (double lat = -60; lat <= 60; lat += 5) LatLng(lat, 2.3),
      ],
    ],
  );
  // Moon DSC (経度 -157.8、Honolulu)
  final moonDsc = al.AstroLine(
    planet: 'moon',
    angle: 'dsc',
    aspect: 'conjunction',
    frame: al.AstroFrame.natal,
    segments: [
      [
        for (double lat = -60; lat <= 60; lat += 5) LatLng(lat, -157.8),
      ],
    ],
  );
  return [venusMc, marsAsc, moonDsc];
}

void main() {
  test('filterThemeLines: love が venus/mars/moon の conjunction 全部を拾う', () {
    final all = _buildSyntheticLoveLines();
    final lines = ce.filterThemeLines(all, 'love');
    expect(lines.length, 3);
    expect(lines.map((l) => l.planet).toSet(), {'venus', 'mars', 'moon'});
  });

  test('filterThemeLines: 未知テーマは空、newStart は uranus/sun/jupiter', () {
    final all = _buildSyntheticLoveLines();
    expect(ce.filterThemeLines(all, 'unknown'), isEmpty);
    expect(ce.themePlanets('newStart'), {'uranus', 'sun', 'jupiter'});
  });

  test('candidateForSpecific: Kyoto の love 候補が Venus MC を最寄りに拾う', () {
    final lines = ce.filterThemeLines(
      _buildSyntheticLoveLines(),
      'love',
    );
    final spec = ce.candidateForSpecific(
      target: LatLng(35.0116, 135.7681), // Kyoto
      nameJP: '京都',
      nameEN: 'Kyoto',
      country: 'JP',
      region: '京都府',
      themeLines: lines,
    );
    expect(spec.nearLines, isNotEmpty);
    // Kyoto (135.7E) からは Venus MC (139.7E) が最寄り
    expect(spec.nearLines.first.planet, 'venus');
    // 距離は約 360km (経度 4 度 × cos(35°))
    expect(
      spec.nearLines.first.distanceKm,
      inInclusiveRange(300, 450),
    );
  });

  test('candidatesForRegion: JP 縛りで 3 候補返る', () {
    final lines = ce.filterThemeLines(
      _buildSyntheticLoveLines(),
      'love',
    );
    final region = ce.candidatesForRegion(
      themeLines: lines,
      countries: {'JP'},
    );
    expect(region.length, 3);
    expect(region.every((c) => c.country == 'JP'), isTrue);
    // Venus MC が 139.7E なので、139.7 近傍の都市 (東京/横浜/千葉) が上位
    expect(
      region.first.nearLines.first.planet,
      'venus',
    );
  });

  test('candidatesForWorld: 3 候補返る、名前ユニーク', () {
    final lines = ce.filterThemeLines(
      _buildSyntheticLoveLines(),
      'love',
    );
    final world = ce.candidatesForWorld(themeLines: lines);
    expect(world.length, 3);
    expect(world.map((c) => c.nameJP).toSet().length, 3);
  });

  test('candidatesForDaily: Shibuya から 8 方位中 上位 3 方位を返す', () {
    final lines = ce.filterThemeLines(
      _buildSyntheticLoveLines(),
      'love',
    );
    final daily = ce.candidatesForDaily(
      currentLocation: LatLng(35.6580, 139.7016),
      themeLines: lines,
      radiusKm: 30,
    );
    expect(daily.length, 3);
    expect(daily.every((c) => c.bearing != null), isTrue);
    expect(daily.map((c) => c.bearing).toSet().length, 3);
  });

  test('refresh: excludeNames で前回候補を除外できる', () {
    final lines = ce.filterThemeLines(
      _buildSyntheticLoveLines(),
      'love',
    );
    final first = ce.candidatesForWorld(themeLines: lines);
    final excluded = [first.first.nameJP];
    final second = ce.candidatesForWorld(
      themeLines: lines,
      excludeNames: excluded,
    );
    expect(
      second.map((c) => c.nameJP).contains(first.first.nameJP),
      isFalse,
      reason: '除外した名前が再出してはならない',
    );
  });

  test('worldCities: 300 件以上ロード済', () {
    expect(worldCities.length, greaterThanOrEqualTo(300));
    final jp = worldCities.where((c) => c.country == 'JP').length;
    final us = worldCities.where((c) => c.country == 'US').length;
    expect(jp, greaterThanOrEqualTo(40));
    expect(us, greaterThanOrEqualTo(50));
  });

  test('CandidateLocation.toJson: Stella に渡す形に変換できる', () {
    final lines = ce.filterThemeLines(
      _buildSyntheticLoveLines(),
      'love',
    );
    final c = ce.candidateForSpecific(
      target: LatLng(35.0, 135.0),
      nameJP: 'テスト',
      nameEN: 'Test',
      country: 'JP',
      region: 'テスト地方',
      themeLines: lines,
    );
    final json = c.toJson();
    expect(json['name'], 'テスト');
    expect(json['nearLines'], isList);
    final near = (json['nearLines'] as List).first as Map;
    expect(near.containsKey('planet'), isTrue);
    expect(near.containsKey('distanceKm'), isTrue);
  });
}
