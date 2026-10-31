import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:daejin_app/services/mileage_service.dart';
import 'package:daejin_app/services/notice_service.dart';
import 'package:daejin_app/services/twin_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 응답 HTML은 2026-10-31 실제 응답 구조(점수·순위·스크립트의 학과/학년 코드)와
// 명세서(상세_3 2·4번) 예시를 따라 만든 것이다. 학번은 모두 가짜다.

const _statusHtml = '''
<div class="mymileage_score">
  <p>나의 마일리지 <strong>35</strong></p>
  <div class="ranking">
    126
    위
    <strong class="mileage_tit">나의 마일리지 순위</strong>
  </div>
  <strong class="mileage_info">※ 동일학년 기준</strong>
</div>
<table><tbody><tr><th scope="row">1위</th><td>144</td></tr></tbody></table>
<script>
  var param = {
    sustCd : "AA0194",
    shyrCd : "3"
  };
</script>
''';

String _historyPage(List<List<String>> rows, {int total = 7}) =>
    '''
<table><thead><tr><th>획득일</th><th>구분</th><th>활동명</th><th>획득 마일리지</th></tr></thead>
<tbody>
${rows.map((r) => '<tr>${r.map((c) => '<td>$c</td>').join()}</tr>').join()}
</tbody></table>
<script>var currentPage = '1'; var totalCnt = '$total';</script>
''';

const _emptyHistory = '''
<table><thead><tr><th>획득일</th><th>구분</th><th>활동명</th><th>획득 마일리지</th></tr></thead>
<tbody><tr><td colspan="4">마일리지 취득 현황이 없습니다</td></tr></tbody></table>
<script>var currentPage = '1'; var totalCnt = '0';</script>
''';

http.Response _html(String body, [int status = 200]) =>
    http.Response.bytes(utf8.encode(body), status);

MockClient _twin(
  List<http.Request> log, {
  bool loginOk = true,
  String statusBody = _statusHtml,
  String? historyBody,
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
              ? '/clientMain/a/t/main.do'
              : '/login/a/m/loginView.do',
        },
      );
    case '/login/a/m/loginView.do':
      return http.Response('', 200);
    case '/myStatus/a/n/getMyStatusListAjax.do':
      return _html(statusBody);
    case '/myStatus/a/n/getMileageStatusInfoAjax.do':
      if (historyBody != null) return _html(historyBody);
      return _html(switch (request.bodyFields['pageIndex']) {
        '1' => _historyPage([
          ['2026-09-10', '봉사활동', '교내 봉사', '5'],
          ['2026-03-15', '학술활동', '세미나', '10'],
          ['2026-02-20', '비교과', '특강', '3'],
          ['2025-11-02', '봉사활동', '헌혈', '7'],
          ['2025-09-01', '학술활동', '경진대회', '4'],
        ]),
        _ => _historyPage([
          ['2026-10-01', '비교과', '취업특강', '6'],
          ['2026-08-31', '비교과', '여름특강', 'x'],
        ]),
      });
  }
  return http.Response('not found', 404);
});

