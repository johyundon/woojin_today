import 'package:geolocator/geolocator.dart';

import '../models/geo_point.dart';

/// 기기의 현재 위치를 한 번 읽어 온다.
///
/// 위치 권한은 처음 부를 때만 묻고, 거부했거나 위치 서비스가 꺼져 있거나
/// 읽다가 실패하면 조용히 null을 돌려준다(지도는 파란 점 없이 그대로 쓴다).
class CurrentLocationService {
  const CurrentLocationService();

  Future<GeoPoint?> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 6),
        ),
      );
      return GeoPoint(lat: position.latitude, lng: position.longitude);
    } catch (_) {
      // 새 위치를 제때 못 받으면 기기가 마지막으로 알던 위치라도 쓴다.
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last == null) return null;
        return GeoPoint(lat: last.latitude, lng: last.longitude);
      } catch (_) {
        return null;
      }
    }
  }
}
