import 'dart:async';

import '../portal_login_service.dart';

/// 실제 포털 로그인 API(`login.do`)를 호출하지 않고 항상 로그인 성공으로
/// 처리하는 가짜 서비스. `kUseMockApi`가 true인 동안만 쓰인다.
class FakePortalLoginService extends PortalLoginService {
  @override
  Future<PortalLoginResult> login({
    required String userId,
    required String userPwd,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const PortalLoginResult(
      success: true,
      wmonid: 'MOCK_WMONID',
      jsessionId: 'MOCK_JSESSIONID',
      userId2: 'MOCK_USERID2',
    );
  }
}
