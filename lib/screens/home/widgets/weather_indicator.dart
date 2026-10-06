import 'package:flutter/material.dart';

import '../../../services/weather_service.dart';
import '../home_colors.dart';

/// Headline 우측의 날씨 아이콘/온도 영역. 로딩 중에는 작은 스피너,
/// 에러 시에는 cloud_off 아이콘, 성공 시에는 날씨 아이콘 + 현재 온도를 보여준다.
/// 성공 상태일 때만 [onTap]을 걸어 날씨 상세 모달을 열 수 있게 한다 — 로딩/에러
/// 상태는 보여줄 데이터가 없으므로 누를 수 없다.
class WeatherIndicator extends StatelessWidget {
  const WeatherIndicator({
    required this.colors,
    required this.weatherLoading,
    required this.weatherHasError,
    required this.weatherData,
    this.onTap,
  });

  final HomeColors colors;
  final bool weatherLoading;
  final bool weatherHasError;
  final WeatherResponse? weatherData;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (weatherLoading) {
      return const SizedBox(
        width: 44,
        height: 44,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    final weather = weatherData;
    if (weatherHasError || weather == null) {
      return Icon(Icons.cloud_off, color: colors.textSecondary, size: 44);
    }

    final display = weatherDisplay(weather.currentWeatherCode);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Icon(display.icon, color: const Color(0xFFFFC452), size: 36),
          const SizedBox(height: 4),
          Text(
            '${weather.currentTemp.round()}°C',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// WMO Weather Code(현재 날씨 코드)를 아이콘+한글 라벨로 단순 매핑한다.
/// 전체 코드 표를 그대로 옮기지 않고, 명세에서 언급한 자주 쓰는 범위만
/// 구간으로 묶어서 구분한다:
/// 0=맑음, 1~3=대체로 흐림, 45·48=안개, 51~67=비, 71~77=눈, 80~82=소나기,
/// 95~99=뇌우. 그 외 값은 "알 수 없음"으로 처리한다.
///
/// 날씨 상세 모달(weather_detail_dialog.dart)에서도 같은 매핑을 쓰므로
/// public으로 둔다.
({IconData icon, String label}) weatherDisplay(int code) {
  if (code == 0) return (icon: Icons.wb_sunny, label: '맑음');
  if (code >= 1 && code <= 3) return (icon: Icons.cloud, label: '흐림');
  if (code == 45 || code == 48) return (icon: Icons.foggy, label: '안개');
  if (code >= 51 && code <= 67) return (icon: Icons.umbrella, label: '비');
  if (code >= 71 && code <= 77) return (icon: Icons.ac_unit, label: '눈');
  if (code >= 80 && code <= 82) return (icon: Icons.grain, label: '소나기');
  if (code >= 95 && code <= 99) {
    return (icon: Icons.thunderstorm, label: '뇌우');
  }
  return (icon: Icons.cloud, label: '알 수 없음');
}
