import 'package:flutter/material.dart';

/// 「ラベル + 値」情報行 (horo 系 panel 共通)。
///
/// horo_birth_panel.dart の `_bsInfoRow` と horo_transit_panel.dart の
/// `_bsInfoRow` が完全同一実装で重複していたため集約 (audit T1 #3 検出、2026-05-04)。
///
/// Positional 引数 (label, value) で旧 private method と互換。
class HoroInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const HoroInfoRow(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
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
