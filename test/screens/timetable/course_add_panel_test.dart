// "과목 추가" 버튼을 누르면 검색 패널이 올라오고, "담기"로 과목이 시간표에
// 담기는지 확인한다.
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
}
