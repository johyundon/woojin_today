import 'dart:convert';

import 'package:daejin_app/services/twin_rank_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 응답 HTML은 명세서(상세_2 학과순위 2·3번)의 예시 구조를 따라 만든 것이다.

const _gpaHtml = '''
<ul class="grade_detail">
  <li class="grade_my"><p>내 성적</p><strong>4.34</strong></li>
  <li class="grade_same"><p>동일 학년</p><strong>3.23</strong></li>
</ul>
''';

String _peerPage(List<String> gpas, {int total = 12}) =>
    '''
<table><thead><tr><th>학과명</th><th>학점</th></tr></thead><tbody>
${gpas.map((g) => '<tr><td>컴퓨터공학전공</td><td>$g</td><td>0</td></tr>').join()}
</tbody></table>
<script>var currentPage = '1'; var totalCnt = '$total';</script>
''';

http.Response _html(String body, [int status = 200]) =>
    http.Response.bytes(utf8.encode(body), status);

/// together → nsso → together 로 오가는 로그인 흐름(시뮬레이터에서 본 순서)을 흉내 낸다.
/// [loginOk]가 false면 로그인 페이지로 되돌려 보낸다.
MockClient _server(
  List<http.Request> log, {
  bool loginOk = true,
  String gpaBody = _gpaHtml,
}) => MockClient((request) async {
  log.add(request);
  final path = request.url.path;
  switch (path) {
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
    case '/myFuture/a/n/getResultDivInfoPage.do':
      return _html(gpaBody);
    case '/myFuture/r/n/getGrStdCompareListAjax.do':
      final page = request.bodyFields['pageIndex'];
      return _html(switch (page) {
        '1' => _peerPage(['4.5', '4.34', '4.1', 'x', '3.9']),
        '2' => _peerPage(['3.8', '3.7', '3.6', '3.5', '3.4']),
        _ => _peerPage(['3.0', '2.9']),
      });
  }
  return http.Response('not found', 404);
});

Future<TwinGradeStats> _fetch(
  TwinRankService service, {
  bool forceRefresh = false,
}) => service.fetchGradeStats(
  userId: '20201234',
  userPwd: 'pw&1',
  sustCd: 'AA0194',
  shyrCd: '3',
  forceRefresh: forceRefresh,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('로그인 후 내 평점과 동기 평점 목록을 페이지 순서대로 모은다', () async {
    final log = <http.Request>[];
    final stats = await _fetch(TwinRankService(client: _server(log)));

    expect(stats.myGpa, 4.34);
    expect(stats.sameGradeAvg, 3.23);
    expect(stats.totalCount, 12);
    // 숫자가 아닌 행('x')은 건너뛰고, 1→2→3 페이지 순서로 이어 붙인다.
    expect(stats.peerGpas, [
      4.5, 4.34, 4.1, 3.9, 3.8, 3.7, 3.6, 3.5, 3.4, 3.0, 2.9, //
    ]);

    final login = log.firstWhere(
      (r) => r.url.path == '/login/a/n/loginProc.do',
    );
    expect(login.bodyFields, {
      'targetUrl': '/clientMain/a/t/main.do',
      'userId': '20201234',
      'userPw': 'pw&1',
    });

    final gpa = log.firstWhere(
      (r) => r.url.path == '/myFuture/a/n/getResultDivInfoPage.do',
    );
    expect(gpa.bodyFields, {
      'sustCd': 'AA0194',
      'shyrCd': '3',
      'pageIndex': '1',
      'searchType': 'STD_GROUP',
      'roadMapType': 'SAMEGRADE',
    });
    expect(gpa.headers['IS_AJAX'], 'isAjax');
  });

  test('쿠키는 받은 서버에만 보내 nsso 쿠키가 T-WIN 쿠키를 덮어쓰지 않는다', () async {
    final log = <http.Request>[];
    await _fetch(TwinRankService(client: _server(log)));

    final gpa = log.firstWhere(
      (r) => r.url.path == '/myFuture/a/n/getResultDivInfoPage.do',
    );
    expect(gpa.headers['Cookie'], 'JSESSIONID=together-1');
  });

  test('로그인 후 최종 주소에 /login/이 남으면 로그인 실패로 본다', () async {
    final log = <http.Request>[];
    await expectLater(
      _fetch(TwinRankService(client: _server(log, loginOk: false))),
      throwsA(
        isA<TwinRankException>().having(
          (e) => e.failure,
          'failure',
          TwinRankFailure.loginFailed,
        ),
      ),
    );
    // 로그인에 실패하면 성적은 요청하지 않는다.
    expect(log.any((r) => r.url.path.contains('myFuture')), isFalse);
  });

  test('응답에 내 평점이 없으면 noData로 실패한다', () async {
    await expectLater(
      _fetch(
        TwinRankService(client: _server([], gpaBody: '<p>로그인이 필요합니다</p>')),
      ),
      throwsA(
        isA<TwinRankException>().having(
          (e) => e.failure,
          'failure',
          TwinRankFailure.noData,
        ),
      ),
    );
  });

  test('통신이 실패하면 network로 실패한다', () async {
    await expectLater(
      _fetch(
        TwinRankService(
          client: MockClient((_) async => throw Exception('offline')),
        ),
      ),
      throwsA(
        isA<TwinRankException>().having(
          (e) => e.failure,
          'failure',
          TwinRankFailure.network,
        ),
      ),
    );
  });

  group('7일 캐시', () {
    test('7일 안에는 다시 요청하지 않고, 7일이 지나면 새로 받는다', () async {
      final log = <http.Request>[];
      var now = DateTime(2026, 10, 31, 10);
      final service = TwinRankService(client: _server(log), now: () => now);

      await _fetch(service);
      final firstCount = log.length;

      now = now.add(const Duration(days: 6, hours: 23));
      final cached = await _fetch(service);
      expect(log.length, firstCount);
      expect(cached.myGpa, 4.34);
      expect(cached.peerGpas.length, 11);

      now = now.add(const Duration(hours: 1));
      await _fetch(service);
      expect(log.length, firstCount * 2);
    });

    test('forceRefresh면 기한 안이라도 새로 받는다', () async {
      final log = <http.Request>[];
      final service = TwinRankService(client: _server(log));

      await _fetch(service);
      final firstCount = log.length;
      await _fetch(service, forceRefresh: true);
      expect(log.length, firstCount * 2);
    });

    test('실패한 결과는 저장하지 않는다', () async {
      final failing = TwinRankService(
        client: _server([], gpaBody: '<p>없음</p>'),
      );
      await expectLater(_fetch(failing), throwsA(isA<TwinRankException>()));

      final log = <http.Request>[];
      await _fetch(TwinRankService(client: _server(log)));
      expect(log, isNotEmpty);
    });
  });
}
