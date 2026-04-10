import 'package:flutter/material.dart';

/// 16方位の方位名
const dir16 = ['N','NNE','NE','ENE','E','ESE','SE','SSE',
               'S','SSW','SW','WSW','W','WNW','NW','NNW'];

/// 16方位の日本語名
const dir16JP = <String,String>{
  'N':'北','NNE':'北北東','NE':'北東','ENE':'東北東',
  'E':'東','ESE':'東南東','SE':'南東','SSE':'南南東',
  'S':'南','SSW':'南南西','SW':'南西','WSW':'西南西',
  'W':'西','WNW':'西北西','NW':'北西','NNW':'北北西',
};

/// HTML: fp-item --pc colors
const categoryColors = <String, Color>{
  'all': Color(0xFFE8E0D0), 'healing': Color(0xFF64C8B4), 'money': Color(0xFFF5D76E),
  'love': Color(0xFFFF88B4), 'work': Color(0xFF6BB5FF), 'communication': Color(0xFFB088FF),
};

/// カテゴリ日本語ラベル
const categoryLabels = <String, String>{
  'all':'総合','healing':'癒し','money':'金運','love':'恋愛','work':'仕事','communication':'話す',
};

/// HTML: COMP_COLORS
const compColors = <String, Color>{
  'tSoft': Color(0xFFC9A84C), 'tHard': Color(0xFF6B5CE7),
  'pSoft': Color(0xFF4CB8B0), 'pHard': Color(0xFFE74C6B),
};
const compKeys = ['tSoft', 'tHard', 'pSoft', 'pHard'];

/// ソースタブラベル
const srcLabels = <String, String>{'combined':'合計','transit':'トランジット','progressed':'プログレス'};
