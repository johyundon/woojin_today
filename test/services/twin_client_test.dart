// T-WIN 로그인의 "비밀번호 3개월 미변경" 분기(Notion 명세 6번)를 가짜 서버로
// 검증한다. 실제 그런 상태의 계정 응답은 본 적이 없어서, 명세 설명대로 만든
// 응답이다(SecurityCheck.jsp가 있는 서버 주소는 가상의 값).
import 'dart:convert';

import 'package:daejin_app/services/twin_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _security =
    'https://sso.example.ac.kr/sso/SecurityCheck.jsp?sys=TWIN&uid=abc';

const _loginScript =
    '''
<script>
alert("비밀번호를 변경한 지 3개월이 지났습니다.");
if (confirm("지금 변경하시겠습니까?")) {
  location.href = "$_security";
} else {
  location.href = "https://sso.example.ac.kr/sso/Other.jsp?x=1";
}
</script>
''';

String _securityPage({bool withDt = true}) =>
    '''
<html><body>
<form name="myform" method="get" action="../pw/ChangeGuide.jsp">
  <input type="hidden" name="sys" value="TWIN">
  <input type="hidden" name="cd" value="C01">
  <input type="hidden" name="uid" value="abc%2Bdef">
  <input type="hidden" name="md" value="M">
  ${withDt ? '<input type="hidden" name="dt" value="20261101%3A1200">' : ''}
  <input type="hidden" name="returnurl" value="https%3A%2F%2Ftogether.daejin.ac.kr%2Findex.do">
</form>
</body></html>
''';

const _guidePage = '''
<html><body>
<p>비밀번호 변경 안내</p>
<a href="/pw/ChangeNow.jsp">지금 변경하기</a>
<a href="https://together.daejin.ac.kr/index.do">다음에 변경하기</a>
</body></html>
''';

/// [scenario]: 'normal'(바로 302 성공), 'expired'(3개월 분기), 'wrongPw'(그냥 실패).
MockClient _server(
  List<http.BaseRequest> log, {
  String scenario = 'expired',
  bool withDt = true,
  bool guideHasLater = true,
}) => MockClient((request) async {
  log.add(request);
  final url = request.url;
  switch ('${url.host}${url.path}') {
    case 'together.daejin.ac.kr/clientMain/a/t/main.do':
      return http.Response('', 200);
    case 'together.daejin.ac.kr/login/a/n/loginProc.do':
      return switch (scenario) {
        'normal' => http.Response(
          '',
          302,
          headers: {'location': '/clientMain/a/t/main.do'},
        ),
        'expired' => _html(_loginScript),
        _ => _html('<script>alert("아이디 또는 비밀번호");</script>'),
      };
    case 'sso.example.ac.kr/sso/SecurityCheck.jsp':
      return _html(_securityPage(withDt: withDt));
    case 'sso.example.ac.kr/pw/ChangeGuide.jsp':
      return _html(guideHasLater ? _guidePage : '<html>안내</html>');
    case 'together.daejin.ac.kr/index.do':
      return http.Response(
        '',
        302,
        headers: {'location': 'https://together.daejin.ac.kr/sso/index.jsp'},
      );
    case 'together.daejin.ac.kr/sso/index.jsp':
      return http.Response(
        '',
        302,
        headers: {'location': 'https://nsso.daejin.ac.kr/sso/pmi-sso.jsp'},
      );
    case 'nsso.daejin.ac.kr/sso/pmi-sso.jsp':
      return http.Response(
        '',
        302,
        headers: {
          'location': 'https://together.daejin.ac.kr/clientMain/a/t/main.do',
        },
      );
  }
  return http.Response('not found', 404);
});

http.Response _html(String body) => http.Response.bytes(
  utf8.encode(body),
  200,
  headers: {'content-type': 'text/html; charset=UTF-8'},
);

bool _isDesktop(http.BaseRequest r) =>
    r.headers['User-Agent']!.contains('Macintosh');

void main() {
  test('정상 계정은 기존처럼 바로 성공하고 안내 흐름을 타지 않는다', () async {
    final log = <http.BaseRequest>[];
    await TwinClient(_server(log, scenario: 'normal')).login('20260001', 'pw');

    expect(log.where((r) => r.url.host != 'together.daejin.ac.kr'), isEmpty);
    expect(log.any(_isDesktop), isFalse);
  });

  test('3개월 미변경: 안내 흐름을 끝까지 따라가 로그인에 성공한다', () async {
    final log = <http.BaseRequest>[];
    await TwinClient(_server(log)).login('20260001', 'pw');

    final paths = log.map((r) => '${r.url.host}${r.url.path}').toList();
    expect(paths, [
      'together.daejin.ac.kr/clientMain/a/t/main.do',
      'together.daejin.ac.kr/login/a/n/loginProc.do',
      'sso.example.ac.kr/sso/SecurityCheck.jsp',
      'sso.example.ac.kr/pw/ChangeGuide.jsp',
      'together.daejin.ac.kr/index.do',
      'together.daejin.ac.kr/sso/index.jsp',
      'nsso.daejin.ac.kr/sso/pmi-sso.jsp',
      'together.daejin.ac.kr/clientMain/a/t/main.do',
    ]);
    // 로그인 이후 안내 흐름은 전부 데스크톱 UA.
    expect(log.skip(2).every(_isDesktop), isTrue);
  });

  test('if 쪽 SecurityCheck 주소를 쓰고, 단계마다 직전 주소를 Referer로 보낸다', () async {
    final log = <http.BaseRequest>[];
    await TwinClient(_server(log)).login('20260001', 'pw');

    expect(log[2].url.toString(), _security);
    expect(
      log[2].headers['Referer'],
      'https://together.daejin.ac.kr/login/a/n/loginProc.do',
    );
    expect(log[3].headers['Referer'], _security);
    expect(log[4].headers['Referer'], log[3].url.toString());
  });

  test('숨은 값 6개를 쿼리에 붙이며, 이미 인코딩된 값은 한 번 더 인코딩된다', () async {
    final log = <http.BaseRequest>[];
    await TwinClient(_server(log)).login('20260001', 'pw');

    final guide = log[3].url;
    expect(guide.queryParameters, {
      'sys': 'TWIN',
      'cd': 'C01',
      'uid': 'abc%2Bdef',
      'md': 'M',
      'dt': '20261101%3A1200',
      'returnurl': 'https%3A%2F%2Ftogether.daejin.ac.kr%2Findex.do',
    });
    expect(guide.query, contains('dt=20261101%253A1200'));
  });

  test('SecurityCheck 주소가 없으면(비밀번호 오류) 로그인 실패', () async {
    final log = <http.BaseRequest>[];
    await expectLater(
      TwinClient(_server(log, scenario: 'wrongPw')).login('20260001', 'pw'),
      throwsA(
        isA<TwinException>().having(
          (e) => e.failure,
          'failure',
          TwinFailure.loginFailed,
        ),
      ),
    );
    expect(log, hasLength(2));
  });

  test('숨은 값(dt)이 하나라도 없으면 그 자리에서 실패', () async {
    final log = <http.BaseRequest>[];
    await expectLater(
      TwinClient(_server(log, withDt: false)).login('20260001', 'pw'),
      throwsA(isA<TwinException>()),
    );
    expect(log, hasLength(3));
  });

  test('"다음에 변경하기" 링크가 없으면 실패', () async {
    final log = <http.BaseRequest>[];
    await expectLater(
      TwinClient(_server(log, guideHasLater: false)).login('20260001', 'pw'),
      throwsA(isA<TwinException>()),
    );
    expect(log, hasLength(4));
  });
}
