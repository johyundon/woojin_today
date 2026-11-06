import 'dart:async';
import 'dart:convert';

import 'package:cp949_codec/cp949_codec.dart';
import 'package:flutter/foundation.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'course_catalog_service.dart';
import 'department_codes.dart';

/// 강의계획서 상단 정보 한 칸(예: 담당교수 → 김교수).
typedef SyllabusInfo = ({String label, String value});

/// 3-1) 핵심역량 표의 한 행.
typedef SyllabusCompetency = ({String name, String ratio, String goal});

/// 10. 주별 수업계획 표의 한 행.
typedef SyllabusWeek = ({
  String week,
  String topic,
  String content,
  String method,
});

/// 7. 학습 평가방법 표의 한 행. rowspan 묶음(예: 학습태도)은 [name]에
/// "학습태도 · 발표"처럼 합쳐 둔다.
typedef SyllabusEvaluation = ({String name, String ratio, String detail});

/// 번호 매겨진 절 하나(예: "1. 수업의 개요와 유용성").
class SyllabusSection {
  const SyllabusSection({
    required this.title,
    required this.bodyText,
    this.competencies,
    this.weeks,
    this.evaluations,
  });

  final String title;

  /// 절 안 모든 행의 텍스트(줄 단위).
  final String bodyText;

  /// "3-1)"/"3-2)" 절일 때만.
  final List<SyllabusCompetency>? competencies;

  /// "10." 절일 때만.
  final List<SyllabusWeek>? weeks;

  /// "7." 절일 때만.
  final List<SyllabusEvaluation>? evaluations;
}

class SyllabusDetail {
  const SyllabusDetail({required this.topInfo, required this.sections});

  final List<SyllabusInfo> topInfo;
  final List<SyllabusSection> sections;

  /// 상단 정보에서 [label] 값. 없거나 비어 있으면 null.
  String? info(String label) {
    for (final i in topInfo) {
      if (i.label == label && i.value.isNotEmpty) return i.value;
    }
    return null;
  }

  /// 제목이 [prefix]로 시작하는 첫 절. 없으면 null.
  SyllabusSection? section(String prefix) {
    for (final s in sections) {
      if (s.title.startsWith(prefix)) return s;
    }
    return null;
  }
}

sealed class SyllabusException implements Exception {
  const SyllabusException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 네트워크 연결 실패 또는 타임아웃.
class SyllabusNetworkException extends SyllabusException {
  const SyllabusNetworkException(super.message);
}

/// 서버가 200이 아닌 상태 코드로 응답한 경우.
class SyllabusServerException extends SyllabusException {
  const SyllabusServerException(super.message);
}

/// 응답은 받았지만 기대한 구조가 아닌 경우.
class SyllabusParseException extends SyllabusException {
  const SyllabusParseException(super.message);
}

/// 이 과목은 강의계획서를 찾을 방법이 없는 경우(교양선택 영역 코드 없음,
/// 학과 코드 없음, 목록에 과목이 없음 등). 다시 시도해도 결과가 같다.
class SyllabusUnavailableException extends SyllabusException {
  const SyllabusUnavailableException(super.message);
}

abstract class SyllabusServiceBase {
  Future<SyllabusDetail> fetchSyllabus({
    required CourseCatalogItem course,
    required int year,
    required int semester,
    required String jsessionId,
    required String wmonid,
    required String userId2,
  });
}

/// 과목 하나의 강의계획서를 가져온다.
///
/// 상세 주소에 담당교수 번호(`fhd_04`)가 꼭 필요한데(비우면 빈 페이지가 옴 —
/// 2026-10-31 실제 확인), 이 번호는 분류별 강의계획서 목록에만 있다. 그래서
/// 과목의 이수구분으로 분류를 골라 목록 1번(학기·분류별로 저장해 재사용) →
/// 상세 1번 순서로 부른다. 명세서처럼 72개 분류를 전부 부르지 않는다.
class SyllabusService implements SyllabusServiceBase {
  SyllabusService({http.Client? client, DateTime Function()? now})
    : _client = client ?? http.Client(),
      _now = now ?? DateTime.now;

  final http.Client _client;
  final DateTime Function() _now;

  /// 기기에 저장한 목록·상세를 다시 쓰는 기간. 교수번호와 강의계획서 내용은
  /// 학기 중 거의 바뀌지 않아 한 학기 정도인 3개월(90일)로 둔다(사용자 요청).
  static const cacheDuration = Duration(days: 90);
  static const _listPrefsPrefix = 'syllabus_list_';
  static const _detailPrefsPrefix = 'syllabus_detail_';

