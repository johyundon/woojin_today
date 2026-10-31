part of 'timetable_screen.dart';

/// 개설과목 조회, 내 시간표 조회, 저장된 시간표 개수 로딩을 담당하는 믹스인.
mixin TimetableDataLoadingMixin on TimetableSessionMixin {
  Future<void> _loadSavedCount() async {
    final items = await _savedTimetableStorage.loadAll();
    if (!mounted) return;
    setState(() => _savedCount = items.length);
  }

  Future<void> _loadCatalog({bool forceRefresh = false}) async {
    if (!_hasSession) return;
    setState(() {
      _catalogLoading = true;
      _catalogError = null;
    });
    try {
      final catalog = await SessionCache.getCourseCatalog(
        _courseCatalogService,
        year: _year,
        semester: _semester,
        jsessionId: widget.jsessionId!,
        wmonid: widget.wmonid!,
        icKwa: '%',
        userId: widget.userId2,
        forceRefresh: forceRefresh,
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

  /// 내 시간표 응답에 과목 정보가 다 들어 있어 개설과목 조회 없이 그리드를
  /// 채운다. 결과는 [_myTimetableStatus]로 화면 아래 안내(빈 상태/실패+다시
  /// 시도)에 쓰인다.
  Future<void> _loadMyTimetable() async {
    if (!_hasFullSession) return;
    setState(() {
      _myTimetableLoading = true;
      _myTimetableStatus = MyTimetableStatus.idle;
    });
    try {
      final myTimetable = await SessionCache.getMyTimetable(
        _myTimetableService,
        year: _year,
        semester: _semester,
        jsessionId: widget.jsessionId!,
        wmonid: widget.wmonid!,
        userId2: widget.userId2!,
      );
      if (!mounted) return;
      setState(() {
        _confirmedCourses = myTimetable.courses
            .map(PlannedCourse.fromCatalogItem)
            .toList();
        _myTimetableLoading = false;
        _myTimetableStatus = myTimetable.courses.isEmpty
            ? MyTimetableStatus.empty
            : MyTimetableStatus.idle;
      });
    } catch (e) {
      debugPrint('[Timetable] 내 시간표 조회 실패: $e');
      if (!mounted) return;
      setState(() {
        _myTimetableLoading = false;
        _myTimetableStatus = MyTimetableStatus.failed;
      });
    }
  }
}
