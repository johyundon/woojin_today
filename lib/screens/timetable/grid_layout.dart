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

/// [courses]의 `rawSchedule`을 파싱해(`parseRawSchedule`,
/// class_schedule_parser.dart) 그리드에 그릴 블록 목록을 만든다. 원문에
/// 이미 요일별 시작~종료 시각이 그대로 들어있어(예: "월09:30-11:30"),
/// 교시 병합 같은 추가 가공 없이 슬롯 하나당 블록 하나로 그린다. 토/일
/// 슬롯은 그리드에 요일 열이 없어 제외한다.
List<CourseBlockLayout> buildBlockLayouts(List<PlannedCourse> courses) {
  final layouts = <CourseBlockLayout>[];

  for (final course in courses) {
    for (final slot in parseRawSchedule(course.rawSchedule)) {
      if (gridColumnIndexOf(slot.day) == null) continue;
      layouts.add(
        CourseBlockLayout(
          course: course,
          day: slot.day,
          startMinutes: slot.startMinutes,
          endMinutes: slot.endMinutes,
        ),
      );
    }
  }

  return layouts;
}
