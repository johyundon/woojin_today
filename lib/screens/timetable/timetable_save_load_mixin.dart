part of 'timetable_screen.dart';

/// 시간표 저장 다이얼로그 열기, 저장된 시간표 목록 화면 열기(불러오기) 책임.
mixin TimetableSaveLoadMixin on TimetableDataLoadingMixin {
  Future<void> _openSaveDialog() async {
    // 빈 시간표는 저장하지 않고, 과목을 먼저 담으라고 알려준다.
    if (_confirmedCourses.isEmpty) {
      await showEmptySaveDialog(context);
      return;
    }
    // 이름을 비워 두면 기존 저장분과 겹치지 않는 "시간표N"으로 저장한다.
    final existing = await _savedTimetableStorage.loadAll();
    if (!mounted) return;
    final defaultName = nextDefaultTimetableName(existing.map((t) => t.name));
    final name = await showDialog<String>(
      context: context,
      barrierColor: TimetableColors.barrier,
      builder: (_) => SaveTimetableDialog(defaultName: defaultName),
    );
    if (name == null) return;

    final saved = SavedTimetable(
      id: _now().millisecondsSinceEpoch.toString(),
      name: name,
      year: _year,
      semester: _semester,
      savedAt: _now(),
      courses: _confirmedCourses,
    );
    await _savedTimetableStorage.save(saved);
    _editStartCourses = _confirmedCourses; // 저장했으니 나갈 때 묻지 않는다.
    await _loadSavedCount();
    if (!mounted) return;
    showTopBanner(
      context,
      title: '시간표를 저장했어요',
      message: '"$name" · $_year년 $_semester학기 ${_confirmedCourses.length}과목',
      icon: Icons.check_circle_rounded,
    );
  }

  Future<void> _openSavedList() async {
    final selected = await Navigator.of(context).push<SavedTimetable>(
      MaterialPageRoute(
        builder: (_) => SavedTimetablesScreen(storage: _savedTimetableStorage),
      ),
    );
    await _loadSavedCount();
    if (selected == null || !mounted) return;
    setState(() {
      _year = selected.year;
      _semester = selected.semester;
      _confirmedCourses = selected.courses;
      _catalog = [];
      _pendingSlot = null;
      _filters.clear();
    });
    if (_hasSession) {
      _loadCatalog();
    }
  }
}
