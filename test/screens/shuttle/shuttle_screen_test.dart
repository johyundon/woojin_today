// ShuttleScreen이 "서비스 준비 중" 안내를 오버플로우 없이 보여주고
// 돌아가기가 동작하는지 확인한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/screens/shuttle/shuttle_screen.dart';

void main() {
  testWidgets('서비스 준비 중 안내를 보여준다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ShuttleScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('서비스\n준비 중입니다'), findsOneWidget);
    expect(find.text('셔틀버스 정보를 준비하고 있어요'), findsOneWidget);
  });

  testWidgets('돌아가기 버튼이 이전 화면으로 돌아간다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ShuttleScreen())),
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('돌아가기'));
    await tester.pumpAndSettle();

    expect(find.text('서비스\n준비 중입니다'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
