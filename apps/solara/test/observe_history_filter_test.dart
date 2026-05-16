// Unit test: ObserveHistoryFilter — C3 (柱 3)
//
// DailyReading の filter ロジックのみを検証する。
// TarotData は asset 依存なので、test では `flutter_test`
// + TarotData の初期化を済ませる必要がある。

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:solara/models/daily_reading.dart';
import 'package:solara/screens/observe/observe_history_filter.dart';
import 'package:solara/utils/tarot_data.dart';

DailyReading _reading({
  required String date,
  required int cardId,
  required bool isMajor,
  bool reversed = false,
  String reading = '',
  String synchronicity = '',
}) {
  return DailyReading(
    date: date,
    cardId: cardId,
    isMajor: isMajor,
    moonPhase: 0,
    reversed: reversed,
    reading: reading,
    synchronicity: synchronicity,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    // TarotData は AssetBundle 経由で 78 枚読み込む。test では rootBundle を使う。
    await TarotData.initialize();
  });

  group('ObserveHistoryFilter.apply', () {
    // cardId=0 = The Fool (Major, air)
    // cardId=22 = first Minor Wands (fire)
    final m = _reading(date: '2026-05-01', cardId: 0, isMajor: true,
        reading: '炎のエネルギー');
    final f = _reading(date: '2026-05-02', cardId: 22, isMajor: false,
        reading: '大地の癒し');
    final mRev = _reading(date: '2026-05-03', cardId: 0, isMajor: true,
        reversed: true);

    test('default は全件をそのまま返す', () {
      const ff = ObserveHistoryFilter();
      expect(ff.apply([m, f, mRev]).length, 3);
    });

    test('onlyMajor=true で Major のみ', () {
      const ff = ObserveHistoryFilter(onlyMajor: true);
      final r = ff.apply([m, f, mRev]);
      expect(r.length, 2);
      expect(r.every((x) => x.cardId == 0), isTrue);
    });

    test('onlyReversed=true で逆位置のみ', () {
      const ff = ObserveHistoryFilter(onlyReversed: true);
      final r = ff.apply([m, f, mRev]);
      expect(r.length, 1);
      expect(r.first.reversed, isTrue);
    });

    test('query は reading/synchronicity に対する大小文字無視部分一致', () {
      const ff = ObserveHistoryFilter(query: '大地');
      final r = ff.apply([m, f, mRev]);
      expect(r.length, 1);
      expect(r.first.cardId, 22);
    });

    test('isActive: default false / 何か入れば true', () {
      expect(const ObserveHistoryFilter().isActive, isFalse);
      expect(const ObserveHistoryFilter(query: 'x').isActive, isTrue);
      expect(const ObserveHistoryFilter(onlyMajor: true).isActive, isTrue);
      expect(
          const ObserveHistoryFilter(elements: {'fire'}).isActive, isTrue);
      expect(
          const ObserveHistoryFilter(onlyReversed: false).isActive, isTrue);
    });

    test('copyWith で onlyMajor を null に戻せる (sentinel)', () {
      const base = ObserveHistoryFilter(onlyMajor: true);
      final cleared = base.copyWith(onlyMajor: null);
      expect(cleared.onlyMajor, isNull);
      expect(cleared.isActive, isFalse);
    });

    test('elements 集合フィルタ', () {
      // The Fool = air, Wands Ace = fire
      const ff = ObserveHistoryFilter(elements: {'fire'});
      final r = ff.apply([m, f]);
      expect(r.length, 1);
      expect(r.first.cardId, 22);
    });

    test('質問欄 (question) も検索対象に含まれる', () {
      final withQ = _reading(
        date: '2026-05-04',
        cardId: 0,
        isMajor: true,
        reading: 'なし',
      )..question = '転職について悩んでいます';

      const ff = ObserveHistoryFilter(query: '転職');
      final r = ff.apply([m, f, withQ]);
      expect(r.length, 1);
      expect(r.first.question, contains('転職'));
    });

    test('question が null でも他のフィールドは検索できる', () {
      final r = _reading(
        date: '2026-05-05',
        cardId: 0,
        isMajor: true,
        reading: 'シンクロ無し',
      );
      expect(r.question, isNull);
      const ff = ObserveHistoryFilter(query: 'シンクロ');
      expect(ff.apply([r]).length, 1);
    });
  });

  group('DailyReading question persistence', () {
    test('toJson/fromJson で question を保持', () {
      final r = DailyReading(
        date: '2026-05-10',
        cardId: 5,
        isMajor: true,
        moonPhase: 10.0,
        question: 'Pro 質問テスト',
      );
      final json = r.toJson();
      expect(json['question'], 'Pro 質問テスト');

      final restored = DailyReading.fromJson(json);
      expect(restored.question, 'Pro 質問テスト');
    });

    test('question が null/空なら toJson に含めない (旧データ互換)', () {
      final r = DailyReading(
        date: '2026-05-11',
        cardId: 5,
        isMajor: true,
        moonPhase: 10.0,
      );
      final json = r.toJson();
      expect(json.containsKey('question'), isFalse);

      final restored = DailyReading.fromJson(json);
      expect(restored.question, isNull);
    });
  });
}
