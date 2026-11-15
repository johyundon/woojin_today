// 캠퍼스 지도 검색 화면(시안 2번)이 오늘 수업·최근 검색·검색 결과를 보여 주고,
// 고른 결과를 돌려주는지 확인한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:daejin_app/screens/campus_map/campus_map_search_screen.dart';
import 'package:daejin_app/services/class_schedule_parser.dart';
import 'package:daejin_app/services/course_catalog_service.dart';

CourseCatalogItem _course(String name, String schedule, String room) =>
    CourseCatalogItem(
      seq: 1,
      courseCode: name,
      section: '01',
      courseName: name,
      courseType: '전필',
      credit: 3,
      targetGrade: '1',
      professor: '교수',
      rawSchedule: schedule,
      room: room,
      isClosed: false,
      capacity: 40,
      waitlistCount: 0,
      enrollmentRatio: '0',
    );

// 2026-11-18은 수요일. 12:20이면 진로설계는 끝났고 컴퓨터개론은 아직.
final _now = DateTime(2026, 11, 18, 12, 20);

Future<CampusSearchResult?> _open(
  WidgetTester tester, {
  List<TodayClass> classes = const [],
}) async {
  CampusSearchResult? result;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              result = await Navigator.of(context).push<CampusSearchResult>(
                MaterialPageRoute(
                  builder: (_) =>
                      CampusMapSearchScreen(todayClasses: classes, now: _now),
                ),
              );
            },
            child: const Text('열기'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('오늘 수업 길찾기·오늘 강의실을 보여 준다', (tester) async {
    final classes = todayClasses(
      courses: [
        _course('진로설계', '수10:30-12:15', '인문학관302'),
        _course('컴퓨터개론', '수12:30-14:00', '공대가동105'),
      ],
      now: _now,
    );
    await _open(tester, classes: classes);

    expect(find.text('오늘 수업 길찾기'), findsOneWidget);
    expect(find.text('진로설계 → 컴퓨터개론'), findsOneWidget);
    expect(find.text('인문학관302 → 공대가동105 · 여유 15분'), findsOneWidget);
    expect(find.text('진로설계 · 12:15 끝'), findsOneWidget);
    expect(find.text('컴퓨터개론 · 12:30 시작'), findsOneWidget);
  });

  testWidgets('검색해서 고르면 최근 검색에 남고 지울 수 있다', (tester) async {
    await _open(tester);
    expect(find.text('최근 검색'), findsNothing);

    await tester.enterText(find.byType(TextField), '도서관');
    await tester.pumpAndSettle();
    await tester.tap(find.text('중앙도서관'));
    await tester.pumpAndSettle();

    // 다시 열면 최근 검색에 있다.
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.text('최근 검색'), findsWidgets);
    expect(find.text('중앙도서관'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('최근 검색에서 지우기'));
    await tester.pumpAndSettle();
    expect(find.text('중앙도서관'), findsNothing);
  });
}
