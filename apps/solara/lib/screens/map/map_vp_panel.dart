import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
class SlotManager {
  final String storageKey;
  final int maxSlots;
  final List<String> defaultNames;

  SlotManager({required this.storageKey, this.maxSlots = 5, this.defaultNames = const ['職場','お気に入り','スポット','場所']});

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
      if (slots.length > maxSlots) slots.length = maxSlots;
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
      return '保存は${maxSlots - homeCount}件までです。\n不要な地点を削除してから追加してください。';
    }
    final userIdx = slots.length - homeCount;
    final defaultName = userIdx < defaultNames.length ? defaultNames[userIdx] : 'スポット';

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
