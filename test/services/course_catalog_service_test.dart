// 개설과목 조회 응답(EUC-KR 또는 UTF-8 인코딩 HTML) 파싱 로직을 고정된
// 픽스처로 검증한다. 실제 대진대 서버 호출(네트워크)은 하지 않고
// http.testing.MockClient로 대체한다.

import 'dart:convert';

import 'package:cp949_codec/cp949_codec.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/services/course_catalog_service.dart';

/// 한 행 분량의 <td> 14개를 쉽게 조립하기 위한 헬퍼.
String _row(String trClass, List<String> cells) {
  final tds = cells.map((c) => '<td>$c</td>').join();
  return '<tr class="$trClass">$tds</tr>';
}

/// 정상 행 하나 분량의 기본 셀 값(인덱스 0~13).
List<String> _validCells({
  String seq = '1',
  String codeAndSection = 'CSE301-01',
  String name = '자료구조',
  String type = '전공필수',
  String credit = '3.0',
  String grade = '2',
  String professor = '홍길동',
  String schedule = '월1,2 화3',
  String room = '공학관201',
  String closed = '',
  String capacity = '40',
  String waitlist = '0',
  String ratio = '30/40',
  String note = '',
}) => [
  seq,
  codeAndSection,
  name,
  type,
  credit,
  grade,
  professor,
  schedule,
  room,
  closed,
  capacity,
  waitlist,
  ratio,
  note,
];

String _fixtureHtml(List<String> rowsHtml) =>
    '<html><body><table>'
    '<tr class="tr_chrm_n">'
    '<td>일련번호</td><td>과목코드</td><td>과목명</td><td>이수구분</td>'
    '<td>학점</td><td>학년</td><td>교수</td><td>시간표</td><td>강의실</td>'
    '<td>폐강</td><td>정원</td><td>대기</td><td>신청비율</td><td>비고</td>'
    '</tr>'
    '${rowsHtml.join()}'
    '</table></body></html>';

/// [rowsHtml]을 테이블 안에 넣고 EUC-KR 바이트로 인코딩한 전체 응답 본문을 만든다.
List<int> _fixtureBytes(List<String> rowsHtml) =>
    cp949.encode(_fixtureHtml(rowsHtml));

/// 위와 동일하지만 UTF-8 바이트로 인코딩한다 — 실기기에서 이 엔드포인트가
/// 명세(EUC-KR)와 달리 실제로는 UTF-8로 응답하는 사례가 확인되어, 디코딩
/// 폴백 동작을 검증하기 위한 픽스처.
List<int> _fixtureBytesUtf8(List<String> rowsHtml) =>
    utf8.encode(_fixtureHtml(rowsHtml));

