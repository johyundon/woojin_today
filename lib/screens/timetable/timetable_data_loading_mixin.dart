part of 'timetable_screen.dart';

/// 개설과목 조회, 내 시간표 조회, 저장된 시간표 개수 로딩을 담당하는 믹스인.
mixin TimetableDataLoadingMixin on TimetableSessionMixin {
  Future<void> _loadSavedCount() async {
    final items = await _savedTimetableStorage.loadAll();
    if (!mounted) return;
    setState(() => _savedCount = items.length);
  }

  Future<void> _loadCatalog() async {
    if (!_hasSession) return;
    setState(() {
      _catalogLoading = true;
      _catalogError = null;
    });
    try {
      final catalog = await _courseCatalogService.fetchCourseCatalog(
        year: _year,
        semester: _semester,
        jsessionId: widget.jsessionId!,
        wmonid: widget.wmonid!,
        icKwa: '%',
        userId: widget.userId2,
      );
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _catalogLoading = false;
      });
    } on CourseCatalogException catch (e) {
      if (!mounted) return;
      setState(() {
        _catalogLoading = false;
        _catalogError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _catalogLoading = false;
        _catalogError = '개설과목을 불러오지 못했어요.';
      });
    }
  }

  Future<void> _loadMyTimetable() async {
    if (!_hasFullSession) return;
    setState(() => _myTimetableLoading = true);
    try {
      final catalog = _catalog.isNotEmpty
          ? _catalog
          : await _courseCatalogService.fetchCourseCatalog(
              year: _year,
              semester: _semester,
              jsessionId: widget.jsessionId!,
              wmonid: widget.wmonid!,
              icKwa: '%',
              userId: widget.userId2,
            );
      final myTimetable = await _myTimetableService.fetchMyTimetable(
        year: _year,
        semester: _semester,
        jsessionId: widget.jsessionId!,
        wmonid: widget.wmonid!,
        userId2: widget.userId2!,
      );
      final matched = matchEnrolledCourses(
        catalog: catalog,
        myTimetable: myTimetable,
      );
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _confirmedCourses = matched.courses
            .map(PlannedCourse.fromCatalogItem)
            .toList();
        _myTimetableLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _myTimetableLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('내 시간표를 불러오지 못했어요.')));
    }
  }
}
