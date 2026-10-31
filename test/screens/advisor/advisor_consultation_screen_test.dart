// AdvisorConsultationScreen이 지도교수 성함(FakeStudentInfoService)과 T-WIN
// 상담 데이터(가짜 상담 서비스)를 오버플로우 없이 보여주고, 상세보기/교수
// 검색/상담 신청(온라인·방문 두 흐름 모두) 흐름이 제대로 동작하는지, 그리고
// 실제 신청이 막혀 있을 때는 서비스의 신청 함수가 절대 불리지 않는지 확인한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/screens/advisor/advisor_consultation_screen.dart';
import 'package:daejin_app/services/advisor_consultation_service.dart';
import 'package:daejin_app/services/fakes/fake_student_info_service.dart';
import 'package:daejin_app/services/session_cache.dart';
import 'package:daejin_app/services/twin_client.dart';

const _credentials = (userId: '20230000', userPwd: 'pw');

final _overview = AdvisorOverview(
  counts: const {'1_1': 3, '2_1': 2, '1_2': 2, '2_2': 2, '1_3': 1},
  goalCount: 12,
  advisorStaffNo: '1234567',
  history: const [
    ConsultationRecord(
      cnsKeyId: 'K1',
      appliedAt: '2026-09-24',
      method: '온라인상담',
      status: '상담 대기',
    ),
    ConsultationRecord(
      cnsKeyId: 'K2',
      appliedAt: '2026-06-01',
      method: '온라인상담',
      status: '상담 완료',
    ),
  ],
  fetchedAt: DateTime(2026, 10, 31),
);

class _FakeConsultationService implements AdvisorConsultationServiceBase {
  _FakeConsultationService({this.failOverview = false});

  bool failOverview;
  int overviewCalls = 0;
  final List<String> searchQueries = [];
  final List<DateTime> slotDates = [];
  final List<Object> submitted = [];

  @override
  Future<AdvisorOverview> fetchOverview({
    required String userId,
    required String userPwd,
    bool forceRefresh = false,
  }) async {
    overviewCalls++;
    if (failOverview) {
      throw const TwinException(TwinFailure.network, 'offline');
    }
    return _overview;
  }

  @override
  Future<ConsultationDetailInfo> fetchDetail({
    required String userId,
    required String userPwd,
    required ConsultationRecord record,
  }) async => record.cnsKeyId == 'K2'
      ? const ConsultationDetailInfo(
          appliedAt: '2026-06-01',
          status: '상담 완료',
          content: '진로 상담 부탁드립니다.',
          answeredAt: '2026-06-10',
          answerContent: '확인완료',
        )
      : const ConsultationDetailInfo(
          appliedAt: '2026-09-24',
          status: '상담 대기',
          content: '안녕하세요 교수님.',
        );

  @override
  Future<ProfessorSearchPage> searchProfessors({
    required String userId,
    required String userPwd,
    required String query,
    int page = 1,
  }) async {
    searchQueries.add(query);
    return const ProfessorSearchPage(
      professors: [
        ProfessorInfo(staffNo: '7654321', name: '이시진', department: 'AI융합학부'),
        // 지도교수와 같은 사람은 결과에서 빠져야 한다.
        ProfessorInfo(staffNo: '1234567', name: '김민준', department: '컴퓨터공학과'),
      ],
      total: 2,
    );
  }

  @override
  Future<List<VisitSlot>> fetchVisitSlots({
    required String userId,
    required String userPwd,
    required String staffNo,
    required DateTime date,
  }) async {
    slotDates.add(date);
    return [
      VisitSlot(date: DateUtils.dateOnly(date), time: '10:00'),
      VisitSlot(date: DateUtils.dateOnly(date), time: '14:30'),
      // 다른 날짜 칸은 고른 날에 보이지 않아야 한다.
      VisitSlot(
        date: DateUtils.dateOnly(date).add(const Duration(days: 1)),
        time: '11:00',
      ),
    ];
  }

  @override
  Future<void> submitOnline({
    required String userId,
    required String userPwd,
    required OnlineApplyRequest request,
  }) async => submitted.add(request);

