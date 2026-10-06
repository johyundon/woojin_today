// Open-Meteo 날씨 응답 파싱 로직을 고정된 JSON 픽스처로 검증한다.
// 실제 외부 API 호출(네트워크)은 하지 않고 http.testing.MockClient로 대체한다.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/services/weather_service.dart';

const _fixtureJson = '''
{
  "current": {
    "temperature_2m": 18.5,
    "relative_humidity_2m": 55,
    "apparent_temperature": 17.9,
    "precipitation": 0.0,
    "weather_code": 3,
    "wind_speed_10m": 4.2
  },
  "hourly": {
    "time": ["2026-10-06T00:00", "2026-10-06T01:00"],
    "temperature_2m": [15.0, 14.5],
    "precipitation": [0.0, 0.1],
    "precipitation_probability": [10, 20],
    "weather_code": [1, 2]
  },
  "daily": {
    "time": ["2026-10-06", "2026-10-07"],
    "temperature_2m_max": [20.1, 21.3],
    "temperature_2m_min": [10.2, 11.0],
    "precipitation_sum": [0.0, 2.5],
    "precipitation_probability_max": [10, 60],
    "weather_code": [3, 61]
  }
}
''';

void main() {
  group('WeatherService.fetchWeather', () {
    test('정상 JSON 응답을 WeatherResponse로 파싱한다', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          _fixtureJson,
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final service = WeatherService(client: mockClient);

      final result = await service.fetchWeather();

      expect(result.currentTemp, 18.5);
      expect(result.currentWeatherCode, 3);
      expect(result.currentPrecipitation, 0.0);

      expect(result.hourly, hasLength(2));
      expect(result.hourly[0].time, '2026-10-06T00:00');
      expect(result.hourly[0].temperature, 15.0);
      expect(result.hourly[0].weatherCode, 1);
      expect(result.hourly[1].weatherCode, 2);

      expect(result.daily, hasLength(2));
      expect(result.daily[0].date, '2026-10-06');
      expect(result.daily[0].tempMax, 20.1);
      expect(result.daily[0].tempMin, 10.2);
      expect(result.daily[0].precipitationSum, 0.0);
      expect(result.daily[0].precipitationProbabilityMax, 10);
      expect(result.daily[0].weatherCode, 3);
      expect(result.daily[1].precipitationProbabilityMax, 60);
    });

    test('요청 쿼리 파라미터가 명세대로 고정값으로 조립된다', () async {
      Uri? capturedUri;
      final mockClient = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(_fixtureJson, 200);
      });
      final service = WeatherService(client: mockClient);

      await service.fetchWeather();

      expect(capturedUri, isNotNull);
      final query = capturedUri!.queryParameters;
      expect(query['latitude'], '37.8708627');
      expect(query['longitude'], '127.1568845');
      expect(
        query['current'],
        'temperature_2m,relative_humidity_2m,apparent_temperature,'
        'precipitation,weather_code,wind_speed_10m',
      );
      expect(
        query['hourly'],
        'temperature_2m,precipitation,precipitation_probability,'
        'weather_code',
      );
      expect(
        query['daily'],
        'temperature_2m_max,temperature_2m_min,precipitation_sum,'
        'precipitation_probability_max,weather_code',
      );
      expect(query['timezone'], 'Asia/Seoul');
      expect(query['forecast_days'], '7');
    });

    test('서버가 200이 아닌 상태 코드를 반환하면 WeatherServerException을 던진다', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });
      final service = WeatherService(client: mockClient);

      expect(
        () => service.fetchWeather(),
        throwsA(isA<WeatherServerException>()),
      );
    });

    test('응답이 JSON이 아니면 WeatherParseException을 던진다', () async {
      final mockClient = MockClient((request) async {
        return http.Response('<html>not json</html>', 200);
      });
      final service = WeatherService(client: mockClient);

      expect(
        () => service.fetchWeather(),
        throwsA(isA<WeatherParseException>()),
      );
    });

    test('JSON이지만 기대한 필드 구조가 아니면 WeatherParseException을 던진다', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'unexpected': 'shape'}), 200);
      });
      final service = WeatherService(client: mockClient);

      expect(
        () => service.fetchWeather(),
        throwsA(isA<WeatherParseException>()),
      );
    });

    test('네트워크 예외가 발생하면 WeatherNetworkException을 던진다', () async {
      final mockClient = MockClient((request) async {
        throw const SocketExceptionStub();
      });
      final service = WeatherService(client: mockClient);

      expect(
        () => service.fetchWeather(),
        throwsA(isA<WeatherNetworkException>()),
      );
    });
  });
}

/// MockClient 핸들러에서 네트워크 예외를 흉내내기 위한 간단한 Exception.
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}
