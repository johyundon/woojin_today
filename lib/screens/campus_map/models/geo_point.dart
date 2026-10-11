import 'dart:math' as math;

/// 위경도 좌표 하나. 카카오맵 SDK의 LatLng와 별개로, 지도 플러그인에
/// 의존하지 않는 순수 모델로 둬서 경로 계산 로직을 플러그인 없이도
/// 테스트할 수 있게 한다.
class GeoPoint {
  const GeoPoint({required this.lat, required this.lng});

  final double lat;
  final double lng;

  @override
  bool operator ==(Object other) =>
      other is GeoPoint && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);

  @override
  String toString() => 'GeoPoint($lat, $lng)';
}

/// 두 좌표 사이의 실측 거리(미터). 캠퍼스 규모(수백 m~수 km)에서는 지구
/// 곡률 영향이 미미하지만, 위도마다 경도 1도의 실제 거리가 달라지는 문제는
/// 있어 하버사인 공식을 쓴다.
double haversineMeters(GeoPoint a, GeoPoint b) {
  const earthRadiusMeters = 6371000.0;
  final dLat = _degToRad(b.lat - a.lat);
  final dLng = _degToRad(b.lng - a.lng);
  final sinDLat = math.sin(dLat / 2);
  final sinDLng = math.sin(dLng / 2);
  final h =
      sinDLat * sinDLat +
      math.cos(_degToRad(a.lat)) *
          math.cos(_degToRad(b.lat)) *
          sinDLng *
          sinDLng;
  return 2 * earthRadiusMeters * math.asin(math.sqrt(h.clamp(0, 1)));
}

double _degToRad(double deg) => deg * math.pi / 180;
