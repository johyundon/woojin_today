import 'package:daejin_app/services/air_quality_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('AirQuality.grade', () {
    test('PM10/PM2.5 경계값별 등급', () {
      expect(const AirQuality(pm10: 30, pm25: 15).grade, AirGrade.good);
      expect(const AirQuality(pm10: 31, pm25: 10).grade, AirGrade.normal);
      expect(const AirQuality(pm10: 20, pm25: 36).grade, AirGrade.bad);
      expect(const AirQuality(pm10: 151, pm25: 5).grade, AirGrade.veryBad);
    });

    test('둘 중 더 나쁜 등급을 쓴다', () {
      expect(const AirQuality(pm10: 20, pm25: 40).grade, AirGrade.bad);
    });

    test('한쪽만 있어도 등급이 나오고, 둘 다 없으면 null', () {
      expect(const AirQuality(pm25: 50).grade, AirGrade.bad);
      expect(const AirQuality().grade, isNull);
    });
  });

  group('AirQualityService', () {
    test('응답의 current 값을 읽는다', () async {
      final service = AirQualityService(
        client: MockClient((request) async {
          expect(request.url.host, 'air-quality-api.open-meteo.com');
          expect(request.url.queryParameters['current'], 'pm10,pm2_5');
          return http.Response(
            '{"current":{"time":"2026-10-14T10:00","pm10":12.5,"pm2_5":null}}',
            200,
          );
        }),
      );
      final air = await service.fetchAirQuality();
      expect(air.pm10, 12.5);
      expect(air.pm25, isNull);
      expect(air.grade, AirGrade.good);
    });

    test('200이 아니면 예외', () async {
      final service = AirQualityService(
        client: MockClient((_) async => http.Response('', 500)),
      );
      expect(service.fetchAirQuality(), throwsException);
    });
  });
}
