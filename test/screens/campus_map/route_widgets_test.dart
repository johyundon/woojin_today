// 길안내 화면(시안 3번)의 위쪽 출발·도착 카드와 아래 시트, 연강 정보 글자를 확인한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/screens/campus_map/models/route_classes.dart';
import 'package:daejin_app/screens/campus_map/widgets/route_endpoints_card.dart';
import 'package:daejin_app/screens/campus_map/widgets/route_sheet.dart';
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

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  test('연강 정보에서 카드·시트 글자를 만든다', () {
    final classes = todayClasses(
      courses: [
        _course('진로설계', '수10:30-12:15', '인문학관302'),
        _course('컴퓨터개론', '수12:30-14:00', '공대가동B105'),
      ],
      now: DateTime(2026, 11, 18, 12, 20),
    );
    final route = RouteClasses(from: classes[0], to: classes[1]);

    expect(route.fromTitle, '진로설계 · 인문학관302');
    expect(route.toTitle, '컴퓨터개론 · 공대가동B105');
    expect(route.fromTime, '12:15 끝');
    expect(route.toTime, '12:30 시작');
    expect(route.toRoom, '공대가동B105');
    expect(route.spareMinutes, 15);
  });

  testWidgets('출발·도착 카드: 글자를 보여 주고 바꾸기를 알려 준다', (tester) async {
    var swaps = 0;
    await tester.pumpWidget(
      _wrap(
        RouteEndpointsCard(
          originTitle: '진로설계 · 인문학관302',
          destinationTitle: null,
          originTime: '12:15 끝',
          onTapOrigin: () {},
          onTapDestination: () {},
          onSwap: () => swaps++,
        ),
      ),
    );

    expect(find.text('출발점'), findsOneWidget);
    expect(find.text('진로설계 · 인문학관302'), findsOneWidget);
    expect(find.text('12:15 끝'), findsOneWidget);
    expect(find.text('건물 선택'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('출발점과 도착점 바꾸기'));
    await tester.pumpAndSettle();
    expect(swaps, 1);
  });

  testWidgets('길안내 시트: 여유 시간은 있을 때만, 도착 예정은 늘 보인다', (tester) async {
    var starts = 0;
    Widget sheet(int? spare) => _wrap(
      RouteSheet(
        destinationName: '공대가동B105',
        walkMinutes: 7,
        distanceMeters: 480.2,
        arrivalTime: '12:22',
        spareMinutes: spare,
        onStart: () => starts++,
      ),
    );

    await tester.pumpWidget(sheet(8));
    expect(find.text('여유 시간 8분'), findsOneWidget);
    expect(find.text('걸어서 7분 · 480m · 12:22 도착 예정'), findsOneWidget);

    await tester.tap(find.text('안내 시작'));
    await tester.pumpAndSettle();
    expect(starts, 1);

    await tester.pumpWidget(sheet(null));
    expect(find.textContaining('여유 시간'), findsNothing);
  });
}
