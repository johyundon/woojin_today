import 'package:flutter/material.dart' show RangeValues;

import '../../services/class_schedule_parser.dart';
import '../../services/course_catalog_service.dart';

/// "교양선택1영역" 같은 이수구분 문자열에서 "N영역"의 N만 뽑아낸다.
///
/// *** 추정(비검증) ***: 명세서/실제 응답 샘플로 이 포맷을 확인하지 못했다.
/// 한국 대학 교양과정에서 흔히 쓰이는 "N영역" 표기 관례를 근거로 한
/// 추측이며, 대진대 실제 이수구분 문자열로 검증되는 즉시 재확인이 필요하다.
/// 매칭되지 않으면(교양이 아니거나 포맷이 다르면) null — 그런 과목은 영역
/// 필터에 아예 안 걸린다(거짓으로 분류하지 않음).
final RegExp _areaPattern = RegExp(r'(\d)\s*영역');

String? extractArea(String courseType) =>
    _areaPattern.firstMatch(courseType)?.group(1);

/// 강의실 문자열에 "온라인/원격/비대면/사이버" 중 하나가 들어있으면 비대면
/// 수업으로 본다.
///
/// *** 추정(비검증) ***: 강의실 칸에 이런 키워드가 실제로 들어오는지 확인된
/// 샘플이 없다 — 흔한 표기 관례 기반 추측이다. 실제 데이터로 검증 필요.
final RegExp _onlineRoomPattern = RegExp('온라인|원격|비대면|사이버');

bool looksOnline(String room) => _onlineRoomPattern.hasMatch(room);

/// 검색/필터 패널의 필터 상태.
///
/// 요일/학년/이수구분/학점/시간대는 [CourseCatalogItem]의 실제 필드를 그대로
/// 비교한다. 영역/온라인은 전용 필드가 없어([extractArea]/[looksOnline]
/// 문서 참고) 이수구분·강의실 문자열에서 패턴으로 추정한다 — 추정이 틀리면
/// 해당 과목은 그냥 필터에 안 걸릴 뿐, 거짓으로 걸러내진 않는다.
class CourseFilters {
  CourseFilters({
    this.day,
    this.grade,
    this.courseType,
    this.credit,
    Set<String>? areas,
    this.onlineOnly = false,
    this.timeRange = const RangeValues(8 * 60, 22 * 60),
  }) : areas = areas ?? {};

  Weekday? day;
  String? grade;
  String? courseType;
  double? credit;

  /// Figma 시안(node-id=6-33)에서 영역은 체크박스 여러 개를 동시에 켤 수
  /// 있는 다중 선택이다 — 단일값이 아니라 Set.
  Set<String> areas;
  bool onlineOnly;

  /// 00:00부터의 분 단위 범위(08:00~22:00 기본).
  RangeValues timeRange;

  bool get isDefault =>
      day == null &&
      grade == null &&
      courseType == null &&
      credit == null &&
      areas.isEmpty &&
      !onlineOnly &&
      timeRange.start == 8 * 60 &&
      timeRange.end == 22 * 60;

  void clear() {
    day = null;
    grade = null;
    courseType = null;
    credit = null;
    areas = {};
    onlineOnly = false;
    timeRange = const RangeValues(8 * 60, 22 * 60);
  }

  bool matches(CourseCatalogItem item) {
    final slots = parseRawSchedule(item.rawSchedule);

    if (day != null && !slots.any((s) => s.day == day)) {
      return false;
    }

    if (grade != null && item.targetGrade != grade) {
      return false;
    }

    if (courseType != null && item.courseType != courseType) {
      return false;
    }

    if (credit != null && item.credit != credit) {
      return false;
    }

    if (areas.isNotEmpty && !areas.contains(extractArea(item.courseType))) {
      return false;
    }

    if (onlineOnly && !looksOnline(item.room)) {
      return false;
    }

    final isDefaultTimeRange =
        timeRange.start == 8 * 60 && timeRange.end == 22 * 60;
    if (!isDefaultTimeRange && slots.isNotEmpty) {
      final overlapsRange = slots.any(
        (slot) =>
            slot.startMinutes < timeRange.end &&
            slot.endMinutes > timeRange.start,
      );
      if (!overlapsRange) return false;
    }

    return true;
  }

  /// 그리드 빈 셀을 탭해서 만든 [day]/[startMinutes]~[endMinutes] 범위와
  /// 겹치는 교시가 있는지. (일반 필터와 별개로 추가 적용된다.)
  static bool matchesSlot({
    required CourseCatalogItem item,
    required Weekday day,
    required int startMinutes,
    required int endMinutes,
  }) {
    final slots = parseRawSchedule(item.rawSchedule);
    return slots.any(
      (slot) =>
          slot.day == day &&
          slot.startMinutes < endMinutes &&
          slot.endMinutes > startMinutes,
    );
  }
}
