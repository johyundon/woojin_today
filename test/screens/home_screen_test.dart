// 홈 화면 헤드라인의 날씨 표시 상태(로딩/성공/에러)를 검증한다.
// 실제 네트워크 호출 없이 WeatherService에 http.testing.MockClient를 주입해서
// 각 상태로 분기시킨다.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:daejin_app/screens/home_screen.dart';
import 'package:daejin_app/services/weather_service.dart';

const _fixtureJson = '''
{
  "current": {
    "temperature_2m": 21.3,
    "relative_humidity_2m": 55,
    "apparent_temperature": 20.9,
    "precipitation": 0.0,
    "weather_code": 0,
    "wind_speed_10m": 4.2
  },
  "hourly": {
    "time": ["2026-10-06T00:00"],
    "temperature_2m": [15.0],
    "precipitation": [0.0],
    "precipitation_probability": [10],
    "weather_code": [1]
  },
  "daily": {
    "time": ["2026-10-06"],
    "temperature_2m_max": [20.1],
    "temperature_2m_min": [10.2],
    "precipitation_sum": [0.0],
    "precipitation_probability_max": [10],
    "weather_code": [3]
  }
}
''';

void main() {
  testWidgets('날씨 조회가 끝나기 전에는 로딩 인디케이터를 보여준다', (tester) async {
    // 응답을 completer로 보류해서 로딩 상태를 고정시킨 뒤, 테스트 종료 전에
    // 완료시켜 pending timer가 남지 않게 한다.
    final responseCompleter = Completer<http.Response>();
    final mockClient = MockClient((request) => responseCompleter.future);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(weatherService: WeatherService(client: mockClient)),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    responseCompleter.complete(http.Response(_fixtureJson, 200));
    await tester.pumpAndSettle();
  });

  testWidgets('날씨 조회 성공 시 현재 온도와 날씨 아이콘을 보여준다', (tester) async {
    final mockClient = MockClient((request) async {
      return http.Response(_fixtureJson, 200);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(weatherService: WeatherService(client: mockClient)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('21°C'), findsOneWidget);
    expect(find.text('맑음'), findsOneWidget);
    expect(find.byIcon(Icons.wb_sunny), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('날씨 조회 실패 시 cloud_off 아이콘만 조용히 보여준다', (tester) async {
    final mockClient = MockClient((request) async {
      return http.Response('Internal Server Error', 500);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(weatherService: WeatherService(client: mockClient)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    // 에러 시 스낵바/다이얼로그 같은 방해 UI는 뜨지 않아야 한다.
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byType(Dialog), findsNothing);
  });
}
