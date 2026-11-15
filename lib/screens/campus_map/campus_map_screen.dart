import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

import '../../services/class_schedule_parser.dart';
import '../../services/session_cache.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pressable.dart';
import '../../widgets/top_banner.dart';
import 'campus_map_colors.dart';
import 'campus_map_search_screen.dart';
import 'models/campus_building.dart';
import 'models/geo_point.dart';
import 'services/campus_route_service.dart';
import 'services/current_location_service.dart';
import 'widgets/building_detail_card.dart';
import 'widgets/building_picker_panel.dart';
import 'widgets/building_sheet.dart';
import 'widgets/campus_map_top_bar.dart';
import 'widgets/campus_search_bar.dart';
import 'widgets/route_info_banner.dart';

/// "연강 이동" 캠퍼스 지도 화면 (Figma 섹션 "연강", node 6:98~6:102).
///
/// 시간표 화면에서 연강 사이 "이동하기"를 눌러 들어올 때는
/// [initialOriginBuilding]/[initialDestinationBuilding]으로 출발지·목적지를
/// 미리 채운다. 검색에서 건물을 골라 들어올 때는 [initialSelectedBuilding]으로
/// 그 건물을 가운데 두고 선택한 상태로 연다.
class CampusMapScreen extends StatefulWidget {
  const CampusMapScreen({
    super.key,
    this.initialOriginBuilding,
    this.initialDestinationBuilding,
    this.initialSelectedBuilding,
  });

  final String? initialOriginBuilding;
  final String? initialDestinationBuilding;
  final String? initialSelectedBuilding;

  @override
  State<CampusMapScreen> createState() => _CampusMapScreenState();
}

/// 지금 "건물 선택" 패널이 어느 칸을 채우는 중인지. [none]이면 패널이
/// 닫혀있다.
enum _PickerTarget { none, origin, destination }

/// 건물 핀을 지도에 그릴지. 사용자 요청으로 지금은 숨겨 두었다(핀 만드는
/// 코드와 핀을 눌렀을 때 처리는 다시 켤 때를 위해 남겨 둔다).
const bool _showBuildingPins = false;

class _CampusMapScreenState extends State<CampusMapScreen> {
  final _routeService = CampusRouteService();
  final _locationService = const CurrentLocationService();

  KakaoMapController? _mapController;
  CampusBuilding? _origin;
  CampusBuilding? _destination;
  CampusBuilding? _selectedBuilding;
  CampusRoute? _route;
  _PickerTarget _pickerTarget = _PickerTarget.none;

  /// 기기의 현재 위치. 권한이 없거나 못 읽었으면 null(파란 점을 안 그린다).
  GeoPoint? _myLocation;

  /// 현재 위치 → 고른 건물까지 걷는 경로(시트의 "걸어서 N분"에 쓴다).
  CampusRoute? _walkToSelected;

  /// 현재 위치 버튼을 눌러 위치를 읽는 중이면 true(버튼에 빙글이를 띄운다).
  bool _locating = false;

  /// 위쪽 카테고리 칩 중 고른 것.
  int? _selectedCategory;

  /// 시간표에서 "이동하기"로 들어와 출발지·목적지를 고르는 중이면 true.
  /// 이때는 예전 출발지/목적지 검색바를 그대로 쓴다(길안내 화면은 아직 시안
  /// 반영 전).
  bool get _isRouteMode => _origin != null || _destination != null;

  // 뒤로가기 버튼 + 출발지/목적지 검색바(헤더)의 실제 렌더 높이를 측정해,
  // 경로 배너/건물 선택 패널이 기기(노치 유무 등)에 상관없이 늘 헤더
  // 바로 아래에 오도록 한다(timetable_grid_resize_mixin.dart와 같은
  // GlobalKey 실측 패턴). 측정 전엔 적당한 기본값을 쓴다.
  final _headerKey = GlobalKey();
  double _headerHeight = 120;

