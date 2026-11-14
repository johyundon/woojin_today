// GraduationCreditScreen이 서비스에서 받은 졸업학점 현황을 오버플로우 없이
// 보여주고, 불러오는 중·실패·다시 시도·새로고침을 처리하는지 확인한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/screens/graduation/graduation_credit_screen.dart';
import 'package:daejin_app/screens/graduation/models/graduation_credit.dart';
import 'package:daejin_app/services/graduation_credit_service.dart';

final _summary = GraduationCreditSummary(
  totalRequired: 126,
  totalEarned: 107,
  gpa: 3.5,
  gpaMinimum: 2.0,
  categories: const [
    GraduationCreditCategory(
      label: '교필',
      earned: 13,
      required: 12,
      courses: [
        GraduationCourseRecord(
          name: '과목01',
          semester: '2021-1',
          credit: 2,
          grade: 'A+',
          area: '교필',
        ),
      ],
    ),
    GraduationCreditCategory(
      label: '교선',
      earned: 4,
      required: 24,
      courses: [
        GraduationCourseRecord(
          name: '균형과목',
          semester: '2023-2',
          credit: 2,
          grade: 'B',
          area: '교선1균형',
        ),
        // 예전에 저장한 값처럼 세부 영역이 비어 있으면 구분 이름(교선)으로 채운다.
        GraduationCourseRecord(
          name: '영역없는과목',
          semester: '2021-1',
          credit: 2,
          grade: 'A',
        ),
      ],
    ),
    GraduationCreditCategory(
      label: '전필',
      earned: 6,
      required: 12,
      courses: [
        GraduationCourseRecord(
          name: '전필과목',
          semester: '2024-1',
          credit: 3,
          grade: 'A',
          area: '전필',
        ),
      ],
    ),
    GraduationCreditCategory(
      label: '전선',
      earned: 48,
      required: 30,
      courses: [
        GraduationCourseRecord(
          name: '수강중과목',
          semester: '2026-2',
          credit: 3,
          grade: '',
          area: '전선',
        ),
      ],
    ),
    GraduationCreditCategory(label: '복전', earned: 0, required: 36),
    GraduationCreditCategory(label: '일선', earned: 9),
  ],
  areas: const [
    GraduationAreaProgress(label: '1', earned: 2, required: 1),
    GraduationAreaProgress(label: '2', earned: 0, required: 1),
    GraduationAreaProgress(label: '7', earned: 6),
  ],
  rules: const ['① 안내문 첫째', '② 안내문 둘째'],
  fetchedAt: DateTime(2026, 10, 31),
);

class _FakeService implements GraduationCreditServiceBase {
  _FakeService(this.results);

  /// 호출마다 차례로 돌려줄 값(예외면 던진다).
  final List<Object> results;
  final List<bool> forceRefreshCalls = [];

  @override
  Future<GraduationCreditSummary> fetchSummary({
    required String userId2,
    bool forceRefresh = false,
  }) async {
    forceRefreshCalls.add(forceRefresh);
    final result = results.removeAt(0);
    if (result is GraduationCreditException) throw result;
    return result as GraduationCreditSummary;
  }
}

Widget _app(GraduationCreditServiceBase service, {String? userId2 = 'uid'}) =>
    MaterialApp(
      home: GraduationCreditScreen(userId2: userId2, service: service),
    );

