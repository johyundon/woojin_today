import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/advisor_submit_config.dart';
import 'twin_client.dart';

/// 지도교수 상담 인정 현황(명세 상세_4 2번)과 신청 이력 전체(5번).
class AdvisorOverview {
  const AdvisorOverview({
    required this.counts,
    required this.goalCount,
    required this.advisorStaffNo,
    required this.history,
    required this.fetchedAt,
  });

  /// '학기_학년'(예: '1_3' = 3학년 1학기) → 인정 횟수. 0회인 칸은 없다.
  final Map<String, int> counts;

  /// 졸업 기준 횟수. 편입생은 4, 그 외 12.
  final int goalCount;

  /// 지도교수 직번. 응답에서 못 찾으면 null.
  final String? advisorStaffNo;

  /// 신청 이력. 서버가 준 순서(최신순) 그대로.
  final List<ConsultationRecord> history;

  /// 서버에서 받아온 시각. 캐시 유효기간 판단에 쓴다.
  final DateTime fetchedAt;

  int get totalCount => counts.values.fold(0, (a, b) => a + b);

  int countOf({required int term, required int grade}) =>
      counts['${term}_$grade'] ?? 0;

  factory AdvisorOverview.fromJson(Map<String, dynamic> json) =>
      AdvisorOverview(
        counts: (json['counts'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, v as int),
        ),
        goalCount: json['goalCount'] as int,
        advisorStaffNo: json['advisorStaffNo'] as String?,
        history: [
          for (final e in json['history'] as List<dynamic>)
            ConsultationRecord.fromJson(e as Map<String, dynamic>),
        ],
        fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
    'counts': counts,
    'goalCount': goalCount,
    'advisorStaffNo': advisorStaffNo,
    'history': [for (final r in history) r.toJson()],
    'fetchedAt': fetchedAt.toIso8601String(),
  };
}

/// 신청 이력 한 줄(명세 5번).
class ConsultationRecord {
  const ConsultationRecord({
    required this.cnsKeyId,
    required this.appliedAt,
    required this.method,
    required this.status,
  });

  /// 상세보기에 넘기는 고유 키.
  final String cnsKeyId;
  final String appliedAt;

  /// '온라인상담' 등 서버 글자 그대로.
  final String method;

  /// '상담 대기', '상담 완료', '학생 취소' 등 서버 글자 그대로.
  final String status;

  factory ConsultationRecord.fromJson(Map<String, dynamic> json) =>
      ConsultationRecord(
        cnsKeyId: json['cnsKeyId'] as String,
        appliedAt: json['appliedAt'] as String,
        method: json['method'] as String,
        status: json['status'] as String,
      );

  Map<String, dynamic> toJson() => {
    'cnsKeyId': cnsKeyId,
    'appliedAt': appliedAt,
    'method': method,
    'status': status,
  };
}

/// 신청 이력 상세(명세 4번). 교수님이 아직 답하지 않았으면 답변 두 칸이 null.
class ConsultationDetailInfo {
  const ConsultationDetailInfo({
    required this.appliedAt,
    required this.status,
    required this.content,
    this.answeredAt,
    this.answerContent,
  });

  final String appliedAt;
  final String status;
  final String content;
  final String? answeredAt;
  final String? answerContent;

  factory ConsultationDetailInfo.fromJson(Map<String, dynamic> json) =>
      ConsultationDetailInfo(
        appliedAt: json['appliedAt'] as String,
        status: json['status'] as String,
        content: json['content'] as String,
        answeredAt: json['answeredAt'] as String?,
        answerContent: json['answerContent'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'appliedAt': appliedAt,
    'status': status,
    'content': content,
    'answeredAt': answeredAt,
    'answerContent': answerContent,
  };
}

/// 교수 검색 결과 한 명(명세 6번).
class ProfessorInfo {
  const ProfessorInfo({
    required this.staffNo,
    required this.name,
    required this.department,
  });

  final String staffNo;
  final String name;
  final String department;
}

/// 교수 검색 한 페이지와 전체 인원수.
class ProfessorSearchPage {
  const ProfessorSearchPage({required this.professors, required this.total});

  final List<ProfessorInfo> professors;
  final int total;
}

/// 방문 상담 가능 시간 한 칸(명세 7번).
class VisitSlot {
  const VisitSlot({required this.date, required this.time});

