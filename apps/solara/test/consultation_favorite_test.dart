// Unit test: 相談履歴のお気に入り (favorite) — モデル + ストレージ (2026-05-24)

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:solara/utils/consultation_record.dart';
import 'package:solara/utils/solara_storage.dart';

ConsultationRecord _rec(String id, {bool favorite = false}) => ConsultationRecord(
      id: id,
      savedAt: DateTime.utc(2026, 1, 1).add(Duration(minutes: int.parse(id))),
      theme: 'love',
      mode: 'travel',
      scopeKind: 'world',
      candidates: const [],
      evidences: const [],
      favorite: favorite,
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('model', () {
    test('favorite は既定 false', () {
      expect(_rec('1').favorite, isFalse);
    });

    test('copyWith(favorite) は元を変えず複製を返す', () {
      final a = _rec('1');
      final b = a.copyWith(favorite: true);
      expect(a.favorite, isFalse);
      expect(b.favorite, isTrue);
      expect(b.id, a.id);
    });

    test('toJson/fromJson で favorite が往復する', () {
      final r = _rec('1', favorite: true);
      final back = ConsultationRecord.fromJson(r.toJson());
      expect(back.favorite, isTrue);
      // false のときは JSON に含めない (省サイズ) が読み戻しは false。
      final r2 = _rec('2');
      expect(r2.toJson().containsKey('favorite'), isFalse);
      expect(ConsultationRecord.fromJson(r2.toJson()).favorite, isFalse);
    });
  });

  group('storage', () {
    test('setConsultationFavorite で永続化される', () async {
      await SolaraStorage.addConsultationRecord(_rec('1'));
      await SolaraStorage.setConsultationFavorite('1', true);
      var list = await SolaraStorage.loadConsultationHistory();
      expect(list.single.favorite, isTrue);

      await SolaraStorage.setConsultationFavorite('1', false);
      list = await SolaraStorage.loadConsultationHistory();
      expect(list.single.favorite, isFalse);
    });

    test('未知 id は no-op', () async {
      await SolaraStorage.addConsultationRecord(_rec('1'));
      await SolaraStorage.setConsultationFavorite('999', true);
      final list = await SolaraStorage.loadConsultationHistory();
      expect(list.single.favorite, isFalse);
    });
  });
}
