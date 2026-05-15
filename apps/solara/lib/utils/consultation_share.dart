// Consultation Share — Phase 2-5 シェアエクスポート
//
// 設計: apps/solara/docs/pro_candidates.md §7.2 Stage 4
//
// 2 つのエクスポート手段:
//   1. テキストコピー: ConsultationReading を plain text に整形 → Clipboard
//   2. 画像共有: 結果画面の RepaintBoundary を PNG 化 → SharePlus
//
// Phase 2-5 (v1): UI のみ、Pro ゲート未配線。設計上は Pro 機能。
// Phase 2-6 (課金基盤後): Pro チェックで非 Pro はゲートする。

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'consultation_api.dart';

const _themeLabel = <String, String>{
  'love': '恋愛・関係',
  'money': '豊かさ・お金',
  'work': '仕事・キャリア',
  'communication': '対話・学び',
  'healing': '癒し・休息',
  'newStart': '変化・新たな出発',
};

const _modeLabel = <String, String>{
  'migration': '移住',
  'travel': '旅行',
  'daily': 'おでかけ',
};

const _scopeLabel = <String, String>{
  'specific': '具体地点',
  'region': '範囲指定',
  'world': '世界全体',
  'bearings': '方角別',
};

/// 相談結果を plain text に整形する。
/// 履歴詳細でも live 相談直後でも同じフォーマットで吐き出す。
String formatConsultationAsText({
  required String theme,
  required String mode,
  required String scope,
  required String freeText,
  required ConsultationReading reading,
}) {
  final themeJp = _themeLabel[theme] ?? theme;
  final modeJp = _modeLabel[mode] ?? mode;
  final scopeJp = _scopeLabel[scope] ?? scope;

  final buf = StringBuffer();
  buf.writeln('— Solara · Stella による相談 —');
  buf.writeln();
  buf.writeln('テーマ: $themeJp / モード: $modeJp / 範囲: $scopeJp');
  if (freeText.trim().isNotEmpty) {
    buf.writeln('自由記述: ${freeText.trim()}');
  }
  buf.writeln();

  if (reading.intro.isNotEmpty) {
    buf.writeln(reading.intro);
    buf.writeln();
  }

  for (var i = 0; i < reading.candidates.length; i++) {
    final c = reading.candidates[i];
    buf.writeln('━━ ${c.name} ━━');
    if (c.energyLabels.isNotEmpty) {
      for (final label in c.energyLabels) {
        buf.writeln('  · $label');
      }
      buf.writeln();
    }
    if (c.narrative.isNotEmpty) {
      buf.writeln(c.narrative);
      buf.writeln();
    }
  }

  if (reading.outro.isNotEmpty) {
    buf.writeln('— — —');
    buf.writeln(reading.outro);
  }

  buf.writeln();
  buf.writeln('#Solara #Stella');
  return buf.toString().trimRight();
}

/// 出力画像幅 (px)。SNS 共有用 1080px (class_share_card と統一)。
const double _shareImageTargetWidthPx = 1080.0;

/// RepaintBoundary を PNG 化して OS 標準シェアシートで共有する。
///
/// [boundaryKey] = ConsultationResultScreen で結果領域をラップする GlobalKey。
/// [shareText] = シェア時に併記するキャプション (推奨: formatConsultationAsText の冒頭抜粋)。
///
/// 失敗時は例外を投げる。呼出側で try/catch + SnackBar 表示する。
Future<void> shareConsultationImage({
  required GlobalKey boundaryKey,
  required String shareText,
  String filename = 'solara_stella_consultation.png',
}) async {
  final boundary = boundaryKey.currentContext?.findRenderObject()
      as RenderRepaintBoundary?;
  if (boundary == null) {
    throw StateError('capture target not found');
  }

  // 端末の Display Size 設定や画面解像度に依存せず 1080px 幅で出力。
  // (class_share_card.dart と同じ動的 pixelRatio 計算ロジック)
  final boundaryWidth = boundary.size.width;
  final pixelRatio = boundaryWidth > 0
      ? _shareImageTargetWidthPx / boundaryWidth
      : 3.0;
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw StateError('byteData null');
  }

  final tmpDir = await getTemporaryDirectory();
  final file = await File('${tmpDir.path}/$filename').create();
  await file.writeAsBytes(byteData.buffer.asUint8List());

  await SharePlus.instance.share(ShareParams(
    files: [XFile(file.path)],
    text: shareText,
  ));
}

/// シェア用のキャプション短縮版 (画像と一緒に添える text)。
/// テキスト全体は長すぎるので intro + 最初の候補名 + outro 冒頭だけ。
String formatConsultationCaption({
  required String theme,
  required ConsultationReading reading,
}) {
  final themeJp = _themeLabel[theme] ?? theme;
  final buf = StringBuffer();
  buf.writeln('Solara で「$themeJp」について Stella に相談しました。');
  if (reading.candidates.isNotEmpty) {
    final names = reading.candidates.map((c) => c.name).join(' / ');
    buf.writeln('候補: $names');
  }
  buf.writeln();
  buf.writeln('#Solara #Stella');
  return buf.toString().trimRight();
}
