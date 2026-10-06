// 포털 로그인(1단계 login.do + 2단계 LinkPortal.jsp 폴백) 로직을 고정된
// 응답 픽스처로 검증한다. 실제 대진대 서버 호출(네트워크)은 하지 않고
// http.testing.MockClient로 리다이렉트 체인을 흉내낸다.

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:daejin_app/services/portal_login_service.dart';

void main() {
  group('PortalLoginService.login', () {
    test('1단계 응답에서 uid를 바로 찾으면 2단계 없이 로그인에 성공한다', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString() ==
            'https://www.daejin.ac.kr/subLogin/daejin/login.do') {
          return http.Response(
            '',
            302,
            headers: {
              'location': 'https://www.daejin.ac.kr/success1.jsp?uid%3Dstu001%26next%3D1',
              'set-cookie':
                  'WMONID=wmo001; Path=/, JSESSIONID=js001; '
                  'Path=/; HttpOnly',
            },
          );
        }
        if (request.url.toString() ==
            'https://www.daejin.ac.kr/success1.jsp?uid%3Dstu001%26next%3D1') {
          return http.Response(
            '<html>메인</html>',
            200,
            headers: {'content-type': 'text/html; charset=utf-8'},
          );
        }
        throw StateError('예상치 못한 요청: ${request.url}');
      });
      final service = PortalLoginService(clientFactory: () => mockClient);

      final result = await service.login(userId: '20211476', userPwd: 'pw');

      expect(result.success, isTrue);
      expect(result.failReason, isNull);
      expect(result.wmonid, 'wmo001');
      expect(result.jsessionId, 'js001');
      expect(result.userId2, 'stu001');
    });

    test('1단계에서 uid를 못 찾으면 2단계 폴백으로 uid를 찾는다', () async {
      final mockClient = MockClient((request) async {
        switch (request.url.toString()) {
          case 'https://www.daejin.ac.kr/subLogin/daejin/login.do':
            return http.Response(
              '',
              302,
              headers: {
                'location': 'https://www.daejin.ac.kr/success2.jsp',
                'set-cookie':
                    'WMONID=wmo002; Path=/, JSESSIONID=js002; '
                    'Path=/',
              },
            );
          case 'https://www.daejin.ac.kr/success2.jsp':
            return http.Response(
              '<html>메인</html>',
              200,
              headers: {'content-type': 'text/html; charset=utf-8'},
            );
          case 'https://dreams2.daejin.ac.kr/sugang/LinkPortal.jsp?dvd=P':
            return http.Response(
              '',
              302,
              headers: {
                'location': 'https://dreams2.daejin.ac.kr/sugang/next.jsp',
                'set-cookie': 'userId=stu002; Path=/',
              },
            );
          case 'https://dreams2.daejin.ac.kr/sugang/next.jsp':
            return http.Response('ok', 200);
        }
        throw StateError('예상치 못한 요청: ${request.url}');
      });
      final service = PortalLoginService(clientFactory: () => mockClient);

      final result = await service.login(userId: '20211476', userPwd: 'pw');

      expect(result.success, isTrue);
      expect(result.wmonid, 'wmo002');
      expect(result.jsessionId, 'js002');
      expect(result.userId2, 'stu002');
    });

    test('2단계 폴백 중 dreams2가 1단계와 다른 JSESSIONID/WMONID를 새로 내려주면 '
        '최종 결과는 1단계 값이 아니라 그 최신 값을 쓴다', () async {
      // 실기기에서 재현된 상황: 2단계(LinkPortal.jsp)가
      // nsso.daejin.ac.kr을 거치는 리다이렉트 체인에서 dreams2.daejin.ac.kr
      // 자체 세션 쿠키를 새로 내려준다. 1단계 값을 그대로 쓰면 이후
      // dreams2 계열 API 호출이 전부 인증 안 된 요청으로 취급된다.
      final mockClient = MockClient((request) async {
        switch (request.url.toString()) {
          case 'https://www.daejin.ac.kr/subLogin/daejin/login.do':
            return http.Response(
              '',
              302,
              headers: {
                'location': 'https://www.daejin.ac.kr/success2.jsp',
                'set-cookie':
                    'WMONID=wmo_old; Path=/, JSESSIONID=js_old; Path=/',
              },
            );
          case 'https://www.daejin.ac.kr/success2.jsp':
            return http.Response(
              '<html>메인</html>',
              200,
              headers: {'content-type': 'text/html; charset=utf-8'},
            );
          case 'https://dreams2.daejin.ac.kr/sugang/LinkPortal.jsp?dvd=P':
            return http.Response(
              '',
              302,
              headers: {
                'location': 'https://dreams2.daejin.ac.kr/sugang/next.jsp',
                // dreams2 자체 세션 쿠키가 새로 내려옴(1단계와 다른 값).
                'set-cookie':
                    'JSESSIONID=js_new_dreams2; Path=/, '
                    'WMONID=wmo_new_dreams2; Path=/, '
                    'userId=stu002; Path=/',
              },
            );
          case 'https://dreams2.daejin.ac.kr/sugang/next.jsp':
            return http.Response('ok', 200);
        }
        throw StateError('예상치 못한 요청: ${request.url}');
      });
      final service = PortalLoginService(clientFactory: () => mockClient);

      final result = await service.login(userId: '20211476', userPwd: 'pw');

      expect(result.success, isTrue);
      expect(result.jsessionId, 'js_new_dreams2');
      expect(result.wmonid, 'wmo_new_dreams2');
      expect(result.userId2, 'stu002');
    });

    test('HTTP 3xx가 아니라 <meta refresh>로 지시하는 클라이언트 사이드 리다이렉트도 따라간다', () async {
      // 실기기에서 재현된 상황: 2단계 폴백의 마지막 홉이 HTTP 302가 아니라
      // 200으로 응답하면서 본문에 <meta http-equiv="refresh"
      // content="0;url=gopage.jsp">를 담아 보낸다. 이걸 안 따라가면 그
      // 직전 페이지의 쿠키로 체인이 끝난 걸로 착각해, 실제 dreams2 세션
      // 쿠키(gopage.jsp 응답에서 내려옴)를 놓치게 된다.
      final mockClient = MockClient((request) async {
        switch (request.url.toString()) {
          case 'https://www.daejin.ac.kr/subLogin/daejin/login.do':
            return http.Response(
              '',
              302,
              headers: {
                'location': 'https://www.daejin.ac.kr/success2.jsp',
                'set-cookie':
                    'WMONID=wmo_old; Path=/, JSESSIONID=js_old; Path=/',
              },
            );
          case 'https://www.daejin.ac.kr/success2.jsp':
            return http.Response(
              '<html>메인</html>',
              200,
              headers: {'content-type': 'text/html; charset=utf-8'},
            );
          case 'https://dreams2.daejin.ac.kr/sugang/LinkPortal.jsp?dvd=P':
            // HTTP 302가 아니라 200 + 메타 리다이렉트.
            return http.Response(
              '<!doctype html><html><head>'
              '<meta http-equiv="refresh" content="0;url=gopage.jsp">'
              '</head><body>대진대학교</body></html>',
              200,
              headers: {
                'content-type': 'text/html; charset=utf-8',
                'set-cookie': 'userId=stu002; Path=/',
              },
            );
          case 'https://dreams2.daejin.ac.kr/sugang/gopage.jsp':
            // 메타 리다이렉트를 실제로 따라가야만 도달하는, 진짜 세션 쿠키.
            return http.Response(
              'ok',
              200,
              headers: {
                'set-cookie':
                    'JSESSIONID=js_real_session; Path=/, '
                    'WMONID=wmo_real_session; Path=/',
              },
            );
        }
        throw StateError('예상치 못한 요청: ${request.url}');
      });
      final service = PortalLoginService(clientFactory: () => mockClient);

      final result = await service.login(userId: '20211476', userPwd: 'pw');

      expect(result.success, isTrue);
      expect(result.jsessionId, 'js_real_session');
      expect(result.wmonid, 'wmo_real_session');
      expect(result.userId2, 'stu002');
    });

    test('계정이 존재하지 않으면 failReason이 "계정없음"이다', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '회원정보이(가) 존재 하지 않습니다.',
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      });
      final service = PortalLoginService(clientFactory: () => mockClient);

      final result = await service.login(userId: '00000000', userPwd: 'pw');

      expect(result.success, isFalse);
      expect(result.failReason, '계정없음');
      expect(result.remainingAttempts, isNull);
    });

    test('비밀번호가 틀리면 failReason "비밀번호오류"와 잔여 횟수를 반환한다', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '입력하신 계정정보가 올바르지 않습니다. 5회 더 잘못입력하시면 계정이 잠깁니다.',
          200,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      });
      final service = PortalLoginService(clientFactory: () => mockClient);

      final result = await service.login(userId: '20211476', userPwd: 'wrong');

      expect(result.success, isFalse);
      expect(result.failReason, '비밀번호오류');
      expect(result.remainingAttempts, 5);
    });

    test('네트워크 예외가 발생하면 PortalLoginException을 던진다', () async {
      final mockClient = MockClient((request) async {
        throw const SocketExceptionStub();
      });
      final service = PortalLoginService(clientFactory: () => mockClient);

      expect(
        () => service.login(userId: '20211476', userPwd: 'pw'),
        throwsA(isA<PortalLoginException>()),
      );
    });
  });
}

/// MockClient 핸들러에서 네트워크 예외를 흉내내기 위한 간단한 Exception.
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}
