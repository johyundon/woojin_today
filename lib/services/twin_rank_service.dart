import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'twin_client.dart';

/// T-WIN 성적 조회가 어디서 실패했는지. 로그인 코드를 [TwinClient]로 옮기면서
/// 공용 타입의 다른 이름으로 남겼다(화면·테스트가 이 이름을 쓴다).
typedef TwinRankFailure = TwinFailure;
typedef TwinRankException = TwinException;

/// T-WIN에서 받아온 학과·학년 성적 정보. 등수는 여기서 계산하지 않는다.
class TwinGradeStats {
  const TwinGradeStats({
    required this.myGpa,
    required this.sameGradeAvg,
    required this.peerGpas,
    required this.totalCount,
    required this.fetchedAt,
  });

  /// 내 평점(`li.grade_my strong`).
  final double myGpa;

  /// 같은 학년 평균(`li.grade_same strong`). 응답에 없으면 null.
  final double? sameGradeAvg;

  /// 같은 학과·학년 학생들의 평점. 서버가 준 순서 그대로.
  final List<double> peerGpas;

  /// 서버가 알려준 전체 인원수(`totalCnt`).
  final int totalCount;

  /// 서버에서 받아온 시각. 캐시 유효기간 판단에 쓴다.
  final DateTime fetchedAt;

