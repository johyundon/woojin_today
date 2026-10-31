import 'dart:convert';
import 'dart:io';

import 'package:daejin_app/services/advisor_consultation_service.dart';
import 'package:daejin_app/services/twin_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

// fixtures/advisor/*.html은 2026-10-31 실제 응답에서 학번·이름·교수·학과·신청
// 내용·키를 가짜 값으로 바꾼 것이다(학번 20230000, 지도교수 김교수/1234567).

String _fixture(String name) =>
    File('test/services/fixtures/advisor/$name').readAsStringSync();

final _status = _fixture('status.html');
final _historyP1 = _fixture('history_p1.html');
final _detailPending = _fixture('detail_pending.html');
final _profAll = _fixture('prof_search_all.html');
final _profName = _fixture('prof_search_name.html');
final _slotsAllImpossible = _fixture('slots_week.html');

/// 실제 응답에는 가능 칸이 없었으므로, 학교 스크립트가 쓰는 모양
/// (`counsel_possible`, 값 `P`)으로 두 칸을 바꿔 만든다.
final _slotsTwoPossible = _slotsAllImpossible
    .replaceFirst(
      '<label class="counsel_impossible" for="MON_0900">',
      '<label class="counsel_possible" for="MON_0900">',
    )
    .replaceFirst(
      '<label class="counsel_impossible" for="THU_1345">',
      '<label class="counsel_possible" for="THU_1345">',
    );

// 명세 4번 예시 구조(답변이 있는 경우).
const _detailAnswered = '''
<table><tbody>
  <tr><th scope="row">신청일시</th><td>2026-06-01</td></tr>
  <tr><th scope="row">답변일시</th><td>2026-06-10</td></tr>
  <tr><th scope="row">상태</th><td class="font_nightblue bold">상담 완료</td></tr>
  <tr><th scope="row">신청 내용</th><td>상담 부탁드립니다.</td></tr>
  <tr><th scope="row">회신 첨부파일</th><td></td></tr>
  <tr><th scope="row">답변 내용</th><td class="preline"><p>확인완료</p></td></tr>
</tbody></table>
''';

http.Response _html(String body, [int status = 200]) =>
    http.Response.bytes(utf8.encode(body), status);

/// T-WIN 로그인 흐름(together → nsso → together)과 상담 API를 흉내 낸다.
MockClient _server(
  List<http.Request> log, {
  bool loginOk = true,
  String statusBody = '',
  String detailBody = '',
  String slotsBody = '',
  String submitBody = '{"rtnCode":"0"}',
  int ajaxStatus = 200,
}) => MockClient((request) async {
  log.add(request);
  switch (request.url.path) {
    case '/clientMain/a/t/main.do':
      return http.Response(
        '',
        200,
        headers: {'set-cookie': 'JSESSIONID=together-1; Path=/'},
      );
    case '/login/a/n/loginProc.do':
      return http.Response(
        '',
        302,
        headers: {
          'location': loginOk
              ? 'https://nsso.daejin.ac.kr/sso/pmi-sso.jsp'
              : '/login/a/m/loginView.do',
        },
      );
    case '/sso/pmi-sso.jsp':
      return http.Response(
        '',
        302,
        headers: {
          'location': 'https://together.daejin.ac.kr/clientMain/a/t/main.do',
          'set-cookie': 'JSESSIONID=nsso-1; Path=/',
        },
      );
    case '/login/a/m/loginView.do':
      return http.Response('', 200);
  }
  if (ajaxStatus != 200) return http.Response('error', ajaxStatus);
  switch (request.url.path) {
    case '/myStatus/a/n/getMyStatusListAjax.do':
      return _html(statusBody.isEmpty ? _status : statusBody);
    case '/cnsHis/a/n/getCnsHisListAjax.do':
      final page = request.bodyFields['pageIndex']!;
      // 2·3페이지는 1페이지 모양에 키만 바꿔 쓴다.
      return _html(
        page == '1'
            ? _historyP1
            : _historyP1.replaceAll('COM0000000000', 'P${page}_'),
      );
    case '/cnsHis/a/n/getCnsDetailInfoPop.do':
      return _html(detailBody.isEmpty ? _detailPending : detailBody);
    case '/careerCns/a/n/getProfSearchListPop.do':
      return _html(
        request.bodyFields.containsKey('korNm') ? _profName : _profAll,
      );
    case '/cmm/fms/getCnsSchedulCalAjax.do':
      return _html(slotsBody.isEmpty ? _slotsAllImpossible : slotsBody);
    case '/careerCns/w/n/getCnsOnlineApplyAjax.do':
    case '/careerCns/w/n/getCnsOfflineApplyAjax.do':
      return _html(submitBody);
  }
  return http.Response('not found', 404);
});

