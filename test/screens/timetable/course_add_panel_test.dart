// "과목 추가" 버튼을 누르면 검색 패널이 올라오고, "담기"로 과목이 시간표에
// 담기는지 확인한다.
import 'package:daejin_app/screens/home/widgets/home_bottom_nav.dart';
import 'package:daejin_app/screens/timetable/models/saved_timetable.dart';
import 'package:daejin_app/screens/timetable/services/saved_timetable_storage.dart';
import 'package:daejin_app/screens/timetable/timetable_screen.dart';
import 'package:daejin_app/screens/timetable/widgets/course_block.dart';
import 'package:daejin_app/screens/timetable/widgets/course_result_tile.dart';
import 'package:daejin_app/services/fakes/fake_course_catalog_service.dart';
import 'package:daejin_app/services/my_timetable_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStorage implements SavedTimetableStorage {
  @override
  Future<List<SavedTimetable>> loadAll() async => [];

  @override
  Future<void> save(SavedTimetable timetable) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app() => MaterialApp(
  home: TimetableScreen(
    jsessionId: 'j',
    wmonid: 'w',
    userId2: 'u',
    courseCatalogService: FakeCourseCatalogService(),
    myTimetableService: _NoCoursesTimetable(),
    savedTimetableStorage: _FakeStorage(),
  ),
);

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

