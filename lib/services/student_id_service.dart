import 'dart:convert';

import 'package:http/http.dart' as http;

/// `POST /userInfoSearch/daejin/1/idSearch.do` 호출 결과.
///
/// "학번 찾음 / 일치하는 학생 없음 / 네트워크·서버 오류"는 서로 다른 실패 사유이므로
/// 하나의 nullable 필드로 뭉치지 않고 별도 타입으로 구분한다.
sealed class StudentIdSearchResult {
  const StudentIdSearchResult();
}

/// 학번을 찾은 경우.
class StudentIdFound extends StudentIdSearchResult {
  const StudentIdFound(this.studentNo);

  final String studentNo;
}

/// 입력한 정보와 일치하는 학생이 없는 경우.
class StudentIdNotFound extends StudentIdSearchResult {
  const StudentIdNotFound();
}

/// 네트워크 오류 또는 서버 오류(5xx 등)로 요청을 완료하지 못한 경우.
class StudentIdSearchError extends StudentIdSearchResult {
  const StudentIdSearchError(this.message);

  final String message;
}

/// 대진대 포털의 "학번 찾기" 공개 API(비로그인, 세션/쿠키 불필요)를 호출한다.
class StudentIdService {
  static const _endpoint =
      'https://www.daejin.ac.kr/userInfoSearch/daejin/1/idSearch.do';

  /// 조회된 학번은 <strong>20211476</strong> 형태의 응답 HTML에서 학번만 뽑아낸다.
  static final _studentNoPattern = RegExp(
    r'조회된\s*학번은\s*<strong>\s*(\d+)\s*</strong>',
  );

  final http.Client _client;

  StudentIdService({http.Client? client}) : _client = client ?? http.Client();

  /// [name]: 이름, [birthday6]: "YYMMDD" 6자리,
  /// [mobile1]/[mobile2]/[mobile3]: 휴대폰 앞/중/뒤자리.
  Future<StudentIdSearchResult> findStudentId({
    required String name,
    required String birthday6,
    required String mobile1,
    required String mobile2,
    required String mobile3,
  }) async {
    // http 패키지에 Map을 넘기면 모든 필드가 자동으로 URL 인코딩되므로
    // 명세의 "srchNm만 인코딩, 나머지는 raw" 규칙을 지킬 수 없다.
    // 바디 문자열을 직접 조립한다.
    final encodedName = Uri.encodeQueryComponent(name);
    final body =
        'findType=2'
        '&srchGubun=1'
        '&srchNm=$encodedName'
        '&srchBirthday=$birthday6'
        '&srchMobile1=$mobile1'
        '&srchMobile2=$mobile2'
        '&srchMobile3=$mobile3';

    http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(_endpoint),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: body,
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      return StudentIdSearchError('네트워크 오류: $e');
    }

    if (response.statusCode != 200) {
      return StudentIdSearchError('서버 오류 (${response.statusCode})');
    }

    // http 패키지는 응답 헤더에 charset이 없으면 기본적으로 latin1로
    // 디코딩해 한글이 깨진다. 서버가 UTF-8이면서 charset을 명시하지 않는
    // 경우를 대비해 bodyBytes를 직접 UTF-8로 디코딩한다.
    final decodedBody = utf8.decode(response.bodyBytes, allowMalformed: true);
    final match = _studentNoPattern.firstMatch(decodedBody);
    if (match == null) {
      return const StudentIdNotFound();
    }
    return StudentIdFound(match.group(1)!);
  }
}
