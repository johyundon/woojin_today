// 로그인 화면에 "개인정보는 이 휴대폰에만 저장된다"는 안내가 보이고, "자세히"를
// 누르면 설명 창이 열리는지 확인한다. 작은 화면(360x640)에서 키보드가 올라와도
// 화면이 넘치지 않는지도 확인한다(넘치면 테스트가 오류로 실패한다).

import 'package:daejin_app/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpLogin(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double keyboard = 0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
  await tester.pump();
}

void main() {
  testWidgets('로그인 버튼 아래에 휴대폰에만 저장된다는 안내가 보인다', (tester) async {
    await _pumpLogin(tester);

    expect(find.textContaining('이 휴대폰에만 저장돼요'), findsOneWidget);
    expect(find.textContaining('별도 서버 없이 학교와 직접 연결해요'), findsOneWidget);
    expect(find.text('자세히'), findsOneWidget);
  });

  testWidgets('"자세히"를 누르면 설명 창이 열리고 확인으로 닫힌다', (tester) async {
    await _pumpLogin(tester);

    await tester.tap(find.text('자세히'));
    await tester.pumpAndSettle();

    expect(find.text('내 정보는 이 휴대폰에만 있어요'), findsOneWidget);
    for (final title in ['저장하는 정보', '저장 위치', '보내는 곳', '지우는 법']) {
      expect(find.text(title), findsOneWidget);
    }
    expect(find.textContaining('together.daejin.ac.kr'), findsOneWidget);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('내 정보는 이 휴대폰에만 있어요'), findsNothing);
  });

  for (final keyboard in [0.0, 300.0]) {
    testWidgets('360x640 화면, 키보드 높이 $keyboard에서 넘치지 않는다', (tester) async {
      await _pumpLogin(tester, size: const Size(360, 640), keyboard: keyboard);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('작은 화면에서도 설명 창이 넘치지 않는다', (tester) async {
    await _pumpLogin(tester, size: const Size(360, 640));
    await tester.tap(find.text('자세히'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('지우는 법'), findsOneWidget);
  });
}
