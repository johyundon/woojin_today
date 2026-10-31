import 'dart:async';
import 'dart:convert';

import 'package:cp949_codec/cp949_codec.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import 'course_catalog_service.dart';

/// `POST /sugang/center/BlsnTotalTimeTableLst.jsp` 응답(내 시간표).
///
/// 명세서는 "과목코드-분반"만 뽑아 개설과목 조회 결과와 대조하라고 했지만,
/// 실제 응답(2026-10-31 확인)의 `table#tTbl`에는 과목명·학점·교수·강의시간·
/// 강의실까지 10칸이 다 들어 있다. 그래서 개설과목 조회 없이 이 응답만으로
/// 과목 정보를 만든다. 화면/홈의 기존 코드를 그대로 쓰려고 [CourseCatalogItem]
/// 형태로 담는다(응답에 없는 정원·대상학년 등은 빈 값).
class MyTimetableResponse {
  const MyTimetableResponse({required this.courses});

  /// 내가 수강하는 과목들. 응답 표 순서 그대로, "과목코드-분반" 중복은 제거됨.
  final List<CourseCatalogItem> courses;

  /// "과목코드-분반" 문자열 집합.
  Set<String> get courseSectionCodes =>
      {for (final c in courses) '${c.courseCode}-${c.section}'};
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

/// [MyTimetableService]의 공개 API. 화면/팩토리는 이 인터페이스 타입으로
/// 서비스를 주고받아, 실제 구현(HTTP 호출)과 테스트용 가짜 구현
/// ([lib/services/fakes/fake_my_timetable_service.dart]의
/// `FakeMyTimetableService`)을 교체 가능하게 한다.
abstract class MyTimetableServiceBase {
  Future<MyTimetableResponse> fetchMyTimetable({
    required int year,
    required int semester,
    required String jsessionId,
    required String wmonid,
    required String userId2,
  });
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
class MyTimetableService implements MyTimetableServiceBase {
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

  // 실제 응답의 열 개수: 교과번호/교과목명/분반/이수구분/학점/담당교수/
  // 강의시간/강의실/개설학과/비고. 이보다 적은 행은 과목 행이 아니므로 버린다.
  static const _minColumnCount = 10;

  final http.Client _client;

  MyTimetableService({http.Client? client}) : _client = client ?? http.Client();

  /// [year]/[semester]: 요청 바디 selectYear(연도+학기를 구분자 없이 이어붙임.
  /// 예: year=2026, semester=2 -> "20262").
  /// [jsessionId]/[wmonid]: 포털 로그인으로 얻은 세션 쿠키 값.
  /// [userId2]: 포털 로그인으로 얻은 **본인** SSO uid. 개인 데이터 조회라
  /// 고정값/기본값을 두지 않는다 — 반드시 호출자가 실제 값을 넘겨야 한다.
  @override
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

    final decoded = _decodeBody(response);

    try {
      return _parse(decoded);
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
  String _decodeBody(http.Response response) {
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
          return cp949.decode(response.bodyBytes);
        } catch (_) {
          // 헤더가 선언한 값과 실제 바이트가 안 맞음 -> 아래 폴백 체인으로.
        }
      } else if (isUtf8) {
        try {
          return utf8.decode(response.bodyBytes);
        } catch (_) {
          // 헤더가 선언한 값과 실제 바이트가 안 맞음 -> 아래 폴백 체인으로.
        }
      }
      // charset이 있지만 euc-kr/utf-8이 아닌 값이면 그대로 아래 폴백 체인으로.
    }

    try {
      return cp949.decode(response.bodyBytes);
    } catch (_) {
      try {
        return utf8.decode(response.bodyBytes);
      } catch (_) {
        return utf8.decode(response.bodyBytes, allowMalformed: true);
      }
    }
  }

  MyTimetableResponse _parse(String body) {
    final document = html_parser.parse(body);
    final rows = document.querySelectorAll('table#tTbl tr');

    final seen = <String>{};
    final courses = <CourseCatalogItem>[];
    for (var i = 0; i < rows.length; i++) {
      if (i == 0) continue; // 헤더 행 스킵.

      final cells = rows[i].children
          .where((e) => e.localName == 'td')
          .map((e) => e.text.replaceAll(RegExp(r'\s+'), ' ').trim())
          .toList();
      if (cells.length < _minColumnCount) continue;

      final courseCode = cells[0];
      final section = cells[2];
      if (courseCode.isEmpty || !seen.add('$courseCode-$section')) continue;

      courses.add(
        CourseCatalogItem(
          seq: courses.length + 1,
          courseCode: courseCode,
          section: section,
          courseName: cells[1],
          courseType: cells[3],
          credit: double.tryParse(cells[4]) ?? 0,
          targetGrade: '',
          professor: cells[5],
          rawSchedule: cells[6],
          room: cells[7],
          isClosed: false,
          capacity: 0,
          waitlistCount: 0,
          enrollmentRatio: '',
          note: cells[9].isEmpty ? null : cells[9],
        ),
      );
    }

    return MyTimetableResponse(courses: courses);
  }
}
