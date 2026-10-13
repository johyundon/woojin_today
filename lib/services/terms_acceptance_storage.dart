import 'package:shared_preferences/shared_preferences.dart';

/// 이용약관/개인정보 처리방침 동의 여부를 기기에 저장한다.
///
/// v4 리디자인부터 약관 동의 화면이 로그인 "이후"로 옮겨졌고, 최초 로그인
/// 성공 시 한 번만 보여주면 되므로 이 플래그로 재노출 여부를 가른다.
class TermsAcceptanceStorage {
  TermsAcceptanceStorage({SharedPreferencesAsync? prefs})
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const _key = 'daejin_terms_accepted';

  final SharedPreferencesAsync _prefs;

  Future<bool> hasAccepted() async {
    return await _prefs.getBool(_key) ?? false;
  }

  Future<void> markAccepted() async {
    await _prefs.setBool(_key, true);
  }
}
