// 지도를 누른 자리에서 가장 가까운 건물을 고르는지 확인한다.

import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/screens/campus_map/models/campus_building.dart';
import 'package:daejin_app/screens/campus_map/models/geo_point.dart';

void main() {
  test('중앙도서관 좌표 바로 옆을 누르면 중앙도서관', () {
    final b = nearestCampusBuilding(
      const GeoPoint(lat: 37.87343, lng: 127.15493),
    );
    expect(b?.name, '중앙도서관');
  });

  test('건물 안 가게(중앙도서관 그라찌에) 좌표를 눌러도 건물이 잡힌다', () {
    final b = nearestCampusBuilding(
      const GeoPoint(lat: 37.8735394, lng: 127.1550485),
    );
    expect(b?.name, '중앙도서관');
  });

  test('좌표가 같은 학생회관과 가게 중엔 학생회관', () {
    final b = nearestCampusBuilding(
      const GeoPoint(lat: 37.8711868, lng: 127.1551837),
    );
    expect(b?.name, '학생회관');
  });

  test('건물에서 먼 곳(60m 넘게)을 누르면 null', () {
    final b = nearestCampusBuilding(const GeoPoint(lat: 37.88, lng: 127.17));
    expect(b, isNull);
  });
}
