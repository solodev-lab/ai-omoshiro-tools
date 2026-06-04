import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../i18n/strings.g.dart';
import '../../utils/pro_status.dart';
import '../../utils/reverse_geocode.dart';
import '../../utils/solara_storage.dart';

/// VPSlot / SlotManager 定義ファイル。
///
/// 2026-05-09: 旧 VPPanel ウィジェットは削除 (下部 MapMenuChips → MapLocationsSheet に
/// 機能を移行)。データクラスのみここに残し、locations_screen.dart や
/// map_search.dart など複数の参照元から従来通り import 可能。

/// HTML: VP_ICONS — デフォルトアイコン (SlotManager.saveCurrentLocation で使用)。
const _defaultIcons = ['🏠', '🏢', '⭐', '📍'];

/// スロット1件分のデータ
class VPSlot {
  String name;
  double lat;
  double lng;
  String icon;
  bool isHome;

  VPSlot({required this.name, required this.lat, required this.lng, this.icon = '📍', this.isHome = false});

  Map<String, dynamic> toJson() => {'name': name, 'lat': lat, 'lng': lng, 'icon': icon, 'isHome': isHome};
  factory VPSlot.fromJson(Map<String, dynamic> j) => VPSlot(
    name: j['name'] ?? '', lat: (j['lat'] ?? 0).toDouble(),
    lng: (j['lng'] ?? 0).toDouble(), icon: j['icon'] ?? '📍',
    isHome: j['isHome'] ?? false,
  );
}

/// HTML: SlotManager — SharedPreferencesでスロットを永続化
///
/// Phase 2-8: 上限 `maxSlots` を Free 5 / Pro 10 で振り分ける。
/// `ProStatus.instance.isPro` を runtime で参照するため、Pro 切替時に
/// 即座に新しい上限が効く (SharedPreferences に既に保存された 6 件目以降は
/// load 時にそのまま読み込まれるが、新規 add は新しい上限で gate される)。
class SlotManager {
  static const int kMaxSlotsFree = 5;
  static const int kMaxSlotsPro = 10;

  final String storageKey;
  final List<String> defaultNames;

  /// 現在の上限。`ProStatus` を runtime 参照するため、Pro 切替時に動的に変化する。
  int get maxSlots =>
      ProStatus.instance.isPro ? kMaxSlotsPro : kMaxSlotsFree;

  SlotManager({required this.storageKey, this.defaultNames = const []});

  Future<List<VPSlot>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null) return [];
    final list = json.decode(raw) as List;
    return list.map((e) => VPSlot.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> save(List<VPSlot> slots) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, json.encode(slots.map((s) => s.toJson()).toList()));
  }

  /// HTML: syncHome — プロフィールのホーム地点を先頭スロットに同期
  Future<void> syncHome(SolaraProfile? profile) async {
    if (profile == null || profile.homeName.isEmpty) return;
    final slots = await load();
    final h = VPSlot(name: profile.homeName, lat: profile.homeLat, lng: profile.homeLng, icon: '🏠', isHome: true);
    if (slots.isNotEmpty && slots[0].isHome) {
      slots[0] = h;
    } else {
      slots.insert(0, h);
      // Phase 2-8: 旧仕様は超過分を truncate していたが、Pro→Free 降格時に
      // ユーザー保存地点を失うのを避けるため、超過は許容する (柱3 原則
      // 「自分の記録を永久に失わない」)。新規追加は saveCurrentLocation 側で
      // 上限到達時に gate される。
    }
    await save(slots);
  }

  /// HTML: saveCurrentLocation — reverse geocodingで地名取得して保存
  ///
  /// 2026-05-07: 地名取得部分を [reverseGeocode] (utils/reverse_geocode.dart)
  /// に抽出。Horo Birth Panel の試算用 BirthData 入力でも同じヘルパーを共用する。
  Future<String?> saveCurrentLocation(LatLng center) async {
    final slots = await load();
    final homeCount = (slots.isNotEmpty && slots[0].isHome) ? 1 : 0;
    if (slots.length >= maxSlots) {
      // Phase 2-8: Free 上限到達時は Pro アップグレード案内も含める。
      if (!ProStatus.instance.isPro) {
        return t.mapVp.saveLimitFree(
            free: kMaxSlotsFree - homeCount, pro: kMaxSlotsPro - homeCount);
      }
      return t.mapVp.saveLimitFull(max: maxSlots - homeCount);
    }
    final userIdx = slots.length - homeCount;
    final names = defaultNames.isNotEmpty ? defaultNames : t.mapVp.slotDefaults;
    final defaultName =
        userIdx < names.length ? names[userIdx] : t.mapVp.slotFallback;

    final geocoded =
        await reverseGeocode(center.latitude, center.longitude, maxLength: 8);
    final name = geocoded ?? defaultName;

    slots.add(VPSlot(name: name, lat: center.latitude, lng: center.longitude, icon: _defaultIcons[userIdx.clamp(0, _defaultIcons.length - 1)]));
    await save(slots);
    return null; // success
  }

  Future<void> moveSlot(int i, int dir) async {
    final s = await load();
    final t = i + dir;
    if (t < 0 || t >= s.length) return;
    if ((i == 0 && s[0].isHome) || (t == 0 && s[0].isHome)) return;
    final tmp = s[i]; s[i] = s[t]; s[t] = tmp;
    await save(s);
  }

  Future<void> renameSlot(int i, String newName) async {
    final s = await load();
    if (i >= s.length || s[i].isHome) return;
    s[i].name = newName.substring(0, newName.length.clamp(0, 12));
    await save(s);
  }

  Future<void> deleteSlot(int i) async {
    final s = await load();
    if (i >= s.length || s[i].isHome) return;
    s.removeAt(i);
    await save(s);
  }

  Future<void> changeIcon(int i, String icon) async {
    final s = await load();
    if (i >= s.length || s[i].isHome) return;
    s[i].icon = icon;
    await save(s);
  }
}
