import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/solara_storage.dart';
import 'horo_antique_icons.dart';
import 'horo_panel_shared.dart';

// ══════════════════════════════════════════════════
// Birth Section (BS tab)
// HTML: #bsBirth — profile info display
// ══════════════════════════════════════════════════

class HoroBirthPanel extends StatelessWidget {
  final SolaraProfile profile;
  /// 編集されているか (base と異なるか)
  final bool isEdited;
  /// 編集開始 (呼び出し側でエディタpush → 結果を_applyWorkingProfileに渡す)
  final VoidCallback? onEdit;
  /// base に戻す
  final VoidCallback? onReset;
  const HoroBirthPanel({
    super.key, required this.profile,
    this.isEdited = false, this.onEdit, this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final p = profile;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header row with edit notice (when edited)
      Row(children: [
        horoAntiqueHeader(AntiqueIcon.birth, 'BIRTH DATA'),
        const SizedBox(width: 8),
        if (isEdited) Expanded(child: Text(
          '※ Horo画面から離れるとBIRTH DATAは初期化されます',
          style: TextStyle(
            fontSize: 10,
            color: const Color(0xFFFF9E6B).withAlpha(220),
            fontStyle: FontStyle.italic,
          ),
          overflow: TextOverflow.visible,
          softWrap: true,
        )),
      ]),
      const SizedBox(height: 10),
      _bsInfoRow('氏名 NAME', p.name.isEmpty ? '未設定' : p.name),
      _bsInfoRow('生年月日 DATE', p.birthDate),
      _bsInfoRow('出生時刻 TIME', p.birthTimeUnknown ? '不明' : p.birthTime),
      _bsInfoRow('出生地 BIRTHPLACE', p.birthPlace.isEmpty ? '未設定' : p.birthPlace),
      if (p.birthLat != 0) ...[
        _bsInfoRow('緯度/経度', '${p.birthLat.toStringAsFixed(4)} / ${p.birthLng.toStringAsFixed(4)}'),
      ],
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: GestureDetector(
          onTap: onEdit,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFFF6BD60), Color(0xFFE8A840)],
              ),
            ),
            child: const Center(child: Text('編集してホロスコープを試算', style: TextStyle(
              color: Color(0xFF0A0A14), fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1))),
          ),
        )),
        if (isEdited) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onReset,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x66F6BD60)),
              ),
              child: Text('リセット', style: GoogleFonts.cinzel(
                fontSize: 12, color: const Color(0xFFF6BD60),
                letterSpacing: 1.5, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ]),
    ]);
  }

  Widget _bsInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF888888), letterSpacing: 1)),
        const SizedBox(height: 3),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0x0DFFFFFF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x1AFFFFFF)),
          ),
          child: Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFFE8E0D0))),
        ),
      ]),
    );
  }
}
