import 'dart:async';

import 'package:cp949_codec/cp949_codec.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

/// `GET /sugang/center/ProLsnAply06.jsp` 응답의 한 행(개설 과목 하나).
class CourseCatalogItem {
  const CourseCatalogItem({
    required this.seq,
    required this.courseCode,
    required this.section,
    required this.courseName,
    required this.courseType,
    required this.credit,
    required this.targetGrade,
    required this.professor,
    required this.rawSchedule,
    required this.room,
    required this.isClosed,
    required this.capacity,
    required this.waitlistCount,
    required this.enrollmentRatio,
    this.note,
  });

  final int seq;
  final String courseCode;
  final String section;
  final String courseName;
  final String courseType;
  final double credit;
  final String targetGrade;
  final String professor;

  /// 시간표 원문. 추후 별도 파서로 구조화한다(이번 단계에서는 가공하지 않음).
  final String rawSchedule;
  final String room;
  final bool isClosed;
  final int capacity;
  final int waitlistCount;
  final String enrollmentRatio;
  final String? note;
}

/// "네트워크 연결 실패"와 "서버는 응답했지만 비정상(status != 200)"과
/// "응답은 받았지만 HTML 구조가 기대와 다름(파싱 실패)"은 서로 다른 실패
/// 사유이므로 구분한다.
sealed class CourseCatalogException implements Exception {
  const CourseCatalogException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 네트워크 연결 실패 또는 타임아웃.
class CourseCatalogNetworkException extends CourseCatalogException {
  const CourseCatalogNetworkException(super.message);
}

/// 서버가 200이 아닌 상태 코드로 응답한 경우.
class CourseCatalogServerException extends CourseCatalogException {
  const CourseCatalogServerException(super.message);
}

/// 응답 본문이 기대한 HTML 테이블 구조가 아니거나, 셀 값이 기대한 타입으로
/// 변환되지 않는 경우(레거시 시스템이 응답 HTML을 바꾼 경우 등).
class CourseCatalogParseException extends CourseCatalogException {
  const CourseCatalogParseException(super.message);
}

/// 포털 로그인으로 얻은 세션 쿠키(JSESSIONID/WMONID)를 이용해 수강신청
/// 시스템의 "개설과목 조회"(`GET /sugang/center/ProLsnAply06.jsp`)를
/// 호출한다.
///
/// 공개 데이터 조회라 user_id/userId는 고정값(기본 "guest")을 넣어도 동작한다고
/// 명세에 적혀 있다. nm/userFlag/userMjCd/resd1/resd2/orgCd/seq/wkkdCd/
/// passwd/cookWebUser는 SUGANG_FULL_COOKIE 패턴(패턴 F)의 고정 상수값이다.
class CourseCatalogService {
  static const _endpoint =
      'https://dreams2.daejin.ac.kr/sugang/center/ProLsnAply06.jsp';
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

  static const _defaultUserId = 'guest';

  // 명세: "각 행의 직계 자식 td가 14개 미만이면 폐기".
  static const _minColumnCount = 14;

  final http.Client _client;

  CourseCatalogService({http.Client? client})
    : _client = client ?? http.Client();

