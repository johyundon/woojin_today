import 'dart:math' as math;

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
import 'models/route_classes.dart';
import 'services/campus_route_service.dart';
import 'services/current_location_service.dart';
import 'widgets/building_detail_card.dart';
import 'widgets/building_picker_panel.dart';
import 'widgets/building_endpoint_sheet.dart';
import 'widgets/campus_map_top_bar.dart';
import 'widgets/campus_route_header.dart';

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
    this.initialRouteClasses,
  });

  final String? initialOriginBuilding;
  final String? initialDestinationBuilding;
  final String? initialSelectedBuilding;

  /// 연강 이동으로 들어올 때 앞·뒤 수업. 있으면 길안내 카드에 수업명·시각,
  /// 아래 시트에 여유 시간을 보여 준다.
  final RouteClasses? initialRouteClasses;

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

  /// 출발점·도착점이 건물 대신 "내 위치"인지. true면 그 칸의 건물은 null이다.
  bool _originIsMe = false;
  bool _destinationIsMe = false;
  CampusBuilding? _selectedBuilding;
  CampusRoute? _route;
  _PickerTarget _pickerTarget = _PickerTarget.none;

  /// 기기의 현재 위치. 권한이 없거나 못 읽었으면 null(파란 점을 안 그린다).
  GeoPoint? _myLocation;

  /// 현재 위치 버튼을 눌러 위치를 읽는 중이면 true(버튼에 빙글이를 띄운다).
  bool _locating = false;

  /// 지도 빈 곳을 눌러 아래 시트를 접었으면 true. 출발·도착이나 고른
  /// 건물이 바뀌면 다시 편다.
  bool _sheetHidden = false;

  /// 위쪽 카테고리 칩 중 고른 것.
  int? _selectedCategory;

  /// 길안내 중인 두 수업(연강). 출발지·도착지를 직접 바꾸면 지운다.
  RouteClasses? _routeClasses;

  /// 출발지·도착지를 고르는 길안내 화면(시안 3번)이면 true.
  bool get _isRouteMode =>
      _origin != null ||
      _destination != null ||
      _originIsMe ||
      _destinationIsMe;

  /// 출발점·도착점의 좌표. "내 위치"인데 위치를 아직 모르면 null.
  GeoPoint? get _originPoint => _originIsMe ? _myLocation : _pointOf(_origin);
  GeoPoint? get _destinationPoint =>
      _destinationIsMe ? _myLocation : _pointOf(_destination);

  GeoPoint? _pointOf(CampusBuilding? b) =>
      b == null ? null : GeoPoint(lat: b.lat, lng: b.lng);

  /// 카드·시트에 쓸 출발점·도착점 이름.
  String? get _originLabel => _originIsMe ? '내 위치' : _origin?.name;
  String? get _destinationLabel =>
      _destinationIsMe ? '내 위치' : _destination?.name;

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
    _routeClasses = widget.initialRouteClasses;
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
    // 출발·도착이 "내 위치"인데 위치를 몰라 길을 못 그렸으면 이제 그린다.
    if ((_originIsMe || _destinationIsMe) && _route == null) {
      await _fetchRoute();
    }
    if (moveCamera) {
      await _mapController?.panTo(LatLng(location.lat, location.lng));
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
    final origin = _originPoint;
    final destination = _destinationPoint;
    setState(() => _sheetHidden = false);
    if (origin == null || destination == null) {
      setState(() => _route = null);
      return;
    }

    final route = await _routeService.findRoute(
      origin: origin,
      destination: destination,
    );
    if (!mounted) return;
    setState(() => _route = route);
    await _fitRoute(route);
  }

  /// 길 전체가 위쪽 출발·도착 카드와 아래 시트 사이 빈 곳에 보이도록 지도를
  /// 맞춘다(위·아래 여백을 따로 줘야 카드·시트에 길 끝이 가리지 않는다).
  Future<void> _fitRoute(CampusRoute route) async {
    if (route.path.isEmpty) return;
    var minLat = route.path.first.lat, maxLat = minLat;
    var minLng = route.path.first.lng, maxLng = minLng;
    for (final p in route.path) {
      if (p.lat < minLat) minLat = p.lat;
      if (p.lat > maxLat) maxLat = p.lat;
      if (p.lng < minLng) minLng = p.lng;
      if (p.lng > maxLng) maxLng = p.lng;
    }
    final insets = MediaQuery.paddingOf(context);
    // 화면이 막 바뀐 직후엔 헤더 높이 실측값이 기본 화면 것일 수 있어, 출발·
    // 도착 카드 높이(약 160) 이상은 늘 비워 둔다.
    final topInset = math.max(_headerHeight, insets.top + 160);
    await _mapController?.setBounds(
      LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng)),
      (topInset + 40).round(),
      48,
      // 아래 시트(약 190) + 홈 바.
      (insets.bottom + 240).round(),
      48,
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
        _originIsMe = false;
      } else if (target == _PickerTarget.destination) {
        _destination = building;
        _destinationIsMe = false;
      }
      _pickerTarget = _PickerTarget.none;
      _selectedBuilding = null;
      _routeClasses = null;
    });
    await _fetchRoute();
  }

  /// 건물 고르기 목록에서 "내 위치"를 골랐을 때.
  Future<void> _onMyLocationPicked() async {
    final target = _pickerTarget;
    setState(() {
      if (target == _PickerTarget.origin) {
        _origin = null;
        _originIsMe = true;
      } else if (target == _PickerTarget.destination) {
        _destination = null;
        _destinationIsMe = true;
      }
      _pickerTarget = _PickerTarget.none;
      _routeClasses = null;
    });
    if (_myLocation == null) await _loadMyLocation(moveCamera: true);
    await _fetchRoute();
  }

  /// 출발점과 도착점을 바꾼다(수업 시각은 맞지 않게 되니 지운다).
  Future<void> _swapEndpoints() async {
    setState(() {
      final origin = _origin;
      _origin = _destination;
      _destination = origin;
      final originIsMe = _originIsMe;
      _originIsMe = _destinationIsMe;
      _destinationIsMe = originIsMe;
      _routeClasses = null;
    });
    await _fetchRoute();
  }

  /// 위 출발 칸 끝 X — 출발만 비운다(둘 다 비면 기본 화면으로 돌아간다).
  Future<void> _clearOrigin() async {
    setState(() {
      _origin = null;
      _originIsMe = false;
      _routeClasses = null;
    });
    await _fetchRoute();
  }

  /// 위 도착 칸 끝 X — 도착만 비운다.
  Future<void> _clearDestination() async {
    setState(() {
      _destination = null;
      _destinationIsMe = false;
      _routeClasses = null;
    });
    await _fetchRoute();
  }

  /// "길 안내" — 출발할 자리(현재 위치, 없으면 출발점)로 지도를 크게 당긴다.
  /// 걸음마다 알려 주는 안내는 아직 없다.
  Future<void> _startGuidance() async {
    final start = _myLocation ?? _originPoint;
    if (start == null) return;
    await _mapController?.setLevel(2);
    await _mapController?.panTo(LatLng(start.lat, start.lng));
  }

  /// 길안내 화면의 뒤로가기. 시간표에서 바로 길안내로 들어왔으면 지도를
  /// 닫고, 지도 안에서 길안내로 넘어왔으면 기본 화면으로 돌아간다.
  void _onRouteBack() {
    if (widget.initialOriginBuilding != null ||
        widget.initialDestinationBuilding != null) {
      Navigator.of(context).pop();
      return;
    }
    _reset();
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
      _originIsMe = false;
      _destinationIsMe = false;
      _routeClasses = result.classes;
      _selectedBuilding = null;
    });
    await _fetchRoute();
  }

  /// 기본 화면에서 건물을 고른다 — 지도를 그 건물로 옮기고(핀과 아래
  /// 출발·도착 시트가 뜬다), 그려 둔 길은 지운다.
  void _selectBuilding(CampusBuilding? building) {
    setState(() {
      _pickerTarget = _PickerTarget.none;
      _selectedBuilding = building;
      _sheetHidden = false;
      _route = null;
    });
    if (building == null) return;
    _mapController?.panTo(LatLng(building.lat, building.lng));
  }

  /// 시트의 "도착" — 길안내 화면으로 넘어간다. 출발점은 내 위치, 도착점은
  /// 고른 건물. 위치를 모르면 출발 칸을 비워 둔다(팝업은 띄우지 않는다).
  Future<void> _showDirections() async {
    final building = _selectedBuilding;
    if (building == null) return;
    final knowsLocation = _myLocation != null;
    setState(() {
      _origin = null;
      _originIsMe = knowsLocation;
      _destination = building;
      _destinationIsMe = false;
      _selectedBuilding = null;
      _routeClasses = null;
    });
    await _fetchRoute();
  }

  /// 시트의 "출발" — 고른 건물을 출발점으로 길안내 화면으로 넘어간다.
  /// 도착은 위 입력칸을 누르거나 지도에서 건물을 눌러 고른다.
  Future<void> _startFromSelected() async {
    final building = _selectedBuilding;
    if (building == null) return;
    setState(() {
      _origin = building;
      _originIsMe = false;
      _destination = null;
      _destinationIsMe = false;
      _selectedBuilding = null;
      _routeClasses = null;
    });
    await _fetchRoute();
  }

  /// 지도에서 건물 자리를 누르면 차례대로 출발 → 도착으로 정한다.
  /// - 출발이 비어 있으면(기본 화면 포함) 누른 건물이 출발.
  /// - 출발만 있으면 누른 건물이 도착, 바로 길을 그린다.
  /// - 둘 다 있으면 누른 건물을 새 출발로 다시 시작한다.
  /// 건물에서 먼 곳을 누르면 아래 시트만 접는다.
  Future<void> _onMapTap(LatLng latLng) async {
    if (_pickerTarget != _PickerTarget.none) return;
    final building = nearestCampusBuilding(
      GeoPoint(lat: latLng.latitude, lng: latLng.longitude),
    );
    if (building == null) {
      // 건물이 아닌 곳을 누르면 아래 시트를 접어 지도를 넓게 보여 준다.
      setState(() => _sheetHidden = true);
      return;
    }
    final hasOrigin = _origin != null || _originIsMe;
    final hasDestination = _destination != null || _destinationIsMe;
    // 출발 건물을 한 번 더 누른 것(두 번 톡톡 포함)은 도착으로 치지 않는다.
    if (hasOrigin && !hasDestination && building == _origin) return;
    setState(() {
      if (hasOrigin && !hasDestination) {
        _destination = building;
        _destinationIsMe = false;
      } else if (!hasOrigin && hasDestination) {
        _origin = building;
        _originIsMe = false;
      } else {
        _origin = building;
        _originIsMe = false;
        _destination = null;
        _destinationIsMe = false;
      }
      _selectedBuilding = null;
      _routeClasses = null;
    });
    await _fetchRoute();
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
      _originIsMe = false;
      _destinationIsMe = false;
      _route = null;
      _selectedBuilding = null;
      _routeClasses = null;
      _sheetHidden = false;
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
    final category = _isRouteMode ? null : _selectedCategory;
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
    // 길안내 중이면 건물인 출발점엔 흰 테두리 원, 도착점엔 핀을 그린다
    // ("내 위치"인 칸은 아래 파란 점이 대신한다).
    final start = _isRouteMode && !_originIsMe ? _originPoint : null;
    final end = _isRouteMode && !_destinationIsMe ? _destinationPoint : null;
    // 기본 화면에서 고른 건물엔 파란 마름모 핀(학사모 아이콘)을 띄운다.
    final picked = _isRouteMode ? null : _selectedBuilding;
    final marks = [
      if (picked != null)
        CustomOverlay(
          customOverlayId: 'selected_building',
          latLng: LatLng(picked.lat, picked.lng),
          yAnchor: 1,
          zIndex: 9,
          content: _selectedPinHtml,
        ),
      if (start != null)
        CustomOverlay(
          customOverlayId: 'route_start',
          latLng: LatLng(start.lat, start.lng),
          yAnchor: 0.5,
          zIndex: 9,
          content:
              '<div style="width:14px;height:14px;border-radius:50%;'
              'background:#fff;border:5px solid #0A78E6;'
              'box-shadow:0 1px 4px rgba(0,0,0,0.3);"></div>',
        ),
      if (end != null)
        CustomOverlay(
          customOverlayId: 'route_end',
          latLng: LatLng(end.lat, end.lng),
          yAnchor: 1,
          zIndex: 9,
          content:
              '<div style="padding-bottom:4px;">'
              '<div style="width:28px;height:28px;'
              'border-radius:50% 50% 50% 0;background:#0A78E6;'
              'transform:rotate(-45deg);border:3px solid #fff;'
              'box-shadow:0 2px 6px rgba(0,0,0,0.3);display:flex;'
              'align-items:center;justify-content:center;">'
              '<div style="width:9px;height:9px;border-radius:50%;'
              'background:#fff;"></div></div></div>',
        ),
    ];
    if (location == null) return marks.isEmpty ? null : marks;
    return [
      ...marks,
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

  /// 고른 건물 핀 — 둥근 모서리 파란 마름모 안에 흰 학사모. 마름모의 아래
  /// 꼭짓점이 건물 자리를 가리킨다.
  static const String _selectedPinHtml =
      '<div style="width:44px;height:52px;display:flex;'
      'align-items:flex-start;justify-content:center;">'
      '<div style="width:32px;height:32px;margin-top:6px;'
      'background:#0A78E6;border-radius:8px;transform:rotate(45deg);'
      'box-shadow:0 2px 6px rgba(0,0,0,0.25);display:flex;'
      'align-items:center;justify-content:center;">'
      '<svg width="20" height="20" viewBox="0 0 24 24" '
      'style="transform:rotate(-45deg);" fill="#fff">'
      '<path d="M5 13.18v4L12 21l7-3.82v-4L12 17l-7-3.82zM12 3L1 9l11 6 '
      '9-4.91V17h2V9L12 3z"/></svg></div></div>';

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
              onMapTap: _onMapTap,
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
                          : CampusRouteHeader(
                              onBack: _onRouteBack,
                              originName:
                                  _routeClasses?.fromTitle ?? _originLabel,
                              destinationName:
                                  _routeClasses?.toTitle ?? _destinationLabel,
                              onTapOrigin: _openOriginPicker,
                              onTapDestination: _openDestinationPicker,
                              onClearOrigin: _clearOrigin,
                              onClearDestination: _clearDestination,
                              onSwap: _swapEndpoints,
                            ),
                    ),
                  ),
                ),
              ),
            ),
            // 길안내 화면 아래 시트. 도착까지 정해야 "걸어서 N분"과 길 안내가
            // 나온다. 예전 "안내 시작" 시트(RouteSheet)는 숨겨 두었다. "건물
            // 선택" 패널이 열려 있거나 지도 빈 곳을 눌렀으면 숨긴다.
            if (_isRouteMode &&
                !_sheetHidden &&
                _pickerTarget == _PickerTarget.none)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: KakaoMapPointerInterceptor(
                  child: RouteSummarySheet(
                    title:
                        _routeClasses?.toRoom ??
                        _destinationLabel ??
                        _originLabel ??
                        '',
                    walkMinutes: _destinationLabel == null
                        ? null
                        : route?.walkMinutes,
                    distanceMeters: _destinationLabel == null
                        ? null
                        : route?.distanceMeters,
                    onClose: () => setState(() => _sheetHidden = true),
                    onReset: _reset,
                    onStart: route == null ? null : _startGuidance,
                  ),
                ),
              ),
            // 건물을 고르면 아래 끝에 붙는 "출발 · 도착" 시트(시안 "해당 건물
            // 선택 시"). 예전 "층별 안내 · 길 알려줘" 시트(BuildingSheet)는
            // 사용자 요청으로 숨겨 두었다.
            if (!_isRouteMode &&
                selected != null &&
                !_sheetHidden &&
                _pickerTarget == _PickerTarget.none)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: KakaoMapPointerInterceptor(
                  child: BuildingEndpointSheet(
                    buildingName: selected.name,
                    onClose: () => _selectBuilding(null),
                    onSetOrigin: _startFromSelected,
                    onSetDestination: _showDirections,
                  ),
                ),
              ),
            // 시안대로 현재 위치 버튼은 위쪽 흰 카드 바로 아래 오른쪽에 둔다.
            if (_pickerTarget == _PickerTarget.none)
              Positioned(
                top: _headerHeight + 16,
                right: 16,
                child: KakaoMapPointerInterceptor(
                  child: _MyLocationButton(
                    loading: _locating,
                    onTap: () => _loadMyLocation(moveCamera: true),
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
                  child: BuildingPickerPanel(
                    onSelected: _onBuildingPicked,
                    onSelectMyLocation: _onMyLocationPicked,
                  ),
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
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: CampusMapColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppColors.cardShadow,
        ),
        child: loading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: CampusMapColors.accent,
                ),
              )
            : const Icon(
                Icons.gps_fixed_rounded,
                color: CampusMapColors.textSecondary,
                size: 22,
                semanticLabel: '현재 위치로 이동',
              ),
      ),
    );
  }
}
