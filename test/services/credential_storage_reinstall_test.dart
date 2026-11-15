// iOS는 앱을 지워도 키체인(학번·비밀번호)이 남는다. 다시 깐 첫 실행에서 이를
// 지우는지, 업데이트만 한 사람·로그아웃 후 다시 로그인한 사람의 저장값은
// 지우지 않는지 확인한다.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:daejin_app/services/credential_storage.dart';
import 'package:daejin_app/services/logout_cleaner.dart';
import 'package:daejin_app/services/terms_acceptance_storage.dart';

void main() {
  late SharedPreferencesAsync prefs;
  late CredentialStorage storage;

  setUp(() {
    // 키체인에는 예전 설치본이 남긴 학번·비밀번호가 있다.
    FlutterSecureStorage.setMockInitialValues({
      'daejin_user_id': '20211476',
      'daejin_user_pwd': 'old',
    });
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    prefs = SharedPreferencesAsync();
    storage = CredentialStorage(prefs: prefs);
  });

  test('기기 저장소가 비어 있으면(다시 깐 첫 실행) 남은 학번·비밀번호를 지운다', () async {
    await storage.clearIfReinstalled();
    expect(await storage.read(), isNull);
  });

  test('표시가 생긴 뒤에는 다시 켜도 지우지 않는다', () async {
    await storage.clearIfReinstalled();
    await storage.save(userId: '20211476', userPwd: 'new');

    await storage.clearIfReinstalled();
    expect(await storage.read(), isNotNull);
  });

  test('이 표시가 없던 버전에서 업데이트한 사람(약관 동의 기록 있음)은 지우지 않는다', () async {
    await TermsAcceptanceStorage(prefs: prefs).markAccepted('20211476');

    await storage.clearIfReinstalled();
    expect(await storage.read(), isNotNull);
  });

  test('로그아웃해도 표시는 남아서, 다시 로그인한 계정이 다음 실행 때 지워지지 않는다', () async {
    await storage.clearIfReinstalled();
    await clearUserDataOnLogout(
      credentialStorage: storage,
      prefs: prefs,
      cancelNotifications: () async {},
      cancelNoticeBackground: () async {},
    );
    await storage.save(userId: '20211476', userPwd: 'again');

    await storage.clearIfReinstalled();
    expect(await storage.read(), isNotNull);
  });
}
