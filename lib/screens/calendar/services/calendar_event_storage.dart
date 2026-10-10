import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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
class CalendarEventStorage {
  CalendarEventStorage({SharedPreferencesAsync? prefs})
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const _storageKey = 'daejin_calendar_events';

  final SharedPreferencesAsync _prefs;

  Future<List<CalendarEvent>> loadAll() async {
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
}
