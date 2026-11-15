// 화면 전환은 애니메이션 없이 바로 바뀐다(밀려 들어오는 중간 프레임이 없다).

import 'package:daejin_app/theme/instant_page_transitions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('화면을 열고 닫으면 다음 프레임에 바로 바뀐다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.iOS: InstantPageTransitionsBuilder(),
              TargetPlatform.android: InstantPageTransitionsBuilder(),
            },
          ),
        ),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('다음 화면')),
              ),
            ),
            child: const Text('열기'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('열기'));
    await tester.pump(); // 전환 시작
    await tester.pump(); // 0초 전환이라 여기서 끝난다
    expect(find.text('다음 화면'), findsOneWidget);
    expect(find.text('열기'), findsNothing); // 앞 화면은 이미 가려졌다
    expect(tester.hasRunningAnimations, isFalse);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump();
    expect(find.text('다음 화면'), findsNothing);
    expect(find.text('열기'), findsOneWidget);
  });
}
