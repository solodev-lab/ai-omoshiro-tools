import '../models/lunar_intention.dart';
import 'moon_phase.dart';
import 'solara_storage.dart';

/// 月のサイクル儀式の 3 イベント種別。
enum MoonEventKind { newMoon, fullMoon, catasterism }

/// 月イベント (新月・満月・刻星化) が「今この瞬間に保留中か」を判定する単一の真実。
///
/// galaxy_screen の overlay 発火条件 (_checkMoonOverlay) と、main.dart の
/// NavBar バッジ / Map 案内バナーの表示条件をここに一本化する。両者が乖離すると
/// 「バッジは点くのに overlay が出ない」等の不整合が起きるため、必ずこの関数を経由させる。
class MoonEventStatus {
  const MoonEventStatus._();

  /// 今 ([now] = 端末ローカル時刻) 保留中で、かつ「まだ今日 overlay を表示していない」
  /// 月イベントがあればその種別を返す。無ければ null。
  ///
  /// 判定条件は _checkMoonOverlay と完全一致:
  /// - 新月日 かつ 当サイクルの意図未設定
  /// - 満月日 かつ 意図あり・中間チェック未記録
  /// - 刻星化日 (次の新月前日) 以降 かつ 意図あり・刻星化未記録
  /// いずれも wasLocalOverlayShownToday で「今日まだ出していない」ことを要求する
  /// (= バッジ/案内を「タップすれば overlay が出る」状態に正確に一致させる)。
  static Future<MoonEventKind?> pendingToday(DateTime now) async {
    final (cycleStart, cycleEnd) = MoonPhase.getCurrentCycleBounds(now);
    final csLocal = cycleStart.toLocal();
    final cycleId =
        '${csLocal.year}-${csLocal.month.toString().padLeft(2, '0')}';
    final LunarIntention? intention =
        await SolaraStorage.loadIntention(cycleId);

    final today = DateTime(now.year, now.month, now.day);
    final dayBeforeNewMoon = cycleEnd.subtract(const Duration(days: 1));
    final crystDay = DateTime(
        dayBeforeNewMoon.year, dayBeforeNewMoon.month, dayBeforeNewMoon.day);

    if (MoonPhase.isNewMoon(now)) {
      if (intention == null &&
          !await SolaraStorage.wasLocalOverlayShownToday('new_moon')) {
        return MoonEventKind.newMoon;
      }
    } else if (MoonPhase.isFullMoon(now)) {
      if (intention != null &&
          intention.midpoint == null &&
          !await SolaraStorage.wasLocalOverlayShownToday('full_moon')) {
        return MoonEventKind.fullMoon;
      }
    } else if (today == crystDay || today.isAfter(crystDay)) {
      if (intention != null &&
          intention.catasterism == null &&
          !await SolaraStorage.wasLocalOverlayShownToday('catasterism')) {
        return MoonEventKind.catasterism;
      }
    }
    return null;
  }
}