  /// 날짜(시각 없음).
  final DateTime date;

  /// 'HH:MM'.
  final String time;
}

/// 온라인 상담 신청 내용. 칸 이름은 학교 신청 화면의 실제 입력 칸에서 확인했다
/// (2026-10-31, `getProfCnsOnOffAjax.do` cnsOnoffDiv=ON).
class OnlineApplyRequest {
  const OnlineApplyRequest({
    required this.professorStaffNo,
    required this.content,
    required this.phone,
    required this.email,
    required this.advisorStaffNo,
    required this.advisorName,
  });

  final String professorStaffNo;
  final String content;

  /// '010-1234-5678'.
  final String phone;

  /// 비어 있으면 이메일 칸을 비워 보낸다(학교 화면도 이메일은 선택).
  final String email;

  /// 학교 화면이 숨은 칸으로 함께 보내는 본인 지도교수 직번·성함.
  final String advisorStaffNo;
  final String advisorName;
}

/// 방문 상담 신청 내용. 칸 이름은 학교 신청 화면의 실제 입력 칸에서 확인했다
/// (2026-10-31, `getProfCnsOnOffAjax.do` cnsOnoffDiv=OFF). 명세 9번에 없던
/// 연·월·주차, 학생 정보, 요일 표시 칸도 학교 화면처럼 함께 보낸다.
class VisitApplyRequest {
  const VisitApplyRequest({
    required this.professorStaffNo,
    required this.slot,
    required this.content,
    required this.phone,
    required this.email,
    required this.studentInfo,
  });

  final String professorStaffNo;
  final VisitSlot slot;
  final String content;
  final String phone;
  final String email;

  /// '학번 학과 학년 이름'(예: '20230000 OO전공 3학년 홍길동'). 학교 화면이
  /// 이 모양으로 채운다.
  final String studentInfo;
}

/// 실제 신청이 [kAllowRealAdvisorSubmit]로 막혀 있을 때. 네트워크 요청 전에 던진다.
class AdvisorSubmitBlockedException implements Exception {
  const AdvisorSubmitBlockedException();

  @override
  String toString() => '아직 실제 신청은 막혀 있어요';
}

/// [AdvisorConsultationService]의 공개 API. 화면은 이 타입으로 받아 테스트에서
/// 가짜를 끼운다. 실패는 모두 [TwinException]으로 던진다(로그인 실패 /
/// 응답을 못 읽음 / 통신 실패 구분).
abstract class AdvisorConsultationServiceBase {
  Future<AdvisorOverview> fetchOverview({
    required String userId,
    required String userPwd,
    bool forceRefresh = false,
  });

  Future<ConsultationDetailInfo> fetchDetail({
    required String userId,
    required String userPwd,
    required ConsultationRecord record,
  });

  Future<ProfessorSearchPage> searchProfessors({
    required String userId,
    required String userPwd,
    required String query,
    int page = 1,
  });

  /// [date]가 속한 주(월~금)의 상담 가능 시간.
  Future<List<VisitSlot>> fetchVisitSlots({
    required String userId,
    required String userPwd,
    required String staffNo,
    required DateTime date,
  });

  Future<void> submitOnline({
    required String userId,
    required String userPwd,
    required OnlineApplyRequest request,
  });

  Future<void> submitVisit({
    required String userId,
    required String userPwd,
    required VisitApplyRequest request,
  });
}

/// T-WIN(together.daejin.ac.kr)의 지도교수 상담 기능(명세 상세_4 1·2·4~9번).
///
/// 화면 하나에 하나씩 만들어 쓴다. 처음 부를 때 로그인하고 그 뒤로는 같은
/// 로그인을 재사용한다. 요청이 실패하면 로그인을 버려서, "다시 시도"할 때 새로
/// 로그인한다(세션이 끊긴 경우 대비).
///
/// 저장: 인정 현황+이력은 7일, 상세는 (키, 상태)별로 7일 기기에 저장한다. 상태가
/// 바뀌면(예: 대기 → 완료) 키가 달라져 새로 받는다. 교수 검색과 방문 시간은
/// 자주 바뀌어 저장하지 않는다(방문 시간은 이 객체가 살아 있는 동안만 기억).
/// 신청에 성공하면 인정 현황+이력 저장분을 지운다. 로그아웃하면
/// `logout_cleaner`가 기기 저장소를 통째로 지운다.
///
/// 신청(8·9번)은 교수님께 진짜 요청이 간다. [kAllowRealAdvisorSubmit]가 false면
/// 테스트용 [MockClient]가 아닌 한 요청을 보내기 전에
/// [AdvisorSubmitBlockedException]을 던진다.
class AdvisorConsultationService implements AdvisorConsultationServiceBase {
  AdvisorConsultationService({http.Client? client, DateTime Function()? now})
    : _client = client ?? http.Client(),
      _now = now ?? DateTime.now;

