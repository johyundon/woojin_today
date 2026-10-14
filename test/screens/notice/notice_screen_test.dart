// NoticeScreen이 분류 칩/카드/북마크를 오버플로우 없이 보여주고, 공지 상세와
// 마일리지 대상자 확인 다이얼로그로 제대로 이어지는지 확인한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:daejin_app/screens/notice/notice_screen.dart';

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: NoticeScreen()));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('공지를 열면 빨간 점과 "새 글" 개수가 줄고, 다시 와도 유지된다', (tester) async {
    await _pump(tester);
    expect(find.text('새 글 4개'), findsOneWidget);

    await tester.tap(find.text('2026-2학기 수강 정정 및 철회 안내'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();
    expect(find.text('새 글 3개'), findsOneWidget);

    // 화면을 새로 열어도(저장된 읽음 상태를 불러와서) 그대로 3개.
    await tester.pumpWidget(const SizedBox());
    await _pump(tester);
    expect(find.text('새 글 3개'), findsOneWidget);
  });

  testWidgets('전체 칩이 기본이고 최신 공지가 맨 위에 보인다', (tester) async {
    await _pump(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('놓치면 안 되는 공지'), findsOneWidget);
    expect(find.text('새 글 4개'), findsOneWidget);
    for (final label in ['전체', '학사', '장학', '학과', '행사']) {
      expect(find.text(label), findsWidgets);
    }
    expect(find.text('2026-2학기 수강 정정 및 철회 안내'), findsOneWidget);
    expect(find.text('필독'), findsOneWidget);
    expect(find.text('교무처 · 10.08'), findsOneWidget);
  });

  testWidgets('칩을 누르면 그 분류의 공지만 보인다', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('행사').first);
    await tester.pumpAndSettle();
    expect(find.text('대진 축제 부스 운영 동아리 신청'), findsOneWidget);
    expect(find.text('2026-2학기 수강 정정 및 철회 안내'), findsNothing);

    await tester.tap(find.text('전체').first);
    await tester.pumpAndSettle();
    expect(find.text('2026-2학기 수강 정정 및 철회 안내'), findsOneWidget);
  });

  testWidgets('북마크 아이콘을 누르면 채워진 북마크로 바뀐다', (tester) async {
    await _pump(tester);

    expect(find.byIcon(Icons.bookmark), findsNothing);
    await tester.tap(find.byIcon(Icons.bookmark_border).first);
    await tester.pump();
    expect(find.byIcon(Icons.bookmark), findsOneWidget);
  });

  testWidgets('북마크한 공지는 목록 맨 위로 올라가고, 해제하면 원래 자리로 돌아간다', (tester) async {
    await _pump(tester);
    const target = '대진 축제 부스 운영 동아리 신청'; // 원래 4번째

    double topOf(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(topOf(target), greaterThan(topOf('2026-2학기 수강 정정 및 철회 안내')));

    // 4번째 카드의 북마크를 누른다.
    await tester.tap(find.byIcon(Icons.bookmark_border).at(3));
    await tester.pumpAndSettle();
    expect(topOf(target), lessThan(topOf('2026-2학기 수강 정정 및 철회 안내')));

    // 이제 맨 위가 된 그 카드의 북마크를 다시 눌러 해제.
    await tester.tap(find.byIcon(Icons.bookmark));
    await tester.pumpAndSettle();
    expect(topOf(target), greaterThan(topOf('2026-2학기 수강 정정 및 철회 안내')));
  });

  testWidgets('공지를 탭하면 상세 화면으로 이동한다', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('2026-2학기 수강 정정 및 철회 안내'));
    await tester.pumpAndSettle();

    expect(find.text('작성자'), findsOneWidget);
    expect(find.textContaining('수강 정정 및 철회 기간'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();
    expect(find.text('2026-2학기 수강 정정 및 철회 안내'), findsOneWidget);
  });

  testWidgets('장학 칩: "대상자" 공지는 대상자 확인 다이얼로그로, "시행 안내"는 상세 화면으로 간다', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.text('장학').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('2026학년도 1학기 마일리지장학 대상자 공지'));
    await tester.pumpAndSettle();
    expect(find.text('아쉽게도 대상자 명단에 없어요..'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('2026학년도 1학기 마일리지장학 시행 안내'));
    await tester.pumpAndSettle();
    expect(find.textContaining('시행 계획'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('종합강의시간표 공지의 첨부파일 "미리보기"는 스낵바를 보여준다', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('학사').first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('2026학년도 2학기 종합강의시간표'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('2026학년도 2학기 종합강의시간표'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2026학년도 2학기 종합강의시간표'));
    await tester.pumpAndSettle();

    expect(find.text('첨부파일'), findsOneWidget);
    await tester.tap(find.text('미리보기'));
    await tester.pump();
    expect(find.text('미리보기는 지원하지 않아요'), findsOneWidget);
  });

  testWidgets('"새 글 알림" 종 버튼으로 끄고 켤 수 있다', (tester) async {
    await _pump(tester);

    expect(find.byIcon(Icons.notifications_active), findsOneWidget);
    await tester.tap(find.byIcon(Icons.notifications_active));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.notifications_off), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