  @override
  Future<void> submitVisit({
    required String userId,
    required String userPwd,
    required VisitApplyRequest request,
  }) async => submitted.add(request);
}

Widget _app(
  _FakeConsultationService service, {
  bool allowRealSubmit = false,
  String? userId2 = 'mock-user-id2',
}) => MaterialApp(
  home: AdvisorConsultationScreen(
    userId2: userId2,
    studentInfoService: FakeStudentInfoService(),
    consultationService: service,
    readCredentials: () async => _credentials,
    allowRealSubmit: allowRealSubmit,
  ),
);

/// 신청 탭에서 지도교수(기본 선택) 온라인 상담 4단계를 내용 입력까지 채운다.
Future<void> _fillOnlineSteps(WidgetTester tester) async {
  await tester.tap(find.text('상담 신청'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('다음'));
  await tester.pumpAndSettle();
  final phoneFields = find.byType(TextField);
  await tester.enterText(phoneFields.at(1), '5291');
  await tester.enterText(phoneFields.at(2), '3807');
  await tester.pumpAndSettle();
  await tester.tap(find.text('다음'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).first, 'test@daejin.ac.kr');
  await tester.pumpAndSettle();
  await tester.tap(find.text('다음'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).first, '테스트 상담 내용입니다');
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('상담 신청하기'));
  await tester.pumpAndSettle();
}