Uint8List _xlsx(String cells, {String? sharedStrings}) {
  final archive = Archive();
  void add(String name, String content) =>
      archive.addFile(ArchiveFile.bytes(name, utf8.encode(content)));
  add('[Content_Types].xml', '<Types/>');
  add(
    'xl/worksheets/sheet1.xml',
    '<worksheet><sheetData><row r="1">$cells</row></sheetData></worksheet>',
  );
  if (sharedStrings != null) add('xl/sharedStrings.xml', sharedStrings);
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

/// 실제 명단처럼 학번만 숫자 칸에 있고 sharedStrings.xml이 없다.
final _roster = _xlsx(
  '<c r="A1" s="1"><v>11110001</v></c><c r="B1"><v>11110002</v></c>',
);

const _listHtml = '''
<table class="board-table"><tbody>
<tr class="notice"><td class="td-subject"><a href="/bbs/daejin/189/1/artclView.do"><strong>2026학년도 2학기 재학생 등록 안내</strong></a></td></tr>
<tr><td class="td-subject"><a href="/bbs/daejin/189/10/artclView.do"><strong>2026학년도 1학기 마일리지장학 대상자 공지</strong></a></td><td class="td-date">2026.03.30</td></tr>
<tr><td class="td-subject"><a href="/bbs/daejin/189/9/artclView.do"><strong>2026학년도 마일리지장학 시행 안내</strong></a></td></tr>
<tr><td class="td-subject"><a href="/bbs/daejin/189/8/artclView.do"><strong>2025학년도 2학기 마일리지장학 대상자 공지(수정)</strong></a></td></tr>
<tr><td class="td-subject"><a href="/bbs/daejin/189/7/artclView.do"><strong>2025학년도 1학기 마일리지장학 대상자 공지</strong></a></td></tr>
<tr><td class="td-subject"><a href="/bbs/daejin/189/6/artclView.do"><strong>2024학년도 2학기 마일리지장학 대상자 공지</strong></a></td></tr>
<tr><td class="td-subject"><a href="/bbs/daejin/189/5/artclView.do"><strong>2024학년도 1학기 마일리지장학 대상자 공지</strong></a></td></tr>
<tr><td class="td-subject"><a href="/bbs/daejin/189/4/artclView.do"><strong>2023학년도 2학기 마일리지장학 대상자 공지</strong></a></td></tr>
</tbody></table>
''';

String _detailHtml(String fileName) =>
    '''
<h2 class="view-title">마일리지장학 대상자 공지</h2>
<div class="view-con"><p>명단을 확인하세요.</p></div>
<a class="file-download" href="/bbs/daejin/189/555/download.do">
  $fileName
</a>
''';

MockClient _www(
  List<http.Request> log, {
  String fileName = '대상자명단.xlsx',
  List<int>? fileBytes,
}) => MockClient((request) async {
  log.add(request);
  final path = request.url.path;
  if (path == '/daejin/1002/subview.do') return _html(_listHtml);
  if (path.endsWith('/artclView.do')) return _html(_detailHtml(fileName));
  if (path.endsWith('/download.do')) {
    // 실제 서버도 이상한 Content-Type을 준다. 무시해야 한다.
    return http.Response.bytes(
      fileBytes ?? _roster,
      200,
      headers: {'content-type': 'application/x-msdownload; =;charset=UTF-8'},
    );
  }
  return http.Response('not found', 404);
});

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    NoticeService.clearMemoryCache();
  });

  final now = DateTime(2026, 10, 31, 12);

  group('내 현황·지급 내역', () {
    Future<MileageStatus> fetch(
      http.Client client, {
      DateTime? at,
      bool forceRefresh = false,
    }) => MileageService(client: client, now: () => at ?? now).fetchStatus(
      userId: '11110001',
      userPwd: 'pw',
      forceRefresh: forceRefresh,
    );

    test('로그인 한 번으로 점수·순위와 모든 페이지의 지급 내역을 받는다', () async {
      final log = <http.Request>[];
      final status = await fetch(_twin(log));

      expect(status.points, 35);
      expect(status.sameGradeRank, 126);
      expect(status.history.map((e) => e.title), [
        '교내 봉사',
        '세미나',
        '특강',
        '헌혈',
        '경진대회',
        '취업특강',
        '여름특강',
      ]);
      expect(status.history.last.points, 0, reason: '숫자가 아니면 0');
      expect(
        log.where((r) => r.url.path == '/login/a/n/loginProc.do'),
        hasLength(1),
      );

      final historyCalls = log
          .where((r) => r.url.path.endsWith('getMileageStatusInfoAjax.do'))
          .toList();
      expect(historyCalls, hasLength(2), reason: '7건 → 5건씩 2페이지');
      expect(historyCalls.first.bodyFields, {
        'userId': '11110001',
        'sustCd': 'AA0194',
        'shyrCd': '3',
        'pageIndex': '1',
      });
    });

    test('내역이 없을 때 오는 안내 행은 내역으로 세지 않는다', () async {
      final status = await fetch(_twin([], historyBody: _emptyHistory));
      expect(status.history, isEmpty);
    });

    test('로그인 후 최종 주소에 /login/이 남으면 로그인 실패로 본다', () async {
      await expectLater(
        fetch(_twin([], loginOk: false)),
        throwsA(
          isA<TwinException>().having(
            (e) => e.failure,
            'failure',
            TwinFailure.loginFailed,
          ),
        ),
      );
    });

    test('응답에 점수나 학과·학년 코드가 없으면 noData로 실패한다', () async {
      for (final body in [
        '<p>로그인이 필요합니다</p>',
        _statusHtml.replaceAll('sustCd', 'other'),
      ]) {
        await expectLater(
          fetch(_twin([], statusBody: body)),
          throwsA(
            isA<TwinException>().having(
              (e) => e.failure,
              'failure',
              TwinFailure.noData,
            ),
          ),
        );
      }
    });

    test('하루 안에는 다시 요청하지 않고, 하루가 지나면 새로 받는다', () async {
      final log = <http.Request>[];
      final client = _twin(log);
      await fetch(client);
      final first = log.length;

      await fetch(client, at: now.add(const Duration(hours: 23)));
      expect(log.length, first);

      await fetch(client, at: now.add(const Duration(days: 1)));
      expect(log.length, greaterThan(first));
    });

    test('forceRefresh면 기한 안이라도 새로 받는다', () async {
      final log = <http.Request>[];
      final client = _twin(log);
      await fetch(client);
      final first = log.length;
      await fetch(client, forceRefresh: true);
      expect(log.length, greaterThan(first));
    });

    test('실패한 결과는 저장하지 않는다', () async {
      await expectLater(
        fetch(_twin([], statusBody: '<p>오류</p>')),
        throwsA(isA<TwinException>()),
      );
      final log = <http.Request>[];
      await fetch(_twin(log));
      expect(log, isNotEmpty);
    });
  });

  test('이번 학기 합계는 지급 내역 날짜로 계산한다', () {
    final status = MileageStatus(
      points: 0,
      sameGradeRank: 1,
      fetchedAt: now,
      history: const [
        MileageEntry(date: '2026-10-01', category: '', title: '', points: 6),
        MileageEntry(date: '2026.09.01', category: '', title: '', points: 5),
        MileageEntry(date: '2026-08-31', category: '', title: '', points: 100),
        MileageEntry(date: '2027-02-28', category: '', title: '', points: 2),
        MileageEntry(date: '날짜없음', category: '', title: '', points: 50),
      ],
    );
    expect(status.semesterPoints(DateTime(2026, 10, 31)), 13);
    expect(status.semesterPoints(DateTime(2027, 1, 15)), 13);
    expect(status.semesterPoints(DateTime(2026, 5, 1)), 100);
  });

  group('장학 대상자', () {
    MileageService service(http.Client client) =>
        MileageService(client: client, now: () => now);

    test('제목에 "대상자"가 있는 공지만 최신 5개 보여준다', () async {
      final notices = await service(_www([])).fetchTargetNotices();
      expect(notices.map((n) => n.detailPath), [
        '/bbs/daejin/189/10/artclView.do',
        '/bbs/daejin/189/8/artclView.do',
        '/bbs/daejin/189/7/artclView.do',
        '/bbs/daejin/189/6/artclView.do',
        '/bbs/daejin/189/5/artclView.do',
      ]);
    });

    test('명단에 학번이 있으면 대상자, 없으면 대상자 아님', () async {
      final log = <http.Request>[];
      final s = service(_www(log));
      expect(
        await s.checkTarget(
          detailPath: '/bbs/daejin/189/10/artclView.do',
          studentId: '11110002',
        ),
        MileageTargetResult.target,
      );
      expect(
        await s.checkTarget(
          detailPath: '/bbs/daejin/189/10/artclView.do',
          studentId: '11119999',
        ),
        MileageTargetResult.notTarget,
      );
      expect(
        log.last.url.toString(),
        'https://www.daejin.ac.kr/bbs/daejin/189/555/download.do',
      );
    });

    test('첨부가 xlsx가 아니면 명단 없음으로 본다', () async {
      final log = <http.Request>[];
      final result = await service(_www(log, fileName: '안내문.pdf')).checkTarget(
        detailPath: '/bbs/daejin/189/9/artclView.do',
        studentId: '1',
      );
      expect(result, MileageTargetResult.noRoster);
      expect(log.where((r) => r.url.path.endsWith('download.do')), isEmpty);
    });

    test('받은 파일이 zip(PK)이 아니면 실패한다', () async {
      await expectLater(
        service(_www([], fileBytes: utf8.encode('<html>오류</html>')))
            .checkTarget(
              detailPath: '/bbs/daejin/189/10/artclView.do',
              studentId: '1',
            ),
        throwsA(isA<NoticeException>()),
      );
    });

    test('공유 문자열·인라인 문자열·소수점 숫자 칸도 학번으로 읽는다', () {
      final shared = _xlsx(
        '<c r="A1" t="s"><v>1</v></c>',
        sharedStrings: '<sst><si><t>학번</t></si><si><r><t>1111</t></r><r><t>0003</t></r></si></sst>',
      );
      expect(MileageService.rosterContains(shared, '11110003'), isTrue);

      final inline = _xlsx(
        '<c r="A1" t="inlineStr"><is><t>11110004</t></is></c>',
      );
      expect(MileageService.rosterContains(inline, '11110004'), isTrue);

      final decimal = _xlsx(
        '<c r="A1"><v>11110005.0</v></c><c r="B1"><v>1.1110006E7</v></c>',
      );
      expect(MileageService.rosterContains(decimal, '11110005'), isTrue);
      expect(MileageService.rosterContains(decimal, '11110006'), isTrue);
      expect(MileageService.rosterContains(decimal, '1111000'), isFalse);
    });
  });
}
