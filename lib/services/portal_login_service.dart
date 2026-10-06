import 'dart:convert';

import 'package:http/http.dart' as http;

/// `POST /subLogin/daejin/login.do` (+ 필요시 `GET /sugang/LinkPortal.jsp?dvd=P`
/// 2단계 폴백) 호출 결과.
///
/// 로그인 자체의 성공/실패와, 성공했을 때 이후 dreams2 계열 API 호출에 필요한
/// 쿠키 값들을 함께 담는다. 이 쿠키들을 앱 전역에 저장하는 세션 관리는 이
/// 서비스의 책임이 아니다 — 호출자가 반환값을 받아 필요에 맞게 쓴다.
class PortalLoginResult {
  const PortalLoginResult({
    required this.success,
    this.failReason,
    this.remainingAttempts,
    this.wmonid,
    this.jsessionId,
    this.userId2,
  });

  final bool success;

  /// null | "계정없음" | "비밀번호오류"
  final String? failReason;

  /// failReason이 "비밀번호오류"일 때만 값이 있을 수 있다.
  final int? remainingAttempts;

  final String? wmonid;
  final String? jsessionId;

  /// SSO uid. 1단계에서 못 찾으면 2단계 폴백으로 재시도하며, 그래도 못 찾으면
  /// null이지만 로그인 자체는 성공으로 처리한다.
  final String? userId2;
}

/// 네트워크 연결 실패 또는 서버 오류(5xx 등)로 로그인 요청 자체를 완료하지
/// 못한 경우. "로그인은 됐지만 계정없음/비밀번호오류"와는 다른 종류의 실패라서
/// [PortalLoginResult]로 뭉치지 않고 별도 예외로 던진다.
class PortalLoginException implements Exception {
  const PortalLoginException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 리다이렉트 체인 전체를 수동으로 따라간 뒤의 결과.
/// 모든 홉의 Set-Cookie / Location을 순서대로 모아서 보관한다.
class _RedirectChainResult {
  const _RedirectChainResult({
    required this.setCookies,
    required this.locations,
    required this.finalBody,
    required this.finalStatusCode,
  });

  final List<String> setCookies;
  final List<String> locations;
  final String finalBody;
  final int finalStatusCode;
}

/// 대진대 포털 로그인(1단계 `login.do`, 필요시 2단계 `LinkPortal.jsp` 폴백)을
/// 호출한다.
class PortalLoginService {
  static const _loginUrl = 'https://www.daejin.ac.kr/subLogin/daejin/login.do';
  static const _fallbackUrl =
      'https://dreams2.daejin.ac.kr/sugang/LinkPortal.jsp?dvd=P';
  static const _userAgent =
      'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36';

  // 로그인 실패(계정없음 등)는 리다이렉트 1홉으로 끝나지만, 실제 로그인 성공
  // 시 SSO/세션 설정 과정에서 홉이 더 늘어날 수 있어 여유를 둔다.
  static const _maxRedirects = 20;

  static final _wmonidPattern = RegExp(r'WMONID=(.*?);');
  static final _jsessionIdPattern = RegExp(r'JSESSIONID=(.*?);');
  static final _uidPattern = RegExp(r'uid%3D(.+?)(?:%26|&|$)');
  static final _userIdCookiePattern = RegExp(r'^userId=([^;]*)');
  static final _remainingAttemptsPattern = RegExp(r'(\d+)회\s*더\s*잘못입력');

  /// 로그인 시도마다 쿠키 저장소를 격리하기 위해 매 [login] 호출마다 새
  /// [http.Client]를 만든다. 테스트에서는 이 팩토리를 교체해 MockClient를
  /// 주입한다.
  final http.Client Function() _clientFactory;

  PortalLoginService({http.Client Function()? clientFactory})
    : _clientFactory = clientFactory ?? http.Client.new;

