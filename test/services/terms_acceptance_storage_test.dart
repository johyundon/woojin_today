// 약관 동의·온보딩 완료가 학번별로 저장되고, 약관 버전이 오르면 다시 받는지
// 확인한다.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:daejin_app/services/terms_acceptance_storage.dart';

void main() {
  late SharedPreferencesAsync prefs;
  late TermsAcceptanceStorage storage;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    prefs = SharedPreferencesAsync();
    storage = TermsAcceptanceStorage(prefs: prefs);
  });

  test('처음에는 동의·온보딩 기록이 없다', () async {
    expect(await storage.hasAccepted('20211476'), isFalse);
    expect(await storage.hasCompletedOnboarding('20211476'), isFalse);
  });

  test('학번별로 따로 기억한다', () async {
    await storage.markAccepted('20211476');
    await storage.markOnboardingCompleted('20211476');

    expect(await storage.hasAccepted('20211476'), isTrue);
    expect(await storage.hasCompletedOnboarding('20211476'), isTrue);
    expect(await storage.hasAccepted('20220001'), isFalse);
    expect(await storage.hasCompletedOnboarding('20220001'), isFalse);
  });

  test('예전 버전 약관에 동의했으면 다시 받는다', () async {
    await prefs.setInt(
      'daejin_terms_version_20211476',
      TermsAcceptanceStorage.currentTermsVersion - 1,
    );

    expect(await storage.hasAccepted('20211476'), isFalse);
  });

  test('로그아웃 때 남길 키는 약관·온보딩 기록뿐이다', () {
    expect(
      TermsAcceptanceStorage.isKeptOnLogout('daejin_terms_version_20211476'),
      isTrue,
    );
    expect(
      TermsAcceptanceStorage.isKeptOnLogout('daejin_onboarding_done_20211476'),
      isTrue,
    );
    expect(
      TermsAcceptanceStorage.isKeptOnLogout('daejin_saved_timetables'),
      isFalse,
    );
    expect(
      TermsAcceptanceStorage.isKeptOnLogout('daejin_terms_accepted'),
      isFalse,
    );
  });
}
