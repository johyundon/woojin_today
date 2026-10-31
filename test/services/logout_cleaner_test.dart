// 로그아웃 정리(clearUserDataOnLogout)가 자동 로그인 정보, 기기 저장소(두 저장
// 방식 모두), 예약 알림을 모두 지우는지 확인한다.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:daejin_app/services/credential_storage.dart';
import 'package:daejin_app/services/logout_cleaner.dart';

void main() {
  test('자격증명·기기 저장소·예약 알림을 전부 지운다', () async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final credentials = CredentialStorage();
    final prefs = SharedPreferencesAsync();
    await credentials.save(userId: '20211476', userPwd: 'pw');
    await prefs.setString('daejin_saved_timetables', '[]');
    await prefs.setString('daejin_calendar_events', '[]');
    await prefs.setStringList('daejin_read_notices', ['a']);
    await prefs.setBool('daejin_terms_accepted', true);
    var notificationsCancelled = false;

    await clearUserDataOnLogout(
      credentialStorage: credentials,
      prefs: prefs,
      cancelNotifications: () async => notificationsCancelled = true,
    );

    expect(await credentials.read(), isNull);
    expect(await prefs.getKeys(), isEmpty);
    expect(notificationsCancelled, isTrue);
  });

  test('한 단계가 실패해도 나머지는 계속 지운다', () async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final prefs = SharedPreferencesAsync();
    await prefs.setBool('daejin_terms_accepted', true);

    await clearUserDataOnLogout(
      prefs: prefs,
      cancelNotifications: () async => throw Exception('알림 취소 실패'),
    );

    expect(await prefs.getKeys(), isEmpty);
  });

  test('예전 방식으로 저장한 캐시(등수·공지·학사일정)도 지워 다시 읽히지 않는다', () async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    SharedPreferences.setMockInitialValues({});
    final legacy = await SharedPreferences.getInstance();
    await legacy.setString('twin_rank_20211476_AA0194_3', '{"myGpa":4.34}');
    await legacy.setString('notice_list_academic', '{}');
    await legacy.setString('academic_schedule_2026_10', '{}');

    await clearUserDataOnLogout(
      prefs: SharedPreferencesAsync(),
      cancelNotifications: () async {},
    );

    // 앱을 끄지 않고 다시 읽어도(같은 메모리 캐시) 남아 있지 않다.
    final after = await SharedPreferences.getInstance();
    expect(after.getKeys(), isEmpty);
    expect(after.getString('twin_rank_20211476_AA0194_3'), isNull);
  });
}
