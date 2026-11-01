import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 시간표 화면 "강의시간 알림" 토글의 켜짐 여부를 기기에 저장한다.
///
/// 기본은 꺼짐이다(켤 때 알림 권한을 묻기 때문). 로그아웃하면
/// `logout_cleaner`가 기기 저장소와 예약 알림을 통째로 지운다.
class ClassReminderSettings {
  ClassReminderSettings({SharedPreferencesAsync? prefs}) : _prefsArg = prefs;

  static const _enabledKey = 'class_reminder_enabled';

  final SharedPreferencesAsync? _prefsArg;

  /// 처음 쓸 때 만든다. 저장소가 없는 환경(위젯 테스트 등)에서는 만들 때 예외가
  /// 나는데, 쓰는 곳이 모두 try 안이라 조용히 넘어간다.
  late final SharedPreferencesAsync _prefs =
      _prefsArg ?? SharedPreferencesAsync();

  Future<bool> isEnabled() async {
    try {
      return await _prefs.getBool(_enabledKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    try {
      await _prefs.setBool(_enabledKey, enabled);
    } catch (e) {
      debugPrint('[ClassReminder] 알림 설정 저장 실패: $e');
    }
  }
}
