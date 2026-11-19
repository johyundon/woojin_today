// 홈 학식 카드: 지금 시각의 끼니(아침·점심·저녁) 메뉴에서 음료·김치·밥 같은 곁들이를 빼고
// 한 장에 하나씩 보여 주며 3초마다 다음 장으로 넘기고, 마지막 다음에는 처음으로 돌아온다.
// 장이 하나뿐이면 넘기지 않는다.

import 'package:daejin_app/screens/cafeteria/models/cafeteria_menu.dart';
import 'package:daejin_app/screens/home/widgets/cafeteria_menu_card.dart';
import 'package:daejin_app/services/cafeteria_menu_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeService implements CafeteriaMenuServiceBase {
  _FakeService(this.lunch, this.dinner);
  final List<CafeteriaMenuItem> lunch;
  final List<CafeteriaMenuItem> dinner;

  @override
  Future<DailyCafeteriaMenu> fetchMenu(DateTime date) async =>
      DailyCafeteriaMenu(lunch: lunch, dinner: dinner);
}

Future<void> _pump(
  WidgetTester tester,
  List<CafeteriaMenuItem> lunch, {
  DateTime? now,
  List<CafeteriaMenuItem> dinner = const [],
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 180,
        child: CafeteriaMenuCard(
          now: now ?? DateTime(2026, 11, 16, 11),
          onTap: () {},
          service: _FakeService(lunch, dinner),
        ),
      ),
    ),
  ),
);

Future<void> _next(WidgetTester tester) async {
  await tester.pump(CafeteriaMenuCard.autoSlide);
  await tester.pumpAndSettle();
}

void main() {
  const dorm = CafeteriaMenuItem(
    restaurant: '생활관식당',
    dishes: ['시골된장찌개', '쌀밥', '제육볶음', '김치', '요구르트'],
    price: 5500,
    venue: CafeteriaVenue.dorm,
  );
  const student = CafeteriaMenuItem(
    restaurant: '학생식당',
    dishes: ['김치찌개', '쌀밥'],
    price: 5000,
  );

  test('곁들이를 빼고 식당마다 메뉴를 한 장에 하나씩 둔다', () {
    final pages = menuPages(const [dorm, student]);
    expect(
      [for (final p in pages) p.dishes],
      [
        ['시골된장찌개'],
        ['제육볶음'],
        ['김치찌개'],
      ],
    );
    expect(pages.last.item.restaurant, '학생식당');
  });

  test('실제 학식에 나온 음료·김치·피클·밥은 곁들이로 본다', () {
    for (final side in [
      '주스', '사과주스', '콜라', '초코우유', '바이요요플레사과', '요구르트', //
      '배추김치', '깍두기', '단무지', '피클', '블루베리무피클', '치킨무',
      '마늘쫑장아찌', '갓절임', '미니고추지', '오복채', '쌀밥', '옥수수수염차',
    ]) {
      expect(isSideDish(side), isTrue, reason: side);
    }
    for (final main in ['참치김치찌개', '김치전', '불향제육덮밥', '왕등심돈까스', '설렁탕', '김가루밥']) {
      expect(isSideDish(main), isFalse, reason: main);
    }
  });

  test('메뉴가 다 곁들이면 그대로 보여 준다', () {
    const drinks = CafeteriaMenuItem(
      restaurant: '매점',
      dishes: ['주스', '우유'],
      price: 1000,
    );
    expect(
      [
        for (final p in menuPages(const [drinks])) p.dishes,
      ],
      [
        ['주스'],
        ['우유'],
      ],
    );
  });

  testWidgets('식당이 하나여도 3초마다 다음 메뉴로 넘어가고 끝나면 처음으로 돌아온다', (tester) async {
    await _pump(tester, const [dorm]);
    await tester.pumpAndSettle();
    expect(find.text('시골된장찌개'), findsOneWidget);

    await _next(tester);
    expect(find.text('제육볶음'), findsOneWidget);
    await _next(tester);
    expect(find.text('시골된장찌개'), findsOneWidget);
    expect(find.text('생활관식당'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('장이 하나뿐이면 넘기지 않는다', (tester) async {
    await _pump(tester, const [student]);
    await tester.pumpAndSettle();
    await tester.pump(CafeteriaMenuCard.autoSlide * 2);
    await tester.pumpAndSettle();
    expect(find.text('김치찌개'), findsOneWidget);
  });

  testWidgets('오후 3시가 지나면 "오늘 저녁"과 석식 메뉴를 보여 준다', (tester) async {
    const supper = CafeteriaMenuItem(
      restaurant: '생활관식당',
      dishes: ['닭갈비', '쌀밥'],
      price: 5500,
      venue: CafeteriaVenue.dorm,
    );
    await _pump(
      tester,
      const [student],
      dinner: const [supper],
      now: DateTime(2026, 11, 16, 17),
    );
    await tester.pumpAndSettle();
    expect(find.text('오늘 저녁'), findsOneWidget);
    expect(find.text('닭갈비'), findsOneWidget);
    expect(find.text('김치찌개'), findsNothing);
  });

  test('시각별 끼니: 10시 전 아침, 15시 전 점심, 그 뒤 저녁', () {
    expect(mealAt(DateTime(2026, 11, 16, 9, 59)), CafeteriaMeal.breakfast);
    expect(mealAt(DateTime(2026, 11, 16, 10)), CafeteriaMeal.lunch);
    expect(mealAt(DateTime(2026, 11, 16, 14, 59)), CafeteriaMeal.lunch);
    expect(mealAt(DateTime(2026, 11, 16, 15)), CafeteriaMeal.dinner);
  });

  testWidgets('같은 날에는 다시 받지 않고, 날짜가 바뀌면 그날 메뉴를 새로 받는다', (tester) async {
    final service = _RecordingService();
    Widget card(DateTime now) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 180,
          child: CafeteriaMenuCard(now: now, onTap: () {}, service: service),
        ),
      ),
    );

    await tester.pumpWidget(card(DateTime(2026, 11, 16, 11)));
    await tester.pumpAndSettle();
    await tester.pumpWidget(card(DateTime(2026, 11, 16, 11, 1)));
    await tester.pumpAndSettle();
    expect(service.dates, [DateTime(2026, 11, 16, 11)]);

    await tester.pumpWidget(card(DateTime(2026, 11, 17, 0, 0)));
    await tester.pumpAndSettle();
    expect(service.dates.last, DateTime(2026, 11, 17));
  });
}

/// 어느 날짜 메뉴를 요청했는지 적어 둔다.
class _RecordingService implements CafeteriaMenuServiceBase {
  final dates = <DateTime>[];

  @override
  Future<DailyCafeteriaMenu> fetchMenu(DateTime date) async {
    dates.add(date);
    return const DailyCafeteriaMenu();
  }
}
