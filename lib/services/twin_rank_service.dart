import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// T-WIN 성적 조회가 어디서 실패했는지.
enum TwinRankFailure {
  /// T-WIN 로그인이 안 됨(학번·비밀번호 오류, 서버 점검 등).
  loginFailed,

  /// 로그인은 됐지만 응답에서 평점을 못 찾음(세션 만료, 학과·학년코드 오류 등).
  noData,

  /// 타임아웃 등 통신 자체가 실패함.
  network,
}

class TwinRankException implements Exception {
  const TwinRankException(this.failure, this.message);

  final TwinRankFailure failure;
  final String message;

  @override
  String toString() => message;
}

/// T-WIN에서 받아온 학과·학년 성적 정보. 등수는 여기서 계산하지 않는다.
class TwinGradeStats {
  const TwinGradeStats({
    required this.myGpa,
    required this.sameGradeAvg,
    required this.peerGpas,
    required this.totalCount,
    required this.fetchedAt,
  });

  /// 내 평점(`li.grade_my strong`).
  final double myGpa;

  /// 같은 학년 평균(`li.grade_same strong`). 응답에 없으면 null.
  final double? sameGradeAvg;

  /// 같은 학과·학년 학생들의 평점. 서버가 준 순서 그대로.
  final List<double> peerGpas;

  /// 서버가 알려준 전체 인원수(`totalCnt`).
  final int totalCount;

  /// 서버에서 받아온 시각. 캐시 유효기간 판단에 쓴다.
  final DateTime fetchedAt;

