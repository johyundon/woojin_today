import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/geo_point.dart';

/// 두 건물 사이 도보 경로 계산 결과.
class CampusRoute {
  const CampusRoute({
    required this.path,
    required this.distanceMeters,
    required this.walkMinutes,
  });

  /// 출발지 → (캠퍼스 보행로를 따라가는 경유점들) → 목적지 순서의 좌표 목록.
  /// 지도에 그대로 폴리라인으로 그리면 된다.
  final List<GeoPoint> path;
  final double distanceMeters;
  final int walkMinutes;
}

/// 평균 보행 속도(분당 미터). 성인 평속 4km/h 기준.
const double _walkMetersPerMinute = 4000 / 60;

/// `assets/campus/campus_paths.geojson`(OSM에서 추출한 캠퍼스 도로/보행로)을
/// 그래프로 만들어, 두 지점 사이 최단 도보 경로를 계산한다.
///
/// 외부 길찾기 API(카카오맵 자체는 무료 보행자 길찾기를 제공하지 않는다) 없이,
/// 이 안에 들어있는 실제 캠퍼스 도로망만으로 "대충 직선거리"가 아닌 실제
/// 길을 따라가는 경로/거리를 구한다.
class CampusRouteService {
  CampusRouteService({this.assetPath = 'assets/campus/campus_paths.geojson'});

  final String assetPath;

  Map<GeoPoint, List<_Edge>>? _graph;
  List<GeoPoint>? _nodes;

  Future<void> _ensureLoaded() async {
    if (_graph != null) return;

    final raw = await rootBundle.loadString(assetPath);
    final geojson = jsonDecode(raw) as Map<String, dynamic>;
    final features = geojson['features'] as List<dynamic>;

    final graph = <GeoPoint, List<_Edge>>{};

    void addEdge(GeoPoint a, GeoPoint b) {
      if (a == b) return;
      final distance = haversineMeters(a, b);
      (graph[a] ??= []).add(_Edge(b, distance));
      (graph[b] ??= []).add(_Edge(a, distance));
    }

    for (final feature in features) {
      final geometry = feature['geometry'] as Map<String, dynamic>;
      if (geometry['type'] != 'LineString') continue;

      final coords = (geometry['coordinates'] as List<dynamic>)
          .map(
            (c) => GeoPoint(
              lat: (c[1] as num).toDouble(),
              lng: (c[0] as num).toDouble(),
            ),
          )
          .toList();

      for (var i = 0; i < coords.length - 1; i++) {
        addEdge(coords[i], coords[i + 1]);
      }
    }

    _graph = graph;
    _nodes = graph.keys.toList();
  }

  /// [graph]의 노드 중 [point]와 가장 가까운 노드를 찾는다(전수 탐색 —
  /// 노드가 수백 개뿐이라 공간 인덱스 없이도 충분히 빠르다).
  GeoPoint _nearestNode(GeoPoint point) {
    final nodes = _nodes!;
    var nearest = nodes.first;
    var nearestDistance = haversineMeters(point, nearest);
    for (final node in nodes.skip(1)) {
      final distance = haversineMeters(point, node);
      if (distance < nearestDistance) {
        nearest = node;
        nearestDistance = distance;
      }
    }
    return nearest;
  }

  /// 단순 O(V^2) 다익스트라. 그래프 노드가 500여 개뿐이라 우선순위 큐 없이도
  /// 충분히 빠르고, 코드가 훨씬 단순하다.
  List<GeoPoint>? _shortestPath(GeoPoint start, GeoPoint end) {
    final graph = _graph!;
    if (start == end) return [start];

    final dist = <GeoPoint, double>{start: 0};
    final prev = <GeoPoint, GeoPoint>{};
    final visited = <GeoPoint>{};
    final unvisited = {...graph.keys};

    GeoPoint? current = start;
    while (current != null) {
      visited.add(current);
      unvisited.remove(current);

      final currentDist = dist[current]!;
      for (final edge in graph[current] ?? const <_Edge>[]) {
        if (visited.contains(edge.to)) continue;
        final candidate = currentDist + edge.weight;
        if (candidate < (dist[edge.to] ?? double.infinity)) {
          dist[edge.to] = candidate;
          prev[edge.to] = current;
        }
      }

      if (current == end) break;

      GeoPoint? next;
      var nextDist = double.infinity;
      for (final node in unvisited) {
        final d = dist[node];
        if (d != null && d < nextDist) {
          next = node;
          nextDist = d;
        }
      }
      current = next;
    }

    if (!dist.containsKey(end)) return null;

    final path = <GeoPoint>[end];
    var node = end;
    while (node != start) {
      node = prev[node]!;
      path.add(node);
    }
    return path.reversed.toList();
  }

  /// [origin]에서 [destination]까지의 도보 경로를 구한다. 캠퍼스 보행로
  /// 네트워크에 두 지점이 모두 연결돼 있으면 실제 길을 따라가는 경로를,
  /// 그렇지 않으면(끊긴 구역 등) 직선 경로로 대체한다.
  Future<CampusRoute> findRoute({
    required GeoPoint origin,
    required GeoPoint destination,
  }) async {
    if (origin == destination) {
      return CampusRoute(path: [origin], distanceMeters: 0, walkMinutes: 0);
    }

    await _ensureLoaded();

    final startNode = _nearestNode(origin);
    final endNode = _nearestNode(destination);
    final networkPath = _shortestPath(startNode, endNode);

    final path = <GeoPoint>[
      origin,
      if (networkPath != null) ...networkPath else endNode,
      destination,
    ];

    var distanceMeters = 0.0;
    for (var i = 0; i < path.length - 1; i++) {
      distanceMeters += haversineMeters(path[i], path[i + 1]);
    }

    return CampusRoute(
      path: path,
      distanceMeters: distanceMeters,
      walkMinutes: (distanceMeters / _walkMetersPerMinute).ceil().clamp(1, 999),
    );
  }
}

class _Edge {
  const _Edge(this.to, this.weight);

  final GeoPoint to;
  final double weight;
}
