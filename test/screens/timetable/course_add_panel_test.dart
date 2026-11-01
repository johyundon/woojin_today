// "과목 추가" 버튼을 누르면 검색 패널이 올라오고, "담기"로 과목이 시간표에
// 담기는지 확인한다.
import 'package:daejin_app/screens/home/widgets/home_bottom_nav.dart';
import 'package:daejin_app/screens/timetable/models/saved_timetable.dart';
import 'package:daejin_app/screens/timetable/services/saved_timetable_storage.dart';
import 'package:daejin_app/screens/timetable/timetable_screen.dart';
import 'package:daejin_app/services/fakes/fake_course_catalog_service.dart';
import 'package:daejin_app/services/fakes/fake_my_timetable_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStorage implements SavedTimetableStorage {
  @override
  Future<List<SavedTimetable>> loadAll() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app() => MaterialApp(
  home: TimetableScreen(
    jsessionId: 'j',
    wmonid: 'w',
    userId2: 'u',
    courseCatalogService: FakeCourseCatalogService(),
    myTimetableService: FakeMyTimetableService(),
    savedTimetableStorage: _FakeStorage(),
  ),
);

void main() {
  testWidgets('"과목 추가"를 누르면 검색 패널이 열리고 담기가 된다', (tester) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    tester.takeException(); // 첫 프레임(실측 전) 일시 오버플로우는 기존 동작.
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull, reason: 'before open');
    expect(find.text('과목코드, 교수명, 과목명 검색'), findsNothing);

    await tester.tap(find.text('과목 추가'));
    await tester.pumpAndSettle();

    expect(find.text('과목코드, 교수명, 과목명 검색'), findsOneWidget);
    expect(find.text('담기'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('담기').first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('과목 추가'));
    await tester.pumpAndSettle();
    expect(find.text('과목코드, 교수명, 과목명 검색'), findsNothing);
  });

  testWidgets('패널은 미끄러져 올라오고, 다 내려간 뒤에 탭 바가 다시 보인다', (tester) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    tester.takeException(); // 첫 프레임(실측 전) 일시 오버플로우는 기존 동작.
    expect(find.byType(HomeBottomNav), findsOneWidget);

    final search = find.text('과목코드, 교수명, 과목명 검색');
    double searchTop() => tester.getTopLeft(search).dy;

    await tester.tap(find.text('과목 추가'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final midway = searchTop();
    await tester.pumpAndSettle();
    expect(searchTop(), lessThan(midway), reason: '올라오는 중이었다');
    expect(find.byType(HomeBottomNav), findsNothing);

    await tester.tap(find.text('과목 추가'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // 내려가는 동안에는 패널이 남아 있고 탭 바는 아직 숨어 있다.
    expect(search, findsOneWidget);
    expect(find.byType(HomeBottomNav), findsNothing);

    await tester.pumpAndSettle();
    expect(search, findsNothing);
    expect(find.byType(HomeBottomNav), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