/// 새 상단(2026-11-16): "과목 추가"는 연필 버튼(시간표가 비어 있으면 가운데
/// "시간표 만들기" 버튼)이 대신한다. 열리면 "시간표 만들기" 화면이 되고 뒤로가기로 닫는다.
Future<void> _tapAddCourse(WidgetTester tester) async {
  // 열려 있으면("시간표 만들기" 편집 화면) 뒤로가기로 닫는다.
  final back = find.byKey(const ValueKey('timetable-edit-back'));
  final edit = find.byKey(const ValueKey('timetable-edit'));
  await tester.tap(
    back.evaluate().isNotEmpty
        ? back
        : edit.evaluate().isNotEmpty
        ? edit
        : find.byKey(const ValueKey('timetable-create')),
  );
}

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

    await _tapAddCourse(tester);
    await tester.pumpAndSettle();

    expect(find.text('과목코드, 교수명, 과목명 검색'), findsOneWidget);
    // 담기·강의계획서는 줄을 눌러 펼쳐야 보인다(팝업 대신, 2026-11-16).
    expect(find.text('담기'), findsNothing);
    expect(tester.takeException(), isNull);

    final firstTile = find.byType(CourseResultTile).first;
    await tester.tap(
      find.descendant(of: firstTile, matching: find.byType(Text)).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('담기'), findsOneWidget);
    expect(find.text('강의계획서'), findsOneWidget);
    expect(find.byType(Dialog), findsNothing); // 팝업은 뜨지 않는다.

    await tester.tap(find.text('담기'));
    await tester.pumpAndSettle();
    expect(find.text('담음'), findsOneWidget); // 담은 과목은 다시 못 담는다.
    expect(tester.takeException(), isNull);

    // 시간표 격자의 그 과목을 눌러도 팝업 대신 아래 시트에 펼쳐진다. 오른쪽 위
    // ×(삭제)를 피해 블록 왼쪽 아래를 누른다.
    final block = find.byType(CourseBlock).first;
    await tester.tapAt(tester.getBottomLeft(block) + const Offset(8, -8));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('강의계획서'), findsOneWidget);

    await _tapAddCourse(tester);
    await tester.pumpAndSettle();
    // 담은 게 있어 확인창이 뜬다 — "나가기".
    await tester.tap(find.byKey(const ValueKey('edit-leave-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('과목코드, 교수명, 과목명 검색'), findsNothing);
  });

  testWidgets('시간표 만들기 화면: 상단·버튼이 바뀌고, 손잡이로 시트를 최소~최대로 끈다', (tester) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    tester.takeException();

    await _tapAddCourse(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('timetable-edit-back')), findsOneWidget);
    expect(find.text('저장'), findsOneWidget);
    expect(find.text('자동 생성'), findsOneWidget);
    expect(find.text('내 시간표 불러오기'), findsOneWidget);

    final search = find.text('과목코드, 교수명, 과목명 검색');
    final minTop = tester.getTopLeft(search).dy;
    // 손잡이(검색창 바로 위)를 위로 끌면 시트가 최대로 올라간다.
    await tester.dragFrom(
      tester.getTopLeft(search) + const Offset(150, -20),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    final maxTop = tester.getTopLeft(search).dy;
    expect(maxTop, lessThan(minTop - 200));
    // 시트 높이 차이는 화면의 31%(844 * 0.31 ≈ 262)쯤이다.
    expect(minTop - maxTop, closeTo(844 * 0.31, 2));

    // 뒤로가기로 닫으면 원래 시간표 상단으로 돌아온다.
    await _tapAddCourse(tester);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('timetable-edit-back')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('시간표 만들기 화면에서는 과목 블록 오른쪽 위 ×(누르는 범위 44)로 과목을 뺀다', (tester) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    tester.takeException();

    await _tapAddCourse(tester);
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .descendant(
            of: find.byType(CourseResultTile).first,
            matching: find.byType(Text),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('담기'));
    await tester.pumpAndSettle();

    final remove = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('course-remove-'),
    );
    // 주 2회 수업이면 블록마다 ×가 하나씩 붙는다.
    expect(remove, findsWidgets);
    expect(tester.getSize(remove.first), const Size(44, 44));

    // ×를 누르면 확인창이 뜨고, 취소하면 그대로다.
    await tester.tap(remove.first);
    await tester.pumpAndSettle();
    expect(find.text('삭제하시겠습니까?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('course-remove-cancel')));
    await tester.pumpAndSettle();
    expect(remove, findsWidgets);

    // 삭제를 누르면 빠진다.
    await tester.tap(remove.first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('course-remove-confirm')));
    await tester.pumpAndSettle();
    expect(remove, findsNothing);
    expect(find.text('담기'), findsOneWidget); // 빠졌으니 다시 담을 수 있다.
    expect(tester.takeException(), isNull);
  });

  testWidgets('일반 화면에서 과목 블록을 눌러도 팝업 없이 시간표 만들기가 열리고 그 과목이 펼쳐진다', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    tester.takeException();

    // 과목 하나를 담고 일반 화면으로 돌아온다.
    await _tapAddCourse(tester);
    await tester.pumpAndSettle();
    final firstTile = find.byType(CourseResultTile).first;
    final name = tester.widget<CourseResultTile>(firstTile).course.courseName;
    await tester.tap(
      find.descendant(of: firstTile, matching: find.byType(Text)).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('담기'));
    await tester.pumpAndSettle();
    await _tapAddCourse(tester); // 뒤로가기
    await tester.pumpAndSettle();
    // 담은 게 있으니 "작성 중인 내용이 있어요"가 뜬다. "계속 작성"이면 그대로 남는다.
    expect(find.text('작성 중인 내용이 있어요'), findsOneWidget);
    expect(find.text('지금 나가면 내용이 저장되지 않아요.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('edit-leave-cancel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('timetable-edit-back')), findsOneWidget);

    // 저장하면 뒤로가기 때 묻지 않고 담은 과목도 남는다.
    await tester.tap(find.byKey(const ValueKey('timetable-edit-save')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4)); // 저장 안내 배너 타이머 비우기
    await tester.pumpAndSettle();
    await _tapAddCourse(tester); // 뒤로가기
    await tester.pumpAndSettle();
    expect(find.text('작성 중인 내용이 있어요'), findsNothing);
    expect(find.byKey(const ValueKey('timetable-edit-back')), findsNothing);

    // 일반 화면의 블록을 누른다.
    final block = find.descendant(
      of: find.byType(CourseBlock),
      matching: find.text(name),
    );
    expect(block, findsWidgets);
    await tester.tap(block.first);
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
    expect(find.byKey(const ValueKey('timetable-edit-back')), findsOneWidget);
    expect(find.text('강의계획서'), findsOneWidget);
    expect(find.text('담음'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('시간표 만들기에서 담고 뒤로가기 → "나가기"면 담은 과목이 빠진다', (tester) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    tester.takeException();

    final blocksBefore = find.byType(CourseBlock).evaluate().length;
    await _tapAddCourse(tester);
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .descendant(
            of: find.byType(CourseResultTile).first,
            matching: find.byType(Text),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('담기'));
    await tester.pumpAndSettle();
    expect(
      find.byType(CourseBlock).evaluate().length,
      greaterThan(blocksBefore),
    );

    await _tapAddCourse(tester); // 뒤로가기
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('edit-leave-confirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('timetable-edit-back')), findsNothing);
    expect(find.byType(CourseBlock).evaluate().length, blocksBefore);
    expect(tester.takeException(), isNull);
  });

  testWidgets('시간표 만들기에서 아무것도 안 바꾸고 뒤로가기면 묻지 않고 닫힌다', (tester) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    tester.takeException();

    await _tapAddCourse(tester);
    await tester.pumpAndSettle();
    await _tapAddCourse(tester); // 뒤로가기
    await tester.pumpAndSettle();
    expect(find.text('작성 중인 내용이 있어요'), findsNothing);
    expect(find.byKey(const ValueKey('timetable-edit-back')), findsNothing);
  });

  testWidgets('필터를 열어도 시트가 위로 튀어 오르지 않는다', (tester) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    tester.takeException();

    await _tapAddCourse(tester);
    await tester.pumpAndSettle();
    final search = find.text('과목코드, 교수명, 과목명 검색');
    final before = tester.getTopLeft(search).dy;
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(search).dy, before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('필터를 접으면 고른 값이 풀리고 칩도 남지 않는다', (tester) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    tester.takeException();

    await _tapAddCourse(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('학년'));
    await tester.pumpAndSettle();
    final option = find.textContaining('학년').last;
    final label = tester.widget<Text>(option).data!;
    await tester.tap(option);
    await tester.pumpAndSettle();
    expect(find.text(label), findsOneWidget); // 위 칩에만 보인다.

    await tester.tap(find.byIcon(Icons.tune_rounded)); // 필터 접기
    await tester.pumpAndSettle();
    expect(find.text(label), findsNothing);

    await tester.tap(find.byIcon(Icons.tune_rounded)); // 다시 펴면 '학년'으로
    await tester.pumpAndSettle();
    expect(find.text('학년'), findsOneWidget);
    expect(tester.takeException(), isNull);
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

    await _tapAddCourse(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final midway = searchTop();
    await tester.pumpAndSettle();
    expect(searchTop(), lessThan(midway), reason: '올라오는 중이었다');
    expect(find.byType(HomeBottomNav), findsNothing);

    await _tapAddCourse(tester);
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
