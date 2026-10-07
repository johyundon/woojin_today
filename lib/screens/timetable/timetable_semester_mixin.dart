part of 'timetable_screen.dart';

/// 현재 학기를 추정한다. home_screen.dart의 `_estimateCurrentSemester`와
/// 로직이 같지만, 그쪽은 private(화면 파일 밖에서 재사용 불가)이라 이 화면
/// 전용으로 똑같이 작게 복제했다 — 이 화면 하나를 위해 홈 화면 파일을
/// 건드리고 싶지 않았다.
({int year, int semester}) _estimateCurrentSemester(DateTime now) {
  if (now.month >= 3 && now.month <= 8) {
    return (year: now.year, semester: 1);
  } else if (now.month >= 9 && now.month <= 12) {
    return (year: now.year, semester: 2);
  } else {
    return (year: now.year - 1, semester: 2);
  }
}

({int year, int semester}) _stepSemester(
  ({int year, int semester}) s,
  int steps,
) {
  var year = s.year;
  var semester = s.semester;
  if (steps >= 0) {
    for (var i = 0; i < steps; i++) {
      if (semester == 1) {
        semester = 2;
      } else {
        semester = 1;
        year++;
      }
    }
  } else {
    for (var i = 0; i < -steps; i++) {
      if (semester == 2) {
        semester = 1;
      } else {
        semester = 2;
        year--;
      }
    }
  }
  return (year: year, semester: semester);
}

/// 학기 이동(헤더의 학기 드롭다운 메뉴) 책임.
mixin TimetableSemesterMixin on TimetableDataLoadingMixin {
  // Figma 시안(node-id=6-38)에서 드롭다운이 "학기" 필이 아니라 헤더 줄
  // 왼쪽 끝(뒤로가기 화살표 쪽)에 맞춰서 뜬다 — 그 폭을 그대로 흉내낸
  // 고정값. 헤더 Row 자체는 Spacer 때문에 화면 폭만큼 넓어서, 메뉴 폭을
  // renderBox.size에서 그대로 따오면 지나치게 넓어진다.
  static const double _semesterMenuWidth = 180;

  Future<void> _openSemesterMenu() async {
    final renderBox =
        _headerKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    if (renderBox == null) return;

    final topLeft = renderBox.localToGlobal(
      Offset(0, renderBox.size.height + 8),
      ancestor: overlay,
    );

    final position = RelativeRect.fromRect(
      Rect.fromLTWH(topLeft.dx, topLeft.dy, _semesterMenuWidth, 0),
      Offset.zero & overlay.size,
    );

    final current = _estimateCurrentSemester(_now());
    final options = [for (var i = 1; i >= -3; i--) _stepSemester(current, i)];

    final selected = await showMenu<({int year, int semester})>(
      context: context,
      position: position,
      color: TimetableColors.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: [
        for (final option in options)
          PopupMenuItem(
            value: option,
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '${option.year}년 ${option.semester}학기',
              style: const TextStyle(
                color: TimetableColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );

    if (!mounted || selected == null) return;
    if (selected.year == _year && selected.semester == _semester) return;

    setState(() {
      _year = selected.year;
      _semester = selected.semester;
      // 학기를 바꾸면 이전 학기 데이터는 더 이상 유효하지 않다 — 그리드/검색
      // 결과를 비우고 새 학기 데이터를 다시 불러온다.
      _confirmedCourses = [];
      _catalog = [];
      _pendingSlot = null;
      _filters.clear();
    });
    if (_hasSession) {
      _loadCatalog();
    }
    if (_hasFullSession) {
      _loadMyTimetable();
    }
  }
}
