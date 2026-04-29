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

/// 左サイドの縦並びボタン群（🔍 ≡ 📍 📅 🗺 🔮）
/// topPad+76 から 48px 間隔で配置。
class MapSideButtons extends StatelessWidget {
  final double topPad;
  final bool searchOpen;
  final bool layerPanelOpen;
  final bool astroPanelOpen; // 2026-04-29: ☰ DISPLAY と ✨ ASTRO の2ボタン分割
  final bool vpPanelOpen;
  final VoidCallback onSearchTap;
  final VoidCallback onLayerTap;
  final VoidCallback onAstroPanelTap;
  final VoidCallback onVpTap;
  final VoidCallback onLocationsTap;
  final VoidCallback onForecastTap;
  final VoidCallback onAstroCartoTap;

  const MapSideButtons({
    super.key,
    required this.topPad,
    required this.searchOpen,
    required this.layerPanelOpen,
    required this.astroPanelOpen,
    required this.vpPanelOpen,
    required this.onSearchTap,
    required this.onLayerTap,
    required this.onAstroPanelTap,
    required this.onVpTap,
    required this.onLocationsTap,
    required this.onForecastTap,
    required this.onAstroCartoTap,
  });

  @override
  Widget build(BuildContext context) {
    // 📅 日付ボタンは削除（左上の SelectedDateBadge をタップでピッカー起動するため重複）。
    // 日付バッジ（top+44, 高さ約38px）と被らないよう全ボタンを 16px 下げて 48px 等間隔に並べる。
    // 2026-04-29: TimeSlider が top+44 で展開時 ~144 まで伸びるため、
    // 全サイドボタンを +60 シフト (旧: 92→152, 140→200, ...)。
    return Stack(children: [
      if (!searchOpen) Positioned(
        top: topPad + 152, left: 16,
        child: MapBtn(
          onTap: onSearchTap,
          child: const Icon(Icons.search, size: 18, color: Color(0x99C9A84C)),
        ),
      ),
      // ☰ DISPLAY パネル: 16方位/コンパス/MAPSTYLE
      Positioned(
        top: topPad + 200, left: 16,
        child: MapBtn(
          active: layerPanelOpen,
          onTap: onLayerTap,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 18, height: 2, decoration: BoxDecoration(color: const Color(0xFFE8E0D0), borderRadius: BorderRadius.circular(1))),
            const SizedBox(height: 3),
            Container(width: 18, height: 2, decoration: BoxDecoration(color: const Color(0xFFC9A84C), borderRadius: BorderRadius.circular(1))),
            const SizedBox(height: 3),
            Container(width: 18, height: 2, decoration: BoxDecoration(color: const Color(0xFF00D4FF), borderRadius: BorderRadius.circular(1))),
          ]),
        ),
      ),
      // ✨ ASTRO パネル: 惑星ライン/引越し/CCG 4 frame/CHART/PLANET GROUP/FORTUNE
      Positioned(
        top: topPad + 248, left: 16,
        child: MapBtn(
          active: astroPanelOpen,
          onTap: onAstroPanelTap,
          child: const Icon(Icons.auto_awesome, size: 18, color: Color(0xFFC9A84C)),
        ),
      ),
      Positioned(
        top: topPad + 296, left: 16,
        child: MapBtn(
          active: vpPanelOpen,
          onTap: onVpTap,
          child: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFFC9A84C)),
        ),
      ),
      Positioned(
        top: topPad + 344, left: 16,
        child: MapBtn(
          onTap: onLocationsTap,
          child: const Icon(Icons.map_outlined, size: 18, color: Color(0xFFC9A84C)),
        ),
      ),
      Positioned(
        top: topPad + 392, left: 16,
        child: MapBtn(
          onTap: onForecastTap,
          child: const Icon(Icons.auto_graph, size: 18, color: Color(0xFFC9A84C)),
        ),
      ),
      // Astro*Carto*Graphy モード起動ボタン (世界規模ライン+天頂点表示)
      Positioned(
        top: topPad + 440, left: 16,
        child: MapBtn(
          onTap: onAstroCartoTap,
          child: const Icon(Icons.public, size: 18, color: Color(0xFFC9A84C)),
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
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFFC9A84C))),
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

/// Pull tab（Fortune Sheet を呼ぶ「▲ 運勢方位」タブ）
class FortunePullTab extends StatelessWidget {
  final VoidCallback onTap;
  const FortunePullTab({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 2),
        decoration: const BoxDecoration(
          color: Color(0xCC0A0A19),
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          border: Border(
            top: BorderSide(color: Color(0x33C9A84C)),
            left: BorderSide(color: Color(0x33C9A84C)),
            right: BorderSide(color: Color(0x33C9A84C)),
          ),
        ),
        child: const Text('▲ 運勢方位',
          style: TextStyle(fontSize: 10, color: Color(0xFF888888), letterSpacing: 0.5)),
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

