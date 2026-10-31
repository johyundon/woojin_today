// NoticeScreen이 학사공지·마일리지장학 공지를 받아 최신순으로 보여주고, 분류 칩·
// 읽음·북마크·상세(실제 본문/첨부)·불러오기 실패·새로고침이 동작하는지 확인한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:daejin_app/screens/notice/models/notice_item.dart';
import 'package:daejin_app/screens/notice/notice_screen.dart';
import 'package:daejin_app/services/notice_service.dart';

class _FakeNotices implements NoticeServiceBase {
  bool failMileage = false;
  final forceFlags = <bool>[];
  final detailCalls = <String>[];

  @override
  Future<List<NoticeItem>> fetchNotices(
    NoticeBoard board, {
    bool forceRefresh = false,
  }) async {
    forceFlags.add(forceRefresh);
    if (board == NoticeBoard.mileage) {
      if (failMileage) throw const NoticeException('fail');
      return const [
        NoticeItem(
          title: '2026학년도 1학기 마일리지장학 대상자 공지',
          author: '학생복지팀',
          date: '2026.08.05',
          viewCount: 2233,
          tag: NoticeTag.scholarship,
          detailPath: '/m1',
          hasAttachment: true,
        ),
      ];
    }
    return const [
      NoticeItem(
        title: '부·복수전공 이수신청 안내',
        author: '학사팀',
        date: '2026.10.29',
        viewCount: 94,
        tag: NoticeTag.academic,
        isNew: true,
        detailPath: '/a1',
        hasAttachment: true,
      ),
      NoticeItem(
        title: '학사팀 업무 일시 중단 안내',
        author: '학사팀',
        date: '2026.10.20',
        viewCount: 85,
        tag: NoticeTag.academic,
        isNew: true,
        detailPath: '/a2',
      ),
      NoticeItem(
        title: '중간시험 수업평가 시행 안내',
        author: '교무팀',
        date: '2026.10.01',
        viewCount: 394,
        tag: NoticeTag.academic,
        detailPath: '/a3',
      ),
    ];
  }

  @override
  Future<NoticeDetail> fetchDetail(String detailPath) async {
    detailCalls.add(detailPath);
    return const NoticeDetail(
      title: '부·복수전공 이수신청 안내',
      author: '학사팀',
      date: '2026.10.29',
      viewCount: 95,
      body: '1. 관련 : 학칙 시행세칙\n\n가. 이수신청 대상 : 재학생',
      attachments: [
        NoticeAttachment(name: '붙임 1 안내문.xlsx', url: 'https://x/1'),
        NoticeAttachment(name: '붙임 2 서식.hwp', url: 'https://x/2'),
      ],
    );
  }
}

Future<void> _pump(WidgetTester tester, _FakeNotices service) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: NoticeScreen(service: service)));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('두 게시판을 최신순으로 합쳐 보여주고, 학과·행사 칩은 숨긴다', (tester) async {
    await _pump(tester, _FakeNotices());

    expect(tester.takeException(), isNull);
    expect(find.text('놓치면 안 되는 공지'), findsOneWidget);
    expect(find.text('새 글 2개'), findsOneWidget);
    for (final label in ['전체', '학사', '장학']) {
      expect(find.text(label), findsWidgets);
    }
    expect(find.text('학과'), findsNothing);
    expect(find.text('행사'), findsNothing);

    double topOf(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(topOf('부·복수전공 이수신청 안내'), lessThan(topOf('중간시험 수업평가 시행 안내')));
    expect(find.text('학사팀 · 10.29'), findsOneWidget);
  });

  testWidgets('장학 칩을 누르면 마일리지장학 공지만 보인다', (tester) async {
    await _pump(tester, _FakeNotices());

    await tester.tap(find.text('장학').first);
    await tester.pumpAndSettle();
    expect(find.text('2026학년도 1학기 마일리지장학 대상자 공지'), findsOneWidget);
    expect(find.text('부·복수전공 이수신청 안내'), findsNothing);
  });

  testWidgets('공지를 열면 실제 본문과 첨부파일이 보이고, 새 글 개수가 줄어 유지된다', (tester) async {
    final service = _FakeNotices();
    await _pump(tester, service);

    await tester.tap(find.text('부·복수전공 이수신청 안내'));
    await tester.pumpAndSettle();

    expect(service.detailCalls, ['/a1']);
    expect(find.textContaining('이수신청 대상 : 재학생'), findsOneWidget);
    expect(find.text('95'), findsOneWidget);
    expect(find.text('첨부파일'), findsOneWidget);
    expect(find.text('붙임 1 안내문.xlsx'), findsOneWidget);
    expect(find.text('붙임 2 서식.hwp'), findsOneWidget);

    await tester.tap(find.text('미리보기').first);
    await tester.pump();
    expect(find.text('미리보기는 지원하지 않아요'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();
    expect(find.text('새 글 1개'), findsOneWidget);

    // 화면을 새로 열어도(저장된 읽음 상태를 불러와서) 그대로 1개.
    await tester.pumpWidget(const SizedBox());
    await _pump(tester, service);
    expect(find.text('새 글 1개'), findsOneWidget);
  });

  testWidgets('북마크한 공지는 맨 위로 올라가고, 해제하면 원래 자리로 돌아간다', (tester) async {
    await _pump(tester, _FakeNotices());
    const target = '중간시험 수업평가 시행 안내'; // 학사 3건 중 가장 오래된 것
    const newest = '부·복수전공 이수신청 안내';

    double topOf(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(topOf(target), greaterThan(topOf(newest)));

    await tester.tap(find.byIcon(Icons.bookmark_border).at(2));
    await tester.pumpAndSettle();
    expect(topOf(target), lessThan(topOf(newest)));

    await tester.tap(find.byIcon(Icons.bookmark));
    await tester.pumpAndSettle();
    expect(topOf(target), greaterThan(topOf(newest)));
  });

  testWidgets('한 게시판을 못 불러오면 안내를 띄우고, 다시 시도하면 채운다', (tester) async {
    final service = _FakeNotices()..failMileage = true;
    await _pump(tester, service);

    expect(find.text('마일리지장학 공지를 불러오지 못했어요'), findsOneWidget);
    expect(find.text('부·복수전공 이수신청 안내'), findsOneWidget);

    service.failMileage = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('마일리지장학 공지를 불러오지 못했어요'), findsNothing);
    expect(find.text('2026학년도 1학기 마일리지장학 대상자 공지'), findsOneWidget);
  });

  testWidgets('당겨서 새로고침하면 캐시를 무시하고 새로 받는다', (tester) async {
    final service = _FakeNotices();
    await _pump(tester, service);
    expect(service.forceFlags, [false, false]);

    await tester.fling(find.text('부·복수전공 이수신청 안내'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(service.forceFlags.skip(2), [true, true]);
  });

  testWidgets('"새 글 알림" 종 버튼으로 끌 수 있다', (tester) async {
    await _pump(tester, _FakeNotices());

    expect(find.byIcon(Icons.notifications_active), findsOneWidget);
    await tester.tap(find.byIcon(Icons.notifications_active));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
