import 'dart:math';

import '../../../services/class_schedule_parser.dart';
import '../../../services/course_catalog_service.dart';
import '../grid_layout.dart';
import '../models/ai_recommend_answers.dart';
import '../models/planned_course.dart';

/// 오전/오후 선호를 가를 기준 시각 — *** 추정(비검증) ***: Figma 스크린샷에
/// 정확한 경계 시각이 적혀있지 않아, 13시(오후 1시)를 기준으로 삼았다.
const int _afternoonStartHour = 13;

/// 후보를 몇 번 만들어 보고 그중 좋은 것을 고를지. 예시 데이터(약 1,500과목)로
/// 재 보니 한 번 누를 때 수십 ms 안에 끝나는 정도다.
const int _defaultAttempts = 150;

/// 이수구분이 전공인지. 학교 개설과목은 "전선"·"전필"·"전기"처럼 줄임말만
/// 쓰고 "전공"이라는 글자가 없다(2026-2 실제 응답 확인). 그래서 "전"으로
/// 시작하면 전공으로 본다("전공선택" 같은 긴 이름도 함께 걸린다).
bool isMajorCourseType(String courseType) => courseType.trim().startsWith('전');

/// 대상학년 칸의 숫자(학교 데이터는 "3", 예전 가짜 데이터는 "3학년").
String? _gradeDigit(String targetGrade) =>
    RegExp(r'[1-4]').firstMatch(targetGrade)?.group(0);

/// 교직 과목은 교직 이수자만 듣는 과목이라 자동 생성 후보에서 뺀다.
bool _isTeachingCourse(String courseType) => courseType.trim() == '교직';

/// 자동 생성이 참고하는 "나"에 대한 정보. 못 구하면 null로 두고, 그 경우엔
/// 학과·학년을 가리지 않는다.
class AiRecommendProfile {
  const AiRecommendProfile({this.myMajorCourseCodes, this.myGrade});

  /// 내 학과 전공 과목코드(학과별 개설과목 조회 결과). 있으면 이 목록에 없는
  /// 전공 과목(다른 학과 전공)은 후보에서 뺀다. 교양은 학과와 상관없이 둔다.
  final Set<String>? myMajorCourseCodes;

  /// 내 학년(1~4). 있으면 대상학년이 같은 전공 과목을 먼저 고른다.
  final int? myGrade;
}

/// [AiRecommendAnswers] 설문 답변을 바탕으로 처음부터 새 시간표 후보
/// [candidateCount]개를 만든다(현재 확정된 과목과는 무관하게 완전히
/// 새로 짠다 — "이 시간표로 할래요"를 눌러야 비로소 기존 확정 목록을
/// 대체한다).
///
/// 과목을 섞어 조건에 맞는 것부터 담는 일을 [attempts]번 해 보고, 점수가
/// 높은(목표 학점에 가깝고, 전공 비율·학년·오전오후 균형이 맞는) 서로 다른
/// 후보를 고른다.
///
/// [AiRecommendAnswers.majorSubRatio](주전공/타전공)와
/// [ExtraOption.honeyLecturesPreferred](꿀강의)는 아직 반영하지 않는다(모델
/// 문서 참고).
List<List<PlannedCourse>> generateTimetableCandidates({
  required List<CourseCatalogItem> catalog,
  required AiRecommendAnswers answers,
  AiRecommendProfile profile = const AiRecommendProfile(),
  int candidateCount = 3,
  int attempts = _defaultAttempts,
  Random? random,
}) {
  final rng = random ?? Random();
  final pool = _buildPool(catalog, profile);

  final scored = <({List<_PoolItem> picked, double score, String key})>[];
  for (var i = 0; i < max(attempts, candidateCount); i++) {
    final picked = _pickOneCandidate(
      _weightedShuffle(pool, answers, profile, rng),
      answers,
    );
    scored.add((
      picked: picked,
      score: _score(picked, answers, profile),
      key: (picked.map((p) => p.item.courseCode).toList()..sort()).join(','),
    ));
  }
  scored.sort((a, b) => b.score.compareTo(a.score));

  // 같은 조합은 한 번만 보여주고, 서로 다른 후보가 모자라면 남은 것으로 채운다.
  final result = <List<_PoolItem>>[];
  final seen = <String>{};
  for (final s in scored) {
    if (result.length >= candidateCount) break;
    if (seen.add(s.key)) result.add(s.picked);
  }
  for (final s in scored) {
    if (result.length >= candidateCount) break;
    result.add(s.picked);
  }

  return [
    for (final picked in result)
      [for (final p in picked) PlannedCourse.fromCatalogItem(p.item)],
  ];
}

/// 과목 하나와 미리 풀어 둔 수업 시간.
class _PoolItem {
  const _PoolItem(this.item, this.slots, this.isMajor);

  final CourseCatalogItem item;
  final List<ClassTimeSlot> slots;
  final bool isMajor;
}

