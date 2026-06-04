import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../i18n/strings.g.dart';
import 'map_vp_panel.dart' show VPSlot;
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
  final bool searchOpen;
  final bool displayMenuOpen;
  final bool viewpointMenuOpen;
  final VoidCallback onSearchTap;
  final VoidCallback onDisplayMenuTap;
  final VoidCallback onViewpointMenuTap;

  const MapSideButtons({
    super.key,
    required this.searchOpen,
    required this.displayMenuOpen,
    required this.viewpointMenuOpen,
    required this.onSearchTap,
    required this.onDisplayMenuTap,
    required this.onViewpointMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    // 検索中は左サイド全ボタン非表示 (検索バー + VP チップ列が
    // 横幅をフル使うため)。検索が閉じれば 3 ボタン復帰。
    if (searchOpen) return const SizedBox.shrink();
    // 2026-05-31: 親指が届きやすいよう、左サイド 3 ボタンを画面上部から
    // 下端チップバーの直上 (左寄せ) に移動。右下の現在地/相談ボタン列と
    // 左右対称になる。bottom 基準で配置するため SizedBox.expand で全画面を占有
    // (空白領域は Stack が hit-test しないので地図ジェスチャは透過する)。
    // 縦の視覚順は従来どおり 🔍 (上) / ☰ (中) / 📍 (下)。
    return SizedBox.expand(
      child: Stack(children: [
        // 🔍 検索 (上)
        Positioned(
          bottom: 176,
          left: 16,
          child: MapBtn(
            onTap: onSearchTap,
            child: const Icon(Icons.search, size: 18, color: Color(0x99C9A84C)),
          ),
        ),
        // ☰ 表示メニュートリガー (3本ライン = レイヤー切替の象徴)
        Positioned(
          bottom: 128,
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
          bottom: 80,
          left: 16,
          child: MapBtn(
            active: viewpointMenuOpen,
            onTap: onViewpointMenuTap,
            child: const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFFC9A84C)),
          ),
        ),
      ]),
    );
  }
}

/// 検索バー（_searchOpen 時に最上部に表示）
///
/// Stateful にしている理由:
/// `autofocus: true` だけだとアプリ起動後 Map 画面で最初に 🔍 を押した時に
/// フォーカスが取れない (FocusScope が初回 mount で温まっておらず autofocus が
/// 取り損なう Flutter の既知挙動)。
/// initState の postFrame で明示 requestFocus することで初回も確実に取る。
class SearchBarOverlay extends StatefulWidget {
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
  State<SearchBarOverlay> createState() => _SearchBarOverlayState();
}

class _SearchBarOverlayState extends State<SearchBarOverlay> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

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
          controller: widget.controller,
          focusNode: _focusNode,
          autofocus: true,
          style: const TextStyle(color: Color(0xFFE8E0D0), fontSize: 13),
          decoration: InputDecoration(
            hintText: t.mapOverlay.searchHint,
            hintStyle: const TextStyle(color: Color(0xFF555555)),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          ),
          onSubmitted: widget.onSubmitted,
        )),
        GestureDetector(
          onTap: widget.onClose,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.close, size: 16, color: Color(0xFF888888)),
          ),
        ),
      ]),
    );
  }
}

/// 検索バー直上に出す VIEWPOINT (16方位基準) 選択チップ列。
///
/// チップ：[📍 現在地] [🏠 自宅 (or HOMEスロット)] [⭐ VP1...]
/// タップで VP のみ更新 (地図は動かさない)。検索バー自体は閉じない。
///
/// active 表示: VP の lat/lng が現在の _center と近いチップを金色で強調。
/// 現在地チップは active 検出不可なので常に非選択スタイル (押下トリガー扱い)。
class SearchVpChipRow extends StatelessWidget {
  final List<VPSlot> vpSlots;
  /// 現在の VP 位置 (_center)。チップの active 強調判定に使う。
  final LatLng currentVp;
  final VoidCallback onCurrentLocationTap;
  final void Function(LatLng) onSlotTap;
  final VoidCallback onHelpTap;

  const SearchVpChipRow({
    super.key,
    required this.vpSlots,
    required this.currentVp,
    required this.onCurrentLocationTap,
    required this.onSlotTap,
    required this.onHelpTap,
  });

  bool _isActive(VPSlot s) {
    // 1e-4 ≈ 11m。VP Pin ドラッグの微小差は許容して active 判定。
    return (s.lat - currentVp.latitude).abs() < 1e-4 &&
        (s.lng - currentVp.longitude).abs() < 1e-4;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xE60F0F1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x26FFFFFF)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          // 「VP:」ラベル + ? アイコン (使い方説明 popup を開く)
          Text(
            t.mapOverlay.vpLabel,
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF888888),
                letterSpacing: 0.5),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onHelpTap,
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.help_outline,
                  size: 13, color: Color(0xFF888888)),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _Chip(
                  label: t.mapOverlay.currentLocation,
                  active: false,
                  onTap: onCurrentLocationTap,
                ),
                for (final s in vpSlots) ...[
                  const SizedBox(width: 6),
                  _Chip(
                    label: '${s.icon} ${s.isHome ? t.mapOverlay.home : s.name}',
                    active: _isActive(s),
                    onTap: () => onSlotTap(LatLng(s.lat, s.lng)),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active
              ? const Color(0x33C9A84C)
              : const Color(0x14C9A84C),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: active
                  ? const Color(0xFFC9A84C)
                  : const Color(0x33C9A84C),
              width: active ? 1.2 : 1),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: active
                ? const Color(0xFFE8E0D0)
                : const Color(0xFFB8B0A0),
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
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

