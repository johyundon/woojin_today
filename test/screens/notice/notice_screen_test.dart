// NoticeScreen이 3개 카테고리 탭(학사공지/종합강의시간표/마일리지)을
// 오버플로우 없이 보여주고, 공지 상세/마일리지 대상자 확인 다이얼로그로
// 제대로 이어지는지 확인한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/screens/notice/notice_screen.dart';

void main() {
  testWidgets('기본 탭(학사공지)이 목록을 보여준다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NoticeScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('학사공지'), findsWidgets);
    expect(find.text('2026학년도 2학기 조기졸업 신청 안내'), findsOneWidget);
    expect(find.text('new'), findsOneWidget);
  });

  testWidgets('공지를 탭하면 상세 화면으로 이동하고, 첨부파일 미리보기는 스낵바로 안내한다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NoticeScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('2026학년도 2학기 조기졸업 신청 안내'));
    await tester.pumpAndSettle();

    expect(find.textContaining('조기졸업 요건'), findsOneWidget);
    expect(find.text('작성자'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('2026학년도 2학기 조기졸업 신청 안내'), findsOneWidget);
  });

  testWidgets('종합강의시간표 탭의 첨부파일 "미리보기"는 스낵바를 보여준다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NoticeScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('종합강의시간표'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2026학년도 2학기 종합강의시간표').first);
    await tester.pumpAndSettle();

    expect(find.text('첨부파일'), findsOneWidget);
    await tester.tap(find.text('미리보기'));
    await tester.pump();
    expect(find.text('미리보기는 지원하지 않아요'), findsOneWidget);
  });

  testWidgets('마일리지 탭: "대상자" 공지는 대상자 확인 다이얼로그로, "시행 안내"는 상세 화면으로 간다', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: NoticeScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('마일리지'));
    await tester.pumpAndSettle();

    expect(find.text('대상자 확인'), findsNWidgets(3));

    await tester.tap(find.text('대상자 확인').first);
    await tester.pumpAndSettle();
    expect(find.text('아쉽게도 대상자 명단에 없어요..'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('2026학년도 1학기 마일리지장학 시행 안내'));
    await tester.pumpAndSettle();
    expect(find.textContaining('시행 계획'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('"새 글 알림 받기" 토글을 끄고 켤 수 있다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NoticeScreen()));
    await tester.pumpAndSettle();

    final switchFinder = find.byType(Switch);
    expect(tester.widget<Switch>(switchFinder).value, isTrue);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(switchFinder).value, isFalse);
    expect(tester.takeException(), isNull);
  });
}
