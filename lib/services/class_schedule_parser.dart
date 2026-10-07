// `CourseCatalogItem.rawSchedule`(시간표 원문 문자열)을 구조화된 요일+시각
// 데이터로 파싱하고, "지금 수업 중인지"를 판단하는 로직.
//
// 포맷: 실기기에서 확인된 실제 응답 샘플("월09:30-11:30")을 기준으로 "요일 한
// 글자 + HH:MM-HH:MM"을 파싱한다 — 교시 번호가 아니라 시작/종료 시각이
// 원문에 그대로 들어있어, 교시→시각 환산표(추정치)가 더 이상 필요 없다.
// 다만 한 과목이 여러 요일/시간대를 가질 때 그 블록들이 원문 안에서 어떤
// 구분자로 이어지는지는 샘플 하나로는 확인되지 않았다 — 구분자에 상관없이
// 동작하도록 문자열 전체에서 이 패턴에 매칭되는 부분만 전부 찾는(관대한)
// 방식으로 처리한다.
import 'course_catalog_service.dart';

/// 요일. 월요일부터 일요일까지.
enum Weekday { mon, tue, wed, thu, fri, sat, sun }

/// `rawSchedule` 파싱 결과 하나(요일 + 실제 시작/종료 시각).
class ClassTimeSlot {
  const ClassTimeSlot({
    required this.day,
    required this.startMinutes,
    required this.endMinutes,
  });

  final Weekday day;

  /// 00:00부터의 분. 예: 09:30 -> 570.
  final int startMinutes;

  /// 00:00부터의 분(종료 시각, exclusive로 취급).
  final int endMinutes;

  @override
  bool operator ==(Object other) =>
      other is ClassTimeSlot &&
      other.day == day &&
      other.startMinutes == startMinutes &&
      other.endMinutes == endMinutes;

  @override
  int get hashCode => Object.hash(day, startMinutes, endMinutes);

  @override
  String toString() =>
      'ClassTimeSlot(day: $day, startMinutes: $startMinutes, endMinutes: $endMinutes)';
}

/// 요일 한 글자(월/화/수/목/금/토/일) -> [Weekday]. 모르는 글자는 null.
Weekday? _weekdayFromChar(String char) {
  switch (char) {
    case '월':
      return Weekday.mon;
    case '화':
      return Weekday.tue;
    case '수':
      return Weekday.wed;
    case '목':
      return Weekday.thu;
    case '금':
      return Weekday.fri;
    case '토':
      return Weekday.sat;
    case '일':
      return Weekday.sun;
    default:
      return null;
  }
}

/// `DateTime.weekday`(1=월요일 ... 7=일요일) -> [Weekday].
Weekday _weekdayFromDateTime(DateTime dateTime) {
  const map = {
    DateTime.monday: Weekday.mon,
    DateTime.tuesday: Weekday.tue,
    DateTime.wednesday: Weekday.wed,
    DateTime.thursday: Weekday.thu,
    DateTime.friday: Weekday.fri,
    DateTime.saturday: Weekday.sat,
    DateTime.sunday: Weekday.sun,
  };
  return map[dateTime.weekday]!;
}

/// "요일 한 글자" + "HH:MM-HH:MM"이 반복되는 패턴. 예: "월09:30-11:30".
///
/// 블록 사이의 구분자는 무시하고, 문자열 안에서 이 패턴에 매칭되는 부분만
/// 전부 찾아낸다(관대한/permissive 매칭). 전혀 매칭되지 않으면(포맷이
/// 다르거나 빈 문자열이면) 매칭 결과가 없다.
final RegExp _scheduleBlockPattern = RegExp(
  r'([월화수목금토일])(\d{1,2}):(\d{2})-(\d{1,2}):(\d{2})',
);

/// [rawSchedule] 문자열에서 "요일 + 시작/종료 시각" 조합을 전부 추출한다.
///
/// 패턴이 전혀 안 맞으면 빈 리스트를 반환한다(예외를 던지지 않음) — 시간표
/// 원문을 못 가진 과목이라도 화면이 깨지면 안 되기 때문이다. 종료 시각이
/// 시작 시각보다 앞서는(데이터 이상) 블록도 건너뛴다.
List<ClassTimeSlot> parseRawSchedule(String rawSchedule) {
  final slots = <ClassTimeSlot>[];

  for (final match in _scheduleBlockPattern.allMatches(rawSchedule)) {
    final day = _weekdayFromChar(match.group(1)!);
    if (day == null) continue;

    final startHour = int.tryParse(match.group(2)!);
    final startMinute = int.tryParse(match.group(3)!);
    final endHour = int.tryParse(match.group(4)!);
    final endMinute = int.tryParse(match.group(5)!);
    if (startHour == null ||
        startMinute == null ||
        endHour == null ||
        endMinute == null) {
      continue;
    }

    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;
    if (endMinutes <= startMinutes) continue;

    slots.add(
      ClassTimeSlot(day: day, startMinutes: startMinutes, endMinutes: endMinutes),
    );
  }

  return slots;
}

/// [now] 시각에 [courses] 중 수업이 진행 중인 과목을 찾는다. 없으면 null.
///
/// 내부적으로 각 과목의 `rawSchedule`을 [parseRawSchedule]로 파싱해 오늘
/// 요일(=`now.weekday`)에 해당하는 시간대가 있는지, `now`의 시:분이 그
/// 범위 안인지 확인한다.
///
/// 정책: 같은 시각에 두 과목 이상이 겹치는 경우(데이터 이상), [courses]
/// 리스트에서 먼저 나오는 과목을 반환한다(첫 매칭 우선, 예외를 던지지 않음).
CourseCatalogItem? findCurrentClass({
  required List<CourseCatalogItem> courses,
  required DateTime now,
}) {
  final today = _weekdayFromDateTime(now);
  final nowMinutes = now.hour * 60 + now.minute;

  for (final course in courses) {
    for (final slot in parseRawSchedule(course.rawSchedule)) {
      if (slot.day != today) continue;
      if (nowMinutes >= slot.startMinutes && nowMinutes < slot.endMinutes) {
        return course;
      }
    }
  }

  return null;
}
