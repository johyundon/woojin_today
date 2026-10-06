import 'package:flutter/material.dart';

import '../../../services/weather_service.dart';
import '../home_colors.dart';
import 'weather_indicator.dart';

const List<String> _koreanWeekdays = ['월', '화', '수', '목', '금', '토', '일'];

/// 날씨 아이콘을 누르면 뜨는 "우리 학교 날씨는?!" 상세 모달.
///
/// Figma 참고 자료(node 6:24)는 Figma로 직접 그려진 디자인이 아니라 다른 앱의
/// 폰 스크린샷 3장을 참고용으로 붙여놓은 것이라 정확한 수치는 없다 — 느낌만
/// 따르고, 간격/색상은 이 앱의 기존 모달("내 정보", home_screen.dart의
/// `_showMyInfoDialog`)과 같은 패턴([HomeColors], 둥근 카드 Dialog)을 그대로 쓴다.
///
/// [WeatherResponse.daily](최대 7일치)를 좌우 화살표로 넘겨볼 수 있다. 첫 번째
/// 날(오늘)은 현재 온도 하나와 "지금/저녁" 2칸을, 이후 날짜는 최저/최고 온도와
/// "새벽/아침/낮/저녁" 4칸을 보여준다.
Future<void> showWeatherDetailDialog(
  BuildContext context, {
  required HomeColors colors,
  required WeatherResponse weather,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _WeatherDetailDialog(colors: colors, weather: weather),
  );
}

class _WeatherDetailDialog extends StatefulWidget {
  const _WeatherDetailDialog({required this.colors, required this.weather});

  final HomeColors colors;
  final WeatherResponse weather;

  @override
  State<_WeatherDetailDialog> createState() => _WeatherDetailDialogState();
}

class _WeatherDetailDialogState extends State<_WeatherDetailDialog> {
  int _dayIndex = 0;

