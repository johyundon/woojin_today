import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart';

import '../screens/notice/models/notice_item.dart';
import 'notice_service.dart';
import 'twin_client.dart';

/// 내가 참여한 비교과 프로그램 한 건(T-WIN My-Status > 비교과 "비교과 이수 현황").
///
/// 2026-11-14 실제 응답에서 확인한 9칸 표(상태/활동 영역/활동명/운영시작일/
/// 운영종료일/운영부서/출석현황/출석률/획득마일리지) 중 화면에 쓰는 칸만 담는다.
class MileageEntry {
  const MileageEntry({
    required this.date,
    required this.category,
    required this.title,
    required this.department,
    required this.status,
    required this.points,
  });

  /// 운영시작일. 서버가 준 글자 그대로(예: "2026-05-01").
  final String date;

  /// 활동 영역(예: "취, 창업 지원 Let's DJ (Discover Job)").
  final String category;

  /// 활동명.
  final String title;

  /// 운영부서(예: 취업팀).
  final String department;

  /// 상태(예: 이수).
  final String status;

  /// 획득 마일리지. 7.5처럼 소수도 온다.
  final double points;

  /// [date]를 날짜로 읽는다. "2026-03-15", "2026.03.15" 모두 받는다.
  DateTime? get parsedDate {
    final m = RegExp(r'(\d{4})\D(\d{1,2})\D(\d{1,2})').firstMatch(date);
    if (m == null) return null;
    return DateTime(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
    );
  }

