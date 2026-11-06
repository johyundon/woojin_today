// 홈·모아보기 위쪽 공지·이벤트 배너: 어떤 카드를 모으는지, 화면에 어떻게
// 보이고 넘어가는지, 누르면 어디로 가는지 확인한다.

import 'dart:typed_data';

import 'package:daejin_app/screens/home/services/home_banner_items.dart';
import 'package:daejin_app/screens/home/widgets/home_notice_banner.dart';
import 'package:daejin_app/screens/notice/models/notice_item.dart';
import 'package:daejin_app/screens/notice/notice_detail_screen.dart';
import 'package:daejin_app/services/academic_schedule_service.dart';
import 'package:daejin_app/services/notice_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

NoticeItem _notice(String title, String date, {bool isNew = false}) =>
    NoticeItem(
      title: title,
      author: '학사팀',
      date: date,
      viewCount: 1,
      tag: NoticeTag.academic,
      isNew: isNew,
      detailPath: '/n/$title',
    );

class _FakeNotices implements NoticeServiceBase {
  _FakeNotices(this.byBoard, {this.failing = const {}});

  final Map<NoticeBoard, List<NoticeItem>> byBoard;
  final Set<NoticeBoard> failing;
  final asked = <NoticeBoard>[];

  @override
  Future<List<NoticeItem>> fetchNotices(
    NoticeBoard board, {
    bool forceRefresh = false,
  }) async {
    asked.add(board);
    if (failing.contains(board)) throw Exception('실패');
    return byBoard[board] ?? const [];
  }

  @override
  Future<NoticeDetail> fetchDetail(String detailPath) =>
      throw UnimplementedError();

  @override
  Future<Uint8List> downloadAttachment(String url) =>
      throw UnimplementedError();
}

class _FakeSchedule implements AcademicScheduleServiceBase {
  _FakeSchedule(this.byMonth);

  final Map<(int, int), List<AcademicScheduleItem>> byMonth;
  final asked = <(int, int)>[];

  @override
  Future<List<AcademicScheduleItem>> fetchMonth(
    int year,
    int month, {
    bool forceRefresh = false,
  }) async {
    asked.add((year, month));
    return byMonth[(year, month)] ?? const [];
  }
}

AcademicScheduleItem _event(String title, DateTime start, [DateTime? end]) =>
    AcademicScheduleItem(start: start, end: end ?? start, title: title);

void main() {
  group('loadHomeBannerItems', () {
    test('최근 공지 3개와 2주 안 학사일정 2개를 가까운 순서로 모은다', () async {
      final notices = _FakeNotices({
        NoticeBoard.academic: [
          _notice('A', '2026.11.01'),
          _notice('B', '2026.11.06'),
          _notice('C', '2026.10.20'),
        ],
        NoticeBoard.mileage: [_notice('D', '2026.11.04')],
      });
      final longEvent = _event(
        '달넘는일정',
        DateTime(2026, 11, 30),
        DateTime(2026, 12, 3),
      );
      final schedule = _FakeSchedule({
        (2026, 11): [
          _event('지난일정', DateTime(2026, 11, 1)),
          _event('진행중', DateTime(2026, 11, 18), DateTime(2026, 11, 25)),
          longEvent,
          _event('다음주', DateTime(2026, 11, 27)),
        ],
        (2026, 12): [longEvent, _event('너무먼일정', DateTime(2026, 12, 20))],
      });

      final items = await loadHomeBannerItems(
        notices: notices,
        schedule: schedule,
        now: DateTime(2026, 11, 20, 10),
      );

      expect(items.where((i) => i.notice != null).map((i) => i.notice!.title), [
        'B',
        'D',
        'A',
      ]);
      expect(items.where((i) => i.event != null).map((i) => i.event!.title), [
        '진행중',
        '다음주',
      ]);
      // 로그인이 필요한 게시판은 묻지 않는다.
      expect(notices.asked, isNot(contains(NoticeBoard.timetable)));
      // 2주 뒤가 다음 달이면 다음 달도 본다.
      expect(schedule.asked, containsAll([(2026, 11), (2026, 12)]));
    });

    test('달을 넘는 학사일정은 두 달 응답에 있어도 한 번만 담는다', () async {
      final long = _event(
        '겨울방학',
        DateTime(2026, 11, 30),
        DateTime(2026, 12, 20),
      );
      final items = await loadHomeBannerItems(
        notices: _FakeNotices({}),
        schedule: _FakeSchedule({
          (2026, 11): [long],
          (2026, 12): [long],
        }),
        now: DateTime(2026, 11, 25),
      );
      expect(items.map((i) => i.event?.title), ['겨울방학']);
    });

    test('공지를 못 읽어도 학사일정은 보여준다', () async {
      final items = await loadHomeBannerItems(
        notices: _FakeNotices(
          {},
          failing: {NoticeBoard.academic, NoticeBoard.mileage},
        ),
        schedule: _FakeSchedule({
          (2026, 11): [_event('수강정정', DateTime(2026, 11, 9))],
        }),
        now: DateTime(2026, 11, 7),
      );
      expect(items.single.event!.title, '수강정정');
    });
  });

  group('HomeNoticeBanner', () {
    Future<void> pump(
      WidgetTester tester,
      List<HomeBannerItem> items, {
      VoidCallback? onOpenCalendar,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                HomeNoticeBanner(
                  load: () async => items,
                  onOpenCalendar: onOpenCalendar,
                  now: () => DateTime(2026, 11, 7),
                  padding: const EdgeInsets.all(18),
                ),
                const Text('아래 내용'),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('보여줄 것이 없으면 칸 자체를 숨긴다', (tester) async {
      await pump(tester, const []);
      expect(find.byType(PageView), findsNothing);
      expect(
        tester.getTopLeft(find.text('아래 내용')).dy,
        lessThan(10),
        reason: '여백도 남지 않는다',
      );
    });

    testWidgets('공지와 학사일정을 보여주고 4초마다 다음 카드로 넘긴다', (tester) async {
      await pump(tester, [
        HomeBannerItem.notice(_notice('수강 정정 안내', '2026.11.06', isNew: true)),
        HomeBannerItem.event(_event('기말고사', DateTime(2026, 11, 10))),
      ]);

      expect(find.text('수강 정정 안내'), findsOneWidget);
      expect(find.text('학사 공지 · 11.06'), findsOneWidget);
      expect(
        tester
            .getSize(
              find
                  .ancestor(
                    of: find.byType(PageView),
                    matching: find.byType(Container),
                  )
                  .first,
            )
            .height,
        76,
      );

      await tester.pump(HomeNoticeBanner.autoSlide);
      await tester.pumpAndSettle();
      expect(find.text('기말고사'), findsOneWidget);
      expect(find.text('D-3 · 학사일정'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('공지를 누르면 상세, 학사일정을 누르면 캘린더로 간다', (tester) async {
      var calendarOpened = 0;
      await pump(tester, [
        HomeBannerItem.event(_event('기말고사', DateTime(2026, 11, 10))),
        HomeBannerItem.notice(_notice('수강 정정 안내', '2026.11.06')),
      ], onOpenCalendar: () => calendarOpened++);

      await tester.tap(find.text('기말고사'));
      await tester.pumpAndSettle();
      expect(calendarOpened, 1);

      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1500);
      await tester.pumpAndSettle();
      await tester.tap(find.text('수강 정정 안내'));
      await tester.pumpAndSettle();
      expect(find.byType(NoticeDetailScreen), findsOneWidget);
    });
  });
}
