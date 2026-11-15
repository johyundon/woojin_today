// 홈 학식 카드: 지금 시각의 끼니(아침·점심·저녁) 메뉴를 두 가지씩 묶어 3초마다 다음 묶음으로 넘기고,
// 마지막 다음에는 처음으로 돌아와 계속 돈다. 식당이 하나여도 메뉴가 셋 이상이면
// 넘어가고, 묶음이 하나뿐이면 넘기지 않는다.

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

  test('식당마다 메뉴를 두 개씩 묶는다', () {
    final pages = menuPages(const [dorm, student]);
    expect(
      [for (final p in pages) p.dishes],
      [
        ['시골된장찌개', '쌀밥'],
        ['제육볶음', '김치'],
        ['요구르트'],
        ['김치찌개', '쌀밥'],
      ],
    );
    expect(pages.last.item.restaurant, '학생식당');
  });

  testWidgets('식당이 하나여도 3초마다 다음 메뉴로 넘어가고 끝나면 처음으로 돌아온다', (tester) async {
    await _pump(tester, const [dorm]);
    await tester.pumpAndSettle();
    expect(find.text('시골된장찌개\n쌀밥'), findsOneWidget);

    await _next(tester);
    expect(find.text('제육볶음\n김치'), findsOneWidget);
    await _next(tester);
    expect(find.text('요구르트'), findsOneWidget);
    await _next(tester);
    expect(find.text('시골된장찌개\n쌀밥'), findsOneWidget);
    expect(find.text('생활관식당'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('묶음이 하나뿐이면 넘기지 않는다', (tester) async {
    await _pump(tester, const [student]);
    await tester.pumpAndSettle();
    await tester.pump(CafeteriaMenuCard.autoSlide * 2);
    await tester.pumpAndSettle();
    expect(find.text('김치찌개\n쌀밥'), findsOneWidget);
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
    expect(find.text('닭갈비\n쌀밥'), findsOneWidget);
    expect(find.text('김치찌개\n쌀밥'), findsNothing);
  });

  test('시각별 끼니: 10시 전 아침, 15시 전 점심, 그 뒤 저녁', () {
    expect(mealAt(DateTime(2026, 11, 16, 9, 59)), CafeteriaMeal.breakfast);
    expect(mealAt(DateTime(2026, 11, 16, 10)), CafeteriaMeal.lunch);
    expect(mealAt(DateTime(2026, 11, 16, 14, 59)), CafeteriaMeal.lunch);
    expect(mealAt(DateTime(2026, 11, 16, 15)), CafeteriaMeal.dinner);
  });
}