  static const cacheDuration = Duration(days: 7);
  static const _overviewKeyPrefix = 'advisor_overview_';
  static const _detailKeyPrefix = 'advisor_detail_';

  /// 이력 한 페이지 건수(명세: 실제 호출로 확인된 고정값).
  static const _historyPageSize = 5;

  static const _statusReferer =
      '${TwinClient.base}/myStatus/a/m/myStatusView.do';
  static const _cnsReferer = '${TwinClient.base}/myCns/a/m/getMyCnsMain.do';

  static final _cntPattern = RegExp(
    r'var\s+cnt\s*=\s*parseInt\("(\d+)"\)\s*,\s*grade\s*=\s*parseInt\("(\d+)"\);'
    r'[\s\S]*?\$\("#term"\+(\d+)\+"_"\+grade\)\.text',
  );
  static final _goalPattern = RegExp(
    r"""var\s+goalCnt\s*=\s*\("([^"]+)"\s*==\s*'B01003'""",
  );
  static final _staffNoPattern = RegExp(r'guidStaffNo=(\d+)');
  static final _totalCntPattern = RegExp(r"var\s+totalCnt\s*=\s*'(\d+)'");
  static final _profTotalPattern = RegExp(r'Total:\s*(\d+)');
  static final _weekDatePattern = RegExp(
    r"revsDate == '(MON|TUE|WED|THU|FRI)'\)[\s\S]*?"
    r"revDateText = '(\d{4}-\d{2}-\d{2})';",
  );
  static final _successPattern = RegExp(r'"rtnCode"\s*:\s*"?0"?\s*[,}]');

  final http.Client _client;
  final DateTime Function() _now;

  TwinClient? _twin;
  String? _loggedInUserId;
  final Map<String, List<VisitSlot>> _slotMemo = {};

  bool get _submitAllowed => kAllowRealAdvisorSubmit || _client is MockClient;

  @override
  Future<AdvisorOverview> fetchOverview({
    required String userId,
    required String userPwd,
    bool forceRefresh = false,
  }) async {
    final key = '$_overviewKeyPrefix$userId';
    if (!forceRefresh) {
      final cached = await _readStored(key, AdvisorOverview.fromJson);
      if (cached != null &&
          _now().difference(cached.fetchedAt) < cacheDuration) {
        return cached;
      }
    }
    final overview = await _withTwin(userId, userPwd, (twin) async {
      final statusBody = await _post(
        twin,
        '/myStatus/a/n/getMyStatusListAjax.do',
        'userId=&listType=cns&cnsDiv=CNSGB01',
        referer: _statusReferer,
      );
      final (counts, goal, staffNo) = parseStatus(statusBody);
      final history = await _fetchAllHistory(twin, userId);
      return AdvisorOverview(
        counts: counts,
        goalCount: goal,
        advisorStaffNo: staffNo,
        history: history,
        fetchedAt: _now(),
      );
    });
    await _writeStored(key, overview.toJson());
    return overview;
  }

  @override
  Future<ConsultationDetailInfo> fetchDetail({
    required String userId,
    required String userPwd,
    required ConsultationRecord record,
  }) async {
    final key =
        '$_detailKeyPrefix${userId}_${record.cnsKeyId}_${record.status}';
    final cached = await _readStored(key, (json) {
      final fetchedAt = DateTime.parse(json['fetchedAt'] as String);
      return _now().difference(fetchedAt) < cacheDuration
          ? ConsultationDetailInfo.fromJson(json)
          : null;
    });
    if (cached != null) return cached;

    final detail = await _withTwin(userId, userPwd, (twin) async {
      final body = await _post(
        twin,
        '/cnsHis/a/n/getCnsDetailInfoPop.do',
        'cnsKeyId=${Uri.encodeQueryComponent(record.cnsKeyId)}'
            '&cnsOnoffDiv=ON&cnsDiv=CNSGB01',
        referer: _cnsReferer,
      );
      return parseDetail(body);
    });
    await _writeStored(key, {
      ...detail.toJson(),
      'fetchedAt': _now().toIso8601String(),
    });
    return detail;
  }