  factory TwinGradeStats.fromJson(Map<String, dynamic> json) => TwinGradeStats(
    myGpa: (json['myGpa'] as num).toDouble(),
    sameGradeAvg: (json['sameGradeAvg'] as num?)?.toDouble(),
    peerGpas: [
      for (final v in json['peerGpas'] as List<dynamic>) (v as num).toDouble(),
    ],
    totalCount: json['totalCount'] as int,
    fetchedAt: DateTime.parse(json['fetchedAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'myGpa': myGpa,
    'sameGradeAvg': sameGradeAvg,
    'peerGpas': peerGpas,
    'totalCount': totalCount,
    'fetchedAt': fetchedAt.toIso8601String(),
  };
}

/// [TwinRankService]의 공개 API. 화면은 이 타입으로 받아 테스트에서 가짜를 끼운다.
abstract class TwinRankServiceBase {
  /// [sustCd] 학과코드(예: AA0194), [shyrCd] 학년코드.
  /// [forceRefresh]가 true면 캐시를 무시하고 서버에서 새로 받는다.
  Future<TwinGradeStats> fetchGradeStats({
    required String userId,
    required String userPwd,
    required String sustCd,
    required String shyrCd,
    bool forceRefresh = false,
  });
}

/// T-WIN(together.daejin.ac.kr)에 로그인해 내 평점과 같은 학과·학년 평점 목록을
/// 받아온다(명세: 상세_2 "학과순위" 1~3번).
///
/// 결과는 기기에 7일 동안 저장해 두고 다시 요청하지 않는다. 평점은 학기 단위로만
/// 바뀌는데, 한 번 받는 데 요청이 15번 안팎 나가기 때문이다. 실패한 결과는
/// 저장하지 않는다. 로그아웃하면 `logout_cleaner`가 기기 저장소를 통째로 지운다.
///
/// 쿠키는 서버별로 나눠 보관한다. 로그인이 together → nsso → together로 오가는데,
/// 한곳에 섞으면 nsso의 JSESSIONID가 together의 것을 덮어써 성적 조회가 "로그인이
/// 필요"로 실패한다(2026-10-30 시뮬레이터에서 확인).
class TwinRankService implements TwinRankServiceBase {
  TwinRankService({http.Client? client, DateTime Function()? now})
    : _client = client ?? http.Client(),
      _now = now ?? DateTime.now;

  static const _base = 'https://together.daejin.ac.kr';
  static const _userAgent =
      'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36';
  static const _referer = '$_base/myFuture/a/m/myFutureView.do';

  static const cacheDuration = Duration(days: 7);
  static const _prefsKeyPrefix = 'twin_rank_';

  /// 동기 목록 한 페이지 인원(명세: 실제 호출로 확인된 고정값).
  static const _pageSize = 5;
  static const _maxRedirects = 10;

  static final _totalCntPattern = RegExp(r"var\s+totalCnt\s*=\s*'(\d+)'");

  final http.Client _client;
  final DateTime Function() _now;

  @override
  Future<TwinGradeStats> fetchGradeStats({
    required String userId,
    required String userPwd,
    required String sustCd,
    required String shyrCd,
    bool forceRefresh = false,
  }) async {
    final prefsKey = '$_prefsKeyPrefix${userId}_${sustCd}_$shyrCd';
    if (!forceRefresh) {
      final cached = await _readStored(prefsKey);
      if (cached != null &&
          _now().difference(cached.fetchedAt) < cacheDuration) {
        return cached;
      }
    }

    final cookies = _HostCookies();
    await _login(cookies, userId, userPwd);
    final (myGpa, sameGradeAvg) = await _fetchMyGpa(cookies, sustCd, shyrCd);
    final (peers, total) = await _fetchPeers(cookies, sustCd, shyrCd);

    final stats = TwinGradeStats(
      myGpa: myGpa,
      sameGradeAvg: sameGradeAvg,
      peerGpas: peers,
      totalCount: total,
      fetchedAt: _now(),
    );
    await _writeStored(prefsKey, stats);
    return stats;
  }

  /// 명세 1번. 첫 화면을 먼저 열어 세션 쿠키를 받은 뒤 로그인한다(시뮬레이터에서
  /// 성공한 순서 그대로). 리다이렉트를 끝까지 따라가 최종 응답이 2xx이고 주소에
  /// `/login/`이 없으면 성공이다.
  Future<void> _login(
    _HostCookies cookies,
    String userId,
    String userPwd,
  ) async {
    await _send(
      cookies,
      http.Request('GET', Uri.parse('$_base/clientMain/a/t/main.do')),
    );
    final (status, finalUrl, _) = await _send(
      cookies,
      http.Request('POST', Uri.parse('$_base/login/a/n/loginProc.do'))
        ..headers.addAll({
          'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
          'Origin': _base,
          'Referer': '$_base/clientMain/a/t/main.do',
        })
        ..body =
            'targetUrl=%2FclientMain%2Fa%2Ft%2Fmain.do'
            '&userId=${Uri.encodeQueryComponent(userId)}'
            '&userPw=${Uri.encodeQueryComponent(userPwd)}',
    );
    if (status < 200 || status >= 300 || finalUrl.path.contains('/login/')) {
      throw const TwinRankException(
        TwinRankFailure.loginFailed,
        'T-WIN 로그인에 실패했어요',
      );
    }
  }

  /// 명세 2번. `li.grade_my strong`이 내 평점, `li.grade_same strong`이 같은 학년 평균.
  Future<(double, double?)> _fetchMyGpa(
    _HostCookies cookies,
    String sustCd,
    String shyrCd,
  ) async {
    final (status, _, body) = await _send(
      cookies,
      _ajaxPost(
        '/myFuture/a/n/getResultDivInfoPage.do',
        'sustCd=$sustCd&shyrCd=$shyrCd&pageIndex=1'
            '&searchType=STD_GROUP&roadMapType=SAMEGRADE',
      ),
      followRedirects: false,
    );
    final doc = html_parser.parse(body);
    double? number(String selector) =>
        double.tryParse(doc.querySelector(selector)?.text.trim() ?? '');
    final myGpa = status == 200 ? number('li.grade_my strong') : null;
    if (myGpa == null) {
      throw TwinRankException(
        TwinRankFailure.noData,
        '평점을 찾지 못했어요 (응답 $status)',
      );
    }
    return (myGpa, number('li.grade_same strong'));
  }

  /// 명세 3번. 1페이지에서 전체 인원수를 읽고, 나머지 페이지는 한꺼번에 요청한 뒤
  /// 페이지 순서대로 이어 붙인다.
  Future<(List<double>, int)> _fetchPeers(
    _HostCookies cookies,
    String sustCd,
    String shyrCd,
  ) async {
    Future<String> page(int index) async {
      final (status, _, body) = await _send(
        cookies,
        _ajaxPost(
          '/myFuture/r/n/getGrStdCompareListAjax.do',
          'sustCd=$sustCd&shyrCd=$shyrCd&searchType=STD_GROUP'
              '&pageIndex=$index',
        ),
        followRedirects: false,
      );
      if (status != 200) {
        throw TwinRankException(
          TwinRankFailure.noData,
          '동기 평점 목록을 받지 못했어요 (응답 $status)',
        );
      }
      return body;
    }

    final first = await page(1);
    final total =
        int.tryParse(_totalCntPattern.firstMatch(first)?.group(1) ?? '') ?? 0;
    final pageCount = total == 0 ? 1 : (total / _pageSize).ceil();
    final rest = await Future.wait([
      for (var i = 2; i <= pageCount; i++) page(i),
    ]);
    return (
      [
        for (final body in [first, ...rest]) ..._parsePeerRows(body),
      ],
      total,
    );
  }

  static List<double> _parsePeerRows(String body) => [
    for (final row
        in html_parser.parse(body).querySelectorAll('table tbody tr'))
      if (row.querySelectorAll('td') case final cells when cells.length > 1)
        ?double.tryParse(cells[1].text.trim()),
  ];

  http.Request _ajaxPost(String path, String body) =>
      http.Request('POST', Uri.parse('$_base$path'))
        ..headers.addAll({
          'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
          'IS_AJAX': 'isAjax',
          'X-Requested-With': 'XMLHttpRequest',
          'Origin': _base,
          'Referer': _referer,
        })
        ..body = body;

  /// 요청을 보내고 (최종 상태 코드, 최종 주소, 본문)을 돌려준다.
  /// [followRedirects]면 3xx를 직접 따라가며 각 서버의 쿠키를 주고받는다.
  Future<(int, Uri, String)> _send(
    _HostCookies cookies,
    http.Request request, {
    bool followRedirects = true,
  }) async {
    var current = request;
    for (var hop = 0; hop <= _maxRedirects; hop++) {
      current
        ..followRedirects = false
        ..headers['User-Agent'] = _userAgent;
      final cookieHeader = cookies.headerFor(current.url);
      if (cookieHeader.isNotEmpty) current.headers['Cookie'] = cookieHeader;

      final http.Response response;
      try {
        response = await http.Response.fromStream(
          await _client.send(current).timeout(const Duration(seconds: 15)),
        );
      } catch (e) {
        throw TwinRankException(TwinRankFailure.network, '네트워크 오류: $e');
      }
      cookies.store(
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
    throw const TwinRankException(
      TwinRankFailure.loginFailed,
      'T-WIN 로그인 중 리다이렉트가 너무 많아요',
    );
  }

  Future<TwinGradeStats?> _readStored(String key) async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(key);
      if (raw == null) return null;
      return TwinGradeStats.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      // 저장된 값을 못 읽어도 서버에서 새로 받으면 되므로 조회를 막지 않는다.
      debugPrint('[TwinRank] 저장된 성적 읽기 실패: $e');
      return null;
    }
  }

  Future<void> _writeStored(String key, TwinGradeStats stats) async {
    try {
      await (await SharedPreferences.getInstance()).setString(
        key,
        jsonEncode(stats.toJson()),
      );
    } catch (e) {
      debugPrint('[TwinRank] 성적 저장 실패: $e');
    }
  }
}

/// 쿠키를 (서버, 이름)으로 나눠 보관한다. Domain 속성이 있으면 하위 서버에도
/// 보내고, 없으면 받은 서버에만 보낸다. 경로·만료 시각은 다루지 않고, Max-Age=0이면
/// 지운다.
class _HostCookies {
  final Map<String, ({String name, String value, String domain, bool hostOnly})>
  _items = {};

  void store(Uri url, List<String> setCookies) {
    for (final cookie in setCookies) {
      final parts = cookie.split(';');
      final eq = parts.first.indexOf('=');
      if (eq <= 0) continue;
      final name = parts.first.substring(0, eq).trim();
      final value = parts.first.substring(eq + 1).trim();
      var domain = url.host.toLowerCase();
      var hostOnly = true;
      var expired = false;
      for (final attr in parts.skip(1)) {
        final a = attr.trim().toLowerCase();
        if (a.startsWith('domain=')) {
          domain = a.substring(7).replaceFirst(RegExp(r'^\.'), '');
          hostOnly = false;
        } else if (a.startsWith('max-age=') && a.substring(8).trim() == '0') {
          expired = true;
        }
      }
      final key = '$domain|$name';
      if (expired) {
        _items.remove(key);
      } else {
        _items[key] = (
          name: name,
          value: value,
          domain: domain,
          hostOnly: hostOnly,
        );
      }
    }
  }

  String headerFor(Uri url) {
    final host = url.host.toLowerCase();
    return _items.values
        .where(
          (c) => c.hostOnly
              ? c.domain == host
              : host == c.domain || host.endsWith('.${c.domain}'),
        )
        .map((c) => '${c.name}=${c.value}')
        .join('; ');
  }
}
