import '../../services/class_schedule_parser.dart';
import 'models/planned_course.dart';

/// 그리드에 보여주는 시간 범위(8시~22시, 필터 패널의 시간 슬라이더 범위와 동일).
const int gridStartHour = 8;
const int gridEndHour = 22;

/// 그리드 한 시간(60분) 칸의 높이(px).
const double gridHourRowHeight = 64;

/// 그리드에 표시하는 요일(월~금만 — Figma 디자인에 토/일 열이 없다).
const List<Weekday> gridWeekdays = [
  Weekday.mon,
  Weekday.tue,
  Weekday.wed,
  Weekday.thu,
  Weekday.fri,
];

/// [gridWeekdays] 안에서의 인덱스(0~4). 토/일이면 null.
int? gridColumnIndexOf(Weekday day) {
  final index = gridWeekdays.indexOf(day);
  return index < 0 ? null : index;
}

/// 그리드에 그릴 과목 블록 하나(한 요일에서 연속된 교시를 하나로 합친 범위).
class CourseBlockLayout {
  const CourseBlockLayout({
    required this.course,
    required this.day,
    required this.startMinutes,
    required this.endMinutes,
  });

  final PlannedCourse course;
  final Weekday day;

  /// 00:00부터의 분.
  final int startMinutes;
  final int endMinutes;
}

/// [courses]의 `rawSchedule`을 파싱해(`parseRawSchedule`/`assumedPeriodTimes`,
/// 둘 다 class_schedule_parser.dart의 기존 "추정" 로직을 그대로 재사용) 그리드에
/// 그릴 블록 목록을 만든다.
///
/// 같은 요일에 교시 번호가 연속이면(예: 3,4교시) 하나의 블록으로 합친다 —
/// Figma 스크린샷에서 "마이크로임베디드" 같은 2교시 연속 수업이 끊김 없이
/// 하나의 긴 블록으로 보이는 것과 맞추기 위함이다. 토/일 슬롯은 그리드에
/// 요일 열이 없어 제외한다.
List<CourseBlockLayout> buildBlockLayouts(List<PlannedCourse> courses) {
  final layouts = <CourseBlockLayout>[];

  for (final course in courses) {
    final slots = parseRawSchedule(course.rawSchedule);

    final periodsByDay = <Weekday, List<int>>{};
    for (final slot in slots) {
      if (gridColumnIndexOf(slot.day) == null) continue;
      periodsByDay.putIfAbsent(slot.day, () => []).add(slot.period);
    }

    for (final entry in periodsByDay.entries) {
      final periods = entry.value.toSet().toList()..sort();
      var runStart = periods.first;
      var prev = periods.first;

      void flushRun() {
        final startRange = assumedPeriodTimes[runStart];
        final endRange = assumedPeriodTimes[prev];
        if (startRange == null || endRange == null) return;
        layouts.add(
          CourseBlockLayout(
            course: course,
            day: entry.key,
            startMinutes: startRange.startMinutes,
            endMinutes: endRange.endMinutes,
          ),
        );
      }

      for (var i = 1; i < periods.length; i++) {
        if (periods[i] != prev + 1) {
          flushRun();
          runStart = periods[i];
        }
        prev = periods[i];
      }
      flushRun();
    }
  }

  return layouts;
}
