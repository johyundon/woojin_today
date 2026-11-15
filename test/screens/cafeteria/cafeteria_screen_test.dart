// CafeteriaScreen이 디자인 "07 학식" 레이아웃("학식" 제목 / 가로로 넘기는 날짜 칩 /
// 전체·식당 탭 / 조식·중식·석식 구역별 메뉴 카드 2열)을 오버플로우 없이 그리고,
// 날짜·식당 바꾸기가 동작하는지 확인한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/screens/cafeteria/cafeteria_screen.dart';
import 'package:daejin_app/screens/cafeteria/widgets/cafeteria_date_picker_dialog.dart';
import 'package:daejin_app/services/fakes/fake_cafeteria_menu_service.dart';

DateTime get _today {
  final t = DateTime.now();
  return DateTime(t.year, t.month, t.day);
}

/// 낮 12시 기준으로 연다. 목데이터는 실제 "오늘"~"모레"에만 메뉴가 있다.
Future<void> _pump(
  WidgetTester tester, {
  double w = 390,
  double h = 844,
}) async {
  tester.view.physicalSize = Size(w * 3, h * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: CafeteriaScreen(
        now: _today.add(const Duration(hours: 12)),
        service: FakeCafeteriaMenuService(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 메뉴 목록(세로 스크롤)에서 [finder]가 보일 때까지 내린다.
Future<void> _scrollTo(WidgetTester tester, Finder finder) =>
    tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .last,
    );

void main() {
  testWidgets('"학식" 제목, 날짜 칩, 식당 탭, 조식·중식·석식 카드가 보인다', (tester) async {
    await _pump(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('학식'), findsOneWidget);
    // 예전 윗부분(큰 제목·끼니 알약·달력 버튼)은 숨겼다.
    expect(find.text('오늘 뭐 먹지?'), findsNothing);
    expect(find.textContaining('학생회관 1층'), findsNothing);
    expect(find.byIcon(Icons.calendar_month_rounded), findsNothing);

    for (final label in ['전체', '학생식당', '생활관식당', '교직원식당']) {
      expect(find.text(label), findsWidgets); // 탭 + 카드 배지
    }
    expect(find.text('카페'), findsNothing); // 데이터가 없어 숨긴 탭

    // 조식: 코너 이름이 크게, 메뉴 구성은 "·"로 이어서, 가격은 아래에.
    expect(find.text('조식'), findsOneWidget);
    expect(find.text('천원의밥상'), findsOneWidget);
    expect(find.text('콩나물국 · 쌀밥 · 계란말이 · 어묵볶음 · 배추김치'), findsOneWidget);
    expect(find.text('1,000원'), findsOneWidget);

    await _scrollTo(tester, find.text('데일리밥'));
    expect(find.text('중식'), findsOneWidget);
    expect(find.text('제육볶음 · 된장찌개 · 잡곡밥 · 콩나물무침 · 깍두기'), findsOneWidget);

    await _scrollTo(tester, find.text('석식'));
    await _scrollTo(tester, find.text('치킨가라아게 · 쌀밥 · 미소장국 · 샐러드'));
    expect(find.text('5,300원'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('날짜 칩에는 주말도 있고, 처음에는 오늘이 왼쪽 끝에 온다', (tester) async {
    await _pump(tester);

    // 오늘 칩이 왼쪽 여백(16) 바로 뒤에 있다(칩 너비 64의 가운데 = 48).
    final todayChip = find.text('${_today.day}');
    expect(todayChip, findsOneWidget);
    expect(tester.getCenter(todayChip).dx, closeTo(48, 1));

    // 오늘부터 일주일 안에는 토·일이 꼭 있다(화면 오른쪽 밖에 미리 그려 둔 칩 포함).
    expect(find.text('토', skipOffstage: false), findsWidgets);
    expect(find.text('일', skipOffstage: false), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('날짜 칩을 누르면 그 날 메뉴로 바뀌고, 메뉴가 없는 날은 안내 문구가 나온다', (tester) async {
    await _pump(tester);

    // 내일 점심(목데이터 돈카츠락 치즈돈까스).
    final tomorrow = _today.add(const Duration(days: 1));
    await tester.tap(find.text('${tomorrow.day}'));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('치즈돈까스 · 쌀밥 · 우동국 · 양배추샐러드'));
    expect(find.text('치즈돈까스 · 쌀밥 · 우동국 · 양배추샐러드'), findsOneWidget);

    // 어제는 목데이터가 없어 세 끼 모두 안내 문구.
    final yesterday = _today.subtract(const Duration(days: 1));
    await tester.drag(
      find.text('${tomorrow.day}'),
      const Offset(100, 0),
    ); // 어제 칩이 보이게
    await tester.pumpAndSettle();
    await tester.tap(find.text('${yesterday.day}'));
    await tester.pumpAndSettle();
    expect(find.text('등록된 메뉴가 없어요'), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('전체 탭에는 교직원식당 메뉴도 "교직원식당" 배지로 함께 나온다', (tester) async {
    await _pump(tester);

    await _scrollTo(tester, find.text('교직원 일품'));
    expect(find.text('연어덮밥 · 유부장국'), findsOneWidget);
    expect(find.text('교직원식당'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('학생식당 탭에는 학생식당 코너 메뉴만 나온다', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('학생식당').first); // 탭(배지보다 위)
    await tester.pumpAndSettle();

    for (final corner in ['데일리밥', '일품', '누들송', '파스타랩', '분식당', '덮밥집', '샐러드바']) {
      await _scrollTo(tester, find.text(corner));
      expect(find.text(corner), findsOneWidget);
    }
    expect(find.text('교직원 일품'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('식당 탭을 바꾸면 그 식당 메뉴만 보이고, 메뉴 없는 끼니는 안내가 나온다', (tester) async {
    await _pump(tester);

    await tester.ensureVisible(find.text('교직원식당').first);
    await tester.tap(find.text('교직원식당').first); // 탭(배지보다 위)
    await tester.pumpAndSettle();
    expect(find.text('6,500원'), findsOneWidget);
    expect(find.text('데일리밥'), findsNothing);
    // 교직원식당은 점심만 있어 조식·석식은 안내 문구.
    expect(find.text('등록된 메뉴가 없어요'), findsNWidgets(2));

    // 가짜 데이터에는 생활관식당 메뉴가 없다.
    await tester.ensureVisible(find.text('생활관식당'));
    await tester.tap(find.text('생활관식당'));
    await tester.pumpAndSettle();
    expect(find.text('등록된 메뉴가 없어요'), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('숨겨 둔 날짜 팝업은 열고 취소로 닫을 수 있다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                showCafeteriaDatePickerDialog(context, initialDate: _today),
            child: const Text('열기'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.text('날짜 선택'), findsOneWidget);

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.text('날짜 선택'), findsNothing);
  });

  testWidgets('작은 화면(360x640)에서도 넘치지 않는다', (tester) async {
    await _pump(tester, w: 360, h: 640);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('교직원식당').first);
    await tester.tap(find.text('교직원식당').first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
