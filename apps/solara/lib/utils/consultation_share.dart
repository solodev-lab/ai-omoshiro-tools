// Consultation Share — シェアエクスポート (V2: 全要素統合)
//
// 設計: project_solara_consultation_full_integration.md
//
// 2 つのエクスポート手段:
//   1. テキストコピー: 蓄積した候補群を plain text に整形 → Clipboard
//   2. 画像共有: 結果画面の RepaintBoundary を PNG 化 → SharePlus
//
// シェアは Pro 限定 (結果画面側で Pro ゲート)。

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'consultation_record.dart';
import 'consultation_v2_api.dart';

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
  'point': '具体地点',
  'bearing': '方角別',
  'radius': '自宅から半径',
  'region': '範囲指定',
  'country': '自国内',
  'world': '世界全体',
};

/// 相談結果を plain text に整形する。
String formatConsultationAsText({
  required String theme,
  required String mode,
  required String scopeKind,
  String withWhom = '',
  String wish = '',
  String innerSeason = '',
  String intro = '',
  String outro = '',
  required List<ConsultationV2Candidate> candidates,
  required List<ConsultationEvidence> evidences,
}) {
  final themeJp = _themeLabel[theme] ?? theme;
  final modeJp = _modeLabel[mode] ?? mode;
  final scopeJp = _scopeLabel[scopeKind] ?? scopeKind;

  final buf = StringBuffer();
  buf.writeln('— Solara · Stella による相談 —');
  buf.writeln();
  buf.writeln('テーマ: $themeJp / 場面: $modeJp / 範囲: $scopeJp');
  if (withWhom.trim().isNotEmpty) buf.writeln('だれと: ${withWhom.trim()}');
  if (wish.trim().isNotEmpty) buf.writeln('願い: ${wish.trim()}');
  buf.writeln();

  if (innerSeason.isNotEmpty) {
    buf.writeln(innerSeason);
    buf.writeln();
  }
  if (intro.isNotEmpty) {
    buf.writeln(intro);
    buf.writeln();
  }

  for (var i = 0; i < candidates.length; i++) {
    final c = candidates[i];
    buf.writeln('━━ ${ConsultationRecord.displayName(c)} ━━');
    if (c.characterHeadline.isNotEmpty) buf.writeln('◆ ${c.characterHeadline}');
    for (final label in c.energyLabels) {
      buf.writeln('  · $label');
    }
    if (c.narrative.isNotEmpty) {
      buf.writeln();
      buf.writeln(c.narrative);
    }
    buf.writeln();
  }

  if (outro.isNotEmpty) {
    buf.writeln('— — —');
    buf.writeln(outro);
  }

  buf.writeln();
  buf.writeln('#Solara #Stella');
  return buf.toString().trimRight();
}

/// 出力画像幅 (px)。SNS 共有用 1080px (class_share_card と統一)。
const double _shareImageTargetWidthPx = 1080.0;

/// RepaintBoundary を PNG 化して OS 標準シェアシートで共有する。
Future<void> shareConsultationImage({
  required GlobalKey boundaryKey,
  required String shareText,
  String filename = 'solara_stella_consultation.png',
}) async {
  final boundary =
      boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) {
    throw StateError('capture target not found');
  }

  final boundaryWidth = boundary.size.width;
  final pixelRatio =
      boundaryWidth > 0 ? _shareImageTargetWidthPx / boundaryWidth : 3.0;
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
String formatConsultationCaption({
  required String theme,
  required List<ConsultationV2Candidate> candidates,
}) {
  final themeJp = _themeLabel[theme] ?? theme;
  final buf = StringBuffer();
  buf.writeln('Solara で「$themeJp」について Stella に相談しました。');
  if (candidates.isNotEmpty) {
    final names =
        candidates.map((c) => ConsultationRecord.displayName(c)).join(' / ');
    buf.writeln('候補: $names');
  }
  buf.writeln();
  buf.writeln('#Solara #Stella');
  return buf.toString().trimRight();
}
