#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""generate_world_cities.py — Solara (ii) AI 相談 Stage 2 用 都市リスト生成スクリプト

出力: ../lib/utils/world_cities.dart (Dart 定数ファイル、手書き禁止・要再生成)

設計: docs/pro_candidates.md §7.2 Stage 2「キュレート都市リスト ~500-1000」

データ源:
  v1 = この script に embed されたキュレーションリスト (~300 都市)。
       GeoNames cities500 等のフル抽出は v2 以降の拡張で。
       (ローンチ MVP には ~300 で十分。47 都道府県主要 + US 全州 + 世界主要を網羅)

カバレッジ (合計 ~320 都市):
  JP    : 47 県庁所在地 + 10 政令指定都市/主要都市 = 57
  US    : 50 州都 + 30 主要都市 = 80
  Europe: ~80
  Asia  : ~45 (中国/韓国/台湾/東南アジア/南アジア/中東)
  Africa: ~15
  Americas (除 US): ~25
  Oceania: ~10

各 entry: (nameJP, nameEN, lat, lng, country, region, population)
  - lat/lng は都市中心の代表点 (誤差数 km は OK、線距離計算は km オーダー)
  - population は ~2024 の概数 (千人単位で十分、AI ランキング初期重み用)
  - country = ISO 2-letter
  - region = 国内の地域 (都道府県/state/region) — bbox や絞込み用

実行:
  python apps/solara/tools/generate_world_cities.py
