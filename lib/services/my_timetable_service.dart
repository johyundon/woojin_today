import 'dart:async';

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

    if (response.statusCode != 200) {
      throw MyTimetableServerException('서버 오류 (${response.statusCode})');
    }

    // 명세 본문에는 이 엔드포인트의 인코딩이 명시돼 있지 않지만, 같은
    // dreams2.daejin.ac.kr(수강신청 시스템) 소속이고 명세서 공통 섹션에
    // "수강신청 시스템 응답 인코딩이 EUC-KR인 경우가 많음"이라고 돼 있어
    // 1단계(개설과목 조회)와 동일하게 EUC-KR/CP949로 디코딩한다.
    String body;
    try {
      body = cp949.decode(response.bodyBytes);
    } catch (e) {
      throw MyTimetableParseException('EUC-KR 디코딩에 실패했습니다: $e');
    }

    try {
      return _parse(body);
    } on MyTimetableParseException {
      rethrow;
    } catch (e) {
      throw MyTimetableParseException('응답 구조가 예상과 다릅니다: $e');
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
