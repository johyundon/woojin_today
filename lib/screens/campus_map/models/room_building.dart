import '../../../services/class_schedule_parser.dart';
import 'campus_building.dart';

/// 시간표 강의실 글자 앞부분(공백 뺀 건물 이름) → [campusBuildings]의 건물 이름.
/// 건물 목록 이름과 그대로 같은 경우는 따로 적지 않아도 된다.
///
/// *** 미검증 *** 실제 시간표 응답의 강의실 표기를 아직 다 확인하지 못해,
/// 흔히 쓰는 줄임말만 넣었다. 못 찾으면 null이 되어 걷는 거리를 숨긴다.
const Map<String, String> _roomPrefixAliases = {
  '인문관': '인문학관',
  '인문': '인문학관',
  '사회관': '사회과학관',
  '사과관': '사회과학관',
  '교육관': '대진교육관',
  '공대가동': '공대 가동',
  '공대나동': '공대 나동',
  '공대다동': '공대 다동',
  '공학관가동': '공대 가동',
  '공학관나동': '공대 나동',
  '공학관다동': '공대 다동',
  '가동': '공대 가동',
  '나동': '공대 나동',
  '다동': '공대 다동',
  '도서관': '중앙도서관',
  '미술관': '미술학관',
  '음악관': '음악학관',
  '생과관': '생활과학관',
  '생활관': '생활과학관',
  '실습관': '산학협동실습관',
};

/// 같은 과목이 시간대마다 강의실이 다르면 `강의실1/강의실2`처럼 `/`로 나뉘어
/// 오고, 순서는 강의시간 순서와 같다. [item]의 시간대에 해당하는 강의실을
/// 돌려준다. 개수가 맞지 않으면 원문 그대로 돌려준다.
String roomForSlot(TodayClass item) {
  final rooms = item.course.room
      .split('/')
      .map((r) => r.trim())
      .where((r) => r.isNotEmpty)
      .toList();
  if (rooms.length <= 1) return item.course.room.trim();
  final slots = parseRawSchedule(item.course.rawSchedule);
  final index = slots.indexWhere(
    (s) =>
        s.day == item.slot.day &&
        s.startMinutes == item.slot.startMinutes &&
        s.endMinutes == item.slot.endMinutes,
  );
  if (rooms.length != slots.length || index < 0) return item.course.room.trim();
  return rooms[index];
}

/// 강의실 글자("인문학관 302", "인문관302호" 등)에서 숫자 앞 건물 이름을 떼어
/// 캠퍼스 건물을 찾는다. 못 찾으면 null.
CampusBuilding? buildingForRoom(String room) {
  final compact = room.replaceAll(RegExp(r'\s+'), '');
  final prefix = RegExp(r'^[^\d\-]+').firstMatch(compact)?.group(0);
  if (prefix == null || prefix.isEmpty) return null;
  final name = _roomPrefixAliases[prefix] ?? prefix;
  for (final building in campusBuildings) {
    if (building.name.replaceAll(' ', '') == name.replaceAll(' ', '')) {
      return building;
    }
  }
  return null;
}
