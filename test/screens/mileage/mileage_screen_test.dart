// MileageScreen이 실제 서비스(가짜로 대체) 결과를 그리고, 학번·비밀번호 입력,
// 오류, 당겨서 새로고침, 장학 대상자 확인까지 이어지는지 확인한다.

import 'package:daejin_app/screens/mileage/mileage_screen.dart';
import 'package:daejin_app/screens/notice/models/notice_item.dart';
import 'package:daejin_app/services/mileage_service.dart';
import 'package:daejin_app/services/twin_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeMileage implements MileageServiceBase {
  _FakeMileage({this.failure, this.history = _history});

  TwinFailure? failure;
  final List<MileageEntry> history;
  final calls = <({String userId, bool forceRefresh})>[];
  final checked = <({String detailPath, String studentId})>[];
  MileageTargetResult targetResult = MileageTargetResult.target;

  static const _history = [
    MileageEntry(
      date: '2026-10-08',
      category: '봉사활동',
      title: '신입생 멘토링 참여',
      points: 20,
    ),
    MileageEntry(
      date: '2026-03-15',
      category: '학술활동',
      title: '학과 세미나 참석',
      points: 3,
    ),
  ];

  @override
  Future<MileageStatus> fetchStatus({
    required String userId,
    required String userPwd,
    bool forceRefresh = false,
  }) async {
    calls.add((userId: userId, forceRefresh: forceRefresh));
    final f = failure;
    if (f != null) throw TwinException(f, 'fail');
    return MileageStatus(
      points: 1240,
      sameGradeRank: 12,
      history: history,
      fetchedAt: DateTime(2026, 10, 31),
    );
  }

  @override
  Future<List<NoticeItem>> fetchTargetNotices({
    bool forceRefresh = false,
  }) async => const [
    NoticeItem(
      title: '2026학년도 1학기 마일리지장학 대상자 공지',
      author: '학생지원팀',
      date: '2026.03.30',
      viewCount: 120,
      tag: NoticeTag.scholarship,
      detailPath: '/bbs/daejin/189/10/artclView.do',
    ),
    NoticeItem(
      title: '2025학년도 2학기 마일리지장학 대상자 공지',
      author: '학생지원팀',
      date: '2025.09.30',
      viewCount: 98,
      tag: NoticeTag.scholarship,
      detailPath: '/bbs/daejin/189/8/artclView.do',
    ),
  ];

  @override
  Future<MileageTargetResult> checkTarget({
    required String detailPath,
    required String studentId,
  }) async {
    checked.add((detailPath: detailPath, studentId: studentId));
    return targetResult;
  }
}

Widget _app(
  _FakeMileage service, {
  ({String userId, String userPwd})? stored = (
    userId: '11110001',
    userPwd: 'pw',
  ),
}) => MaterialApp(
  home: MileageScreen(
    service: service,
    readCredentials: () async => stored,
    now: () => DateTime(2026, 10, 31),
  ),
);

void main() {
  testWidgets('내 점수 · 이번 학기 합계 · 적립 내역을 그리고 API에 없는 값은 숨긴다', (tester) async {
    await tester.pumpWidget(_app(_FakeMileage()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('모은 마일리지'), findsOneWidget);
    expect(find.text('1,240'), findsOneWidget);
    expect(find.text('+20P'), findsOneWidget, reason: '9월 이후 내역만 이번 학기');
    expect(find.text('신입생 멘토링 참여'), findsOneWidget);
    expect(find.text('2026.10.08 · 봉사활동'), findsOneWidget);
    expect(find.text('+20'), findsOneWidget);
    expect(find.text('학과 세미나 참석'), findsOneWidget);

    expect(find.textContaining('실버까지'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('2,000P'), findsNothing);
  });

  testWidgets('적립 내역이 없으면 안내 문구를 보여준다', (tester) async {
    await tester.pumpWidget(_app(_FakeMileage(history: const [])));
    await tester.pumpAndSettle();
    expect(find.text('적립 내역이 없어요'), findsOneWidget);
    expect(find.text('+0P'), findsOneWidget);
  });

  testWidgets('저장된 학번이 없으면 입력받아 조회한다', (tester) async {
    final service = _FakeMileage();
    await tester.pumpWidget(_app(service, stored: null));
    await tester.pumpAndSettle();

    expect(find.text('학번과 비밀번호가 필요해요'), findsOneWidget);
    expect(service.calls, isEmpty);

    await tester.enterText(find.byType(TextField).at(0), '22220002');
    await tester.enterText(find.byType(TextField).at(1), 'pw');
    await tester.tap(find.text('마일리지 보기'));
    await tester.pumpAndSettle();

    expect(service.calls.single.userId, '22220002');
    expect(find.text('1,240'), findsOneWidget);
  });

  testWidgets('입력한 학번·비밀번호가 틀리면 오류와 함께 다시 입력받는다', (tester) async {
    final service = _FakeMileage(failure: TwinFailure.loginFailed);
    await tester.pumpWidget(_app(service, stored: null));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '22220002');
    await tester.enterText(find.byType(TextField).at(1), 'wrong');
    await tester.tap(find.text('마일리지 보기'));
    await tester.pumpAndSettle();

    expect(find.text('학번과 비밀번호가 필요해요'), findsOneWidget);
    expect(find.textContaining('T-WIN 로그인에 실패했어요'), findsOneWidget);
  });

  testWidgets('통신이 실패하면 안내와 다시 시도 버튼을 보여준다', (tester) async {
    final service = _FakeMileage(failure: TwinFailure.network);
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    expect(find.text('네트워크 연결을 확인해 주세요.'), findsOneWidget);
    service.failure = null;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('1,240'), findsOneWidget);
  });

  testWidgets('당겨서 새로고침하면 캐시를 무시하고 새로 받는다', (tester) async {
    final service = _FakeMileage();
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    await tester.fling(find.text('모은 마일리지'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(service.calls.map((c) => c.forceRefresh), [false, true]);
  });

  testWidgets('장학 대상자 → 공지 목록 → 대상자 확인 결과만 보여준다', (tester) async {
    final service = _FakeMileage();
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    await tester.tap(find.text('장학 대상자'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('대상자 확인'), findsNWidgets(2));
    expect(find.textContaining('학생지원팀'), findsNWidgets(2));

    await tester.tap(find.text('대상자 확인').first);
    await tester.pumpAndSettle();
    expect(find.text('축하해요! 대상자 명단에 있어요'), findsOneWidget);
    expect(service.checked.single, (
      detailPath: '/bbs/daejin/189/10/artclView.do',
      studentId: '11110001',
    ));
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    service.targetResult = MileageTargetResult.notTarget;
    await tester.tap(find.text('대상자 확인').last);
    await tester.pumpAndSettle();
    expect(find.text('아쉽게도 대상자 명단에 없어요..'), findsOneWidget);
    expect(find.text('명단보기'), findsNothing, reason: '다른 학생 명단은 보여주지 않는다');
  });

  testWidgets('작은 화면(360w)에서도 넘치지 않는다', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(_FakeMileage()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
