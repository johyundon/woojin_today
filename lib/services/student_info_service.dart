import 'dart:async';

import 'package:cp949_codec/cp949_codec.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

/// `GET /sugang/center/Bshr020101.jsp` 응답(지도교수/학생 개인정보 테이블).
///
/// 지도교수 성함뿐 아니라 같은 테이블(`td.tr_chrm1_n` 라벨-값 쌍)에 있을 것으로
/// 보이는 이름/학과/학년도 한 번의 호출로 함께 파싱한다.
///
/// "지도교수" 라벨은 명세서 원문에 명시된 값이라 추측이 아니다. 반면
/// 이름/학과/학년의 라벨 문자열은 **추론이며 실기기 응답으로 검증되지
/// 않았다** — 실제 라벨이 다르면 해당 필드는 조용히 null로 남는다.
class StudentInfoResponse {
  const StudentInfoResponse({
    this.advisorName,
    this.name,
    this.department,
    this.grade,
  });

  /// 지도교수 성함. 라벨("지도교수")이나 형제 요소가 없거나 비어있으면 null.
  final String? advisorName;

  /// 학생 이름. 라벨 후보는 추론이다("이름"/"성명") — 실기기 검증 필요.
  final String? name;

  /// 소속 학과. 라벨 후보는 추론이다("학과"/"학과명"/"소속학과") — 실기기 검증 필요.
  final String? department;

  /// 학년. 라벨 후보는 추론이다("학년"/"학년도") — 실기기 검증 필요.
  final String? grade;
}

/// "네트워크 연결 실패"와 "서버는 응답했지만 비정상(status != 200)"과
/// "응답은 받았지만 디코딩/구조가 기대와 다름"은 서로 다른 실패 사유이므로
/// 구분한다.
sealed class StudentInfoException implements Exception {
  const StudentInfoException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 네트워크 연결 실패 또는 타임아웃.
class StudentInfoNetworkException extends StudentInfoException {
  const StudentInfoNetworkException(super.message);
}

/// 서버가 200이 아닌 상태 코드로 응답한 경우.
class StudentInfoServerException extends StudentInfoException {
  const StudentInfoServerException(super.message);
}

/// 응답 본문을 EUC-KR로 디코딩하지 못한 경우(레거시 시스템이 인코딩을
/// 바꾼 경우 등). 반면 개별 라벨을 테이블에서 못 찾는 것은 파싱 "실패"가
/// 아니라 해당 필드가 null인 정상 케이스로 취급한다(지도교수 이름 조회
/// 명세의 기존 처리 방식과 동일).
class StudentInfoParseException extends StudentInfoException {
  const StudentInfoParseException(super.message);
}

/// 포털 로그인으로 얻은 **본인** userId2로 수강신청 시스템의 "내 지도교수
/// 이름 조회" (`GET /sugang/center/Bshr020101.jsp`)를 호출해, 같은 응답에서
/// 지도교수/이름/학과/학년을 한 번에 파싱한다.
///
/// SUGANG_SIMPLE_COOKIE 패턴(패턴 S) 사용 — `userId`/`orgCd` 2필드만 필요하고
/// (다른 dreams2 서비스들이 쓰는 SUGANG_FULL_COOKIE 패턴 F와 달리)
/// JSESSIONID/WMONID는 쓰지 않는다.
class StudentInfoService {
  static const _endpoint =
      'https://dreams2.daejin.ac.kr/sugang/center/Bshr020101.jsp';
  static const _userAgent =
      'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36';

  // SUGANG_SIMPLE_COOKIE 패턴(패턴 S)의 고정 상수 쿠키 필드.
  static const _fixedOrgCd = 'orgCd=ZjzT1v9Ax6ybAbmfZIWOsA%3D%3D';

  // 지도교수 라벨은 명세서 원문에 명시된 값("지도교수") — 추측 아님.
  static const _advisorLabels = ['지도교수'];

  // 아래 세 라벨 집합은 실기기 응답으로 검증되지 않은 추론이다. 실제 라벨이
  // 다르면 모든 후보가 실패하고 해당 필드는 null로 남는다(에러를 던지지 않음).
  static const _nameLabels = ['이름', '성명'];
  static const _departmentLabels = ['학과', '학과명', '소속학과'];
  static const _gradeLabels = ['학년', '학년도'];

  final http.Client _client;

  StudentInfoService({http.Client? client}) : _client = client ?? http.Client();

  /// [userId2]: 포털 로그인으로 얻은 **본인** SSO uid. 개인 데이터 조회라
  /// 고정값/기본값을 두지 않는다 — 반드시 호출자가 실제 값을 넘겨야 한다.
  Future<StudentInfoResponse> fetchStudentInfo({
    required String userId2,
  }) async {
    final cookie = 'userId=$userId2; $_fixedOrgCd;';

    http.Response response;
    try {
      response = await _client
          .get(
            Uri.parse(_endpoint),
            headers: {'Cookie': cookie, 'User-Agent': _userAgent},
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException catch (e) {
      throw StudentInfoNetworkException('요청 시간 초과: $e');
    } catch (e) {
      throw StudentInfoNetworkException('네트워크 오류: $e');
    }

    if (response.statusCode != 200) {
      throw StudentInfoServerException('서버 오류 (${response.statusCode})');
    }

    // 명세: 응답은 EUC-KR 인코딩 — UTF-8이 아니라 EUC-KR로 디코딩해야 한글이
    // 안 깨진다. cp949는 EUC-KR(KS X 1001)의 상위 집합이라 호환된다.
    String body;
    try {
      body = cp949.decode(response.bodyBytes);
    } catch (e) {
      throw StudentInfoParseException('EUC-KR 디코딩에 실패했습니다: $e');
    }

    return _parse(body);
  }

  StudentInfoResponse _parse(String body) {
    final document = html_parser.parse(body);
    final cells = document.querySelectorAll('td.tr_chrm1_n');

    return StudentInfoResponse(
      advisorName: _findValue(cells, _advisorLabels),
      name: _findValue(cells, _nameLabels),
      department: _findValue(cells, _departmentLabels),
      grade: _findValue(cells, _gradeLabels),
    );
  }

  /// [labels] 중 하나와 텍스트가 정확히 일치하는 `td.tr_chrm1_n`을 찾아 그
  /// `nextElementSibling`의 텍스트(trim)를 반환한다. 라벨/형제 요소가 없거나
  /// 값이 비어있으면 null(에러를 던지지 않음).
  String? _findValue(List<Element> cells, List<String> labels) {
    for (final cell in cells) {
      if (labels.contains(cell.text.trim())) {
        final value = cell.nextElementSibling?.text.trim();
        if (value != null && value.isNotEmpty) return value;
      }
    }
    return null;
  }
}
