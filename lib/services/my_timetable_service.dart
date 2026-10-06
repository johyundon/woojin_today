import 'dart:async';
import 'dart:convert';

import 'package:cp949_codec/cp949_codec.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

/// `POST /sugang/center/BlsnTotalTimeTableLst.jsp` 응답(내 시간표).
///
/// 중복 제거를 위해 "과목코드-분반" 문자열 집합으로만 표현한다. 시간 문자열
/// 파싱 등 추가 가공은 이후 단계에서 다룬다(이번 단계에서는 가공하지 않음).
class MyTimetableResponse {
  const MyTimetableResponse({required this.courseSectionCodes});

  /// "과목코드-분반" 형태의 문자열 집합(중복 제거됨).
  final Set<String> courseSectionCodes;
}

/// "네트워크 연결 실패"와 "서버는 응답했지만 비정상(status != 200)"과
/// "응답은 받았지만 HTML 구조가 기대와 다름(파싱 실패)"은 서로 다른 실패
/// 사유이므로 구분한다.
sealed class MyTimetableException implements Exception {
  const MyTimetableException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 네트워크 연결 실패 또는 타임아웃.
class MyTimetableNetworkException extends MyTimetableException {
  const MyTimetableNetworkException(super.message);
}

/// 서버가 200이 아닌 상태 코드로 응답한 경우.
class MyTimetableServerException extends MyTimetableException {
  const MyTimetableServerException(super.message);
}

/// 응답 본문이 기대한 HTML 테이블 구조가 아닌 경우(레거시 시스템이 응답
/// HTML을 바꾼 경우 등).
class MyTimetableParseException extends MyTimetableException {
  const MyTimetableParseException(super.message);
}

/// 디코딩 결과(본문 문자열)와, 어떤 방법으로 디코딩했는지(진단 로그용)를
/// 함께 담는다.
class _DecodedBody {
  const _DecodedBody(this.body, this.method);

  final String body;
  final String method;
}

/// 포털 로그인으로 얻은 세션 쿠키(JSESSIONID/WMONID)와 **본인 userId2**를
/// 이용해 수강신청 시스템의 "내 시간표 불러오기"
/// (`POST /sugang/center/BlsnTotalTimeTableLst.jsp`)를 호출한다.
///
/// 개인 데이터 조회이므로 1단계(개설과목 조회, 공개 데이터)와 달리 user_id/
/// userId 쿠키 값에 고정값(예: "guest")을 쓰면 안 된다. 호출자가 반드시
/// 본인의 userId2를 넘겨야 하며, 이 서비스는 그 값을 기본값 없이 필수
/// 파라미터로만 받는다. nm/userFlag/userMjCd/resd1/resd2/orgCd/seq/wkkdCd/
/// passwd/cookWebUser는 SUGANG_FULL_COOKIE 패턴(패턴 F)의 고정 상수값이다.
class MyTimetableService {
  static const _endpoint =
      'https://dreams2.daejin.ac.kr/sugang/center/BlsnTotalTimeTableLst.jsp';
  static const _userAgent =
      'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36';

  // SUGANG_FULL_COOKIE 패턴(패턴 F)의 고정 상수 쿠키 필드.
  static const _fixedCookieFields =
      'nm=8p13%2B7QRPNTh19POT6%2FJPw%3D%3D; '
      'userFlag=M0KvE%2FndjQ2bDxDXFBSM6A%3D%3D; '
      'userMjCd=AFkB9N2kRhFOtBPWa6nzxg%3D%3D; '
      'resd1=kffK4oSHCEBxASZ5sQOZeQ%3D%3D; '
      'resd2=KOXkLxIFhOL33Ka%2BYe1Yrw%3D%3D; '
      'orgCd=ZjzT1v9Ax6ybAbmfZIWOsA%3D%3D; '
      'seq=b%2B3V6U777TAsKzSC6a5IAA%3D%3D; '
      'wkkdCd=AFkB9N2kRhFOtBPWa6nzxg%3D%3D; '
      'passwd=AFkB9N2kRhFOtBPWa6nzxg%3D%3D; '
      'cookWebUser=btH3g7sAv6imoh3YAJBUEA%3D%3D';

  // 명세: "각 행의 직계 자식 td가 3개 미만이면 폐기".
  static const _minColumnCount = 3;

  final http.Client _client;

  MyTimetableService({http.Client? client}) : _client = client ?? http.Client();

