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
  /// 이번 학기이고 학교에 등록된 과목이 있으면, 화면은 학교 시간표를 보여 주기만
  /// 한다. 이미 수강이 확정된 시간표라 과목 추가·자동 생성·저장이 필요 없어서
  /// 그 버튼들을 숨기고 빈 칸 누르기도 막는다.
  bool get _viewingRegisteredTimetable {
    final current = _estimateCurrentSemester(_now());
    return current.year == _year &&
        current.semester == _semester &&
        _hasRegisteredCourses;
  }

  // v7 디자인 24: 학기 버튼 바로 아래(왼쪽으로 6 비켜서)에 폭 206 흰 상자로
  // 뜬다. 지금 보고 있는 학기 줄만 연파랑 바탕 + 파란 굵은 글자.
  static const double _semesterMenuWidth = 206;

  Future<void> _openSemesterMenu() async {
    final renderBox =
        _headerKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    if (renderBox == null) return;

    final topLeft = renderBox.localToGlobal(
      Offset(-6, renderBox.size.height + 4),
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
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      // 디자인 그림자(검정 6%, 번짐 14)에 가깝게 낮은 그림자만 준다.
      elevation: 2,
      menuPadding: const EdgeInsets.all(8),
      constraints: const BoxConstraints.tightFor(width: _semesterMenuWidth),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        for (final option in options)
          PopupMenuItem(
            value: option,
            height: 44,
            padding: EdgeInsets.zero,
            child: _semesterMenuRow(
              '${option.year}년 ${option.semester}학기',
              selected: option.year == _year && option.semester == _semester,
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
      _hasRegisteredCourses = false;
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

  Widget _semesterMenuRow(String label, {required bool selected}) {
    return Container(
      height: 44,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: selected ? AppColors.blueSoft : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.blue : AppColors.textStrong,
          fontSize: 14,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          height: 1.4,
        ),
      ),
    );
  }
}
