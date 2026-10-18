// AdvisorConsultationScreen이 실제 지도교수 조회(FakeStudentInfoService,
// kUseMockApi 모드)와 상담 현황/신청 목데이터를 오버플로우 없이 보여주고,
// 상세보기/교수 변경/상담 신청(온라인·방문 두 흐름 모두) 흐름이 제대로
// 동작하는지 확인한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/screens/advisor/advisor_consultation_screen.dart';
import 'package:daejin_app/screens/advisor/services/advisor_consultation_mock_data.dart';
import 'package:daejin_app/services/session_cache.dart';

void main() {
  // AdvisorConsultationScreen도 이제 SessionCache를 통해 학생 정보를
  // 조회한다 — 같은 userId2('mock-user-id2')를 재사용하는 여러 테스트가
  // 서로의 캐시를 보지 않도록 매 테스트 전에 비운다.
  setUp(SessionCache.clear);

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

  testWidgets('현황 탭 기본 데이터와 상세보기 바텀시트가 동작한다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdvisorConsultationScreen(userId2: 'mock-user-id2'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('지금까지 상담 인정 횟수'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('2026-08-17'), findsOneWidget);

    // 두 번째 이력 카드(2026-06-01)는 테스트 뷰포트 아래쪽이라 스크롤해야
    // 보인다.
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('2026-06-01'), findsOneWidget);

    await tester.tap(find.text('상세보기').last);
    await tester.pumpAndSettle();

    expect(find.text('상세보기'), findsWidgets);
    expect(find.text('교수님 사랑합니다!'), findsOneWidget);
    expect(find.text('확인완료'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('교수님 사랑합니다!'), findsNothing);
  });

  testWidgets('신청 탭: 기본 지도교수 선택, 변경, 온라인 상담 신청까지 이어진다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdvisorConsultationScreen(userId2: 'mock-user-id2'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('상담 신청'));
    await tester.pumpAndSettle();

    expect(find.text('김민준 (지도교수)'), findsOneWidget);

    await tester.tap(find.text('변경'));
    await tester.pumpAndSettle();
    expect(find.text('교수님 이름으로 검색'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '이시진');
    await tester.pumpAndSettle();
    // "이시진"은 검색창에 입력한 글자 자체와 걸러진 결과 줄, 두 곳에 나온다.
    expect(find.text('이시진'), findsNWidgets(2));
    expect(find.text('신완섭'), findsNothing);

    await tester.tap(find.text('이시진').last);
    await tester.pumpAndSettle();
    expect(find.text('이시진 (AI융합학부)'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // 기본값(온라인 상담)이 이미 선택돼 있어 1단계(교수/방식) → 2단계(전화번호).
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('전화번호를 입력해주세요'), findsOneWidget);

    final phoneFields = find.byType(TextField);
    expect(phoneFields, findsNWidgets(3));
    await tester.enterText(phoneFields.at(1), '5291');
    await tester.enterText(phoneFields.at(2), '3807');
    await tester.pumpAndSettle();

    // 마지막 칸(4자리)을 다 채우면 다음 칸으로 넘길 곳이 없으니 키보드가
    // 저절로 내려가야 한다.
    expect(tester.testTextInput.isVisible, isFalse);

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
    expect(find.text('상담 신청이 완료됐어요'), findsNothing);

    await tester.enterText(find.byType(TextField).first, '테스트 상담 내용입니다');
    await tester.pumpAndSettle();
    final submitFinder = find.text('상담 신청하기');
    await tester.ensureVisible(submitFinder);
    await tester.pumpAndSettle();
    await tester.tap(submitFinder);
    await tester.pumpAndSettle();

    expect(find.text('상담 신청이 완료됐어요'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // "상담 현황 보기"를 누르면 현황 탭으로 돌아간다.
    await tester.tap(find.text('상담 현황 보기'));
    await tester.pumpAndSettle();
    expect(find.text('지금까지 상담 인정 횟수'), findsOneWidget);
  });

  testWidgets('신청 탭: 방문 상담은 전화/이메일 없이 날짜·시간 선택 2단계로 끝난다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AdvisorConsultationScreen(userId2: 'mock-user-id2'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('상담 신청'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('방문 상담'));
    await tester.pump();

    // 날짜/시간을 고르기 전에는 "다음"이 비활성 상태다.
    await tester.tap(find.text('다음'), warnIfMissed: false);
    await tester.pump();
    expect(find.text('전화번호를 입력해주세요'), findsNothing);
    expect(find.text('어떤 이야기를 나누고 싶어요?'), findsNothing);

    // 날짜를 고르기 전엔 시간 칸 대신 안내 문구가 뜬다.
    expect(find.text('날짜를 먼저 선택해주세요'), findsOneWidget);

    // 캘린더는 기본적으로 오늘이 속한 달을 보여주므로, 오늘(=예약 가능
    // 기간의 시작일) 칸은 항상 화면에 떠 있다.
    final today = AdvisorConsultationMockData.visitBookingWindowStart();
    final dateFinder = find.byKey(
      ValueKey('visit-calendar-day-${today.year}-${today.month}-${today.day}'),
    );
    await tester.ensureVisible(dateFinder);
    await tester.pumpAndSettle();
    await tester.tap(dateFinder);
    await tester.pump();

    expect(find.text('날짜를 먼저 선택해주세요'), findsNothing);

    final timeFinder = find.byKey(
      ValueKey(
        'visit-time-${AdvisorConsultationMockData.visitAvailableTimes.first}',
      ),
    );
    await tester.ensureVisible(timeFinder);
    await tester.pumpAndSettle();
    await tester.tap(timeFinder);
    await tester.pump();

    // 1단계(교수/방식+시간) → 2단계(상담 내용) — 방문은 전화/이메일을 안 거친다.
    final nextFinder = find.text('다음');
    await tester.ensureVisible(nextFinder);
    await tester.pumpAndSettle();
    await tester.tap(nextFinder);
    await tester.pumpAndSettle();
    expect(find.text('어떤 이야기를 나누고 싶어요?'), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '방문 상담 테스트 내용');
    await tester.pumpAndSettle();
    await tester.tap(find.text('상담 신청하기'));
    await tester.pumpAndSettle();

    expect(find.text('상담 신청이 완료됐어요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
