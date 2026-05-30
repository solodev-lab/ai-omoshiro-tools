// Unit test: ConsultRestore — 押下ルート画面復元レジストリ (Android プロセス死対策)。
//
// 登録スタック方式の核となる挙動を固定する:
//   - 最前面 (最後に登録) のスナップショットが優先される (入力→結果の push 連鎖)
//   - 最前面が null を返したら下のエントリにフォールバック (結果が fetch 中など)
//   - unregister で下のエントリが復活 (結果を pop して入力へ戻る)

import 'package:flutter_test/flutter_test.dart';
import 'package:solara/utils/consult_restore.dart';

void main() {
  group('ConsultRestore', () {
    test('空なら captureTop は null', () {
      final reg = ConsultRestore.instance;
      expect(reg.captureTop(), isNull);
    });

    test('1 件登録 → そのスナップショットを返す', () {
      final reg = ConsultRestore.instance;
      final token = reg.register(() => {'type': 'a'});
      expect(reg.captureTop(), {'type': 'a'});
      reg.unregister(token);
      expect(reg.captureTop(), isNull);
    });

    test('複数登録 → 最後に登録した最前面が優先される', () {
      final reg = ConsultRestore.instance;
      final t1 = reg.register(() => {'type': 'input'});
      final t2 = reg.register(() => {'type': 'result'});
      expect(reg.captureTop(), {'type': 'result'});
      reg.unregister(t2);
      // 結果を pop した想定 → 入力が復活する
      expect(reg.captureTop(), {'type': 'input'});
      reg.unregister(t1);
      expect(reg.captureTop(), isNull);
    });

    test('最前面が null を返したら下のエントリにフォールバック', () {
      final reg = ConsultRestore.instance;
      final t1 = reg.register(() => {'type': 'input'});
      // 結果が fetch 中 (未保存) で null を返すケース
      final t2 = reg.register(() => null);
      expect(reg.captureTop(), {'type': 'input'});
      reg.unregister(t1);
      reg.unregister(t2);
    });

    test('全エントリが null なら captureTop も null', () {
      final reg = ConsultRestore.instance;
      final t1 = reg.register(() => null);
      final t2 = reg.register(() => null);
      expect(reg.captureTop(), isNull);
      reg.unregister(t1);
      reg.unregister(t2);
    });
  });
}
