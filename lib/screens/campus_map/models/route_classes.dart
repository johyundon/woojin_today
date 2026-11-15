import '../../../services/class_schedule_parser.dart';
import 'room_building.dart';

/// 길안내의 출발·도착이 오늘 수업 두 개일 때(연강 이동), 위쪽 카드와 아래
/// 시트에 수업명·강의실·시각·여유 시간을 보여 주려고 함께 넘긴다.
class RouteClasses {
  const RouteClasses({required this.from, required this.to});

  /// 방금 끝난(또는 듣는 중인) 수업 — 출발점.
  final TodayClass from;

  /// 다음 수업 — 도착점.
  final TodayClass to;

  String get fromTitle => '${from.course.courseName} · ${roomForSlot(from)}';
  String get toTitle => '${to.course.courseName} · ${roomForSlot(to)}';
  String get fromTime => '${hhmm(from.slot.endMinutes)} 끝';
  String get toTime => '${hhmm(to.slot.startMinutes)} 시작';
  String get toRoom => roomForSlot(to);

  /// 앞 수업이 끝나고 다음 수업이 시작하기까지 남는 분.
  int get spareMinutes => to.slot.startMinutes - from.slot.endMinutes;
}

/// 00:00부터의 분 → "12:05".
String hhmm(int minutes) =>
    '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}';