  static const _base = 'https://dreams2.daejin.ac.kr/sugang/center/';
  static const _userAgent =
      'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36';
  static const _fixedCookieFields =
      'nm=8p13%2B7QRPNTh19POT6%2FJPw%3D%3D; '
      'userFlag=M0KvE%2FndjQ2bDxDXFBSM6A%3D%3D; '
      'userMjCd=AFkB9N2kRhFOtBPWa6nzxg%3D%3D; '
      'resd1=kffK4oSHCEBxASZ5sQOZeQ%3D%3D; '
      'resd2=KOXkLxIFhOL33Ka%2BYe1Yrw%3D%3D; '
      'orgCd=ZjzT1v9Ax6ybAbmfZIWOsA%3D%3D; '
      'seq=b%2B3V6U777TAsKzSC6a5IAA%3D%3D; '
      'wkkdCd=AFkB9N2kRhFOtBPWa6nzxg%3D%3D; '
      'passwd=AFkB9N2kRhFOtBPWa6nzxg%3D%3D; '
      'cookWebUser=btH3g7sAv6imoh3YAJBUEA%3D%3D';

  /// "연도:학기:분류쿼리" → {"과목코드-분반": 상세 상대경로}. 공개 데이터라
  /// 로그인 사용자와 상관없이 앱 실행 동안 재사용한다.
  static final Map<String, Map<String, String>> _listCache = {};

  /// 상세 주소 → 결과. 같은 강의계획서를 다시 열 때 요청하지 않는다.
  static final Map<String, SyllabusDetail> _detailCache = {};

  /// 테스트용: 저장해 둔 목록/상세를 비운다.
  static void clearCache() {
    _listCache.clear();
    _detailCache.clear();
  }

  /// 과목의 이수구분/개설학과로 목록 조회 쿼리(`ic_kwa...`)를 만든다.
  /// 만들 수 없으면 null.
  ///
  /// 학과 코드 뒤 공백(`%20`)은 Notion 명세의 실제 요청 예시를 따른 것이다.
  static String? categoryQuery(CourseCatalogItem course) {
    final type = course.courseType.trim();
    if (type.startsWith('교필')) return 'ic_kwa=B41001';
    if (type.startsWith('교직')) return 'ic_kwa=B41004';
    if (type.startsWith('일선')) return 'ic_kwa=B41020';
    if (type.startsWith('전')) return departmentQuery(course);
    return null;
  }

  /// 개설학과의 전공 목록 쿼리. 학과를 모르면 null.
  static String? departmentQuery(CourseCatalogItem course) {
    final code = kDepartmentCodes[course.department?.trim()];
    if (code == null) return null;
    return 'ic_kwa=B41005&ic_kwa_1=$code%20';
  }

  /// [categoryQuery]가 null일 때 사용자에게 보여줄 이유.
  static String unavailableReason(CourseCatalogItem course) {
    final type = course.courseType.trim();
    final department = course.department?.trim() ?? '';
    if (type.startsWith('교선') || type.startsWith('교양')) {
      return '교양선택 과목은 아직 강의계획서를 불러올 수 없어요.';
    }
    if (type.startsWith('전') && department.isEmpty) {
      // 예전에 저장한 시간표나 검색에서 담은 과목은 개설학과 정보가 없다.
      return '학과 정보가 없어 강의계획서를 찾을 수 없어요.\n'
          '"내 시간표 불러오기"로 다시 불러오면 열 수 있어요.';
    }
    if (type.startsWith('전')) {
      return '$department의 강의계획서 목록을 찾을 수 없어요.';
    }
    return '이 과목은 강의계획서를 찾을 수 없어요.';
  }

