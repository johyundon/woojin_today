// 앱을 켤 때 자동 로그인이 비밀번호 오류·계정 없음으로 실패하면, 저장된
// 학번·비밀번호를 지우고 로그인 화면에서 이유를 알려주는지 확인한다. 지우지
// 않으면 앱을 켤 때마다 틀린 비밀번호가 학교에 쌓여 계정이 잠길 수 있다.
// 네트워크 오류는 비밀번호와 상관없으므로 지우지 않는다.

import 'package:daejin_app/screens/login_screen.dart';
import 'package:daejin_app/screens/splash_screen.dart';
import 'package:daejin_app/services/credential_storage.dart';
import 'package:daejin_app/services/portal_login_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStorage extends CredentialStorage {
  _FakeStorage(this.saved);

  ({String userId, String userPwd})? saved;
  var clearCount = 0;

  @override
  Future<({String userId, String userPwd})?> read() async => saved;

  @override
  Future<void> clear() async {
    clearCount++;
    saved = null;
  }
}

class _FakeLogin implements PortalLoginServiceBase {
  _FakeLogin(this.respond);

  final Future<PortalLoginResult> Function() respond;
  var calls = 0;

  @override
  Future<PortalLoginResult> login({
    required String userId,
    required String userPwd,
  }) {
    calls++;
    return respond();
  }
}

Future<void> _pumpSplash(
  WidgetTester tester,
  _FakeStorage storage,
  _FakeLogin login,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: SplashScreen(portalLoginService: login, credentialStorage: storage),
    ),
  );
  // 스플래시는 최소 2초 보인다.
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('비밀번호 오류면 저장된 계정을 지우고 학번을 채운 채 이유를 알린다', (tester) async {
    final storage = _FakeStorage((userId: '20261234', userPwd: 'old'));
    final login = _FakeLogin(
      () async => const PortalLoginResult(
        success: false,
        failReason: '비밀번호오류',
        remainingAttempts: 3,
      ),
    );
    await _pumpSplash(tester, storage, login);

    expect(login.calls, 1);
    expect(storage.clearCount, 1);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('20261234'), findsOneWidget);
    expect(find.textContaining('저장된 비밀번호로 로그인하지 못했어요'), findsOneWidget);
    expect(find.textContaining('3회 더 틀리면'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('계정 없음이면 저장된 계정을 지우고 이유를 알린다', (tester) async {
    final storage = _FakeStorage((userId: '20261234', userPwd: 'pw'));
    final login = _FakeLogin(
      () async => const PortalLoginResult(success: false, failReason: '계정없음'),
    );
    await _pumpSplash(tester, storage, login);

    expect(storage.clearCount, 1);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.textContaining('저장된 학번으로 로그인하지 못했어요'), findsOneWidget);
  });

  testWidgets('네트워크 오류면 저장된 계정을 지우지 않는다', (tester) async {
    final storage = _FakeStorage((userId: '20261234', userPwd: 'pw'));
    final login = _FakeLogin(
      () async => throw const PortalLoginException('네트워크 오류'),
    );
    await _pumpSplash(tester, storage, login);

    expect(storage.clearCount, 0);
    expect(storage.saved, isNotNull);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.textContaining('로그인하지 못했어요'), findsNothing);
  });

  testWidgets('저장된 계정이 없으면 로그인을 시도하지 않는다', (tester) async {
    final storage = _FakeStorage(null);
    final login = _FakeLogin(
      () async => const PortalLoginResult(success: true),
    );
    await _pumpSplash(tester, storage, login);

    expect(login.calls, 0);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
