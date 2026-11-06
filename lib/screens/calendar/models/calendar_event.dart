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

/// 여러 날 학사일정의 알림 종류.
enum ReminderKind {
  /// 시작일(하루짜리 일정·내가 만든 일정은 이것 하나뿐).
  start(''),

  /// 마감 하루 전. 기간이 3일 이상일 때만(2일짜리는 시작일과 겹침).
  dayBeforeEnd('#before'),

  /// 마감일.
  end('#end');

  const ReminderKind(this.idSuffix);

  /// 알림 예약 번호에 붙이는 꼬리. 시작은 일정 id 그대로, 나머지는 따로
  /// 취소할 수 있게 구분한다(`#end`는 예전에 건 알림과 같은 번호).
  final String idSuffix;
}

/// 실제로 걸 알림 하나: 울릴 시각, 종류, 알림 본문.
typedef ScheduledReminder = ({DateTime at, ReminderKind kind, String body});

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

  /// 실제로 울려야 할 알림 시각 전부([reminders]의 시각).
  List<DateTime> get reminderAts => [for (final r in reminders) r.at];

  /// 실제로 걸 알림 전부. 사용자가 만든 일정과 하루짜리 일정은 시작일 한 번이다.
  /// 여러 날에 걸친 학사일정은 시작일, 마감 하루 전(3일 이상일 때), 마감일까지
  /// 최대 세 번이다 — 매일 울리면 긴 일정에서 너무 많고, 마감 당일 한 번만으로는
  /// 신청·납부를 처리하기 빠듯해서다. 본문으로 어느 알림인지 구분한다.
  List<ScheduledReminder> get reminders {
    final first = reminderAt;
    if (first == null) return const [];
    if (isUserEvent || !isMultiDay) {
      return [
        (
          at: first,
          kind: ReminderKind.start,
          body: '$label · ${reminderOffset!.label}',
        ),
      ];
    }
    final endDay = '${endDate.month}월 ${endDate.day}일';
    final deadline = _deadlinePattern.hasMatch(title);
    final days = DateTime(endDate.year, endDate.month, endDate.day)
        .difference(DateTime(startDate.year, startDate.month, startDate.day))
        .inDays;
    return [
      (at: first, kind: ReminderKind.start, body: '오늘부터 시작 · $endDay까지'),
      if (days >= 2)
        (
          at: _reminderOn(endDate.subtract(const Duration(days: 1)))!,
          kind: ReminderKind.dayBeforeEnd,
          body: deadline ? '내일 마감 · $endDay' : '내일 끝나요 · $endDay',
        ),
      (
        at: _reminderOn(endDate)!,
        kind: ReminderKind.end,
        body: deadline ? '오늘 마감' : '오늘 끝나요',
      ),
    ];
  }

  /// 제목에 이 말이 있으면 "마감"으로, 없으면(방학·시험 기간 등) "끝나요"로 쓴다.
  /// 학교 일정 제목이 다양해 완벽한 구분은 아니다.
  static final _deadlinePattern = RegExp('신청|등록|납부|제출|접수');

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
