import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'credential_storage.dart';
import 'notification_service.dart';
import 'session_cache.dart';

/// 로그아웃할 때 기기에 남은 이 사용자의 데이터를 전부 지운다.
///
/// 같은 기기로 다른 학생이 로그인할 수 있으므로 다음을 모두 비운다.
/// - 자동 로그인용 학번·비밀번호(키체인)
/// - 학생정보·시간표·개설과목 임시 기억([SessionCache])
/// - 기기 저장소 전체(저장한 시간표, 캘린더 일정, 공지 읽음, 약관 동의)
/// - 예전 방식 저장소의 캐시(학과 등수 평점, 공지 목록, 학식, 학사일정)
/// - 예약된 알림 전체(캘린더 일정, 강의시간)
///
/// 기기 저장소는 키를 하나씩 지우지 않고 통째로 비운다 — 지금 저장하는 값이
/// 전부 사용자 데이터라서다. 사용자와 무관한 기기 설정을 저장하게 되면 이
/// 부분을 다시 봐야 한다.
///
/// 저장 방식이 두 가지라 둘 다 지운다. 캐시들은 예전 방식([SharedPreferences])으로
/// 저장하는데, Android에서는 새 방식([SharedPreferencesAsync])과 저장 파일이 달라
/// 새 방식만 지우면 캐시가 남고, iOS에서도 예전 방식은 앱이 켜져 있는 동안 값을
/// 메모리에 들고 있어서 직접 비워야 한다(2026-10-31 라이브러리 소스로 확인).
///
/// 한 단계가 실패해도 나머지는 계속 지우고, 로그아웃 자체는 막지 않는다.
Future<void> clearUserDataOnLogout({
  CredentialStorage? credentialStorage,
  SharedPreferencesAsync? prefs,
  Future<void> Function()? cancelNotifications,
}) async {
  SessionCache.clear();
  await _run('자격증명', (credentialStorage ?? CredentialStorage()).clear);
  await _run('캐시 저장소', () async {
    await (await SharedPreferences.getInstance()).clear();
  });
  await _run('기기 저장소', (prefs ?? SharedPreferencesAsync()).clear);
  await _run(
    '예약 알림',
    cancelNotifications ?? NotificationService.instance.cancelAll,
  );
}

Future<void> _run(String what, Future<void> Function() step) async {
  try {
    await step();
  } catch (e) {
    debugPrint('[Logout] $what 삭제 실패: $e');
  }
}
