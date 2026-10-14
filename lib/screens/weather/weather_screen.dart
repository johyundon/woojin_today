import 'package:flutter/material.dart';

import '../../services/air_quality_service.dart';
import '../../services/weather_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/mascot_sticker.dart';
import '../home/widgets/weather_indicator.dart' show weatherDisplay;

/// 지금부터 몇 시간 뒤의 예보를 시간대 줄에 보여줄지("지금" 다음 5칸).
const _hourOffsets = [1, 2, 3, 5, 8];

/// "오늘 날씨 어때?" 화면(v4 리디자인). 캠퍼스 좌표 고정 날씨([WeatherResponse])를
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
    final display = weatherDisplay(weather.currentWeatherCode);
    final slots = _hourSlots(current);

    return Scaffold(
      backgroundColor: AppColors.cobalt,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.cobaltDeep,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lime,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, size: 14, color: AppColors.ink),
                    SizedBox(width: 4),
                    Text(
                      '포천 선단동',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '오늘 날씨 어때?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.04,
              ),
            ),
            const SizedBox(height: 18),
            _CurrentCard(
              icon: display.icon,
              conditionLabel: _conditionLabel(weather.currentWeatherCode),
              temp: weather.currentTemp,
              tempMax: today.tempMax,
              tempMin: today.tempMin,
              apparentTemp: weather.currentApparentTemp,
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Transform.rotate(
                angle: -0.03,
                child: _AdviceChip(message: _advice(current)),
              ),
            ),
            const SizedBox(height: 14),
            _HourlyStrip(
              nowTemp: weather.currentTemp,
              nowIcon: display.icon,
              slots: slots,
            ),
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _InfoCard(
                      color: AppColors.lime,
                      textColor: AppColors.ink,
                      icon: Icons.water_drop,
                      label: '비 올 확률',
                      value: '${today.precipitationProbabilityMax}%',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoCard(
                      color: AppColors.ink,
                      textColor: Colors.white,
                      icon: Icons.air,
                      label: '미세먼지',
                      value: airQuality?.grade?.label ?? '-',
                    ),
                  ),
                ],
              ),
            ),
          ],
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
          icon: weatherDisplay(hour.weatherCode).icon,
          temp: hour.temperature,
        ),
      );
    }
    return slots;
  }

  /// 분홍 말풍선 한 줄 조언. 비 소식이 우선이고, 그다음 저녁(18시) 기온이
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
    required this.icon,
    required this.temp,
  });

  final String label;
  final IconData icon;
  final double temp;
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
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 22, color: AppColors.cobalt),
                  const SizedBox(width: 8),
                  Text(
                    '지금 · $conditionLabel',
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${temp.round()}°',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 96,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                  letterSpacing: -4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                detail,
                style: const TextStyle(
                  color: Color(0xFF6B6B70),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Positioned(
            right: 0,
            bottom: 8,
            child: MascotSticker(width: 92, angle: 0.08),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.blushPink,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.checkroom, size: 16, color: AppColors.ink),
          const SizedBox(width: 6),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
        color: AppColors.cobaltDeep,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: _HourCell(
              label: '지금',
              icon: nowIcon,
              temp: nowTemp,
              highlighted: true,
            ),
          ),
          for (final slot in slots)
            Expanded(
              child: _HourCell(
                label: slot.label,
                icon: slot.icon,
                temp: slot.temp,
              ),
            ),
        ],
      ),
    );
  }
}

class _HourCell extends StatelessWidget {
  const _HourCell({
    required this.label,
    required this.icon,
    required this.temp,
    this.highlighted = false,
  });

  final String label;
  final IconData icon;
  final double temp;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final color = highlighted ? AppColors.ink : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.lime : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            '${temp.round()}°',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.color,
    required this.textColor,
    required this.icon,
    required this.label,
    required this.value,
  });

  final Color color;
  final Color textColor;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.2),
            offset: const Offset(0, 6),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: textColor.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
