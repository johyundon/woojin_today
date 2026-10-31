import 'dart:async';
import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/cafeteria/models/cafeteria_menu.dart';

/// 학식 조회 실패. 네트워크 오류, 서버 오류(200 아님)를 구분 없이 메시지로 전달한다.
/// 표에서 메뉴를 못 찾는 것은 실패가 아니라 "메뉴 없음"으로 취급한다(명세).
class CafeteriaMenuException implements Exception {
  const CafeteriaMenuException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// [CafeteriaMenuService]의 공개 API. 화면은 이 인터페이스 타입으로 서비스를
/// 받아, 테스트에서 가짜 구현을 끼울 수 있다.
abstract class CafeteriaMenuServiceBase {
  /// [date] 하루치 학식. 그 날 등록된 메뉴가 없으면 [DailyCafeteriaMenu.isEmpty]인
  /// 값을 돌려준다.
  Future<DailyCafeteriaMenu> fetchMenu(DateTime date);
}

/// `POST /diet/daejin/2/view.do`로 한 주치 학식을 받아 날짜별 메뉴로 바꾼다.
/// 로그인/쿠키는 필요 없다.
///
/// 서버는 요청한 날짜가 속한 주(월~일) 전체를 한 번에 주므로, 주 단위로 메모리와
/// 기기에 캐시해 같은 주는 다시 요청하지 않는다. 실패한 요청은 캐시하지 않는다.
///
/// 캐시는 그 주 월요일 06:00 이후에 받은 것만 믿는다. 다음 주 메뉴를 월요일 전에
/// 미리 받아 두면 아직 덜 채워진 상태일 수 있어서, 월요일 06:00이 지난 뒤 처음
/// 조회할 때 한 번 새로 받는다(앱이 꺼져 있는 동안 자동으로 받지는 않는다).
///
/// 명세서의 응답 예시에는 메뉴가 들어 있는 칸이 없어서(전부 "등록된 식단내용이
/// (가) 없습니다"), 코너·가격을 읽는 규칙은 **실기기 응답으로 검증되지
/// 않았다.**
class CafeteriaMenuService implements CafeteriaMenuServiceBase {
  CafeteriaMenuService({http.Client? client, DateTime Function()? now})
    : _client = client ?? http.Client(),
      _now = now ?? DateTime.now;

  static const _endpoint = 'https://www.daejin.ac.kr/diet/daejin/2/view.do';
  static const _userAgent =
      'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36';

  /// 명세: 코너 이름이 없으면 쓰는 기본값.
  static const _defaultCorner = '학생회관';

  static final _datePattern = RegExp(r'\d{4}\.\d{2}\.\d{2}');
  static final _cornerPattern = RegExp(r'^\[(.+?)]');
  static final _starCornerPattern = RegExp(r'^★(.+?)★');
  static final _pricePattern = RegExp(r'가격\s*:\s*(.+?)]');

  /// 월요일 날짜(yyyy-MM-dd) → 그 주의 (날짜(yyyy-MM-dd) → 하루 메뉴).
  static final Map<String, _CachedWeek> _weekCache = {};

  /// 기기에 저장하는 키 앞부분. 뒤에 월요일 날짜가 붙는다.
  static const _prefsKeyPrefix = 'cafeteria_week_';

  /// 주 단위 캐시를 몇 시에 "새 주 메뉴가 확정됐다"고 볼지(월요일 이 시각 기준).
  static const _refreshHour = 6;

  final http.Client _client;
  final DateTime Function() _now;

  /// 테스트에서 메모리 캐시를 비우려고 쓴다.
  @visibleForTesting
  static void clearMemoryCache() => _weekCache.clear();

  @override
  Future<DailyCafeteriaMenu> fetchMenu(DateTime date) async {
    final monday = DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: date.weekday - DateTime.monday));
    final mondayKey = _dashKey(monday);