  void _scheduleHeaderMeasurement() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final height = _headerKey.currentContext?.size?.height;
      if (height == null || (height - _headerHeight).abs() < 0.5) return;
      setState(() => _headerHeight = height);
    });
  }

  @override
  void initState() {
    super.initState();
    _origin = _findBuilding(widget.initialOriginBuilding);
    _destination = _findBuilding(widget.initialDestinationBuilding);
    _selectedBuilding = _findBuilding(widget.initialSelectedBuilding);
    if (_origin != null && _destination != null) {
      _fetchRoute();
    }
    _loadMyLocation();
  }

  /// 현재 위치를 읽어 파란 점을 갱신한다. [moveCamera]면(현재 위치 버튼)
  /// 지도도 그 자리로 옮기고, 못 읽으면 안내 배너를 띄운다.
  Future<void> _loadMyLocation({bool moveCamera = false}) async {
    if (moveCamera) {
      if (_locating) return;
      // 이미 아는 위치가 있으면 기다리지 않고 바로 옮긴 뒤, 새 위치로 고친다.
      final known = _myLocation;
      if (known != null) {
        _mapController?.panTo(LatLng(known.lat, known.lng));
      }
      setState(() => _locating = true);
    }
    final location = await _locationService.current();
    if (!mounted) return;
    if (moveCamera) setState(() => _locating = false);
    if (location == null) {
      if (moveCamera) {
        showTopBanner(
          context,
          title: '현재 위치를 알 수 없어요',
          message: '설정에서 위치 권한을 켜 주세요.',
          icon: Icons.location_off_rounded,
        );
      }
      return;
    }
    setState(() => _myLocation = location);
    if (moveCamera) {
      await _mapController?.panTo(LatLng(location.lat, location.lng));
    }
    await _updateWalkToSelected();
  }

  /// 현재 위치와 고른 건물이 둘 다 있으면 걷는 경로를 다시 구한다.
  Future<void> _updateWalkToSelected() async {
    final from = _myLocation;
    final building = _selectedBuilding;
    if (from == null || building == null) {
      setState(() => _walkToSelected = null);
      return;
    }
    final route = await _routeService.findRoute(
      origin: from,
      destination: GeoPoint(lat: building.lat, lng: building.lng),
    );
    // 기다리는 사이 다른 건물을 골랐으면 버린다.
    if (!mounted || _selectedBuilding != building) return;
    setState(() => _walkToSelected = route);
  }

  CampusBuilding? _findBuilding(String? name) {
    if (name == null) return null;
    for (final building in campusBuildings) {
      if (building.name == name) return building;
    }
    return null;
  }

  Future<void> _fetchRoute() async {
    final origin = _origin;
    final destination = _destination;
    if (origin == null || destination == null) {
      setState(() => _route = null);
      return;
    }

    final route = await _routeService.findRoute(
      origin: GeoPoint(lat: origin.lat, lng: origin.lng),
      destination: GeoPoint(lat: destination.lat, lng: destination.lng),
    );
    if (!mounted) return;
    setState(() => _route = route);

    await _mapController?.fitBounds(
      route.path.map((g) => LatLng(g.lat, g.lng)).toList(),
      padding: 80,
    );
  }

  void _openOriginPicker() {
    setState(() => _pickerTarget = _PickerTarget.origin);
  }

  void _openDestinationPicker() {
    setState(() => _pickerTarget = _PickerTarget.destination);
  }

  void _closePicker() {
    setState(() => _pickerTarget = _PickerTarget.none);
  }

  Future<void> _onBuildingPicked(String name) async {
    final target = _pickerTarget;
    final building = _findBuilding(name);
    setState(() {
      if (target == _PickerTarget.origin) {
        _origin = building;
      } else if (target == _PickerTarget.destination) {
        _destination = building;
      }
      _pickerTarget = _PickerTarget.none;
      _selectedBuilding = null;
    });
    await _fetchRoute();
  }

  /// 검색 화면(시안 2번)을 연다. 건물을 고르면 그 건물을 아래 시트에,
  /// "오늘 수업 길찾기"를 고르면 출발지 → 도착지 길을 지도에 그린다.
  Future<void> _openSearch() async {
    final now = DateTime.now();
    final courses = SessionCache.lastMyTimetable?.courses ?? const [];
    final result = await Navigator.of(context).push<CampusSearchResult>(
      MaterialPageRoute(
        builder: (_) => CampusMapSearchScreen(
          todayClasses: todayClasses(courses: courses, now: now),
          now: now,
        ),
      ),
    );
    if (!mounted || result == null) return;
    final origin = result.origin;
    if (origin == null) {
      _selectBuilding(result.destination);
      return;
    }
    setState(() {
      _origin = origin;
      _destination = result.destination;
      _selectedBuilding = null;
    });
    await _fetchRoute();
  }

  /// 기본 화면에서 건물을 고른다 — 지도를 그 건물로 옮기고, 그려 둔 길은
  /// 지우고, 걷는 거리를 다시 구한다.
  void _selectBuilding(CampusBuilding? building) {
    setState(() {
      _pickerTarget = _PickerTarget.none;
      _selectedBuilding = building;
      _walkToSelected = null;
      _route = null;
    });
    if (building == null) return;
    _mapController?.panTo(LatLng(building.lat, building.lng));
    _updateWalkToSelected();
  }

  /// "길 알려줘" — 현재 위치에서 고른 건물까지 길을 지도에 그린다.
  Future<void> _showDirections() async {
    if (_myLocation == null) {
      showTopBanner(
        context,
        title: '현재 위치를 알 수 없어요',
        message: '위치 권한을 켜면 지금 있는 곳에서 가는 길을 그려 드려요.',
        icon: Icons.location_off_rounded,
      );
      return;
    }
    if (_walkToSelected == null) await _updateWalkToSelected();
    final route = _walkToSelected;
    if (!mounted || route == null) return;
    setState(() => _route = route);
    await _mapController?.fitBounds(
      route.path.map((g) => LatLng(g.lat, g.lng)).toList(),
      padding: 80,
    );
  }

  void _showFloorGuidePending() {
    showTopBanner(
      context,
      title: '층별 안내는 준비 중이에요',
      message: '건물별 층 정보를 모으는 중이에요.',
      icon: Icons.layers_rounded,
    );
  }

  void _onMarkerTap(String markerId) {
    final building = _findBuilding(markerId);
    if (building == null) return;
    // 기본 화면(칩으로 띄운 핀)이면 아래 시트로 보여 준다.
    if (!_isRouteMode) {
      _selectBuilding(building);
      return;
    }
    setState(() => _selectedBuilding = building);
  }

  /// 칩을 누르면 그 종류 장소만 핀으로 띄우고 다 보이게 지도를 맞춘다.
  /// 같은 칩을 다시 누르면 끈다.
  Future<void> _onCategoryTap(int index) async {
    final selected = _selectedCategory == index ? null : index;
    setState(() => _selectedCategory = selected);
    if (selected == null) return;
    final points = [
      for (final b in _categoryPlaces(selected)) LatLng(b.lat, b.lng),
    ];
    if (points.length == 1) {
      await _mapController?.panTo(points.first);
    } else if (points.isNotEmpty) {
      await _mapController?.fitBounds(points, padding: 80);
    }
  }

  List<CampusBuilding> _categoryPlaces(int index) => [
    for (final name in campusMapCategories[index].places) ?_findBuilding(name),
  ];

  Future<void> _setOriginFromSelected() async {
    final building = _selectedBuilding;
    if (building == null) return;
    setState(() {
      _origin = building;
      _selectedBuilding = null;
    });
    await _fetchRoute();
  }

  Future<void> _setDestinationFromSelected() async {
    final building = _selectedBuilding;
    if (building == null) return;
    setState(() {
      _destination = building;
      _selectedBuilding = null;
    });
    await _fetchRoute();
  }

  void _reset() {
    setState(() {
      _origin = null;
      _destination = null;
      _route = null;
      _selectedBuilding = null;
    });
  }

  /// 모든 건물 좌표의 평균 — 지도 초기 중심.
  LatLng get _defaultCenter {
    final avgLat =
        campusBuildings.map((b) => b.lat).reduce((a, b) => a + b) /
        campusBuildings.length;
    final avgLng =
        campusBuildings.map((b) => b.lng).reduce((a, b) => a + b) /
        campusBuildings.length;
    return LatLng(avgLat, avgLng);
  }

  /// 처음 지도 중심. 고른 건물이 있으면 그 건물, 없으면 [_defaultCenter].
  late final LatLng _initialCenter = switch (_selectedBuilding) {
    final b? => LatLng(b.lat, b.lng),
    null => _defaultCenter,
  };

  /// 칩을 골랐으면 그 종류 장소의 핀, 아니면(전체 핀은 숨김) 핀 없음.
  List<Marker>? get _markers {
    final category = _selectedCategory;
    final places = category != null
        ? _categoryPlaces(category)
        : (_showBuildingPins ? campusBuildings : null);
    return places
        ?.map((b) => Marker(markerId: b.name, latLng: LatLng(b.lat, b.lng)))
        .toList();
  }

  /// 현재 위치 파란 점(옅은 원 위에 흰 테두리 점).
  List<CustomOverlay>? get _customOverlays {
    final location = _myLocation;
    if (location == null) return null;
    return [
      CustomOverlay(
        customOverlayId: 'my_location',
        latLng: LatLng(location.lat, location.lng),
        yAnchor: 0.5,
        zIndex: 10,
        content:
            '<div style="width:28px;height:28px;border-radius:50%;'
            'background:rgba(10,120,230,0.18);display:flex;'
            'align-items:center;justify-content:center;">'
            '<div style="width:14px;height:14px;border-radius:50%;'
            'background:#0A78E6;border:3px solid #fff;'
            'box-shadow:0 1px 4px rgba(0,0,0,0.3);"></div></div>',
      ),
    ];
  }

  List<Polyline>? get _polylines {
    final route = _route;
    if (route == null) return null;
    return [
      Polyline(
        polylineId: 'route',
        points: route.path.map((g) => LatLng(g.lat, g.lng)).toList(),
        strokeColor: CampusMapColors.accent,
        strokeWidth: 5,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final route = _route;
    final selected = _selectedBuilding;
    _scheduleHeaderMeasurement();

    // 위쪽 검색 영역이 흰색이라 상태 표시줄 글자를 어둡게 한다.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: CampusMapColors.background,
        body: Stack(
          children: [
            KakaoMap(
              center: _initialCenter,
              currentLevel: 4,
              markers: _markers,
              customOverlays: _customOverlays,
              polylines: _polylines,
              onMapCreated: (controller) => _mapController = controller,
              onMarkerTap: (markerId, latLng, zoomLevel) =>
                  _onMarkerTap(markerId),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: KakaoMapPointerInterceptor(
                // 상태 표시줄까지 덮는 흰 영역(아래 모서리만 둥글게).
                child: Container(
                  key: _headerKey,
                  decoration: const BoxDecoration(
                    color: CampusMapColors.surface,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                    boxShadow: CampusMapColors.headerShadow,
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      child: !_isRouteMode
                          ? CampusMapTopBar(
                              onBack: () => Navigator.of(context).pop(),
                              onTapSearch: _openSearch,
                              selectedCategory: _selectedCategory,
                              onCategoryTap: _onCategoryTap,
                            )
                          // 뒤로가기 버튼과 출발지/목적지 검색바를 한 줄에 나란히 둔다.
                          : Row(
                              children: [
                                Pressable.icon(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.fill,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: AppColors.textStrong,
                                      size: 15,
                                      semanticLabel: '뒤로',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: CampusSearchBar(
                                    originName: _origin?.name,
                                    destinationName: _destination?.name,
                                    onTapOrigin: _openOriginPicker,
                                    onTapDestination: _openDestinationPicker,
                                    onReset: _reset,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
            // "건물 선택" 패널이 열려있는 동안엔 경로 배너/건물 상세 카드를
            // 같이 보여주면 화면이 복잡해지니 숨긴다.
            if (route != null &&
                _isRouteMode &&
                _pickerTarget == _PickerTarget.none)
              Positioned(
                top: _headerHeight,
                left: 0,
                right: 0,
                child: KakaoMapPointerInterceptor(
                  child: Center(
                    child: RouteInfoBanner(
                      walkMinutes: route.walkMinutes,
                      distanceMeters: route.distanceMeters,
                    ),
                  ),
                ),
              ),
            if (!_isRouteMode && _pickerTarget == _PickerTarget.none)
              Positioned(
                left: 12,
                right: 12,
                // 홈 바(화면 아래 안전 영역) 위로 띄운다.
                bottom: MediaQuery.paddingOf(context).bottom + 20,
                child: KakaoMapPointerInterceptor(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _MyLocationButton(
                        loading: _locating,
                        onTap: () => _loadMyLocation(moveCamera: true),
                      ),
                      if (selected != null) ...[
                        const SizedBox(height: 20),
                        BuildingSheet(
                          buildingName: selected.name,
                          walkMinutes: _walkToSelected?.walkMinutes,
                          distanceMeters: _walkToSelected?.distanceMeters,
                          onFloorGuide: _showFloorGuidePending,
                          onDirections: _showDirections,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            // 핀을 다시 켜고 길안내 중에 핀을 누르면 예전 카드를 쓴다.
            if (_isRouteMode &&
                selected != null &&
                _pickerTarget == _PickerTarget.none)
              Positioned(
                left: 10,
                right: 10,
                bottom: 22,
                child: KakaoMapPointerInterceptor(
                  child: BuildingDetailCard(
                    buildingName: selected.name,
                    onClose: () => setState(() => _selectedBuilding = null),
                    onSetOrigin: _setOriginFromSelected,
                    onSetDestination: _setDestinationFromSelected,
                  ),
                ),
              ),
            if (_pickerTarget != _PickerTarget.none) ...[
              // 패널이 열려있는 동안 지도를 어둡게 깔아 패널에 시선이 가도록
              // 하고, 이 영역을 탭하면 패널이 닫힌다.
              Positioned.fill(
                child: KakaoMapPointerInterceptor(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _closePicker,
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: _headerHeight,
                left: 16,
                right: 16,
                child: KakaoMapPointerInterceptor(
                  child: BuildingPickerPanel(onSelected: _onBuildingPicked),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 지도 오른쪽의 현재 위치 버튼(흰 둥근 네모 + 조준 아이콘).
class _MyLocationButton extends StatelessWidget {
  const _MyLocationButton({required this.onTap, required this.loading});

  final VoidCallback onTap;

  /// 위치를 읽는 중이면 아이콘 대신 빙글이를 보여 준다.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Pressable.icon(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: CampusMapColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppColors.cardShadow,
        ),
        child: loading
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: CampusMapColors.accent,
                ),
              )
            : const Icon(
                Icons.my_location_rounded,
                color: CampusMapColors.accent,
                size: 24,
                semanticLabel: '현재 위치로 이동',
              ),
      ),
    );
  }
}
