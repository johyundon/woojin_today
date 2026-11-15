// 약관 동의 화면의 "내 정보는 내 휴대폰에만 저장돼요" 안내 상자: 처음엔 접혀
// 있고, 누르면 설명이 펼쳐지며, 작은 화면에서 펼쳐도 넘치지 않는지 확인한다.

import 'package:daejin_app/screens/terms_agreement_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const body = '[우진이의 하루]는 대진대학교 서버와 직접 통신합니다.';

  testWidgets('안내 상자는 접혀 있다가 누르면 펼쳐지고, 다시 누르면 접힌다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TermsAgreementScreen(userId: '20261234')),
    );

    expect(find.text('내 정보는 내 휴대폰에만 저장돼요'), findsOneWidget);
    expect(find.textContaining(body), findsNothing);

    await tester.tap(find.text('내 정보는 내 휴대폰에만 저장돼요'));
    await tester.pumpAndSettle();
    expect(find.textContaining(body), findsOneWidget);

    await tester.tap(find.text('내 정보는 내 휴대폰에만 저장돼요'));
    await tester.pumpAndSettle();
    expect(find.textContaining(body), findsNothing);
  });

  testWidgets('작은 화면에서 펼쳐도 넘치지 않고, 스크롤해서 버튼을 누를 수 있다', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: TermsAgreementScreen(userId: '20261234')),
    );
    await tester.tap(find.text('내 정보는 내 휴대폰에만 저장돼요'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('동의하고 시작하기'));
    await tester.pumpAndSettle();
    expect(find.text('동의하고 시작하기').hitTestable(), findsOneWidget);
  });
}
