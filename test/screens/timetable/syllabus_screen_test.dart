// 강의계획서 화면: 불러오는 중 → 실제 절 내용, 실패 → 다시 시도,
// 찾을 수 없는 과목 → 안내만(다시 시도 없음)을 확인한다.
import 'dart:io';

import 'package:cp949_codec/cp949_codec.dart';
import 'package:daejin_app/screens/timetable/syllabus_screen.dart';
import 'package:daejin_app/services/course_catalog_service.dart';
import 'package:daejin_app/services/session_cache.dart';
import 'package:daejin_app/services/student_info_service.dart';
import 'package:daejin_app/services/syllabus_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _detail = SyllabusService.parseDetail(
  cp949.decode(
    File('test/services/fixtures/syllabus/syllabus_detail_anonymized.html')
        .readAsBytesSync(),
  ),
);

/// 호출될 때마다 [results]를 앞에서부터 꺼낸다. Exception이면 던진다.
class _FakeService implements SyllabusServiceBase {
  _FakeService(this.results);

  final List<Object> results;
  int calls = 0;
  CourseCatalogItem? lastCourse;

  @override
  Future<SyllabusDetail> fetchSyllabus({
    required CourseCatalogItem course,
    required int year,
    required int semester,
    required String jsessionId,
    required String wmonid,
    required String userId2,
  }) async {
    lastCourse = course;
    final next = results[calls++];
    if (next is Exception) throw next;
    return next as SyllabusDetail;
  }
}

const _course = CourseCatalogItem(
  seq: 1,
  courseCode: '922601',
  section: '01',
  courseName: 'AI시대의컴퓨팅사고',
  courseType: '교필',
  credit: 2,
  targetGrade: '',
  professor: '김가상',
  rawSchedule: '수11:30-13:30',
  room: '',
  isClosed: false,
  capacity: 0,
  waitlistCount: 0,
  enrollmentRatio: '',
);

Future<void> _pump(
  WidgetTester tester,
  SyllabusServiceBase service, {
  bool withSession = true,
  CourseCatalogItem course = _course,
  StudentInfoServiceBase? studentInfo,
}) async {
  tester.view.physicalSize = const Size(780, 1688);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: SyllabusScreen(
        course: course,
        year: 2026,
        semester: 2,
        jsessionId: withSession ? 'j' : null,
        wmonid: withSession ? 'w' : null,
        userId2: withSession ? 'u' : null,
        syllabusService: service,
        studentInfoService: studentInfo,
      ),
    ),
  );
}

class _FakeStudentInfo implements StudentInfoServiceBase {
  _FakeStudentInfo(this.department);

  final String? department;

  @override
  Future<StudentInfoResponse> fetchStudentInfo({
    required String userId2,
  }) async => StudentInfoResponse(department: department);
}

/// "과목 추가" 목록에서 고른 전공 과목(개설학과 정보 없음).
const _majorWithoutDepartment = CourseCatalogItem(
  seq: 2,
  courseCode: '252607',
  section: '01',
  courseName: '가상전공과목',
  courseType: '전선',
  credit: 3,
  targetGrade: '3',
  professor: '김가상',
  rawSchedule: '수11:30-13:00',
  room: '',
  isClosed: false,
  capacity: 20,
  waitlistCount: 0,
  enrollmentRatio: '',
);

