import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_timetable.dart';

/// "저장한 시간표" 로컬 저장소.
///
/// *** 중요: 서버 API 없음 ***
/// API 명세서(daejin-api-spec-reference)에 "시간표 저장"/"저장한 시간표 조회"에
/// 대응하는 엔드포인트가 없다. 그래서 이 기능은 기기 로컬(SharedPreferences)
/// 에만 저장되고, 다른 기기/재설치 시에는 보이지 않는다 — 추측으로 서버 API를
/// 만들어 호출하지 않는다.
class SavedTimetableStorage {
  SavedTimetableStorage({SharedPreferencesAsync? prefs})
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const _storageKey = 'daejin_saved_timetables';

  final SharedPreferencesAsync _prefs;

  Future<List<SavedTimetable>> loadAll() async {
    final raw = await _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => SavedTimetable.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // 저장된 형식이 깨졌으면(앱 업데이트 등) 빈 목록으로 조용히 폴백한다.
      return [];
    }
  }

  Future<void> save(SavedTimetable timetable) async {
    final all = await loadAll();
    all.add(timetable);
    await _writeAll(all);
  }

  Future<void> delete(String id) async {
    final all = await loadAll();
    all.removeWhere((t) => t.id == id);
    await _writeAll(all);
  }

  Future<void> _writeAll(List<SavedTimetable> all) async {
    final encoded = jsonEncode(all.map((t) => t.toJson()).toList());
    await _prefs.setString(_storageKey, encoded);
  }
}