/// 후보로 쓸 수 있는 과목만 남기고 수업 시간을 한 번만 풀어 둔다.
List<_PoolItem> _buildPool(
  List<CourseCatalogItem> catalog,
  AiRecommendProfile profile,
) {
  final myMajors = profile.myMajorCourseCodes;
  final pool = <_PoolItem>[];
  for (final item in catalog) {
    if (item.isClosed || _isTeachingCourse(item.courseType)) continue;
    final isMajor = isMajorCourseType(item.courseType);
    // 내 학과 전공 목록을 알면 다른 학과 전공은 뺀다.
    if (isMajor && myMajors != null && !myMajors.contains(item.courseCode)) {
      continue;
    }
    final slots = parseRawSchedule(item.rawSchedule);
    if (slots.isEmpty) continue;
    if (slots.any((s) => gridColumnIndexOf(s.day) == null)) {
      continue; // 그리드에 없는 요일(토/일) 포함 과목은 제외.
    }
    if (slots.any(
      (s) =>
          s.startMinutes < gridStartHour * 60 ||
          s.endMinutes > gridEndHour * 60,
    )) {
      continue; // 시간표 칸 밖 시간 포함 과목은 제외.
    }
    pool.add(_PoolItem(item, slots, isMajor));
  }
  return pool;
}

/// 담을 순서를 정한다. 전공과 그 밖의 과목을 따로 섞은 뒤, 고른 전공 비율만큼의
/// 확률로 번갈아 꺼낸다. 내 학과 전공은 수십 개뿐이라 전체를 한꺼번에 섞으면
/// 전공이 앞쪽에 거의 오지 않아 전공 비율을 못 채우기 때문이다. 전공 안에서는
/// 내 학년 과목이 앞에 더 자주 오게 한다(무게 2배).
List<_PoolItem> _weightedShuffle(
  List<_PoolItem> pool,
  AiRecommendAnswers answers,
  AiRecommendProfile profile,
  Random rng,
) {
  final grade = profile.myGrade?.toString();
  double weight(_PoolItem p) =>
      grade != null && p.isMajor && _gradeDigit(p.item.targetGrade) == grade
      ? 2.0
      : 1.0;
  List<_PoolItem> shuffle(Iterable<_PoolItem> items) {
    final keyed = [for (final p in items) (p, rng.nextDouble() * weight(p))]
      ..sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final k in keyed) k.$1];
  }

  final majors = shuffle(pool.where((p) => p.isMajor));
  final others = shuffle(pool.where((p) => !p.isMajor));
  final majorChance = answers.majorRatioAny
      ? (pool.isEmpty ? 0.0 : majors.length / pool.length)
      : answers.majorRatio / 100;

  final ordered = <_PoolItem>[];
  var i = 0;
  var j = 0;
  while (i < majors.length || j < others.length) {
    final takeMajor =
        j >= others.length ||
        (i < majors.length && rng.nextDouble() < majorChance);
    ordered.add(takeMajor ? majors[i++] : others[j++]);
  }
  return ordered;
}

List<_PoolItem> _pickOneCandidate(
  List<_PoolItem> shuffledPool,
  AiRecommendAnswers answers,
) {
  final occupied = <Weekday, List<({int start, int end})>>{
    for (final day in gridWeekdays) day: [],
  };
  final touchedDays = <Weekday>{};
  final picked = <_PoolItem>[];
  final pickedCodes = <String>{};
  var pickedCredit = 0.0;
  var majorCredit = 0.0;

  for (final p in shuffledPool) {
    if (pickedCredit >= answers.credit) break;
    final item = p.item;
    if (pickedCodes.contains(item.courseCode)) continue;

    final slots = p.slots;
    if (!_matchesFreeDayConstraint(slots, answers)) continue;
    if (!_matchesTimePreference(slots, answers.timePreference)) continue;
    if (!_fitsFreely(slots, occupied)) continue;

    final newCredit = pickedCredit + item.credit;
    if (newCredit > answers.credit + 3) continue; // 목표 학점을 크게 넘기지 않는다.

    final newMajorCredit = majorCredit + (p.isMajor ? item.credit : 0);
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

    picked.add(p);
    pickedCodes.add(item.courseCode);
    for (final slot in slots) {
      occupied[slot.day]!.add((start: slot.startMinutes, end: slot.endMinutes));
    }
    touchedDays
      ..clear()
      ..addAll(newTouchedDays);
    pickedCredit = newCredit;
    majorCredit = newMajorCredit;
  }

  return picked;
}

/// 후보 점수. 높을수록 좋다.
/// - 목표 학점과 1학점 차이마다 -10 (가장 중요)
/// - 전공 비율이 목표와 1%p 벌어질 때마다 -0.2
/// - 내 학년 전공 과목마다 +1, 다른 학년 전공 과목마다 -1
/// - "적당히 섞어주세요"면 오전·오후 수업 수 차이마다 -2
double _score(
  List<_PoolItem> picked,
  AiRecommendAnswers answers,
  AiRecommendProfile profile,
) {
  final credit = picked.fold(0.0, (s, p) => s + p.item.credit);
  var score = -10 * (credit - answers.credit).abs();

  if (!answers.majorRatioAny && credit > 0) {
    final major = picked
        .where((p) => p.isMajor)
        .fold(0.0, (s, p) => s + p.item.credit);
    score -= 0.2 * (major / credit * 100 - answers.majorRatio).abs();
  }

  final grade = profile.myGrade?.toString();
  if (grade != null) {
    for (final p in picked.where((p) => p.isMajor)) {
      score += _gradeDigit(p.item.targetGrade) == grade ? 1 : -1;
    }
  }

  if (answers.timePreference == TimePreference.mixed) {
    var morning = 0;
    var afternoon = 0;
    for (final p in picked) {
      for (final s in p.slots) {
        s.startMinutes < _afternoonStartHour * 60 ? morning++ : afternoon++;
      }
    }
    score -= 2 * (morning - afternoon).abs();
  }
  return score;
}

bool _fitsFreely(
  List<ClassTimeSlot> slots,
  Map<Weekday, List<({int start, int end})>> occupied,
) {
  for (final slot in slots) {
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