  Future<PortalLoginResult> login({
    required String userId,
    required String userPwd,
  }) async {
    final client = _clientFactory();
    // 1단계와 2단계(폴백)는 같은 로그인 시도이므로 같은 쿠키 저장소를
    // 공유해야 한다 — client 인스턴스뿐 아니라 수집한 쿠키 맵도 함께 넘긴다.
    final cookieJar = <String, String>{};
    try {
      final step1 = await _step1(client, cookieJar, userId, userPwd);
      if (step1.failReason != null) {
        return step1;
      }
      if (step1.userId2 != null) {
        return step1;
      }
      final fallbackUid = await _step2Fallback(client, cookieJar);
      // 2단계 폴백(LinkPortal.jsp)은 www.daejin.ac.kr이 아니라
      // dreams2.daejin.ac.kr(+ nsso.daejin.ac.kr SSO 리다이렉트)을 거치는데,
      // 이 흐름에서 dreams2 쪽이 1단계와는 다른 자체 JSESSIONID/WMONID를
      // 새로 내려주는 사례가 실기기에서 확인됐다. 1단계 값을 그대로 쓰면
      // 이후 dreams2 계열 API 호출(개설과목 조회 등)이 전부 인증 안 된
      // 요청으로 취급돼 일반 랜딩 페이지로 리다이렉트되는 버그로 이어졌다.
      // cookieJar는 1단계+2단계 전체 리다이렉트 체인에 걸쳐 계속 갱신된
      // 값이므로, 여기서 다시 읽어 최신 값을 우선한다.
      return PortalLoginResult(
        success: true,
        wmonid: cookieJar['WMONID'] ?? step1.wmonid,
        jsessionId: cookieJar['JSESSIONID'] ?? step1.jsessionId,
        userId2: fallbackUid,
      );
    } on PortalLoginException {
      rethrow;
    } catch (e) {
      throw PortalLoginException('네트워크 오류: $e');
    } finally {
      client.close();
    }
  }

  Future<PortalLoginResult> _step1(
    http.Client client,
    Map<String, String> cookieJar,
    String userId,
    String userPwd,
  ) async {
    // http 패키지에 Map을 넘기면 모든 필드가 자동으로 URL 인코딩되므로
    // "userId/userPwd만 인코딩, 나머지는 빈 문자열 그대로" 규칙을 지킬 수
    // 없다. 바디 문자열을 직접 조립한다.
    final body =
        'layout='
        '&pwdCrtfcNo='
        '&pwdInputExcessYn='
        '&userId2='
        '&userId=${Uri.encodeQueryComponent(userId)}'
        '&userPwd=${Uri.encodeQueryComponent(userPwd)}';

    final request = http.Request('POST', Uri.parse(_loginUrl))
      ..headers['Content-Type'] =
          'application/x-www-form-urlencoded;charset=UTF-8'
      ..headers['User-Agent'] = _userAgent
      ..body = body;

    final chain = await _followRedirects(client, cookieJar, request);

    final wmonid = _firstMatch(_wmonidPattern, chain.setCookies);
    final jsessionId = _firstMatch(_jsessionIdPattern, chain.setCookies);
    final userId2 = _extractUidFromLocations(chain.locations);

    // 로그인 성공 시에도 nsso.daejin.ac.kr의 SSO 리다이렉트가 자체 라우팅
    // 문제로 404를 내는 경우가 실제로 확인됐다(pmi-issue 티켓까지는 정상
    // 발급됨). 최종 상태코드로 성공/실패를 단정하지 않고, 명세대로 본문의
    // 실패 문구 존재 여부로만 판정한다. 5xx(실제 서버 장애)만 별도로 처리.
    if (chain.finalStatusCode >= 500) {
      throw PortalLoginException('서버 오류 (${chain.finalStatusCode})');
    }

    if (chain.finalBody.contains('회원정보이(가) 존재 하지 않습니다')) {
      return PortalLoginResult(
        success: false,
        failReason: '계정없음',
        wmonid: wmonid,
        jsessionId: jsessionId,
        userId2: userId2,
      );
    }
    if (chain.finalBody.contains('입력하신 계정정보가 올바르지 않습니다')) {
      final remainingText = _remainingAttemptsPattern
          .firstMatch(chain.finalBody)
          ?.group(1);
      return PortalLoginResult(
        success: false,
        failReason: '비밀번호오류',
        remainingAttempts: remainingText == null
            ? null
            : int.tryParse(remainingText),
        wmonid: wmonid,
        jsessionId: jsessionId,
        userId2: userId2,
      );
    }

    return PortalLoginResult(
      success: true,
      wmonid: wmonid,
      jsessionId: jsessionId,
      userId2: userId2,
    );
  }

