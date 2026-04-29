// ============================================================
// Solara DirectionEnergy — Soft/Hard 独立2エネルギー
//
// 設計思想: project_solara_design_philosophy.md (2026-04-29 オーナー確定)
//
// 🔴 重要原則 🔴
//   - ソフトとハードは独立した別エネルギー（1軸の両端ではない）
//   - プラスマイナスではない、両方とも正の存在量
//   - total / softRatio は意図的に持たない
//     （合算/割合は1次元化を招き、設計思想に反する）
//
// 🔴 実装禁止 🔴
//   - `double get total => soft + hard;` を追加しない
//   - `double get softRatio => soft / (soft + hard);` を追加しない
//   - UIで両エネルギーを1つの値に丸めて表示しない
//
// 🔴 実装すべき 🔴
//   - soft / hard を独立した絶対値として保持
//   - UI は2エネルギーを並列表示（バー2本、または S40/H25 形式）
//   - 色は「赤=悪 緑=良」を避ける（ハード=金陽色、ソフト=銀月色 等）
// ============================================================
library;

/// 16方位や時刻における2つの独立したエネルギー存在量。
///
/// ソフトは「流れに乗る力」（寛容・拡大・受容・安定）、
/// ハードは「摩擦と変化の力」（挑戦・変容・対峙・成長）。
///
/// それぞれが独立した別のエネルギーであり、
/// 良し悪しではなく性質の違いとして提示する。
class DirectionEnergy {
  /// ソフトエネルギー量（流れ・受容のエネルギー）
  final double soft;

  /// ハードエネルギー量（摩擦・変容のエネルギー）
  final double hard;

  const DirectionEnergy({required this.soft, required this.hard});

  /// 量がほぼ0のエネルギー（活性化していない方角・時刻）
  static const empty = DirectionEnergy(soft: 0, hard: 0);

  /// 性質分類（4象限）。優劣ではなく、エネルギーの組み合わせの違い。
  ///
  /// 閾値はUI側のキャリブレーションに依存するため引数で渡す。
  /// 同じ閾値を全方向に適用することで「相対比較」ではなく
  /// 「絶対量の有無」で分類できる。
  EnergyMode classify(double threshold) {
    final softHigh = soft > threshold;
    final hardHigh = hard > threshold;
    if (softHigh && hardHigh) return EnergyMode.both;
    if (softHigh) return EnergyMode.softOnly;
    if (hardHigh) return EnergyMode.hardOnly;
    return EnergyMode.quiet;
  }

  /// 内部ソート用の「アクティブ度」（max を使い、合算ではない）。
  ///
  /// 注意: この値はUIに直接表示してはいけない。
  /// 「ソートされた順番」でユーザーに方角を提示する用途のみ許可。
  /// ソフト/ハードを単一値に潰す表現は設計思想に反する。
  double get _maxComponent => soft > hard ? soft : hard;

  /// ソート用キー（プライベートゲッターのpublicエイリアス）
  /// 用途: 「最もアクティブな3方角を上に並べる」のような表示順制御。
  /// 値そのものをUIに出さないこと。
  double get sortKey => _maxComponent;

  @override
  String toString() =>
      'DirectionEnergy(soft: ${soft.toStringAsFixed(2)}, '
      'hard: ${hard.toStringAsFixed(2)})';
}

/// エネルギーの組み合わせによる性質分類。
///
/// これらは「良い/悪い」ではなく、性質の違いを示すラベル。
/// UIで色分けする場合も、4種をすべて美しく見せること。
enum EnergyMode {
  /// 両エネルギーが強く効く：両面の深い体験
  both,

  /// ソフトのみ強い：流れに乗りやすい
  softOnly,

  /// ハードのみ強い：摩擦・内省・対峙
  hardOnly,

  /// 両方静か：特別な動きなし
  quiet,
}

// ============================================================
// AspectContribution — 1つのアスペクトが特定方角/カテゴリに
// 寄与した soft / hard 量の記録。
//
// 用途: 「南方位がなぜ ☯12 / ☐8 なのか」の attribution 表示。
//   E4 ポップアップで「金星×木星 トライン由来 ☯7.2」
//   「金星×火星 スクエア由来 ☐5.5」のように分解表示する。
//
// 設計: soft / hard を独立に保持（DirectionEnergy と同じ思想）。
//   neutral aspect (conjunction) は両方非0、
//   soft aspect は softAmount のみ、hard/tense は hardAmount のみ。
// ============================================================