void main() {
  group('CourseCatalogService.fetchCourseCatalog', () {
    test('정상 행을 CourseCatalogItem으로 파싱한다', () async {
      final bytes = _fixtureBytes([_row('tr_a0_chrm', _validCells())]);
      final mockClient = MockClient((request) async {
        return http.Response.bytes(bytes, 200);
      });
      final service = CourseCatalogService(client: mockClient);

      final result = await service.fetchCourseCatalog(
        year: 2026,
        semester: 2,
        jsessionId: 'JSESSION123',
        wmonid: 'WMONID123',
      );

      expect(result, hasLength(1));
      final item = result.single;
      expect(item.seq, 1);
      expect(item.courseCode, 'CSE301');
      expect(item.section, '01');
      expect(item.courseName, '자료구조');
      expect(item.courseType, '전공필수');
      expect(item.credit, 3.0);
      expect(item.targetGrade, '2');
      expect(item.professor, '홍길동');
      expect(item.rawSchedule, '월1,2 화3');
      expect(item.room, '공학관201');
      expect(item.isClosed, isFalse);
      expect(item.capacity, 40);
      expect(item.waitlistCount, 0);
      expect(item.enrollmentRatio, '30/40');
      expect(item.note, isNull);
    });

    test('응답이 명세(EUC-KR)와 달리 UTF-8이어도 자동으로 재시도해 정상 파싱한다', () async {
      final bytes = _fixtureBytesUtf8([_row('tr_a0_chrm', _validCells())]);
      final mockClient = MockClient((request) async {
        return http.Response.bytes(bytes, 200);
      });
      final service = CourseCatalogService(client: mockClient);

      final result = await service.fetchCourseCatalog(
        year: 2026,
        semester: 2,
        jsessionId: 'J',
        wmonid: 'W',
      );

      expect(result, hasLength(1));
      expect(result.single.courseCode, 'CSE301');
    });

    test('Content-Type 헤더에 charset=UTF-8이 명시되면 EUC-KR 추정보다 헤더를 우선한다', () async {
      final bytes = _fixtureBytesUtf8([_row('tr_a0_chrm', _validCells())]);
      final mockClient = MockClient((request) async {
        return http.Response.bytes(
          bytes,
          200,
          headers: {'content-type': 'text/html; charset=UTF-8'},
        );
      });
      final service = CourseCatalogService(client: mockClient);

      final result = await service.fetchCourseCatalog(
        year: 2026,
        semester: 2,
        jsessionId: 'J',
        wmonid: 'W',
      );

      expect(result, hasLength(1));
      expect(result.single.courseCode, 'CSE301');
    });

    test('tr_a 접두사가 붙은 여러 행(tr_a0_chrm, tr_a1_chrm)을 모두 인식한다', () async {
      final bytes = _fixtureBytes([
        _row('tr_a0_chrm', _validCells(seq: '1', codeAndSection: 'AAA-01')),
        _row('tr_a1_chrm', _validCells(seq: '2', codeAndSection: 'BBB-02')),
      ]);
      final mockClient = MockClient((request) async {
        return http.Response.bytes(bytes, 200);
      });
      final service = CourseCatalogService(client: mockClient);

      final result = await service.fetchCourseCatalog(
        year: 2026,
        semester: 2,
        jsessionId: 'J',
        wmonid: 'W',
      );

      expect(result, hasLength(2));
      expect(result[0].courseCode, 'AAA');
      expect(result[1].courseCode, 'BBB');
    });

    test('헤더행(tr_chrm_n)은 제외된다', () async {
      // _fixtureBytes가 항상 tr_chrm_n 헤더행을 포함시키므로, 데이터 행이
      // 없으면 결과가 비어 있어야 한다(헤더행이 섞여 들어오지 않음을 검증).
      final bytes = _fixtureBytes([]);
      final mockClient = MockClient((request) async {
        return http.Response.bytes(bytes, 200);
      });
      final service = CourseCatalogService(client: mockClient);

      final result = await service.fetchCourseCatalog(
        year: 2026,
        semester: 2,
        jsessionId: 'J',
        wmonid: 'W',
      );

      expect(result, isEmpty);
    });

    test('직계 자식 td가 14개 미만인 행은 폐기한다', () async {
      final shortRow =
          '<tr class="tr_a0_chrm">'
          '${List.generate(13, (i) => '<td>$i</td>').join()}'
          '</tr>';
      final bytes = _fixtureBytes([shortRow]);
      final mockClient = MockClient((request) async {
        return http.Response.bytes(bytes, 200);
      });
      final service = CourseCatalogService(client: mockClient);

      final result = await service.fetchCourseCatalog(
        year: 2026,
        semester: 2,
        jsessionId: 'J',
        wmonid: 'W',
      );

      expect(result, isEmpty);
    });

    test('과목코드-분반은 마지막 "-" 기준으로 split한다', () async {
      final bytes = _fixtureBytes([
        _row('tr_a0_chrm', _validCells(codeAndSection: 'CSE-301-01')),
      ]);
      final mockClient = MockClient((request) async {
        return http.Response.bytes(bytes, 200);
      });
      final service = CourseCatalogService(client: mockClient);

      final result = await service.fetchCourseCatalog(
        year: 2026,
        semester: 2,
        jsessionId: 'J',
        wmonid: 'W',
      );

      expect(result.single.courseCode, 'CSE-301');
      expect(result.single.section, '01');
    });

    test('폐강 셀이 비어있지 않으면 isClosed가 true다', () async {
      final bytes = _fixtureBytes([
        _row('tr_a0_chrm', _validCells(closed: '폐강')),
      ]);
      final mockClient = MockClient((request) async {
        return http.Response.bytes(bytes, 200);
      });
      final service = CourseCatalogService(client: mockClient);

      final result = await service.fetchCourseCatalog(
        year: 2026,
        semester: 2,
        jsessionId: 'J',
        wmonid: 'W',
      );

      expect(result.single.isClosed, isTrue);
    });

    test('비고가 비어있지 않으면 note에 값이 채워진다', () async {
      final bytes = _fixtureBytes([
        _row('tr_a0_chrm', _validCells(note: '공학인증')),
      ]);
      final mockClient = MockClient((request) async {
        return http.Response.bytes(bytes, 200);
      });
      final service = CourseCatalogService(client: mockClient);

      final result = await service.fetchCourseCatalog(
        year: 2026,
        semester: 2,
        jsessionId: 'J',
        wmonid: 'W',
      );

      expect(result.single.note, '공학인증');
    });

    test('쿠키/쿼리 파라미터가 명세대로 조립된다', () async {
      Uri? capturedUri;
      String? capturedCookie;
      final mockClient = MockClient((request) async {
        capturedUri = request.url;
        capturedCookie = request.headers['Cookie'];
        return http.Response.bytes(_fixtureBytes([]), 200);
      });
      final service = CourseCatalogService(client: mockClient);

      await service.fetchCourseCatalog(
        year: 2026,
        semester: 2,
        jsessionId: 'JSESSION123',
        wmonid: 'WMONID123',
        icKwa: 'B41005',
        icKwa1: 'B41005',
        userId: 'guest',
      );

      expect(capturedUri, isNotNull);
      expect(
        capturedUri!.toString(),
        startsWith(
          'https://dreams2.daejin.ac.kr/sugang/center/ProLsnAply06.jsp',
        ),
      );
      expect(capturedUri!.queryParameters['fhd_yyyy'], '2026');
      expect(capturedUri!.queryParameters['fhd_shtm'], '2');
      expect(capturedUri!.queryParameters['ic_kwa'], 'B41005');
      expect(capturedUri!.queryParameters['ic_kwa_1'], 'B41005');

      expect(capturedCookie, contains('JSESSIONID=JSESSION123'));
      expect(capturedCookie, contains('user_id=guest'));
      expect(capturedCookie, contains('userId=guest'));
      expect(capturedCookie, contains('WMONID=WMONID123'));
      expect(capturedCookie, contains('nm=8p13%2B7QRPNTh19POT6%2FJPw%3D%3D'));
    });

    test('icKwa가 "%"가 아닌데 icKwa1이 없으면 ArgumentError를 던진다', () async {
      final mockClient = MockClient((request) async {
        return http.Response.bytes(_fixtureBytes([]), 200);
      });
      final service = CourseCatalogService(client: mockClient);

      expect(
        () => service.fetchCourseCatalog(
          year: 2026,
          semester: 2,
          jsessionId: 'J',
          wmonid: 'W',
          icKwa: 'B41005',
        ),
        throwsArgumentError,
      );
    });

    test('서버가 200이 아닌 상태 코드를 반환하면 CourseCatalogServerException을 던진다', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });
      final service = CourseCatalogService(client: mockClient);

      expect(
        () => service.fetchCourseCatalog(
          year: 2026,
          semester: 2,
          jsessionId: 'J',
          wmonid: 'W',
        ),
        throwsA(isA<CourseCatalogServerException>()),
      );
    });

    test('네트워크 예외가 발생하면 CourseCatalogNetworkException을 던진다', () async {
      final mockClient = MockClient((request) async {
        throw const SocketExceptionStub();
      });
      final service = CourseCatalogService(client: mockClient);

      expect(
        () => service.fetchCourseCatalog(
          year: 2026,
          semester: 2,
          jsessionId: 'J',
          wmonid: 'W',
        ),
        throwsA(isA<CourseCatalogNetworkException>()),
      );
    });

    test('숫자 칼럼이 깨진 행은 건너뛰고, 나머지 정상 행은 그대로 반환한다', () async {
      // 실기기 테스트에서 숫자 칼럼이 기대와 다른 행이 섞여 들어오는 사례가
      // 확인됨 — 행 하나가 깨졌다고 검색 결과 전체가 날아가면 안 된다.
      final bytes = _fixtureBytes([
        _row('tr_a0_chrm', _validCells(seq: '일련번호아님')),
        _row('tr_a1_chrm', _validCells(seq: '2', codeAndSection: 'MAT201-02')),
      ]);
      final mockClient = MockClient((request) async {
        return http.Response.bytes(bytes, 200);
      });
      final service = CourseCatalogService(client: mockClient);

      final result = await service.fetchCourseCatalog(
        year: 2026,
        semester: 2,
        jsessionId: 'J',
        wmonid: 'W',
      );

      expect(result, hasLength(1));
      expect(result.single.courseCode, 'MAT201');
    });
  });
}

/// MockClient 핸들러에서 네트워크 예외를 흉내내기 위한 간단한 Exception.
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}
