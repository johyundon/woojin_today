// 시간표 화면에서 자동 생성을 끝까지 누르면, 내 정보의 학과로 학과별
// 개설과목을 한 번 불러와 다른 학과 전공을 빼고 추천하는지 확인한다.

import 'package:daejin_app/screens/timetable/models/saved_timetable.dart';
import 'package:daejin_app/screens/timetable/services/saved_timetable_storage.dart';
import 'package:daejin_app/screens/timetable/timetable_screen.dart';
import 'package:daejin_app/services/course_catalog_service.dart';
import 'package:daejin_app/services/student_info_service.dart';
import 'package:daejin_app/services/my_timetable_service.dart';
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
final _business = _item('B1', '경영학과전공', '전선', '금09:00-11:00');

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
    if (icKwa == '%') return [_mine1, _mine2, _other, _general, _business];
    return icKwa1 == 'AA0242' ? [_business] : [_mine1, _mine2];
  }
}

/// 이번 학기에 수강 과목이 없는 학생(수강신청 전). 등록된 시간표가 있으면 과목
/// 추가·자동 생성 버튼이 숨겨지므로, 편집 기능을 확인하는 이 테스트는 빈
/// 시간표로 연다.
class _NoCoursesTimetable implements MyTimetableServiceBase {
  @override
  Future<MyTimetableResponse> fetchMyTimetable({
    required int year,
    required int semester,
    required String jsessionId,
    required String wmonid,
    required String userId2,
  }) async => const MyTimetableResponse(courses: []);
}

/// 개설과목이 아직 하나도 올라오지 않은 학기.
class _EmptyCatalog implements CourseCatalogServiceBase {
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
  }) async => [];
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('개설과목이 아직 없으면 시간표 만들기에서 알림창을 띄운다', (tester) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: TimetableScreen(
          jsessionId: 'empty-j',
          wmonid: 'empty-w',
          userId2: 'empty-u',
          courseCatalogService: _EmptyCatalog(),
          myTimetableService: _NoCoursesTimetable(),
          studentInfoService: _FakeStudentInfo(),
          savedTimetableStorage: _FakeStorage(),
          now: () => DateTime(2026, 10, 26, 9),
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

    expect(find.text('아직 시간표가 나오지 않았어요'), findsOneWidget);
    expect(find.textContaining('2026년 2학기 시간표가 아직 나오지 않아서'), findsOneWidget);
    // 결과 화면으로 넘어가지 않는다.
    expect(find.text('이 시간표 할래요'), findsNothing);
  });

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
          myTimetableService: _NoCoursesTimetable(),
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
    expect(find.textContaining('경영학과전공'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('설문에서 타전공 학과를 고르면 그 학과 전공도 담는다', (tester) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final catalog = _RecordingCatalog();
    await tester.pumpWidget(
      MaterialApp(
        home: TimetableScreen(
          jsessionId: 'second-j',
          wmonid: 'second-w',
          userId2: 'second-u',
          courseCatalogService: catalog,
          myTimetableService: _NoCoursesTimetable(),
          studentInfoService: _FakeStudentInfo(),
          savedTimetableStorage: _FakeStorage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    tester.takeException(); // 첫 프레임(실측 전) 일시 오버플로우는 기존 동작.

    await tester.tap(find.text('자동 생성'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
    }

    // 4/5: 타전공 학과를 고르기 전에는 주전공/타전공 슬라이더가 없다.
    expect(find.textContaining('주전공 '), findsNothing);
    await tester.tap(find.text('선택 안 함'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '경영');
    await tester.pumpAndSettle();
    await tester.tap(find.text('경영학과'));
    await tester.pumpAndSettle();
    expect(find.text('경영학과'), findsOneWidget);
    expect(find.textContaining('주전공 '), findsOneWidget);

    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('시간표 만들기'));
    await tester.pumpAndSettle();

    expect(catalog.calls, contains(('B41005', 'AA0242')));
    expect(find.textContaining('경영학과전공'), findsWidgets);
    expect(find.textContaining('다른학과전공'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
