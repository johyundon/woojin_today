// 홈 "오늘 점심" 카드: 식당이 둘 이상이면 4초마다 다음 식당 메뉴로 넘어가고,
// 마지막 다음에는 처음으로 돌아온다. 하나뿐이면 넘기지 않는다.

import 'package:daejin_app/screens/cafeteria/models/cafeteria_menu.dart';
import 'package:daejin_app/screens/home/widgets/cafeteria_menu_card.dart';
import 'package:daejin_app/services/cafeteria_menu_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeService implements CafeteriaMenuServiceBase {
  _FakeService(this.lunch);
  final List<CafeteriaMenuItem> lunch;

  @override
  Future<DailyCafeteriaMenu> fetchMenu(DateTime date) async =>
      DailyCafeteriaMenu(lunch: lunch);
}

Future<void> _pump(WidgetTester tester, List<CafeteriaMenuItem> lunch) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            child: CafeteriaMenuCard(
              now: DateTime(2026, 11, 16, 11),
              onTap: () {},
              service: _FakeService(lunch),
            ),
          ),
        ),
      ),
    );

void main() {
  const student = CafeteriaMenuItem(
    restaurant: '학생식당',
    dishes: ['김치찌개', '쌀밥'],
    price: 5000,
  );
  const dorm = CafeteriaMenuItem(
    restaurant: '생활관식당',
    dishes: ['된장찌개', '잡곡밥'],
    price: 5500,
    venue: CafeteriaVenue.dorm,
  );

  testWidgets('식당이 둘이면 4초마다 다음 식당 메뉴로 넘어갔다가 처음으로 돌아온다', (tester) async {
    await _pump(tester, const [student, dorm]);
    await tester.pumpAndSettle();
    expect(find.text('학생식당'), findsOneWidget);

    await tester.pump(CafeteriaMenuCard.autoSlide);
    await tester.pumpAndSettle();
    expect(find.text('생활관식당'), findsOneWidget);
    expect(find.text('학생식당'), findsNothing);

    await tester.pump(CafeteriaMenuCard.autoSlide);
    await tester.pumpAndSettle();
    expect(find.text('학생식당'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('식당이 하나면 넘기지 않는다', (tester) async {
    await _pump(tester, const [student]);
    await tester.pumpAndSettle();
    await tester.pump(CafeteriaMenuCard.autoSlide * 2);
    await tester.pumpAndSettle();
    expect(find.text('학생식당'), findsOneWidget);
  });
}
