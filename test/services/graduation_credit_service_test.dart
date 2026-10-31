import 'dart:convert';
import 'dart:io';

import 'package:daejin_app/services/graduation_credit_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 실제 응답(2026-10-31)에서 학번·이름·학과·과목명·과목코드·성적·평점을 가짜
/// 값으로 바꾸고 칸 위치·이수영역·학기·학점만 남긴 예제.
final _report = File('test/services/fixtures/graduation_credit_report.mml')
    .readAsStringSync();
final _viewer = File('test/services/fixtures/graduation_credit_viewer.html')
    .readAsStringSync();

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('parseReport', () {
    final summary = GraduationCreditService.parseReport(
      _report,
      fetchedAt: DateTime(2026, 10, 31),
    );

    test('졸업학점·졸업평점 기준과 취득을 읽는다', () {
      expect(summary.totalRequired, 126);
      expect(summary.totalEarned, 107);
      expect(summary.gpa, 3.50);
      expect(summary.gpaMinimum, 2.00);
    });

    test('이수구분은 학교 소계 단위로 묶고 기준표 순서를 따른다', () {
      expect(summary.categories.map((c) => c.label), [
        '교필',
        '교선',
        '전필',
        '전선',
        '복전',
        '일선',
      ]);
      final byLabel = {for (final c in summary.categories) c.label: c};
      expect(byLabel['교필']!.earned, 13);
      expect(byLabel['교필']!.required, 12);
      expect(byLabel['교필']!.courseCount, 8);
      expect(byLabel['교선']!.earned, 31);
      expect(byLabel['교선']!.required, 24);
      expect(byLabel['교선']!.courseCount, 13);
      expect(byLabel['전필']!.required, 12);
      expect(byLabel['전선']!.courseCount, 16);
      // 들은 과목이 없어도 기준이 있는 구분은 보여준다.
      expect(byLabel['복전']!.earned, 0);
      expect(byLabel['복전']!.required, 36);
      expect(byLabel['복전']!.courses, isEmpty);
      // 기준표에 없는 구분은 기준 없이 둔다.
      expect(byLabel['일선']!.earned, 9);
      expect(byLabel['일선']!.required, isNull);
      // 기준·취득이 모두 0이거나 빈 구분(기초·전기)은 뺀다.
      expect(byLabel.containsKey('기초'), isFalse);
      expect(byLabel.containsKey('전기'), isFalse);
    });

    test('과목 한 줄을 학기·과목명·학점·성적으로 읽고, 수강 중이면 성적이 비어 있다', () {
      final first = summary.categories.first.courses.first;
      expect(first.semester, '2021-1');
      expect(first.name, '과목01');
      expect(first.credit, 2);
      expect(first.grade, 'A+');

      final major = summary.categories.firstWhere((c) => c.label == '전선');
      expect(major.courses.last.semester, '2026-2');
      expect(major.courses.last.grade, '');
    });

    test('교양영역은 값이 있는 칸만, 기준이 빈 칸은 기준 없이 읽는다', () {
      expect(summary.areas.map((a) => a.label), [
        '1',
        '2',
        '3',
        '4',
        '5',
        '6',
        '7',
        '8',
      ]);
      expect(summary.areas.map((a) => a.earned), [2, 2, 2, 8, 2, 6, 6, 3]);
      expect(summary.areas.take(6).map((a) => a.required), everyElement(1));
      expect(summary.areas[6].required, isNull);
    });

    test('여러 줄로 나뉜 안내문을 번호 단위 문단으로 잇는다', () {
      expect(summary.rules, hasLength(3));
      expect(summary.rules[0], startsWith('① 학생의 졸업사정'));
      expect(summary.rules[2], contains('마이크로전공 12학점'));
    });

    test('(실제 응답 미확인) 왼쪽 단에서 끝나지 않은 구분은 오른쪽 단 소계로 이어진다', () {
      String tl(String tid, int le, int to, String text) =>
          '<TL tid="$tid" le="$le" to="$to">$text</TL>';
      final mml = [
        '<MML version="2.9"><BODY><PG no="1">',
        for (final (le, label) in [
          (202, '이수영역'),
          (644, '년도학기'),
          (1170, '교과목명'),
          (2956, '학점'),
          (3236, '성적'),
          (3942, '이수영역'),
          (4384, '년도학기'),
          (4910, '교과목명'),
          (6696, '학점'),
          (6976, '성적'),
        ])
          tl('1', le, 822, label),
        tl('3', 170, 1015, '전선'),
        tl('3', 654, 1015, '2024-1'),
        tl('3', 1714, 1015, '왼쪽과목'),
        tl('3', 2984, 1015, '3'),
        tl('3', 3264, 1015, 'A'),
        tl('3', 3910, 1015, '전선'),
        tl('3', 4394, 1015, '2024-2'),
        tl('3', 5454, 1015, '오른쪽과목'),
        tl('3', 6724, 1015, '3'),
        tl('3', 7004, 1015, 'B'),
        tl('3', 5450, 1131, '전선 취득학점 계 : 6'),
        '</PG></BODY></MML>',
      ].join();

      final parsed = GraduationCreditService.parseReport(
        mml,
        fetchedAt: DateTime(2026),
      );
      expect(parsed.categories.single.label, '전선');
      expect(parsed.categories.single.earned, 6);
      expect(parsed.categories.single.courses.map((c) => c.name), [
        '왼쪽과목',
        '오른쪽과목',
      ]);
    });

    test('표가 하나도 없으면 형식 오류', () {
      expect(
        () => GraduationCreditService.parseReport(
          '<MML version="2.9"><BODY></BODY></MML>',
          fetchedAt: DateTime(2026),
        ),
        throwsA(isA<GraduationCreditParseException>()),
      );
    });
  });

  group('fetchSummary', () {
    late List<http.Request> requests;

    MockClient client({String? viewer, int reportStatus = 200}) =>
        MockClient((request) async {
          requests.add(request);
          if (request.url.path.endsWith('sugang_wlsn0555.jsp')) {
            return http.Response.bytes(
              utf8.encode(viewer ?? _viewer),
              200,
              headers: {'content-type': 'text/html; charset=euc-kr'},
            );
          }
          return http.Response.bytes(
            utf8.encode(_report),
            reportStatus,
            headers: {'content-type': 'text/xml;charset=utf-8'},
          );
        });

    setUp(() => requests = []);

    test('리포트 주소를 받아 그대로 form 인코딩해 보낸다', () async {
      final summary = await GraduationCreditService(client: client())
          .fetchSummary(userId2: 'uid');

      expect(summary.totalEarned, 107);
      expect(requests, hasLength(2));
      final post = requests[1];
      expect(post.method, 'POST');
      expect(post.headers['Cookie'], startsWith('userId=uid; orgCd='));
      expect(post.headers['Content-Type'], 'application/x-www-form-urlencoded');
      final fields = Uri.splitQueryString(post.body);
      expect(fields['mrd_path'], '%26%3bFAKEPATH%29');
      expect(fields['mrd_param'], '%26%3aFAKEPARAM%3e');
      expect(fields['opcode'], '700');
      expect(fields['enc_type'], '5');
    });

    test('7일 안에는 저장된 값을 쓰고, 새로고침이나 7일 뒤에는 다시 받는다', () async {
      var now = DateTime(2026, 10, 31);
      final service = GraduationCreditService(client: client(), now: () => now);

      await service.fetchSummary(userId2: 'uid');
      now = now.add(const Duration(days: 6));
      await service.fetchSummary(userId2: 'uid');
      expect(requests, hasLength(2));

      await service.fetchSummary(userId2: 'uid', forceRefresh: true);
      expect(requests, hasLength(4));

      now = now.add(const Duration(days: 8));
      await service.fetchSummary(userId2: 'uid');
      expect(requests, hasLength(6));
    });

    test('리포트 주소가 없으면 형식 오류', () async {
      await expectLater(
        GraduationCreditService(client: client(viewer: '<html></html>'))
            .fetchSummary(userId2: 'uid'),
        throwsA(isA<GraduationCreditParseException>()),
      );
    });

    test('200이 아니면 서버 오류', () async {
      await expectLater(
        GraduationCreditService(client: client(reportStatus: 500))
            .fetchSummary(userId2: 'uid'),
        throwsA(isA<GraduationCreditServerException>()),
      );
    });

    test('연결이 끊기면 네트워크 오류', () async {
      await expectLater(
        GraduationCreditService(
          client: MockClient((_) async => throw http.ClientException('끊김')),
        ).fetchSummary(userId2: 'uid'),
        throwsA(isA<GraduationCreditNetworkException>()),
      );
    });
  });
}
