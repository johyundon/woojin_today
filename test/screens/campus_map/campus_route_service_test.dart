import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/screens/campus_map/models/campus_building.dart';
import 'package:daejin_app/screens/campus_map/models/geo_point.dart';
import 'package:daejin_app/screens/campus_map/services/campus_route_service.dart';

GeoPoint _pointOf(String name) {
  final building = campusBuildings.firstWhere((b) => b.name == name);
  return GeoPoint(lat: building.lat, lng: building.lng);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('인문학관 -> 공대 다동 경로는 Figma 레퍼런스(9분·약599m)와 비슷한 범위로 나온다', () async {
    final service = CampusRouteService();
    final route = await service.findRoute(
      origin: _pointOf('인문학관'),
      destination: _pointOf('공대 다동'),
    );

    expect(route.path.first, _pointOf('인문학관'));
    expect(route.path.last, _pointOf('공대 다동'));
    expect(route.distanceMeters, greaterThan(100));
    expect(route.distanceMeters, lessThan(1500));
    expect(route.walkMinutes, greaterThan(0));
  });

  test('같은 건물이면 거리가 0에 가깝다', () async {
    final service = CampusRouteService();
    final route = await service.findRoute(
      origin: _pointOf('본관'),
      destination: _pointOf('본관'),
    );

    expect(route.distanceMeters, lessThan(5));
  });

  test('모든 건물 쌍에 대해 경로 계산이 예외 없이 끝난다', () async {
    final service = CampusRouteService();
    final sample = campusBuildings.take(6).toList();
    for (final a in sample) {
      for (final b in sample) {
        final route = await service.findRoute(
          origin: GeoPoint(lat: a.lat, lng: a.lng),
          destination: GeoPoint(lat: b.lat, lng: b.lng),
        );
        expect(route.distanceMeters, isNotNull);
      }
    }
  });
}
