import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 로그인 자격증명(학번/비밀번호)을 기기 암호화 저장소(iOS 키체인 / Android
/// 키스토어)에 저장한다.
///
/// 서버 쿠키(WMONID/JSESSIONID/userId2)는 유효기간이 있어 여기 저장하지
/// 않는다 — 대신 저장된 자격증명으로 앱 시작 시 [PortalLoginService.login]을
/// 다시 호출해 "조용히 재로그인"하는 방식을 쓴다.
class CredentialStorage {
  CredentialStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _userIdKey = 'daejin_user_id';
  static const _userPwdKey = 'daejin_user_pwd';

  Future<void> save({required String userId, required String userPwd}) async {
    await _storage.write(key: _userIdKey, value: userId);
    await _storage.write(key: _userPwdKey, value: userPwd);
    // TODO(debug): 저장이 실제로 성공하는지 확인하기 위한 임시 로그 — 비밀번호
    // 값 자체는 찍지 않는다. 확인 끝나면 제거.
    final saved = await read();
    print(
      '[CredentialStorage] save 완료. 저장 확인: '
      '${saved != null && saved.userId == userId ? "성공" : "실패"}',
    );
  }

  /// 저장된 자격증명이 하나라도 없으면 null을 반환한다.
  Future<({String userId, String userPwd})?> read() async {
    final userId = await _storage.read(key: _userIdKey);
    final userPwd = await _storage.read(key: _userPwdKey);
    if (userId == null || userPwd == null) return null;
    return (userId: userId, userPwd: userPwd);
  }
}
