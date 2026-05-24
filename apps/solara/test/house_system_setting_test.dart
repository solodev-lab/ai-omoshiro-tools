// Unit test: ハウスシステム設定の読み書き + 同期キャッシュ (2026-05-24)
//
// Sanctuary「ハウスシステム」設定が保存され、fetchChart (async) と
// calcHousesRelocate (sync, popup build) の両方から参照できることを担保する。
// load/save が同期キャッシュ (currentHouseSystem) を更新する点を検証。

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:solara/utils/solara_storage.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('未設定はデフォルト placidus', () async {
    expect(await SolaraStorage.loadHouseSystem(), 'placidus');
    expect(SolaraStorage.currentHouseSystem, 'placidus');
  });

  test('save で値と同期キャッシュが更新される', () async {
    await SolaraStorage.saveHouseSystem('whole_sign');
    expect(SolaraStorage.currentHouseSystem, 'whole_sign');
    expect(await SolaraStorage.loadHouseSystem(), 'whole_sign');
  });

  test('load が prefs から同期キャッシュを prime する', () async {
    SharedPreferences.setMockInitialValues({'solara_house_system': 'whole_sign'});
    expect(await SolaraStorage.loadHouseSystem(), 'whole_sign');
    expect(SolaraStorage.currentHouseSystem, 'whole_sign');
  });
}
