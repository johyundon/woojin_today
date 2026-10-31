import 'dart:convert';

import 'package:daejin_app/services/academic_schedule_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 2026-10-31 실제 응답(10월분)의 구조를 본떠 만든 HTML이다.
const _html = '''
<html><body>
<div class="month-search-box"><a href="#" onclick="jf_month('11')">11월</a></div>
<table class="calendar"><tbody><tr><td class="sun">4</td><td>5</td></tr></tbody></table>
<div class="applyList calList">
  <table>
    <tbody>
      <tr>
        <th scope="row" class="first last">2026.10.05(Mon)</th>
        <td class="first last">수업일수 1/3선<br></td>
      </tr>
      <tr>
        <th scope="row" class="first last">2026.10.20(Tue)
          ~ 2026.11.01(Sun)</th>
        <td class="first last">중간   수업평가<br></td>
      </tr>
      <tr><th scope="row">날짜 없음</th><td>버릴 행</td></tr>
      <tr><th scope="row">2026.10.22(Thu)</th><td> </td></tr>
      <tr><td>th 없는 행</td></tr>
    </tbody>
  </table>
</div>
</body></html>
''';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('날짜가 하나면 하루, 둘이면 기간으로 읽고 빈 행은 건너뛴다', () {
    final items = AcademicScheduleService.parse(_html);

    expect(items.length, 2);
    expect(items[0].title, '수업일수 1/3선');
    expect(items[0].start, DateTime(2026, 10, 5));
    expect(items[0].end, DateTime(2026, 10, 5));
    expect(items[1].title, '중간 수업평가');
    expect(items[1].start, DateTime(2026, 10, 20));
    expect(items[1].end, DateTime(2026, 11, 1));
  });

  test('id는 시작일+제목이라 다른 달 응답에서 받아도 같다', () {
    final a = AcademicScheduleItem(
      start: DateTime(2026, 10, 20),
      end: DateTime(2026, 11, 1),
      title: '중간 수업평가',
    );
    final b = AcademicScheduleItem.fromJson(a.toJson());

    expect(a.id, 'school-20261020-중간 수업평가');
    expect(b.id, a.id);
    expect(b.end, DateTime(2026, 11, 1));
  });

  test('연·월을 폼으로 보내고 결과를 돌려준다', () async {
    late http.Request captured;
    final service = AcademicScheduleService(
      client: MockClient((request) async {
        captured = request;
        return http.Response.bytes(utf8.encode(_html), 200);
      }),
    );

    final items = await service.fetchMonth(2027, 1);

    expect(captured.method, 'POST');
    expect(captured.bodyFields, {'year': '2027', 'month': '1'});
    expect(captured.headers['User-Agent'], contains('Mobile'));
    expect(items.length, 2);
  });

  test('같은 달은 하루 동안 다시 요청하지 않고, 하루가 지나면 새로 받는다', () async {
    var calls = 0;
    var now = DateTime(2026, 10, 31, 10);
    final service = AcademicScheduleService(
      client: MockClient((_) async {
        calls++;
        return http.Response.bytes(utf8.encode(_html), 200);
      }),
      now: () => now,
    );

    await service.fetchMonth(2026, 10);
    now = now.add(const Duration(hours: 23, minutes: 59));
    final cached = await service.fetchMonth(2026, 10);
    expect(calls, 1);
    expect(cached.map((i) => i.id), [
      'school-20261005-수업일수 1/3선',
      'school-20261020-중간 수업평가',
    ]);

    // 다른 달은 따로 저장한다.
    await service.fetchMonth(2026, 11);
    expect(calls, 2);

    now = now.add(const Duration(minutes: 1));
    await service.fetchMonth(2026, 10);
    expect(calls, 3);

    await service.fetchMonth(2026, 10, forceRefresh: true);
    expect(calls, 4);
  });

  test('통신 실패와 서버 오류를 구분하고, 실패는 저장하지 않는다', () async {
    await expectLater(
      AcademicScheduleService(
        client: MockClient((_) async => throw Exception('offline')),
      ).fetchMonth(2026, 10),
      throwsA(
        isA<AcademicScheduleException>().having(
          (e) => e.isNetwork,
          'isNetwork',
          true,
        ),
      ),
    );
    await expectLater(
      AcademicScheduleService(
        client: MockClient((_) async => http.Response('err', 500)),
      ).fetchMonth(2026, 10),
      throwsA(
        isA<AcademicScheduleException>().having(
          (e) => e.isNetwork,
          'isNetwork',
          false,
        ),
      ),
    );

    var calls = 0;
    await AcademicScheduleService(
      client: MockClient((_) async {
        calls++;
        return http.Response.bytes(utf8.encode(_html), 200);
      }),
    ).fetchMonth(2026, 10);
    expect(calls, 1);
  });
}
