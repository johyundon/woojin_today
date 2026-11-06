import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/air_quality_service.dart';
import '../../services/weather_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pressable.dart';
import '../home/widgets/weather_indicator.dart' show weatherDisplay;

/// 지금부터 몇 시간 뒤의 예보를 시간대 줄에 보여줄지("지금" 다음 5칸).
const _hourOffsets = [1, 2, 3, 5, 8];

/// 비 올 확률이 이 값(%) 이상이면 "비 올 것 같은 날"로 보고 카드 숫자를 회색으로
/// 둔다(아래 조언 문구가 우산을 권하는 기준과 같다).
const _rainyProbability = 50;

/// v7 디자인 49·50 weather에서 옮긴 이 화면 전용 색.
const _tempText = Color(0xFF2B2F3B); // 큰 기온 rgb(43, 47, 59)
const _bigIcon = Color(0xFFB7C2D3); // 큰 카드 오른쪽 날씨 그림 rgb(183, 194, 211)
const _darkText = Color(0xFF2F3347); // 조언 문구·시간대 기온 rgb(47, 51, 71)
const _hourLabel = Color(0xFF6B7280); // 시간대 시각 rgb(107, 114, 128)
const _nowLabel = Color(0xFFDCEAFF); // "지금" 칸 시각 rgb(220, 234, 255)
const _cloudIcon = Color(0xFF7B8494); // 흐림 아이콘 rgb(123, 132, 148)
const _partlyIcon = Color(0xFFE3A53A); // 구름 조금 아이콘 rgb(227, 165, 58)
const _sunIcon = Color(0xFFF2A81D); // 맑음 아이콘 rgb(242, 168, 29)

/// 시간대 줄 아이콘과 색. Flutter 기본 아이콘에는 디자인의 partly_cloudy_day·
/// rainy가 없어 wb_cloudy·umbrella로 대신한다.
({IconData icon, Color color}) _hourIconStyle(int code) {
  if (code == 0) return (icon: Icons.wb_sunny_rounded, color: _sunIcon);
  if (code == 1 || code == 2) {
    return (icon: Icons.wb_cloudy_rounded, color: _partlyIcon);
  }
  if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
    return (icon: Icons.umbrella_rounded, color: AppColors.blue);
  }
  if (code >= 95 && code <= 99) {
    return (icon: Icons.thunderstorm_rounded, color: AppColors.blue);
  }
  return (icon: _iconFor(code), color: _cloudIcon);
}

/// 날씨 코드에 맞는 아이콘(기존 [weatherDisplay] 구분을 둥근 아이콘으로).
IconData _iconFor(int code) {
  if (code == 0) return Icons.wb_sunny_rounded;
  if (code == 45 || code == 48) return Icons.foggy;
  if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
    return Icons.umbrella_rounded;
  }
  if (code >= 71 && code <= 77) return Icons.ac_unit_rounded;
  if (code >= 95 && code <= 99) return Icons.thunderstorm_rounded;
  return Icons.cloud_rounded;
}

/// "오늘 날씨 어때?" 화면(v7 디자인). 캠퍼스 좌표 고정 날씨([WeatherResponse])를
/// 한눈에 보여준다. [now]는 "지금"을 정하는 기준으로, 테스트에서 고정하기 위해
/// 주입할 수 있다.
class WeatherScreen extends StatelessWidget {
  const WeatherScreen({
    required this.weather,
    this.airQuality,
    this.now,
    super.key,
  });

  final WeatherResponse weather;

  /// 미세먼지. 조회에 실패했거나 아직 없으면 null이고, 카드에는 "-"가 뜬다.
  final AirQuality? airQuality;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final current = now ?? DateTime.now();
    final today = weather.daily.first;
    final slots = _hourSlots(current);
    final rainProbability = today.precipitationProbabilityMax;
    final airGrade = airQuality?.grade;

