import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// 미세먼지 등급(한국 환경부 기준 4단계).
enum AirGrade {
  good('좋음'),
  normal('보통'),
  bad('나쁨'),
  veryBad('매우 나쁨');

  const AirGrade(this.label);

  final String label;
}

/// 현재 미세먼지(PM10)/초미세먼지(PM2.5) 농도(㎍/㎥). 값이 없으면 null.
class AirQuality {
  const AirQuality({this.pm10, this.pm25});

  final double? pm10;
  final double? pm25;

  factory AirQuality.fromJson(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>;
    return AirQuality(
      pm10: (current['pm10'] as num?)?.toDouble(),
      pm25: (current['pm2_5'] as num?)?.toDouble(),
    );
  }

  /// PM10과 PM2.5 등급 중 더 나쁜 쪽. 둘 다 값이 없으면 null.
  AirGrade? get grade {
    final grades = [
      if (pm10 != null) _grade(pm10!, const [30, 80, 150]),
      if (pm25 != null) _grade(pm25!, const [15, 35, 75]),
    ];
    if (grades.isEmpty) return null;
    return grades.reduce((a, b) => a.index >= b.index ? a : b);
  }

  /// [limits] = 좋음/보통/나쁨의 상한(이하). 그 위는 매우 나쁨.
  static AirGrade _grade(double value, List<int> limits) {
    if (value <= limits[0]) return AirGrade.good;
    if (value <= limits[1]) return AirGrade.normal;
    if (value <= limits[2]) return AirGrade.bad;
    return AirGrade.veryBad;
  }
}

/// Open-Meteo 대기질 API로 캠퍼스 좌표의 현재 미세먼지를 조회한다. 날씨와
/// 같은 무료 서비스라 로그인/세션이 필요 없다. 실패하면 예외를 던지고,
/// 호출한 쪽에서 "미세먼지 정보 없음"으로 처리한다.
class AirQualityService {
  static const _endpoint =
      'https://air-quality-api.open-meteo.com/v1/air-quality';

  // 날씨 조회와 같은 캠퍼스 좌표.
  static const _queryParameters = <String, String>{
    'latitude': '37.8708627',
    'longitude': '127.1568845',
    'current': 'pm10,pm2_5',
    'timezone': 'Asia/Seoul',
  };

  final http.Client _client;

  AirQualityService({http.Client? client}) : _client = client ?? http.Client();

  Future<AirQuality> fetchAirQuality() async {
    final uri = Uri.parse(_endpoint).replace(queryParameters: _queryParameters);
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('대기질 서버 오류 (${response.statusCode})');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    return AirQuality.fromJson(decoded as Map<String, dynamic>);
  }
}
