// Unit test: googleMapsUrlForHit — 検索結果を Google マップで開く URL の組み立て。
//
// 要件 (オーナー): 座標ピンではなく、店舗/施設のページ (メニュー・営業時間) が
// 開いた状態にしたい。Google Places 経路は place_id を query_place_id に乗せて
// place card を直接開く。Nominatim 経路は place_id が無いので店名検索に落とす。

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
}