  Future<String?> _step2Fallback(
    http.Client client,
    Map<String, String> cookieJar,
  ) async {
    final request = http.Request('GET', Uri.parse(_fallbackUrl))
      ..headers['Referer'] = 'https://www.daejin.ac.kr/'
      ..headers['User-Agent'] = _userAgent;

    final chain = await _followRedirects(client, cookieJar, request);

    // "마지막 매치"를 채택해야 하므로 전부 순회하며 덮어쓴다.
    String? userId2;
    for (final cookie in chain.setCookies) {
      final match = _userIdCookiePattern.firstMatch(cookie);
      if (match != null) {
        userId2 = match.group(1);
      }
    }
    return userId2;
  }

  String? _extractUidFromLocations(List<String> locations) {
    for (final location in locations) {
      if (location.contains('uid%253D')) {
        final decoded = Uri.decodeFull(location);
        final match = _uidPattern.firstMatch(decoded);
        if (match != null) return match.group(1);
      } else if (location.contains('uid%3D')) {
        final match = _uidPattern.firstMatch(location);
        if (match != null) return match.group(1);
      }
    }
    return null;
  }

  String? _firstMatch(RegExp pattern, List<String> values) {
    for (final value in values) {
      final match = pattern.firstMatch(value);
      if (match != null) return match.group(1);
    }
    return null;
  }

  /// [initialRequest]를 보내고, 3xx + `Location`이면 그 주소로 다음 요청을
  /// 직접 만들어 보내는 방식으로 리다이렉트 체인을 수동으로 전부 따라간다.
  /// `http.Request.followRedirects`를 꺼서 고수준 `http.post`/`http.get`이
  /// 자동으로 리다이렉트를 따라가며 중간 홉의 헤더를 감춰버리는 걸 막는다.
  /// 모든 홉의 Set-Cookie/Location을 순서대로 모아서 반환한다.
  Future<_RedirectChainResult> _followRedirects(
    http.Client client,
    Map<String, String> cookieJar,
    http.Request initialRequest,
  ) async {
    final setCookies = <String>[];
    final locations = <String>[];

    var request = initialRequest;
    for (var hop = 0; hop < _maxRedirects; hop++) {
      request.followRedirects = false;
      if (cookieJar.isNotEmpty) {
        request.headers['Cookie'] = cookieJar.entries
            .map((e) => '${e.key}=${e.value}')
            .join('; ');
      }

      final http.Response response;
      try {
        final streamedResponse = await client
            .send(request)
            .timeout(const Duration(seconds: 15));
        response = await http.Response.fromStream(streamedResponse);
      } catch (e) {
        throw PortalLoginException('네트워크 오류: $e');
      }

      final hopSetCookies =
          response.headersSplitValues['set-cookie'] ?? const <String>[];
      setCookies.addAll(hopSetCookies);
      for (final cookie in hopSetCookies) {
        final pair = cookie.split(';').first;
        final eq = pair.indexOf('=');
        if (eq > 0) {
          cookieJar[pair.substring(0, eq).trim()] = pair
              .substring(eq + 1)
              .trim();
        }
      }

      final location = response.headers['location'];
      if (location != null) locations.add(location);
      // TODO(debug): 404 원인 추적용 임시 로그 — 진단 끝나면 제거.
      print(
        '[PortalLogin][hop $hop] ${request.method} ${request.url} '
        '-> ${response.statusCode}'
        '${location != null ? ' Location: $location' : ''}',
      );

      final isRedirect =
          response.statusCode >= 300 &&
          response.statusCode < 400 &&
          location != null;
      if (!isRedirect) {
        final body = utf8.decode(response.bodyBytes, allowMalformed: true);
        return _RedirectChainResult(
          setCookies: setCookies,
          locations: locations,
          finalBody: body,
          finalStatusCode: response.statusCode,
        );
      }

      final locationUri = Uri.parse(location);
      final nextUri = locationUri.hasScheme
          ? locationUri
          : request.url.resolve(location);
      // 307/308만 원래 메서드를 유지하고, 그 외 3xx는 GET으로 전환한다
      // (POST 로그인 요청 뒤 이어지는 리다이렉트는 보통 GET 페이지다).
      final nextMethod =
          (response.statusCode == 307 || response.statusCode == 308)
          ? request.method
          : 'GET';
      final nextRequest = http.Request(nextMethod, nextUri)
        ..headers['User-Agent'] = _userAgent;
      final referer = request.headers['Referer'];
      if (referer != null) {
        nextRequest.headers['Referer'] = referer;
      }
      request = nextRequest;
    }

    throw const PortalLoginException('리다이렉트 횟수를 초과했습니다.');
  }
}
