import 'dart:convert';
import 'dart:io';

import 'package:daejin_app/screens/cafeteria/models/cafeteria_menu.dart';
import 'package:daejin_app/services/cafeteria_menu_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 명세서의 응답 예시에는 메뉴가 담긴 칸이 없어서, 명세의 파싱 규칙(코너 `[..]`,
// `/` -> `·`, `span`의 가격)에 맞춰 직접 만든 HTML이다. 실제 응답으로 검증된
// 것이 아니다.
const _html = '''
<html><head><meta charset="UTF-8"></head><body>
<div class="box-table"><table>
<thead><tr>
<th scope="col">식단구분</th>
<th scope="col">월<br>2026.09.14</th><th scope="col">화<br>2026.09.15</th>
<th scope="col">수<br>2026.09.16</th><th scope="col">목<br>2026.09.17</th>
<th scope="col">금<br>2026.09.18</th><th scope="col">토<br>2026.09.19</th>
<th scope="col">일<br>2026.09.20</th>
</tr></thead>
<tbody>
<tr><th scope="row">조식</th>
<td class="no-data">등록된 식단내용이(가) 없습니다.</td>
<td class="no-data">등록된 식단내용이(가) 없습니다.</td>
<td class="no-data">등록된 식단내용이(가) 없습니다.</td>
<td class="no-data">등록된 식단내용이(가) 없습니다.</td>
<td class="no-data">등록된 식단내용이(가) 없습니다.</td>
<td class="no-data">등록된 식단내용이(가) 없습니다.</td>
<td class="no-data">등록된 식단내용이(가) 없습니다.</td></tr>
<tr><th scope="row">점심</th>
<td>[데일리밥] /제육볶음/된장찌개/ <span>[가격 : 5,000원]</span></td>
<td class="no-data">등록된 식단내용이(가) 없습니다.</td>
<td class="no-data">등록된 식단내용이(가) 없습니다.</td>
<td class="no-data">등록된 식단내용이(가) 없습니다.</td>
<td class="no-data">등록된 식단내용이(가) 없습니다.</td>
<td class="no-data">등록된 식단내용이(가) 없습니다.</td>
<td class="no-data">등록된 식단내용이(가) 없습니다.</td></tr>
<tr>
<td>돈까스/우동</td>
<td class="no-data">등록된 식단내용이(가) 없습니다.</td>
<td class="no-data">등록된 식단내용이(가) 없습니다.</td>
<td class="no-data">등록된 식단내용이(가) 없습니다.</td>
<td class="no-data">등록된 식단내용이(가) 없습니다.</td>
<td class="no-data">등록된 식단내용이(가) 없습니다.</td>
<td class="no-data">등록된 식단내용이(가) 없습니다.</td></tr>
</tbody></table></div>
</body></html>
''';

void main() {
  // 서비스는 주 단위 결과를 메모리와 기기에 캐시하므로, 테스트마다 비워서 서로
  // 영향을 주지 않게 한다.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CafeteriaMenuService.clearMemoryCache();
  });

  _realResponseTests();
  _cacheTests();

  test('주간 표를 날짜별 끼니 메뉴로 바꾸고, 같은 주는 다시 요청하지 않는다', () async {
    var calls = 0;
    late http.Request captured;
    final service = CafeteriaMenuService(
      client: MockClient((request) async {
        calls++;
        captured = request;
        return http.Response.bytes(utf8.encode(_html), 200);
      }),
    );

    // 수요일을 요청해도 그 주의 월요일 날짜로 조회한다.
    final wed = await service.fetchMenu(DateTime(2026, 9, 16));
    expect(captured.bodyFields['monday'], '2026.09.14');
    expect(captured.bodyFields['week'], '');
    expect(wed.isEmpty, isTrue);

    final mon = await service.fetchMenu(DateTime(2026, 9, 14));
    expect(calls, 1);
    expect(mon.breakfast, isEmpty);
    expect(mon.lunch, hasLength(2));
    expect(mon.lunch[0].restaurant, '데일리밥');
    expect(mon.lunch[0].dishes, ['제육볶음', '된장찌개']);
    expect(mon.lunch[0].price, 5000);
    expect(mon.lunch[1].restaurant, '학생회관'); // 코너 표시 없으면 기본값
    expect(mon.lunch[1].dishes, ['돈까스', '우동']);
    expect(mon.lunch[1].price, isNull);
  });

  test('서버 오류와 네트워크 오류는 CafeteriaMenuException으로 알린다', () async {
    final serverError = CafeteriaMenuService(
      client: MockClient((_) async => http.Response('', 500)),
    );
    expect(
      serverError.fetchMenu(DateTime(2026, 1, 5)),
      throwsA(isA<CafeteriaMenuException>()),
    );

    final networkError = CafeteriaMenuService(
      client: MockClient((_) async => throw http.ClientException('끊김')),
    );
    expect(
      networkError.fetchMenu(DateTime(2026, 1, 12)),
      throwsA(isA<CafeteriaMenuException>()),
    );
  });

  test('표가 없는 응답은 7일 모두 메뉴 없음으로 돌려준다', () async {
    final service = CafeteriaMenuService(
      client: MockClient(
        (_) async => http.Response.bytes(utf8.encode('<html></html>'), 200),
      ),
    );
    final menu = await service.fetchMenu(DateTime(2026, 2, 3));
    expect(menu.isEmpty, isTrue);
    expect(menu, isA<DailyCafeteriaMenu>());
  });
}

