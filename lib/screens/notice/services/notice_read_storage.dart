import 'package:shared_preferences/shared_preferences.dart';

/// 읽은 공지 목록 로컬 저장소. 공지 서버가 없어 "읽음" 상태도 기기에만
/// 저장되고, 재설치하면 초기화된다.
class NoticeReadStorage {
  NoticeReadStorage({SharedPreferencesAsync? prefs})
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const _storageKey = 'daejin_read_notices';

  final SharedPreferencesAsync _prefs;

  /// 읽은 공지의 키([NoticeItem.key]) 집합. 읽거나 파싱에 실패하면 빈 집합.
  Future<Set<String>> load() async {
    try {
      return (await _prefs.getStringList(_storageKey))?.toSet() ?? {};
    } catch (_) {
      return {};
    }
  }

  Future<void> save(Set<String> readKeys) async {
    try {
      await _prefs.setStringList(_storageKey, readKeys.toList());
    } catch (_) {
      // 저장에 실패해도 이번 실행 동안의 화면 상태에는 영향이 없다.
    }
  }
}