"""

from __future__ import annotations
import sys
from pathlib import Path


# ────────────────────────────────────────────────────────────
# JP — 47 県庁所在地 + 政令指定都市/主要都市
# ────────────────────────────────────────────────────────────
JP_CITIES = [
    # 北海道・東北
    ("札幌", "Sapporo", 43.0642, 141.3469, "JP", "北海道", 1973000),
    ("青森", "Aomori", 40.8244, 140.7400, "JP", "青森県", 271000),
    ("盛岡", "Morioka", 39.7036, 141.1527, "JP", "岩手県", 286000),
    ("仙台", "Sendai", 38.2682, 140.8694, "JP", "宮城県", 1097000),
    ("秋田", "Akita", 39.7186, 140.1024, "JP", "秋田県", 303000),
    ("山形", "Yamagata", 38.2404, 140.3636, "JP", "山形県", 245000),
    ("福島", "Fukushima", 37.7503, 140.4676, "JP", "福島県", 277000),
    # 関東
    ("水戸", "Mito", 36.3418, 140.4468, "JP", "茨城県", 270000),
    ("宇都宮", "Utsunomiya", 36.5658, 139.8836, "JP", "栃木県", 518000),
    ("前橋", "Maebashi", 36.3895, 139.0634, "JP", "群馬県", 333000),
    ("さいたま", "Saitama", 35.8617, 139.6455, "JP", "埼玉県", 1340000),
    ("千葉", "Chiba", 35.6074, 140.1065, "JP", "千葉県", 980000),
    ("東京", "Tokyo", 35.6762, 139.6503, "JP", "東京都", 13960000),
    ("横浜", "Yokohama", 35.4437, 139.6380, "JP", "神奈川県", 3777000),
    ("川崎", "Kawasaki", 35.5308, 139.7029, "JP", "神奈川県", 1539000),
    # 中部・北陸
    ("新潟", "Niigata", 37.9026, 139.0234, "JP", "新潟県", 781000),
    ("富山", "Toyama", 36.6953, 137.2113, "JP", "富山県", 412000),
    ("金沢", "Kanazawa", 36.5613, 136.6562, "JP", "石川県", 463000),
    ("福井", "Fukui", 36.0652, 136.2216, "JP", "福井県", 261000),
    ("甲府", "Kofu", 35.6635, 138.5683, "JP", "山梨県", 186000),
    ("長野", "Nagano", 36.6485, 138.1810, "JP", "長野県", 369000),
    ("岐阜", "Gifu", 35.4233, 136.7607, "JP", "岐阜県", 403000),
    ("静岡", "Shizuoka", 34.9756, 138.3828, "JP", "静岡県", 692000),
    ("浜松", "Hamamatsu", 34.7108, 137.7261, "JP", "静岡県", 791000),
    ("名古屋", "Nagoya", 35.1815, 136.9066, "JP", "愛知県", 2332000),
    # 関西
    ("津", "Tsu", 34.7185, 136.5057, "JP", "三重県", 274000),
    ("大津", "Otsu", 35.0045, 135.8686, "JP", "滋賀県", 343000),
    ("京都", "Kyoto", 35.0116, 135.7681, "JP", "京都府", 1463000),
    ("大阪", "Osaka", 34.6937, 135.5023, "JP", "大阪府", 2752000),
    ("堺", "Sakai", 34.5733, 135.4830, "JP", "大阪府", 826000),
    ("神戸", "Kobe", 34.6901, 135.1956, "JP", "兵庫県", 1525000),
    ("奈良", "Nara", 34.6851, 135.8048, "JP", "奈良県", 354000),
    ("和歌山", "Wakayama", 34.2261, 135.1675, "JP", "和歌山県", 357000),
    # 中国・四国
    ("鳥取", "Tottori", 35.5037, 134.2382, "JP", "鳥取県", 188000),
    ("松江", "Matsue", 35.4723, 133.0505, "JP", "島根県", 202000),
    ("岡山", "Okayama", 34.6618, 133.9344, "JP", "岡山県", 720000),
    ("広島", "Hiroshima", 34.3853, 132.4553, "JP", "広島県", 1199000),
    ("山口", "Yamaguchi", 34.1859, 131.4706, "JP", "山口県", 191000),
    ("徳島", "Tokushima", 34.0703, 134.5548, "JP", "徳島県", 252000),
    ("高松", "Takamatsu", 34.3401, 134.0434, "JP", "香川県", 416000),
    ("松山", "Matsuyama", 33.8392, 132.7656, "JP", "愛媛県", 506000),
    ("高知", "Kochi", 33.5597, 133.5311, "JP", "高知県", 326000),
    # 九州・沖縄
    ("福岡", "Fukuoka", 33.5904, 130.4017, "JP", "福岡県", 1612000),
    ("北九州", "Kitakyushu", 33.8835, 130.8751, "JP", "福岡県", 928000),
    ("佐賀", "Saga", 33.2494, 130.2989, "JP", "佐賀県", 230000),
    ("長崎", "Nagasaki", 32.7503, 129.8779, "JP", "長崎県", 401000),
    ("熊本", "Kumamoto", 32.7898, 130.7417, "JP", "熊本県", 738000),
    ("大分", "Oita", 33.2382, 131.6126, "JP", "大分県", 475000),
    ("宮崎", "Miyazaki", 31.9077, 131.4202, "JP", "宮崎県", 397000),
    ("鹿児島", "Kagoshima", 31.5969, 130.5571, "JP", "鹿児島県", 593000),
    ("那覇", "Naha", 26.2125, 127.6809, "JP", "沖縄県", 318000),
    # 主要副都市 (関東・関西の主要 + 観光地)
    ("函館", "Hakodate", 41.7687, 140.7290, "JP", "北海道", 251000),
    ("旭川", "Asahikawa", 43.7707, 142.3650, "JP", "北海道", 327000),
    ("八王子", "Hachioji", 35.6557, 139.3389, "JP", "東京都", 561000),
    ("町田", "Machida", 35.5469, 139.4467, "JP", "東京都", 432000),
    ("船橋", "Funabashi", 35.6947, 139.9826, "JP", "千葉県", 645000),
    ("豊田", "Toyota", 35.0830, 137.1565, "JP", "愛知県", 423000),
    ("姫路", "Himeji", 34.8151, 134.6852, "JP", "兵庫県", 525000),
    ("倉敷", "Kurashiki", 34.5852, 133.7720, "JP", "岡山県", 477000),
    ("石垣", "Ishigaki", 24.3448, 124.1572, "JP", "沖縄県", 49000),
]


# ────────────────────────────────────────────────────────────
# US — 州都 + 主要都市
# ────────────────────────────────────────────────────────────
US_CITIES = [
    # 州都 (50)
    ("モンゴメリー", "Montgomery", 32.3792, -86.3077, "US", "Alabama", 200000),
    ("ジュノー", "Juneau", 58.3019, -134.4197, "US", "Alaska", 32000),
    ("フェニックス", "Phoenix", 33.4484, -112.0740, "US", "Arizona", 1608000),
    ("リトルロック", "Little Rock", 34.7465, -92.2896, "US", "Arkansas", 198000),
    ("サクラメント", "Sacramento", 38.5816, -121.4944, "US", "California", 525000),
    ("デンバー", "Denver", 39.7392, -104.9903, "US", "Colorado", 716000),
    ("ハートフォード", "Hartford", 41.7658, -72.6734, "US", "Connecticut", 121000),
    ("ドーバー", "Dover", 39.1582, -75.5244, "US", "Delaware", 39000),
    ("タラハシー", "Tallahassee", 30.4383, -84.2807, "US", "Florida", 200000),
    ("アトランタ", "Atlanta", 33.7490, -84.3880, "US", "Georgia", 499000),
    ("ホノルル", "Honolulu", 21.3099, -157.8581, "US", "Hawaii", 350000),
    ("ボイシ", "Boise", 43.6150, -116.2023, "US", "Idaho", 235000),
    ("スプリングフィールド", "Springfield", 39.7817, -89.6501, "US", "Illinois", 114000),
    ("インディアナポリス", "Indianapolis", 39.7684, -86.1581, "US", "Indiana", 887000),
    ("デモイン", "Des Moines", 41.5868, -93.6250, "US", "Iowa", 214000),
    ("トピカ", "Topeka", 39.0473, -95.6752, "US", "Kansas", 126000),
    ("フランクフォート", "Frankfort", 38.2009, -84.8733, "US", "Kentucky", 28000),
    ("バトンルージュ", "Baton Rouge", 30.4515, -91.1871, "US", "Louisiana", 222000),
    ("オーガスタ", "Augusta", 44.3106, -69.7795, "US", "Maine", 19000),
    ("アナポリス", "Annapolis", 38.9784, -76.4922, "US", "Maryland", 40000),
    ("ボストン", "Boston", 42.3601, -71.0589, "US", "Massachusetts", 654000),
    ("ランシング", "Lansing", 42.7325, -84.5555, "US", "Michigan", 113000),
    ("セントポール", "Saint Paul", 44.9537, -93.0900, "US", "Minnesota", 311000),
    ("ジャクソン", "Jackson", 32.2988, -90.1848, "US", "Mississippi", 153000),
    ("ジェファーソンシティ", "Jefferson City", 38.5767, -92.1735, "US", "Missouri", 43000),
    ("ヘレナ", "Helena", 46.5891, -112.0391, "US", "Montana", 32000),
    ("リンカーン", "Lincoln", 40.8136, -96.7026, "US", "Nebraska", 292000),
    ("カーソンシティ", "Carson City", 39.1638, -119.7674, "US", "Nevada", 58000),
    ("コンコード", "Concord", 43.2081, -71.5376, "US", "New Hampshire", 43000),
    ("トレントン", "Trenton", 40.2206, -74.7597, "US", "New Jersey", 90000),
    ("サンタフェ", "Santa Fe", 35.6870, -105.9378, "US", "New Mexico", 87000),
    ("オールバニ", "Albany", 42.6526, -73.7562, "US", "New York", 99000),
    ("ローリー", "Raleigh", 35.7796, -78.6382, "US", "North Carolina", 467000),
    ("ビスマーク", "Bismarck", 46.8083, -100.7837, "US", "North Dakota", 73000),
    ("コロンバス", "Columbus", 39.9612, -82.9988, "US", "Ohio", 905000),
    ("オクラホマシティ", "Oklahoma City", 35.4676, -97.5164, "US", "Oklahoma", 681000),
    ("セーラム", "Salem", 44.9429, -123.0351, "US", "Oregon", 175000),
    ("ハリスバーグ", "Harrisburg", 40.2732, -76.8839, "US", "Pennsylvania", 50000),
    ("プロビデンス", "Providence", 41.8240, -71.4128, "US", "Rhode Island", 191000),
    ("コロンビア", "Columbia", 34.0007, -81.0348, "US", "South Carolina", 137000),
    ("ピア", "Pierre", 44.3683, -100.3510, "US", "South Dakota", 14000),
    ("ナッシュビル", "Nashville", 36.1627, -86.7816, "US", "Tennessee", 689000),
    ("オースティン", "Austin", 30.2672, -97.7431, "US", "Texas", 974000),
    ("ソルトレイクシティ", "Salt Lake City", 40.7608, -111.8910, "US", "Utah", 200000),
    ("モントピリア", "Montpelier", 44.2601, -72.5754, "US", "Vermont", 8000),
    ("リッチモンド", "Richmond", 37.5407, -77.4360, "US", "Virginia", 226000),
    ("オリンピア", "Olympia", 47.0379, -122.9007, "US", "Washington", 56000),
    ("チャールストン", "Charleston", 38.3498, -81.6326, "US", "West Virginia", 47000),
    ("マディソン", "Madison", 43.0731, -89.4012, "US", "Wisconsin", 269000),
    ("シャイアン", "Cheyenne", 41.1400, -104.8202, "US", "Wyoming", 65000),
    # 主要都市 (州都以外)
    ("ニューヨーク", "New York", 40.7128, -74.0060, "US", "New York", 8336000),
    ("ロサンゼルス", "Los Angeles", 34.0522, -118.2437, "US", "California", 3979000),
    ("シカゴ", "Chicago", 41.8781, -87.6298, "US", "Illinois", 2693000),
    ("ヒューストン", "Houston", 29.7604, -95.3698, "US", "Texas", 2320000),
    ("フィラデルフィア", "Philadelphia", 39.9526, -75.1652, "US", "Pennsylvania", 1584000),
    ("サンアントニオ", "San Antonio", 29.4241, -98.4936, "US", "Texas", 1547000),
    ("サンディエゴ", "San Diego", 32.7157, -117.1611, "US", "California", 1424000),
    ("ダラス", "Dallas", 32.7767, -96.7970, "US", "Texas", 1343000),
    ("サンノゼ", "San Jose", 37.3382, -121.8863, "US", "California", 1021000),
    ("ジャクソンビル", "Jacksonville", 30.3322, -81.6557, "US", "Florida", 911000),
    ("フォートワース", "Fort Worth", 32.7555, -97.3308, "US", "Texas", 909000),
    ("シャーロット", "Charlotte", 35.2271, -80.8431, "US", "North Carolina", 885000),
    ("シアトル", "Seattle", 47.6062, -122.3321, "US", "Washington", 753000),
    ("エルパソ", "El Paso", 31.7619, -106.4850, "US", "Texas", 682000),
    ("デトロイト", "Detroit", 42.3314, -83.0458, "US", "Michigan", 670000),
    ("メンフィス", "Memphis", 35.1495, -90.0490, "US", "Tennessee", 651000),
    ("ポートランド", "Portland", 45.5152, -122.6784, "US", "Oregon", 654000),
    ("ラスベガス", "Las Vegas", 36.1699, -115.1398, "US", "Nevada", 644000),
    ("ルイビル", "Louisville", 38.2527, -85.7585, "US", "Kentucky", 617000),
    ("ボルチモア", "Baltimore", 39.2904, -76.6122, "US", "Maryland", 593000),
    ("ミルウォーキー", "Milwaukee", 43.0389, -87.9065, "US", "Wisconsin", 590000),
    ("アルバカーキ", "Albuquerque", 35.0844, -106.6504, "US", "New Mexico", 562000),
    ("ツーソン", "Tucson", 32.2226, -110.9747, "US", "Arizona", 548000),
    ("フレズノ", "Fresno", 36.7378, -119.7871, "US", "California", 542000),
    ("ミネアポリス", "Minneapolis", 44.9778, -93.2650, "US", "Minnesota", 429000),
    ("マイアミ", "Miami", 25.7617, -80.1918, "US", "Florida", 442000),
    ("オークランド", "Oakland", 37.8044, -122.2712, "US", "California", 433000),
    ("サンフランシスコ", "San Francisco", 37.7749, -122.4194, "US", "California", 874000),
    ("ニューオーリンズ", "New Orleans", 29.9511, -90.0715, "US", "Louisiana", 391000),
    ("ピッツバーグ", "Pittsburgh", 40.4406, -79.9959, "US", "Pennsylvania", 302000),
]


# ────────────────────────────────────────────────────────────
# Europe — 主要国の首都 + 主要都市
# ────────────────────────────────────────────────────────────
EU_CITIES = [
    ("ロンドン", "London", 51.5074, -0.1278, "GB", "England", 8982000),
    ("マンチェスター", "Manchester", 53.4808, -2.2426, "GB", "England", 553000),
    ("バーミンガム", "Birmingham", 52.4862, -1.8904, "GB", "England", 1141000),
    ("リバプール", "Liverpool", 53.4084, -2.9916, "GB", "England", 498000),
    ("エディンバラ", "Edinburgh", 55.9533, -3.1883, "GB", "Scotland", 488000),
    ("グラスゴー", "Glasgow", 55.8642, -4.2518, "GB", "Scotland", 626000),
    ("ダブリン", "Dublin", 53.3498, -6.2603, "IE", "Leinster", 555000),
    ("パリ", "Paris", 48.8566, 2.3522, "FR", "Île-de-France", 2161000),
    ("マルセイユ", "Marseille", 43.2965, 5.3698, "FR", "PACA", 868000),
    ("リヨン", "Lyon", 45.7640, 4.8357, "FR", "Auvergne-Rhône-Alpes", 522000),
    ("ニース", "Nice", 43.7102, 7.2620, "FR", "PACA", 342000),
    ("トゥールーズ", "Toulouse", 43.6047, 1.4442, "FR", "Occitanie", 493000),
    ("ボルドー", "Bordeaux", 44.8378, -0.5792, "FR", "Nouvelle-Aquitaine", 261000),
    ("ストラスブール", "Strasbourg", 48.5734, 7.7521, "FR", "Grand Est", 280000),
    ("ベルリン", "Berlin", 52.5200, 13.4050, "DE", "Berlin", 3669000),
    ("ハンブルク", "Hamburg", 53.5511, 9.9937, "DE", "Hamburg", 1841000),
    ("ミュンヘン", "Munich", 48.1351, 11.5820, "DE", "Bavaria", 1488000),
    ("ケルン", "Cologne", 50.9375, 6.9603, "DE", "North Rhine-Westphalia", 1086000),
    ("フランクフルト", "Frankfurt", 50.1109, 8.6821, "DE", "Hesse", 753000),
    ("シュトゥットガルト", "Stuttgart", 48.7758, 9.1829, "DE", "Baden-Württemberg", 635000),
    ("デュッセルドルフ", "Düsseldorf", 51.2277, 6.7735, "DE", "North Rhine-Westphalia", 619000),
    ("ライプツィヒ", "Leipzig", 51.3397, 12.3731, "DE", "Saxony", 601000),
    ("ドレスデン", "Dresden", 51.0504, 13.7373, "DE", "Saxony", 556000),
    ("アムステルダム", "Amsterdam", 52.3676, 4.9041, "NL", "North Holland", 821000),
    ("ロッテルダム", "Rotterdam", 51.9244, 4.4777, "NL", "South Holland", 651000),
    ("ハーグ", "The Hague", 52.0705, 4.3007, "NL", "South Holland", 545000),
    ("ブリュッセル", "Brussels", 50.8503, 4.3517, "BE", "Brussels", 1208000),
    ("アントワープ", "Antwerp", 51.2194, 4.4025, "BE", "Flanders", 530000),
    ("マドリード", "Madrid", 40.4168, -3.7038, "ES", "Madrid", 3223000),
    ("バルセロナ", "Barcelona", 41.3851, 2.1734, "ES", "Catalonia", 1620000),
    ("バレンシア", "Valencia", 39.4699, -0.3763, "ES", "Valencia", 791000),
    ("セビリア", "Seville", 37.3891, -5.9845, "ES", "Andalusia", 688000),
    ("ビルバオ", "Bilbao", 43.2630, -2.9350, "ES", "Basque Country", 346000),
    ("マラガ", "Málaga", 36.7213, -4.4214, "ES", "Andalusia", 574000),
    ("リスボン", "Lisbon", 38.7223, -9.1393, "PT", "Lisbon", 547000),
    ("ポルト", "Porto", 41.1579, -8.6291, "PT", "Norte", 237000),
    ("ローマ", "Rome", 41.9028, 12.4964, "IT", "Lazio", 2872000),
    ("ミラノ", "Milan", 45.4642, 9.1900, "IT", "Lombardy", 1396000),
    ("ナポリ", "Naples", 40.8518, 14.2681, "IT", "Campania", 967000),
    ("トリノ", "Turin", 45.0703, 7.6869, "IT", "Piedmont", 870000),
    ("フィレンツェ", "Florence", 43.7696, 11.2558, "IT", "Tuscany", 380000),
    ("ヴェネツィア", "Venice", 45.4408, 12.3155, "IT", "Veneto", 261000),
    ("ボローニャ", "Bologna", 44.4949, 11.3426, "IT", "Emilia-Romagna", 388000),
    ("ジェノヴァ", "Genoa", 44.4056, 8.9463, "IT", "Liguria", 583000),
    ("チューリッヒ", "Zurich", 47.3769, 8.5417, "CH", "Zurich", 415000),
    ("ジュネーブ", "Geneva", 46.2044, 6.1432, "CH", "Geneva", 203000),
    ("ベルン", "Bern", 46.9480, 7.4474, "CH", "Bern", 134000),
    ("ウィーン", "Vienna", 48.2082, 16.3738, "AT", "Vienna", 1897000),
    ("ザルツブルク", "Salzburg", 47.8095, 13.0550, "AT", "Salzburg", 155000),
    ("コペンハーゲン", "Copenhagen", 55.6761, 12.5683, "DK", "Capital Region", 638000),
    ("ストックホルム", "Stockholm", 59.3293, 18.0686, "SE", "Stockholm", 975000),
    ("ヨーテボリ", "Gothenburg", 57.7089, 11.9746, "SE", "Västra Götaland", 583000),
    ("オスロ", "Oslo", 59.9139, 10.7522, "NO", "Oslo", 697000),
    ("ベルゲン", "Bergen", 60.3913, 5.3221, "NO", "Vestland", 285000),
    ("ヘルシンキ", "Helsinki", 60.1699, 24.9384, "FI", "Uusimaa", 658000),
    ("レイキャヴィク", "Reykjavik", 64.1466, -21.9426, "IS", "Capital Region", 132000),
    ("ワルシャワ", "Warsaw", 52.2297, 21.0122, "PL", "Masovian", 1790000),
    ("クラクフ", "Kraków", 50.0647, 19.9450, "PL", "Lesser Poland", 779000),
    ("プラハ", "Prague", 50.0755, 14.4378, "CZ", "Prague", 1309000),
    ("ブダペスト", "Budapest", 47.4979, 19.0402, "HU", "Budapest", 1750000),
    ("アテネ", "Athens", 37.9838, 23.7275, "GR", "Attica", 664000),
    ("テッサロニキ", "Thessaloniki", 40.6401, 22.9444, "GR", "Central Macedonia", 326000),
    ("イスタンブール", "Istanbul", 41.0082, 28.9784, "TR", "Istanbul", 15462000),
    ("アンカラ", "Ankara", 39.9334, 32.8597, "TR", "Ankara", 5663000),
    ("イズミル", "Izmir", 38.4237, 27.1428, "TR", "Izmir", 3057000),
    ("モスクワ", "Moscow", 55.7558, 37.6173, "RU", "Moscow", 12506000),
    ("サンクトペテルブルク", "Saint Petersburg", 59.9311, 30.3609, "RU", "Saint Petersburg", 5384000),
    ("キエフ", "Kyiv", 50.4501, 30.5234, "UA", "Kyiv", 2962000),
    ("ブカレスト", "Bucharest", 44.4268, 26.1025, "RO", "București", 1716000),
    ("ソフィア", "Sofia", 42.6977, 23.3219, "BG", "Sofia", 1228000),
    ("ベオグラード", "Belgrade", 44.7866, 20.4489, "RS", "Belgrade", 1166000),
    ("ザグレブ", "Zagreb", 45.8150, 15.9819, "HR", "Zagreb", 770000),
    ("リュブリャナ", "Ljubljana", 46.0569, 14.5058, "SI", "Central Slovenia", 295000),
    ("ブラチスラヴァ", "Bratislava", 48.1486, 17.1077, "SK", "Bratislava", 437000),
    ("タリン", "Tallinn", 59.4370, 24.7536, "EE", "Harju", 437000),
    ("リガ", "Riga", 56.9496, 24.1052, "LV", "Riga", 633000),
    ("ヴィリニュス", "Vilnius", 54.6872, 25.2797, "LT", "Vilnius", 588000),
    ("ミンスク", "Minsk", 53.9006, 27.5590, "BY", "Minsk", 2018000),
    ("ルクセンブルク", "Luxembourg", 49.6116, 6.1319, "LU", "Luxembourg", 124000),
]


# ────────────────────────────────────────────────────────────
# Asia (除日本)
# ────────────────────────────────────────────────────────────
ASIA_CITIES = [
    # China
    ("北京", "Beijing", 39.9042, 116.4074, "CN", "Beijing", 21540000),
    ("上海", "Shanghai", 31.2304, 121.4737, "CN", "Shanghai", 24870000),
    ("広州", "Guangzhou", 23.1291, 113.2644, "CN", "Guangdong", 15300000),
    ("深圳", "Shenzhen", 22.5431, 114.0579, "CN", "Guangdong", 12590000),
    ("成都", "Chengdu", 30.5728, 104.0668, "CN", "Sichuan", 16330000),
    ("武漢", "Wuhan", 30.5928, 114.3055, "CN", "Hubei", 11210000),
    ("西安", "Xi'an", 34.3416, 108.9398, "CN", "Shaanxi", 12953000),
    ("杭州", "Hangzhou", 30.2741, 120.1551, "CN", "Zhejiang", 12200000),
    ("南京", "Nanjing", 32.0603, 118.7969, "CN", "Jiangsu", 9314000),
    ("天津", "Tianjin", 39.3434, 117.3616, "CN", "Tianjin", 13860000),
    ("重慶", "Chongqing", 29.5630, 106.5516, "CN", "Chongqing", 32050000),
    ("香港", "Hong Kong", 22.3193, 114.1694, "HK", "Hong Kong", 7482000),
    ("マカオ", "Macau", 22.1987, 113.5439, "MO", "Macau", 696000),
    # Korea
    ("ソウル", "Seoul", 37.5665, 126.9780, "KR", "Seoul", 9776000),
    ("釜山", "Busan", 35.1796, 129.0756, "KR", "Busan", 3349000),
    ("仁川", "Incheon", 37.4563, 126.7052, "KR", "Incheon", 2954000),
    ("大邱", "Daegu", 35.8714, 128.6014, "KR", "Daegu", 2410000),
    # Taiwan
    ("台北", "Taipei", 25.0330, 121.5654, "TW", "Taipei", 2646000),
    ("高雄", "Kaohsiung", 22.6273, 120.3014, "TW", "Kaohsiung", 2773000),
    ("台中", "Taichung", 24.1477, 120.6736, "TW", "Taichung", 2820000),
    # Southeast Asia
    ("バンコク", "Bangkok", 13.7563, 100.5018, "TH", "Bangkok", 10539000),
    ("チェンマイ", "Chiang Mai", 18.7883, 98.9853, "TH", "Chiang Mai", 127000),
    ("プーケット", "Phuket", 7.8804, 98.3923, "TH", "Phuket", 79000),
    ("シンガポール", "Singapore", 1.3521, 103.8198, "SG", "Singapore", 5454000),
    ("クアラルンプール", "Kuala Lumpur", 3.1390, 101.6869, "MY", "Kuala Lumpur", 1808000),
    ("ペナン", "George Town", 5.4145, 100.3292, "MY", "Penang", 708000),
    ("ジャカルタ", "Jakarta", -6.2088, 106.8456, "ID", "Jakarta", 10770000),
    ("バリ島", "Denpasar", -8.6705, 115.2126, "ID", "Bali", 897000),
    ("マニラ", "Manila", 14.5995, 120.9842, "PH", "NCR", 1780000),
    ("セブ", "Cebu", 10.3157, 123.8854, "PH", "Cebu", 922000),
    ("ハノイ", "Hanoi", 21.0285, 105.8542, "VN", "Hanoi", 8054000),
    ("ホーチミン", "Ho Chi Minh City", 10.8231, 106.6297, "VN", "Ho Chi Minh", 8993000),
    ("ダナン", "Da Nang", 16.0544, 108.2022, "VN", "Da Nang", 1134000),
    ("プノンペン", "Phnom Penh", 11.5564, 104.9282, "KH", "Phnom Penh", 2129000),
    ("ヴィエンチャン", "Vientiane", 17.9757, 102.6331, "LA", "Vientiane", 948000),
    ("ヤンゴン", "Yangon", 16.8409, 96.1735, "MM", "Yangon", 5160000),
    # South Asia
    ("デリー", "Delhi", 28.7041, 77.1025, "IN", "Delhi", 16787000),
    ("ムンバイ", "Mumbai", 19.0760, 72.8777, "IN", "Maharashtra", 20411000),
    ("バンガロール", "Bangalore", 12.9716, 77.5946, "IN", "Karnataka", 8443000),
    ("コルカタ", "Kolkata", 22.5726, 88.3639, "IN", "West Bengal", 14850000),
    ("チェンナイ", "Chennai", 13.0827, 80.2707, "IN", "Tamil Nadu", 10971000),
    ("ハイデラバード", "Hyderabad", 17.3850, 78.4867, "IN", "Telangana", 10269000),
    ("カラチ", "Karachi", 24.8607, 67.0011, "PK", "Sindh", 16094000),
    ("イスラマバード", "Islamabad", 33.6844, 73.0479, "PK", "Islamabad", 1015000),
    ("ダッカ", "Dhaka", 23.8103, 90.4125, "BD", "Dhaka", 9540000),
    ("コロンボ", "Colombo", 6.9271, 79.8612, "LK", "Western", 753000),
    ("カトマンズ", "Kathmandu", 27.7172, 85.3240, "NP", "Bagmati", 975000),
    # Middle East
    ("ドバイ", "Dubai", 25.2048, 55.2708, "AE", "Dubai", 3331000),
    ("アブダビ", "Abu Dhabi", 24.4539, 54.3773, "AE", "Abu Dhabi", 1483000),
    ("リヤド", "Riyadh", 24.7136, 46.6753, "SA", "Riyadh", 7676000),
    ("ジッダ", "Jeddah", 21.4858, 39.1925, "SA", "Mecca", 4697000),
    ("ドーハ", "Doha", 25.2854, 51.5310, "QA", "Doha", 1850000),
    ("クウェート", "Kuwait City", 29.3759, 47.9774, "KW", "Capital", 240000),
    ("マナーマ", "Manama", 26.2235, 50.5876, "BH", "Capital", 157000),
    ("マスカット", "Muscat", 23.5880, 58.3829, "OM", "Muscat", 1560000),
    ("テヘラン", "Tehran", 35.6892, 51.3890, "IR", "Tehran", 9384000),
    ("テルアビブ", "Tel Aviv", 32.0853, 34.7818, "IL", "Tel Aviv", 460000),
    ("エルサレム", "Jerusalem", 31.7683, 35.2137, "IL", "Jerusalem", 936000),
    ("ベイルート", "Beirut", 33.8938, 35.5018, "LB", "Beirut", 361000),
    ("アンマン", "Amman", 31.9454, 35.9284, "JO", "Amman", 4007000),
]


# ────────────────────────────────────────────────────────────
# Americas (除 US) — Canada, Mexico, Central/South America
# ────────────────────────────────────────────────────────────
AMERICAS_CITIES = [
    ("トロント", "Toronto", 43.6532, -79.3832, "CA", "Ontario", 2930000),
    ("モントリオール", "Montreal", 45.5017, -73.5673, "CA", "Quebec", 1762000),
    ("バンクーバー", "Vancouver", 49.2827, -123.1207, "CA", "British Columbia", 675000),
    ("カルガリー", "Calgary", 51.0447, -114.0719, "CA", "Alberta", 1336000),
    ("オタワ", "Ottawa", 45.4215, -75.6972, "CA", "Ontario", 1017000),
    ("エドモントン", "Edmonton", 53.5461, -113.4938, "CA", "Alberta", 981000),
    ("ケベックシティ", "Quebec City", 46.8139, -71.2080, "CA", "Quebec", 542000),
    ("メキシコシティ", "Mexico City", 19.4326, -99.1332, "MX", "Mexico City", 9209000),
    ("グアダラハラ", "Guadalajara", 20.6597, -103.3496, "MX", "Jalisco", 1495000),
    ("モンテレイ", "Monterrey", 25.6866, -100.3161, "MX", "Nuevo León", 1135000),
    ("カンクン", "Cancún", 21.1619, -86.8515, "MX", "Quintana Roo", 888000),
    ("グアテマラシティ", "Guatemala City", 14.6349, -90.5069, "GT", "Guatemala", 996000),
    ("ハバナ", "Havana", 23.1136, -82.3666, "CU", "Havana", 2130000),
    ("サンホセ", "San José", 9.9281, -84.0907, "CR", "San José", 343000),
    ("パナマシティ", "Panama City", 8.9824, -79.5199, "PA", "Panamá", 880000),
    ("ボゴタ", "Bogotá", 4.7110, -74.0721, "CO", "Bogotá", 7412000),
    ("メデリン", "Medellín", 6.2476, -75.5658, "CO", "Antioquia", 2530000),
    ("カラカス", "Caracas", 10.4806, -66.9036, "VE", "Capital District", 1943000),
    ("キト", "Quito", -0.1807, -78.4678, "EC", "Pichincha", 1620000),
    ("リマ", "Lima", -12.0464, -77.0428, "PE", "Lima", 9751000),
    ("サンティアゴ", "Santiago", -33.4489, -70.6693, "CL", "Santiago", 6160000),
    ("ブエノスアイレス", "Buenos Aires", -34.6037, -58.3816, "AR", "Buenos Aires", 3075000),
    ("モンテビデオ", "Montevideo", -34.9011, -56.1645, "UY", "Montevideo", 1383000),
    ("サンパウロ", "São Paulo", -23.5505, -46.6333, "BR", "São Paulo", 12325000),
    ("リオデジャネイロ", "Rio de Janeiro", -22.9068, -43.1729, "BR", "Rio de Janeiro", 6748000),
    ("ブラジリア", "Brasília", -15.7942, -47.8825, "BR", "Federal District", 3055000),
    ("サルバドール", "Salvador", -12.9714, -38.5014, "BR", "Bahia", 2886000),
]


# ────────────────────────────────────────────────────────────
# Africa
# ────────────────────────────────────────────────────────────
AFRICA_CITIES = [
    ("カイロ", "Cairo", 30.0444, 31.2357, "EG", "Cairo", 9540000),
    ("アレクサンドリア", "Alexandria", 31.2001, 29.9187, "EG", "Alexandria", 5200000),
    ("ラゴス", "Lagos", 6.5244, 3.3792, "NG", "Lagos", 15388000),
    ("アブジャ", "Abuja", 9.0765, 7.3986, "NG", "FCT", 3279000),
    ("ナイロビ", "Nairobi", -1.2921, 36.8219, "KE", "Nairobi", 4397000),
    ("アディスアベバ", "Addis Ababa", 9.1450, 38.7667, "ET", "Addis Ababa", 3604000),
    ("ヨハネスブルク", "Johannesburg", -26.2041, 28.0473, "ZA", "Gauteng", 5635000),
    ("ケープタウン", "Cape Town", -33.9249, 18.4241, "ZA", "Western Cape", 4618000),
    ("ダーバン", "Durban", -29.8587, 31.0218, "ZA", "KwaZulu-Natal", 3442000),
    ("カサブランカ", "Casablanca", 33.5731, -7.5898, "MA", "Casablanca-Settat", 3360000),
    ("ラバト", "Rabat", 34.0209, -6.8416, "MA", "Rabat-Salé-Kénitra", 580000),
    ("マラケシュ", "Marrakech", 31.6295, -7.9811, "MA", "Marrakech-Safi", 928000),
    ("チュニス", "Tunis", 36.8065, 10.1815, "TN", "Tunis", 638000),
    ("ダカール", "Dakar", 14.7167, -17.4677, "SN", "Dakar", 1146000),
    ("アクラ", "Accra", 5.6037, -0.1870, "GH", "Greater Accra", 2291000),
]


# ────────────────────────────────────────────────────────────
# Oceania
# ────────────────────────────────────────────────────────────
OCEANIA_CITIES = [
    ("シドニー", "Sydney", -33.8688, 151.2093, "AU", "New South Wales", 5312000),
    ("メルボルン", "Melbourne", -37.8136, 144.9631, "AU", "Victoria", 5078000),
    ("ブリスベン", "Brisbane", -27.4698, 153.0251, "AU", "Queensland", 2462000),
    ("パース", "Perth", -31.9523, 115.8613, "AU", "Western Australia", 2059000),
    ("アデレード", "Adelaide", -34.9285, 138.6007, "AU", "South Australia", 1345000),
    ("キャンベラ", "Canberra", -35.2809, 149.1300, "AU", "ACT", 431000),
    ("ゴールドコースト", "Gold Coast", -28.0167, 153.4000, "AU", "Queensland", 679000),
    ("オークランド", "Auckland", -36.8485, 174.7633, "NZ", "Auckland", 1486000),
    ("ウェリントン", "Wellington", -41.2865, 174.7762, "NZ", "Wellington", 215000),
    ("クライストチャーチ", "Christchurch", -43.5320, 172.6362, "NZ", "Canterbury", 383000),
    ("ホニアラ", "Honiara", -9.4438, 159.9498, "SB", "Honiara", 84000),
    ("スバ", "Suva", -18.1416, 178.4419, "FJ", "Central", 88000),
]


def all_cities():
    """全リストを連結 + 重複除去 (英名+国コードで判定)。"""
    src = (
        JP_CITIES + US_CITIES + EU_CITIES + ASIA_CITIES
        + AMERICAS_CITIES + AFRICA_CITIES + OCEANIA_CITIES
    )
    seen = set()
    deduped = []
    for c in src:
        key = (c[1], c[4])  # nameEN + country
        if key in seen:
            continue
        seen.add(key)
        deduped.append(c)
    return deduped


# ────────────────────────────────────────────────────────────
# Dart 出力
# ────────────────────────────────────────────────────────────
DART_HEADER = '''// GENERATED FILE — DO NOT EDIT BY HAND
// Source: apps/solara/tools/generate_world_cities.py
// Regenerate: python apps/solara/tools/generate_world_cities.py
//
// Solara (ii) AI 相談 Stage 2 用 キュレート都市リスト。
// 設計: docs/pro_candidates.md §7.2 Stage 2
//
// 各 CityEntry は consultation_engine.dart の候補生成に使う。

class CityEntry {
  final String nameJP;
  final String nameEN;
  final double lat;
  final double lng;
  final String country; // ISO 2-letter
  final String region;
  final int population;

  const CityEntry({
    required this.nameJP,
    required this.nameEN,
    required this.lat,
    required this.lng,
    required this.country,
    required this.region,
    required this.population,
  });
}

'''

DART_FOOTER = '''
/// 国コード → カバー領域 (大まかな bbox 中心、UI で region picker に使う想定)。
/// 範囲指定モードで「JP」「US」「Europe」等の大ブロック選択を可能にする。
const Map<String, String> worldCityRegionGroups = {
  'JP': '日本',
  'US': '北米',
  'CA': '北米',
  'MX': '北米',
  'GB': 'ヨーロッパ',
  'FR': 'ヨーロッパ',
  'DE': 'ヨーロッパ',
  'IT': 'ヨーロッパ',
  'ES': 'ヨーロッパ',
  'NL': 'ヨーロッパ',
  'BE': 'ヨーロッパ',
  'CH': 'ヨーロッパ',
  'AT': 'ヨーロッパ',
  'PT': 'ヨーロッパ',
  'IE': 'ヨーロッパ',
  'DK': 'ヨーロッパ',
  'SE': 'ヨーロッパ',
  'NO': 'ヨーロッパ',
  'FI': 'ヨーロッパ',
  'IS': 'ヨーロッパ',
  'PL': 'ヨーロッパ',
  'CZ': 'ヨーロッパ',
  'HU': 'ヨーロッパ',
  'GR': 'ヨーロッパ',
  'RO': 'ヨーロッパ',
  'BG': 'ヨーロッパ',
  'RS': 'ヨーロッパ',
  'HR': 'ヨーロッパ',
  'SI': 'ヨーロッパ',
  'SK': 'ヨーロッパ',
  'EE': 'ヨーロッパ',
  'LV': 'ヨーロッパ',
  'LT': 'ヨーロッパ',
  'BY': 'ヨーロッパ',
  'LU': 'ヨーロッパ',
  'TR': 'ヨーロッパ',
  'RU': 'ヨーロッパ',
  'UA': 'ヨーロッパ',
  'CN': 'アジア',
  'HK': 'アジア',
  'MO': 'アジア',
  'KR': 'アジア',
  'TW': 'アジア',
  'TH': 'アジア',
  'SG': 'アジア',
  'MY': 'アジア',
  'ID': 'アジア',
  'PH': 'アジア',
  'VN': 'アジア',
  'KH': 'アジア',
  'LA': 'アジア',
  'MM': 'アジア',
  'IN': 'アジア',
  'PK': 'アジア',
  'BD': 'アジア',
  'LK': 'アジア',
  'NP': 'アジア',
  'AE': '中東',
  'SA': '中東',
  'QA': '中東',
  'KW': '中東',
  'BH': '中東',
  'OM': '中東',
  'IR': '中東',
  'IL': '中東',
  'LB': '中東',
  'JO': '中東',
  'EG': 'アフリカ',
  'NG': 'アフリカ',
  'KE': 'アフリカ',
  'ET': 'アフリカ',
  'ZA': 'アフリカ',
  'MA': 'アフリカ',
  'TN': 'アフリカ',
  'SN': 'アフリカ',
  'GH': 'アフリカ',
  'GT': '中南米',
  'CU': '中南米',
  'CR': '中南米',
  'PA': '中南米',
  'CO': '中南米',
  'VE': '中南米',
  'EC': '中南米',
  'PE': '中南米',
  'CL': '中南米',
  'AR': '中南米',
  'UY': '中南米',
  'BR': '中南米',
  'AU': 'オセアニア',
  'NZ': 'オセアニア',
  'SB': 'オセアニア',
  'FJ': 'オセアニア',
};
'''


def escape_dart(s: str) -> str:
    return s.replace('\\', '\\\\').replace("'", "\\'")


def emit_dart(cities) -> str:
    lines = [DART_HEADER]
    lines.append('/// キュレート都市リスト ({} 件)。'.format(len(cities)))
    lines.append('/// 生成元: apps/solara/tools/generate_world_cities.py')
    lines.append('const List<CityEntry> worldCities = [')
    for nameJP, nameEN, lat, lng, country, region, pop in cities:
        lines.append(
            "  CityEntry(nameJP: '{}', nameEN: '{}', lat: {:.4f}, lng: {:.4f}, "
            "country: '{}', region: '{}', population: {}),".format(
                escape_dart(nameJP),
                escape_dart(nameEN),
                lat,
                lng,
                escape_dart(country),
                escape_dart(region),
                pop,
            )
        )
    lines.append('];')
    lines.append(DART_FOOTER)
    return '\n'.join(lines)


def main():
    cities = all_cities()
    output = emit_dart(cities)

    here = Path(__file__).resolve().parent
    target = here.parent / 'lib' / 'utils' / 'world_cities.dart'
    target.write_text(output, encoding='utf-8')

    # 集計レポート
    by_country = {}
    for c in cities:
        by_country.setdefault(c[4], 0)
        by_country[c[4]] += 1

    print('Generated:', target)
    print('Total cities:', len(cities))
    print('Countries:', len(by_country))
    print('Top countries (by entry count):')
    for cc, n in sorted(by_country.items(), key=lambda x: -x[1])[:10]:
        print('  {}: {}'.format(cc, n))


if __name__ == '__main__':
    main()
