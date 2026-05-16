// Galaxy Cycle エクスポート — C5 (Pro 機能、柱 3)
//
// 設計: apps/solara/docs/pro_candidates.md §7.3 + §3 C5
//
// 役割:
//   - 完了した [GalaxyCycle] を Markdown / 画像で外部書き出し
//   - LunarIntention (内包する CatasterismResult) があれば併記
//   - 画像は RepaintBoundary → PNG 1080px (consultation_share と同パターン)
//
// 柱 3 原則: 「記録は Free でも全件閲覧」「Pro が売るのは記録を使う道具」。
// エクスポートは「記録を使う道具」側なので Pro ゲート対象。
// (ゲート自体は呼出側で showProUnlockDialog 経由で済ませる、本ファイルは pure utility。)

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/galaxy_cycle.dart';
import '../models/lunar_intention.dart';

/// 1 サイクルを Markdown に整形する。Stella や Solara 内で完結する書式で、
/// 外部 SNS に貼っても崩れないシンプル構成。
String formatGalaxyCycleAsMarkdown({
  required GalaxyCycle cycle,
  LunarIntention? intention,
}) {
  final buf = StringBuffer();
  buf.writeln('# ✦ ${cycle.nameJP.isNotEmpty ? cycle.nameJP : cycle.nameEN}');
  if (cycle.nameJP.isNotEmpty && cycle.nameEN.isNotEmpty) {
    buf.writeln('_${cycle.nameEN}_');
  }
  buf.writeln();
  buf.writeln('- 期間: ${_isoDate(cycle.cycleStart)} 〜 ${_isoDate(cycle.cycleEnd)}');
  buf.writeln('- レアリティ: ${cycle.rarityLabel} (${cycle.rarity}/5)');
  final anchors = cycle.dots.where((d) => d.isMajor).length;
  buf.writeln('- 構成: ${cycle.dots.length} stars / $anchors anchors');
  buf.writeln();

  if (intention != null) {
    buf.writeln('## 新月の意図');
    if (intention.chosenTextJP.isNotEmpty) {
      buf.writeln(intention.chosenTextJP);
    } else if (intention.chosenText.isNotEmpty) {
      buf.writeln(intention.chosenText);
    }
    buf.writeln();
    if (intention.midpoint != null) {
      final r = intention.midpoint!.rating;
      const ratingLabel = {1: '苦戦中', 2: '取り組み中', 3: '感じられる'};
      buf.writeln('### 満月の中間チェック');
      buf.writeln(
          '- ${_isoDate(intention.midpoint!.checkedAt)}: ${ratingLabel[r] ?? "rating $r"}');
      buf.writeln();
    }
    if (intention.catasterism != null) {
      buf.writeln('### 刻星化セルフアセスメント');
      final released = intention.catasterism!.released;
      buf.writeln(
          '- ${_isoDate(intention.catasterism!.assessedAt)}: ${released ? "手放せた" : "まだ途中"}');
      buf.writeln();
    }
  }

  buf.writeln('---');
  buf.writeln('Solara · Galaxy Archive');
  buf.writeln('#Solara');
  return buf.toString().trimRight();
}

/// シェア用の短いキャプション (画像と一緒に添える text)。
String formatGalaxyCycleCaption(GalaxyCycle cycle) {
  final name = cycle.nameJP.isNotEmpty ? cycle.nameJP : cycle.nameEN;
  final buf = StringBuffer();
  buf.writeln('Solara で「$name」のサイクルを記録しました。');
  buf.writeln('${cycle.rarityLabel} · ${cycle.dots.length} stars');
  buf.writeln();
  buf.writeln('#Solara');
  return buf.toString().trimRight();
}

const double _shareImageTargetWidthPx = 1080.0;

/// RepaintBoundary を PNG 化して OS 標準シェアシートで共有する。
/// [boundaryKey] = エクスポートカード領域をラップする GlobalKey。
Future<void> shareGalaxyCycleImage({
  required GlobalKey boundaryKey,
  required String shareText,
  String filename = 'solara_galaxy_cycle.png',
}) async {
  final boundary = boundaryKey.currentContext?.findRenderObject()
      as RenderRepaintBoundary?;
  if (boundary == null) {
    throw StateError('capture target not found');
  }

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

String _isoDate(DateTime dt) {
  final l = dt.toLocal();
  final y = l.year;
  final m = l.month.toString().padLeft(2, '0');
  final d = l.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