void main() {
  setUp(SessionCache.clear);

  testWidgets('학과 정보가 없는 전공 과목은 내 학과 전공 목록에서 찾는다', (tester) async {
    final service = _FakeService([_detail]);
    await _pump(
      tester,
      service,
      course: _majorWithoutDepartment,
      studentInfo: _FakeStudentInfo('컴퓨터공학과'),
    );
    await tester.pumpAndSettle();

    // 학생 정보의 "컴퓨터공학과"가 코드표 이름 "컴퓨터공학전공"으로 맞춰진다.
    expect(service.lastCourse?.department, '컴퓨터공학전공');
    expect(find.text('수업의 개요와 유용성'), findsOneWidget);
  });

  testWidgets('내 학과 목록에도 없으면 다른 학과 과목이라고 안내한다', (tester) async {
    await _pump(
      tester,
      _FakeService([
        const SyllabusUnavailableException('강의계획서 목록에 이 과목이 없어요.'),
      ]),
      course: _majorWithoutDepartment,
      studentInfo: _FakeStudentInfo('컴퓨터공학전공'),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('컴퓨터공학전공 전공 목록에 없는 과목이에요.'), findsOneWidget);
    expect(find.text('다시 시도'), findsNothing);
  });

  testWidgets('내 학과를 못 맞추면 과목을 그대로 넘긴다', (tester) async {
    final service = _FakeService([
      const SyllabusUnavailableException('학과 정보가 없어 강의계획서를 찾을 수 없어요.'),
    ]);
    await _pump(
      tester,
      service,
      course: _majorWithoutDepartment,
      studentInfo: _FakeStudentInfo(null),
    );
    await tester.pumpAndSettle();

    expect(service.lastCourse?.department, isNull);
    expect(find.text('학과 정보가 없어 강의계획서를 찾을 수 없어요.'), findsOneWidget);
  });

  testWidgets('불러오면 실제 절 제목·내용과 강의계획서 위쪽 정보를 보여준다', (tester) async {
    await _pump(tester, _FakeService([_detail]));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    // 첫 칸은 기본으로 펼쳐져 있다.
    expect(find.text('수업의 개요와 유용성'), findsOneWidget);
    expect(find.textContaining('본 교과목은'), findsOneWidget);
    expect(find.text('주별 수업계획'), findsOneWidget);
    expect(find.text('학습 평가방법'), findsOneWidget);
    // 강의계획서 값으로 채운 위쪽 정보. 정원(0)과 연구실은 보여주지 않는다.
    expect(find.text('가상관 310 강의실'), findsOneWidget);
    expect(find.text('2.0학점 · 1학년'), findsOneWidget);
    expect(find.text('정원'), findsNothing);
    expect(find.text('연구실'), findsNothing);
    expect(find.text('가상관 101 호'), findsNothing);

    await tester.tap(find.text('학습 평가방법'));
    await tester.pumpAndSettle();
    final evaluation = find.textContaining('출석 20%');
    expect(evaluation, findsOneWidget);
    // 0% 항목은 빠진다.
    expect(find.textContaining('토의/토론'), findsNothing);
  });

  testWidgets('정원이 있는 과목(과목 추가 목록)은 정원을 보여주고 연구실은 보여주지 않는다', (tester) async {
    const withCapacity = CourseCatalogItem(
      seq: 1,
      courseCode: '922601',
      section: '01',
      courseName: 'AI시대의컴퓨팅사고',
      courseType: '교필',
      credit: 2,
      targetGrade: '1',
      professor: '김가상',
      rawSchedule: '수11:30-13:30',
      room: '',
      isClosed: false,
      capacity: 40,
      waitlistCount: 0,
      enrollmentRatio: '30/40',
    );
    await _pump(tester, _FakeService([_detail]), course: withCapacity);
    await tester.pumpAndSettle();

    expect(find.text('정원'), findsOneWidget);
    expect(find.text('40명'), findsOneWidget);
    expect(find.text('연구실'), findsNothing);
    expect(find.text('가상관 101 호'), findsNothing);
  });

  testWidgets('실패하면 안내와 다시 시도, 다시 시도가 성공하면 내용이 나온다', (tester) async {
    final service = _FakeService([
      const SyllabusNetworkException('끊김'),
      _detail,
    ]);
    await _pump(tester, service);
    await tester.pumpAndSettle();

    expect(find.text('강의계획서를 불러오지 못했어요.'), findsOneWidget);
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(service.calls, 2);
    expect(find.text('수업의 개요와 유용성'), findsOneWidget);
  });

  testWidgets('찾을 수 없는 과목은 안내만 하고 다시 시도는 없다', (tester) async {
    await _pump(
      tester,
      _FakeService([
        const SyllabusUnavailableException('이 과목은 강의계획서를 찾을 수 없어요.'),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('이 과목은 강의계획서를 찾을 수 없어요.'), findsOneWidget);
    expect(find.text('다시 시도'), findsNothing);
  });

  testWidgets('로그인 정보가 없으면 요청하지 않고 안내한다', (tester) async {
    final service = _FakeService([]);
    await _pump(tester, service, withSession: false);
    await tester.pumpAndSettle();

    expect(service.calls, 0);
    expect(find.text('로그인 정보가 없어 강의계획서를 불러올 수 없어요.'), findsOneWidget);
  });
}
