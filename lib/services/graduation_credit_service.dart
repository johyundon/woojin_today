import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cp949_codec/cp949_codec.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/graduation/models/graduation_credit.dart';

/// 네트워크 실패, 서버 오류(200 아님), 응답 형식이 예상과 다름을 구분한다.
sealed class GraduationCreditException implements Exception {
  const GraduationCreditException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GraduationCreditNetworkException extends GraduationCreditException {
  const GraduationCreditNetworkException(super.message);
}

class GraduationCreditServerException extends GraduationCreditException {
  const GraduationCreditServerException(super.message);
}

class GraduationCreditParseException extends GraduationCreditException {
  const GraduationCreditParseException(super.message);
}

abstract class GraduationCreditServiceBase {
  Future<GraduationCreditSummary> fetchSummary({
    required String userId2,
    bool forceRefresh = false,
  });
}

/// 수강신청 시스템(dreams2)의 "이수구분표" 리포트를 받아 졸업학점 현황으로 바꾼다.
///
/// 1. `GET /sugang/sugang_wlsn0555.jsp` → `openFile("경로", "파라미터")` 두 값.
/// 2. `POST /ReportingServer/service` → 리포트 한 장(MML). 글자 칸마다
///    `<TL tid le to>텍스트</TL>`로 위치가 붙어 있어, 같은 세로 위치(`to`)끼리
///    한 줄로 묶어 표를 다시 짠다.
///
/// 쿠키는 `userId`·`orgCd` 두 개뿐이고, 2번에 1번의 세션 쿠키는 필요 없다.
/// 1번 값은 디코딩하지 않고 그대로 form 인코딩해 보낸다(2026-10-31 실제 호출로
/// 확인). 결과는 7일 동안 기기에 저장해 학교 요청을 줄인다.
class GraduationCreditService implements GraduationCreditServiceBase {
  GraduationCreditService({http.Client? client, DateTime Function()? now})
    : _client = client ?? http.Client(),
      _now = now ?? DateTime.now;

  static const _viewerUrl =
      'https://dreams2.daejin.ac.kr/sugang/sugang_wlsn0555.jsp';
  static const _reportUrl =
      'https://dreams2.daejin.ac.kr/ReportingServer/service';
  static const _userAgent =
      'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36';
  static const _fixedOrgCd = 'orgCd=ZjzT1v9Ax6ybAbmfZIWOsA%3D%3D';

  static const cacheDuration = Duration(days: 7);
  static const _prefsKeyPrefix = 'graduation_credit_';

  static final _openFile = RegExp(r'openFile\("([^"]+)"\s*,\s*"([^"]+)"\)');

  final http.Client _client;
  final DateTime Function() _now;

  @override
  Future<GraduationCreditSummary> fetchSummary({
    required String userId2,
    bool forceRefresh = false,
  }) async {
    final prefsKey = '$_prefsKeyPrefix$userId2';
    if (!forceRefresh) {
      final cached = await _readStored(prefsKey);
      if (cached != null &&
          _now().difference(cached.fetchedAt) < cacheDuration) {
        return cached;
      }
    }

    final cookie = 'userId=$userId2; $_fixedOrgCd;';

    final viewer = await _send(
      http.Request('GET', Uri.parse(_viewerUrl))
        ..headers.addAll({'Cookie': cookie, 'User-Agent': _userAgent}),
    );
    final match = _openFile.firstMatch(_decode(viewer));
    if (match == null) {
      throw const GraduationCreditParseException('이수구분표 주소를 찾지 못했어요');
    }

    final form = {
      'opcode': '700',
      'mrd_path': match.group(1)!,
      'mrd_param': match.group(2)!,
      'mrd_plain_param': '',
      'mrd_data': '',
      'runtime_param': '',
      'mmlVersion': '0',
      'protocol': 'sync',
      'use_cache': 'false',
      'html5_uuid': _randomUuid(),
      'enc_type': '5',
    };
    // http 패키지의 bodyFields는 Content-Type에 charset을 붙이므로, 명세대로
    // charset 없는 본문을 직접 만든다.
    final body = form.entries
        .map(
          (e) =>
              '${Uri.encodeQueryComponent(e.key)}='
              '${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');
    final report = await _send(
      http.Request('POST', Uri.parse(_reportUrl))
        ..headers.addAll({
          'Cookie': cookie,
          'User-Agent': _userAgent,
          'Content-Type': 'application/x-www-form-urlencoded',
        })
        ..bodyBytes = utf8.encode(body),
    );

    final summary = parseReport(_decode(report), fetchedAt: _now());
    await _writeStored(prefsKey, summary);
    return summary;
  }

