import 'package:flutter/material.dart' show RangeValues;

import '../../services/class_schedule_parser.dart';
import '../../services/course_catalog_service.dart';

/// 검색/필터 패널의 필터 상태.
///
/// Figma 디자인(상태 3~5)에는 전공/영역/온라인/타전공 칩도 있지만,
/// [CourseCatalogItem]에 대응하는 필드가 없어(개설과목 조회 응답에 없는 값)
/// 뺐다 — 디자인 브리프에도 "눈대중으로 비슷한 톤을 매칭하면 충분하다"고만
/// 돼 있을 뿐, 없는 데이터 필드를 지어내서 필터링하진 않는다. 실제 모델
/// 필드로 구현 가능한 요일/학년/이수구분/학점/시간대만 필터로 둔다.
class CourseFilters {
  CourseFilters({
    this.day,
    this.grade,
    this.courseType,
    this.credit,
    this.timeRange = const RangeValues(8 * 60, 22 * 60),
  });

  Weekday? day;
  String? grade;
  String? courseType;
  double? credit;

  /// 00:00부터의 분 단위 범위(08:00~22:00 기본).
  RangeValues timeRange;

  bool get isDefault =>
      day == null &&
      grade == null &&
      courseType == null &&
      credit == null &&
      timeRange.start == 8 * 60 &&
      timeRange.end == 22 * 60;

  void clear() {
    day = null;
    grade = null;
    courseType = null;
    credit = null;
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
