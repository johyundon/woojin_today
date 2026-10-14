// RingingBell이 꺼짐 → 켜짐으로 바뀔 때만 흔들리고, 그냥 다시 그려질 때나 꺼질 때는
// 흔들리지 않는지 확인한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/screens/calendar/widgets/ringing_bell.dart';

Widget _app(bool active, {bool playOnStart = false}) => MaterialApp(
  home: Center(
    child: RingingBell(
      active: active,
      size: 20,
      activeColor: Colors.blue,
      inactiveColor: Colors.grey,
      playOnStart: playOnStart,
    ),
  ),
);

/// 종을 감싼 회전(Transform) 중 이 위젯의 것의 현재 각도.
double _angle(WidgetTester tester) {
  final transform = tester.widget<Transform>(
    find.descendant(
      of: find.byType(RingingBell),
      matching: find.byType(Transform),
    ),
  );
  // Transform.rotate의 행렬에서 sin 값(회전 각도에 비례)을 읽는다.
  return transform.transform.entry(1, 0);
}

void main() {
  testWidgets('꺼짐 → 켜짐으로 바뀌면 흔들리다가 멈춘다', (tester) async {
    await tester.pumpWidget(_app(false));
    expect(_angle(tester), 0);

    await tester.pumpWidget(_app(true));
    await tester.pump(const Duration(milliseconds: 60));
    expect(_angle(tester), isNot(0)); // 흔들리는 중

    await tester.pumpAndSettle();
    expect(_angle(tester).abs(), lessThan(0.001)); // 다 울리고 제자리
    expect(find.byIcon(Icons.notifications_active), findsOneWidget);
  });

  testWidgets('이미 켜져 있던 종은 처음 그려질 때 흔들리지 않는다', (tester) async {
    await tester.pumpWidget(_app(true));
    await tester.pump(const Duration(milliseconds: 60));
    expect(_angle(tester), 0);
  });

  testWidgets('playOnStart면 처음 나타날 때 한 번 울린다', (tester) async {
    await tester.pumpWidget(_app(true, playOnStart: true));
    await tester.pump(const Duration(milliseconds: 60));
    expect(_angle(tester), isNot(0));
    await tester.pumpAndSettle();
  });

  testWidgets('울리는 도중 꺼지면 바로 멈춘다', (tester) async {
    await tester.pumpWidget(_app(false));
    await tester.pumpWidget(_app(true));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpWidget(_app(false));
    await tester.pump();
    expect(_angle(tester), 0);
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
  });
}