  factory MileageEntry.fromJson(Map<String, dynamic> json) => MileageEntry(
    date: json['date'] as String,
    category: json['category'] as String,
    title: json['title'] as String,
    department: json['department'] as String,
    status: json['status'] as String,
    points: (json['points'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'date': date,
    'category': category,
    'title': title,
    'department': department,
    'status': status,
    'points': points,
  };
}

/// 내 마일리지 현황(명세: 상세_3 2번)과 비교과 이수 내역.
class MileageStatus {
  const MileageStatus({
    required this.points,
    required this.sameGradeRank,
    required this.history,
    required this.fetchedAt,
  });

  /// 내 마일리지 점수(`div.mymileage_score p strong`). 학기마다 초기화되는
  /// 지금 점수로 보인다(지난 학기 이수 내역이 있어도 0으로 오는 것을 확인).
  final int points;

  /// 동일학년 기준 내 순위(`div.ranking`). 2026-10-31 실제 응답에서
  /// "※ 동일학년 기준"이 함께 붙어 있는 것을 확인했다.
  final int sameGradeRank;

  /// 비교과 이수 내역. 운영시작일 최신순.
  final List<MileageEntry> history;

  /// 서버에서 받아온 시각. 캐시 유효기간 판단에 쓴다.
  final DateTime fetchedAt;

  factory MileageStatus.fromJson(Map<String, dynamic> json) => MileageStatus(
    points: json['points'] as int,
    sameGradeRank: json['sameGradeRank'] as int,
    history: [
      for (final e in json['history'] as List<dynamic>)
        MileageEntry.fromJson(e as Map<String, dynamic>),
    ],
    fetchedAt: DateTime.parse(json['fetchedAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'points': points,
    'sameGradeRank': sameGradeRank,
    'history': [for (final e in history) e.toJson()],
    'fetchedAt': fetchedAt.toIso8601String(),
  };
}

/// 장학 대상자 확인 결과.
enum MileageTargetResult {
  /// 명단에 내 학번이 있다.
  target,

  /// 명단에 내 학번이 없다.
  notTarget,

  /// 공지에 xlsx 명단이 붙어 있지 않다.
  noRoster,
}

/// [MileageService]의 공개 API. 화면은 이 타입으로 받아 테스트에서 가짜를 끼운다.
abstract class MileageServiceBase {
  /// 내 점수·순위·비교과 이수 내역. [forceRefresh]면 캐시를 무시하고 새로 받는다.
  /// 실패하면 [TwinException].
  Future<MileageStatus> fetchStatus({
    required String userId,
    required String userPwd,
    bool forceRefresh = false,
  });

  /// 마일리지장학 공지 중 제목에 "대상자"가 들어간 것 최신 5개.
  /// 실패하면 [NoticeException].
  Future<List<NoticeItem>> fetchTargetNotices({bool forceRefresh = false});

  /// [detailPath] 공지의 xlsx 명단에 [studentId]가 있는지. 명단은 결과만 보고
  /// 버리며 화면에 넘기거나 저장하지 않는다. 실패하면 [NoticeException].
  Future<MileageTargetResult> checkTarget({
    required String detailPath,
    required String studentId,
  });
}

/// 마일리지 화면의 실제 데이터를 가져온다(명세: 상세_3 "마일리지" 1~6번).
///
/// 내 현황·비교과 이수 내역은 T-WIN에 한 번 로그인해서 같이 받고, 기기에 하루 동안
/// 저장해 둔다. 실패한 결과는 저장하지 않는다. 로그아웃하면 `logout_cleaner`가
/// 기기 저장소를 통째로 지운다.
///
/// 공지·명단은 학교 홈페이지(www)에서 받으며 로그인이 필요 없다.
class MileageService implements MileageServiceBase {
  MileageService({http.Client? client, DateTime Function()? now})
    : _client = client ?? http.Client(),
      _now = now ?? DateTime.now,
      _notices = NoticeService(client: client, now: now);

  static const cacheDuration = Duration(days: 1);

  /// 내역 형식이 지급 내역에서 비교과 이수 내역으로 바뀌어 키를 새로 쓴다.
  static const _prefsKeyPrefix = 'mileage_status_v2_';
  static const _referer = '${TwinClient.base}/myStatus/a/m/myStatusView.do';
  static const _historyReferer =
      '${TwinClient.base}/myStatus/a/m/getMyStatus.do';

  /// 이수 내역 한 페이지 건수(2026-11-14 실제 응답의 페이지 스크립트 값).
  static const _pageSize = 5;
  static const _targetNoticeCount = 5;

  static final _totalCntPattern = RegExp(r"var\s+totalCnt\s*=\s*'(\d+)'");

  final http.Client _client;
  final DateTime Function() _now;
  final NoticeService _notices;

  @override
  Future<MileageStatus> fetchStatus({
    required String userId,
    required String userPwd,
    bool forceRefresh = false,
  }) async {
    final prefsKey = '$_prefsKeyPrefix$userId';
    if (!forceRefresh) {
      final cached = await _readStored(prefsKey);
      if (cached != null &&
          _now().difference(cached.fetchedAt) < cacheDuration) {
        return cached;
      }
    }

    final twin = TwinClient(_client);
    await twin.login(userId, userPwd);
    final (status, _, body) = await twin.send(
      twin.ajaxPost(
        '/myStatus/a/n/getMyStatusListAjax.do',
        'listType=mileage',
        referer: _referer,
      ),
      followRedirects: false,
    );
    final summary = status == 200 ? parseStatus(body) : null;
    if (summary == null) {
      throw TwinException(TwinFailure.noData, '마일리지 점수를 찾지 못했어요 (응답 $status)');
    }
    final history = await _fetchHistory(twin, userId);

    final result = MileageStatus(
      points: summary.points,
      sameGradeRank: summary.rank,
      history: history,
      fetchedAt: _now(),
    );
    await _writeStored(prefsKey, result);
    return result;
  }

  /// 명세 2번. 점수·순위를 읽는다. 하나라도 없으면 null.
  @visibleForTesting
  static ({int points, int rank})? parseStatus(String body) {
    final doc = html_parser.parse(body);
    final points = int.tryParse(
      doc.querySelector('div.mymileage_score p strong')?.text.trim() ?? '',
    );
    final rankText =
        doc
            .querySelector('div.ranking')
            ?.nodes
            .whereType<Text>()
            .map((t) => t.text)
            .join() ??
        '';
    final rank = int.tryParse(
      RegExp(r'\d+').firstMatch(rankText)?.group(0) ?? '',
    );
    if (points == null || rank == null) return null;
    return (points: points, rank: rank);
  }

  /// 비교과 이수 내역(T-WIN My-Status > 비교과 탭이 부르는 주소, 2026-11-14
  /// 실제 응답 확인). 학년·학기 구분 없이 지금까지 이수한 프로그램이 모두 온다.
  /// 1페이지에서 전체 건수를 읽고, 나머지 페이지는 한꺼번에 요청한 뒤 이어 붙여
  /// 운영시작일 최신순으로 정렬한다(서버 순서는 날짜순이 아니다).
  Future<List<MileageEntry>> _fetchHistory(
    TwinClient twin,
    String userId,
  ) async {
    Future<String> page(int index) async {
      final (status, _, body) = await twin.send(
        twin.ajaxPost(
          '/mileageHis/a/n/getMileageHistListAjax.do',
          'userId=${Uri.encodeQueryComponent(userId)}'
              '&programType=NCR_PROGRAM&pageIndex=$index',
          referer: _historyReferer,
        ),
        followRedirects: false,
      );
      if (status != 200) {
        throw TwinException(
          TwinFailure.noData,
          '비교과 이수 내역을 받지 못했어요 (응답 $status)',
        );
      }
      return body;
    }

    final first = await page(1);
    final total =
        int.tryParse(_totalCntPattern.firstMatch(first)?.group(1) ?? '') ?? 0;
    final pageCount = total == 0 ? 1 : (total / _pageSize).ceil();
    final rest = await Future.wait([
      for (var i = 2; i <= pageCount; i++) page(i),
    ]);
    final entries = [
      for (final body in [first, ...rest]) ...parseHistoryRows(body),
    ];
    // 날짜를 못 읽은 행은 맨 뒤로 보낸다.
    final oldest = DateTime(0);
    entries.sort(
      (a, b) => (b.parsedDate ?? oldest).compareTo(a.parsedDate ?? oldest),
    );
    return entries;
  }

  /// 이수 내역 한 페이지의 행. 칸 순서는 상태/활동 영역/활동명/운영시작일/
  /// 운영종료일/운영부서/출석현황/출석률/획득마일리지. 칸이 9개 미만인 행(내역이
  /// 없을 때 오는 안내 행 등)은 버린다.
  @visibleForTesting
  static List<MileageEntry> parseHistoryRows(String body) => [
    for (final row
        in html_parser.parse(body).querySelectorAll('table tbody tr'))
      if ([
            for (final c in row.children)
              if (c.localName == 'th' || c.localName == 'td') c.text.trim(),
          ]
          case final cells when cells.length >= 9)
        MileageEntry(
          status: cells[0],
          category: cells[1],
          title: cells[2],
          date: cells[3],
          department: cells[5],
          points:
              double.tryParse(
                RegExp(r'-?\d+(\.\d+)?').firstMatch(cells[8])?.group(0) ?? '',
              ) ??
              0,
        ),
  ];

  @override
  Future<List<NoticeItem>> fetchTargetNotices({
    bool forceRefresh = false,
  }) async {
    final all = await _notices.fetchNotices(
      NoticeBoard.mileage,
      forceRefresh: forceRefresh,
    );
    return all
        .where((n) => n.title.contains('대상자') && n.detailPath != null)
        .take(_targetNoticeCount)
        .toList();
  }

  @override
  Future<MileageTargetResult> checkTarget({
    required String detailPath,
    required String studentId,
  }) async {
    final detail = await _notices.fetchDetail(detailPath);
    final roster = detail.attachments
        .where((a) => a.name.trim().toLowerCase().endsWith('.xlsx'))
        .firstOrNull;
    if (roster == null) return MileageTargetResult.noRoster;
    final bytes = await _notices.downloadBytes(roster.url);
    return rosterContains(bytes, studentId)
        ? MileageTargetResult.target
        : MileageTargetResult.notTarget;
  }

  /// xlsx 안의 모든 시트·셀 중 [studentId]와 같은 값이 있는지(명세 6번).
  ///
  /// 실제 명단(2026-10-31 확인)은 학번만 숫자 칸에 들어 있고, 공유 문자열 파일
  /// (`xl/sharedStrings.xml`)이 아예 없기도 하다. 서버가 주는 Content-Type은
  /// 믿지 않고 파일 앞 두 글자가 zip 표시 `PK`인지로 확인한다.
  @visibleForTesting
  static bool rosterContains(Uint8List bytes, String studentId) {
    final target = studentId.trim();
    if (bytes.length < 2 || bytes[0] != 0x50 || bytes[1] != 0x4B) {
      throw const NoticeException('명단 파일이 엑셀(xlsx) 형식이 아니에요');
    }
    final Archive zip;
    try {
      zip = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw const NoticeException('명단 파일을 열지 못했어요');
    }

    XmlDocument? xmlOf(String name) {
      final file = zip.findFile(name);
      if (file == null) return null;
      try {
        return XmlDocument.parse(
          utf8.decode(file.readBytes() ?? const [], allowMalformed: true),
        );
      } catch (_) {
        throw const NoticeException('명단 파일을 읽지 못했어요');
      }
    }

    String texts(XmlElement e) =>
        e.findAllElements('t').map((t) => t.innerText).join();

    final shared = [
      for (final si
          in xmlOf('xl/sharedStrings.xml')?.findAllElements('si') ??
              const <XmlElement>[])
        texts(si),
    ];

    final sheetName = RegExp(r'^xl/worksheets/sheet\d+\.xml$');
    for (final file in zip.files) {
      if (!sheetName.hasMatch(file.name)) continue;
      for (final cell in xmlOf(file.name)!.findAllElements('c')) {
        final type = cell.getAttribute('t');
        String value;
        if (type == 'inlineStr') {
          final inline = cell.getElement('is');
          value = inline == null ? '' : texts(inline);
        } else {
          value = cell.getElement('v')?.innerText ?? '';
          if (type == 's') {
            final index = int.tryParse(value.trim());
            if (index != null && index >= 0 && index < shared.length) {
              value = shared[index];
            }
          }
        }
        if (_normalizeCell(value) == target) return true;
      }
    }
    return false;
  }

  /// 숫자 칸이 "20201234.0"이나 "2.0201234E7"로 저장된 경우도 정수 글자로 맞춘다.
  static String _normalizeCell(String raw) {
    final v = raw.trim();
    if (v.contains('.') || v.contains('E') || v.contains('e')) {
      final d = double.tryParse(v);
      if (d != null && d == d.truncateToDouble() && d.abs() < 1e15) {
        return d.toInt().toString();
      }
    }
    return v;
  }

  Future<MileageStatus?> _readStored(String key) async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(key);
      if (raw == null) return null;
      return MileageStatus.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      // 저장된 값을 못 읽어도 서버에서 새로 받으면 되므로 조회를 막지 않는다.
      debugPrint('[Mileage] 저장된 마일리지 읽기 실패: $e');
      return null;
    }
  }

  Future<void> _writeStored(String key, MileageStatus status) async {
    try {
      await (await SharedPreferences.getInstance()).setString(
        key,
        jsonEncode(status.toJson()),
      );
    } catch (e) {
      debugPrint('[Mileage] 마일리지 저장 실패: $e');
    }
  }
}
