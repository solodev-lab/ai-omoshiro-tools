import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'map_widgets.dart';

/// VP Pin (ドラッグ可能な中央の金色ピン) の Marker を生成する。
/// pan 量を現在の可視範囲から緯経度差分に変換する計算を内包。
Marker buildVpPinMarker({
  required MapController mapCtrl,
  required LatLng center,
  required Size screenSize,
  required ValueChanged<LatLng> onCenterChange,
  required VoidCallback onDragEnd,
}) {
  return Marker(
    point: center,
    width: 20,
    height: 20,
    child: GestureDetector(
      onPanUpdate: (d) {
        final bounds = mapCtrl.camera.visibleBounds;
        final latRange = bounds.north - bounds.south;
        final lngRange = bounds.east - bounds.west;
        onCenterChange(LatLng(
          center.latitude - d.delta.dy * latRange / screenSize.height,
          center.longitude + d.delta.dx * lngRange / screenSize.width,
        ));
      },
      onPanEnd: (_) => onDragEnd(),
      child: const VpPinVisual(),
    ),
  );
}

/// Map 画面の小さなオーバーレイ群。map_screen.dart から分離。

/// 左サイド縦並び 3 ボタン: 🔍 検索 / ☰ 表示 / 📍 地点 (2026-05-09 第二弾)。
///
/// 設計の経緯:
/// - 旧 7 サイドボタン (検索/DISPLAY/ASTRO/VP/LOC/予報/ACG) → 集約再設計を経て
/// - 検索は文字入力フローでサイドに残置
/// - 表示・地点は「右に展開する」メニューを開くトリガーボタン
///   (表示メニュー = MapDisplayMenu、地点メニュー = MapViewpointMenu)
/// - 下部チップ (Daily Transit / 運勢方位 / LOCATIONS / 予報) は別 widget
///
/// 表示と地点メニューは相互排他。両方同時に開けない (親 state で管理)。
class MapSideButtons extends StatelessWidget {
  final double topPad;
  final bool searchOpen;
  final bool displayMenuOpen;
  final bool viewpointMenuOpen;
  final VoidCallback onSearchTap;
  final VoidCallback onDisplayMenuTap;
  final VoidCallback onViewpointMenuTap;

  const MapSideButtons({
    super.key,
    required this.topPad,
    required this.searchOpen,
    required this.displayMenuOpen,
    required this.viewpointMenuOpen,
    required this.onSearchTap,
    required this.onDisplayMenuTap,
    required this.onViewpointMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      if (!searchOpen)
        Positioned(
          top: topPad + 152,
          left: 16,
          child: MapBtn(
            onTap: onSearchTap,
            child: const Icon(Icons.search, size: 18, color: Color(0x99C9A84C)),
          ),
        ),
      // ☰ 表示メニュートリガー (3本ライン = レイヤー切替の象徴)
      Positioned(
        top: topPad + 200,
        left: 16,
        child: MapBtn(
          active: displayMenuOpen,
          onTap: onDisplayMenuTap,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 18, height: 2, decoration: BoxDecoration(color: const Color(0xFFE8E0D0), borderRadius: BorderRadius.circular(1))),
            const SizedBox(height: 3),
            Container(width: 18, height: 2, decoration: BoxDecoration(color: const Color(0xFFC9A84C), borderRadius: BorderRadius.circular(1))),
            const SizedBox(height: 3),
            Container(width: 18, height: 2, decoration: BoxDecoration(color: const Color(0xFF00D4FF), borderRadius: BorderRadius.circular(1))),
          ]),
        ),
      ),
      // 📍 地点メニュートリガー (VIEWPOINT 保存スロット選択)
      Positioned(
        top: topPad + 248,
        left: 16,
        child: MapBtn(
          active: viewpointMenuOpen,
          onTap: onViewpointMenuTap,
          child: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFFC9A84C)),
        ),
      ),
    ]);
  }
}

