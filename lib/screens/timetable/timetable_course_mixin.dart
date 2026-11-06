part of 'timetable_screen.dart';

/// 빈 셀 탭, 과목 추가, AI 시간표 자동 생성 진입 등 확정 과목
/// 목록(_confirmedCourses)을 직접 조작하는 책임.
mixin TimetableCourseMixin on TimetableSessionMixin {
  void _onEmptyCellTap(Weekday day, int startHour) {
    setState(() => _pendingSlot = PendingSlot(day: day, startHour: startHour));
  }

  void _clearPendingSlot() {
    setState(() => _pendingSlot = null);
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

  /// 그리드 위 반짝이(AI) 버튼 — 5단계 설문([AiRecommendWizardScreen])으로
  /// 이동한다. 실제 추천 생성은 [_onAiRecommendSubmit]에서 처리한다.
  void _openAiRecommendWizard() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AiRecommendWizardScreen(onSubmit: _onAiRecommendSubmit),
      ),
    );
  }

  /// 설문 5단계 "시간표 만들기"를 눌렀을 때 호출된다. 답변으로 후보
  /// 시간표를 만들어 결과 화면([AiRecommendResultScreen])으로 넘어간다.
  Future<void> _onAiRecommendSubmit(
    BuildContext stepContext,
    AiRecommendAnswers answers,
  ) async {
    if (_catalog.isEmpty) {
      ScaffoldMessenger.of(stepContext)
          .showSnackBar(const SnackBar(content: Text('추천할 개설과목 데이터가 없어요.')));
      return;
    }

    final profile = await _loadAiRecommendProfile();
    if (!stepContext.mounted) return;

    await Navigator.of(stepContext).push(
      MaterialPageRoute(
        builder: (_) => AiRecommendResultScreen(
          candidates: generateTimetableCandidates(
            catalog: _catalog,
            answers: answers,
            profile: profile,
          ),
          answers: answers,
          onRegenerate: () async => generateTimetableCandidates(
            catalog: _catalog,
            answers: answers,
            profile: profile,
          ),
          onConfirm: (chosen) {
            setState(() => _confirmedCourses = chosen);
            // 결과 화면 + 설문 화면을 모두 닫고 시간표 화면으로 돌아간다.
            Navigator.of(context).pop();
            Navigator.of(context).pop();
            showTopBanner(
              context,
              title: '우진이',
              message: '${chosen.length}과목으로 시간표를 채웠어요.',
            );
          },
        ),
      ),
    );
  }

  /// 자동 생성이 참고할 내 학과 전공 목록과 학년. 학생 정보는 홈에서 이미
  /// 불러와 저장돼 있어 보통 새 요청이 없고, 학과별 개설과목은 학기마다 한
  /// 번만 학교에 묻고 기기에 저장한다. 못 구하면 학과·학년을 가리지 않는다.
  Future<AiRecommendProfile> _loadAiRecommendProfile() async {
    final userId2 = widget.userId2;
    if (!_hasFullSession || userId2 == null) {
      return const AiRecommendProfile();
    }
    try {
      final info = await SessionCache.getStudentInfo(
        widget.studentInfoService ?? ServiceFactory.studentInfo(),
        userId2: userId2,
      );
      final grade = int.tryParse(
        RegExp(r'[1-4]').firstMatch(info.grade ?? '')?.group(0) ?? '',
      );
      final deptName = matchDepartmentName(info.department);
      final deptCode = deptName == null ? null : kDepartmentCodes[deptName];
      Set<String>? majors;
      if (deptCode != null) {
        final dept = await SessionCache.getCourseCatalog(
          _courseCatalogService,
          year: _year,
          semester: _semester,
          jsessionId: widget.jsessionId!,
          wmonid: widget.wmonid!,
          icKwa: 'B41005',
          icKwa1: deptCode,
          userId: userId2,
        );
        if (dept.isNotEmpty) majors = {for (final i in dept) i.courseCode};
      }
      return AiRecommendProfile(myMajorCourseCodes: majors, myGrade: grade);
    } catch (e) {
      debugPrint('[AiRecommend] 내 학과·학년 읽기 실패: $e');
      return const AiRecommendProfile();
    }
  }
}
