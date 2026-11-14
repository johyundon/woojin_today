import 'package:flutter/material.dart';

import '../advisor/advisor_consultation_screen.dart';
import '../cafeteria/cafeteria_screen.dart';
import '../calendar/calendar_screen.dart';
import '../campus_map/campus_map_screen.dart';
import '../fileshare/fileshare_screen.dart';
import '../graduation/graduation_credit_screen.dart';
import '../home/rank/department_rank_screen.dart';
import '../mileage/mileage_screen.dart';
import '../notice/notice_screen.dart';
import '../weather/weather_page.dart';

/// 기능 화면을 열 때 필요한, 홈에서 받아 온 값.
class FeatureLinks {
  const FeatureLinks({this.userId2, this.onTabTap});

  /// 포털 로그인으로 얻은 본인 SSO uid(학과 등수·졸업학점·파일공유·상담 예약).
  final String? userId2;

  /// 홈의 하단 탭 이동(0 시간표). 시간표는 세션 쿠키가 필요해 이 경로로 연다.
  final ValueChanged<int>? onTabTap;
}

/// 앱 기능 하나. 모아보기 화면과 검색 화면이 같은 목록을 쓴다.
class AppFeature {
  const AppFeature({
    required this.label,
    required this.description,
    required this.icon,
    required this.open,
    this.keywords = const [],
  });

  final String label;
  final String description;
  final IconData icon;

  /// 이름·설명에 없는 말로도 찾을 수 있게 하는 검색어(예: 학식 → 밥, 점심).
  final List<String> keywords;

  final void Function(BuildContext context, FeatureLinks links) open;

  /// 이름·설명·검색어 중 하나에 [query]가 들어 있는지(띄어쓰기·대소문자 무시).
  bool matches(String query) {
    final q = normalizeSearchText(query);
    if (q.isEmpty) return false;
    return [
      label,
      description,
      ...keywords,
    ].any((t) => normalizeSearchText(t).contains(q));
  }
}

/// 검색 비교용: 띄어쓰기를 빼고 영문은 소문자로.
String normalizeSearchText(String text) =>
    text.replaceAll(RegExp(r'\s+'), '').toLowerCase();

void _push(BuildContext context, Widget screen) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
}

/// 앱 기능 목록.
abstract final class AppFeatures {
  static final timetable = AppFeature(
    label: '시간표',
    description: '다음 수업 확인',
    icon: Icons.calendar_month_rounded,
    keywords: const ['수업', '강의', '과목', '강의실', '수강'],
    open: (context, links) => links.onTabTap?.call(0),
  );

  static final cafeteria = AppFeature(
    label: '학식',
    description: '오늘의 메뉴',
    icon: Icons.restaurant_rounded,
    keywords: const ['식당', '메뉴', '밥', '점심', '저녁', '아침', '학생식당'],
    open: (context, links) => _push(context, const CafeteriaScreen()),
  );

  static final calendar = AppFeature(
    label: '캘린더',
    description: '학사일정·내 일정',
    icon: Icons.event_rounded,
    keywords: const ['일정', '달력', '시험', '방학', '개강'],
    open: (context, links) =>
        _push(context, CalendarScreen(onTabTap: links.onTabTap)),
  );

  static final notice = AppFeature(
    label: '공지사항',
    description: '학교 소식을 확인해요',
    icon: Icons.campaign_rounded,
    keywords: const ['공지', '소식', '안내', '게시판'],
    open: (context, links) => _push(context, const NoticeScreen()),
  );

  static final departmentRank = AppFeature(
    label: '학과 등수',
    description: '우리 학과에서 내 위치',
    icon: Icons.leaderboard_rounded,
    keywords: const ['등수', '석차', '순위', '성적', '평점', '학점'],
    open: (context, links) => _push(
      context,
      DepartmentRankScreen(isDark: true, userId2: links.userId2),
    ),
  );

  static final graduationCredit = AppFeature(
    label: '졸업학점',
    description: '남은 학점 확인',
    icon: Icons.school_rounded,
    keywords: const ['졸업', '학점', '이수'],
    open: (context, links) =>
        _push(context, GraduationCreditScreen(userId2: links.userId2)),
  );

  static final mileage = AppFeature(
    label: '마일리지',
    description: '내 점수와 비교과 내역',
    icon: Icons.stars_rounded,
    keywords: const ['장학', '장학금', '포인트', '점수'],
    open: (context, links) => _push(context, const MileageScreen()),
  );

  static final consecutiveClasses = AppFeature(
    label: '연강',
    description: '붙어 있는 수업 이동 시간',
    icon: Icons.timelapse_rounded,
    keywords: const ['이동', '이동시간', '쉬는시간'],
    open: (context, links) => _push(context, const CampusMapScreen()),
  );

  static final weather = AppFeature(
    label: '날씨',
    description: '오늘 학교 날씨',
    icon: Icons.wb_sunny_rounded,
    keywords: const ['기온', '비', '미세먼지', '우산'],
    open: (context, links) => _push(context, const WeatherPage()),
  );

  static final campusMap = AppFeature(
    label: '캠퍼스 지도',
    description: '건물 위치와 길찾기',
    icon: Icons.map_rounded,
    keywords: const ['지도', '길찾기', '건물', '위치'],
    open: (context, links) => _push(context, const CampusMapScreen()),
  );

  static final fileShare = AppFeature(
    label: '파일공유',
    description: '친구와 파일 주고받기',
    icon: Icons.folder_shared_rounded,
    keywords: const ['파일', '공유', '자료'],
    open: (context, links) =>
        _push(context, FileShareScreen(userId2: links.userId2)),
  );

  static final advisor = AppFeature(
    label: '상담 예약',
    description: '지도교수 상담 신청',
    icon: Icons.forum_rounded,
    keywords: const ['상담', '지도교수', '교수', '면담'],
    open: (context, links) =>
        _push(context, AdvisorConsultationScreen(userId2: links.userId2)),
  );

  static final all = [
    timetable,
    cafeteria,
    calendar,
    notice,
    departmentRank,
    graduationCredit,
    mileage,
    consecutiveClasses,
    weather,
    campusMap,
    fileShare,
    advisor,
  ];
}
