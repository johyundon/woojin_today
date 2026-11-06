import 'package:flutter/foundation.dart';

import '../../../services/academic_schedule_service.dart';
import '../../../services/notice_service.dart';
import '../../notice/models/notice_item.dart';

/// 홈·모아보기 위쪽 배너 한 장. 공지([notice]) 또는 학사일정([event]) 중 하나.
class HomeBannerItem {
  const HomeBannerItem.notice(NoticeItem this.notice) : event = null;
  const HomeBannerItem.event(AcademicScheduleItem this.event) : notice = null;

  final NoticeItem? notice;
  final AcademicScheduleItem? event;
}

/// 배너에 보여줄 공지는 최근 것부터 이만큼.
const int _maxNotices = 3;

/// 앞으로 이 기간 안에 시작하는(또는 진행 중인) 학사일정을 보여준다.
const Duration _eventWindow = Duration(days: 14);

/// 배너에 보여줄 학사일정은 가까운 것부터 이만큼.
const int _maxEvents = 2;

/// 배너 카드들을 모은다. 공지는 로그인 없이 볼 수 있는 게시판(학사·마일리지장학)의
/// 최근 글, 학사일정은 오늘부터 2주 안의 일정이다.
///
/// 두 서비스 모두 받은 목록을 기기에 저장해 두고(공지 1시간, 학사일정 하루)
/// 그 안에는 학교에 다시 묻지 않는다. 홈은 새 공지 확인이 끝난 뒤 이 함수를
/// 불러서 공지는 보통 저장분을 쓴다. 한쪽이 실패해도 다른 쪽은 보여준다.
Future<List<HomeBannerItem>> loadHomeBannerItems({
  required NoticeServiceBase notices,
  required AcademicScheduleServiceBase schedule,
  required DateTime now,
}) async {
  final noticeItems = <NoticeItem>[];
  // 새 공지 확인([NoticeWatcher.check])과 같은 게시판을 읽어야 저장분을 같이 쓴다.
  for (final board in NoticeBoard.values) {
    if (board.requiresLogin) continue;
    try {
      noticeItems.addAll(await notices.fetchNotices(board));
    } catch (e) {
      debugPrint('[HomeBanner] ${board.name} 공지 읽기 실패: $e');
    }
  }
  // 날짜는 "2026.11.06" 형식이라 글자 순서가 곧 날짜 순서다.
  noticeItems.sort((a, b) => b.date.compareTo(a.date));

  final today = DateTime(now.year, now.month, now.day);
  final until = today.add(_eventWindow);
  final months = {(today.year, today.month), (until.year, until.month)};
  final events = <String, AcademicScheduleItem>{};
  for (final (year, month) in months) {
    try {
      for (final e in await schedule.fetchMonth(year, month)) {
        final notOver = !e.end.isBefore(today);
        final startsSoon = !e.start.isAfter(until);
        // 달을 넘는 일정은 두 달 응답에 모두 들어 있어 id로 한 번만 담는다.
        if (notOver && startsSoon) events[e.id] = e;
      }
    } catch (e) {
      debugPrint('[HomeBanner] $year-$month 학사일정 읽기 실패: $e');
    }
  }
  final upcoming = events.values.toList()
    ..sort((a, b) => a.start.compareTo(b.start));

  return [
    for (final n in noticeItems.take(_maxNotices)) HomeBannerItem.notice(n),
    for (final e in upcoming.take(_maxEvents)) HomeBannerItem.event(e),
  ];
}