  @override
  Future<SyllabusDetail> fetchSyllabus({
    required CourseCatalogItem course,
    required int year,
    required int semester,
    required String jsessionId,
    required String wmonid,
    required String userId2,
  }) async {
    final category = categoryQuery(course);
    if (category == null) {
      throw SyllabusUnavailableException(unavailableReason(course));
    }
    final cookie =
        'JSESSIONID=$jsessionId; user_id=$userId2; userId=$userId2; '
        '$_fixedCookieFields; WMONID=$wmonid';

    final key = '${course.courseCode}-${course.section}';
    var href = (await _links(year, semester, category, cookie))[key];
    // 일선처럼 다른 학과 전공을 듣는 과목은 분류 목록이 아니라 개설학과의
    // 전공 목록에 있다(2026-11-01 실제 일선 과목에서 확인). 이때만 한 번 더 찾는다.
    final department = departmentQuery(course);
    if (href == null && department != null && department != category) {
      href = (await _links(year, semester, department, cookie))[key];
    }
    if (href == null) {
      throw const SyllabusUnavailableException('강의계획서 목록에 이 과목이 없어요.');
    }

    final detailUri = Uri.parse('${_base}Blsn020302.jsp').resolve(href);
    final detailKey = detailUri.toString();
    final cached = _detailCache[detailKey];
    if (cached != null) return cached;
    final prefsKey = '$_detailPrefsPrefix$detailKey';
    final stored = await _readStored(prefsKey);
    if (stored != null) {
      final detail = _detailFromJson(stored as Map<String, dynamic>);
      _detailCache[detailKey] = detail;
      return detail;
    }
    final detail = parseDetail(await _get(detailUri, cookie));
    _detailCache[detailKey] = detail;
    await _writeStored(prefsKey, _detailToJson(detail));
    return detail;
  }

  /// 학기·분류별 목록({"과목코드-분반": 상세 링크}). 한 번 받은 목록은 재사용한다.
  Future<Map<String, String>> _links(
    int year,
    int semester,
    String category,
    String cookie,
  ) async {
    final listKey = '$year:$semester:$category';
    final cached = _listCache[listKey];
    if (cached != null) return cached;
    final prefsKey = '$_listPrefsPrefix$listKey';
    final stored = await _readStored(prefsKey);
    if (stored != null) {
      final links = (stored as Map<String, dynamic>).cast<String, String>();
      _listCache[listKey] = links;
      return links;
    }
    final listUri = Uri.parse(
      '${_base}Blsn020302.jsp?fhd_yyyy=$year&fhd_shtm=$semester&$category',
    );
    final links = parseList(await _get(listUri, cookie));
    _listCache[listKey] = links;
    await _writeStored(prefsKey, links);
    return links;
  }

