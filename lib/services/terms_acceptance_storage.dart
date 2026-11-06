import 'package:shared_preferences/shared_preferences.dart';

/// 학번별로 이용약관 동의와 온보딩 완료 여부를 기기에 저장한다.
///
/// 약관·온보딩은 로그인 "이후" 그 학생이 처음 한 번만 보면 되는 화면이다.
/// 같은 기기로 다른 학생이 로그인하면 그 학생은 따로 봐야 하므로 학번별로
/// 기억한다. 로그아웃해도 이 기록은 남긴다([isKeptOnLogout]).
///
/// 약관은 동의한 "버전"을 저장한다. 약관 내용이 바뀌면 [currentTermsVersion]을
/// 올리면 되고, 그러면 이전 버전에 동의한 사람도 약관 화면을 한 번 더 본다
/// (온보딩은 다시 나오지 않는다).
class TermsAcceptanceStorage {
  TermsAcceptanceStorage({SharedPreferencesAsync? prefs})
    : _prefs = prefs ?? SharedPreferencesAsync();

  /// 지금 앱에 들어 있는 약관의 버전. 약관 내용을 바꾸면 1 올린다.
  static const currentTermsVersion = 1;

  static const _termsVersionPrefix = 'daejin_terms_version_';
  static const _onboardingDonePrefix = 'daejin_onboarding_done_';

  /// 로그아웃 정리에서 지우지 않고 남길 키인지.
  static bool isKeptOnLogout(String key) =>
      key.startsWith(_termsVersionPrefix) ||
      key.startsWith(_onboardingDonePrefix);

  final SharedPreferencesAsync _prefs;

  Future<bool> hasAccepted(String userId) async {
    final version = await _prefs.getInt('$_termsVersionPrefix$userId');
    return version != null && version >= currentTermsVersion;
  }

  Future<void> markAccepted(String userId) async {
    await _prefs.setInt('$_termsVersionPrefix$userId', currentTermsVersion);
  }

  Future<bool> hasCompletedOnboarding(String userId) async {
    return await _prefs.getBool('$_onboardingDonePrefix$userId') ?? false;
  }

  Future<void> markOnboardingCompleted(String userId) async {
    await _prefs.setBool('$_onboardingDonePrefix$userId', true);
  }
}
