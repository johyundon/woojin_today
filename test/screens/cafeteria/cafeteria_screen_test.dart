// CafeteriaScreen이 디자인 "07 학식" 레이아웃(요일 칩 / 전체·식당 탭 / 같은 크기
// 메뉴 카드 2열)을 오버플로우 없이 그리고, 요일·식당·끼니 바꾸기, 날짜 선택이
// 동작하는지 확인한다.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/screens/cafeteria/cafeteria_screen.dart';
import 'package:daejin_app/services/fakes/fake_cafeteria_menu_service.dart';

/// 점심시간(낮 12시) 기준으로 연다 — 목데이터의 "오늘" 점심이 기본으로 보인다.
Future<void> _pump(WidgetTester tester, {DateTime? now, double w = 390}) async {
  tester.view.physicalSize = Size(w * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final t = DateTime.now();
  await tester.pumpWidget(
    MaterialApp(
      home: CafeteriaScreen(
        now: now ?? DateTime(t.year, t.month, t.day, 12),
        service: FakeCafeteriaMenuService(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('"오늘 뭐 먹지?" 헤더, 요일 칩, 식당 탭 4개, 메뉴 카드가 보인다', (tester) async {
    await _pump(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('오늘 뭐 먹지?'), findsOneWidget);
    for (final label in ['월', '화', '수', '목', '금']) {
      expect(find.text(label), findsOneWidget);
    }
    for (final label in ['전체', '학생식당', '교직원식당', '카페']) {
      // 교직원식당은 전체 탭 메뉴 배지에도 나온다.
      expect(find.text(label), findsWidgets);
    }
    expect(find.text('학생회관 1층 · 점심 11:30 - 13:30'), findsOneWidget);

    // 큰 대표 카드 없이 첫 메뉴도 같은 카드로 나온다.
    expect(find.text('데일리밥 · 한식'), findsOneWidget);
    expect(find.text('제육볶음\n된장찌개'), findsOneWidget);
    expect(find.text('인기 1위'), findsNothing);
    expect(find.text('5,000원'), findsWidgets);
    expect(find.text('돈까스\n우동'), findsOneWidget);
    expect(find.text('5,500원'), findsOneWidget);
  });

  testWidgets('전체 탭에는 교직원식당 메뉴도 "교직원식당" 배지로 함께 나온다', (tester) async {
    await _pump(tester);

    await tester.scrollUntilVisible(
      find.text('소불고기\n미역국'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('소불고기\n미역국'), findsOneWidget);
    // 탭 1개 + 배지 2개(교직원식당 메뉴 둘).
    expect(find.text('교직원식당'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('오늘 학생식당 점심에는 한식 말고도 양식·분식·일식·샐러드·중식 메뉴가 있다', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('학생식당'));
    await tester.pumpAndSettle();

    for (final label in [
      '데일리밥 · 한식',
      '파스타랩 · 양식',
      '분식당 · 분식',
      '덮밥집 · 일식',
      '샐러드바 · 샐러드',
      '누들송 · 중식',
      '일품 · 일식',
    ]) {
      await tester.scrollUntilVisible(
        find.text(label),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('소불고기\n미역국'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('식당 탭을 바꾸면 그 식당의 메뉴만 보이고, 카페는 메뉴가 없다', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('교직원식당').first); // 탭(배지보다 위)
    await tester.pumpAndSettle();
    expect(find.text('소불고기\n미역국'), findsOneWidget);
    expect(find.text('6,500원'), findsOneWidget);
    expect(find.text('제육볶음\n된장찌개'), findsNothing);
    expect(find.text('교직원식당 · 점심'), findsOneWidget);

    await tester.tap(find.text('카페'));
    await tester.pumpAndSettle();
    expect(find.text('등록된 메뉴가 없어요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('알약을 누르면 끼니가 아침 → 저녁으로 바뀐다', (tester) async {
    await _pump(tester);

    await tester.tap(find.textContaining('학생회관 1층'));
    await tester.pumpAndSettle();
    expect(find.text('학생회관 1층 · 저녁'), findsOneWidget);
    expect(find.text('치킨가라아게\n쌀밥'), findsOneWidget);

    await tester.tap(find.textContaining('학생회관 1층'));
    await tester.pumpAndSettle();
    expect(find.text('학생회관 1층 · 아침'), findsOneWidget);
    expect(find.text('콩나물국\n쌀밥'), findsOneWidget);
  });

  testWidgets('지금 시각에 맞는 끼니가 기본으로 선택된다(오전 8시 = 아침)', (tester) async {
    final t = DateTime.now();
    await _pump(tester, now: DateTime(t.year, t.month, t.day, 8));
    expect(find.text('학생회관 1층 · 아침'), findsOneWidget);
  });

  testWidgets('요일 칩을 누르면 그 날 메뉴로 바뀌고, 메뉴가 없는 날은 안내 문구가 나온다', (tester) async {
    await _pump(tester);

    // 목데이터는 오늘~모레만 있다. 이번 주 월~금 중 오늘보다 일주일 뒤 같은 요일은 없다.
    await tester.fling(
      find.text('월'),
      const Offset(-300, 0),
      1000,
    ); // 다음 주로 넘기기
    await tester.pumpAndSettle();
    expect(find.text('등록된 메뉴가 없어요'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.fling(
      find.text('월'),
      const Offset(300, 0),
      1000,
    ); // 이번 주로 돌아오기
    await tester.pumpAndSettle();
    expect(find.text('등록된 메뉴가 없어요'), findsNothing);
    expect(find.text('제육볶음\n된장찌개'), findsOneWidget);
  });

  testWidgets('날짜 선택 버튼을 누르면 날짜 팝업이 뜨고 취소로 닫을 수 있다', (tester) async {
    await _pump(tester);

    await tester.tap(find.byIcon(Icons.calendar_month_rounded));
    await tester.pumpAndSettle();
    expect(find.text('날짜 선택'), findsOneWidget);

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.text('날짜 선택'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('날짜 팝업에서 다음 날로 바꿔 확인하면 반영된다', (tester) async {
    await _pump(tester);
    final now = DateTime.now();

    await tester.tap(find.byIcon(Icons.calendar_month_rounded));
    await tester.pumpAndSettle();
    expect(find.text('${now.year}년'), findsOneWidget);
    expect(find.text('${now.month}월'), findsOneWidget);

    final wheels = find.byType(CupertinoPicker);
    expect(wheels, findsNWidgets(3));
    await tester.drag(wheels.at(2), const Offset(0, -36)); // 일 휠 한 칸
    await tester.pumpAndSettle();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    // 내일 점심(목데이터 돈카츠락 치즈돈까스)이 대표로 보인다.
    expect(find.text('치즈돈까스\n쌀밥'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('작은 화면(360x640)에서도 넘치지 않는다', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final t = DateTime.now();
    await tester.pumpWidget(
      MaterialApp(
        home: CafeteriaScreen(
          now: DateTime(t.year, t.month, t.day, 12),
          service: FakeCafeteriaMenuService(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('교직원식당').first); // 탭(배지보다 위)
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
