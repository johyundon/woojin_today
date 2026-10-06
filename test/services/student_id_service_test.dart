// 학번 찾기 API 응답 파싱 로직을 고정된 HTML 픽스처로 검증한다.
// 실제 대진대 서버 호출(네트워크)은 하지 않고 http.testing.MockClient로 대체한다.

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/services/student_id_service.dart';

void main() {
  group('StudentIdService.findStudentId', () {
    test('응답 HTML에 학번이 있으면 StudentIdFound를 반환한다', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '<html><body>조회된 학번은 <strong>20211476</strong> 입니다.</body></html>',
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      });
      final service = StudentIdService(client: mockClient);

      final result = await service.findStudentId(
        name: '홍길동',
        birthday6: '060101',
        mobile1: '010',
        mobile2: '1234',
        mobile3: '5678',
      );

      expect(result, isA<StudentIdFound>());
      expect((result as StudentIdFound).studentNo, '20211476');
    });

    test('응답 HTML에 학번 패턴이 없으면 StudentIdNotFound를 반환한다', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '<html><body>일치하는 회원정보가 없습니다.</body></html>',
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      });
      final service = StudentIdService(client: mockClient);

      final result = await service.findStudentId(
        name: '홍길동',
        birthday6: '060101',
        mobile1: '010',
        mobile2: '1234',
        mobile3: '5678',
      );

      expect(result, isA<StudentIdNotFound>());
    });

    test('서버가 200이 아닌 상태 코드를 반환하면 StudentIdSearchError를 반환한다', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });
      final service = StudentIdService(client: mockClient);

      final result = await service.findStudentId(
        name: '홍길동',
        birthday6: '060101',
        mobile1: '010',
        mobile2: '1234',
        mobile3: '5678',
      );

      expect(result, isA<StudentIdSearchError>());
    });

    test('네트워크 예외가 발생하면 StudentIdSearchError를 반환한다', () async {
      final mockClient = MockClient((request) async {
        throw const SocketExceptionStub();
      });
      final service = StudentIdService(client: mockClient);

      final result = await service.findStudentId(
        name: '홍길동',
        birthday6: '060101',
        mobile1: '010',
        mobile2: '1234',
        mobile3: '5678',
      );

      expect(result, isA<StudentIdSearchError>());
    });

    test('요청 바디는 srchNm만 인코딩하고 나머지는 raw로 조립한다', () async {
      String? capturedBody;
      final mockClient = MockClient((request) async {
        capturedBody = request.body;
        return http.Response(
          '조회된 학번은 <strong>12345678</strong>',
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      });
      final service = StudentIdService(client: mockClient);

      await service.findStudentId(
        name: '홍 길동', // 공백 포함 → 인코딩되어야 함
        birthday6: '060101',
        mobile1: '010',
        mobile2: '1234',
        mobile3: '5678',
      );

      expect(
        capturedBody,
        'findType=2&srchGubun=1&srchNm=${Uri.encodeQueryComponent('홍 길동')}'
        '&srchBirthday=060101&srchMobile1=010&srchMobile2=1234&srchMobile3=5678',
      );
    });
  });
}

/// MockClient 핸들러에서 네트워크 예외를 흉내내기 위한 간단한 Exception.
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}