    final threshold = DateTime(
      monday.year,
      monday.month,
      monday.day,
      _refreshHour,
    );
    // 월요일 06:00 전에 받아 둔 값은, 06:00이 지나기 전까지만 믿는다.
    bool isFresh(_CachedWeek cached) =>
        !cached.savedAt.isBefore(threshold) || _now().isBefore(threshold);

    var cached = _weekCache[mondayKey];
    if (cached == null || !isFresh(cached)) {
      final stored = await _readStored(mondayKey);
      cached = stored != null && isFresh(stored) ? stored : null;
    }
    if (cached == null) {
      cached = _CachedWeek(_now(), await _fetchWeek(monday));
      await _writeStored(mondayKey, cached);
    }
    _weekCache[mondayKey] = cached;
    final week = cached.days;
    return week[_dashKey(date)] ?? const DailyCafeteriaMenu();
  }

  Future<_CachedWeek?> _readStored(String mondayKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefsKeyPrefix$mondayKey');
      if (raw == null) return null;
      return _CachedWeek.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      // 저장된 값을 못 읽어도 서버에서 새로 받으면 되므로 조회를 막지 않는다.
      debugPrint('[Cafeteria] 저장된 학식 읽기 실패: $e');
      return null;
    }
  }

  Future<void> _writeStored(String mondayKey, _CachedWeek week) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_prefsKeyPrefix$mondayKey',
        jsonEncode(week.toJson()),
      );
    } catch (e) {
      debugPrint('[Cafeteria] 학식 저장 실패: $e');
    }
  }

  Future<Map<String, DailyCafeteriaMenu>> _fetchWeek(DateTime monday) async {
    http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type':
                  'application/x-www-form-urlencoded; charset=UTF-8',
              'User-Agent': _userAgent,
            },
            // week는 노션 예시(week=next)와 프롬프트(빈값 고정)가 달라, 프롬프트를
            // 따라 빈값으로 보낸다.
            body: {'monday': _dotKey(monday), 'week': ''},
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException catch (e) {
      throw CafeteriaMenuException('요청 시간 초과: $e');
    } catch (e) {
      throw CafeteriaMenuException('네트워크 오류: $e');
    }

    if (response.statusCode != 200) {
      throw CafeteriaMenuException('서버 오류 (${response.statusCode})');
    }

    final body = utf8.decode(response.bodyBytes, allowMalformed: true);
    return _parse(body, monday);
  }

  Map<String, DailyCafeteriaMenu> _parse(String body, DateTime monday) {
    final table = html_parser.parse(body).querySelector('div.box-table table');

    // 요일별 날짜. 표가 없거나 헤더에서 못 찾으면 월요일 + 요일 순서로 채운다.
    final dates = List.generate(
      7,
      (i) => DateTime(monday.year, monday.month, monday.day + i),
    );
    final breakfast = List.generate(7, (_) => <CafeteriaMenuItem>[]);
    final lunch = List.generate(7, (_) => <CafeteriaMenuItem>[]);
    final dinner = List.generate(7, (_) => <CafeteriaMenuItem>[]);

    if (table != null) {
      final headers = table.querySelectorAll('thead th');
      for (var i = 0; i < 7 && i + 1 < headers.length; i++) {
        final match = _datePattern.firstMatch(headers[i + 1].text);
        if (match == null) continue;
        final parts = match.group(0)!.split('.').map(int.parse).toList();
        dates[i] = DateTime(parts[0], parts[1], parts[2]);
      }

      List<List<CafeteriaMenuItem>>? section;
      for (final row in table.querySelectorAll('tbody tr')) {
        final th = row.querySelector('th');
        if (th != null) {
          final title = th.text;
          if (title.contains('조식')) {
            section = breakfast;
          } else if (title.contains('중식') || title.contains('점심')) {
            section = lunch;
          } else if (title.contains('석식') || title.contains('저녁')) {
            section = dinner;
          } else {
            section = null;
          }
        }
        if (section == null) continue;

        final cells = row.querySelectorAll('td');
        for (var i = 0; i < cells.length && i < 7; i++) {
          final item = _parseCell(cells[i]);
          if (item != null) section[i].add(item);
        }
      }
    }

    return {
      for (var i = 0; i < 7; i++)
        _dashKey(dates[i]): DailyCafeteriaMenu(
          breakfast: breakfast[i],
          lunch: lunch[i],
          dinner: dinner[i],
        ),
    };
  }

  CafeteriaMenuItem? _parseCell(Element cell) {
    if (cell.classes.contains('no-data')) return null;

    // 셀 안의 글자 줄들(<br>로 나뉜 텍스트 노드). 가격은 <span>이라 여기에 안 들어온다.
    final lines = [
      for (final node in cell.nodes)
        if (node is Text && node.text.trim().isNotEmpty) node.text.trim(),
    ];
    if (lines.isEmpty) return null;
    // 실제 응답: 운영하지 않는 날은 메뉴 대신 "*미운영*"만 적혀 있다.
    if (lines.any((line) => line.contains('미운영'))) return null;

    var corner = _defaultCorner;
    var first = lines.first;
    final cornerMatch = _cornerPattern.firstMatch(first);
    final starMatch = _starCornerPattern.firstMatch(first);
    if (cornerMatch != null) {
      // 일반 메뉴: "[데일리밥] 음식/음식/음식"
      corner = cornerMatch.group(1)!.trim();
      first = first.substring(cornerMatch.end);
    } else if (starMatch != null) {
      // 실제 응답: 프리미엄식탁은 "★프리미엄식탁★" 줄 아래에 음식과 안내 문구가
      // 줄마다 따로 적혀 있다.
      corner = starMatch.group(1)!.trim();
      first = '';
    }

    final dishes = [
      for (final line in [first, ...lines.skip(1)])
        for (final dish in line.split('/'))
          if (dish.trim().isNotEmpty) dish.trim(),
    ];
    if (dishes.isEmpty) return null;

    int? price;
    final span = cell.querySelector('span');
    if (span != null) {
      final priceText = _pricePattern.firstMatch(span.text)?.group(1);
      final digits = priceText?.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits != null && digits.isNotEmpty) price = int.parse(digits);
    }

    return CafeteriaMenuItem(restaurant: corner, dishes: dishes, price: price);
  }

  static String _dashKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String _dotKey(DateTime d) => _dashKey(d).replaceAll('-', '.');
}

