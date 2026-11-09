// 시간표 화면의 "내 시간표 불러오기"가 서비스 결과에 따라 그리드를 채우거나,
// 빈 상태 안내 / 실패 안내 + 다시 시도를 보여주는지 확인한다.
import 'package:daejin_app/screens/timetable/models/saved_timetable.dart';
import 'package:daejin_app/screens/timetable/services/saved_timetable_storage.dart';
import 'package:daejin_app/screens/timetable/timetable_screen.dart';
import 'package:daejin_app/screens/timetable/widgets/course_block.dart';
import 'package:daejin_app/screens/timetable/widgets/course_detail_dialog.dart';
import 'package:daejin_app/services/course_catalog_service.dart';
import 'package:daejin_app/services/fakes/fake_course_catalog_service.dart';
import 'package:daejin_app/services/my_timetable_service.dart';
import 'package:daejin_app/services/session_cache.dart';
import 'package:daejin_app/services/syllabus_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStorage implements SavedTimetableStorage {
  @override
  Future<List<SavedTimetable>> loadAll() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 호출될 때마다 [results]를 앞에서부터 하나씩 꺼내 돌려준다. 값이 Exception이면
/// 던진다.
class _FakeService implements MyTimetableServiceBase {
  _FakeService(this.results);

  final List<Object> results;
  int calls = 0;

  @override
  Future<MyTimetableResponse> fetchMyTimetable({
    required int year,
    required int semester,
    required String jsessionId,
    required String wmonid,
    required String userId2,
  }) async {
    final next = results[calls++];
    if (next is Exception) throw next;
    return next as MyTimetableResponse;
  }
}

/// [emptyYear]년 [emptySemester]학기만 개설과목이 아직 안 올라온 것처럼 빈 목록을 돌려준다.
class _CatalogUntil implements CourseCatalogServiceBase {
  _CatalogUntil({required this.emptyYear, required this.emptySemester});

  final int emptyYear;
  final int emptySemester;
  final _real = FakeCourseCatalogService();

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
    if (year == emptyYear && semester == emptySemester) return [];
    return _real.fetchCourseCatalog(
      year: year,
      semester: semester,
      jsessionId: jsessionId,
      wmonid: wmonid,
      icKwa: icKwa,
      icKwa1: icKwa1,
      userId: userId,
      forceRefresh: forceRefresh,
    );
  }
}

const _course = CourseCatalogItem(
  seq: 1,
  courseCode: '900101',
  section: '01',
  courseName: '가상자료구조',
  courseType: '전필',
  credit: 3,
  targetGrade: '',
  professor: '김가상',
  rawSchedule: '월10:00-11:15,수10:00-11:15',
  room: '가상관 101',
  isClosed: false,
  capacity: 0,
  waitlistCount: 0,
  enrollmentRatio: '',
);

/// 강의계획서 요청을 기록만 하고 빈 강의계획서를 돌려준다.
class _FakeSyllabus implements SyllabusServiceBase {
  final requested = <CourseCatalogItem>[];

  @override
  Future<SyllabusDetail> fetchSyllabus({
    required CourseCatalogItem course,
    required int year,
    required int semester,
    required String jsessionId,
    required String wmonid,
    required String userId2,
  }) async {
    requested.add(course);
    final reason = SyllabusService.categoryQuery(course) == null
        ? SyllabusService.unavailableReason(course)
        : null;
    if (reason != null) throw SyllabusUnavailableException(reason);
    return const SyllabusDetail(
      topInfo: [(label: '수업장소', value: '가상관 999')],
      sections: [SyllabusSection(title: '1. 수업의 개요와 유용성', bodyText: '가상 개요')],
    );
  }
}

Future<void> _pump(
  WidgetTester tester,
  _FakeService service, {
  SyllabusServiceBase? syllabus,
  CourseCatalogServiceBase? catalog,
}) async {
  tester.view.physicalSize = const Size(780, 1688);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: TimetableScreen(
        jsessionId: 'j',
        wmonid: 'w',
        userId2: 'u',
        courseCatalogService: catalog ?? FakeCourseCatalogService(),
        myTimetableService: service,
        savedTimetableStorage: _FakeStorage(),
        syllabusService: syllabus,
        now: () => DateTime(2026, 10, 26, 9), // 월요일
      ),
    ),
  );
  await tester.pumpAndSettle();
  tester.takeException(); // 첫 프레임(실측 전) 일시 오버플로우는 기존 동작.
  // 가짜 개설과목 서비스의 0.5초 지연이 끝나도록 시간을 흘려보낸다.
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

