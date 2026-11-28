// 넓은 화면(아이폰 듀오를 펼친 화면 등)에서는 앱을 아이폰 폭으로 가운데에
// 세우고, 보통 아이폰 세로 화면에서는 그대로 두는지 확인한다.
import 'package:daejin_app/widgets/phone_width_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app() => MaterialApp(
  builder: (context, child) => PhoneWidthFrame(child: child!),
  home: Builder(
    builder: (context) => Scaffold(
      key: const ValueKey('page'),
      body: Text('w=${MediaQuery.sizeOf(context).width.toInt()}'),
    ),
  ),
);

void main() {
  testWidgets('넓은 화면에서는 440 폭으로 가운데에 세운다', (tester) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app());

    final page = find.byKey(const ValueKey('page'));
    expect(tester.getSize(page).width, PhoneWidthFrame.maxWidth);
    expect(tester.getTopLeft(page).dx, (900 - PhoneWidthFrame.maxWidth) / 2);
    // 안쪽 화면도 폭을 440으로 알고 레이아웃한다.
    expect(find.text('w=440'), findsOneWidget);
  });

  testWidgets('아이폰 세로 화면에서는 그대로 꽉 채운다', (tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app());

    expect(tester.getSize(find.byKey(const ValueKey('page'))).width, 402);
    expect(find.text('w=402'), findsOneWidget);
  });
}