  @override
  Future<ProfessorSearchPage> searchProfessors({
    required String userId,
    required String userPwd,
    required String query,
    int page = 1,
  }) => _withTwin(userId, userPwd, (twin) async {
    final trimmed = query.trim();
    final body = await _post(
      twin,
      '/careerCns/a/n/getProfSearchListPop.do',
      'pageIndex=$page'
          '${trimmed.isEmpty ? '' : '&korNm=${Uri.encodeQueryComponent(trimmed)}'}',
      referer: _cnsReferer,
    );
    return parseProfessors(body);
  });

  @override
  Future<List<VisitSlot>> fetchVisitSlots({
    required String userId,
    required String userPwd,
    required String staffNo,
    required DateTime date,
  }) async {
    final week = weekOfMonth(date);
    final month = date.month.toString().padLeft(2, '0');
    final memoKey = '${staffNo}_${date.year}_${month}_$week';
    final memo = _slotMemo[memoKey];
    if (memo != null) return memo;

    final slots = await _withTwin(userId, userPwd, (twin) async {
      final body = await _post(
        twin,
        '/cmm/fms/getCnsSchedulCalAjax.do',
        'curYear=${date.year}&curMonth=$month&curWeek=$week'
            '&cnsStaffId=${Uri.encodeQueryComponent(staffNo)}'
            '&cnsType=PROF&viewType=CLIENT',
        referer: _cnsReferer,
      );
      return parseVisitSlots(body);
    });
    return _slotMemo[memoKey] = slots;
  }

  @override
  Future<void> submitOnline({
    required String userId,
    required String userPwd,
    required OnlineApplyRequest request,
  }) async {
    if (!_submitAllowed) throw const AdvisorSubmitBlockedException();
    final (email1, email2) = _splitEmail(request.email);
    await _submit(userId, userPwd, '/careerCns/w/n/getCnsOnlineApplyAjax.do', {
      'radio1': 'on',
      'comProfId': request.professorStaffNo,
      'comApplyCont': request.content,
      'comApplyPhone': request.phone,
      'comApplyEmail1': email1,
      'comApplyEmail2': email2,
      'comApplyEmail': email1.isEmpty ? '' : request.email.trim(),
      'CNSGB01_idx': '1',
      'comGuidStaffNo': request.advisorStaffNo,
      'comGuidStaffNm': request.advisorName,
    }, emptyFileField: 'CNSGB01');
  }

  @override
  Future<void> submitVisit({
    required String userId,
    required String userPwd,
    required VisitApplyRequest request,
  }) async {
    if (!_submitAllowed) throw const AdvisorSubmitBlockedException();
    final date = request.slot.date;
    final (email1, email2) = _splitEmail(request.email);
    await _submit(userId, userPwd, '/careerCns/w/n/getCnsOfflineApplyAjax.do', {
      'radio1': 'on',
      'coaResrvCnlsrId': request.professorStaffNo,
      'coaResrvDate': formatDate(date),
      'coaResrvTime': request.slot.time.replaceAll(':', ''),
      'curYear': '${date.year}',
      'curMonth': date.month.toString().padLeft(2, '0'),
      'curWeek': '${weekOfMonth(date)}',
      'revStdInfo': request.studentInfo,
      'cnsType': 'PROF',
      'cnsRevsDate': 'SCD_${_weekdayCodes[date.weekday - 1]}_STATE',
      'coaApplyCont': request.content,
      'coaApplyPhone': request.phone,
      'coaApplyEmail1': email1,
      'coaApplyEmail2': email2,
      'coaApplyEmail': email1.isEmpty ? '' : request.email.trim(),
    });
  }

