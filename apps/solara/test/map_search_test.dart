// Unit test: googleMapsUrlForHit — 検索結果を Google マップで開く URL の組み立て。
//
// 要件 (オーナー): 座標ピンではなく、店舗/施設のページ (メニュー・営業時間) が
// 開いた状態にしたい。Google Places 経路は place_id を query_place_id に乗せて
// place card を直接開く。Nominatim 経路は place_id が無いので店名検索に落とす。

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:solara/screens/map/map_search.dart';

void main() {
  group('googleMapsUrlForHit', () {
    test('Google 経路: placeId があれば query_place_id で店舗ページを直接開く', () {
      final hit = SearchHit(
        name: 'スターバックス 渋谷',
        address: '東京都渋谷区道玄坂',
        lat: 35.66,
        lng: 139.70,
        source: 'google',
        placeId: 'ChIJtest123',
      );
      final url = googleMapsUrlForHit(hit);
      expect(url, startsWith('https://www.google.com/maps/search/?api=1&query='));
      expect(url, contains('query_place_id=ChIJtest123'));
      // 店名・住所は URL エンコードされて query に乗る (place_id 解決失敗時の保険)。
      expect(url, contains(Uri.encodeComponent('スターバックス')));
      expect(url, contains(Uri.encodeComponent('道玄坂')));
    });

    test('Nominatim 経路: placeId 無しは query のみ (place card 無し・店名検索)', () {
      final hit = SearchHit(
        name: '鎌倉, 神奈川県, 日本',
        lat: 35.31,
        lng: 139.55,
        source: 'nominatim',
      );
      final url = googleMapsUrlForHit(hit);
      expect(url, contains('query='));
      expect(url, isNot(contains('query_place_id')));
      expect(url, contains(Uri.encodeComponent('鎌倉')));
    });

    test('placeId が空文字なら query_place_id を付けない (防御)', () {
      final hit = SearchHit(
        name: 'Tokyo Tower',
        lat: 35.65,
        lng: 139.74,
        source: 'google',
        placeId: '',
      );
      final url = googleMapsUrlForHit(hit);
      expect(url, isNot(contains('query_place_id')));
    });

    test('名前も住所も空なら座標フォールバック', () {
      final hit = SearchHit(name: '', lat: 35.0, lng: 139.0);
      final url = googleMapsUrlForHit(hit);
      expect(url, contains('query=${Uri.encodeComponent('35.0,139.0')}'));
      expect(url, isNot(contains('query_place_id')));
    });
  });

  // 画面復元 (Android プロセス死対策) の心臓部。検索結果詳細を復元するには
  // SearchHit を SharedPreferences に JSON で保存 → 復元できる必要がある。
  group('SearchHit JSON round-trip (画面復元用)', () {
    test('Google 経路 (全フィールド埋まり) が往復で完全一致する', () {
      final hit = SearchHit(
        name: 'スターバックス 渋谷',
        address: '東京都渋谷区道玄坂',
        lat: 35.661,
        lng: 139.701,
        country: 'JP',
        source: 'google',
        placeId: 'ChIJtest123',
        bestDir: 'NE',
        bestScore: 7.5,
        bestFortune: 'money',
        bestFortuneScore: 6.2,
      );
      final r = SearchHit.fromJson(hit.toJson());
      expect(r.name, hit.name);
      expect(r.address, hit.address);
      expect(r.lat, hit.lat);
      expect(r.lng, hit.lng);
      expect(r.country, hit.country);
      expect(r.source, hit.source);
      expect(r.placeId, hit.placeId);
      expect(r.bestDir, hit.bestDir);
      expect(r.bestScore, hit.bestScore);
      expect(r.bestFortune, hit.bestFortune);
      expect(r.bestFortuneScore, hit.bestFortuneScore);
    });

    test('Nominatim 経路 (address/placeId/score 系が null/0) も往復できる', () {
      final hit = SearchHit(
        name: '鎌倉, 神奈川県, 日本',
        lat: 35.31,
        lng: 139.55,
        source: 'nominatim',
      );
      final r = SearchHit.fromJson(hit.toJson());
      expect(r.name, hit.name);
      expect(r.address, isNull);
      expect(r.placeId, isNull);
      expect(r.country, isNull);
      expect(r.source, 'nominatim');
      expect(r.bestDir, isNull);
      expect(r.bestScore, 0);
      expect(r.bestFortune, isNull);
      expect(r.bestFortuneScore, 0);
    });

    test('リスト全体を JSON encode/decode しても各 hit が一致する', () {
      final hits = [
        SearchHit(
            name: 'A', lat: 1.0, lng: 2.0, source: 'google', placeId: 'p1'),
        SearchHit(name: 'B', lat: 3.5, lng: 4.5),
      ];
      final encoded = json.encode(hits.map((h) => h.toJson()).toList());
      final decoded = (json.decode(encoded) as List)
          .map((e) => SearchHit.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      expect(decoded.length, 2);
      expect(decoded[0].name, 'A');
      expect(decoded[0].placeId, 'p1');
      expect(decoded[1].name, 'B');
      expect(decoded[1].lat, 3.5);
    });
  });
}
