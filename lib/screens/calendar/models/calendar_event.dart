import 'package:flutter/material.dart';

/// 알림을 일정 시작 몇 분 전에 울릴지.
enum ReminderOffset {
  atStart('정각', 0),
  tenMinutes('10분 전', 10),
  oneHour('1시간 전', 60),
  oneDay('하루 전', 24 * 60);

  const ReminderOffset(this.label, this.minutes);

  final String label;
  final int minutes;
}

/// 종일 일정(시작 시간 없음)의 알림을 계산할 때 "시작 시각"으로 보는 시각.
const TimeOfDay allDayReminderAnchor = TimeOfDay(hour: 9, minute: 0);

/// 캘린더 화면의 일정 하나.
///
/// 학사일정 API 연동이 없어(`kUseMockApi = true`) 최초 1회는 하드코딩된 샘플
/// 데이터로 시드되지만, 알림을 걸 수 있어야 해서 이후로는 기기 로컬
/// (`CalendarEventStorage`, SharedPreferences)에 저장된다. 시간/장소/알림은
/// 알림 스위치를 켜고 끌 때마다 그 자리에서 바뀌어야 해서 final로 두지 않았다.
class CalendarEvent {
  CalendarEvent({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.label,
    required this.title,
    required this.color,
    this.startTime,
    this.endTime,
    this.location,
    this.reminderOffset,
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

  /// 일정 시작/끝 시각. [startTime]이 null이면 종일 일정이다. [endTime]은
  /// 시작 시각만 정한 일정에서는 null일 수 있다.
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  /// 장소(없으면 null).
  String? location;

  /// "시작 N분 전" 알림. null이면 알림 꺼짐. 알림은 여러 날짜짜리 일정이어도
  /// 시작일 기준으로 한 번만 울린다(제품 결정).
  ReminderOffset? reminderOffset;

  bool get hasReminder => reminderOffset != null;

  bool get isAllDay => startTime == null;

  /// 사용자가 직접 만든 일정이면 true(수정/삭제 가능). 학교가 정한 학사일정은
  /// 보기만 된다 — 직접 만든 일정은 id가 "local-"로 시작한다.
  bool get isUserEvent => id.startsWith('local-');

  bool get isMultiDay =>
      startDate.year != endDate.year ||
      startDate.month != endDate.month ||
      startDate.day != endDate.day;

  /// [reminderOffset]에 따른, [date]일의 실제 알림 시각. 알림이 꺼져 있으면 null.
  /// 종일 일정은 [allDayReminderAnchor](오전 9시)를 시작으로 본다.
  DateTime? _reminderOn(DateTime date) {
    final offset = reminderOffset;
    if (offset == null) return null;
    final t = startTime ?? allDayReminderAnchor;
    final start = DateTime(date.year, date.month, date.day, t.hour, t.minute);
    return start.subtract(Duration(minutes: offset.minutes));
  }

  /// 시작일 기준 알림 시각(알림이 꺼져 있으면 null).
  DateTime? get reminderAt => _reminderOn(startDate);

  /// 실제로 울려야 할 알림 시각 전부. 사용자가 만든 일정은 시작일 한 번이고,
  /// 여러 날에 걸친 학사일정은 시작일과 마감일(끝나는 날) 두 번이다 — 시작과 마감이
  /// 둘 다 중요한데 매일 울리면 기간이 긴 일정에서 너무 많아서다.
  List<DateTime> get reminderAts {
    final first = reminderAt;
    if (first == null) return const [];
    if (isUserEvent || !isMultiDay) return [first];
    return [first, _reminderOn(endDate)!];
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'label': label,
    'title': title,
    'color': color.toARGB32(),
    'startHour': startTime?.hour,
    'startMinute': startTime?.minute,
    'endHour': endTime?.hour,
    'endMinute': endTime?.minute,
    'location': location,
    'reminderOffset': reminderOffset?.name,
  };

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    TimeOfDay? time(String hourKey, String minuteKey) {
      final h = json[hourKey] as int?;
      final m = json[minuteKey] as int?;
      return h == null || m == null ? null : TimeOfDay(hour: h, minute: m);
    }

    var startTime = time('startHour', 'startMinute');

    final offsetName = json['reminderOffset'] as String?;
    ReminderOffset? offset;
    for (final value in ReminderOffset.values) {
      if (value.name == offsetName) offset = value;
    }

    // 옛 저장분은 알림 시각을 직접 저장했다("그날 9:30에 울려라"). 같은 시각에
    // 그대로 울리도록 변환한다 — 오전 9시면 종일 일정의 "정각"으로, 그 밖의
    // 시각이면 그 시각을 일정 시작 시각으로 삼아 "정각"으로.
    final legacyHour = json['reminderHour'] as int?;
    final legacyMinute = json['reminderMinute'] as int?;
    if (offset == null && legacyHour != null && legacyMinute != null) {
      final legacy = TimeOfDay(hour: legacyHour, minute: legacyMinute);
      offset = ReminderOffset.atStart;
      if (startTime == null && legacy != allDayReminderAnchor) {
        startTime = legacy;
      }
    }

    return CalendarEvent(
      id: json['id'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      label: json['label'] as String,
      title: json['title'] as String,
      color: Color(json['color'] as int),
      startTime: startTime,
      endTime: time('endHour', 'endMinute'),
      location: json['location'] as String?,
      reminderOffset: offset,
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
