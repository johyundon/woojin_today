// 통합 검색 화면: 검색어가 없으면 기능 전체를 보여 주고, 이름·설명·검색어로
// 기능을 찾고, 공지 제목과 캠퍼스 장소도 함께 찾는다. 결과가 없으면 안내를
// 띄우고, 시간표는 홈의 탭 이동으로 연다.

import 'dart:typed_data';

import 'package:daejin_app/screens/campus_map/models/room_building.dart';
import 'package:daejin_app/screens/notice/models/notice_item.dart';
import 'package:daejin_app/screens/notice/notice_detail_screen.dart';
import 'package:daejin_app/screens/search/app_features.dart';
import 'package:daejin_app/screens/search/search_screen.dart';
import 'package:daejin_app/screens/search/widgets/search_result_row.dart';
import 'package:daejin_app/services/notice_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _FakeNotices implements NoticeServiceBase {
  _FakeNotices({this.fail = false});

  final bool fail;
  final boards = <NoticeBoard>[];

  @override
  Future<List<NoticeItem>> fetchNotices(
    NoticeBoard board, {
    bool forceRefresh = false,
  }) async {
    boards.add(board);
    if (fail) throw const NoticeException('실패', isNetwork: true);
    return switch (board) {
      NoticeBoard.academic => const [
        NoticeItem(
          title: '2026학년도 2학기 수강신청 안내',
          author: '학사지원팀',
          date: '2026.11.02',
          viewCount: 10,
          tag: NoticeTag.academic,
          detailPath: '/academic/1',
        ),
      ],
      NoticeBoard.mileage => const [
        NoticeItem(
          title: '마일리지장학 대상자 안내',
          author: '학생지원팀',
          date: '2026.10.20',
          viewCount: 5,
          tag: NoticeTag.scholarship,
          detailPath: '/mileage/1',
        ),
      ],
      NoticeBoard.timetable => const [],
    };
  }

  @override
  Future<NoticeDetail> fetchDetail(String detailPath) async =>
      const NoticeDetail(
        title: '2026학년도 2학기 수강신청 안내',
        author: '학사지원팀',
        date: '2026.11.02',
        viewCount: 10,
        body: '본문',
        attachments: [],
      );

  @override
  Future<Uint8List> downloadAttachment(String url) async => Uint8List(0);
}

Future<void> _pump(
  WidgetTester tester, {
  ValueChanged<int>? onTabTap,
  _FakeNotices? notices,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: SearchScreen(
        links: FeatureLinks(onTabTap: onTabTap),
        noticeService: notices ?? _FakeNotices(),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _search(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.pump();
}

Finder _row(String text) => find.descendant(
  of: find.byType(SearchResultRow),
  matching: find.text(text),
);

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('AppFeature.matches', () {
    test('이름·검색어로 찾고 띄어쓰기는 무시한다', () {
      expect(AppFeatures.cafeteria.matches('학식'), isTrue);
      expect(AppFeatures.cafeteria.matches('점심'), isTrue);
      expect(AppFeatures.campusMap.matches('캠퍼스지도'), isTrue);
      expect(AppFeatures.advisor.matches('지도 교수'), isTrue);
      expect(AppFeatures.cafeteria.matches('졸업'), isFalse);
      expect(AppFeatures.cafeteria.matches('  '), isFalse);
    });
  });

  group('buildingsMatching', () {
    test('건물 이름과 줄임말로 찾는다', () {
      expect(buildingsMatching('도서관').map((b) => b.name), contains('중앙도서관'));
      expect(buildingsMatching('사과관').map((b) => b.name), contains('사회과학관'));
      expect(buildingsMatching('공대 가동').map((b) => b.name), contains('공대 가동'));
      expect(buildingsMatching(' '), isEmpty);
    });
  });

  testWidgets('검색어가 없으면 찾을 수 있는 기능을 모두 보여 준다', (tester) async {
    await _pump(tester);

    expect(find.text('이런 걸 찾을 수 있어요'), findsOneWidget);
    expect(find.text('시간표'), findsOneWidget);
    expect(find.text('학식'), findsOneWidget);
  });

  testWidgets('검색어로 기능을 찾는다', (tester) async {
    await _pump(tester);

    await _search(tester, '점심');

    expect(_row('학식'), findsOneWidget);
    expect(find.byType(SearchResultRow), findsOneWidget);
    expect(find.text('기능'), findsOneWidget);
  });

  testWidgets('공지 제목으로 찾고, 누르면 공지 상세가 열린다', (tester) async {
    final notices = _FakeNotices();
    await _pump(tester, notices: notices);

    await _search(tester, '수강신청');

    expect(find.text('공지'), findsOneWidget);
    expect(_row('2026학년도 2학기 수강신청 안내'), findsOneWidget);
    expect(find.text('학사 · 11.02 · 학사지원팀'), findsOneWidget);
    // 로그인 정보가 없으면 로그인이 필요한 게시판은 부르지 않는다.
    expect(notices.boards, isNot(contains(NoticeBoard.timetable)));

    await tester.tap(_row('2026학년도 2학기 수강신청 안내'));
    await tester.pumpAndSettle();
    expect(find.byType(NoticeDetailScreen), findsOneWidget);
  });

  testWidgets('공지를 못 불러오면 안내를 띄우고 다른 결과는 그대로 보여 준다', (tester) async {
    await _pump(tester, notices: _FakeNotices(fail: true));

    await _search(tester, '학식');

    expect(find.text('공지를 불러오지 못해 공지는 찾지 못했어요'), findsOneWidget);
    expect(_row('학식'), findsOneWidget);
  });

  testWidgets('장소 이름·줄임말로 캠퍼스 건물을 찾는다', (tester) async {
    await _pump(tester);

    await _search(tester, '도서관');

    expect(find.text('장소'), findsOneWidget);
    expect(_row('중앙도서관'), findsOneWidget);
  });

  testWidgets('맞는 결과가 없으면 안내를 띄우고, 지우기로 처음 목록으로 돌아간다', (tester) async {
    await _pump(tester);

    await _search(tester, '없는기능');
    expect(find.text("'없는기능'에 맞는 결과가 없어요"), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('지우기'));
    await tester.pump();
    expect(find.text('이런 걸 찾을 수 있어요'), findsOneWidget);
  });

  testWidgets('시간표를 누르면 홈의 시간표 탭 이동을 부른다', (tester) async {
    int? tapped;
    await _pump(tester, onTabTap: (i) => tapped = i);

    await _search(tester, '시간표');
    await tester.tap(_row('시간표'));
    await tester.pump();

    expect(tapped, 0);
  });
}
