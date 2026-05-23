// Consultation V2 リクエストモデル — consultation_v2_api.dart の part。
//
// 最小入力 (約1KB): 誕生データ + 自宅座標 + 5問の答え + preset。
// Worker (consultation_engine.js runConsultationPipeline) の契約に対応する。

part of 'consultation_v2_api.dart';

/// 「いつ」(when)。場面ごとに意味が変わる時間指定。
/// 「今日 / 未定」は when=null で送る (Worker が現在/0年として扱う)。
class ConsultationWhen {
  /// 'date' (date) | 'range' (start+end) |
  /// 'within6mo' | 'within1yr' | 'in3yr' | 'in5yrPlus' (移住ホライズン)
  final String kind;
  final String? date; // YYYY-MM-DD ('date')
  final String? start; // YYYY-MM-DD ('range')
  final String? end; // YYYY-MM-DD ('range')

  const ConsultationWhen({required this.kind, this.date, this.start, this.end});

  /// 特定の 1 日 (おでかけ日付指定 / 旅行特定日 / 移住日付指定)。
  factory ConsultationWhen.onDate(String date) =>
      ConsultationWhen(kind: 'date', date: date);

  /// 期間 (旅行)。Worker は最大 3 日サンプリングする。
  factory ConsultationWhen.range(String start, String end) =>
      ConsultationWhen(kind: 'range', start: start, end: end);

  /// 移住ホライズン (within6mo / within1yr / in3yr / in5yrPlus)。
  factory ConsultationWhen.horizon(String kind) => ConsultationWhen(kind: kind);

  Map<String, dynamic> toJson() => {
        'kind': kind,
        if (date != null) 'date': date,
        if (start != null) 'start': start,
        if (end != null) 'end': end,
      };
}

/// 具体地点 (具体地点スコープ)。地図タップ=座標のみ / 検索=店名+種類付き。
class ConsultationPoint {
  final double lat;
  final double lng;

  /// ユーザーが選んだ実在の名前 (店舗名・地名)。座標タップのみのときは null。
  final String? name;

  /// Google Places のタイプ (restaurant/cafe/movie_theater 等)。店舗選択時のみ。
  final String? placeType;

  const ConsultationPoint({
    required this.lat,
    required this.lng,
    this.name,
    this.placeType,
  });

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        if (name != null && name!.isNotEmpty) 'name': name,
        if (placeType != null && placeType!.isNotEmpty) 'placeType': placeType,
      };
}

/// 「どこで」(scope)。候補地点プールの作り方。
class ConsultationScope {
  /// 'point' | 'bearing' | 'radius' | 'region' | 'country' | 'world'
  final String kind;
  final ConsultationPoint? point;
  final double? radiusKm;
  final String? regionGroup; // 'region' のとき (例: '日本', '北米')
  final String? country; // 'country' のとき (省略時 Worker が home から推定)

  const ConsultationScope({
    required this.kind,
    this.point,
    this.radiusKm,
    this.regionGroup,
    this.country,
  });

  factory ConsultationScope.point(ConsultationPoint p) =>
      ConsultationScope(kind: 'point', point: p);

  /// おでかけ: home から 8 方角 × radiusKm の点。
  factory ConsultationScope.bearing({double radiusKm = 50}) =>
      ConsultationScope(kind: 'bearing', radiusKm: radiusKm);

  /// 自宅から半径 radiusKm 以内の都市。
  factory ConsultationScope.radius(double radiusKm) =>
      ConsultationScope(kind: 'radius', radiusKm: radiusKm);

  /// 地域 (大ブロック) 内の都市。
  factory ConsultationScope.region(String regionGroup) =>
      ConsultationScope(kind: 'region', regionGroup: regionGroup);

  /// 自国内 (country 省略時は home 座標から推定)。
  factory ConsultationScope.country([String? country]) =>
      ConsultationScope(kind: 'country', country: country);

  /// 世界全体。
  factory ConsultationScope.world() => const ConsultationScope(kind: 'world');

  Map<String, dynamic> toJson() => {
        'kind': kind,
        if (point != null) 'point': point!.toJson(),
        if (radiusKm != null) 'radiusKm': radiusKm,
        if (regionGroup != null) 'regionGroup': regionGroup,
        if (country != null) 'country': country,
      };
}

