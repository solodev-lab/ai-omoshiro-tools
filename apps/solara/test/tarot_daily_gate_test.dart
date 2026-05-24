// Unit test: 無料タロット (全体運) の「1日1回」単調ガード (2026-05-24)
//
// 「1日の開始時刻」基準の論理日でゲートしつつ、引いた後にリセット時刻を
// 後ろにずらして論理日を過去へ戻し再ドローする不正を、記録ベースの単調
// ガード (markFreeTarotDrawn / hasDrawnFreeTarotToday) で防ぐことを検証する。

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:solara/utils/solara_storage.dart';

const _key = 'solara_last_free_tarot_day';

String _fmt(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('初期状態は未ドロー', () async {
    expect(await SolaraStorage.hasDrawnFreeTarotToday(), isFalse);
  });

  test('mark すると当日は引き済みになる', () async {
    await SolaraStorage.markFreeTarotDrawn();
    expect(await SolaraStorage.hasDrawnFreeTarotToday(), isTrue);
  });

  test('記録が未来日 (= リセット時刻を後ろにずらして論理日を過去へ戻した状況) でもブロック',
      () async {
    final today = DateTime.parse(await SolaraStorage.logicalTodayKey());
    final future = _fmt(today.add(const Duration(days: 1)));
    SharedPreferences.setMockInitialValues({_key: future});
    // last(未来) >= today → まだ同じ論理日扱い → 引けない
    expect(await SolaraStorage.hasDrawnFreeTarotToday(), isTrue);
  });

  test('記録が過去日なら新しい論理日として引ける', () async {
    final today = DateTime.parse(await SolaraStorage.logicalTodayKey());
    final past = _fmt(today.subtract(const Duration(days: 1)));
    SharedPreferences.setMockInitialValues({_key: past});
    expect(await SolaraStorage.hasDrawnFreeTarotToday(), isFalse);
  });

  test('markFreeTarotDrawn は単調 — 既存の未来日を過去日に巻き戻さない', () async {
    final today = DateTime.parse(await SolaraStorage.logicalTodayKey());
    final future = _fmt(today.add(const Duration(days: 1)));
    SharedPreferences.setMockInitialValues({_key: future});
    await SolaraStorage.markFreeTarotDrawn(); // today < future なので上書きしない
    expect(await SolaraStorage.loadLastFreeTarotDay(), future);
  });

  test('clearFreeTarotDay で再ドロー可能に戻る (テスト/デバッグ用)', () async {
    await SolaraStorage.markFreeTarotDrawn();
    expect(await SolaraStorage.hasDrawnFreeTarotToday(), isTrue);
    await SolaraStorage.clearFreeTarotDay();
    expect(await SolaraStorage.hasDrawnFreeTarotToday(), isFalse);
  });
}