    // 밝은 바탕이라 상태 표시줄 글자를 어둡게 한다.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Pressable.icon(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textStrong,
                          size: 15,
                          semanticLabel: '뒤로',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blueSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: AppColors.blue,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '포천 선단동',
                            style: TextStyle(
                              color: AppColors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '오늘 날씨 어때?',
                      style: TextStyle(
                        color: AppColors.textStrong,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                        letterSpacing: -0.91,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _CurrentCard(
                icon: _iconFor(weather.currentWeatherCode),
                conditionLabel: _conditionLabel(weather.currentWeatherCode),
                temp: weather.currentTemp,
                tempMax: today.tempMax,
                tempMin: today.tempMin,
                apparentTemp: weather.currentApparentTemp,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: _AdviceChip(message: _advice(current)),
              ),
              const SizedBox(height: 11),
              _HourlyStrip(
                nowTemp: weather.currentTemp,
                nowIcon: _iconFor(weather.currentWeatherCode),
                slots: slots,
              ),
              const SizedBox(height: 13),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.umbrella_rounded,
                        label: '비 올 확률',
                        value: '$rainProbability%',
                        // 비 걱정이 없으면 파랑, 높으면(50% 이상) 회색.
                        good: rainProbability < _rainyProbability,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.air_rounded,
                        label: '미세먼지',
                        value: airGrade?.label ?? '-',
                        // 좋음·보통이면 파랑, 나쁨 이상이거나 값이 없으면 회색.
                        good:
                            airGrade == AirGrade.good ||
                            airGrade == AirGrade.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// [now] 기준 [_hourOffsets] 시간 뒤의 (시각 라벨, 아이콘, 기온) 목록. 해당
  /// 시각 데이터가 응답에 없으면 그 칸은 건너뛴다.
  List<_HourSlot> _hourSlots(DateTime now) {
    final byTime = {for (final h in weather.hourly) h.time: h};
    final base = DateTime(now.year, now.month, now.day, now.hour);
    final slots = <_HourSlot>[];
    for (final offset in _hourOffsets) {
      final t = base.add(Duration(hours: offset));
      final key =
          '${t.year}-${_two(t.month)}-${_two(t.day)}T${_two(t.hour)}:00';
      final hour = byTime[key];
      if (hour == null) continue;
      slots.add(
        _HourSlot(
          label: '${t.hour}시',
          style: _hourIconStyle(hour.weatherCode),
          temp: hour.temperature,
        ),
      );
    }
    return slots;
  }

  /// 연한 파랑 말풍선 한 줄 조언. 비 소식이 우선이고, 그다음 저녁(18시) 기온이
  /// 쌀쌀하면 겉옷을 권한다.
  String _advice(DateTime now) {
    final today = weather.daily.first;
    if (today.precipitationProbabilityMax >= 50) {
      return '비 올 확률 ${today.precipitationProbabilityMax}%, 우산 챙겨!';
    }
    final date = today.date;
    for (final h in weather.hourly) {
      if (h.time == '${date}T18:00') {
        return h.temperature <= 15
            ? '저녁엔 ${h.temperature.round()}°, 겉옷 챙겨!'
            : '저녁에도 ${h.temperature.round()}°, 가볍게 입어도 돼!';
      }
    }
    return '오늘은 ${weather.currentTemp.round()}°, 편하게 다녀와!';
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// 큰 카드에 쓰는 상태 문구. 1~3은 "구름 많음"으로 묶는다.
  static String _conditionLabel(int code) =>
      code >= 1 && code <= 3 ? '구름 많음' : weatherDisplay(code).label;
}

class _HourSlot {
  const _HourSlot({
    required this.label,
    required this.style,
    required this.temp,
  });

  final String label;
  final ({IconData icon, Color color}) style;
  final double temp;
}

/// 숫자 뒤에 0.75배 크기의 "°"를 위쪽에 맞춰 붙인다(디자인: 74px 숫자에 55.5px
/// 기호를 5px 아래, 14px 숫자에 10.5px 기호를 1px 아래).
Widget _degreeText(int value, TextStyle style) {
  final size = style.fontSize!;
  return Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('$value', style: style),
      Padding(
        padding: EdgeInsets.only(top: size * 0.07),
        child: Text('°', style: style.copyWith(fontSize: size * 0.75)),
      ),
    ],
  );
}

class _CurrentCard extends StatelessWidget {
  const _CurrentCard({
    required this.icon,
    required this.conditionLabel,
    required this.temp,
    required this.tempMax,
    required this.tempMin,
    required this.apparentTemp,
  });

  final IconData icon;
  final String conditionLabel;
  final double temp;
  final double tempMax;
  final double tempMin;
  final double? apparentTemp;

  @override
  Widget build(BuildContext context) {
    final detail = [
      '최고 ${tempMax.round()}°',
      '최저 ${tempMin.round()}°',
      if (apparentTemp != null) '체감 ${apparentTemp!.round()}°',
    ].join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 오른쪽의 큰 날씨 그림(글자 뒤에 깔린다).
          Positioned(
            right: 2,
            top: 57,
            child: Icon(icon, size: 110, color: _bigIcon),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 22, color: AppColors.blue),
                  const SizedBox(width: 6),
                  Text(
                    '지금 · $conditionLabel',
                    style: const TextStyle(
                      color: AppColors.textBody,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _degreeText(
                temp.round(),
                const TextStyle(
                  color: _tempText,
                  fontSize: 74,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  letterSpacing: -3.33,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                detail,
                style: const TextStyle(
                  color: AppColors.textBody,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdviceChip extends StatelessWidget {
  const _AdviceChip({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(10),
        boxShadow: AppColors.cardShadow,
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: _darkText,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          height: 1.4,
        ),
      ),
    );
  }
}

class _HourlyStrip extends StatelessWidget {
  const _HourlyStrip({
    required this.nowTemp,
    required this.nowIcon,
    required this.slots,
  });

  final double nowTemp;
  final IconData nowIcon;
  final List<_HourSlot> slots;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: _HourCell(
              label: '지금',
              icon: nowIcon,
              iconColor: Colors.white,
              temp: nowTemp,
              highlighted: true,
            ),
          ),
          for (final slot in slots) ...[
            const SizedBox(width: 4),
            Expanded(
              child: _HourCell(
                label: slot.label,
                icon: slot.style.icon,
                iconColor: slot.style.color,
                temp: slot.temp,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HourCell extends StatelessWidget {
  const _HourCell({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.temp,
    this.highlighted = false,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final double temp;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.blue : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: highlighted ? _nowLabel : _hourLabel,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Icon(icon, size: 19, color: iconColor),
          const SizedBox(height: 6),
          _degreeText(
            temp.round(),
            TextStyle(
              color: highlighted ? Colors.white : _darkText,
              fontSize: 14,
              fontWeight: highlighted ? FontWeight.w600 : FontWeight.w800,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.good,
  });

  final IconData icon;
  final String label;
  final String value;

  /// 좋은 상태(비 걱정 없음·공기 좋음)면 값을 파랑, 아니면 회색으로 쓴다.
  final bool good;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: AppColors.textSub),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSub,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: good ? AppColors.blue : AppColors.textBody,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.4,
              letterSpacing: -0.99,
            ),
          ),
        ],
      ),
    );
  }
}