  Future<void> _submit(
    String userId,
    String userPwd,
    String path,
    Map<String, String> fields, {
    String? emptyFileField,
  }) async {
    await _withTwin(userId, userPwd, (twin) async {
      final request =
          http.MultipartRequest('POST', Uri.parse('${TwinClient.base}$path'))
            ..headers.addAll({
              'Origin': TwinClient.base,
              'Referer': _cnsReferer,
              'X-Requested-With': 'XMLHttpRequest',
            })
            ..fields.addAll(fields);
      if (emptyFileField != null) {
        request.files.add(
          http.MultipartFile.fromBytes(emptyFileField, const [], filename: ''),
        );
      }
      final (status, _, body) = await twin.send(
        request,
        followRedirects: false,
      );
      if (status != 200 || !_successPattern.hasMatch(body)) {
        throw TwinException(
          TwinFailure.noData,
          '상담 신청이 처리되지 않았어요 (응답 $status)',
        );
      }
    });
    _slotMemo.clear();
    try {
      (await SharedPreferences.getInstance()).remove(
        '$_overviewKeyPrefix$userId',
      );
    } catch (e) {
      debugPrint('[AdvisorConsultation] 저장분 지우기 실패: $e');
    }
  }

  /// 로그인을 재사용해 [action]을 한다. 실패하면 로그인을 버린다.
  Future<T> _withTwin<T>(
    String userId,
    String userPwd,
    Future<T> Function(TwinClient twin) action,
  ) async {
    try {
      var twin = _twin;
      if (twin == null || _loggedInUserId != userId) {
        twin = TwinClient(_client);
        await twin.login(userId, userPwd);
        _twin = twin;
        _loggedInUserId = userId;
      }
      return await action(twin);
    } on TwinException {
      _twin = null;
      rethrow;
    }
  }

  Future<String> _post(
    TwinClient twin,
    String path,
    String body, {
    required String referer,
  }) async {
    final (status, _, text) = await twin.send(
      twin.ajaxPost(path, body, referer: referer),
      followRedirects: false,
    );
    if (status != 200) {
      throw TwinException(TwinFailure.noData, '상담 정보를 받지 못했어요 (응답 $status)');
    }
    return text;
  }

  /// 명세 5번. 1페이지에서 전체 건수를 읽고 나머지 페이지는 한꺼번에 요청한다.
  Future<List<ConsultationRecord>> _fetchAllHistory(
    TwinClient twin,
    String userId,
  ) async {
    Future<String> page(int index) => _post(
      twin,
      '/cnsHis/a/n/getCnsHisListAjax.do',
      'pageIndex=$index&cnsDiv=CNSGB01'
          '&regId=${Uri.encodeQueryComponent(userId)}',
      referer: _cnsReferer,
    );

    final first = await page(1);
    final total =
        int.tryParse(_totalCntPattern.firstMatch(first)?.group(1) ?? '') ?? 0;
    final pageCount = total == 0 ? 1 : (total / _historyPageSize).ceil();
    final rest = await Future.wait([
      for (var i = 2; i <= pageCount; i++) page(i),
    ]);
    return [
      for (final body in [first, ...rest]) ...parseHistory(body),
    ];
  }

  /// 명세 2번. 상담이 한 번도 없으면 횟수 줄이 아예 없으므로, 횟수를 채우는
  /// 함수(`setGraduteCnsStatus`)가 있는데 줄이 없으면 0회로 본다. 그 함수조차
  /// 없으면 응답을 못 읽은 것이다.
  @visibleForTesting
  static (Map<String, int>, int, String?) parseStatus(String body) {
    final counts = <String, int>{};
    for (final m in _cntPattern.allMatches(body)) {
      final key = '${m.group(3)}_${m.group(2)}';
      counts[key] = (counts[key] ?? 0) + int.parse(m.group(1)!);
    }
    if (counts.isEmpty && !body.contains('setGraduteCnsStatus')) {
      throw const TwinException(TwinFailure.noData, '상담 인정 현황을 찾지 못했어요');
    }
    final goal = _goalPattern.firstMatch(body)?.group(1) == 'B01003' ? 4 : 12;
    return (counts, goal, _staffNoPattern.firstMatch(body)?.group(1));
  }

  @visibleForTesting
  static List<ConsultationRecord> parseHistory(String body) => [
    for (final row
        in html_parser.parse(body).querySelectorAll('table tbody tr'))
      if (row.querySelectorAll('td') case final cells
          when cells.length >= 5 &&
              (cells[4]
                          .querySelector('button')
                          ?.attributes['data-param1']
                          ?.trim() ??
                      '')
                  .isNotEmpty)
        ConsultationRecord(
          cnsKeyId: cells[4]
              .querySelector('button')!
              .attributes['data-param1']!
              .trim(),
          appliedAt: cells[1].text.trim(),
          method: cells[2].text.trim(),
          status: cells[3].text.trim(),
        ),
  ];