  /// [year]/[semester]: 요청 바디 selectYear(연도+학기를 구분자 없이 이어붙임.
  /// 예: year=2026, semester=2 -> "20262").
  /// [jsessionId]/[wmonid]: 포털 로그인으로 얻은 세션 쿠키 값.
  /// [userId2]: 포털 로그인으로 얻은 **본인** SSO uid. 개인 데이터 조회라
  /// 고정값/기본값을 두지 않는다 — 반드시 호출자가 실제 값을 넘겨야 한다.
  Future<MyTimetableResponse> fetchMyTimetable({
    required int year,
    required int semester,
    required String jsessionId,
    required String wmonid,
    required String userId2,
  }) async {
    final selectYear = '$year$semester';

    final cookie =
        'JSESSIONID=$jsessionId; '
        'user_id=$userId2; userId=$userId2; '
        '$_fixedCookieFields; '
        'WMONID=$wmonid';

    http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(_endpoint),
            headers: {'Cookie': cookie, 'User-Agent': _userAgent},
            body: {'selectYear': selectYear},
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException catch (e) {
      throw MyTimetableNetworkException('요청 시간 초과: $e');
    } catch (e) {
      throw MyTimetableNetworkException('네트워크 오류: $e');
    }

    // TODO(debug): 실기기 디코딩/파싱 실패 원인 추적용 진단 로그 — 쿠키 값
    // 자체는 민감정보라 남기지 않고, 길이/존재 여부만 남긴다. 진단 끝나면
    // 제거(portal_login_service.dart의 동일 패턴 참고).
    print(
      '[MyTimetable] status=${response.statusCode} '
      'content-type=${response.headers['content-type']} '
      'bodyBytes=${response.bodyBytes.length}',
    );

    if (response.statusCode != 200) {
      throw MyTimetableServerException('서버 오류 (${response.statusCode})');
    }

    final decoded = _decodeBody(response);
    print('[MyTimetable] decode=${decoded.method}');
    final preview = decoded.body.substring(
      0,
      decoded.body.length < 200 ? decoded.body.length : 200,
    );
    print('[MyTimetable] bodyPreview=$preview');

    try {
      return _parse(decoded.body);
    } on MyTimetableParseException {
      rethrow;
    } catch (e) {
      throw MyTimetableParseException('응답 구조가 예상과 다릅니다: $e');
    }
  }

  // "charset=EUC-KR" / `charset="UTF-8"` 등에서 charset 값만 뽑는다.
  static final _charsetPattern = RegExp(
    r'charset\s*=\s*"?([\w-]+)"?',
    caseSensitive: false,
  );

  /// 응답 바이트를 디코딩한다.
  ///
  /// 1순위: 서버가 `Content-Type` 헤더에 실제로 선언한 charset이 있으면 그걸
  /// 신뢰한다(EUC-KR 추정이던 기존 방식보다 신뢰도가 높다 — 서버가 스스로
  /// 밝힌 값이기 때문).
  /// 2순위(헤더에 charset이 없거나, 헤더가 선언한 값으로 디코딩이 실패하거나,
  /// 모르는 값인 경우): 기존처럼 EUC-KR -> UTF-8(strict) -> UTF-8
  /// (allowMalformed, 항상 성공) 순으로 폴백한다. "시간표가 아직 없음"은
  /// 정상 상태이므로 모든 디코딩이 실패해도 예외를 던지지 않고 마지막
  /// allowMalformed 단계로 항상 결과를 만든다 — 그래도 table#tTbl을 못
  /// 찾으면 _parse()가 빈 시간표로 처리한다(기존 동작).
  _DecodedBody _decodeBody(http.Response response) {
    final contentType = response.headers['content-type'];
    final charset = contentType == null
        ? null
        : _charsetPattern.firstMatch(contentType)?.group(1)?.toLowerCase();

    if (charset != null) {
      final isEucKr =
          charset == 'euc-kr' ||
          charset == 'cp949' ||
          charset == 'ks_c_5601-1987' ||
          charset == 'x-windows-949';
      final isUtf8 = charset == 'utf-8' || charset == 'utf8';

      if (isEucKr) {
        try {
          return _DecodedBody(
            cp949.decode(response.bodyBytes),
            'Content-Type 헤더(charset=$charset) 기반 EUC-KR',
          );
        } catch (_) {
          // 헤더가 선언한 값과 실제 바이트가 안 맞음 -> 아래 폴백 체인으로.
        }
      } else if (isUtf8) {
        try {
          return _DecodedBody(
            utf8.decode(response.bodyBytes),
            'Content-Type 헤더(charset=$charset) 기반 UTF-8',
          );
        } catch (_) {
          // 헤더가 선언한 값과 실제 바이트가 안 맞음 -> 아래 폴백 체인으로.
        }
      }
      // charset이 있지만 euc-kr/utf-8이 아닌 값이면 그대로 아래 폴백 체인으로.
    }

    try {
      return _DecodedBody(
        cp949.decode(response.bodyBytes),
        'Content-Type 헤더 없음/불명 -> EUC-KR 폴백',
      );
    } catch (_) {
      try {
        return _DecodedBody(
          utf8.decode(response.bodyBytes),
          'Content-Type 헤더 없음/불명 -> UTF-8(strict) 폴백',
        );
      } catch (_) {
        return _DecodedBody(
          utf8.decode(response.bodyBytes, allowMalformed: true),
          'Content-Type 헤더 없음/불명 -> UTF-8(allowMalformed) 폴백',
        );
      }
    }
  }

  MyTimetableResponse _parse(String body) {
    final document = html_parser.parse(body);
    final rows = document.querySelectorAll('table#tTbl tr');

    final codes = <String>{};
    for (var i = 0; i < rows.length; i++) {
      if (i == 0) continue; // 헤더 행 스킵.

      final cells = rows[i].children.where((e) => e.localName == 'td').toList();
      if (cells.length < _minColumnCount) continue;

      final courseCode = cells[0].text.trim();
      final section = cells[2].text.trim();
      codes.add('$courseCode-$section');
    }

    return MyTimetableResponse(courseSectionCodes: codes);
  }
}
