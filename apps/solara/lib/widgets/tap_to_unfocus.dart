// 子 widget の TextField 外をタップしたら全フォーカスを外す共通 widget。
//
// 用途 (2026-05-19、 オーナー要望):
//   全画面の TextField (Pro テーマ欄 / 各種メモ / プロフィール入力 / 検索バー 等)
//   に対して「入力欄外タップで決定 (キーボード閉じる)」挙動を統一する。
//
// 仕組み:
//   HitTestBehavior.translucent で子の GestureDetector / TextField は通常通り
//   反応しつつ、 子のどれにも当たらない空き領域のタップだけここで拾って
//   `FocusScope.of(context).unfocus()` で全フォーカスを解除する。
//
// 適用方針:
//   各画面の build 最上層をこれでラップする (Scaffold より外側 OR Scaffold body
//   側 = どちらでも動くが、 タブ切替 / NavigationBar も対象にしたいなら最上層)。
//   既に PopScope や他のラッパがある画面は、 その内側に置く方が干渉しにくい。

import 'package:flutter/material.dart';

class TapToUnfocus extends StatelessWidget {
  final Widget child;
  const TapToUnfocus({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: child,
    );
  }
}