  /// 주어진 날짜의 특정 시(hour) 기온을 hourly 응답에서 찾는다. 명세상
  /// hourly의 time은 `"2026-10-06T18:00"` 형식이라 날짜+시를 그대로 이어붙여
  /// 비교한다. 해당 시각 데이터가 없으면(응답 범위를 벗어남 등) null을 돌려주고
  /// 화면에서는 "-"로 표시한다.
  double? _hourlyTempAt(String date, int hour) {
    final target = '${date}T${hour.toString().padLeft(2, '0')}:00';
    for (final h in widget.weather.hourly) {
      if (h.time == target) return h.temperature;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final daily = widget.weather.daily;
    final day = daily[_dayIndex];
    final isToday = _dayIndex == 0;
    final display = weatherDisplay(day.weatherCode);

    return Dialog(
      backgroundColor: colors.cardSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    '우리 학교 날씨는?!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _dayLabel(day.date, isToday),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Icon(display.icon, color: const Color(0xFFFFC452), size: 64),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.chevron_left,
                    color: _dayIndex > 0
                        ? colors.textPrimary
                        : Colors.transparent,
                  ),
                  onPressed: _dayIndex > 0
                      ? () => setState(() => _dayIndex--)
                      : null,
                ),
                Text(
                  isToday
                      ? '${widget.weather.currentTemp.toStringAsFixed(1)}°'
                      : '${day.tempMin.toStringAsFixed(1)}° / '
                            '${day.tempMax.toStringAsFixed(1)}°',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.chevron_right,
                    color: _dayIndex < daily.length - 1
                        ? colors.textPrimary
                        : Colors.transparent,
                  ),
                  onPressed: _dayIndex < daily.length - 1
                      ? () => setState(() => _dayIndex++)
                      : null,
                ),
              ],
            ),
            Text(
              '강수확률 ${day.precipitationProbabilityMax}%',
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Text(
              _weatherMessage(day.weatherCode, isToday),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: isToday
                  ? [
                      _TimeSlot(
                        colors: colors,
                        label: '지금',
                        highlighted: true,
                        weatherCode: widget.weather.currentWeatherCode,
                        temp: widget.weather.currentTemp,
                      ),
                      _TimeSlot(
                        colors: colors,
                        label: '저녁',
                        weatherCode: day.weatherCode,
                        temp: _hourlyTempAt(day.date, 18),
                      ),
                    ]
                  : [
                      _TimeSlot(
                        colors: colors,
                        label: '새벽',
                        weatherCode: day.weatherCode,
                        temp: _hourlyTempAt(day.date, 6),
                      ),
                      _TimeSlot(
                        colors: colors,
                        label: '아침',
                        weatherCode: day.weatherCode,
                        temp: _hourlyTempAt(day.date, 9),
                      ),
                      _TimeSlot(
                        colors: colors,
                        label: '낮',
                        weatherCode: day.weatherCode,
                        temp: _hourlyTempAt(day.date, 15),
                      ),
                      _TimeSlot(
                        colors: colors,
                        label: '저녁',
                        weatherCode: day.weatherCode,
                        temp: _hourlyTempAt(day.date, 18),
                      ),
                    ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeSlot extends StatelessWidget {
  const _TimeSlot({
    required this.colors,
    required this.label,
    required this.weatherCode,
    required this.temp,
    this.highlighted = false,
  });

  final HomeColors colors;
  final String label;
  final int weatherCode;
  final double? temp;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final display = weatherDisplay(weatherCode);
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: highlighted ? accentOrange : colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Icon(display.icon, color: const Color(0xFFFFC452), size: 20),
        const SizedBox(height: 6),
        Text(
          temp == null ? '-' : '${temp!.round()}°',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// "오늘"/"9/7(월)" 형식의 날짜 라벨. [DateTime.weekday]는 월=1~일=7.
String _dayLabel(String isoDate, bool isToday) {
  if (isToday) return '오늘';
  final date = DateTime.parse(isoDate);
  return '${date.month}/${date.day}(${_koreanWeekdays[date.weekday - 1]})';
}

/// 날씨 코드별 안내 문구. API가 텍스트를 내려주지 않아서 직접 매핑한다.
/// 오늘/이후 날짜는 시제가 다르므로("~해요" vs "~할 예정이에요") 각각 완성된
/// 문장으로 따로 쓴다 — 어간에 어미를 이어붙이면("오" + "어요") 불규칙 활용
/// 때문에 "와요"가 아니라 어색한 문장이 만들어지기 때문이다.
String _weatherMessage(int code, bool isToday) {
  final (String today, String future) = switch (code) {
    0 => ('오늘은 하늘이 맑아요! 나들이하기 좋겠어요', '하늘이 맑을 예정이에요! 나들이하기 좋겠어요'),
    >= 1 && <= 3 => ('오늘은 구름이 많이 꼈어요', '구름이 많이 낄 예정이에요'),
    45 || 48 => ('오늘은 안개가 꼈어요. 이동할 때 주의하세요', '안개가 낄 수 있어요. 이동할 때 주의하세요'),
    >= 51 && <= 67 => ('오늘은 비가 와요. 우산을 챙기세요', '비가 올 예정이에요. 우산을 챙기세요'),
    >= 71 && <= 77 => (
      '오늘은 눈이 와요. 길이 미끄러울 수 있어요',
      '눈이 올 예정이에요. 길이 미끄러울 수 있어요',
    ),
    >= 80 && <= 82 => ('오늘은 소나기가 올 수 있어요. 우산을 챙기세요', '소나기가 올 수 있어요. 우산을 챙기세요'),
    >= 95 && <= 99 => (
      '오늘은 천둥·번개를 동반한 비가 와요. 외출을 줄이세요',
      '천둥·번개를 동반한 비가 올 수 있어요. 외출을 줄이세요',
    ),
    _ => ('날씨 정보를 확인하기 어려워요', '날씨 정보를 확인하기 어려워요'),
  };
  return isToday ? today : future;
}
