import 'dart:async';
import 'dart:convert';

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
  static const _maxRedirects = 10;

  final http.Client _client;
  final HostCookieJar _cookies = HostCookieJar();

  /// 명세 1번. 첫 화면을 먼저 열어 세션 쿠키를 받은 뒤 로그인한다(시뮬레이터에서
  /// 성공한 순서 그대로). 리다이렉트를 끝까지 따라가 최종 응답이 2xx이고 주소에
  /// `/login/`이 없으면 성공이다.
  Future<void> login(String userId, String userPwd) async {
    await send(http.Request('GET', Uri.parse('$base/clientMain/a/t/main.do')));
    final (status, finalUrl, _) = await send(
      http.Request('POST', Uri.parse('$base/login/a/n/loginProc.do'))
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
    if (status < 200 || status >= 300 || finalUrl.path.contains('/login/')) {
      throw const TwinException(TwinFailure.loginFailed, 'T-WIN 로그인에 실패했어요');
    }
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
  Future<(int, Uri, String)> send(
    http.Request request, {
    bool followRedirects = true,
  }) async {
    var current = request;
    for (var hop = 0; hop <= _maxRedirects; hop++) {
      current
        ..followRedirects = false
        ..headers['User-Agent'] = _userAgent;
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
        return (
          response.statusCode,
          current.url,
          utf8.decode(response.bodyBytes, allowMalformed: true),
        );
      }
      current = http.Request('GET', current.url.resolve(location));
    }
    throw const TwinException(
      TwinFailure.loginFailed,
      'T-WIN 로그인 중 리다이렉트가 너무 많아요',
    );
  }
}
