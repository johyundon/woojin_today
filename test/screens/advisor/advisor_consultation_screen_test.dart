// AdvisorConsultationScreen이 실제 지도교수 조회(FakeStudentInfoService,
// kUseMockApi 모드)와 상담 현황/신청 목데이터를 오버플로우 없이 보여주고,
// 상세보기/교수 변경/상담 신청 흐름이 제대로 동작하는지 확인한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/screens/advisor/advisor_consultation_screen.dart';

void main() {
  testWidgets('userId2가 있으면 실제(Fake) 지도교수 성함을 불러와 보여준다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdvisorConsultationScreen(userId2: 'mock-user-id2'),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('나의 지도교수님'), findsOneWidget);
    expect(find.text('김민준 교수님', findRichText: true), findsOneWidget);
  });

  testWidgets('userId2가 없으면 조회하지 않고 "불러올 수 없어요"로 처리한다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AdvisorConsultationScreen(userId2: null)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('불러올 수 없어요'), findsOneWidget);
  });

  testWidgets('현황 탭 기본 데이터와 상세보기 다이얼로그가 동작한다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdvisorConsultationScreen(userId2: 'mock-user-id2'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('지금까지의 상담 인정 횟수'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('2026-08-17'), findsOneWidget);

    // 두 번째 이력 카드(2026-06-01)는 테스트 뷰포트 아래쪽이라 스크롤해야
    // 보인다.
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('2026-06-01'), findsOneWidget);

    await tester.tap(find.text('상세보기').last);
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: find.byType(Dialog), matching: find.text('상세보기')),
      findsOneWidget,
    );
    expect(find.text('교수님 사랑합니다!'), findsOneWidget);
    expect(find.text('확인완료'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('교수님 사랑합니다!'), findsNothing);
  });

  testWidgets('신청 탭: 기본 지도교수 선택, 변경, 상담 신청까지 이어진다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdvisorConsultationScreen(userId2: 'mock-user-id2'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('지도교수 상담 신청'));
    await tester.pumpAndSettle();

    expect(find.text('김민준 (지도교수)'), findsOneWidget);

    await tester.tap(find.text('변경'));
    await tester.pumpAndSettle();
    expect(find.text('교수님 이름으로 검색'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '이시진');
    await tester.pumpAndSettle();
    expect(find.text('이시진    AI융합학부'), findsOneWidget);
    expect(find.text('신판섭    AI융합학부'), findsNothing);

    await tester.tap(find.text('이시진    AI융합학부'));
    await tester.pumpAndSettle();
    expect(find.text('이시진 (AI융합학부)'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('온라인 상담'));
    await tester.pump();

    // 1단계(교수/방식) → 2단계(전화번호).
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('전화번호를 입력해주세요'), findsOneWidget);

    final phoneFields = find.byType(TextField);
    expect(phoneFields, findsNWidgets(3));
    await tester.enterText(phoneFields.at(1), '5291');
    await tester.enterText(phoneFields.at(2), '3807');
    await tester.pumpAndSettle();

    // 2단계 → 3단계(이메일).
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('이메일을 입력해주세요'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'test@daejin.ac.kr');
    await tester.pumpAndSettle();

    // 3단계 → 4단계(상담 내용).
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('어떤 이야기를 나누고 싶어요?'), findsOneWidget);

    // 10자 미만이면 "상담 신청하기"가 비활성 상태라 탭해도 진행되지 않는다.
    await tester.enterText(find.byType(TextField).first, '짧음');
    await tester.pumpAndSettle();
    await tester.tap(find.text('상담 신청하기'), warnIfMissed: false);
    await tester.pump();
    expect(find.text('상담을 신청했어요'), findsNothing);

    await tester.enterText(find.byType(TextField).first, '테스트 상담 내용입니다');
    await tester.pumpAndSettle();
    await tester.tap(find.text('상담 신청하기'));
    await tester.pump();

    expect(find.text('상담을 신청했어요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
