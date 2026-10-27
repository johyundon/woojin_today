import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

import '../../theme/app_colors.dart';
import 'campus_map_colors.dart';
import 'models/campus_building.dart';
import 'models/geo_point.dart';
import 'services/campus_route_service.dart';
import 'widgets/building_detail_card.dart';
import 'widgets/building_picker_panel.dart';
import 'widgets/campus_search_bar.dart';
import 'widgets/route_info_banner.dart';

/// "연강 이동" 캠퍼스 지도 화면 (Figma 섹션 "연강", node 6:98~6:102).
///
/// 시간표 화면에서 연강 사이 "이동하기"를 눌러 들어올 때는
/// [initialOriginBuilding]/[initialDestinationBuilding]으로 출발지·목적지를
/// 미리 채운다.
class CampusMapScreen extends StatefulWidget {
  const CampusMapScreen({
    super.key,
    this.initialOriginBuilding,
    this.initialDestinationBuilding,
  });

  final String? initialOriginBuilding;
  final String? initialDestinationBuilding;

  @override
  State<CampusMapScreen> createState() => _CampusMapScreenState();
}

/// 지금 "건물 선택" 패널이 어느 칸을 채우는 중인지. [none]이면 패널이
/// 닫혀있다.
enum _PickerTarget { none, origin, destination }

class _CampusMapScreenState extends State<CampusMapScreen> {
  final _routeService = CampusRouteService();

  KakaoMapController? _mapController;
  CampusBuilding? _origin;
  CampusBuilding? _destination;
  CampusBuilding? _selectedBuilding;
  CampusRoute? _route;
  _PickerTarget _pickerTarget = _PickerTarget.none;

  // 뒤로가기 버튼 + 출발지/목적지 검색바(헤더)의 실제 렌더 높이를 측정해,
  // 경로 배너/건물 선택 패널이 기기(노치 유무 등)에 상관없이 늘 헤더
  // 바로 아래에 오도록 한다(timetable_grid_resize_mixin.dart와 같은
  // GlobalKey 실측 패턴). 측정 전엔 적당한 기본값을 쓴다.
  final _headerKey = GlobalKey();
  double _headerHeight = 72;

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
    if (_origin != null && _destination != null) {
      _fetchRoute();
    }
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

  void _onMarkerTap(String markerId) {
    final building = _findBuilding(markerId);
    if (building == null) return;
    setState(() => _selectedBuilding = building);
  }

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

  List<Marker> get _markers => campusBuildings
      .map((b) => Marker(markerId: b.name, latLng: LatLng(b.lat, b.lng)))
      .toList();

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

    return Scaffold(
      backgroundColor: CampusMapColors.background,
      body: Stack(
        children: [
          KakaoMap(
            center: _defaultCenter,
            currentLevel: 4,
            markers: _markers,
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
              child: SafeArea(
                key: _headerKey,
                bottom: false,
                // 뒤로가기 버튼과 출발지/목적지 검색바를 한 줄에 나란히 둔다.
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      Material(
                        color: AppColors.cobaltDeep,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => Navigator.of(context).pop(),
                          child: const SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 16,
                            ),
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
          // "건물 선택" 패널이 열려있는 동안엔 경로 배너/건물 상세 카드를
          // 같이 보여주면 화면이 복잡해지니 숨긴다.
          if (route != null && _pickerTarget == _PickerTarget.none)
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
          if (selected != null && _pickerTarget == _PickerTarget.none)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: KakaoMapPointerInterceptor(
                child: SafeArea(
                  top: false,
                  child: BuildingDetailCard(
                    buildingName: selected.name,
                    onClose: () => setState(() => _selectedBuilding = null),
                    onSetOrigin: _setOriginFromSelected,
                    onSetDestination: _setDestinationFromSelected,
                  ),
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
                  child: Container(color: Colors.black.withValues(alpha: 0.5)),
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
    );
  }
}