  /// [year]/[semester]: 쿼리 파라미터 fhd_yyyy/fhd_shtm.
  /// [icKwa]: 쿼리 파라미터 ic_kwa. "%"(전체) 또는 학과코드(예: "B41005").
  /// [icKwa1]: 쿼리 파라미터 ic_kwa_1. [icKwa]가 "%"가 아닐 때만 필요한 학과코드.
  /// [jsessionId]/[wmonid]: 포털 로그인으로 얻은 세션 쿠키 값.
  /// [userId]: user_id/userId 쿠키 값. 공개 데이터라 생략 시 고정값("guest")을 쓴다.
  Future<List<CourseCatalogItem>> fetchCourseCatalog({
    required int year,
    required int semester,
    required String jsessionId,
    required String wmonid,
    String icKwa = '%',
    String? icKwa1,
    String? userId,
  }) async {
    if (icKwa != '%' && (icKwa1 == null || icKwa1.isEmpty)) {
      throw ArgumentError('icKwa가 전체("%")가 아닐 때는 icKwa1(학과코드)이 필요합니다.');
    }

    final resolvedUserId = userId ?? _defaultUserId;
    final uri = Uri.parse(_endpoint).replace(
      queryParameters: {
        'fhd_yyyy': year.toString(),
        'fhd_shtm': semester.toString(),
        'ic_kwa': icKwa,
        if (icKwa != '%') 'ic_kwa_1': icKwa1,
      },
    );

    final cookie =
        'JSESSIONID=$jsessionId; '
        'user_id=$resolvedUserId; userId=$resolvedUserId; '
        '$_fixedCookieFields; '
        'WMONID=$wmonid';

    http.Response response;
    try {
      response = await _client
          .get(uri, headers: {'Cookie': cookie, 'User-Agent': _userAgent})
          .timeout(const Duration(seconds: 15));
    } on TimeoutException catch (e) {
      throw CourseCatalogNetworkException('요청 시간 초과: $e');
    } catch (e) {
      throw CourseCatalogNetworkException('네트워크 오류: $e');
    }

    if (response.statusCode != 200) {
      throw CourseCatalogServerException('서버 오류 (${response.statusCode})');
    }

    // 명세: 응답은 EUC-KR 인코딩 — UTF-8이 아니라 EUC-KR로 디코딩해야 한글이
    // 안 깨진다. cp949는 EUC-KR(KS X 1001)의 상위 집합이라 호환된다.
    String body;
    try {
      body = cp949.decode(response.bodyBytes);
    } catch (e) {
      throw CourseCatalogParseException('EUC-KR 디코딩에 실패했습니다: $e');
    }

    try {
      return _parse(body);
    } on CourseCatalogParseException {
      rethrow;
    } catch (e) {
      throw CourseCatalogParseException('응답 구조가 예상과 다릅니다: $e');
    }
  }

  List<CourseCatalogItem> _parse(String body) {
    final document = html_parser.parse(body);
    // "tr[class^=tr_a]" prefix 매칭 — tr_a0_chrm/tr_a1_chrm은 걸리고
    // 헤더행 tr_chrm_n은 자연히 제외된다.
    final rows = document.querySelectorAll('tr[class^=tr_a]');

    final items = <CourseCatalogItem>[];
    for (final row in rows) {
      final cells = row.children.where((e) => e.localName == 'td').toList();
      if (cells.length < _minColumnCount) continue;

      String cellText(int index) => cells[index].text.trim();

      // [1] 과목코드-분반 — 마지막 "-" 기준 split.
      final codeAndSection = cellText(1);
      final dashIndex = codeAndSection.lastIndexOf('-');
      final courseCode = dashIndex >= 0
          ? codeAndSection.substring(0, dashIndex)
          : codeAndSection;
      final section = dashIndex >= 0
          ? codeAndSection.substring(dashIndex + 1)
          : '';

      final noteText = cellText(13);

      // 명세대로 숫자 칼럼([0]/[4]/[10]/[11])을 엄격히 파싱하되, 실제
      // 응답에는 명세에 없는 예외적인 행(예: 정원/대기인원 칸에 숫자가 아닌
      // 값이 들어간 행)이 섞여 들어올 수 있다는 게 실기기 테스트로 확인됐다.
      // 행 하나가 깨졌다고 검색 결과 전체를 날리지 않도록, 해당 행만 건너뛴다.
      final int seq;
      final double credit;
      final int capacity;
      final int waitlistCount;
      try {
        seq = int.parse(cellText(0));
        credit = double.parse(cellText(4));
        capacity = int.parse(cellText(10));
        waitlistCount = int.parse(cellText(11));
      } catch (_) {
        continue;
      }

      items.add(
        CourseCatalogItem(
          seq: seq,
          courseCode: courseCode,
          section: section,
          courseName: cellText(2),
          courseType: cellText(3),
          credit: credit,
          targetGrade: cellText(5),
          professor: cellText(6),
          rawSchedule: cellText(7),
          room: cellText(8),
          isClosed: cellText(9).isNotEmpty,
          capacity: capacity,
          waitlistCount: waitlistCount,
          enrollmentRatio: cellText(12),
          note: noteText.isEmpty ? null : noteText,
        ),
      );
    }
    return items;
  }
}
