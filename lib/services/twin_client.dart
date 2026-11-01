import 'dart:async';
import 'dart:convert';

import 'package:cp949_codec/cp949_codec.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import 'host_cookie_jar.dart';

/// T-WIN 조회가 어디서 실패했는지.
enum TwinFailure {
  /// T-WIN 로그인이 안 됨(학번·비밀번호 오류, 서버 점검 등).
  loginFailed,

  /// 로그인은 됐지만 응답에서 원하는 값을 못 찾음(세션 만료, 코드 오류 등).
  noData,

  /// 타임아웃 등 통신 자체가 실패함.
  network,
}

class TwinException implements Exception {
  const TwinException(this.failure, this.message);

  final TwinFailure failure;
  final String message;

  @override
  String toString() => message;
}

/// T-WIN(together.daejin.ac.kr) 로그인과 요청 보내기를 맡는다. 학과 등수와
/// 마일리지가 같이 쓴다. 로그인 한 번에 하나씩 만들어 쓰고, 쿠키는 이 객체가 들고 있다.
///
/// 쿠키는 서버별로 나눠 보관한다. 로그인이 together → nsso → together로 오가는데,
/// 한곳에 섞으면 nsso의 JSESSIONID가 together의 것을 덮어써 조회가 "로그인이
/// 필요"로 실패한다(2026-10-30 시뮬레이터에서 확인).
class TwinClient {
  TwinClient(this._client);

  static const base = 'https://together.daejin.ac.kr';
  static const _userAgent =
      'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36';
  /// 비밀번호 3개월 미변경 안내 흐름은 모바일 UA로 가면 에러 페이지로 튕긴다(명세).
  static const _desktopUserAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36';
  static const _maxRedirects = 10;

  final http.Client _client;
  final HostCookieJar _cookies = HostCookieJar();

  /// 명세 1번. 첫 화면을 먼저 열어 세션 쿠키를 받은 뒤 로그인한다(시뮬레이터에서
  /// 성공한 순서 그대로). 리다이렉트를 끝까지 따라가 최종 응답이 2xx이고 주소에
  /// `/login/`이 없으면 성공이다.
  Future<void> login(String userId, String userPwd) async {
    await send(http.Request('GET', Uri.parse('$base/clientMain/a/t/main.do')));
    final loginUrl = Uri.parse('$base/login/a/n/loginProc.do');
    final (status, finalUrl, body) = await send(
      http.Request('POST', loginUrl)
        ..headers.addAll({
          'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
          'Origin': base,
          'Referer': '$base/clientMain/a/t/main.do',
        })
        ..body =
            'targetUrl=%2FclientMain%2Fa%2Ft%2Fmain.do'
            '&userId=${Uri.encodeQueryComponent(userId)}'
            '&userPw=${Uri.encodeQueryComponent(userPwd)}',
    );
    if (_loggedIn(status, finalUrl)) return;
    // 비밀번호 3개월 미변경 계정은 리다이렉트 없이 200 + alert/location.href
    // 스크립트만 와서 주소가 loginProc.do에 그대로 남는다. 이때만 안내 흐름을 탄다.
    if (status == 200 && finalUrl.path == loginUrl.path) {
      await _skipPasswordChange(loginUrl, body);
      return;
    }
    throw _loginFailed;
  }

  static const _loginFailed = TwinException(
    TwinFailure.loginFailed,
    'T-WIN 로그인에 실패했어요',
  );

  static bool _loggedIn(int status, Uri finalUrl) =>
      status >= 200 && status < 300 && !finalUrl.path.contains('/login/');

  // if/else 두 location.href 중 항상 먼저 나오는 쪽(SecurityCheck.jsp)을 쓴다.
  static final _securityCheckUrl = RegExp(
    r'''["']([^"']*SecurityCheck\.jsp\?[^"']*)["']''',
  );
  static const _securityFields = ['sys', 'cd', 'uid', 'md', 'dt', 'returnurl'];