  @visibleForTesting
  static ConsultationDetailInfo parseDetail(String body) {
    final map = <String, String>{};
    for (final row
        in html_parser.parse(body).querySelectorAll('table tbody tr')) {
      final th = row.querySelector('th');
      final td = row.querySelector('td');
      if (th != null && td != null) map[th.text.trim()] = td.text.trim();
    }
    final appliedAt = map['신청일시'];
    final status = map['상태'];
    final content = map['신청 내용'];
    if (appliedAt == null || status == null || content == null) {
      throw const TwinException(TwinFailure.noData, '상담 상세 내용을 찾지 못했어요');
    }
    String? optional(String label) {
      final v = map[label];
      return v == null || v.isEmpty ? null : v;
    }

    return ConsultationDetailInfo(
      appliedAt: appliedAt,
      status: status,
      content: content,
      answeredAt: optional('답변일시'),
      answerContent: optional('답변 내용'),
    );
  }

  @visibleForTesting
  static ProfessorSearchPage parseProfessors(String body) {
    final professors = <ProfessorInfo>[];
    for (final row
        in html_parser.parse(body).querySelectorAll('table tbody tr')) {
      final cells = row.querySelectorAll('td');
      if (cells.length < 3) continue;
      final name = cells[0].text.trim();
      final staffNo =
          cells[2].querySelector('a')?.attributes['data-param1']?.trim() ?? '';
      if (name.isEmpty || staffNo.isEmpty) continue;
      professors.add(
        ProfessorInfo(
          staffNo: staffNo,
          name: name,
          department: cells[1].text.trim(),
        ),
      );
    }
    final total =
        int.tryParse(_profTotalPattern.firstMatch(body)?.group(1) ?? '') ?? 0;
    return ProfessorSearchPage(professors: professors, total: total);
  }

  /// 명세 7번. 가능 칸은 `label.counsel_possible`(학교 스크립트 기준, 실물은
  /// 2026-10-31 시점 미확인). 날짜 매핑이 없으면 빈 주로 본다.
  @visibleForTesting
  static List<VisitSlot> parseVisitSlots(String body) {
    final dates = {
      for (final m in _weekDatePattern.allMatches(body))
        m.group(1)!: DateTime.tryParse(m.group(2)!),
    };
    final slots = <VisitSlot>[];
    for (final label
        in html_parser
            .parse(body)
            .querySelectorAll('label.counsel_possible[for]')) {
      final parts = label.attributes['for']!.split('_');
      if (parts.length != 2) continue;
      final date = dates[parts[0]];
      final code = parts[1];
      if (date == null || code.length != 4) continue;
      slots.add(
        VisitSlot(
          date: date,
          time: '${code.substring(0, 2)}:${code.substring(2)}',
        ),
      );
    }
    return slots;
  }

  /// 학교가 쓰는 "그 달의 몇째 주". 일요일에 시작하는 주로 센다 — 2026년 9월
  /// 1주차가 8/31(월)부터, 11월 1주차가 11/2(월)부터인 실제 응답과 맞는다.
  static int weekOfMonth(DateTime date) {
    final firstWeekday = DateTime(date.year, date.month).weekday % 7; // 일=0
    return (date.day + firstWeekday - 1) ~/ 7 + 1;
  }

  static String formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}'
      '-${d.day.toString().padLeft(2, '0')}';

  static const _weekdayCodes = [
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN',
  ];

  static (String, String) _splitEmail(String email) {
    final trimmed = email.trim();
    final at = trimmed.indexOf('@');
    if (at < 0) return (trimmed, '');
    return (trimmed.substring(0, at), trimmed.substring(at + 1));
  }

  Future<T?> _readStored<T>(
    String key,
    T? Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(key);
      if (raw == null) return null;
      return fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      // 저장된 값을 못 읽어도 서버에서 새로 받으면 되므로 조회를 막지 않는다.
      debugPrint('[AdvisorConsultation] 저장된 값 읽기 실패: $e');
      return null;
    }
  }

  Future<void> _writeStored(String key, Map<String, dynamic> json) async {
    try {
      await (await SharedPreferences.getInstance()).setString(
        key,
        jsonEncode(json),
      );
    } catch (e) {
      debugPrint('[AdvisorConsultation] 저장 실패: $e');
    }
  }
}