  factory TwinGradeStats.fromJson(Map<String, dynamic> json) => TwinGradeStats(
    myGpa: (json['myGpa'] as num).toDouble(),
    sameGradeAvg: (json['sameGradeAvg'] as num?)?.toDouble(),
    peerGpas: [
      for (final v in json['peerGpas'] as List<dynamic>) (v as num).toDouble(),
    ],
    totalCount: json['totalCount'] as int,
    fetchedAt: DateTime.parse(json['fetchedAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'myGpa': myGpa,
    'sameGradeAvg': sameGradeAvg,
    'peerGpas': peerGpas,
    'totalCount': totalCount,
    'fetchedAt': fetchedAt.toIso8601String(),
  };
}

/// [TwinRankService]의 공개 API. 화면은 이 타입으로 받아 테스트에서 가짜를 끼운다.
abstract class TwinRankServiceBase {
  /// [sustCd] 학과코드(예: AA0194), [shyrCd] 학년코드.
  /// [forceRefresh]가 true면 캐시를 무시하고 서버에서 새로 받는다.
  Future<TwinGradeStats> fetchGradeStats({
    required String userId,
    required String userPwd,
    required String sustCd,
    required String shyrCd,
    bool forceRefresh = false,
  });
}

/// T-WIN(together.daejin.ac.kr)에 로그인해 내 평점과 같은 학과·학년 평점 목록을
/// 받아온다(명세: 상세_2 "학과순위" 1~3번).
///
/// 결과는 기기에 7일 동안 저장해 두고 다시 요청하지 않는다. 평점은 학기 단위로만
/// 바뀌는데, 한 번 받는 데 요청이 15번 안팎 나가기 때문이다. 실패한 결과는
/// 저장하지 않는다. 로그아웃하면 `logout_cleaner`가 기기 저장소를 통째로 지운다.
///
/// 로그인과 요청 보내기는 [TwinClient]가 맡는다(서버별 쿠키 보관 포함).
class TwinRankService implements TwinRankServiceBase {
  TwinRankService({http.Client? client, DateTime Function()? now})
    : _client = client ?? http.Client(),
      _now = now ?? DateTime.now;

  static const _referer = '${TwinClient.base}/myFuture/a/m/myFutureView.do';

  static const cacheDuration = Duration(days: 7);
  static const _prefsKeyPrefix = 'twin_rank_';

  /// 동기 목록 한 페이지 인원(명세: 실제 호출로 확인된 고정값).
  static const _pageSize = 5;

  static final _totalCntPattern = RegExp(r"var\s+totalCnt\s*=\s*'(\d+)'");

  final http.Client _client;
  final DateTime Function() _now;

  @override
  Future<TwinGradeStats> fetchGradeStats({
    required String userId,
    required String userPwd,
    required String sustCd,
    required String shyrCd,
    bool forceRefresh = false,
  }) async {
    final prefsKey = '$_prefsKeyPrefix${userId}_${sustCd}_$shyrCd';
    if (!forceRefresh) {
      final cached = await _readStored(prefsKey);
      if (cached != null &&
          _now().difference(cached.fetchedAt) < cacheDuration) {
        return cached;
      }
    }

    final twin = TwinClient(_client);
    await twin.login(userId, userPwd);
    final (myGpa, sameGradeAvg) = await _fetchMyGpa(twin, sustCd, shyrCd);
    final (peers, total) = await _fetchPeers(twin, sustCd, shyrCd);

    final stats = TwinGradeStats(
      myGpa: myGpa,
      sameGradeAvg: sameGradeAvg,
      peerGpas: peers,
      totalCount: total,
      fetchedAt: _now(),
    );
    await _writeStored(prefsKey, stats);
    return stats;
  }

  /// 명세 2번. `li.grade_my strong`이 내 평점, `li.grade_same strong`이 같은 학년 평균.
  Future<(double, double?)> _fetchMyGpa(
    TwinClient twin,
    String sustCd,
    String shyrCd,
  ) async {
    final (status, _, body) = await twin.send(
      twin.ajaxPost(
        '/myFuture/a/n/getResultDivInfoPage.do',
        'sustCd=$sustCd&shyrCd=$shyrCd&pageIndex=1'
            '&searchType=STD_GROUP&roadMapType=SAMEGRADE',
        referer: _referer,
      ),
      followRedirects: false,
    );
    final doc = html_parser.parse(body);
    double? number(String selector) =>
        double.tryParse(doc.querySelector(selector)?.text.trim() ?? '');
    final myGpa = status == 200 ? number('li.grade_my strong') : null;
    if (myGpa == null) {
      throw TwinRankException(
        TwinRankFailure.noData,
        '평점을 찾지 못했어요 (응답 $status)',
      );
    }
    return (myGpa, number('li.grade_same strong'));
  }

  /// 명세 3번. 1페이지에서 전체 인원수를 읽고, 나머지 페이지는 한꺼번에 요청한 뒤
  /// 페이지 순서대로 이어 붙인다.
  Future<(List<double>, int)> _fetchPeers(
    TwinClient twin,
    String sustCd,
    String shyrCd,
  ) async {
    Future<String> page(int index) async {
      final (status, _, body) = await twin.send(
        twin.ajaxPost(
          '/myFuture/r/n/getGrStdCompareListAjax.do',
          'sustCd=$sustCd&shyrCd=$shyrCd&searchType=STD_GROUP'
              '&pageIndex=$index',
          referer: _referer,
        ),
        followRedirects: false,
      );
      if (status != 200) {
        throw TwinRankException(
          TwinRankFailure.noData,
          '동기 평점 목록을 받지 못했어요 (응답 $status)',
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
    return (
      [
        for (final body in [first, ...rest]) ..._parsePeerRows(body),
      ],
      total,
    );
  }

  static List<double> _parsePeerRows(String body) => [
    for (final row
        in html_parser.parse(body).querySelectorAll('table tbody tr'))
      if (row.querySelectorAll('td') case final cells when cells.length > 1)
        ?double.tryParse(cells[1].text.trim()),
  ];

  Future<TwinGradeStats?> _readStored(String key) async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(key);
      if (raw == null) return null;
      return TwinGradeStats.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      // 저장된 값을 못 읽어도 서버에서 새로 받으면 되므로 조회를 막지 않는다.
      debugPrint('[TwinRank] 저장된 성적 읽기 실패: $e');
      return null;
    }
  }

  Future<void> _writeStored(String key, TwinGradeStats stats) async {
    try {
      await (await SharedPreferences.getInstance()).setString(
        key,
        jsonEncode(stats.toJson()),
      );
    } catch (e) {
      debugPrint('[TwinRank] 성적 저장 실패: $e');
    }
  }
}
