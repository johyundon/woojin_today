part of 'timetable_screen.dart';

/// 시간표 저장 다이얼로그 열기, 저장된 시간표 목록 화면 열기(불러오기) 책임.
mixin TimetableSaveLoadMixin on TimetableDataLoadingMixin {
  Future<void> _openSaveDialog() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const SaveTimetableDialog(),
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
    await _loadSavedCount();
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