// 2026-10-30에 학교 서버에서 실제로 받은 2026.10.26 주 응답이다.
void _realResponseTests() {
  group('실제 응답(2026.10.26 주)', () {
    late CafeteriaMenuService service;

    setUp(() {
      final bytes = File(
        'test/services/fixtures/cafeteria_diet_2026_10_26.html',
      ).readAsBytesSync();
      service = CafeteriaMenuService(
        client: MockClient((_) async => http.Response.bytes(bytes, 200)),
      );
    });

    test('월~금 모두 조식·점심이 읽히고 저녁은 비어 있다', () async {
      for (final day in [26, 27, 28, 29, 30]) {
        final menu = await service.fetchMenu(DateTime(2026, 10, day));
        expect(menu.lunch, isNotEmpty, reason: '10/$day 점심');
        expect(menu.dinner, isEmpty);
      }
      final mon = await service.fetchMenu(DateTime(2026, 10, 26));
      expect(mon.breakfast.single.restaurant, '천원의밥상');
      expect(mon.breakfast.single.price, 1000);
      expect(mon.lunch.map((e) => e.restaurant), [
        '데일리밥',
        '누들송',
        '크레이지팬',
        '돈카츠락',
      ]);
      expect(mon.lunch.map((e) => e.price), [4300, 5200, 5500, 5700]);
    });

    test('"*미운영*"인 금요일 조식은 메뉴 없음이다', () async {
      final fri = await service.fetchMenu(DateTime(2026, 10, 30));
      expect(fri.breakfast, isEmpty);
    });

    test('프리미엄식탁은 코너 이름과 음식·안내 문구가 모두 읽힌다', () async {
      final tue = await service.fetchMenu(DateTime(2026, 10, 27));
      final premium = tue.lunch.firstWhere((e) => e.restaurant == '프리미엄식탁');
      expect(premium.price, 8500);
      expect(premium.dishes, ['옛날반마리통닭', '샐러드', '치킨무', '콜라', '(기숙사생 카드태그 불가)']);
    });

    test('토·일은 메뉴 없음이다', () async {
      final sat = await service.fetchMenu(DateTime(2026, 10, 31));
      expect(sat.isEmpty, isTrue);
    });
  });
}

void _cacheTests() {
  group('캐시(월요일 06:00 기준)', () {
    // 2026-10-26(월) 주를 조회한다.
    final target = DateTime(2026, 10, 28);

    CafeteriaMenuService serviceAt(
      DateTime now,
      List<DateTime> calls, {
      bool clearMemory = true,
    }) {
      if (clearMemory) CafeteriaMenuService.clearMemoryCache();
      return CafeteriaMenuService(
        now: () => now,
        client: MockClient((_) async {
          calls.add(now);
          return http.Response.bytes(utf8.encode(_html), 200);
        }),
      );
    }

    test('월요일 06:00 이후에 받은 값은 앱을 껐다 켜도(메모리를 비워도) 다시 요청하지 않는다', () async {
      final calls = <DateTime>[];
      await serviceAt(DateTime(2026, 10, 27, 12), calls).fetchMenu(target);
      final menu = await serviceAt(
        DateTime(2026, 10, 28, 9),
        calls,
      ).fetchMenu(target);
      expect(calls, hasLength(1));
      expect(menu, isA<DailyCafeteriaMenu>());
    });

    test('저장된 값에서 코너·음식·가격이 그대로 복원된다', () async {
      final calls = <DateTime>[];
      // 응답 예시(_html)의 2026.09.14 주를 월요일 06:00 이후에 받아 저장한다.
      await serviceAt(
        DateTime(2026, 9, 14, 9),
        calls,
      ).fetchMenu(DateTime(2026, 9, 14));
      final restored = await serviceAt(
        DateTime(2026, 9, 15, 9),
        calls,
      ).fetchMenu(DateTime(2026, 9, 14));
      expect(calls, hasLength(1));
      expect(restored.lunch.first.restaurant, '데일리밥');
      expect(restored.lunch.first.dishes, ['제육볶음', '된장찌개']);
      expect(restored.lunch.first.price, 5000);
      expect(restored.lunch.last.price, isNull);
    });

    test('월요일 06:00 전에 받아 둔 값은 06:00이 지난 뒤 처음 조회할 때 새로 받는다', () async {
      final calls = <DateTime>[];
      // 지난 금요일에 다음 주(10/26 주)를 미리 받아 둔다.
      await serviceAt(DateTime(2026, 10, 23, 18), calls).fetchMenu(target);
      // 월요일 05:59 — 아직 06:00 전이라 저장된 값을 쓴다.
      await serviceAt(DateTime(2026, 10, 26, 5, 59), calls).fetchMenu(target);
      expect(calls, hasLength(1));
      // 월요일 06:00 — 새로 받는다.
      await serviceAt(DateTime(2026, 10, 26, 6), calls).fetchMenu(target);
      expect(calls, hasLength(2));
      // 새로 받은 값은 06:00 이후 것이라 그다음부터는 다시 안 받는다.
      await serviceAt(DateTime(2026, 10, 27, 9), calls).fetchMenu(target);
      expect(calls, hasLength(2));
    });

    test('같은 앱 실행 중 요일만 바꿔 조회해도 다시 요청하지 않는다', () async {
      final calls = <DateTime>[];
      final service = serviceAt(DateTime(2026, 10, 23, 18), calls);
      for (final day in [26, 27, 28]) {
        await service.fetchMenu(DateTime(2026, 10, day));
      }
      expect(calls, hasLength(1));
    });
  });
}
