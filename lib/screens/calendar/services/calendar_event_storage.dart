import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/session_cache.dart';
import '../models/calendar_event.dart';

/// 캘린더 일정 로컬 저장소.
///
/// *** 중요: 서버 API 없음 ***
/// 학사일정 API 연동이 아직 없어(`kUseMockApi = true`) 일정은 기기
/// 로컬(SharedPreferences)에만 저장된다 — 다른 기기/재설치 시에는 보이지
/// 않는다. 알림(로컬 푸시)은 앱이 꺼져 있어도 OS가 울리기 때문에, 일정
/// 데이터를 저장해두지 않으면 "화면상 토글은 꺼져 보이는데 실제로는 전에
/// 걸어둔 알림이 울리는" 불일치가 생긴다 — 이 저장소는 그걸 막기 위한
/// 전제 조건이다(`lib/screens/timetable/services/saved_timetable_storage.dart`
/// 와 같은 패턴).
///
/// 일정은 학번별 칸(`daejin_calendar_events_<학번>`)에 저장하고, 로그아웃해도
/// 지우지 않는다([isKeptOnLogout], 사용자 결정 2026-11-14) — 같은 학생이 다시
/// 로그인하면 내 일정이 돌아오고, 같은 기기로 다른 학생이 로그인하면 그 학생의
/// 칸만 읽어서 앞 사람 일정은 보이지 않는다. 예약 알림은 로그아웃 때 지워지므로
/// 다시 로그인하면 [restoreCalendarReminders]로 다시 건다.
///
/// 학번을 모르면(테스트 등) 예전 한 칸(`daejin_calendar_events`)을 쓴다. 학번별
/// 칸이 생기기 전에 저장된 일정은 처음 읽을 때 그 학생의 칸으로 옮긴다.
class CalendarEventStorage {
  CalendarEventStorage({SharedPreferencesAsync? prefs, String? userId})
    : _prefs = prefs ?? SharedPreferencesAsync(),
      _userId = userId ?? SessionCache.userId;

  static const _legacyKey = 'daejin_calendar_events';
  static const _userKeyPrefix = 'daejin_calendar_events_';

  /// 로그아웃 정리에서 지우지 않고 남길 키인지(학번별 일정 칸).
  static bool isKeptOnLogout(String key) => key.startsWith(_userKeyPrefix);

  final SharedPreferencesAsync _prefs;
  final String? _userId;

  String get _storageKey {
    final userId = _userId;
    return userId == null || userId.isEmpty
        ? _legacyKey
        : '$_userKeyPrefix$userId';
  }

  Future<List<CalendarEvent>> loadAll() async {
    await _migrateLegacy();
    final raw = await _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // 저장된 형식이 깨졌으면(앱 업데이트 등) 빈 목록으로 조용히 폴백한다.
      return [];
    }
  }

  /// 목록 전체를 덮어쓴다. 캘린더 일정은 토글/추가 등으로 통째로 바뀌는
  /// 경우가 많아, 시간표 저장소처럼 건별 save/delete를 나누지 않고
  /// 단순하게 전체 저장으로 통일했다.
  Future<void> saveAll(List<CalendarEvent> events) async {
    final encoded = jsonEncode(events.map((e) => e.toJson()).toList());
    await _prefs.setString(_storageKey, encoded);
  }

  /// 학번별 칸이 아직 없고 예전 한 칸에 일정이 있으면, 그 일정을 지금 학생의
  /// 칸으로 옮긴다. 예전 칸은 로그아웃 때 지워지므로, 남아 있다면 지금 로그인한
  /// 학생이 업데이트 전에 저장한 일정이다.
  Future<void> _migrateLegacy() async {
    final key = _storageKey;
    if (key == _legacyKey) return;
    if (await _prefs.getString(key) != null) return;
    final legacy = await _prefs.getString(_legacyKey);
    if (legacy == null) return;
    await _prefs.setString(key, legacy);
    await _prefs.remove(_legacyKey);
  }
}
