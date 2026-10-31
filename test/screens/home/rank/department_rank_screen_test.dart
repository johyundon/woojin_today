// 학과등수 화면이 T-WIN 평점으로 계산한 등수를 보여주는지, 학번·비밀번호가 없을 때
// 입력 폼을 띄우는지, 학년·학과를 바꾸면 그 값으로 다시 조회하는지 확인한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/screens/home/rank/department_rank_screen.dart';
import 'package:daejin_app/services/twin_rank_service.dart';

class _FakeTwin implements TwinRankServiceBase {
  _FakeTwin({this.failure});

  TwinRankFailure? failure;
  final calls = <Map<String, Object>>[];

  @override
  Future<TwinGradeStats> fetchGradeStats({
    required String userId,
    required String userPwd,
    required String sustCd,
    required String shyrCd,
    bool forceRefresh = false,
  }) async {
    calls.add({
      'userId': userId,
      'userPwd': userPwd,
      'sustCd': sustCd,
      'shyrCd': shyrCd,
      'forceRefresh': forceRefresh,
    });
    final f = failure;
    if (f != null) throw TwinRankException(f, 'fail');
    return TwinGradeStats(
      myGpa: 4.34,
      sameGradeAvg: 3.23,
      peerGpas: const [4.1, 4.5, 4.34, 3.9, 3.2, 2.8],
      totalCount: 6,
      fetchedAt: DateTime(2026, 10, 31),
    );
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required _FakeTwin service,
  String? department = '컴퓨터공학전공',
  Credentials? credentials = (userId: '20240001', userPwd: 'pw'),
  double w = 390,
}) async {
  tester.view.physicalSize = Size(w * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: DepartmentRankScreen(
        isDark: true,
        department: department,
        service: service,
        readCredentials: () async => credentials,
        now: () => DateTime(2026, 10, 31),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('저장된 학번으로 학년을 추정해 조회하고 계산한 등수를 보여준다', (tester) async {
    final service = _FakeTwin();
    await _pump(tester, service: service);

    // 2024학번은 2026년 10월에 3학년.
    expect(service.calls.single['sustCd'], 'AA0194');
    expect(service.calls.single['shyrCd'], '3');
    expect(service.calls.single['forceRefresh'], false);

    expect(find.text('컴퓨터공학전공'), findsOneWidget);
    expect(find.text('3학년'), findsOneWidget);
    expect(find.text('학과 6명 중'), findsOneWidget);
    // 4.5 한 명만 나보다 높아서 2등.
    expect(find.text('2'), findsOneWidget);
    expect(find.text('나'), findsOneWidget);
    expect(find.textContaining('4.34'), findsOneWidget);
    expect(find.text('학과 평균보다 1.11'), findsOneWidget);

    // 실제 데이터가 없는 장학·과목별 석차 카드는 보이지 않는다.
    expect(find.text('장학'), findsNothing);
    expect(find.text('과목별 석차'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('"내 정보"의 학년이 있으면 학번 추정 대신 그 학년으로 조회한다', (tester) async {
    final service = _FakeTwin();
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: DepartmentRankScreen(
          isDark: true,
          department: '컴퓨터공학전공',
          grade: 3,
          service: service,
          // 2021학번은 학번으로만 추정하면 4학년이 된다.
          readCredentials: () async => (userId: '20210001', userPwd: 'pw'),
          now: () => DateTime(2026, 10, 31),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(service.calls.single['shyrCd'], '3');
    expect(find.text('3학년'), findsOneWidget);
  });

  testWidgets('저장된 학번·비밀번호가 없으면 입력받아 조회한다', (tester) async {
    final service = _FakeTwin();
    await _pump(tester, service: service, credentials: null);

    expect(find.text('학번과 비밀번호가 필요해요'), findsOneWidget);
    expect(service.calls, isEmpty);

    await tester.enterText(find.byType(TextField).at(0), '20250002');
    await tester.enterText(find.byType(TextField).at(1), 'secret');
    await tester.tap(find.text('등수 보기'));
    await tester.pumpAndSettle();

    expect(service.calls.single['userId'], '20250002');
    expect(service.calls.single['userPwd'], 'secret');
    expect(service.calls.single['shyrCd'], '2');
    expect(find.text('학과 6명 중'), findsOneWidget);
  });

  testWidgets('입력한 비밀번호로 로그인에 실패하면 폼을 다시 보여준다', (tester) async {
    final service = _FakeTwin(failure: TwinRankFailure.loginFailed);
    await _pump(tester, service: service, credentials: null);

    await tester.enterText(find.byType(TextField).at(0), '20250002');
    await tester.enterText(find.byType(TextField).at(1), 'wrong');
    await tester.tap(find.text('등수 보기'));
    await tester.pumpAndSettle();

    expect(find.text('학번과 비밀번호가 필요해요'), findsOneWidget);
    expect(find.textContaining('T-WIN 로그인에 실패했어요'), findsOneWidget);
  });

  testWidgets('통신 실패면 안내와 다시 시도 버튼을 보여준다', (tester) async {
    final service = _FakeTwin(failure: TwinRankFailure.network);
    await _pump(tester, service: service);

    expect(find.text('네트워크 연결을 확인해 주세요.'), findsOneWidget);
    service.failure = null;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('학과 6명 중'), findsOneWidget);
  });

  testWidgets('학과코드를 모르는 학과면 학과를 고르게 한다', (tester) async {
    final service = _FakeTwin();
    await _pump(tester, service: service, department: '없는학과');

    expect(service.calls, isEmpty);
    expect(find.textContaining('학과코드를 몰라요'), findsOneWidget);
    expect(find.text('학과 고르기'), findsOneWidget);
  });

  testWidgets('학년을 바꾸면 그 학년코드로 다시 조회한다', (tester) async {
    final service = _FakeTwin();
    await _pump(tester, service: service);

    await tester.tap(find.text('3학년'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1학년'));
    await tester.pumpAndSettle();

    expect(service.calls.last['shyrCd'], '1');
    expect(find.text('1학년'), findsOneWidget);
  });

  testWidgets('당겨서 새로고침하면 캐시를 무시하고 새로 받는다', (tester) async {
    final service = _FakeTwin();
    await _pump(tester, service: service);

    await tester.fling(find.text('나 몇 등이야?'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(service.calls.last['forceRefresh'], true);
  });

  testWidgets('작은 화면(360w)에서도 넘치지 않는다', (tester) async {
    await _pump(tester, service: _FakeTwin(), w: 360);
    expect(tester.takeException(), isNull);
  });
}
