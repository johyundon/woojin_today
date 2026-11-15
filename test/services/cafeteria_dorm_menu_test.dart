// 생활관식당(게시판 6번) 학식과, 학생식당·생활관식당 메뉴를 합치는 서비스를 확인한다.
import 'dart:io';

import 'package:daejin_app/screens/cafeteria/models/cafeteria_menu.dart';
import 'package:daejin_app/services/cafeteria_menu_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 2026-11-15에 학교 서버에서 실제로 받은 생활관 2026.11.16 주 응답.
final _dormBytes = File(
  'test/services/fixtures/cafeteria_dorm_diet_2026_11_16.html',
).readAsBytesSync();

/// 2026-11-15에 학교 서버에서 실제로 받은 교직원식당 2026.11.16 주 응답.
final _staffBytes = File(
  'test/services/fixtures/cafeteria_staff_diet_2026_11_16.html',
).readAsBytesSync();

/// 고정된 메뉴를 돌려주는 가짜 식당. [error]가 있으면 던진다.
class _FixedService implements CafeteriaMenuServiceBase {
  _FixedService(this.menu, {this.error});

  final DailyCafeteriaMenu menu;
  final Object? error;

  @override
  Future<DailyCafeteriaMenu> fetchMenu(DateTime date) async {
    if (error != null) throw error!;
    return menu;
  }
}

CafeteriaMenuItem _item(String name, CafeteriaVenue venue) => CafeteriaMenuItem(
  restaurant: name,
  dishes: [name],
  price: null,
  venue: venue,
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CafeteriaMenuService.clearMemoryCache();
  });

  group('생활관식당 실제 응답(2026.11.16 주)', () {
    final urls = <Uri>[];
    late CafeteriaMenuService service;

    setUp(() {
      urls.clear();
      service = CafeteriaMenuService.dormitory(
        client: MockClient((request) async {
          urls.add(request.url);
          return http.Response.bytes(_dormBytes, 200);
        }),
      );
    });

    test('6번 게시판에 요청하고, 아침·점심·저녁을 생활관식당 메뉴로 읽는다', () async {
      final mon = await service.fetchMenu(DateTime(2026, 11, 16));

      expect(urls.single.path, '/diet/daejin/6/view.do');
      final breakfast = mon.breakfast.single;
      expect(breakfast.restaurant, '생활관식당'); // 칸에 코너 표시가 없다
      expect(breakfast.venue, CafeteriaVenue.dorm);
      expect(breakfast.dishes, ['콘참치마요삼각김밥', '미니고구마파이', '바이오플레포도맛']);
      expect(breakfast.price, 5500);
      expect(mon.lunch.single.dishes.first, '사골우거지국');
      expect(mon.dinner.single.dishes.first, '갈릭베이컨볶음밥');
      expect(mon.dinner.single.venue, CafeteriaVenue.dorm);
    });

    test('주말은 아침이 없고 점심·저녁은 있다', () async {
      final sat = await service.fetchMenu(DateTime(2026, 11, 21));
      expect(sat.breakfast, isEmpty);
      expect(sat.lunch.single.dishes.first, '장조림버터볶음밥');
      expect(sat.dinner.single.dishes.first, '종합꼬치어묵탕');
    });

    test('기기에 저장했다 다시 읽어도 생활관식당으로 복원된다', () async {
      await service.fetchMenu(DateTime(2026, 11, 16));
      CafeteriaMenuService.clearMemoryCache();
      final restored = await service.fetchMenu(DateTime(2026, 11, 17));
      expect(urls, hasLength(1));
      expect(restored.lunch.single.venue, CafeteriaVenue.dorm);
    });
  });

  group('교직원식당 실제 응답(2026.11.16 주)', () {
    final urls = <Uri>[];
    late CafeteriaMenuService service;

    setUp(() {
      urls.clear();
      service = CafeteriaMenuService.staff(
        client: MockClient((request) async {
          urls.add(request.url);
          return http.Response.bytes(_staffBytes, 200);
        }),
      );
    });

    test('5번 게시판에 요청하고, 평일 점심을 교직원식당 메뉴로 읽는다', () async {
      final mon = await service.fetchMenu(DateTime(2026, 11, 16));

      expect(urls.single.path, '/diet/daejin/5/view.do');
      expect(mon.breakfast, isEmpty);
      expect(mon.dinner, isEmpty);
      final lunch = mon.lunch.single;
      expect(lunch.restaurant, '교직원식당'); // 칸에 코너 표시가 없다
      expect(lunch.venue, CafeteriaVenue.staff);
      expect(lunch.dishes.take(3), ['설렁탕', '쌀밥', '통등심육전']);
      expect(lunch.price, 7000);
    });

    test('미운영인 금요일과 주말은 메뉴 없음이다', () async {
      for (final day in [20, 21, 22]) {
        final menu = await service.fetchMenu(DateTime(2026, 11, day));
        expect(menu.isEmpty, isTrue, reason: '11/$day');
      }
    });
  });

  test('학생식당과 생활관식당은 같은 주라도 저장을 따로 하고 각자 한 번씩 요청한다', () async {
    final paths = <String>[];
    final client = MockClient((request) async {
      paths.add(request.url.path);
      return http.Response.bytes(_dormBytes, 200);
    });
    final student = CafeteriaMenuService(client: client);
    final dorm = CafeteriaMenuService.dormitory(client: client);

    await student.fetchMenu(DateTime(2026, 11, 16));
    await dorm.fetchMenu(DateTime(2026, 11, 16));
    await student.fetchMenu(DateTime(2026, 11, 17));
    await dorm.fetchMenu(DateTime(2026, 11, 17));

    expect(paths, ['/diet/daejin/2/view.do', '/diet/daejin/6/view.do']);
  });

  group('식당 합치기', () {
    final studentMenu = DailyCafeteriaMenu(
      lunch: [_item('데일리밥', CafeteriaVenue.student)],
    );
    final dormMenu = DailyCafeteriaMenu(
      lunch: [_item('생활관 점심', CafeteriaVenue.dorm)],
      dinner: [_item('생활관 저녁', CafeteriaVenue.dorm)],
    );

    test('끼니별로 학생식당 다음에 생활관식당 메뉴를 붙인다', () async {
      final menu = await CombinedCafeteriaMenuService([
        _FixedService(studentMenu),
        _FixedService(dormMenu),
      ]).fetchMenu(DateTime(2026, 11, 16));

      expect(menu.lunch.map((e) => e.restaurant), ['데일리밥', '생활관 점심']);
      expect(menu.dinner.map((e) => e.restaurant), ['생활관 저녁']);
    });

    test('한 식당이 실패해도 나머지 식당 메뉴는 보여준다', () async {
      final menu = await CombinedCafeteriaMenuService([
        _FixedService(
          studentMenu,
          error: const CafeteriaMenuException('서버 오류 (500)'),
        ),
        _FixedService(dormMenu),
      ]).fetchMenu(DateTime(2026, 11, 16));

      expect(menu.lunch.map((e) => e.restaurant), ['생활관 점심']);
    });

    test('모든 식당이 실패하면 CafeteriaMenuException을 그대로 던진다', () async {
      final combined = CombinedCafeteriaMenuService([
        _FixedService(
          studentMenu,
          error: const CafeteriaMenuException('네트워크 오류'),
        ),
        _FixedService(
          dormMenu,
          error: const CafeteriaMenuException('서버 오류 (500)'),
        ),
      ]);
      expect(
        combined.fetchMenu(DateTime(2026, 11, 16)),
        throwsA(isA<CafeteriaMenuException>()),
      );
    });
  });
}
