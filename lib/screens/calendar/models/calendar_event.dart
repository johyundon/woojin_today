import 'package:flutter/material.dart';

/// 예전 알림 방식(일정 시작 몇 분 전 하나). 지금은 [CalendarEvent.reminderDaysBefore]
/// (며칠 전 목록)를 쓰고, 이 값은 옛 저장분을 옮길 때와 숨겨 둔 수정 화면 칩에서만
/// 쓴다.
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

  /// 마감 하루 전. 지금은 걸지 않고, 예전 버전이 걸어 둔 알림을 취소할 때만 쓴다
  /// (고른 날만 울리도록 바꿈, 사용자 결정 2026-11-14).
  dayBeforeEnd('#before'),

  /// 마감일. [dayBeforeEnd]와 같이 취소용으로만 남아 있다.
  end('#end');

  const ReminderKind(this.idSuffix);

  /// 알림 예약 번호에 붙이는 꼬리. 시작은 일정 id 그대로, 나머지는 따로
  /// 취소할 수 있게 구분한다(`#end`는 예전에 건 알림과 같은 번호).
  final String idSuffix;
}

/// 실제로 걸 알림 하나: 울릴 시각, 종류, 알림 본문, 예약 번호 꼬리.
typedef ScheduledReminder = ({
  DateTime at,
  ReminderKind kind,
  String body,
  String idSuffix,
});

/// "며칠 전" 알림으로 넣을 수 있는 가장 큰 값(시작일 4주 전까지, 사용자 결정 2026-11-13).
const int maxReminderDaysBefore = 28;

/// 가장 작은 값. 음수는 시작일 "뒤"(여러 날 일정이 진행 중인 날)다. 실제로는 끝나는
/// 날까지만 고를 수 있고, 이 값은 저장·취소 범위의 안전한 한계다.
const int minReminderDaysBefore = -60;

/// 알림 설정 창에 늘 나오는 "며칠 전" 줄들. 이 밖의 날은 사용자가 달력에서 직접
/// 고른 날이라 "11월 18일"처럼 날짜로 보여준다([CalendarEvent.reminderDayLabel]).
const List<int> reminderPresetDays = [0, 1, 3, 7, 14, 28];

/// "며칠 전" 이름(알림 본문용). 0은 당일(시간이 있는 일정은 정각), 7의 배수는
/// "N주 전", 음수(시작 뒤)는 "진행 중".
String reminderDaysLabel(int days, {required bool allDay}) {
  if (days < 0) return '진행 중';
  if (days > 0 && days % 7 == 0) return '${days ~/ 7}주 전';
  if (days > 0) return '$days일 전';
  // 기본 알림 시각이 일정 시각이 아니라 오전 9시라서 "정각"이 아닌 "당일"이다.
  return '당일';
}

