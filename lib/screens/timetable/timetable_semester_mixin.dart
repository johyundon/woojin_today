part of 'timetable_screen.dart';

/// 현재 학기를 추정한다(2~7월 1학기, 8~12월 2학기, 1월 전년도 2학기 —
/// 사용자 결정, 2026-11-15). home_screen.dart의 `_estimateCurrentSemester`와
/// 로직이 같지만, 그쪽은 private(화면 파일 밖에서 재사용 불가)이라 이 화면
/// 전용으로 똑같이 작게 복제했다 — 이 화면 하나를 위해 홈 화면 파일을
/// 건드리고 싶지 않았다.
({int year, int semester}) _estimateCurrentSemester(DateTime now) {
  if (now.month >= 2 && now.month <= 7) {
    return (year: now.year, semester: 1);
  } else if (now.month >= 8) {
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
  /// 시간표를 보기만 하는 학기면 그 이유 안내, 고칠 수 있으면 null.
  /// 지금은 모든 학기를 열어 둔다 — 지난 학기도, 학교에 등록된 이번 학기
  /// 시간표도 과목을 더해 볼 수 있다(사용자 요청, 2026-11-15). 보기 전용
  /// 안내를 보여 주는 장치(헤더의 readOnlyNote)는 다시 쓸 수 있게 남겨 둔다.
  String? get _readOnlyNote => null;

  /// 보고 있는 학기가 지금 기준으로 "지난 학기"/"이번 학기"/"다음 학기" 중
  /// 무엇인지(안내 문구에 쓴다).
  String get _semesterWord {
    final current = _estimateCurrentSemester(_now());
    final viewing = _year * 10 + _semester;
    final now = current.year * 10 + current.semester;
    if (viewing < now) return '지난 학기';
    if (viewing > now) return '다음 학기';
    return '이번 학기';
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
      _myTimetableStatus = MyTimetableStatus.idle;
      _catalog = [];
      _pendingSlot = null;
      _filters.clear();
    });
    // 개설과목을 먼저 확인한다. 학교가 그 학기 시간표를 아직 올리지 않았으면
    // 내 시간표도 있을 수 없으니 학교에 묻지 않고 알림창으로 알린다.
    if (_hasSession) {
      await _loadCatalog();
      if (!mounted) return;
      if (_catalogNotReady) {
        await showCatalogNotReadyDialog(
          context,
          year: _year,
          semester: _semester,
        );
        return;
      }
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