  /// 기기에 저장된 값([cacheDuration] 안의 것만). 없거나 못 읽으면 null.
  Future<Object?> _readStored(String key) async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(key);
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = DateTime.parse(json['savedAt'] as String);
      if (_now().difference(savedAt) >= cacheDuration) return null;
      return json['data'];
    } catch (e) {
      // 못 읽어도 서버에서 새로 받으면 되므로 조회를 막지 않는다.
      debugPrint('[Syllabus] 저장된 값 읽기 실패: $e');
      return null;
    }
  }

  Future<void> _writeStored(String key, Object data) async {
    try {
      await (await SharedPreferences.getInstance()).setString(
        key,
        jsonEncode({'savedAt': _now().toIso8601String(), 'data': data}),
      );
    } catch (e) {
      debugPrint('[Syllabus] 저장 실패: $e');
    }
  }

  static Map<String, Object?> _detailToJson(SyllabusDetail d) => {
    'top': [
      for (final i in d.topInfo) [i.label, i.value],
    ],
    'sections': [
      for (final s in d.sections)
        {
          't': s.title,
          'b': s.bodyText,
          if (s.competencies != null)
            'c': [
              for (final c in s.competencies!) [c.name, c.ratio, c.goal],
            ],
          if (s.weeks != null)
            'w': [
              for (final w in s.weeks!) [w.week, w.topic, w.content, w.method],
            ],
          if (s.evaluations != null)
            'e': [
              for (final e in s.evaluations!) [e.name, e.ratio, e.detail],
            ],
        },
    ],
  };

  static SyllabusDetail _detailFromJson(Map<String, dynamic> j) {
    List<String> row(Object? r) => (r as List<dynamic>).cast<String>();
    return SyllabusDetail(
      topInfo: [
        for (final r in j['top'] as List<dynamic>)
          (label: row(r)[0], value: row(r)[1]),
      ],
      sections: [
        for (final s
            in (j['sections'] as List<dynamic>).cast<Map<String, dynamic>>())
          SyllabusSection(
            title: s['t'] as String,
            bodyText: s['b'] as String,
            competencies: s['c'] == null
                ? null
                : [
                    for (final r in s['c'] as List<dynamic>)
                      (name: row(r)[0], ratio: row(r)[1], goal: row(r)[2]),
                  ],
            weeks: s['w'] == null
                ? null
                : [
                    for (final r in s['w'] as List<dynamic>)
                      (
                        week: row(r)[0],
                        topic: row(r)[1],
                        content: row(r)[2],
                        method: row(r)[3],
                      ),
                  ],
            evaluations: s['e'] == null
                ? null
                : [
                    for (final r in s['e'] as List<dynamic>)
                      (name: row(r)[0], ratio: row(r)[1], detail: row(r)[2]),
                  ],
          ),
      ],
    );
  }

  Future<String> _get(Uri uri, String cookie) async {
    http.Response response;
    try {
      response = await _client
          .get(uri, headers: {'Cookie': cookie, 'User-Agent': _userAgent})
          .timeout(const Duration(seconds: 15));
    } on TimeoutException catch (e) {
      throw SyllabusNetworkException('요청 시간 초과: $e');
    } catch (e) {
      throw SyllabusNetworkException('네트워크 오류: $e');
    }
    if (response.statusCode != 200) {
      throw SyllabusServerException('서버 오류 (${response.statusCode})');
    }
    return _decode(response);
  }

  /// 실제 응답은 목록·상세 모두 `charset=euc-kr`였다. 헤더를 우선 따르고,
  /// 실패하면 EUC-KR → UTF-8 순으로 시도한다(dreams2는 엔드포인트마다 다름).
  String _decode(http.Response response) {
    final ct = response.headers['content-type']?.toLowerCase() ?? '';
    final bytes = response.bodyBytes;
    if (ct.contains('utf-8')) {
      try {
        return utf8.decode(bytes);
      } catch (_) {}
    }
    try {
      return cp949.decode(bytes);
    } catch (_) {
      return utf8.decode(bytes, allowMalformed: true);
    }
  }

  static final _detailLink = RegExp(r'Blsn020303\.jsp\?', caseSensitive: false);

  /// 목록 응답에서 {"과목코드-분반": 상세 상대경로}를 뽑는다. 링크 글자가
  /// 과목명일 수도 있어서, 키는 링크 주소의 fhd_00(과목코드)/fhd_01(분반)로
  /// 만든다.
  static Map<String, String> parseList(String body) {
    final document = html_parser.parse(body);
    final result = <String, String>{};
    for (final a in document.querySelectorAll('tr.tr_a_chrm a[href]')) {
      final href = a.attributes['href']!.trim();
      if (!_detailLink.hasMatch(href)) continue;
      final query = Uri.parse(href).queryParameters;
      final code = query['fhd_00']?.trim();
      final section = query['fhd_01']?.trim();
      if (code == null || code.isEmpty || section == null) continue;
      result.putIfAbsent('$code-$section', () => href);
    }
    return result;
  }

  static final _sectionTitle = RegExp(r'^\d+[.\-]');

  /// 상세 응답을 상단 정보 + 번호 매겨진 절로 나눈다(Notion 상세 조회 명세).
  static SyllabusDetail parseDetail(String body) {
    // <br>을 줄바꿈으로 바꿔야 "인문학관<br>427 호"가 붙어 버리지 않는다.
    final document = html_parser.parse(
      body.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n'),
    );

    final topTable = document.querySelector('table.table1');
    if (topTable == null) {
      throw const SyllabusParseException('강의계획서 형식이 예상과 달라요.');
    }
    final topInfo = <SyllabusInfo>[];
    final topRows = topTable.querySelectorAll('tr');
    for (final row in topRows.skip(1)) {
      final cells = _tds(row);
      for (var i = 0; i + 1 < cells.length; i += 2) {
        final label = _oneLine(cells[i].text).replaceAll(' ', '');
        if (label.isEmpty) continue;
        topInfo.add((label: label, value: _oneLine(cells[i + 1].text)));
      }
    }

    return SyllabusDetail(topInfo: topInfo, sections: _parseSections(document));
  }

  static List<SyllabusSection> _parseSections(dom.Document document) {
    dom.Element? firstTitle;
    for (final b in document.querySelectorAll('b')) {
      if (_sectionTitle.hasMatch(_oneLine(b.text))) {
        firstTitle = b;
        break;
      }
    }
    final titleRow = _closest(firstTitle, 'tr');
    final rowParent = titleRow?.parent;
    if (rowParent == null) return const [];

    final sections = <SyllabusSection>[];
    String? title;
    final lines = <String>[];
    List<SyllabusCompetency>? competencies;
    List<SyllabusWeek>? weeks;
    List<SyllabusEvaluation>? evaluations;

    void flush() {
      if (title != null &&
          (lines.isNotEmpty ||
              competencies != null ||
              weeks != null ||
              evaluations != null)) {
        sections.add(
          SyllabusSection(
            title: title!,
            bodyText: lines.join('\n'),
            competencies: competencies,
            weeks: weeks,
            evaluations: evaluations,
          ),
        );
      }
      lines.clear();
      competencies = null;
      weeks = null;
      evaluations = null;
    }

    for (final row in rowParent.children.where((e) => e.localName == 'tr')) {
      final b = row.querySelector('b');
      final bText = b == null ? '' : _oneLine(b.text);
      if (_sectionTitle.hasMatch(bText)) {
        flush();
        title = bText;
        continue;
      }
      final current = title;
      if (current == null) continue;

      lines.addAll(_lines(row.text));
      if (current.startsWith('10.')) {
        (weeks ??= []).addAll(_parseWeeks(row));
      } else if (current.startsWith('7.')) {
        (evaluations ??= []).addAll(_parseEvaluations(row));
      } else if (current.startsWith('3-1)') || current.startsWith('3-2)')) {
        (competencies ??= []).addAll(_parseCompetencies(row));
      }
    }
    flush();
    return sections;
  }

  static List<SyllabusWeek> _parseWeeks(dom.Element row) {
    final result = <SyllabusWeek>[];
    for (final tr in row.querySelectorAll('tr')) {
      final cells = _tds(tr);
      if (cells.length < 4) continue;
      final week = _oneLine(cells[0].text);
      if (int.tryParse(week) == null) continue;
      result.add((
        week: week,
        topic: _oneLine(cells[1].text),
        content: _lines(cells[2].text).join('\n'),
        method: _oneLine(cells[3].text),
      ));
    }
    return result;
  }

  static final _ratio = RegExp(r'^\d+(\.\d+)?%$');

  /// rowspan으로 묶인 그룹(예: "학습태도" 아래 발표/토의...)은 다음 행에
  /// 그룹 칸이 없으므로, 남은 rowspan 수만큼 그룹 이름을 이어받는다.
  static List<SyllabusEvaluation> _parseEvaluations(dom.Element row) {
    final result = <SyllabusEvaluation>[];
    String? group;
    var groupRowsLeft = 0;
    for (final tr in row.querySelectorAll('tr')) {
      final cells = _tds(tr);
      final ratioIndex = cells.indexWhere(
        (c) => _ratio.hasMatch(_oneLine(c.text)),
      );
      if (ratioIndex < 1) continue;
      final names = cells.sublist(0, ratioIndex);
      String name;
      if (names.length >= 2) {
        group = _oneLine(names[0].text);
        groupRowsLeft =
            (int.tryParse(names[0].attributes['rowspan'] ?? '') ?? 1) - 1;
        name = '$group · ${_oneLine(names[1].text)}';
      } else if (groupRowsLeft > 0 && group != null) {
        groupRowsLeft--;
        name = '$group · ${_oneLine(names[0].text)}';
      } else {
        name = _oneLine(names[0].text);
      }
      result.add((
        name: name,
        ratio: _oneLine(cells[ratioIndex].text),
        detail: ratioIndex + 1 < cells.length
            ? _oneLine(cells[ratioIndex + 1].text)
            : '',
      ));
    }
    return result;
  }

  /// 핵심역량 표에서 "역량 | 비율(%) | 수업목표" 행만 고른다. 같은 표 아래쪽
  /// "6대 핵심역량 정의" 행은 비율 칸에 %가 없어 걸러진다.
  static List<SyllabusCompetency> _parseCompetencies(dom.Element row) {
    final result = <SyllabusCompetency>[];
    for (final tr in row.querySelectorAll('tr')) {
      final cells = _tds(tr);
      if (cells.length != 3) continue;
      final ratio = _oneLine(cells[1].text);
      if (!ratio.contains('%')) continue;
      result.add((
        name: _oneLine(cells[0].text),
        ratio: ratio,
        goal: _oneLine(cells[2].text),
      ));
    }
    return result;
  }

  static List<dom.Element> _tds(dom.Element tr) =>
      tr.children.where((e) => e.localName == 'td').toList();

  static dom.Element? _closest(dom.Element? e, String tag) {
    var node = e?.parent;
    while (node != null && node.localName != tag) {
      node = node.parent;
    }
    return node;
  }

  /// 줄 단위로 나눠 공백을 정리하고 빈 줄을 버린다.
  static List<String> _lines(String text) => text
      .replaceAll(' ', ' ')
      .split('\n')
      .map((l) => l.replaceAll(RegExp(r'\s+'), ' ').trim())
      .where((l) => l.isNotEmpty)
      .toList();

  static String _oneLine(String text) => _lines(text).join(' ');
}
