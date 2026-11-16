// 담은 인원은 과목 목록·시트·상세 어디서나 "21/32명"(담은 사람/정원)으로 보인다.
// 학교가 주는 비율 글자("66.7%")는 쓰지 않는다.

import 'package:daejin_app/screens/timetable/widgets/course_result_card.dart';
import 'package:daejin_app/screens/timetable/widgets/course_result_tile.dart';
import 'package:daejin_app/services/course_catalog_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

CourseCatalogItem _course({int capacity = 32, int enrolled = 21}) =>
    CourseCatalogItem(
      seq: 1,
      courseCode: 'CS201',
      section: '01',
      courseName: '자료구조',
      courseType: '전필',
      credit: 3,
      targetGrade: '2',
      professor: '김가상',
      rawSchedule: '월10:00-11:15',
      room: '가상관 101',
      isClosed: false,
      capacity: capacity,
      waitlistCount: enrolled,
      enrollmentRatio: '65.6%',
    );

Future<void> _pump(WidgetTester tester, Widget child) =>
    tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));

void main() {
  testWidgets('과목 추가 패널 줄은 담은인원을 N/M명으로', (tester) async {
    await _pump(
      tester,
      CourseResultCard(course: _course(), onAdd: () {}, onViewDetail: () {}),
    );
    expect(find.text('담은인원 21/32명'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('시간표 만들기 시트 줄도 담은인원을 N/M명으로', (tester) async {
    await _pump(
      tester,
      CourseResultTile(
        course: _course(),
        expanded: false,
        alreadyAdded: false,
        onTap: () {},
        onAdd: () {},
        onViewSyllabus: () {},
      ),
    );
    expect(find.text('담은인원 21/32명'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('정원을 모르면 시트 줄은 담은인원을 숨긴다', (tester) async {
    await _pump(
      tester,
      CourseResultTile(
        course: _course(capacity: 0, enrolled: 0),
        expanded: false,
        alreadyAdded: false,
        onTap: () {},
        onAdd: () {},
        onViewSyllabus: () {},
      ),
    );
    expect(find.textContaining('담은인원'), findsNothing);
  });
}
