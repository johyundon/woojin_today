import '../../services/class_schedule_parser.dart';
import '../campus_map/models/campus_building.dart';
import 'grid_layout.dart';
import 'models/planned_course.dart';

/// 연강(같은 요일 안에서 바로 이어지는 두 수업)인데 건물이 달라서 이동이
/// 필요한 구간 하나.
class TransitLink {
  const TransitLink({
    required this.day,
    required this.gapStartMinutes,
    required this.gapEndMinutes,
    required this.originBuilding,
    required this.destinationBuilding,
  });

  final Weekday day;

  /// 앞 수업이 끝나는 시각(00:00부터의 분).
  final int gapStartMinutes;

  /// 뒤 수업이 시작하는 시각(00:00부터의 분).
  final int gapEndMinutes;

  final String originBuilding;
  final String destinationBuilding;
}

/// 연강 사이 이동이 "10분 이내"인지 판단하는 기준(분).
const int transitGapThresholdMinutes = 10;

/// [room] 문자열 앞부분에서 [campusBuildings]에 있는 건물명을 찾는다.
///
/// 여러 건물명이 서로의 접두사인 경우(예: "학생회관"과 "학생회관 CU")가 있어,
/// 가장 길게 일치하는 이름을 우선한다. 일치하는 건물이 없으면(강의실 표기가
/// 건물 목록과 다르거나 데이터가 이상해도) 예외 없이 null을 반환한다.
String? extractBuildingName(String room) {
  String? best;
  for (final building in campusBuildings) {
    if (room.startsWith(building.name)) {
      if (best == null || building.name.length > best.length) {
        best = building.name;
      }
    }
  }
  return best;
}

/// [courses]를 요일별로 시작 시각 순으로 훑어, 바로 다음 수업과의 간격이
/// [transitGapThresholdMinutes] 이내이면서 건물이 다른 구간을 전부 찾는다.
/// 건물을 못 찾거나(알 수 없는 강의실 표기) 같은 건물이면 건너뛴다(에러 없음).
List<TransitLink> computeTransitLinks(List<PlannedCourse> courses) {
  final layouts = buildBlockLayouts(courses);

  final byDay = <Weekday, List<CourseBlockLayout>>{};
  for (final layout in layouts) {
    (byDay[layout.day] ??= []).add(layout);
  }

  final links = <TransitLink>[];
  for (final entry in byDay.entries) {
    final dayLayouts = entry.value
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

    for (var i = 0; i < dayLayouts.length - 1; i++) {
      final current = dayLayouts[i];
      final next = dayLayouts[i + 1];
      final gap = next.startMinutes - current.endMinutes;
      if (gap < 0 || gap > transitGapThresholdMinutes) continue;

      final origin = extractBuildingName(current.course.room);
      final destination = extractBuildingName(next.course.room);
      if (origin == null || destination == null || origin == destination) {
        continue;
      }

      links.add(
        TransitLink(
          day: entry.key,
          gapStartMinutes: current.endMinutes,
          gapEndMinutes: next.startMinutes,
          originBuilding: origin,
          destinationBuilding: destination,
        ),
      );
    }
  }
  return links;
}
