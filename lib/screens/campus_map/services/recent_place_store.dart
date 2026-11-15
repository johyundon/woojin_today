import 'package:shared_preferences/shared_preferences.dart';

/// 캠퍼스 지도 검색 화면의 "최근 검색"(건물 이름 목록)을 휴대폰에 저장한다.
/// 최근 것이 앞에 오고, 같은 이름은 한 번만, 최대 [maxCount]개까지 둔다.
class RecentPlaceStore {
  const RecentPlaceStore();

  static const String _key = 'campus_map_recent_places';
  static const int maxCount = 5;

  Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? const [];
  }

  Future<List<String>> add(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final list = [
      name,
      ...(prefs.getStringList(_key) ?? const <String>[]).where(
        (n) => n != name,
      ),
    ].take(maxCount).toList();
    await prefs.setStringList(_key, list);
    return list;
  }

  Future<List<String>> remove(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final list = (prefs.getStringList(_key) ?? const <String>[])
        .where((n) => n != name)
        .toList();
    await prefs.setStringList(_key, list);
    return list;
  }
}
