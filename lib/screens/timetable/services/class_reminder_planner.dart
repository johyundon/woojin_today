import '../../../services/class_schedule_parser.dart';
import '../../../utils/time_format.dart';
import '../models/planned_course.dart';

/// 수업 시작 몇 분 전에 알림을 울릴지.
const int classReminderLeadMinutes = 10;

/// 매주 반복해서 울릴 알림 1건. 한 과목이 여러 요일에 있으면 요일마다 1건씩.
class ClassReminder {
  const ClassReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.weekday,
    required this.minutesOfDay,
  });

  /// 예약/취소에 쓰는 고유 키("과목코드-분반-요일-시작분").
  final String id;
  final String title;
  final String body;

  /// [DateTime.weekday] 기준(1=월 ... 7=일).
  final int weekday;

  /// 알림이 울릴 시각(자정부터 몇 분째).
  final int minutesOfDay;
}

/// [courses]의 시간표 원문을 읽어 요일별 알림 목록을 만든다. 시간표 원문이
/// 없거나(시간 미정) 알림 시각이 전날로 넘어가는 과목은 건너뛴다.
List<ClassReminder> buildClassReminders(
  List<PlannedCourse> courses, {
  int leadMinutes = classReminderLeadMinutes,
}) {
  final reminders = <ClassReminder>[];
  for (final course in courses) {
    for (final slot in parseRawSchedule(course.rawSchedule)) {
      final minutes = slot.startMinutes - leadMinutes;
      if (minutes < 0) continue;

      final room = course.room.isEmpty ? '' : ' · ${course.room}';
      reminders.add(
        ClassReminder(
          id: '${course.key}-${slot.day.index + 1}-${slot.startMinutes}',
          title: '${course.courseName} 수업 $leadMinutes분 전',
          body: '${formatMinutesAsTime(slot.startMinutes)} 시작$room',
          weekday: slot.day.index + 1,
          minutesOfDay: minutes,
        ),
      );
    }
  }
  return reminders;
}

/// [now] 이후 가장 가까운, [weekday] 요일 [minutesOfDay] 시각을 돌려준다.
/// 이번 주 그 시각이 이미 지났으면 다음 주로 넘긴다(켜자마자 울리지 않게).
DateTime nextWeeklyOccurrence(DateTime now, int weekday, int minutesOfDay) {
  final hour = minutesOfDay ~/ 60;
  final minute = minutesOfDay % 60;
  final daysAhead = (weekday - now.weekday) % 7;
  var candidate = DateTime(
    now.year,
    now.month,
    now.day + daysAhead,
    hour,
    minute,
  );
  if (!candidate.isAfter(now)) {
    candidate = DateTime(
      candidate.year,
      candidate.month,
      candidate.day + 7,
      hour,
      minute,
    );
  }
  return candidate;
}