void main() {
  setUp(SessionCache.clear);

  testWidgets('화면을 열면 내 시간표 과목이 그리드에 채워진다', (tester) async {
    final service = _FakeService([
      const MyTimetableResponse(courses: [_course]),
    ]);

    await _pump(tester, service);

    expect(service.calls, 1);
    expect(find.text('가상자료구조'), findsWidgets);
    expect(find.text('내 시간표를 불러오지 못했어요.'), findsNothing);
    expect(find.text('이번 학기에 수강신청한 과목이 없어요.'), findsNothing);
  });

  testWidgets('불러오기 버튼을 누르면 위쪽 배너로 알리고, 처음 열 때는 안 띄운다', (tester) async {
    await _pump(
      tester,
      _FakeService([
        const MyTimetableResponse(courses: [_course]),
      ]),
    );
    expect(find.text('내 시간표를 불러왔어요'), findsNothing);

    // 같은 로그인이라 저장된 결과를 다시 쓴다(학교에 다시 묻지 않음).
    await tester.tap(find.text('내 시간표 불러오기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('내 시간표를 불러왔어요'), findsOneWidget);
    expect(find.text('2026년 2학기 1과목'), findsOneWidget);

    // 배너가 저절로 사라질 때까지 기다려 남은 타이머를 비운다.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('이번 학기 등록된 시간표면 저장·자동 생성·과목 추가가 없고, 다른 학기로 바꾸면 보인다', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeService([
        const MyTimetableResponse(courses: [_course]),
        const MyTimetableResponse(courses: []),
      ]),
    );
    // now는 2026년 10월이라 이번 학기는 2026년 2학기다.
    expect(find.text('2026년 2학기'), findsOneWidget);
    expect(find.text('저장'), findsNothing);
    expect(find.text('자동 생성'), findsNothing);
    expect(find.text('과목 추가'), findsNothing);
    expect(find.text('학교에 등록된 이번 학기 시간표예요'), findsOneWidget);

    await tester.tap(find.text('2026년 2학기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2027년 1학기').last);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('저장'), findsOneWidget);
    expect(find.text('자동 생성'), findsOneWidget);
    expect(find.text('과목 추가'), findsOneWidget);
  });

  testWidgets('이번 학기라도 수강 과목이 없으면 저장·자동 생성·과목 추가가 보인다', (tester) async {
    await _pump(tester, _FakeService([const MyTimetableResponse(courses: [])]));

    expect(find.text('2026년 2학기'), findsOneWidget);
    expect(find.text('저장'), findsOneWidget);
    expect(find.text('자동 생성'), findsOneWidget);
    expect(find.text('과목 추가'), findsOneWidget);
  });

  testWidgets('담은 과목이 없을 때 저장을 누르면 알림창을 띄우고 저장하지 않는다', (tester) async {
    await _pump(tester, _FakeService([const MyTimetableResponse(courses: [])]));

    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.text('담은 과목이 없어요'), findsOneWidget);
    expect(find.text('시간표 저장'), findsNothing); // 이름 입력 창은 안 뜬다.

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('담은 과목이 없어요'), findsNothing);
  });

  testWidgets('개설과목이 아직 안 올라온 학기로 바꾸면 알림창으로 알리고 내 시간표는 묻지 않는다', (tester) async {
    final service = _FakeService([
      const MyTimetableResponse(courses: [_course]),
    ]);
    await _pump(
      tester,
      service,
      catalog: _CatalogUntil(emptyYear: 2027, emptySemester: 1),
    );

    await tester.tap(find.text('2026년 2학기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2027년 1학기').last);
    await tester.pumpAndSettle();

    expect(find.text('아직 시간표가 나오지 않았어요'), findsOneWidget);
    expect(find.textContaining('2027년 1학기 시간표가 아직 나오지 않아서'), findsOneWidget);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('아직 시간표가 나오지 않았어요'), findsNothing);
    // 시간표가 안 나온 학기라 내 시간표 불러오기 버튼이 없고, 학교에도 묻지 않았다.
    expect(find.text('내 시간표 불러오기'), findsNothing);
    expect(service.calls, 1); // 처음 화면을 열 때(2026년 2학기) 한 번뿐
  });

  testWidgets('지난 학기는 수강 과목이 없어도 저장·자동 생성·과목 추가가 없다', (tester) async {
    await _pump(
      tester,
      _FakeService([
        const MyTimetableResponse(courses: [_course]),
        const MyTimetableResponse(courses: []),
      ]),
    );

    await tester.tap(find.text('2026년 2학기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2025년 2학기').last);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('지난 학기 시간표예요'), findsOneWidget);
    expect(find.text('지난 학기에 수강신청한 과목이 없어요.'), findsOneWidget);
    expect(find.text('이번 학기에 수강신청한 과목이 없어요.'), findsNothing);
    expect(find.text('저장'), findsNothing);
    expect(find.text('자동 생성'), findsNothing);
    expect(find.text('과목 추가'), findsNothing);
  });

  testWidgets('개설과목이 있는 학기로 바꾸면 알림창이 뜨지 않는다', (tester) async {
    await _pump(
      tester,
      _FakeService([
        const MyTimetableResponse(courses: [_course]),
        const MyTimetableResponse(courses: []),
      ]),
    );

    await tester.tap(find.text('2026년 2학기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2026년 1학기').last);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('아직 시간표가 나오지 않았어요'), findsNothing);
  });

  testWidgets('시간표 과목 칸에는 빼기(×) 버튼이 없다', (tester) async {
    await _pump(
      tester,
      _FakeService([
        const MyTimetableResponse(courses: [_course]),
      ]),
    );

    final block = find.ancestor(
      of: find.text('가상자료구조').first,
      matching: find.byType(CourseBlock),
    );
    expect(block, findsWidgets);
    expect(
      find.descendant(of: block.first, matching: find.byIcon(Icons.close)),
      findsNothing,
    );
  });

  testWidgets('수강 과목이 없으면 빈 상태 안내를 보여준다', (tester) async {
    final service = _FakeService([const MyTimetableResponse(courses: [])]);

    await _pump(tester, service);

    expect(find.text('이번 학기에 수강신청한 과목이 없어요.'), findsOneWidget);
  });

  testWidgets('실패하면 안내와 다시 시도를 보여주고, 다시 시도가 성공하면 채워진다', (tester) async {
    final service = _FakeService([
      const MyTimetableNetworkException('연결 실패'),
      const MyTimetableResponse(courses: [_course]),
    ]);

    await _pump(tester, service);

    expect(find.text('내 시간표를 불러오지 못했어요.'), findsOneWidget);
    expect(find.text('가상자료구조'), findsNothing);

    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(service.calls, 2);
    expect(find.text('내 시간표를 불러오지 못했어요.'), findsNothing);
    expect(find.text('가상자료구조'), findsWidgets);
  });

  testWidgets('과목 상세의 담은인원·학년은 개설과목 목록 값으로 채운다', (tester) async {
    // 내 시간표 응답에는 정원·담은 인원·학년이 없다. 가짜 개설과목의 CS201-01은
    // 정원 40, 담은 인원 2명, 2학년이다.
    const mine = CourseCatalogItem(
      seq: 1,
      courseCode: 'CS201',
      section: '01',
      courseName: '자료구조',
      courseType: '전필',
      credit: 3,
      targetGrade: '',
      professor: '김가상',
      rawSchedule: '월10:00-11:15,수10:00-11:15',
      room: '가상관 101',
      isClosed: false,
      capacity: 0,
      waitlistCount: 0,
      enrollmentRatio: '',
    );
    await _pump(
      tester,
      _FakeService([
        const MyTimetableResponse(courses: [mine]),
      ]),
    );

    await tester.tap(find.text('자료구조').first);
    await tester.pumpAndSettle();

    expect(find.text('담은인원'), findsOneWidget);
    expect(find.text('2/40명'), findsOneWidget);
    expect(find.text('2학년'), findsOneWidget);
  });

  test('학년은 "3학년"처럼, 모르면 "-"', () {
    expect(gradeLabel('3'), '3학년');
    expect(gradeLabel('2학년'), '2학년');
    expect(gradeLabel(''), '-');
  });

  group('시간표 과목 → 상세보기 → 강의계획서', () {
    Future<void> openSyllabus(WidgetTester tester) async {
      await tester.tap(find.text('가상자료구조').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('강의계획서 보기'));
      await tester.pumpAndSettle();
    }

    testWidgets('개설학과가 있는 내 시간표 과목은 학과 행이 보이고 강의계획서가 열린다', (tester) async {
      final syllabus = _FakeSyllabus();
      const course = CourseCatalogItem(
        seq: 1,
        courseCode: '900101',
        section: '01',
        courseName: '가상자료구조',
        courseType: '전필',
        credit: 3,
        targetGrade: '',
        professor: '김가상',
        rawSchedule: '월10:00-11:15,수10:00-11:15',
        room: '가상관 101',
        isClosed: false,
        capacity: 0,
        waitlistCount: 0,
        enrollmentRatio: '',
        department: '컴퓨터공학전공',
      );
      await _pump(
        tester,
        _FakeService([
          const MyTimetableResponse(courses: [course]),
        ]),
        syllabus: syllabus,
      );

      await tester.tap(find.text('가상자료구조').first);
      await tester.pumpAndSettle();
      expect(find.text('컴퓨터공학전공'), findsOneWidget);
      await tester.tap(find.text('강의계획서 보기'));
      await tester.pumpAndSettle();

      expect(syllabus.requested.single.department, '컴퓨터공학전공');
      expect(find.text('가상 개요'), findsOneWidget);
    });

    testWidgets('학과 정보가 없는 전공 과목은 다시 불러오라고 안내한다', (tester) async {
      final syllabus = _FakeSyllabus();
      await _pump(
        tester,
        _FakeService([
          const MyTimetableResponse(courses: [_course]),
        ]),
        syllabus: syllabus,
      );

      await openSyllabus(tester);

      expect(find.textContaining('학과 정보가 없어'), findsOneWidget);
      expect(find.text('다시 시도'), findsNothing);
    });
  });
}