void main() {
  test('칩은 주전공 → 복수전공 → 교양 순서로 학교 구분을 더해 묶는다', () {
    final groups = GraduationCreditScreen.groupCategories(_summary.categories);
    expect(groups.map((g) => g.label), ['주전공', '복수전공', '교양']);
    final major = groups[0];
    expect(major.earned, 54);
    expect(major.required, 42);
    expect(major.courses.map((c) => c.name), ['전필과목', '수강중과목']);
    expect(groups[1].earned, 0);
    expect(groups[1].required, 36);
    final liberal = groups[2];
    expect(liberal.earned, 17);
    expect(liberal.required, 36);
    expect(liberal.courses.map((c) => c.area), ['교필', '교선1균형', '교선']);
  });

  test('복수전공 기준도 과목도 없으면 복수전공 칩을 빼고, 일선은 칩에 없다', () {
    final groups = GraduationCreditScreen.groupCategories(const [
      GraduationCreditCategory(label: '전선', earned: 3, required: 30),
      GraduationCreditCategory(label: '교필', earned: 2, required: 12),
      GraduationCreditCategory(label: '일선', earned: 9),
    ]);
    expect(groups.map((g) => g.label), ['주전공', '교양']);
  });

  testWidgets('총 이수학점·졸업평점·구분 칩·교양영역·안내문을 보여준다', (tester) async {
    await tester.pumpWidget(_app(_FakeService([_summary])));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('졸업까지\n19학점 남았어요'), findsOneWidget);
    expect(find.text('107/126'), findsOneWidget);
    expect(find.text('3.50'), findsOneWidget);
    expect(find.text('/ 2.00'), findsOneWidget);
    expect(find.text('주전공'), findsOneWidget);
    expect(find.text('복수전공'), findsOneWidget);
    expect(find.text('교양'), findsOneWidget);
    expect(find.text('교필'), findsNothing);
    expect(
      tester.getTopLeft(find.text('주전공')).dx,
      lessThan(tester.getTopLeft(find.text('복수전공')).dx),
    );
    expect(
      tester.getTopLeft(find.text('복수전공')).dx,
      lessThan(tester.getTopLeft(find.text('교양')).dx),
    );

    await tester.scrollUntilVisible(
      find.text('1영역'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('2/1'), findsOneWidget);
    expect(find.text('완료'), findsOneWidget);
    expect(find.text('1 남음'), findsOneWidget);
    expect(find.textContaining('① 안내문 첫째'), findsOneWidget);
    expect(find.textContaining('전부 예시'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('7영역'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('그 밖의 교양 영역'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('칩을 누르면 과목 목록이 뜨고, 수강 중 과목은 "수강중"으로 보인다', (tester) async {
    await tester.pumpWidget(_app(_FakeService([_summary])));
    await tester.pumpAndSettle();

    await tester.tap(find.text('교양'));
    await tester.pumpAndSettle();
    expect(find.text('과목01'), findsOneWidget);
    expect(find.text('A+'), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.tap(find.text('주전공'));
    await tester.pumpAndSettle();
    expect(find.text('수강중과목'), findsOneWidget);
    expect(find.text('수강중'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('상세보기에서 세부 영역·학기로 과목을 거른다', (tester) async {
    await tester.pumpWidget(_app(_FakeService([_summary])));
    await tester.pumpAndSettle();

    await tester.tap(find.text('교양'));
    await tester.pumpAndSettle();
    expect(find.text('전체 영역'), findsOneWidget);
    expect(find.text('전체 학기'), findsOneWidget);
    expect(find.text('과목01'), findsOneWidget);
    expect(find.text('균형과목'), findsOneWidget);
    expect(find.text('영역없는과목'), findsOneWidget);

    await tester.tap(find.text('교선1균형'));
    await tester.pumpAndSettle();
    expect(find.text('과목01'), findsNothing);
    expect(find.text('균형과목'), findsOneWidget);
    expect(find.text('1과목 · 2학점'), findsOneWidget);

    await tester.tap(find.text('전체 영역'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2021-1'));
    await tester.pumpAndSettle();
    expect(find.text('과목01'), findsOneWidget);
    expect(find.text('영역없는과목'), findsOneWidget);
    expect(find.text('균형과목'), findsNothing);
    expect(find.text('2과목 · 4학점'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('실패하면 안내와 다시 시도 버튼을 보여주고, 누르면 새로 받는다', (tester) async {
    final service = _FakeService([
      const GraduationCreditNetworkException('끊김'),
      _summary,
    ]);
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    expect(find.text('인터넷 연결을 확인해주세요.'), findsOneWidget);
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.text('107/126'), findsOneWidget);
    expect(service.forceRefreshCalls, [false, true]);
  });

  testWidgets('불러오는 동안 안내를 보여준다', (tester) async {
    await tester.pumpWidget(_app(_FakeService([_summary])));
    expect(find.text('학교에서 이수구분표를 불러오고 있어요'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('로그인 정보가 없으면 조회하지 않고 안내한다', (tester) async {
    final service = _FakeService([]);
    await tester.pumpWidget(_app(service, userId2: null));
    await tester.pumpAndSettle();

    expect(find.text('로그인 정보가 없어 졸업학점을 불러올 수 없어요.'), findsOneWidget);
    expect(service.forceRefreshCalls, isEmpty);
  });

  testWidgets('당겨서 새로고침하면 저장분 대신 새로 받는다', (tester) async {
    final service = _FakeService([_summary, _summary]);
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    await tester.fling(find.text('107/126'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(service.forceRefreshCalls, [false, true]);
  });

  testWidgets('뒤로가기 버튼이 동작한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GraduationCreditScreen(
                      userId2: 'uid',
                      service: _FakeService([_summary]),
                    ),
                  ),
                ),
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.text('총 이수학점'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(find.text('총 이수학점'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
