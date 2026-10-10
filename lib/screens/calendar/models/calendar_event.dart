import 'package:flutter/material.dart';

/// 캘린더 화면의 일정 하나.
///
/// 학사일정 API 연동이 없어(`kUseMockApi = true`) 최초 1회는 하드코딩된 샘플
/// 데이터로 시드되지만, 알림을 걸 수 있어야 해서 이후로는 기기 로컬
/// (`CalendarEventStorage`, SharedPreferences)에 저장된다. [reminderTime]은
/// 알림 토글을 켜고 끌 때마다 그 자리에서 바뀌어야 해서(toggle on → 시간
/// 설정 바텀시트 → 저장) final로 두지 않았다.
class CalendarEvent {
  CalendarEvent({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.label,
    required this.title,
    required this.color,
    this.reminderTime,
  });

  final String id;

  /// 하루짜리 일정이면 [startDate] == [endDate].
  final DateTime startDate;
  final DateTime endDate;

  /// "학사일정" 같은 카테고리 라벨.
  final String label;
  final String title;

  /// 날짜 칸의 요약 바 + 카드 왼쪽 점 색.
  final Color color;

  /// null이면 알림 꺼짐. 알림은 [startDate]의 이 시각에 한 번만 울린다
  /// (여러 날짜짜리 일정이어도 마감일이 아닌 시작일 기준 — 제품 결정).
  TimeOfDay? reminderTime;

  bool get hasReminder => reminderTime != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'label': label,
    'title': title,
    'color': color.toARGB32(),
    'reminderHour': reminderTime?.hour,
    'reminderMinute': reminderTime?.minute,
  };

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    final reminderHour = json['reminderHour'] as int?;
    final reminderMinute = json['reminderMinute'] as int?;
    return CalendarEvent(
      id: json['id'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      label: json['label'] as String,
      title: json['title'] as String,
      color: Color(json['color'] as int),
      reminderTime: reminderHour == null
          ? null
          : TimeOfDay(hour: reminderHour, minute: reminderMinute!),
    );
  }
}

/// 날짜 칸 요약 바 / 카드 점 색상 팔레트.
///
/// Figma 노드(6:39 "캘린더")가 스크린샷 7장으로 평탄화돼 있어 실제 hex 값을
/// 뽑을 수 없었다 — 스크린샷을 눈으로 보고 근사했다(파랑/보라/주황/초록/핑크).
const List<Color> calendarEventPalette = [
  Color(0xFF3D6CFF), // 파랑
  Color(0xFF8B5CF6), // 보라
  Color(0xFFFF7A29), // 주황 (accentOrange)
  Color(0xFF34C759), // 초록
  Color(0xFFE0558F), // 핑크
];
