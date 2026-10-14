import 'package:daejin_app/screens/weather/weather_screen.dart';
import 'package:daejin_app/services/air_quality_service.dart';
import 'package:daejin_app/services/weather_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

WeatherResponse _weather({int rainProbability = 20}) {
  final hourly = [
    for (var h = 0; h < 24; h++)
      HourlyWeather(
        time: '2026-10-14T${h.toString().padLeft(2, '0')}:00',
        temperature: 10.0 + h / 2,
        weatherCode: 3,
      ),
  ];
  return WeatherResponse(
    currentTemp: 14.2,
    currentWeatherCode: 3,
    currentPrecipitation: 0,
    currentApparentTemp: 12.1,
    hourly: hourly,
    daily: [
      DailyWeather(
        date: '2026-10-14',
        tempMax: 18,
        tempMin: 7,
        precipitationSum: 0,
        precipitationProbabilityMax: rainProbability,
        weatherCode: 3,
      ),
    ],
  );
}

Future<void> _pump(
  WidgetTester tester,
  WeatherResponse weather, {
  AirQuality? air,
}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: WeatherScreen(
        weather: weather,
        airQuality: air,
        now: DateTime(2026, 10, 14, 10),
      ),
    ),
  );
}

void main() {
  testWidgets('미세먼지 값이 없으면 "-"로 보인다', (tester) async {
    await _pump(tester, _weather());
    expect(find.text('-'), findsOneWidget);
  });

  testWidgets('현재 기온/최고·최저·체감/시간대가 보인다', (tester) async {
    await _pump(tester, _weather(), air: const AirQuality(pm10: 20, pm25: 8));

    expect(tester.takeException(), isNull);
    expect(find.text('오늘 날씨 어때?'), findsOneWidget);
    expect(find.text('14°'), findsWidgets);
    expect(find.text('지금 · 구름 많음'), findsOneWidget);
    expect(find.text('최고 18° · 최저 7° · 체감 12°'), findsOneWidget);
    expect(find.text('20%'), findsOneWidget);
    expect(find.text('미세먼지'), findsOneWidget);
    expect(find.text('좋음'), findsOneWidget);
    // 10시 기준 +1,+2,+3,+5,+8시간 = 11/12/13/15/18시
    for (final label in ['지금', '11시', '12시', '13시', '15시', '18시']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('저녁 기온이 쌀쌀하면 겉옷, 비 확률이 높으면 우산을 권한다', (tester) async {
    await _pump(tester, _weather());
    expect(find.text('저녁엔 19°, 겉옷 챙겨!'), findsNothing); // 18시=19°라 쌀쌀 아님
    expect(find.text('저녁에도 19°, 가볍게 입어도 돼!'), findsOneWidget);

    await _pump(tester, _weather(rainProbability: 70));
    await tester.pump();
    expect(find.text('비 올 확률 70%, 우산 챙겨!'), findsOneWidget);
  });
}
