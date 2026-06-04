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

import '../i18n/strings.g.dart';
import 'consultation_record.dart';
import 'consultation_v2_api.dart';
import 'solara_i18n.dart';

// 英語化Phase 2: theme/mode/scope ラベルと共有テンプレートは slang (consultShare) で
// ロケール連動。theme は入力UIと同一語のため consultInput.theme.* を再利用、
// mode/scope は共有テキスト固有の表記 (「おでかけ・イベント」「現住所から半径」) を
// consultShare に持たせる (2026-06-04: 旧「自宅から半径」を正典「現住所」へ統一)。

/// slang キーを引き、未登録なら生 id にフォールバックする (未知の theme/mode/scope
/// でもキー文字列でなく id を出す)。tr() は未登録時にキー自身を返すため等値で判定。
String _label(String fullKey, String rawId) {
  final v = tr(fullKey);
  return v == fullKey ? rawId : v;
}

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
  final themeLabel = _label('consultInput.theme.$theme', theme);
  final modeLabel = _label('consultShare.mode.$mode', mode);
  final scopeLabel = _label('consultShare.scope.$scopeKind', scopeKind);

  final buf = StringBuffer();
  buf.writeln(t.consultShare.header);
  buf.writeln();
  buf.writeln(t.consultShare
      .metaLine(theme: themeLabel, mode: modeLabel, scope: scopeLabel));
  if (withWhom.trim().isNotEmpty) {
    buf.writeln(t.consultShare.withWhom(v: withWhom.trim()));
  }
  if (wish.trim().isNotEmpty) buf.writeln(t.consultShare.wish(v: wish.trim()));
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
  final themeLabel = _label('consultInput.theme.$theme', theme);
  final buf = StringBuffer();
  buf.writeln(t.consultShare.captionIntro(theme: themeLabel));
  if (candidates.isNotEmpty) {
    final names =
        candidates.map((c) => ConsultationRecord.displayName(c)).join(' / ');
    buf.writeln(t.consultShare.candidates(names: names));
  }
  buf.writeln();
  buf.writeln('#Solara #Stella');
  return buf.toString().trimRight();
}
