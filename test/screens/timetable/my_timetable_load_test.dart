// 시간표 화면의 "내 시간표 불러오기"가 서비스 결과에 따라 그리드를 채우거나,
// 빈 상태 안내 / 실패 안내 + 다시 시도를 보여주는지 확인한다.
import 'package:daejin_app/screens/timetable/models/saved_timetable.dart';
import 'package:daejin_app/screens/timetable/services/saved_timetable_storage.dart';
import 'package:daejin_app/screens/timetable/timetable_screen.dart';
import 'package:daejin_app/services/course_catalog_service.dart';
import 'package:daejin_app/services/fakes/fake_course_catalog_service.dart';
import 'package:daejin_app/services/my_timetable_service.dart';
import 'package:daejin_app/services/session_cache.dart';
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

Future<void> _pump(WidgetTester tester, _FakeService service) async {
  tester.view.physicalSize = const Size(780, 1688);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: TimetableScreen(
        jsessionId: 'j',
        wmonid: 'w',
        userId2: 'u',
        courseCatalogService: FakeCourseCatalogService(),
        myTimetableService: service,
        savedTimetableStorage: _FakeStorage(),
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
}