void main() {
  // 같은 userId2('mock-user-id2')를 재사용하는 여러 테스트가 서로의 캐시를
  // 보지 않도록 매 테스트 전에 비운다.
  setUp(SessionCache.clear);

  testWidgets('userId2가 있으면 실제(Fake) 지도교수 성함을 불러와 보여준다', (tester) async {
    await tester.pumpWidget(_app(_FakeConsultationService()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('나의 지도교수님'), findsOneWidget);
    expect(find.text('김민준 교수님', findRichText: true), findsOneWidget);
  });

  testWidgets('userId2가 없으면 조회하지 않고 "불러올 수 없어요"로 처리한다', (tester) async {
    await tester.pumpWidget(_app(_FakeConsultationService(), userId2: null));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('불러올 수 없어요'), findsOneWidget);
  });

  testWidgets('현황 탭: 실제 횟수·학기별 표·이력과 상세보기가 동작한다', (tester) async {
    await tester.pumpWidget(_app(_FakeConsultationService()));
    await tester.pumpAndSettle();

    expect(find.text('지금까지 상담 인정 횟수'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('/ 12회'), findsOneWidget);
    // 1학년 1학기 3회(기준 2회), 3학년 1학기 1회(기준 1회), 4학년 2학기 0회.
    expect(find.text('3/2'), findsOneWidget);
    expect(find.text('1/1'), findsOneWidget);
    expect(find.text('6회'), findsOneWidget); // 1학기 합계
    expect(find.text('2026-09-24'), findsOneWidget);
    expect(find.text('대기'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('2026-06-01'), findsOneWidget);

    await tester.tap(find.text('상세보기').last);
    await tester.pumpAndSettle();
    expect(find.text('진로 상담 부탁드립니다.'), findsOneWidget);
    expect(find.text('확인완료'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('진로 상담 부탁드립니다.'), findsNothing);
  });

  testWidgets('현황 탭: 불러오기 실패 시 안내와 다시 시도', (tester) async {
    final service = _FakeConsultationService(failOverview: true);
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    expect(find.text('네트워크 연결을 확인해 주세요.'), findsOneWidget);
    service.failOverview = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('지금까지 상담 인정 횟수'), findsOneWidget);
    expect(service.overviewCalls, 2);
  });

  testWidgets('현황 탭: 이력이 없으면 빈 안내', (tester) async {
    final service = _EmptyHistoryService();
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();
    expect(find.text('아직 상담 신청 이력이 없어요'), findsOneWidget);
  });

  testWidgets('신청 탭: 교수 검색은 검색할 때만 조회하고 지도교수는 맨 위에 고정', (tester) async {
    final service = _FakeConsultationService();
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    await tester.tap(find.text('상담 신청'));
    await tester.pumpAndSettle();
    expect(find.text('김민준 (지도교수)'), findsOneWidget);

    await tester.tap(find.text('변경'));
    await tester.pumpAndSettle();
    expect(find.text('다른 교수님은 이름을 입력하고 검색해 주세요'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '이시진');
    await tester.pumpAndSettle();
    expect(service.searchQueries, isEmpty);

    await tester.tap(find.byKey(const ValueKey('professor-search-button')));
    await tester.pumpAndSettle();
    expect(service.searchQueries, ['이시진']);
    // 지도교수 줄(김민준)은 맨 위 한 번만, 검색 결과에서는 빠진다.
    expect(find.text('김민준'), findsOneWidget);
    expect(find.text('AI융합학부'), findsOneWidget);

    await tester.tap(find.text('이시진').last);
    await tester.pumpAndSettle();
    expect(find.text('이시진 (AI융합학부)'), findsOneWidget);
    expect(find.text('지도교수님이 아니면 상담 인정 횟수에 들어가지 않아요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('신청 탭: 실제 신청이 막혀 있으면 배너만 뜨고 신청 함수는 불리지 않는다', (tester) async {
    final service = _FakeConsultationService();
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();
    await _fillOnlineSteps(tester);

    await tester.tap(find.text('상담 신청하기'));
    await tester.pumpAndSettle();

    expect(find.text('아직 실제 신청은 막혀 있어요'), findsOneWidget);
    expect(find.text('상담 신청이 완료됐어요'), findsNothing);
    expect(service.submitted, isEmpty);
    // 배너가 사라질 때까지 기다린다(타이머 정리).
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('신청 탭: 온라인 상담 4단계와 글자 수 검사, 허용 시 신청 내용', (tester) async {
    final service = _FakeConsultationService();
    await tester.pumpWidget(_app(service, allowRealSubmit: true));
    await tester.pumpAndSettle();

    await tester.tap(find.text('상담 신청'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('전화번호를 입력해주세요'), findsOneWidget);

    final phoneFields = find.byType(TextField);
    expect(phoneFields, findsNWidgets(3));
    await tester.enterText(phoneFields.at(1), '5291');
    await tester.enterText(phoneFields.at(2), '3807');
    await tester.pumpAndSettle();
    // 마지막 칸(4자리)을 다 채우면 키보드가 저절로 내려가야 한다.
    expect(tester.testTextInput.isVisible, isFalse);

    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('이메일을 입력해주세요'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'test@daejin.ac.kr');
    await tester.pumpAndSettle();

    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('어떤 이야기를 나누고 싶어요?'), findsOneWidget);

    // 아무것도 입력하지 않으면 "상담 신청하기"가 눌리지 않는다.
    await tester.tap(find.text('상담 신청하기'), warnIfMissed: false);
    await tester.pump();
    expect(find.textContaining('자 이상 적어주세요 (현재'), findsNothing);

    // 10자 미만이면 신청되지 않고 안내가 뜬다.
    await tester.enterText(find.byType(TextField).first, '짧음');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('상담 신청하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('상담 신청하기'));
    await tester.pumpAndSettle();
    expect(find.text('10자 이상 적어주세요 (현재 2자)'), findsOneWidget);

    // 자음·모음만으로는 글자 수에 포함되지 않는다.
    await tester.enterText(find.byType(TextField).first, 'ㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋ');
    await tester.pumpAndSettle();
    await tester.tap(find.text('상담 신청하기'));
    await tester.pumpAndSettle();
    expect(find.textContaining('(현재 0자)'), findsOneWidget);
    expect(service.submitted, isEmpty);

    await tester.enterText(find.byType(TextField).first, '테스트 상담 내용입니다');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('상담 신청하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('상담 신청하기'));
    await tester.pumpAndSettle();

    expect(find.text('상담 신청이 완료됐어요'), findsOneWidget);
    final request = service.submitted.single as OnlineApplyRequest;
    expect(request.professorStaffNo, '1234567');
    expect(request.phone, '010-5291-3807');
    expect(request.email, 'test@daejin.ac.kr');
    expect(request.content, '테스트 상담 내용입니다');
    expect(request.advisorStaffNo, '1234567');
    expect(request.advisorName, '김민준');
    // 신청 뒤에는 현황을 새로 받는다.
    expect(service.overviewCalls, 2);

    await tester.tap(find.text('상담 현황 보기'));
    await tester.pumpAndSettle();
    expect(find.text('지금까지 상담 인정 횟수'), findsOneWidget);
  });

  testWidgets('신청 탭: 방문 상담은 날짜별 가능 시간을 묻고 전화·이메일까지 4단계', (tester) async {
    final service = _FakeConsultationService();
    await tester.pumpWidget(_app(service, allowRealSubmit: true));
    await tester.pumpAndSettle();

    await tester.tap(find.text('상담 신청'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('방문 상담'));
    await tester.pump();

    // 날짜/시간을 고르기 전에는 "다음"이 비활성 상태다.
    await tester.tap(find.text('다음'), warnIfMissed: false);
    await tester.pump();
    expect(find.text('전화번호를 입력해주세요'), findsNothing);
    expect(find.text('날짜를 먼저 선택해주세요'), findsOneWidget);

    // 오늘은 이미 지난 시간일 수 있어, 다음 달 15일을 고른다.
    final now = DateTime.now();
    final target = DateTime(now.year, now.month + 1, 15);
    await tester.ensureVisible(find.byIcon(Icons.chevron_right));
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    final dateFinder = find.byKey(
      ValueKey('visit-calendar-day-${target.year}-${target.month}-15'),
    );
    await tester.ensureVisible(dateFinder);
    await tester.pumpAndSettle();
    await tester.tap(dateFinder);
    await tester.pumpAndSettle();

    expect(service.slotDates.single, target);
    expect(find.byKey(const ValueKey('visit-time-10:00')), findsOneWidget);
    expect(find.byKey(const ValueKey('visit-time-14:30')), findsOneWidget);
    expect(find.byKey(const ValueKey('visit-time-11:00')), findsNothing);

    final timeFinder = find.byKey(const ValueKey('visit-time-14:30'));
    await tester.ensureVisible(timeFinder);
    await tester.pumpAndSettle();
    await tester.tap(timeFinder);
    await tester.pump();

    final nextFinder = find.text('다음');
    await tester.ensureVisible(nextFinder);
    await tester.pumpAndSettle();
    await tester.tap(nextFinder);
    await tester.pumpAndSettle();
    expect(find.text('전화번호를 입력해주세요'), findsOneWidget);
    expect(find.text('2 / 4'), findsOneWidget);

    final phoneFields = find.byType(TextField);
    await tester.enterText(phoneFields.at(1), '1234');
    await tester.enterText(phoneFields.at(2), '5678');
    await tester.pumpAndSettle();
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('이메일을 입력해주세요'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'a@daejin.ac.kr');
    await tester.pumpAndSettle();
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '방문 상담 테스트 내용');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('상담 신청하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('상담 신청하기'));
    await tester.pumpAndSettle();

    expect(find.text('상담 신청이 완료됐어요'), findsOneWidget);
    final request = service.submitted.single as VisitApplyRequest;
    expect(request.professorStaffNo, '1234567');
    expect(request.slot.date, target);
    expect(request.slot.time, '14:30');
    expect(request.phone, '010-1234-5678');
    expect(request.studentInfo, '20230000 컴퓨터공학과 3학년 홍길동');
    expect(tester.takeException(), isNull);
  });
}

class _EmptyHistoryService extends _FakeConsultationService {
  @override
  Future<AdvisorOverview> fetchOverview({
    required String userId,
    required String userPwd,
    bool forceRefresh = false,
  }) async => AdvisorOverview(
    counts: const {},
    goalCount: 12,
    advisorStaffNo: '1234567',
    history: const [],
    fetchedAt: DateTime(2026, 10, 31),
  );
}
