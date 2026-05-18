// Unit + widget test: 称号 (クラス) 変遷 — C4 (柱 3)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:solara/screens/sanctuary/title_history_screen.dart';
import 'package:solara/utils/solara_storage.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SolaraStorage title history', () {
    test('addTitleHistoryEntry → loadTitleHistory が新しい順で返す', () async {
      await SolaraStorage.addTitleHistoryEntry(
        axis: 'power',
        court: 'page',
        classEN: 'Knight',
        classJP: '騎士',
        lightJP: '守ると決めたら迷わない',
        shadowJP: '守りたいものが多すぎる',
      );
      await Future.delayed(const Duration(milliseconds: 5));
      await SolaraStorage.addTitleHistoryEntry(
        axis: 'mind',
        court: 'queen',
        classEN: 'Chancellor',
        classJP: '司書',
        lightJP: '誰が何を求めているか分かる',
        shadowJP: '気配り上手すぎる',
      );

      final list = await SolaraStorage.loadTitleHistory();
      expect(list.length, 2);
      // 新しい順 → Chancellor が先頭
      expect(list.first['classEN'], 'Chancellor');
      expect(list.last['classEN'], 'Knight');
    });

    test('連続同一 axis+court は skip される', () async {
      await SolaraStorage.addTitleHistoryEntry(
        axis: 'power',
        court: 'page',
        classEN: 'Knight',
        classJP: '騎士',
        lightJP: '',
        shadowJP: '',
      );
      await SolaraStorage.addTitleHistoryEntry(
        axis: 'power',
        court: 'page',
        classEN: 'Knight',
        classJP: '騎士',
        lightJP: '',
        shadowJP: '',
      );
      final list = await SolaraStorage.loadTitleHistory();
      expect(list.length, 1);
    });

    test('違う axis+court なら追加される', () async {
      await SolaraStorage.addTitleHistoryEntry(
        axis: 'power',
        court: 'page',
        classEN: 'Knight',
        classJP: '騎士',
        lightJP: '',
        shadowJP: '',
      );
      await SolaraStorage.addTitleHistoryEntry(
        axis: 'mind',
        court: 'page',
        classEN: 'Sage',
        classJP: '求道者',
        lightJP: '',
        shadowJP: '',
      );
      final list = await SolaraStorage.loadTitleHistory();
      expect(list.length, 2);
    });

    test('titleHistoryMax を超えると古いものから削除', () async {
      for (var i = 0; i < SolaraStorage.titleHistoryMax + 5; i++) {
        // axis を毎回変えて skip を回避
        await SolaraStorage.addTitleHistoryEntry(
          axis: i % 2 == 0 ? 'power' : 'mind',
          court: 'page',
          classEN: 'C$i',
          classJP: 'クラス $i',
          lightJP: '',
          shadowJP: '',
        );
      }
      final list = await SolaraStorage.loadTitleHistory();
      expect(list.length, SolaraStorage.titleHistoryMax);
    });

    test('updateTitleHistoryNote で note が書き込める / 200 字 cap が効く / 未一致は no-op', () async {
      await SolaraStorage.addTitleHistoryEntry(
        axis: 'power',
        court: 'page',
        classEN: 'Knight',
        classJP: '騎士',
        lightJP: '',
        shadowJP: '',
      );
      final savedAt = (await SolaraStorage.loadTitleHistory()).first['savedAt'] as String;

      // 書き込み
      await SolaraStorage.updateTitleHistoryNote(savedAt, '心境を残す');
      var list = await SolaraStorage.loadTitleHistory();
      expect(list.first['note'], '心境を残す');

      // 200 字 cap (grapheme cluster 数)
      final long = '心' * 250;
      await SolaraStorage.updateTitleHistoryNote(savedAt, long);
      list = await SolaraStorage.loadTitleHistory();
      expect((list.first['note'] as String).characters.length, 200);

      // 未一致 savedAt は no-op (既存 note が壊れない)
      await SolaraStorage.updateTitleHistoryNote('not-exist-iso', 'x');
      list = await SolaraStorage.loadTitleHistory();
      expect((list.first['note'] as String).characters.length, 200);
    });

    test('clearTitleHistory で空になる', () async {
      await SolaraStorage.addTitleHistoryEntry(
        axis: 'power',
        court: 'page',
        classEN: 'Knight',
        classJP: '騎士',
        lightJP: '',
        shadowJP: '',
      );
      expect((await SolaraStorage.loadTitleHistory()).length, 1);

      await SolaraStorage.clearTitleHistory();
      expect((await SolaraStorage.loadTitleHistory()).length, 0);
    });
  });

  group('TitleHistoryScreen widget', () {
    testWidgets('empty state を表示', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: TitleHistoryScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('まだ称号の変遷はありません'), findsOneWidget);
    });

    testWidgets('履歴 2 件 → NOW バッジ + 2 件分のクラス名表示', (tester) async {
      Future<List<Map<String, dynamic>>> stub() async => [
            {
              'savedAt': '2026-05-01T10:00:00Z',
              'axis': 'power',
              'court': 'page',
              'classEN': 'Knight',
              'classJP': '騎士',
              'lightJP': '守る',
              'shadowJP': '忙しい',
            },
            {
              'savedAt': '2026-04-01T10:00:00Z',
              'axis': 'mind',
              'court': 'page',
              'classEN': 'Sage',
              'classJP': '求道者',
              'lightJP': 'なぜ？',
              'shadowJP': '夜更かし',
            },
          ];
      await tester.pumpWidget(
        MaterialApp(home: TitleHistoryScreen(loadOverride: stub)),
      );
      await tester.pumpAndSettle();

      expect(find.text('NOW'), findsOneWidget);
      expect(find.text('騎士'), findsOneWidget);
      expect(find.text('求道者'), findsOneWidget);
      expect(find.text('Knight'), findsOneWidget);
      expect(find.text('Sage'), findsOneWidget);
    });
  });
}
