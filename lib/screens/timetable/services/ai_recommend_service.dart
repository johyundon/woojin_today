import 'dart:math';

import '../../../services/class_schedule_parser.dart';
import '../../../services/course_catalog_service.dart';
import '../grid_layout.dart';
import '../models/ai_recommend_answers.dart';
import '../models/planned_course.dart';

/// 오전/오후 선호를 가를 기준 시각 — *** 추정(비검증) ***: Figma 스크린샷에
/// 정확한 경계 시각이 적혀있지 않아, 13시(오후 1시)를 기준으로 삼았다.
const int _afternoonStartHour = 13;

/// 이수구분 문자열에 "전공"이 들어있으면 전공으로 본다 — course_filters.dart의
/// [extractArea]와 같은 방식의 추정(비검증) 분류다. 실제 대진대 이수구분
/// 문자열 전수 조사로 검증된 적은 없다.
bool _isMajor(CourseCatalogItem item) => item.courseType.contains('전공');

/// [AiRecommendAnswers] 설문 답변을 바탕으로 처음부터 새 시간표 후보
/// [candidateCount]개를 만든다(현재 확정된 과목과는 무관하게 완전히
/// 새로 짠다 — "이 시간표로 할래요"를 눌러야 비로소 기존 확정 목록을
/// 대체한다).
///
/// [AiRecommendAnswers.majorSubRatio](주전공/타전공)와
/// [ExtraOption.honeyLecturesPreferred](꿀강의)는 그 과목이 "내 주전공"인지,
/// 강의 평점이 어떤지 구분할 데이터가 카탈로그에 없어 반영하지 않는다(모델
/// 문서 참고, 사용자 확인 완료).
List<List<PlannedCourse>> generateTimetableCandidates({
  required List<CourseCatalogItem> catalog,
  required AiRecommendAnswers answers,
  int candidateCount = 3,
}) {
  final pool = catalog.where((item) => !item.isClosed).toList();
  return [
    for (var i = 0; i < candidateCount; i++)
      _pickOneCandidate((pool.toList()..shuffle(Random())), answers),
  ];
}

List<PlannedCourse> _pickOneCandidate(
  List<CourseCatalogItem> shuffledPool,
  AiRecommendAnswers answers,
) {
  final occupied = <Weekday, List<({int start, int end})>>{
    for (final day in gridWeekdays) day: [],
  };
  final touchedDays = <Weekday>{};
  final picked = <CourseCatalogItem>[];
  var pickedCredit = 0.0;
  var majorCredit = 0.0;

  for (final item in shuffledPool) {
    if (pickedCredit >= answers.credit) break;
    if (picked.any((p) => p.courseCode == item.courseCode)) continue;

    final slots = parseRawSchedule(item.rawSchedule);
    if (slots.isEmpty) continue;
    if (slots.any((s) => gridColumnIndexOf(s.day) == null)) {
      continue; // 그리드에 없는 요일(토/일) 포함 과목은 제외.
    }
    if (!_matchesFreeDayConstraint(slots, answers)) continue;
    if (!_matchesTimePreference(slots, answers.timePreference)) continue;
    if (!_fitsFreely(slots, occupied)) continue;

    final newCredit = pickedCredit + item.credit;
    if (newCredit > answers.credit + 3) continue; // 목표 학점을 크게 넘기지 않는다.

    final newMajorCredit = majorCredit + (_isMajor(item) ? item.credit : 0);
    if (!answers.majorRatioAny &&
        !_matchesMajorRatio(
          majorCredit: newMajorCredit,
          totalCredit: newCredit,
          targetMajorRatio: answers.majorRatio,
        )) {
      continue;
    }

    final newTouchedDays = {...touchedDays, ...slots.map((s) => s.day)};
    if (!_freeDaySlackOk(newTouchedDays, answers)) continue;

    picked.add(item);
    for (final slot in slots) {
      occupied[slot.day]!.add((start: slot.startMinutes, end: slot.endMinutes));
    }
    touchedDays
      ..clear()
      ..addAll(newTouchedDays);
    pickedCredit = newCredit;
    majorCredit = newMajorCredit;
  }

  return picked.map(PlannedCourse.fromCatalogItem).toList();
}

bool _fitsFreely(
  List<ClassTimeSlot> slots,
  Map<Weekday, List<({int start, int end})>> occupied,
) {
  for (final slot in slots) {
    if (slot.startMinutes < gridStartHour * 60 ||
        slot.endMinutes > gridEndHour * 60) {
      return false;
    }
    final overlaps = occupied[slot.day]!.any(
      (r) => slot.startMinutes < r.end && slot.endMinutes > r.start,
    );
    if (overlaps) return false;
  }
  return true;
}

bool _matchesFreeDayConstraint(
  List<ClassTimeSlot> slots,
  AiRecommendAnswers answers,
) {
  if (answers.freeDayMode != FreeDayMode.specificDay) return true;
  final freeDay = answers.specificFreeDay;
  if (freeDay == null) return true;
  return slots.every((s) => s.day != freeDay);
}

bool _freeDaySlackOk(Set<Weekday> touchedDays, AiRecommendAnswers answers) {
  if (answers.freeDayMode != FreeDayMode.anyDaysCount) return true;
  final maxTouchedDays = gridWeekdays.length - answers.anyFreeDaysCount;
  return touchedDays.length <= maxTouchedDays;
}

bool _matchesTimePreference(
  List<ClassTimeSlot> slots,
  TimePreference preference,
) {
  switch (preference) {
    case TimePreference.morning:
      return slots.every((s) => s.startMinutes < _afternoonStartHour * 60);
    case TimePreference.afternoon:
      return slots.every((s) => s.startMinutes >= _afternoonStartHour * 60);
    case TimePreference.mixed:
    case TimePreference.any:
      return true;
  }
}

/// 목표 전공 비율([targetMajorRatio], 0~100)과 ±30%p 넘게 벌어지면 거부한다
/// (완전히 딱 맞추려 하면 후보가 거의 안 나와서 느슨한 허용 범위를 둔다).
/// 학점이 아직 적을 때(6학점 이하)는 비율이 안 흔들리게 항상 허용한다.
bool _matchesMajorRatio({
  required double majorCredit,
  required double totalCredit,
  required double targetMajorRatio,
}) {
  if (totalCredit <= 6) return true;
  final actualRatio = majorCredit / totalCredit * 100;
  return (actualRatio - targetMajorRatio).abs() <= 30;
}
