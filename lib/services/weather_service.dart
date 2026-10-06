import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// `GET https://api.open-meteo.com/v1/forecast` 응답.
///
/// 요청 쿼리에는 `current`/`hourly`에 더 많은 필드를 넣지만(명세에 그렇게
/// 정의돼 있음), 실제로 쓰는 건 current 3개(temperature_2m, weather_code,
/// precipitation)와 hourly 3개(time, temperature_2m, weather_code)뿐이다.
/// daily는 요청한 5개 필드를 전부 사용한다.
class WeatherResponse {
  const WeatherResponse({
    required this.currentTemp,
    required this.currentWeatherCode,
    required this.currentPrecipitation,
    required this.hourly,
    required this.daily,
  });

  final double currentTemp;
  final int currentWeatherCode;
  final double currentPrecipitation;
  final List<HourlyWeather> hourly;
  final List<DailyWeather> daily;

  factory WeatherResponse.fromJson(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>;
    final hourly = json['hourly'] as Map<String, dynamic>;
    final daily = json['daily'] as Map<String, dynamic>;

    final hourlyTime = hourly['time'] as List<dynamic>;
    final hourlyTemp = hourly['temperature_2m'] as List<dynamic>;
    final hourlyCode = hourly['weather_code'] as List<dynamic>;

    final dailyDate = daily['time'] as List<dynamic>;
    final dailyTempMax = daily['temperature_2m_max'] as List<dynamic>;
    final dailyTempMin = daily['temperature_2m_min'] as List<dynamic>;
    final dailyPrecipitationSum = daily['precipitation_sum'] as List<dynamic>;
    final dailyPrecipitationProbabilityMax =
        daily['precipitation_probability_max'] as List<dynamic>;
    final dailyCode = daily['weather_code'] as List<dynamic>;

    return WeatherResponse(
      currentTemp: (current['temperature_2m'] as num).toDouble(),
      currentWeatherCode: (current['weather_code'] as num).toInt(),
      currentPrecipitation: (current['precipitation'] as num).toDouble(),
      hourly: List.generate(
        hourlyTime.length,
        (i) => HourlyWeather(
          time: hourlyTime[i] as String,
          temperature: (hourlyTemp[i] as num).toDouble(),
          weatherCode: (hourlyCode[i] as num).toInt(),
        ),
      ),
      daily: List.generate(
        dailyDate.length,
        (i) => DailyWeather(
          date: dailyDate[i] as String,
          tempMax: (dailyTempMax[i] as num).toDouble(),
          tempMin: (dailyTempMin[i] as num).toDouble(),
          precipitationSum: (dailyPrecipitationSum[i] as num).toDouble(),
          precipitationProbabilityMax:
              (dailyPrecipitationProbabilityMax[i] as num).toInt(),
          weatherCode: (dailyCode[i] as num).toInt(),
        ),
      ),
    );
  }
}

/// hourly 응답 한 시점의 데이터. precipitation/precipitation_probability는
/// 쿼리에는 요청하지만 명세상 쓰지 않는다.
class HourlyWeather {
  const HourlyWeather({
    required this.time,
    required this.temperature,
    required this.weatherCode,
  });

  final String time;
  final double temperature;
  final int weatherCode;
}

/// daily 응답 하루치 데이터. 요청한 5개 필드를 전부 사용한다.
class DailyWeather {
  const DailyWeather({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.precipitationSum,
    required this.precipitationProbabilityMax,
    required this.weatherCode,
  });

  final String date;
  final double tempMax;
  final double tempMin;
  final double precipitationSum;
  final int precipitationProbabilityMax;
  final int weatherCode;
}

/// 날씨 조회 요청이 실패한 원인. "네트워크 연결 실패/타임아웃"과
/// "서버는 응답했지만 비정상(status != 200)"과 "응답은 받았지만 JSON
/// 구조가 기대와 다름(파싱 실패)"은 서로 다른 실패 사유이므로 구분한다.
sealed class WeatherException implements Exception {
  const WeatherException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 네트워크 연결 실패 또는 타임아웃.
class WeatherNetworkException extends WeatherException {
  const WeatherNetworkException(super.message);
}

/// 서버가 200이 아닌 상태 코드로 응답한 경우.
class WeatherServerException extends WeatherException {
  const WeatherServerException(super.message);
}

/// 응답 바디가 JSON이 아니거나, 기대한 필드/구조가 없는 경우.
class WeatherParseException extends WeatherException {
  const WeatherParseException(super.message);
}

/// Open-Meteo 무료 API(`GET /v1/forecast`)로 캠퍼스 좌표 고정 날씨를 조회한다.
/// 학교 서버와 무관한 외부 API라 선행 로그인/세션이 필요 없다.
class WeatherService {
  static const _endpoint = 'https://api.open-meteo.com/v1/forecast';

  // 캠퍼스 좌표 고정 — 명세에 정의된 고정 쿼리 파라미터.
  static const _queryParameters = <String, String>{
    'latitude': '37.8708627',
    'longitude': '127.1568845',
    'current':
        'temperature_2m,relative_humidity_2m,apparent_temperature,'
        'precipitation,weather_code,wind_speed_10m',
    'hourly':
        'temperature_2m,precipitation,precipitation_probability,'
        'weather_code',
    'daily':
        'temperature_2m_max,temperature_2m_min,precipitation_sum,'
        'precipitation_probability_max,weather_code',
    'timezone': 'Asia/Seoul',
    'forecast_days': '7',
  };

  final http.Client _client;

  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  Future<WeatherResponse> fetchWeather() async {
    final uri = Uri.parse(_endpoint).replace(queryParameters: _queryParameters);

    http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 15));
    } on TimeoutException catch (e) {
      throw WeatherNetworkException('요청 시간 초과: $e');
    } catch (e) {
      throw WeatherNetworkException('네트워크 오류: $e');
    }

    if (response.statusCode != 200) {
      throw WeatherServerException('서버 오류 (${response.statusCode})');
    }

    Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      throw WeatherParseException('응답이 올바른 JSON이 아닙니다: $e');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const WeatherParseException('응답 형식이 예상과 다릅니다.');
    }

    try {
      return WeatherResponse.fromJson(decoded);
    } catch (e) {
      throw WeatherParseException('응답 필드 구조가 예상과 다릅니다: $e');
    }
  }
}
