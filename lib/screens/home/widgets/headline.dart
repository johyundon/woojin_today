import 'package:flutter/material.dart';

import '../../../services/weather_service.dart';
import '../home_colors.dart';
import 'weather_indicator.dart';

/// "오늘은 무얼 같이 해볼까요?" 헤드라인 + 날씨 아이콘.
///
/// 날씨는 로딩/성공/에러 3가지 상태를 구분해서 보여준다. 성공 시에는
/// [WeatherResponse.currentWeatherCode](WMO Weather Code)를
/// 아이콘+한글 라벨로 바꾸고, 현재 온도를 함께 표시한다.
/// 에러 시에는 원인(네트워크/서버/파싱)과 무관하게 아이콘만 조용히
/// cloud_off로 바꾼다 — 이 화면에 스낵바/다이얼로그 등 방해되는 UI는 쓰지 않는다.
class Headline extends StatelessWidget {
  const Headline({
    required this.colors,
    required this.weatherLoading,
    required this.weatherHasError,
    required this.weatherData,
  });

  final HomeColors colors;
  final bool weatherLoading;
  final bool weatherHasError;
  final WeatherResponse? weatherData;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            '오늘은 무얼\n같이 해볼까요?',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
        ),
        WeatherIndicator(
          colors: colors,
          weatherLoading: weatherLoading,
          weatherHasError: weatherHasError,
          weatherData: weatherData,
        ),
      ],
    );
  }
}
