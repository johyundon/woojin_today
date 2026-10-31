import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// 학사일정 한 건(시작일~종료일, 제목). 하루짜리면 [start] == [end].
class AcademicScheduleItem {
  const AcademicScheduleItem({
    required this.start,
    required this.end,
    required this.title,
  });

  /// 날짜만 쓴다(시각은 0시).
  final DateTime start;
  final DateTime end;
  final String title;

  /// 캘린더 일정 id. 시작일+제목으로 만들어, 앱을 다시 켜거나 다른 달에서 같은
  /// 일정을 받아도 같은 값이 나온다(걸어 둔 알림이 유지되고, 달을 넘는 일정이
  /// 두 번 들어가지 않는다). 학교가 제목을 고치면 다른 일정으로 본다.
  String get id =>
      'school-${start.year}${_two(start.month)}${_two(start.day)}-$title';

  static String _two(int n) => n.toString().padLeft(2, '0');

  factory AcademicScheduleItem.fromJson(Map<String, dynamic> json) =>
      AcademicScheduleItem(
        start: DateTime.parse(json['start'] as String),
        end: DateTime.parse(json['end'] as String),
        title: json['title'] as String,
      );

  Map<String, dynamic> toJson() => {
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
    'title': title,
  };
}

class AcademicScheduleException implements Exception {
  const AcademicScheduleException(this.message, {this.isNetwork = false});

  final String message;

  /// 타임아웃 등 통신 자체의 실패인지(명세: 네트워크 실패는 따로 구분).
  final bool isNetwork;

  @override
  String toString() => message;
}

/// [AcademicScheduleService]의 공개 API. 화면은 이 타입으로 받아 테스트에서 가짜를 끼운다.
abstract class AcademicScheduleServiceBase {
  /// [year]년 [month]월 학사일정. 그 달에 걸친 일정(앞뒤 달에서 이어지는 것 포함)이
  /// 모두 온다. [forceRefresh]가 true면 캐시를 무시하고 새로 받는다.
  Future<List<AcademicScheduleItem>> fetchMonth(
    int year,
    int month, {
    bool forceRefresh = false,
  });
}

/// 학교 홈페이지의 월별 학사일정(명세: 상세_2 4번). 로그인·쿠키가 필요 없다.
/// 응답 구조는 2026-10-31 실제 응답(10월·11월·2027년 1월)으로 확인했다.
///
/// 달마다 하루 동안 기기에 저장해 두고 다시 요청하지 않는다. 실패한 결과는
/// 저장하지 않는다.
class AcademicScheduleService implements AcademicScheduleServiceBase {
  AcademicScheduleService({http.Client? client, DateTime Function()? now})
    : _client = client ?? http.Client(),
      _now = now ?? DateTime.now;

  static const _endpoint =
      'https://www.daejin.ac.kr/schdulmanage/daejin/19/monthSchdul.do';
  static const _userAgent =
      'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36';
  static const cacheDuration = Duration(days: 1);
  static const _prefsKeyPrefix = 'academic_schedule_';

  static final _datePattern = RegExp(r'(\d{4})\.(\d{2})\.(\d{2})');

  final http.Client _client;
  final DateTime Function() _now;

  @override
  Future<List<AcademicScheduleItem>> fetchMonth(
    int year,
    int month, {
    bool forceRefresh = false,
  }) async {
    final key = '$_prefsKeyPrefix${year}_$month';
    if (!forceRefresh) {
      final cached = await _readStored(key);
      if (cached != null) return cached;
    }

    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type':
                  'application/x-www-form-urlencoded; charset=UTF-8',
              'User-Agent': _userAgent,
            },
            body: {'year': '$year', 'month': '$month'},
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw AcademicScheduleException('네트워크 오류: $e', isNetwork: true);
    }
    if (response.statusCode != 200) {
      throw AcademicScheduleException('서버 오류 (${response.statusCode})');
    }

    final items = parse(utf8.decode(response.bodyBytes, allowMalformed: true));
    await _writeStored(key, items);
    return items;
  }

  /// 명세의 파싱 규칙: `div.applyList table tbody tr`마다 th의 날짜(1~2개) →
  /// 시작·종료일, td → 제목. 날짜나 제목이 없는 행은 건너뛴다.
  @visibleForTesting
  static List<AcademicScheduleItem> parse(String body) {
    final items = <AcademicScheduleItem>[];
    final rows = html_parser
        .parse(body)
        .querySelectorAll('div.applyList table tbody tr');
    for (final row in rows) {
      final dateText = row.querySelector('th')?.text ?? '';
      final title = (row.querySelector('td')?.text ?? '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      final dates = _datePattern.allMatches(dateText).toList();
      if (title.isEmpty || dates.isEmpty) continue;

      DateTime toDate(RegExpMatch m) => DateTime(
        int.parse(m.group(1)!),
        int.parse(m.group(2)!),
        int.parse(m.group(3)!),
      );
      final start = toDate(dates.first);
      items.add(
        AcademicScheduleItem(
          start: start,
          end: dates.length > 1 ? toDate(dates[1]) : start,
          title: title,
        ),
      );
    }
    return items;
  }

  Future<List<AcademicScheduleItem>?> _readStored(String key) async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(key);
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = DateTime.parse(json['savedAt'] as String);
      if (_now().difference(savedAt) >= cacheDuration) return null;
      return [
        for (final e in json['items'] as List<dynamic>)
          AcademicScheduleItem.fromJson(e as Map<String, dynamic>),
      ];
    } catch (e) {
      // 저장된 값을 못 읽어도 서버에서 새로 받으면 되므로 조회를 막지 않는다.
      debugPrint('[AcademicSchedule] 저장된 일정 읽기 실패: $e');
      return null;
    }
  }

  Future<void> _writeStored(
    String key,
    List<AcademicScheduleItem> items,
  ) async {
    try {
      await (await SharedPreferences.getInstance()).setString(
        key,
        jsonEncode({
          'savedAt': _now().toIso8601String(),
          'items': [for (final i in items) i.toJson()],
        }),
      );
    } catch (e) {
      debugPrint('[AcademicSchedule] 일정 저장 실패: $e');
    }
  }
}
