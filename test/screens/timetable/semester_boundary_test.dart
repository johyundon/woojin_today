// 시간표 화면이 오늘 날짜로 학기를 정해 그 학기 시간표를 불러오는지, 그리고 학기가
// 바뀌는 날(2월 1일 → 1학기, 8월 1일 → 2학기, 1월은 전년도 2학기)이 맞는지 확인한다.

import 'package:daejin_app/screens/timetable/models/saved_timetable.dart';
import 'package:daejin_app/screens/timetable/services/saved_timetable_storage.dart';
import 'package:daejin_app/screens/timetable/timetable_screen.dart';
import 'package:daejin_app/services/course_catalog_service.dart';
import 'package:daejin_app/services/my_timetable_service.dart';
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
  }) async => const StudentInfoResponse(department: '컴퓨터공학전공');
}

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

/// 어느 학기 시간표를 요청했는지 적어 둔다.
class _RecordingTimetable implements MyTimetableServiceBase {
  final requested = <String>[];

  @override
  Future<MyTimetableResponse> fetchMyTimetable({
    required int year,
    required int semester,
    required String jsessionId,
    required String wmonid,
    required String userId2,
  }) async {
    requested.add('$year-$semester');
    return const MyTimetableResponse(courses: []);
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final (now, expected) in [
    (DateTime(2026, 10, 26), '2026-2'),
    (DateTime(2027, 1, 31), '2026-2'),
    (DateTime(2027, 2, 1), '2027-1'),
    (DateTime(2027, 7, 31), '2027-1'),
    (DateTime(2027, 8, 1), '2027-2'),
    (DateTime(2027, 12, 31), '2027-2'),
  ]) {
    testWidgets('${now.month}월 ${now.day}일에는 $expected 시간표를 연다', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(780, 2400);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final timetable = _RecordingTimetable();
      // 세션 캐시가 테스트끼리 섞이지 않게 날짜마다 다른 세션 값을 쓴다.
      final session = 'sem-${now.toIso8601String()}';

      await tester.pumpWidget(
        MaterialApp(
          home: TimetableScreen(
            jsessionId: session,
            wmonid: session,
            userId2: session,
            courseCatalogService: _EmptyCatalog(),
            myTimetableService: timetable,
            studentInfoService: _FakeStudentInfo(),
            savedTimetableStorage: _FakeStorage(),
            now: () => now.add(const Duration(hours: 9)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(timetable.requested.first, expected);
      final parts = expected.split('-');
      expect(find.text('${parts[0]}년 ${parts[1]}학기'), findsWidgets);
    });
  }
}