  Future<http.Response> _send(http.Request request) async {
    http.Response response;
    try {
      response = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 20)),
      ).timeout(const Duration(seconds: 20));
    } on TimeoutException catch (e) {
      throw GraduationCreditNetworkException('요청 시간 초과: $e');
    } catch (e) {
      throw GraduationCreditNetworkException('네트워크 오류: $e');
    }
    if (response.statusCode != 200) {
      throw GraduationCreditServerException('서버 오류 (${response.statusCode})');
    }
    return response;
  }

  /// 1번은 `charset=euc-kr`, 2번은 `utf-8`로 왔다. 헤더가 틀릴 때를 대비해
  /// 헤더가 말하는 쪽을 먼저 시도하고 실패하면 다른 쪽으로 읽는다.
  static String _decode(http.Response response) {
    final type = response.headers['content-type']?.toLowerCase() ?? '';
    final bytes = response.bodyBytes;
    final koreanFirst = type.contains('euc-kr') || type.contains('cp949');
    final decoders = <String Function()>[
      if (koreanFirst) () => cp949.decode(bytes),
      () => utf8.decode(bytes),
      if (!koreanFirst) () => cp949.decode(bytes),
    ];
    for (final decode in decoders) {
      try {
        return decode();
      } catch (_) {}
    }
    return utf8.decode(bytes, allowMalformed: true);
  }

  static String _randomUuid() {
    final rnd = Random.secure();
    String hex(int n) =>
        List.generate(n, (_) => rnd.nextInt(16).toRadixString(16)).join();
    return '${hex(8)}-${hex(4)}-4${hex(3)}-'
        '${(8 + rnd.nextInt(4)).toRadixString(16)}${hex(3)}-${hex(12)}';
  }

  // ---------------------------------------------------------------------------
  // 리포트(MML) 읽기
  // ---------------------------------------------------------------------------

  static final _cellPattern = RegExp(r'<TL\b([^>]*)>(.*?)</TL>', dotAll: true);
  static final _attrPattern = RegExp(r'(\w+)="([^"]*)"');
  static final _semesterPattern = RegExp(r'^\d{4}-\S+$');
  static final _courseCodePattern = RegExp(r'^[0-9A-Za-z]{4,}-\d+$');
  static final _subtotalPattern = RegExp(r'^(.+?)\s*취득학점\s*계\s*:\s*(\d+)');
  static final _grandTotalPattern = RegExp(r'취득학점\s*총계\s*:\s*(\d+)');
  static final _rulePattern = RegExp(r'^[①-⑳]');

  /// MML 원문을 졸업학점 현황으로 바꾼다. 표를 하나도 못 찾으면
  /// [GraduationCreditParseException].
  @visibleForTesting
  static GraduationCreditSummary parseReport(
    String mml, {
    required DateTime fetchedAt,
  }) {
    if (!mml.contains('<MML')) {
      throw const GraduationCreditParseException('이수구분표 응답 형식이 달라요');
    }
    final rows = _readRows(mml);

    final courses = _readCourses(rows);
    final standard = _readTable(rows, (first) => first == '구분');
    final areaTable = _readTable(rows, (first) => first == '교양영역');
    if (courses == null && standard == null) {
      throw const GraduationCreditParseException('이수구분표에서 표를 찾지 못했어요');
    }

    int? num(String? s) => s == null ? null : int.tryParse(s.trim());
    double? dbl(String? s) => s == null ? null : double.tryParse(s.trim());

    final groups = courses?.groups ?? {};
    final categories = <GraduationCreditCategory>[];
    final usedGroups = <String>{};
    for (final entry in standard?.entries ?? <_Column>[]) {
      if (entry.label == '졸업학점' || entry.label == '졸업평점평균') continue;
      final required = num(entry.required);
      final group = groups[entry.label];
      if (group != null) {
        usedGroups.add(entry.label);
        categories.add(
          GraduationCreditCategory(
            label: entry.label,
            earned: group.earned,
            required: required,
            courses: group.courses,
          ),
        );
      } else {
        final earned = num(entry.earned);
        if ((required ?? 0) > 0 || (earned ?? 0) > 0) {
          categories.add(
            GraduationCreditCategory(
              label: entry.label,
              earned: earned ?? 0,
              required: required,
            ),
          );
        }
      }
    }
    for (final MapEntry(key: label, value: group) in groups.entries) {
      if (usedGroups.contains(label)) continue;
      categories.add(
        GraduationCreditCategory(
          label: label,
          earned: group.earned,
          courses: group.courses,
        ),
      );
    }

    final areas = <GraduationAreaProgress>[];
    for (final entry in areaTable?.entries ?? <_Column>[]) {
      final required = num(entry.required);
      final earned = num(entry.earned);
      if (required == null && earned == null) continue;
      areas.add(
        GraduationAreaProgress(
          label: entry.label,
          earned: earned ?? 0,
          required: required,
        ),
      );
    }

    final total = standard?.byLabel('졸업학점');
    final gpa = standard?.byLabel('졸업평점평균');
    return GraduationCreditSummary(
      totalRequired: num(total?.required),
      totalEarned: num(total?.earned) ?? courses?.grandTotal,
      gpa: dbl(gpa?.earned),
      gpaMinimum: dbl(gpa?.required),
      categories: categories,
      areas: areas,
      rules: _readRules(rows),
      fetchedAt: fetchedAt,
    );
  }

  /// 글자 칸을 쪽 → 세로 위치 순으로 줄 단위로 묶는다. 같은 줄이라도 칸마다
  /// `to`가 몇 정도 어긋나는 경우가 있어(학적 칸 612/615) 가까우면 같은 줄로 본다.
  static List<List<_Cell>> _readRows(String mml) {
    final cells = <_Cell>[];
    final pages = mml.split('<PG ');
    for (var page = 0; page < pages.length; page++) {
      for (final m in _cellPattern.allMatches(pages[page])) {
        final attrs = {
          for (final a in _attrPattern.allMatches(m.group(1)!))
            a.group(1)!: a.group(2)!,
        };
        cells.add(
          _Cell(
            page: page,
            tid: attrs['tid'] ?? '',
            left: int.tryParse(attrs['le'] ?? '') ?? 0,
            top: int.tryParse(attrs['to'] ?? '') ?? 0,
            text: _unescape(m.group(2)!),
          ),
        );
      }
    }
    cells.sort(
      (a, b) => a.page != b.page
          ? a.page.compareTo(b.page)
          : a.top != b.top
          ? a.top.compareTo(b.top)
          : a.left.compareTo(b.left),
    );

    final rows = <List<_Cell>>[];
    for (final cell in cells) {
      final last = rows.isEmpty ? null : rows.last;
      if (last != null &&
          last.first.page == cell.page &&
          cell.top - last.first.top <= 10) {
        last.add(cell);
      } else {
        rows.add([cell]);
      }
    }
    for (final row in rows) {
      row.sort((a, b) => a.left.compareTo(b.left));
    }
    return rows;
  }

  /// 과목 표. 표 머리("이수영역 | 년도학기 | 교과목명 | 학점 | 성적 | 구이수")가
  /// 한 줄에 좌우 두 번 나오는 2단 구성이라, 왼쪽 단을 끝까지 읽은 뒤 오른쪽 단을
  /// 읽는다. 과목은 바로 뒤에 나오는 "교필 취득학점 계 : 13" 소계의 묶음에 속한다.
  ///
  /// 실제 응답으로 확인한 건 왼쪽 단 1쪽뿐이다. 오른쪽 단·여러 쪽은 같은 규칙을
  /// 가정한다.
  static _CourseTable? _readCourses(List<List<_Cell>> rows) {
    final groups = <String, _Group>{};
    final pending = <(String area, GraduationCourseRecord record)>[];
    int? grandTotal;
    var foundHeader = false;

    void closeGroup(String label, int earned) {
      final group = groups.putIfAbsent(label, _Group.new);
      group.courses.addAll(pending.map((p) => p.$2));
      group.earned = max(group.earned, earned);
      pending.clear();
    }

    for (var i = 0; i < rows.length; i++) {
      final header = rows[i];
      final starts = [
        for (final c in header)
          if (c.tid == '1' && _squash(c.text) == '이수영역') c.left,
      ];
      if (starts.isEmpty || !header.any((c) => _squash(c.text) == '년도학기')) {
        continue;
      }
      foundHeader = true;

      // 머리 다음 줄부터, 다른 표(머리 tid=1)가 나오기 전까지가 과목 표다.
      final body = <List<_Cell>>[];
      for (var j = i + 1; j < rows.length; j++) {
        if (rows[j].first.page != header.first.page) break;
        if (rows[j].any((c) => c.tid == '1')) break;
        body.add(rows[j]);
      }

      for (var b = 0; b < starts.length; b++) {
        final from = starts[b] - 100;
        final to = b + 1 < starts.length ? starts[b + 1] - 100 : 1 << 30;
        bool inBlock(_Cell c) => c.left >= from && c.left < to;
        int? headerAt(String label) {
          for (final c in header) {
            if (inBlock(c) && _squash(c.text) == label) return c.left;
          }
          return null;
        }

        final creditAt = headerAt('학점');
        final gradeAt = headerAt('성적');
        for (final row in body) {
          final cells = [
            for (final c in row)
              if (inBlock(c)) c,
          ];
          final line = cells.map((c) => c.text.trim()).join(' ').trim();
          final total = _grandTotalPattern.firstMatch(line);
          if (total != null) {
            grandTotal = int.parse(total.group(1)!);
            continue;
          }
          final subtotal = _subtotalPattern.firstMatch(line);
          if (subtotal != null) {
            closeGroup(
              subtotal.group(1)!.trim(),
              int.parse(subtotal.group(2)!),
            );
            continue;
          }
          final course = _readCourse(cells, creditAt, gradeAt);
          if (course != null) pending.add(course);
        }
      }
    }
    if (!foundHeader) return null;

    // 소계 줄이 없이 끝난 과목은 과목에 적힌 이수영역 이름으로 묶는다.
    for (final (area, record) in List.of(pending)) {
      final group = groups.putIfAbsent(area, _Group.new);
      group.courses.add(record);
      group.earned += record.credit;
    }
    return _CourseTable(groups, grandTotal);
  }

  static (String, GraduationCourseRecord)? _readCourse(
    List<_Cell> cells,
    int? creditAt,
    int? gradeAt,
  ) {
    final semesterIndex = cells.indexWhere(
      (c) => _semesterPattern.hasMatch(c.text.trim()),
    );
    if (semesterIndex < 0) return null;
    bool near(_Cell c, int? at) => at != null && (c.left - at).abs() <= 150;

    int? credit;
    var grade = '';
    final name = <String>[];
    for (final c in cells.skip(semesterIndex + 1)) {
      final text = c.text.trim();
      if (near(c, creditAt)) {
        credit = int.tryParse(text);
      } else if (near(c, gradeAt)) {
        grade = text;
      } else if (creditAt != null && c.left < creditAt - 150) {
        if (!_courseCodePattern.hasMatch(text) && text.isNotEmpty) {
          name.add(text);
        }
      }
    }
    if (credit == null || name.isEmpty) return null;
    final area = cells
        .take(semesterIndex)
        .map((c) => c.text.trim())
        .join(' ')
        .trim();
    return (
      area,
      GraduationCourseRecord(
        name: name.join(' '),
        semester: cells[semesterIndex].text.trim(),
        credit: credit,
        grade: grade,
      ),
    );
  }

  /// "구 분 | 졸업학점 | …" 또는 "교양영역 | 1 | 2 | …" 머리 줄 아래의 "기 준" ·
  /// "취 득" 줄을 읽는다. 값 칸은 머리 칸과 같은 가로 위치에 놓이고, 빈 값은 칸
  /// 자체가 없다.
  static _Table? _readTable(
    List<List<_Cell>> rows,
    bool Function(String firstCell) isHeader,
  ) {
    for (var i = 0; i < rows.length; i++) {
      final header = [
        for (final c in rows[i])
          if (c.tid == '1') c,
      ];
      if (header.length < 2 || !isHeader(_squash(header.first.text))) continue;

      final labels = header.skip(1).toList();
      final values = <String, Map<int, String>>{};
      for (var j = i + 1; j < rows.length && values.length < 2; j++) {
        final row = [
          for (final c in rows[j])
            if (c.tid == '1') c,
        ];
        if (row.isEmpty) continue;
        final kind = _squash(row.first.text);
        if (kind != '기준' && kind != '취득') break;
        final byColumn = <int, String>{};
        for (final cell in row.skip(1)) {
          var best = -1;
          var bestGap = 200;
          for (var k = 0; k < labels.length; k++) {
            final gap = (cell.left - labels[k].left).abs();
            if (gap <= bestGap) {
              best = k;
              bestGap = gap;
            }
          }
          if (best >= 0 && cell.text.trim().isNotEmpty) {
            byColumn[best] = cell.text.trim();
          }
        }
        values.putIfAbsent(kind, () => byColumn);
      }
      return _Table([
        for (var k = 0; k < labels.length; k++)
          _Column(_squash(labels[k].text), values['기준']?[k], values['취득']?[k]),
      ]);
    }
    return null;
  }

  /// "① …", "② …" 안내문. 한 문단이 여러 줄로 나뉘어 있어 다음 번호가 나올
  /// 때까지 이어 붙인다.
  static List<String> _readRules(List<List<_Cell>> rows) {
    final rules = <String>[];
    var open = false;
    for (final row in rows) {
      final text = row.length == 1 && row.first.tid == '1'
          ? row.first.text.replaceAll(RegExp(r'\s+'), ' ').trim()
          : null;
      if (text == null || text.isEmpty) {
        open = false;
        continue;
      }
      if (_rulePattern.hasMatch(text)) {
        rules.add(text);
        open = true;
      } else if (open) {
        rules[rules.length - 1] = '${rules.last} $text';
      }
    }
    return rules;
  }

  static String _squash(String s) => s.replaceAll(RegExp(r'\s+'), '');

  static String _unescape(String s) => s
      .replaceAllMapped(
        RegExp(r'&#(x?)([0-9a-fA-F]+);'),
        (m) => String.fromCharCode(
          int.parse(m.group(2)!, radix: m.group(1)!.isEmpty ? 10 : 16),
        ),
      )
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&');

  // ---------------------------------------------------------------------------
  // 기기 저장
  // ---------------------------------------------------------------------------

  Future<GraduationCreditSummary?> _readStored(String key) async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(key);
      if (raw == null) return null;
      return GraduationCreditSummary.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (e) {
      // 저장된 값을 못 읽어도 서버에서 새로 받으면 되므로 조회를 막지 않는다.
      debugPrint('[GraduationCredit] 저장된 현황 읽기 실패: $e');
      return null;
    }
  }

  Future<void> _writeStored(String key, GraduationCreditSummary summary) async {
    try {
      await (await SharedPreferences.getInstance()).setString(
        key,
        jsonEncode(summary.toJson()),
      );
    } catch (e) {
      debugPrint('[GraduationCredit] 현황 저장 실패: $e');
    }
  }
}

class _Cell {
  const _Cell({
    required this.page,
    required this.tid,
    required this.left,
    required this.top,
    required this.text,
  });

  final int page;
  final String tid;
  final int left;
  final int top;
  final String text;
}

class _Group {
  int earned = 0;
  final List<GraduationCourseRecord> courses = [];
}

class _CourseTable {
  const _CourseTable(this.groups, this.grandTotal);

  final Map<String, _Group> groups;
  final int? grandTotal;
}

class _Column {
  const _Column(this.label, this.required, this.earned);

  final String label;
  final String? required;
  final String? earned;
}

class _Table {
  const _Table(this.entries);

  final List<_Column> entries;

  _Column? byLabel(String label) {
    for (final e in entries) {
      if (e.label == label) return e;
    }
    return null;
  }
}