/// 알림 기본 시각(오전 9시). 알림 시간을 따로 정하지 않은 일정은 종일이든 시간이
/// 있든 고른 날 이 시각에 울린다.
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
    List<int> reminderDaysBefore = const [],
    this.reminderTime,
  }) : reminderDaysBefore = _normalized(reminderDaysBefore);

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

  /// 시작일 며칠 전에 알림을 받을지(0 = 당일). 큰 수부터 정렬돼 있고, 비어 있으면
  /// 알림 꺼짐. 종 버튼의 알림 설정 창에서 여러 개를 넣는다(사용자 결정, 2026-11-13).
  List<int> reminderDaysBefore;

  bool get hasReminder => reminderDaysBefore.isNotEmpty;

  /// 알림이 울리는 시각(고른 날 모두 같은 시각). null이면 기본 시각
  /// [allDayReminderAnchor](오전 9시).
  /// 알림 설정 창에서 바꾼다(사용자 요청, 2026-11-14).
  TimeOfDay? reminderTime;

  /// 지금 알림이 울리는 시각(직접 정한 시각, 없으면 기본 시각).
  /// 기본은 일정 시각과 상관없이 오전 9시다(사용자 결정, 2026-11-14).
  TimeOfDay get effectiveReminderTime => reminderTime ?? allDayReminderAnchor;

  /// 범위([minReminderDaysBefore]~[maxReminderDaysBefore]) 밖은 버리고, 중복 없이
  /// 큰 수부터 정렬한다.
  static List<int> _normalized(Iterable<int> days) =>
      days
          .where(
            (d) => d >= minReminderDaysBefore && d <= maxReminderDaysBefore,
          )
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));

  /// 알림 날짜들을 바꾼다(범위 확인·정렬 포함).
  void setReminderDaysBefore(Iterable<int> days) =>
      reminderDaysBefore = _normalized(days);

  /// 시작일 알림 예약 번호 꼬리. 당일은 예전과 같은 번호(꼬리 없음)를 써서 이미
  /// 걸어 둔 알림과 이어지게 한다.
  static String _daysIdSuffix(int days) => days == 0 ? '' : '#d$days';

  /// 이 일정에 걸릴 수 있는 알림 예약 번호 꼬리 전부. 끄거나 지울 때 이걸 다
  /// 취소해야 남는 알림이 없다(예전 "하루 전" 알림도 꼬리 없는 번호에 걸려 있다).
  static final List<String> allReminderIdSuffixes = [
    for (var d = minReminderDaysBefore; d <= maxReminderDaysBefore; d++)
      _daysIdSuffix(d),
    for (final k in ReminderKind.values)
      if (k != ReminderKind.start) k.idSuffix,
  ];

  bool get isAllDay => startTime == null;

  /// 화면(설정 창·상세 팝업)에 보여줄 알림 날 이름. 기본 줄은 "3일 전"·"2주 전"
  /// (여러 날 일정의 0은 "시작일"), 직접 고른 날은 "11월 18일"처럼 날짜로 쓴다 —
  /// "시작 17일 뒤" 같은 말은 알아보기 어렵다(사용자 요청, 2026-11-14).
  String reminderDayLabel(int days) {
    if (!reminderPresetDays.contains(days)) {
      final date = DateTime(
        startDate.year,
        startDate.month,
        startDate.day - days,
      );
      return '${date.month}월 ${date.day}일';
    }
    if (isMultiDay && days == 0) return '시작일';
    return reminderDaysLabel(days, allDay: isAllDay);
  }

  /// 사용자가 직접 만든 일정이면 true(수정/삭제 가능). 학교가 정한 학사일정은
  /// 보기만 된다 — 직접 만든 일정은 id가 "local-"로 시작한다.
  bool get isUserEvent => id.startsWith('local-');

  bool get isMultiDay =>
      startDate.year != endDate.year ||
      startDate.month != endDate.month ||
      startDate.day != endDate.day;

  /// [date]일 [daysBefore]일 전의 알림 시각([effectiveReminderTime], 기본 오전 9시).
  DateTime _reminderOn(DateTime date, int daysBefore) {
    final t = effectiveReminderTime;
    return DateTime(
      date.year,
      date.month,
      date.day - daysBefore,
      t.hour,
      t.minute,
    );
  }

  /// 시작일 기준 가장 늦은(일정에 가장 가까운) 알림 시각. 알림이 꺼져 있으면
  /// null. 모든 알림이 지났을 때 안내 팝업에 보여주는 시각이다.
  DateTime? get reminderAt => reminderDaysBefore.isEmpty
      ? null
      : _reminderOn(startDate, reminderDaysBefore.last);

  /// 실제로 울려야 할 알림 시각 전부([reminders]의 시각).
  List<DateTime> get reminderAts => [for (final r in reminders) r.at];

  /// 실제로 걸 알림 전부(시각 순). 사용자가 고른 날마다 하나씩이고, 그 밖의
  /// 알림(예전의 마감 전날·마감일 자동 알림)은 걸지 않는다 — 고르지 않은 날에
  /// 울리면 헷갈린다(사용자 요청, 2026-11-14). 본문으로 어느 알림인지 구분한다.
  List<ScheduledReminder> get reminders {
    if (reminderDaysBefore.isEmpty) return const [];
    final schoolPeriod = !isUserEvent && isMultiDay;
    final startDay = '${startDate.month}월 ${startDate.day}일';
    final endDay = '${endDate.month}월 ${endDate.day}일';
    return [
      for (final d in reminderDaysBefore)
        (
          at: _reminderOn(startDate, d),
          kind: ReminderKind.start,
          body: !schoolPeriod
              ? '$label · ${reminderDaysLabel(d, allDay: isAllDay)}'
              : d == 0
              ? '오늘부터 시작 · $endDay까지'
              : d < 0
              ? '진행 중 · $endDay까지'
              : '$d일 뒤 시작 · $startDay ~ $endDay',
          idSuffix: _daysIdSuffix(d),
        ),
    ];
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
    'reminderDaysBefore': reminderDaysBefore,
    // 옛 형식의 `reminderHour`/`reminderMinute`와 겹치지 않게 다른 키를 쓴다.
    'reminderTimeHour': reminderTime?.hour,
    'reminderTimeMinute': reminderTime?.minute,
  };

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    TimeOfDay? time(String hourKey, String minuteKey) {
      final h = json[hourKey] as int?;
      final m = json[minuteKey] as int?;
      return h == null || m == null ? null : TimeOfDay(hour: h, minute: m);
    }

    var startTime = time('startHour', 'startMinute');

    // 지금 형식은 "며칠 전" 목록(`reminderDaysBefore`).
    var days = <int>[
      for (final d in json['reminderDaysBefore'] as List<dynamic>? ?? const [])
        if (d is int) d,
    ];

    // 그 전 형식은 "시작 N분 전" 하나(`reminderOffset`)였다. 하루 전은 1일 전으로,
    // 정각·10분 전·1시간 전은 일 단위로 나타낼 수 없어 당일(정각)로 옮긴다
    // (사용자 결정, 2026-11-13 — 10분~1시간 늦게 울리게 된다).
    if (!json.containsKey('reminderDaysBefore')) {
      final offsetName = json['reminderOffset'] as String?;
      for (final value in ReminderOffset.values) {
        if (value.name == offsetName) {
          days = [value == ReminderOffset.oneDay ? 1 : 0];
        }
      }
    }

    // 더 옛 저장분은 알림 시각을 직접 저장했다("그날 9:30에 울려라"). 같은 시각에
    // 그대로 울리도록 변환한다 — 오전 9시면 종일 일정의 당일로, 그 밖의
    // 시각이면 그 시각을 일정 시작 시각으로 삼아 당일(정각)로.
    var reminderTime = time('reminderTimeHour', 'reminderTimeMinute');
    final legacyHour = json['reminderHour'] as int?;
    final legacyMinute = json['reminderMinute'] as int?;
    if (days.isEmpty && legacyHour != null && legacyMinute != null) {
      final legacy = TimeOfDay(hour: legacyHour, minute: legacyMinute);
      days = [0];
      if (startTime == null && legacy != allDayReminderAnchor) {
        startTime = legacy;
      }
      // 기본 알림 시각이 오전 9시라, 그 밖의 시각은 알림 시간으로도 남겨야 같은
      // 시각에 울린다.
      if (legacy != allDayReminderAnchor) reminderTime = legacy;
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
      reminderDaysBefore: days,
      reminderTime: reminderTime,
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