/// 検索バー（_searchOpen 時に最上部に表示）
class SearchBarOverlay extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClose;

  const SearchBarOverlay({
    super.key,
    required this.controller,
    required this.onSubmitted,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xE60F0F1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x26FFFFFF)),
      ),
      child: Row(children: [
        const Padding(
          padding: EdgeInsets.only(left: 12, right: 4),
          child: Icon(Icons.search, size: 16, color: Color(0xFF888888)),
        ),
        Expanded(child: TextField(
          controller: controller, autofocus: true,
          style: const TextStyle(color: Color(0xFFE8E0D0), fontSize: 13),
          decoration: const InputDecoration(
            hintText: '場所を検索...',
            hintStyle: TextStyle(color: Color(0xFF555555)),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          ),
          onSubmitted: onSubmitted,
        )),
        GestureDetector(
          onTap: onClose,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.close, size: 16, color: Color(0xFF888888)),
          ),
        ),
      ]),
    );
  }
}

/// 選択日バッジ（地図左上に常時表示）
/// - ラベルタップ → 日付ピッカー（[onTap]）
/// - ✕ アイコン → 今日リセット（[onReset] が null の場合は ✕ 非表示）
class SelectedDateBadge extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback? onReset;
  const SelectedDateBadge({
    super.key,
    required this.label,
    required this.onTap,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    // 外側 GestureDetector で Container 全体（padding 含む）を onTap 領域にする。
    // ✕ アイコンだけ内側 GestureDetector で先取りして onReset を呼ぶ。
    // こうしないと padding 領域のタップが取りこぼされ「反応しない」状態になる。
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xE60F0F1E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x66C9A84C)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('📅', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(fontSize: 18, color: Color(0xFFC9A84C), letterSpacing: 0.5, fontWeight: FontWeight.w600)),
          if (onReset != null) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onReset,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('✕', style: TextStyle(fontSize: 16, color: Color(0xFF888888))),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

/// 右上のステータスバッジ（計算中・検索中）
class StatusBadge extends StatelessWidget {
  final String label;
  const StatusBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xE60F0F1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x33C9A84C)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(
          width: 10, height: 10,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFFC9A84C)),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFFC9A84C))),
      ]),
    );
  }
}

/// VP Pin (ドラッグ可能な中央の金色ピン) — 見た目のみ。
/// ドラッグ処理は呼び出し側で GestureDetector で包む。
class VpPinVisual extends StatelessWidget {
  const VpPinVisual({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20, height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.2, -0.3),
          colors: [Color(0xFFFFE8A0), Color(0xFFC9A84C)],
        ),
        border: Border.all(color: const Color(0xFFE8E0D0), width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x99C9A84C), blurRadius: 12),
          BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
    );
  }
}

/// 休息オーバーレイ（🌙 + テキスト）
class RestOverlay extends StatelessWidget {
  final String text;
  final VoidCallback onDismiss;
  const RestOverlay({super.key, required this.text, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Colors.transparent,
        child: Center(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          constraints: const BoxConstraints(maxWidth: 260),
          decoration: BoxDecoration(
            color: const Color(0xD90F0F1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x4DC9A84C)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🌙', style: TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFFC9A84C), height: 1.7)),
          ]),
        )),
      ),
    );
  }
}

/// Solara テーマ適用の DatePicker を開く。選択されたら DateTime を返す（正午固定はしない）。
/// 範囲: 今日−10年 〜 今日+20年（過去回顧 + 中長期予測をカバー）。
/// initial が範囲外なら自動クランプして assertion を回避。
Future<DateTime?> showSolaraDatePicker(BuildContext context, {DateTime? initial}) {
  final now = DateTime.now();
  final firstDate = DateTime(now.year - 10, now.month, now.day);
  final lastDate = DateTime(now.year + 20, now.month, now.day);
  var safeInitial = (initial ?? now).toLocal();
  if (safeInitial.isBefore(firstDate)) safeInitial = firstDate;
  if (safeInitial.isAfter(lastDate)) safeInitial = lastDate;
  return showDatePicker(
    context: context,
    initialDate: safeInitial,
    firstDate: firstDate,
    lastDate: lastDate,
    builder: (ctx, child) => Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFC9A84C),
          onPrimary: Color(0xFF0F0F1E),
          surface: Color(0xFF0F0F1E),
          onSurface: Color(0xFFE8E0D0),
        ),
        dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF0F0F1E)),
      ),
      child: child!,
    ),
  );
}