  /// 명세 6번 "비번 3개월 미변경 분기". SecurityCheck.jsp → 숨은 값 6개를 붙여
  /// 안내 페이지 → "다음에 변경하기" 링크 → 302 체인으로 main.do 도착까지 간다.
  /// 모든 단계에서 데스크톱 UA와 직전 주소 Referer를 보내야 하고, dt는 매번 새로
  /// 받은 값을 쓴다. 중간에 값을 하나라도 못 찾으면 바로 로그인 실패로 끝낸다.
  ///
  /// *** 실제 계정으로는 확인 못 함 *** — Notion 명세 설명만 보고 구현했다.
  Future<void> _skipPasswordChange(Uri loginUrl, String loginBody) async {
    final match = _securityCheckUrl.firstMatch(loginBody);
    if (match == null) throw _loginFailed;
    final securityUrl = loginUrl.resolve(match.group(1)!.replaceAll('&amp;', '&'));

    final (_, securityFinal, securityBody) = await send(
      http.Request('GET', securityUrl)..headers['Referer'] = loginUrl.toString(),
      userAgent: _desktopUserAgent,
    );
    final form = html_parser
        .parse(securityBody)
        .querySelector('form[name="myform"]');
    final action = form?.attributes['action'];
    if (form == null || action == null || action.isEmpty) throw _loginFailed;
    final values = <String, String>{};
    for (final name in _securityFields) {
      final value = form
          .querySelector('input[name="$name"]')
          ?.attributes['value'];
      if (value == null) throw _loginFailed;
      values[name] = value;
    }
    // 값은 이미 인코딩된 문자열이라, 표준 인코딩을 한 번 더 거치면 실제
    // 브라우저가 보내는 이중 인코딩 모양이 된다(명세).
    final guideUrl = securityFinal
        .resolve(action)
        .replace(queryParameters: values);

    final (_, guideFinal, guideBody) = await send(
      http.Request('GET', guideUrl)..headers['Referer'] = securityUrl.toString(),
      userAgent: _desktopUserAgent,
    );
    String? laterHref;
    for (final a in html_parser.parse(guideBody).querySelectorAll('a[href]')) {
      if (a.text.trim() == '다음에 변경하기') {
        laterHref = a.attributes['href'];
        break;
      }
    }
    if (laterHref == null || laterHref.isEmpty) throw _loginFailed;

    final (status, finalUrl, _) = await send(
      http.Request('GET', guideFinal.resolve(laterHref))
        ..headers['Referer'] = guideUrl.toString(),
      userAgent: _desktopUserAgent,
    );
    if (!_loggedIn(status, finalUrl)) throw _loginFailed;
  }

  /// 화면 안에서 부르는 ajax 요청(POST, form). [referer]는 그 화면 주소.
  http.Request ajaxPost(String path, String body, {required String referer}) =>
      http.Request('POST', Uri.parse('$base$path'))
        ..headers.addAll({
          'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
          'IS_AJAX': 'isAjax',
          'X-Requested-With': 'XMLHttpRequest',
          'Origin': base,
          'Referer': referer,
        })
        ..body = body;

  /// 요청을 보내고 (최종 상태 코드, 최종 주소, 본문)을 돌려준다.
  /// [followRedirects]면 3xx를 직접 따라가며 각 서버의 쿠키를 주고받는다.
  /// [userAgent]를 주면 리다이렉트 단계까지 모두 그 값을 쓴다.
  Future<(int, Uri, String)> send(
    http.BaseRequest request, {
    bool followRedirects = true,
    String? userAgent,
  }) async {
    http.BaseRequest current = request;
    for (var hop = 0; hop <= _maxRedirects; hop++) {
      current
        ..followRedirects = false
        ..headers['User-Agent'] = userAgent ?? _userAgent;
      final cookieHeader = _cookies.headerFor(current.url);
      if (cookieHeader.isNotEmpty) current.headers['Cookie'] = cookieHeader;

      final http.Response response;
      try {
        response = await http.Response.fromStream(
          await _client.send(current).timeout(const Duration(seconds: 15)),
        );
      } catch (e) {
        throw TwinException(TwinFailure.network, '네트워크 오류: $e');
      }
      _cookies.store(
        current.url,
        response.headersSplitValues['set-cookie'] ?? const [],
      );

      final location = response.headers['location'];
      final isRedirect =
          response.statusCode >= 300 &&
          response.statusCode < 400 &&
          location != null;
      if (!followRedirects || !isRedirect) {
        return (response.statusCode, current.url, _decode(response));
      }
      current = http.Request('GET', current.url.resolve(location));
    }
    throw const TwinException(
      TwinFailure.loginFailed,
      'T-WIN 로그인 중 리다이렉트가 너무 많아요',
    );
  }

  /// 기본은 UTF-8. 안내 흐름은 다른 서버를 거쳐서, 헤더가 EUC-KR이라고 밝히면
  /// 그걸 따른다("다음에 변경하기" 글자를 찾아야 하므로).
  static String _decode(http.Response response) {
    final type = response.headers['content-type']?.toLowerCase() ?? '';
    if (type.contains('euc-kr') || type.contains('ks_c_5601')) {
      try {
        return cp949.decode(response.bodyBytes);
      } catch (_) {}
    }
    return utf8.decode(response.bodyBytes, allowMalformed: true);
  }
}
