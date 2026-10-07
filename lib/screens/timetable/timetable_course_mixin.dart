part of 'timetable_screen.dart';

/// 빈 셀 탭, 과목 추가/삭제, 규칙 기반 자동 시간표 추천 등 확정 과목
/// 목록(_confirmedCourses)을 직접 조작하는 책임.
mixin TimetableCourseMixin on TimetableSessionMixin {
  void _onEmptyCellTap(Weekday day, int startHour) {
    setState(() => _pendingSlot = PendingSlot(day: day, startHour: startHour));
  }

  void _clearPendingSlot() {
    setState(() => _pendingSlot = null);
  }

  void _removeCourse(PlannedCourse course) {
    setState(() {
      _confirmedCourses = _confirmedCourses
          .where((c) => c.key != course.key)
          .toList();
    });
  }

  void _addCourse(CourseCatalogItem item) {
    final planned = PlannedCourse.fromCatalogItem(item);
    setState(() {
      // 분반(시간대)만 다르고 과목코드가 같으면 같은 과목이다 — 새로 고른
      // 분반으로 교체한다(동시에 여러 분반을 담지 못하게).
      _confirmedCourses = [
        ..._confirmedCourses.where((c) => c.courseCode != planned.courseCode),
        planned,
      ];
      _pendingSlot = null;
    });
  }

  /// 규칙 기반 자동 시간표 추천: 외부 AI 호출 없이, 현재 빈 시간대에 완전히
  /// 들어맞는 미확정 개설과목을 앞에서부터 그리디하게 채운다. 이미 확정된
  /// 과목·폐강 과목·그리드 범위(월~금 8~22시) 밖 교시는 후보에서 제외한다.
  void _autoFillSchedule() {
    if (_catalog.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('추천할 개설과목 데이터가 없어요.')));
      return;
    }

    final occupied = <Weekday, List<({int start, int end})>>{
      for (final day in gridWeekdays) day: [],
    };
    for (final course in _confirmedCourses) {
      for (final slot in parseRawSchedule(course.rawSchedule)) {
        if (!occupied.containsKey(slot.day)) continue;
        occupied[slot.day]!.add((start: slot.startMinutes, end: slot.endMinutes));
      }
    }

    bool fitsFreely(List<ClassTimeSlot> slots) {
      for (final slot in slots) {
        if (!occupied.containsKey(slot.day)) return false;
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

    final existingKeys = _confirmedCourses.map((c) => c.key).toSet();
    final picked = <CourseCatalogItem>[];

    for (final item in _catalog) {
      if (item.isClosed) continue;
      final key = '${item.courseCode}-${item.section}';
      if (existingKeys.contains(key)) continue;

      final slots = parseRawSchedule(item.rawSchedule);
      if (slots.isEmpty || !fitsFreely(slots)) continue;

      for (final slot in slots) {
        occupied[slot.day]!.add((start: slot.startMinutes, end: slot.endMinutes));
      }
      picked.add(item);
      existingKeys.add(key);
    }

    if (picked.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('빈 시간대에 맞는 과목을 찾지 못했어요.')));
      return;
    }

    setState(() {
      _confirmedCourses = [
        ..._confirmedCourses,
        ...picked.map(PlannedCourse.fromCatalogItem),
      ];
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${picked.length}과목을 추천해서 채웠어요.')));
  }
}
