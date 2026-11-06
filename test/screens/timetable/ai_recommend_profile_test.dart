// 시간표 화면에서 자동 생성을 끝까지 누르면, 내 정보의 학과로 학과별
// 개설과목을 한 번 불러와 다른 학과 전공을 빼고 추천하는지 확인한다.

import 'package:daejin_app/screens/timetable/models/saved_timetable.dart';
import 'package:daejin_app/screens/timetable/services/saved_timetable_storage.dart';
import 'package:daejin_app/screens/timetable/timetable_screen.dart';
import 'package:daejin_app/services/course_catalog_service.dart';
import 'package:daejin_app/services/fakes/fake_my_timetable_service.dart';
import 'package:daejin_app/services/student_info_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeStorage implements SavedTimetableStorage {
  @override
  Future<List<SavedTimetable>> loadAll() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStudentInfo implements StudentInfoServiceBase {
  @override
  Future<StudentInfoResponse> fetchStudentInfo({
    required String userId2,
  }) async => const StudentInfoResponse(
    name: '테스트',
    department: '컴퓨터공학전공',
    grade: '3학년',
  );
}

CourseCatalogItem _item(String code, String name, String type, String time) =>
    CourseCatalogItem(
      seq: 0,
      courseCode: code,
      section: '01',
      courseName: name,
      courseType: type,
      credit: 3,
      targetGrade: '3',
      professor: '',
      rawSchedule: time,
      room: '',
      isClosed: false,
      capacity: 30,
      waitlistCount: 0,
      enrollmentRatio: '',
    );

final _mine1 = _item('M1', '내학과전공1', '전선', '월09:00-11:00');
final _mine2 = _item('M2', '내학과전공2', '전필', '화09:00-11:00');
final _other = _item('X1', '다른학과전공', '전선', '수09:00-11:00');
final _general = _item('G1', '교양과목', '교선', '목09:00-11:00');

/// 전체 조회면 네 과목, 학과별 조회면 내 학과 전공 두 과목을 돌려주고 호출을 적어 둔다.
class _RecordingCatalog implements CourseCatalogServiceBase {
  final calls = <(String, String?)>[];

  @override
  Future<List<CourseCatalogItem>> fetchCourseCatalog({
    required int year,
    required int semester,
    required String jsessionId,
    required String wmonid,
    String icKwa = '%',
    String? icKwa1,
    String? userId,
    bool forceRefresh = false,
  }) async {
    calls.add((icKwa, icKwa1));
    return icKwa == '%' ? [_mine1, _mine2, _other, _general] : [_mine1, _mine2];
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('자동 생성은 내 학과 전공 목록을 불러와 다른 학과 전공을 뺀다', (tester) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final catalog = _RecordingCatalog();
    await tester.pumpWidget(
      MaterialApp(
        home: TimetableScreen(
          jsessionId: 'profile-j',
          wmonid: 'profile-w',
          userId2: 'profile-u',
          courseCatalogService: catalog,
          myTimetableService: FakeMyTimetableService(),
          studentInfoService: _FakeStudentInfo(),
          savedTimetableStorage: _FakeStorage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    tester.takeException(); // 첫 프레임(실측 전) 일시 오버플로우는 기존 동작.

    await tester.tap(find.text('자동 생성'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('시간표 만들기'));
    await tester.pumpAndSettle();

    expect(catalog.calls, contains(('B41005', 'AA0194')));
    // 기본 설문은 전공 100%라 내 학과 전공 두 과목만 담긴다.
    expect(find.textContaining('내학과전공1'), findsWidgets);
    expect(find.textContaining('내학과전공2'), findsWidgets);
    expect(find.textContaining('다른학과전공'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