/// 한 주치 학식과 그것을 받은 시각. 기기에 JSON으로 저장한다.
class _CachedWeek {
  const _CachedWeek(this.savedAt, this.days);

  final DateTime savedAt;

  /// 날짜(yyyy-MM-dd) → 그 날 메뉴.
  final Map<String, DailyCafeteriaMenu> days;

  factory _CachedWeek.fromJson(Map<String, dynamic> json) {
    List<CafeteriaMenuItem> items(Object? list) => [
      for (final item in list as List<dynamic>)
        CafeteriaMenuItem(
          restaurant: item['restaurant'] as String,
          dishes: (item['dishes'] as List<dynamic>).cast<String>(),
          price: item['price'] as int?,
        ),
    ];
    return _CachedWeek(DateTime.parse(json['savedAt'] as String), {
      for (final entry in (json['days'] as Map<String, dynamic>).entries)
        entry.key: DailyCafeteriaMenu(
          breakfast: items(entry.value['breakfast']),
          lunch: items(entry.value['lunch']),
          dinner: items(entry.value['dinner']),
        ),
    });
  }

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> items(List<CafeteriaMenuItem> list) => [
      for (final item in list)
        {
          'restaurant': item.restaurant,
          'dishes': item.dishes,
          'price': item.price,
        },
    ];
    return {
      'savedAt': savedAt.toIso8601String(),
      'days': {
        for (final entry in days.entries)
          entry.key: {
            'breakfast': items(entry.value.breakfast),
            'lunch': items(entry.value.lunch),
            'dinner': items(entry.value.dinner),
          },
      },
    };
  }
}
