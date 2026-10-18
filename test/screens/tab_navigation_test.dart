// 하단 탭 바로 시간표 / 모아보기 / 캘린더를 서로 오갈 때, 홈으로 튕기지 않고 누른
// 탭의 화면으로 바로 가는지 확인한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:daejin_app/screens/home_screen.dart';
import 'package:daejin_app/services/weather_service.dart';

const _weatherJson = '''
{
  "current": {"temperature_2m": 21.3, "apparent_temperature": 20.9,
              "precipitation": 0.0, "weather_code": 0},
  "hourly": {"time": ["2026-10-06T00:00"], "temperature_2m": [15.0],
             "weather_code": [1]},
  "daily": {"time": ["2026-10-06"], "temperature_2m_max": [20.1],
            "temperature_2m_min": [10.2], "precipitation_sum": [0.0],
            "precipitation_probability_max": [10], "weather_code": [3]}
}
''';

Future<void> _openHome(WidgetTester tester) async {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: HomeScreen(
        weatherService: WeatherService(
          client: MockClient((_) async => http.Response(_weatherJson, 200)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 하단 탭 바의 [label] 탭을 누른다.
Future<void> _tapTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('시간표 → 모아보기: 홈이 아니라 모아보기 화면으로 간다', (tester) async {
    await _openHome(tester);

    await _tapTab(tester, '시간표');
    expect(find.text('내 시간표'), findsOneWidget);

    await _tapTab(tester, '모아보기');
    expect(find.text('필요한 거 다 있음'), findsOneWidget); // 모아보기 화면
    expect(find.text('내 시간표'), findsNothing); // 시간표는 걷혀 있다
    expect(tester.takeException(), isNull);
  });

  testWidgets('시간표 → 캘린더 → 모아보기 → 시간표로 계속 이어서 오갈 수 있다', (tester) async {
    await _openHome(tester);

    await _tapTab(tester, '시간표');
    await _tapTab(tester, '캘린더');
    expect(find.byIcon(Icons.chevron_right), findsOneWidget); // 캘린더의 달 이동 버튼

    await _tapTab(tester, '모아보기');
    expect(find.text('필요한 거 다 있음'), findsOneWidget);

    await _tapTab(tester, '시간표');
    expect(find.text('내 시간표'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('탭 화면에서 뒤로가기는 홈으로, 홈 탭(가운데 버튼)도 홈으로 간다', (tester) async {
    await _openHome(tester);

    // 시간표 → 모아보기로 바꾼 뒤 뒤로가기 → 홈(쌓인 화면이 하나만 남는다).
    await _tapTab(tester, '시간표');
    await _tapTab(tester, '모아보기');
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    expect(await navigator.maybePop(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('필요한 거 다 있음'), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(await navigator.maybePop(), isFalse); // 더 닫을 화면이 없다 = 홈

    // 모아보기의 가운데 홈 버튼도 홈으로 돌아간다.
    await _tapTab(tester, '모아보기');
    await tester.tap(find.byType(Image).last); // 가운데 라임 홈 버튼(마스코트 이미지)
    await tester.pumpAndSettle();
    expect(find.text('필요한 거 다 있음'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('이미 보고 있는 탭을 다시 눌러도 아무 일도 없다', (tester) async {
    await _openHome(tester);

    await _tapTab(tester, '시간표');
    await _tapTab(tester, '시간표');
    expect(find.text('내 시간표'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