/// 1アスペクトの方角への寄与量。
///
/// p1 / p2 はベース惑星名 + プレフィックス記号:
///   - 接頭辞なし: トランジット惑星（例: 'venus'）
///   - `N:` 接頭辞: ナタル惑星（例: 'N:venus'）
///   - `P:` 接頭辞: プログレス惑星
///   - `_asc` / `_mc` / `_dsc` / `_ic`: ナタルアングル
class AspectContribution {
  /// アスペクトを構成する惑星1
  final String p1;

  /// アスペクトを構成する惑星2（プレフィックスでナタル/プログレス/アングル区別）
  final String p2;

  /// アスペクト種別: 'conjunction' | 'sextile' | 'square' | 'trine' | 'quincunx' | 'opposition'
  final String aspectType;

  /// アスペクトの性質: 'soft' | 'hard' | 'tense' | 'neutral'
  final String quality;

  /// この方角に寄与したソフト量
  final double softAmount;

  /// この方角に寄与したハード量
  final double hardAmount;

  const AspectContribution({
    required this.p1,
    required this.p2,
    required this.aspectType,
    required this.quality,
    required this.softAmount,
    required this.hardAmount,
  });

  /// 同じアスペクトを別の方角に寄与させる際の cosFall スケーリング。
  AspectContribution scaledBy(double factor) => AspectContribution(
        p1: p1,
        p2: p2,
        aspectType: aspectType,
        quality: quality,
        softAmount: softAmount * factor,
        hardAmount: hardAmount * factor,
      );

  /// UI で同種アスペクトをグループ化するキー（"venus_square_mars"）
  String get groupKey => '${p1}_${aspectType}_$p2';
}

/// 集約済みアスペクト寄与。E4 ポップアップ用。
/// 同種アスペクト（同 groupKey）を1エントリにまとめ、soft/hard を合算。
class AggregatedAspect {
  final String p1;
  final String p2;
  final String aspectType;
  final String quality;
  final double softAmount;
  final double hardAmount;
  final int count; // 何回スプレッドされたか（複数pathで来ることがある）

  const AggregatedAspect({
    required this.p1,
    required this.p2,
    required this.aspectType,
    required this.quality,
    required this.softAmount,
    required this.hardAmount,
    required this.count,
  });

  /// soft / hard どちらかの最大値（並び替え用）
  double get magnitude => softAmount > hardAmount ? softAmount : hardAmount;
}

/// 寄与アスペクトリストを groupKey で集約し、magnitude の降順でソート。
/// [topN] が指定されていれば上位N件のみ返す。
List<AggregatedAspect> aggregateContributions(
  List<AspectContribution> contributions, {
  int? topN,
}) {
  final grouped = <String, _AggBuilder>{};
  for (final c in contributions) {
    final key = c.groupKey;
    final b = grouped[key];
    if (b == null) {
      grouped[key] = _AggBuilder(c);
    } else {
      b.merge(c);
    }
  }
  final result = grouped.values.map((b) => b.build()).toList()
    ..sort((a, b) => b.magnitude.compareTo(a.magnitude));
  if (topN != null && result.length > topN) {
    return result.sublist(0, topN);
  }
  return result;
}

class _AggBuilder {
  final String p1;
  final String p2;
  final String aspectType;
  final String quality;
  double soft;
  double hard;
  int count;

  _AggBuilder(AspectContribution first)
      : p1 = first.p1,
        p2 = first.p2,
        aspectType = first.aspectType,
        quality = first.quality,
        soft = first.softAmount,
        hard = first.hardAmount,
        count = 1;

  void merge(AspectContribution c) {
    soft += c.softAmount;
    hard += c.hardAmount;
    count++;
  }

  AggregatedAspect build() => AggregatedAspect(
        p1: p1,
        p2: p2,
        aspectType: aspectType,
        quality: quality,
        softAmount: soft,
        hardAmount: hard,
        count: count,
      );
}

