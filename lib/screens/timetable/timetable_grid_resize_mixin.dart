part of 'timetable_screen.dart';

// 그리드 아래 핸들을 드래그해서 조절할 수 있는 그리드 뷰포트 높이의 허용 범위.
const double _minGridViewportHeight = 240;
const double _maxGridViewportHeight = 640;

// 그리드를 아무리 늘려도 검색 결과 리스트에 항상 남겨줄 최소 높이.
const double _minResultsReserve = 0;

/// 그리드 아래 핸들을 드래그해서 조절하는 그리드 뷰포트 높이 책임.
///
/// 드래그 가능한 최댓값을 계산하기 위해, 그리드를 제외한 나머지 요소들
/// (헤더~빠른실행줄, 핸들~검색바)의 실제 렌더 높이를 매 프레임 실측한다.
/// "스크롤뷰로 감싸서 넘치면 자체 스크롤" 방식은 핸들의 드래그 제스처와
/// 스크롤뷰의 드래그 제스처가 서로 경합해서(제스처 아레나 충돌) 드래그
/// 방향에 따라 번갈아 씹히는 문제가 있어 포기했다 — 대신 애초에 넘칠 수
/// 없는 값으로만 _gridViewportHeight가 움직이게 만든다.
///
/// 아래 [GlobalKey]들은 build()에서 실제 렌더 트리의 특정 위젯에 그대로
/// 붙어야 측정이 되므로, 이 믹스인으로 분리하더라도 build()는 여전히
/// 이 믹스인이 가진 바로 그 키 인스턴스를 그대로 참조해 붙인다(같은
/// State 객체의 필드이므로 분리 전후로 동일 인스턴스).
mixin TimetableGridResizeMixin on State<TimetableScreen> {
  // 그리드 아래 핸들을 드래그해서 조절하는 그리드 뷰포트 높이.
  double _gridViewportHeight = 360;

  // 드래그 가능한 최댓값을 계산하기 위해, 그리드를 제외한 나머지 요소들
  // (헤더~빠른실행줄, 핸들~검색바)의 실제 렌더 높이를 매 프레임 실측한다.
  final _chromeAboveGridKey = GlobalKey();
  final _chromeBelowGridKey = GlobalKey();
  final _gridWrapperKey = GlobalKey();
  double _chromeAboveHeight = 0;
  double _chromeBelowHeight = 0;
  // TimetableGrid 내부의 요일 라벨 행 + 여백처럼 viewportHeight에 포함되지
  // 않는 고정 높이분. 실측치에서 역산한다(그리드 자체는 고정폭 레이아웃이라
  // 이 값이 뷰포트 크기와 무관하게 항상 같다).
  double _gridChromeHeight = 0;
  double _bodyHeight = 0;

  double get _computedMaxGridViewportHeight {
    final cap =
        _bodyHeight -
        _minResultsReserve -
        _chromeAboveHeight -
        _chromeBelowHeight -
        _gridChromeHeight;
    return cap.clamp(_minGridViewportHeight, _maxGridViewportHeight);
  }

  void _scheduleChromeMeasurement(double gridViewportHeightThisBuild) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final above = _chromeAboveGridKey.currentContext?.size?.height;
      final below = _chromeBelowGridKey.currentContext?.size?.height;
      final gridWrapper = _gridWrapperKey.currentContext?.size?.height;
      if (above == null || below == null || gridWrapper == null) return;

      final gridChrome = gridWrapper - gridViewportHeightThisBuild;
      final changed =
          (above - _chromeAboveHeight).abs() > 0.5 ||
          (below - _chromeBelowHeight).abs() > 0.5 ||
          (gridChrome - _gridChromeHeight).abs() > 0.5;
      if (!changed) return;

      setState(() {
        _chromeAboveHeight = above;
        _chromeBelowHeight = below;
        _gridChromeHeight = gridChrome;
      });
    });
  }
}
