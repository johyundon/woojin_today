// 내 시간표 불러오기 응답(EUC-KR 인코딩 HTML) 파싱 로직을 고정된 픽스처로 검증한다.
// 실제 대진대 서버 호출(네트워크)은 하지 않고 http.testing.MockClient로 대체한다.

import 'package:cp949_codec/cp949_codec.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/services/my_timetable_service.dart';

/// <td>들을 조립해 `table#tTbl`의 한 행을 만드는 헬퍼.
String _row(List<String> cells) {
  final tds = cells.map((c) => '<td>$c</td>').join();
  return '<tr>$tds</tr>';
}

/// [rowsHtml]을 `table#tTbl` 안에 넣고(첫 행은 헤더로 간주) EUC-KR 바이트로
/// 인코딩한 전체 응답 본문을 만든다.
List<int> _fixtureBytes(List<String> rowsHtml) {
  final html =
      '<html><body><table id="tTbl">'
      '<tr><td>과목코드</td><td>과목명</td><td>분반</td></tr>'
      '${rowsHtml.join()}'
      '</table></body></html>';
  return cp949.encode(html);
}

void main() {
  group('MyTimetableService.fetchMyTimetable', () {
    test('정상 행을 과목코드-분반 문자열로 파싱한다', () async {
      final bytes = _fixtureBytes([
        _row(['CSE301', '자료구조', '01']),
      ]);
      final mockClient = MockClient((request) async {
        return http.Response.bytes(bytes, 200);
      });
      final service = MyTimetableService(client: mockClient);

      final result = await service.fetchMyTimetable(
        year: 2026,
        semester: 2,
        jsessionId: 'JSESSION123',
        wmonid: 'WMONID123',
        userId2: 'REAL_USER_UID',
      );

      expect(result.courseSectionCodes, {'CSE301-01'});
    });

    test('헤더 행(첫 번째 행)은 제외된다', () async {
      // _fixtureBytes가 항상 첫 행을 헤더로 포함시키므로, 데이터 행이
      // 없으면 결과가 비어 있어야 한다(헤더행이 섞여 들어오지 않음을 검증).
      final bytes = _fixtureBytes([]);
      final mockClient = MockClient((request) async {
        return http.Response.bytes(bytes, 200);
      });
      final service = MyTimetableService(client: mockClient);

      final result = await service.fetchMyTimetable(
        year: 2026,
        semester: 2,
        jsessionId: 'J',
        wmonid: 'W',
        userId2: 'REAL_USER_UID',
      );

      expect(result.courseSectionCodes, isEmpty);
    });

    test('직계 자식 td가 3개 미만인 행은 폐기한다', () async {
      final shortRow = '<tr><td>CSE301</td><td>자료구조</td></tr>';
      final bytes = _fixtureBytes([shortRow]);
      final mockClient = MockClient((request) async {
        return http.Response.bytes(bytes, 200);
      });
      final service = MyTimetableService(client: mockClient);

      final result = await service.fetchMyTimetable(
        year: 2026,
        semester: 2,
        jsessionId: 'J',
        wmonid: 'W',
        userId2: 'REAL_USER_UID',
      );

      expect(result.courseSectionCodes, isEmpty);
    });

    test('같은 과목코드-분반이 여러 번 나오면 Set으로 중복 제거된다', () async {
      final bytes = _fixtureBytes([
        _row(['CSE301', '자료구조', '01']),
        _row(['CSE301', '자료구조', '01']),
        _row(['MAT201', '선형대수', '02']),
      ]);
      final mockClient = MockClient((request) async {
        return http.Response.bytes(bytes, 200);
      });
      final service = MyTimetableService(client: mockClient);

      final result = await service.fetchMyTimetable(
        year: 2026,
        semester: 2,
        jsessionId: 'J',
        wmonid: 'W',
        userId2: 'REAL_USER_UID',
      );

      expect(result.courseSectionCodes, {'CSE301-01', 'MAT201-02'});
    });

    test('요청 바디/쿠키가 명세대로 조립되고, userId2가 고정값이 아니라 그대로 전달된다', () async {
      Uri? capturedUri;
      String? capturedMethod;
      String? capturedBody;
      String? capturedCookie;
      final mockClient = MockClient((request) async {
        capturedUri = request.url;
        capturedMethod = request.method;
        capturedBody = request.body;
        capturedCookie = request.headers['Cookie'];
        return http.Response.bytes(_fixtureBytes([]), 200);
      });
      final service = MyTimetableService(client: mockClient);

      const myRealUserId2 = 'SOME_UNIQUE_REAL_UID_42';

      await service.fetchMyTimetable(
        year: 2026,
        semester: 2,
        jsessionId: 'JSESSION123',
        wmonid: 'WMONID123',
        userId2: myRealUserId2,
      );

      expect(capturedMethod, 'POST');
      expect(
        capturedUri?.toString(),
        'https://dreams2.daejin.ac.kr/sugang/center/BlsnTotalTimeTableLst.jsp',
      );
      expect(capturedBody, 'selectYear=20262');

      // 개인정보 요구사항: user_id/userId 쿠키 값은 호출자가 넘긴 실제
      // userId2여야 하고, "guest" 같은 고정값이 섞여 들어가면 안 된다.
      expect(capturedCookie, contains('user_id=$myRealUserId2'));
      expect(capturedCookie, contains('userId=$myRealUserId2'));
      expect(capturedCookie, isNot(contains('user_id=guest')));
      expect(capturedCookie, isNot(contains('userId=guest')));
      expect(capturedCookie, contains('JSESSIONID=JSESSION123'));
      expect(capturedCookie, contains('WMONID=WMONID123'));
      expect(capturedCookie, contains('nm=8p13%2B7QRPNTh19POT6%2FJPw%3D%3D'));
    });

    test('selectYear는 연도+학기를 구분자 없이 이어붙인 문자열이다', () async {
      String? capturedBody;
      final mockClient = MockClient((request) async {
        capturedBody = request.body;
        return http.Response.bytes(_fixtureBytes([]), 200);
      });
      final service = MyTimetableService(client: mockClient);

      await service.fetchMyTimetable(
        year: 2025,
        semester: 1,
        jsessionId: 'J',
        wmonid: 'W',
        userId2: 'U',
      );

      expect(capturedBody, 'selectYear=20251');
    });

    test('서버가 200이 아닌 상태 코드를 반환하면 MyTimetableServerException을 던진다', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });
      final service = MyTimetableService(client: mockClient);

      expect(
        () => service.fetchMyTimetable(
          year: 2026,
          semester: 2,
          jsessionId: 'J',
          wmonid: 'W',
          userId2: 'U',
        ),
        throwsA(isA<MyTimetableServerException>()),
      );
    });

    test('네트워크 예외가 발생하면 MyTimetableNetworkException을 던진다', () async {
      final mockClient = MockClient((request) async {
        throw const SocketExceptionStub();
      });
      final service = MyTimetableService(client: mockClient);

      expect(
        () => service.fetchMyTimetable(
          year: 2026,
          semester: 2,
          jsessionId: 'J',
          wmonid: 'W',
          userId2: 'U',
        ),
        throwsA(isA<MyTimetableNetworkException>()),
      );
    });

    test('응답 본문에 table#tTbl이 없으면 결과가 빈 Set이다(구조 변경을 파싱 실패로 흡수)', () async {
      final bytes = cp949.encode('<html><body>No table here</body></html>');
      final mockClient = MockClient((request) async {
        return http.Response.bytes(bytes, 200);
      });
      final service = MyTimetableService(client: mockClient);

      final result = await service.fetchMyTimetable(
        year: 2026,
        semester: 2,
        jsessionId: 'J',
        wmonid: 'W',
        userId2: 'U',
      );

      expect(result.courseSectionCodes, isEmpty);
    });
  });
}

/// MockClient 핸들러에서 네트워크 예외를 흉내내기 위한 간단한 Exception.
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}
