import 'dart:convert';

import 'package:daejin_app/screens/collection_screen.dart';
import 'package:daejin_app/screens/weather/weather_page.dart';
import 'package:daejin_app/services/air_quality_service.dart';
import 'package:daejin_app/services/weather_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String _json() => jsonEncode({
  'current': {
    'temperature_2m': 14.2,
    'weather_code': 3,
    'precipitation': 0,
    'apparent_temperature': 12.0,
  },
  'hourly': {
    'time': ['2026-10-14T10:00'],
    'temperature_2m': [14.0],
    'weather_code': [3],
  },
  'daily': {
    'time': ['2026-10-14'],
    'temperature_2m_max': [18.0],
    'temperature_2m_min': [7.0],
    'precipitation_sum': [0.0],
    'precipitation_probability_max': [20],
    'weather_code': [3],
  },
});

void main() {
  testWidgets('조회 성공하면 날씨 화면이 뜬다', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final service = WeatherService(
      client: MockClient((_) async => http.Response(_json(), 200)),
    );
    final air = AirQualityService(
      client: MockClient(
        (_) async =>
            http.Response('{"current":{"pm10":40.0,"pm2_5":10.0}}', 200),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: WeatherPage(service: service, airQualityService: air),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('오늘 날씨 어때?'), findsOneWidget);
    expect(find.text('20%'), findsOneWidget);
    expect(find.text('보통'), findsOneWidget); // PM10 40 → 보통
  });

  testWidgets('미세먼지 조회가 실패해도 날씨 화면은 뜬다', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final service = WeatherService(
      client: MockClient((_) async => http.Response(_json(), 200)),
    );
    final air = AirQualityService(
      client: MockClient((_) async => http.Response('', 500)),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: WeatherPage(service: service, airQualityService: air),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('오늘 날씨 어때?'), findsOneWidget);
    expect(find.text('-'), findsOneWidget);
  });

  testWidgets('조회 실패하면 안내와 다시 시도 버튼이 뜬다', (tester) async {
    final service = WeatherService(
      client: MockClient((_) async => http.Response('', 500)),
    );
    await tester.pumpWidget(MaterialApp(home: WeatherPage(service: service)));
    await tester.pumpAndSettle();

    expect(find.text('날씨를 불러오지 못했어요'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
  });

  testWidgets('모아보기의 날씨 항목을 누르면 날씨 화면으로 이동한다', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: CollectionScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('날씨'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(WeatherPage), findsOneWidget);
    // 실제 네트워크 요청이 걸려 있으므로 정리를 위해 화면을 닫는다.
    await tester.pumpWidget(const SizedBox());
  });
}