/// 相談リクエスト (最小入力 約1KB)。Worker が全計算する。
class ConsultationRequest {
  // 誕生データ
  final String birthDate; // YYYY-MM-DD
  final String? birthTime; // HH:mm (timeUnknown のとき null)
  final bool birthTimeUnknown;
  final double birthLat;
  final double birthLng;
  final int birthTz; // UTC offset (legacy fallback)
  final String? birthTzName; // IANA TZ 名 (DST 対応)
  // 自宅座標
  final double homeLat;
  final double homeLng;
  // 5 つの問い
  final String theme; // love/money/work/communication/healing/newStart
  final String mode; // migration/travel/daily
  final ConsultationWhen? when; // null = 今日/未定
  final ConsultationScope? scope; // null = world
  final String withWhom; // だれと (語りのレンズ・自由記述)
  final String wish; // どうなりたい/願い (語りの核・自由記述)
  // ページング
  final bool isFirst; // 初回 (内的季節/intro/outro を出す)
  final List<String> excluded; // 既出候補名 (「別の候補地」用)
  final String lang;

  const ConsultationRequest({
    required this.birthDate,
    required this.birthTime,
    required this.birthTimeUnknown,
    required this.birthLat,
    required this.birthLng,
    required this.birthTz,
    required this.birthTzName,
    required this.homeLat,
    required this.homeLng,
    required this.theme,
    required this.mode,
    this.when,
    this.scope,
    this.withWhom = '',
    this.wish = '',
    this.isFirst = true,
    this.excluded = const [],
    this.lang = 'ja',
  });

  /// 保存済みプロフィールから誕生/自宅データを引いてリクエストを組む。
  factory ConsultationRequest.fromProfile(
    SolaraProfile p, {
    required String theme,
    required String mode,
    ConsultationWhen? when,
    ConsultationScope? scope,
    String withWhom = '',
    String wish = '',
    bool isFirst = true,
    List<String> excluded = const [],
    String lang = 'ja',
  }) {
    final unknown = p.birthTimeUnknown || p.birthTime.isEmpty;
    return ConsultationRequest(
      birthDate: p.birthDate,
      birthTime: unknown ? null : p.birthTime,
      birthTimeUnknown: unknown,
      birthLat: p.birthLat,
      birthLng: p.birthLng,
      birthTz: p.birthTz,
      birthTzName: p.birthTzName,
      homeLat: p.homeLat,
      homeLng: p.homeLng,
      theme: theme,
      mode: mode,
      when: when,
      scope: scope,
      withWhom: withWhom,
      wish: wish,
      isFirst: isFirst,
      excluded: excluded,
      lang: lang,
    );
  }

  ConsultationRequest copyWith({
    bool? isFirst,
    List<String>? excluded,
  }) =>
      ConsultationRequest(
        birthDate: birthDate,
        birthTime: birthTime,
        birthTimeUnknown: birthTimeUnknown,
        birthLat: birthLat,
        birthLng: birthLng,
        birthTz: birthTz,
        birthTzName: birthTzName,
        homeLat: homeLat,
        homeLng: homeLng,
        theme: theme,
        mode: mode,
        when: when,
        scope: scope,
        withWhom: withWhom,
        wish: wish,
        isFirst: isFirst ?? this.isFirst,
        excluded: excluded ?? this.excluded,
        lang: lang,
      );

  Map<String, dynamic> toJson() => {
        'birth': {
          'date': birthDate,
          if (birthTime != null) 'time': birthTime,
          'timeUnknown': birthTimeUnknown,
          'lat': birthLat,
          'lng': birthLng,
          'tz': birthTz,
          if (birthTzName != null) 'tzName': birthTzName,
        },
        'home': {'lat': homeLat, 'lng': homeLng},
        'theme': theme,
        'mode': mode,
        if (when != null) 'when': when!.toJson(),
        if (scope != null) 'scope': scope!.toJson(),
        if (withWhom.isNotEmpty) 'withWhom': withWhom,
        if (wish.isNotEmpty) 'wish': wish,
        'isFirst': isFirst,
        if (excluded.isNotEmpty) 'excluded': excluded,
        'lang': lang,
      };
}
