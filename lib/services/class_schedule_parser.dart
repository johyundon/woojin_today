// `CourseCatalogItem.rawSchedule`(시간표 원문 문자열)을 구조화된 요일+교시
// 데이터로 파싱하고, 교시를 실제 시각으로 환산해 "지금 수업 중인지"를
// 판단하는 로직.
//
// *** 전체 파일이 "추정(비검증)" 구현이다 ***
// API 명세서는 rawSchedule을 "시간표 원문(구조화는 후속 단계)"라고만 적어놓고
// 실제 포맷 예시나 파싱 규칙을 정의하지 않았다. 또한 교시별 실제 시작/종료
// 시각(교시표)도 명세서에 없다. 이 파일의 파서 패턴과 교시표는 한국 대학
// 수강신청 시스템에서 흔히 쓰이는 표기 관례를 바탕으로 한 **추측**이며,
// 실제 대진대학교 시스템에서 받은 샘플 데이터로 검증되지 않았다.
// 실제 데이터를 확보하는 즉시 재검증/수정이 필요하다.

import 'course_catalog_service.dart';

/// 요일. 월요일부터 일요일까지.
enum Weekday { mon, tue, wed, thu, fri, sat, sun }

/// `rawSchedule` 파싱 결과 하나(요일 + 교시 번호).
class ClassPeriodSlot {
  const ClassPeriodSlot({required this.day, required this.period});

  final Weekday day;

  /// 교시 번호(1부터 시작).
  final int period;

  @override
  bool operator ==(Object other) =>
      other is ClassPeriodSlot && other.day == day && other.period == period;

  @override
  int get hashCode => Object.hash(day, period);

  @override
  String toString() => 'ClassPeriodSlot(day: $day, period: $period)';
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

/// **추측 포맷**: "요일 한 글자" + "교시 숫자(쉼표로 구분)"가 반복되는 패턴.
/// 예: "월1,2,3목4,5", "월1,2 화3".
///
/// 요일 블록 사이의 구분자(공백 등)는 무시하고, 문자열 안에서 이 패턴에
/// 매칭되는 부분만 전부 찾아낸다(관대한/permissive 매칭). 이 정규식에
/// 전혀 매칭되지 않으면(예: 포맷이 다르거나 빈 문자열이면) 매칭 결과가 없다.
final RegExp _scheduleBlockPattern = RegExp(r'([월화수목금토일])((?:\d+\s*,\s*)*\d+)');

/// [rawSchedule] 문자열에서 "요일 + 교시" 조합을 전부 추출한다.
///
/// 패턴이 전혀 안 맞으면 빈 리스트를 반환한다(예외를 던지지 않음) — 시간표
/// 원문을 못 가진 과목이라도 화면이 깨지면 안 되기 때문이다.
///
/// 주의: 이 파서가 가정하는 포맷 자체가 추측이다(파일 상단 설명 참고).
List<ClassPeriodSlot> parseRawSchedule(String rawSchedule) {
  final slots = <ClassPeriodSlot>[];

  for (final match in _scheduleBlockPattern.allMatches(rawSchedule)) {
    final day = _weekdayFromChar(match.group(1)!);
    if (day == null) continue;

    final periodsText = match.group(2)!;
    for (final rawPeriod in periodsText.split(',')) {
      final period = int.tryParse(rawPeriod.trim());
      if (period == null || period <= 0) continue;
      slots.add(ClassPeriodSlot(day: day, period: period));
    }
  }

  return slots;
}

/// 교시 번호 하나의 시작/종료 시각(자정 기준 분 단위, 0~1439).
class PeriodTimeRange {
  const PeriodTimeRange({
    required this.period,
    required this.startMinutes,
    required this.endMinutes,
  });

  final int period;

  /// 00:00부터의 분. 예: 09:00 -> 540.
  final int startMinutes;

  /// 00:00부터의 분(종료 시각, exclusive로 취급).
  final int endMinutes;
}

// --- 아래 상수들은 전부 "추정값"이다 ---
// 실제 대진대학교 교시표(공식 수업시간표)를 확인하기 전까지는 검증되지
// 않은 가정이며, 가장 단순하고 널리 쓰이는 패턴(1교시 09:00 시작, 50분
// 수업 + 10분 휴식 -> 교시마다 1시간씩 밀림)을 그대로 적용했을 뿐이다.
// 실제 교시표(쉬는 시간이 다르거나 공강 시간이 끼어있는 등)와 다를 수 있다.

/// 1교시 시작 시각(분). 09:00 가정 — 추정값.
const int _assumedFirstPeriodStartMinutes = 9 * 60;

/// 한 교시의 수업 시간(분). 50분 가정 — 추정값.
const int _assumedClassDurationMinutes = 50;

/// 교시 시작 시각 간 간격(분). 50분 수업 + 10분 휴식 = 60분 가정 — 추정값.
const int _assumedPeriodIntervalMinutes = 60;

/// 생성할 교시 수의 임의 상한(야간 수업 포함 넉넉하게). 실제 상한이 아니라
/// 테이블을 유한하게 만들기 위한 임의 값 — 추정값.
const int _assumedPeriodCount = 14;

/// 교시 번호(1부터) -> [PeriodTimeRange]. **검증되지 않은 추정 교시표**다.
/// 실제 대진대 교시표로 반드시 재검증해야 한다.
final Map<int, PeriodTimeRange> assumedPeriodTimes = {
  for (var period = 1; period <= _assumedPeriodCount; period++)
    period: PeriodTimeRange(
      period: period,
      startMinutes:
          _assumedFirstPeriodStartMinutes +
          (period - 1) * _assumedPeriodIntervalMinutes,
      endMinutes:
          _assumedFirstPeriodStartMinutes +
          (period - 1) * _assumedPeriodIntervalMinutes +
          _assumedClassDurationMinutes,
    ),
};

/// [now] 시각에 [courses] 중 수업이 진행 중인 과목을 찾는다. 없으면 null.
///
/// 내부적으로 각 과목의 `rawSchedule`을 [parseRawSchedule]로 파싱해 오늘
/// 요일(=`now.weekday`)에 해당하는 교시가 있는지 확인하고, [assumedPeriodTimes]
/// (추정 교시표)로 그 교시의 시작~종료 시각과 `now`의 시:분을 비교한다.
///
/// 정책: 같은 시각에 두 과목 이상이 겹치는 경우(데이터 이상), [courses]
/// 리스트에서 먼저 나오는 과목을 반환한다(첫 매칭 우선, 예외를 던지지 않음).
///
/// 주의: 이 판단은 [parseRawSchedule]의 포맷 추측과 [assumedPeriodTimes]의
/// 추정 교시표에 의존하므로, 둘 중 하나라도 실제와 다르면 잘못된 결과를
/// 반환할 수 있다. 실제 대진대 데이터로 재검증이 필요하다.
CourseCatalogItem? findCurrentClass({
  required List<CourseCatalogItem> courses,
  required DateTime now,
}) {
  final today = _weekdayFromDateTime(now);
  final nowMinutes = now.hour * 60 + now.minute;

  for (final course in courses) {
    final slots = parseRawSchedule(course.rawSchedule);
    for (final slot in slots) {
      if (slot.day != today) continue;

      final range = assumedPeriodTimes[slot.period];
      if (range == null) continue;

      if (nowMinutes >= range.startMinutes && nowMinutes < range.endMinutes) {
        return course;
      }
    }
  }

  return null;
}
