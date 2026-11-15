import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'terms_acceptance_storage.dart';

/// 로그인 자격증명(학번/비밀번호)을 기기 암호화 저장소(iOS 키체인 / Android
/// 키스토어)에 저장한다.
///
/// 서버 쿠키(WMONID/JSESSIONID/userId2)는 유효기간이 있어 여기 저장하지
/// 않는다 — 대신 저장된 자격증명으로 앱 시작 시 [PortalLoginService.login]을
/// 다시 호출해 "조용히 재로그인"하는 방식을 쓴다.
class CredentialStorage {
  CredentialStorage({
    FlutterSecureStorage? storage,
    SharedPreferencesAsync? prefs,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _prefsArg = prefs;

  final FlutterSecureStorage _storage;
  final SharedPreferencesAsync? _prefsArg;

  static const _userIdKey = 'daejin_user_id';
  static const _userPwdKey = 'daejin_user_pwd';

  /// 이 설치본에서 앱을 한 번 이상 켰다는 표시(기기 저장소에 둔다).
  static const _installedKey = 'daejin_app_installed';

  /// 로그아웃 정리에서 지우지 않고 남길 키인지. 이 표시가 지워지면 다음에
  /// 앱을 켤 때 새로 깐 것으로 보고 방금 저장한 학번·비밀번호를 지워 버린다.
  static bool isKeptOnLogout(String key) => key == _installedKey;

  /// 앱을 지웠다 다시 깔았으면 남아 있던 학번·비밀번호를 지운다.
  ///
  /// iOS 키체인은 앱을 지워도 남아서, 다시 깔면 예전 계정으로 자동 로그인된다.
  /// 기기 저장소(SharedPreferences)는 앱을 지우면 함께 지워지므로, 거기에
  /// [_installedKey]가 없으면 새로 깐 것으로 본다. 다만 이 표시가 생기기 전
  /// 버전을 쓰던 사람은 표시가 없어도 약관 동의 기록이 남아 있으므로, 그때는
  /// 지우지 않고 표시만 남긴다(업데이트만 했는데 로그아웃되지 않게).
  /// 실패해도 앱 시작을 막지 않는다.
  Future<void> clearIfReinstalled() async {
    try {
      final prefs = _prefsArg ?? SharedPreferencesAsync();
      final keys = await prefs.getKeys();
      if (keys.contains(_installedKey)) return;
      final usedBefore = keys.any(TermsAcceptanceStorage.isKeptOnLogout);
      if (!usedBefore) await clear();
      await prefs.setBool(_installedKey, true);
    } catch (e) {
      debugPrint('[CredentialStorage] 재설치 확인 실패: $e');
    }
  }

  Future<void> save({required String userId, required String userPwd}) async {
    await _storage.write(key: _userIdKey, value: userId);
    await _storage.write(key: _userPwdKey, value: userPwd);
  }

  /// 로그아웃 시 저장된 학번·비밀번호를 지운다.
  Future<void> clear() async {
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _userPwdKey);
  }

  /// 저장된 자격증명이 하나라도 없으면 null을 반환한다.
  Future<({String userId, String userPwd})?> read() async {
    final userId = await _storage.read(key: _userIdKey);
    final userPwd = await _storage.read(key: _userPwdKey);
    if (userId == null || userPwd == null) return null;
    return (userId: userId, userPwd: userPwd);
  }
}