const _id = '20230000';
const _pw = 'pw&1';

bool _isApi(http.Request r) => !const {
  '/clientMain/a/t/main.do',
  '/login/a/n/loginProc.do',
  '/sso/pmi-sso.jsp',
  '/login/a/m/loginView.do',
}.contains(r.url.path);

int _logins(List<http.Request> log) =>
    log.where((r) => r.url.path == '/login/a/n/loginProc.do').length;

/// multipart 본문에서 텍스트 칸을 이름 → 값으로 뽑는다.
Map<String, String> _multipartFields(http.Request r) {
  final body = utf8.decode(r.bodyBytes);
  return {
    for (final m in RegExp(
      r'content-disposition: form-data; name="([^"]+)"\r\n'
      r'(?:[^\r\n]+\r\n)*\r\n([\s\S]*?)\r\n--',
      caseSensitive: false,
    ).allMatches(body))
      if (!m.group(0)!.contains('filename=')) m.group(1)!: m.group(2)!,
  };
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('상담 인정 현황 + 이력', () {
    test('학기·학년별 횟수, 목표, 지도교수 직번, 이력 전체를 읽는다', () async {
      final log = <http.Request>[];
      final service = AdvisorConsultationService(client: _server(log));
      final overview = await service.fetchOverview(userId: _id, userPwd: _pw);

      expect(overview.counts, {
        '1_1': 3,
        '2_1': 2,
        '1_2': 2,
        '2_2': 2,
        '1_3': 1,
      });
      expect(overview.totalCount, 10);
      expect(overview.countOf(term: 1, grade: 3), 1);
      expect(overview.countOf(term: 2, grade: 4), 0);
      expect(overview.goalCount, 12);
      expect(overview.advisorStaffNo, '1234567');

      // totalCnt 13 → 3페이지를 모두 받아 1→2→3 순서로 잇는다.
      expect(overview.history, hasLength(15));
      final first = overview.history.first;
      expect(first.cnsKeyId, 'COM000000000001');
      expect(first.appliedAt, '2026-09-24');
      expect(first.method, '온라인상담');
      expect(first.status, '상담 대기');
      expect(overview.history[5].cnsKeyId, startsWith('P2_'));
      expect(overview.history[10].cnsKeyId, startsWith('P3_'));

      final status = log.firstWhere(
        (r) => r.url.path == '/myStatus/a/n/getMyStatusListAjax.do',
      );
      expect(status.bodyFields, {
        'userId': '',
        'listType': 'cns',
        'cnsDiv': 'CNSGB01',
      });
      expect(status.headers['IS_AJAX'], 'isAjax');
      final history = log.firstWhere(
        (r) => r.url.path == '/cnsHis/a/n/getCnsHisListAjax.do',
      );
      expect(history.bodyFields, {
        'pageIndex': '1',
        'cnsDiv': 'CNSGB01',
        'regId': _id,
      });
      expect(_logins(log), 1);
    });

    test('7일 동안은 저장분을 쓰고, 새로고침이나 7일이 지나면 다시 받는다', () async {
      final log = <http.Request>[];
      var now = DateTime(2026, 11, 1);
      final service = AdvisorConsultationService(
        client: _server(log),
        now: () => now,
      );

      await service.fetchOverview(userId: _id, userPwd: _pw);
      final afterFirst = log.length;

      now = now.add(const Duration(days: 6));
      await service.fetchOverview(userId: _id, userPwd: _pw);
      expect(log.length, afterFirst);

      await service.fetchOverview(
        userId: _id,
        userPwd: _pw,
        forceRefresh: true,
      );
      expect(log.length, greaterThan(afterFirst));

      final afterRefresh = log.length;
      now = now.add(const Duration(days: 7));
      await service.fetchOverview(userId: _id, userPwd: _pw);
      expect(log.length, greaterThan(afterRefresh));
    });

    test('상담이 한 번도 없으면 0회, 편입생이면 목표 4회', () {
      final (counts, goal, _) = AdvisorConsultationService.parseStatus(
        '<script>function setGraduteCnsStatus() { var cntByGrade = [0,0,0,0]; '
        'var goalCnt = ("B01003" == \'B01003\' ? \'4\' : \'12\'); }</script>',
      );
      expect(counts, isEmpty);
      expect(goal, 4);
    });

    test('횟수 스크립트가 아예 없으면 응답을 못 읽은 것으로 본다', () async {
      final service = AdvisorConsultationService(
        client: _server([], statusBody: '<html>로그인이 필요합니다</html>'),
      );
      await expectLater(
        service.fetchOverview(userId: _id, userPwd: _pw),
        throwsA(
          isA<TwinException>().having(
            (e) => e.failure,
            'failure',
            TwinFailure.noData,
          ),
        ),
      );
    });
  });

  group('상세보기', () {
    const record = ConsultationRecord(
      cnsKeyId: 'COM000000000001',
      appliedAt: '2026-09-24',
      method: '온라인상담',
      status: '상담 대기',
    );

    test('답변 전이면 답변 칸이 비고, 첨부파일 줄은 무시한다', () async {
      final log = <http.Request>[];
      final service = AdvisorConsultationService(client: _server(log));
      final detail = await service.fetchDetail(
        userId: _id,
        userPwd: _pw,
        record: record,
      );
      expect(detail.appliedAt, '2026-09-24');
      expect(detail.status, '상담 대기');
      expect(detail.content, '교수님 상담 신청드립니다.');
      expect(detail.answeredAt, isNull);
      expect(detail.answerContent, isNull);

      final req = log.firstWhere(
        (r) => r.url.path == '/cnsHis/a/n/getCnsDetailInfoPop.do',
      );
      expect(req.bodyFields, {
        'cnsKeyId': 'COM000000000001',
        'cnsOnoffDiv': 'ON',
        'cnsDiv': 'CNSGB01',
      });
    });

    test('답변이 있으면 답변일시와 내용을 읽는다', () {
      final detail = AdvisorConsultationService.parseDetail(_detailAnswered);
      expect(detail.answeredAt, '2026-06-10');
      expect(detail.answerContent, '확인완료');
    });

    test('같은 키·상태면 저장분을 쓰고, 상태가 바뀌면 다시 받는다', () async {
      final log = <http.Request>[];
      final service = AdvisorConsultationService(client: _server(log));
      await service.fetchDetail(userId: _id, userPwd: _pw, record: record);
      await service.fetchDetail(userId: _id, userPwd: _pw, record: record);
      bool isDetail(http.Request r) =>
          r.url.path == '/cnsHis/a/n/getCnsDetailInfoPop.do';
      expect(log.where(isDetail), hasLength(1));

      await service.fetchDetail(
        userId: _id,
        userPwd: _pw,
        record: const ConsultationRecord(
          cnsKeyId: 'COM000000000001',
          appliedAt: '2026-09-24',
          method: '온라인상담',
          status: '상담 완료',
        ),
      );
      expect(log.where(isDetail), hasLength(2));
    });

    test('필수 줄이 없으면 응답을 못 읽은 것으로 본다', () {
      expect(
        () => AdvisorConsultationService.parseDetail(
          '<table><tbody></tbody></table>',
        ),
        throwsA(isA<TwinException>()),
      );
    });
  });

  group('교수 검색', () {
    test('검색어가 없으면 korNm을 빼고 보내고, 전체 인원수와 5명을 읽는다', () async {
      final log = <http.Request>[];
      final service = AdvisorConsultationService(client: _server(log));
      final page = await service.searchProfessors(
        userId: _id,
        userPwd: _pw,
        query: '  ',
      );
      expect(page.total, 436);
      expect(page.professors, hasLength(5));
      final req = log.lastWhere(_isApi);
      expect(req.bodyFields, {'pageIndex': '1'});
    });

    test('이름으로 검색하면 korNm을 보내고 직번·학과를 읽는다', () async {
      final log = <http.Request>[];
      final service = AdvisorConsultationService(client: _server(log));
      final page = await service.searchProfessors(
        userId: _id,
        userPwd: _pw,
        query: '김교수',
        page: 2,
      );
      expect(page.total, 1);
      expect(page.professors.single.name, '김교수');
      expect(page.professors.single.staffNo, '1234567');
      expect(page.professors.single.department, 'AI융합학부');
      expect(log.lastWhere(_isApi).bodyFields, {
        'pageIndex': '2',
        'korNm': '김교수',
      });
    });
  });

  group('방문 가능 시간', () {
    test('학교의 주차 계산(일요일 시작)을 따른다', () {
      expect(AdvisorConsultationService.weekOfMonth(DateTime(2026, 11, 2)), 1);
      expect(AdvisorConsultationService.weekOfMonth(DateTime(2026, 11, 13)), 2);
      expect(AdvisorConsultationService.weekOfMonth(DateTime(2026, 9, 1)), 1);
      expect(AdvisorConsultationService.weekOfMonth(DateTime(2026, 10, 30)), 5);
    });

    test('가능 칸만 날짜·시간으로 바꾸고, 같은 주는 다시 묻지 않는다', () async {
      final log = <http.Request>[];
      final service = AdvisorConsultationService(
        client: _server(log, slotsBody: _slotsTwoPossible),
      );
      final slots = await service.fetchVisitSlots(
        userId: _id,
        userPwd: _pw,
        staffNo: '1234567',
        date: DateTime(2026, 11, 4),
      );
      expect(slots.map((s) => (s.date, s.time)), [
        (DateTime(2026, 11, 2), '09:00'),
        (DateTime(2026, 11, 5), '13:45'),
      ]);
      expect(log.lastWhere(_isApi).bodyFields, {
        'curYear': '2026',
        'curMonth': '11',
        'curWeek': '1',
        'cnsStaffId': '1234567',
        'cnsType': 'PROF',
        'viewType': 'CLIENT',
      });

      final before = log.length;
      await service.fetchVisitSlots(
        userId: _id,
        userPwd: _pw,
        staffNo: '1234567',
        date: DateTime(2026, 11, 6),
      );
      expect(log.length, before);
    });

    test('실제 응답처럼 전부 불가면 빈 목록', () async {
      final service = AdvisorConsultationService(client: _server([]));
      final slots = await service.fetchVisitSlots(
        userId: _id,
        userPwd: _pw,
        staffNo: '1234567',
        date: DateTime(2026, 11, 2),
      );
      expect(slots, isEmpty);
    });
  });

  group('실패 구분과 로그인 재사용', () {
    test('로그인 실패', () async {
      final service = AdvisorConsultationService(
        client: _server([], loginOk: false),
      );
      await expectLater(
        service.fetchOverview(userId: _id, userPwd: _pw),
        throwsA(
          isA<TwinException>().having(
            (e) => e.failure,
            'failure',
            TwinFailure.loginFailed,
          ),
        ),
      );
    });

    test('통신 실패', () async {
      final service = AdvisorConsultationService(
        client: MockClient((_) => throw const SocketException('offline')),
      );
      await expectLater(
        service.fetchOverview(userId: _id, userPwd: _pw),
        throwsA(
          isA<TwinException>().having(
            (e) => e.failure,
            'failure',
            TwinFailure.network,
          ),
        ),
      );
    });

    test('서버 오류 응답이면 noData, 다음 호출은 새로 로그인한다', () async {
      final log = <http.Request>[];
      final service = AdvisorConsultationService(
        client: _server(log, ajaxStatus: 500),
      );
      await expectLater(
        service.searchProfessors(userId: _id, userPwd: _pw, query: ''),
        throwsA(
          isA<TwinException>().having(
            (e) => e.failure,
            'failure',
            TwinFailure.noData,
          ),
        ),
      );
      await expectLater(
        service.searchProfessors(userId: _id, userPwd: _pw, query: ''),
        throwsA(isA<TwinException>()),
      );
      expect(_logins(log), 2);
    });

    test('성공한 로그인은 여러 조회에 재사용한다', () async {
      final log = <http.Request>[];
      final service = AdvisorConsultationService(client: _server(log));
      await service.searchProfessors(userId: _id, userPwd: _pw, query: '');
      await service.fetchVisitSlots(
        userId: _id,
        userPwd: _pw,
        staffNo: '1234567',
        date: DateTime(2026, 11, 2),
      );
      expect(_logins(log), 1);
    });
  });

  group('신청 (가짜 서버로만 확인)', () {
    const online = OnlineApplyRequest(
      professorStaffNo: '1234567',
      content: '진로 상담 부탁드립니다.',
      phone: '010-1234-5678',
      email: '20230000@daejin.ac.kr',
      advisorStaffNo: '1234567',
      advisorName: '김교수',
    );
    final visit = VisitApplyRequest(
      professorStaffNo: '1234567',
      slot: VisitSlot(date: DateTime(2026, 11, 5), time: '13:45'),
      content: '방문 상담 부탁드립니다.',
      phone: '010-1234-5678',
      email: '',
      studentInfo: '20230000 OO전공 3학년 홍길동',
    );

    test('실제 클라이언트로는 요청을 보내기 전에 막는다', () async {
      final sent = <http.BaseRequest>[];
      final service = AdvisorConsultationService(
        client: _RecordingClient(sent),
      );
      await expectLater(
        service.submitOnline(userId: _id, userPwd: _pw, request: online),
        throwsA(isA<AdvisorSubmitBlockedException>()),
      );
      await expectLater(
        service.submitVisit(userId: _id, userPwd: _pw, request: visit),
        throwsA(isA<AdvisorSubmitBlockedException>()),
      );
      expect(sent, isEmpty);
    });

    test('온라인 신청은 학교 화면과 같은 칸을 multipart로 보낸다', () async {
      final log = <http.Request>[];
      final service = AdvisorConsultationService(client: _server(log));
      await service.submitOnline(userId: _id, userPwd: _pw, request: online);

      final req = log.lastWhere(
        (r) => r.url.path == '/careerCns/w/n/getCnsOnlineApplyAjax.do',
      );
      expect(req.method, 'POST');
      expect(req.headers['content-type'], startsWith('multipart/form-data'));
      expect(req.headers['X-Requested-With'], 'XMLHttpRequest');
      expect(req.headers.containsKey('IS_AJAX'), isFalse);
      expect(req.headers['Cookie'], 'JSESSIONID=together-1');
      expect(_multipartFields(req), {
        'radio1': 'on',
        'comProfId': '1234567',
        'comApplyCont': '진로 상담 부탁드립니다.',
        'comApplyPhone': '010-1234-5678',
        'comApplyEmail1': '20230000',
        'comApplyEmail2': 'daejin.ac.kr',
        'comApplyEmail': '20230000@daejin.ac.kr',
        'CNSGB01_idx': '1',
        'comGuidStaffNo': '1234567',
        'comGuidStaffNm': '김교수',
      });
      expect(
        utf8.decode(req.bodyBytes),
        contains('name="CNSGB01"; filename=""'),
      );
    });

    test('방문 신청은 명세에 없던 칸까지 학교 화면과 같이 보낸다', () async {
      final log = <http.Request>[];
      final service = AdvisorConsultationService(client: _server(log));
      await service.submitVisit(userId: _id, userPwd: _pw, request: visit);

      final req = log.lastWhere(
        (r) => r.url.path == '/careerCns/w/n/getCnsOfflineApplyAjax.do',
      );
      expect(_multipartFields(req), {
        'radio1': 'on',
        'coaResrvCnlsrId': '1234567',
        'coaResrvDate': '2026-11-05',
        'coaResrvTime': '1345',
        'curYear': '2026',
        'curMonth': '11',
        'curWeek': '1',
        'revStdInfo': '20230000 OO전공 3학년 홍길동',
        'cnsType': 'PROF',
        'cnsRevsDate': 'SCD_THU_STATE',
        'coaApplyCont': '방문 상담 부탁드립니다.',
        'coaApplyPhone': '010-1234-5678',
        'coaApplyEmail1': '',
        'coaApplyEmail2': '',
        'coaApplyEmail': '',
      });
    });

    test('rtnCode가 0이 아니면 실패로 본다', () async {
      final service = AdvisorConsultationService(
        client: _server([], submitBody: '{"rtnCode":"-1","rtnMsg":"fail"}'),
      );
      await expectLater(
        service.submitOnline(userId: _id, userPwd: _pw, request: online),
        throwsA(
          isA<TwinException>().having(
            (e) => e.failure,
            'failure',
            TwinFailure.noData,
          ),
        ),
      );
    });

    test('신청에 성공하면 저장된 현황을 지워 다음에 새로 받는다', () async {
      final log = <http.Request>[];
      final service = AdvisorConsultationService(client: _server(log));
      await service.fetchOverview(userId: _id, userPwd: _pw);
      await service.submitOnline(userId: _id, userPwd: _pw, request: online);

      bool isStatus(http.Request r) =>
          r.url.path == '/myStatus/a/n/getMyStatusListAjax.do';
      await service.fetchOverview(userId: _id, userPwd: _pw);
      expect(log.where(isStatus), hasLength(2));
    });
  });
}

/// MockClient가 아닌 "진짜처럼 보이는" 클라이언트. 요청이 오면 기록만 한다.
class _RecordingClient extends http.BaseClient {
  _RecordingClient(this.sent);

  final List<http.BaseRequest> sent;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    sent.add(request);
    return http.StreamedResponse(const Stream.empty(), 500);
  }
}
