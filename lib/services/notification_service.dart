import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// 캘린더 일정 알림(로컬 푸시) 전담 서비스.
///
/// 서버가 없는 앱이라(`kUseMockApi = true`, 학사일정 API 연동 자체가 없음)
/// FCM 같은 서버 발송 방식은 안 맞고, OS가 들고 있다가 울려주는 로컬 알림만
/// 쓴다. 이 앱은 대진대(국내) 학생 전용이라 시간대는 'Asia/Seoul'로 고정한다
/// (자동 지역감지 패키지를 더 추가할 실익이 없음).
///
/// 알림은 "정확히 그 1분"이 중요한 게 아니라 "그 시간대쯤 챙기면 되는"
/// 성격이라 비정확(inexact) 모드로 예약한다 — Android 12+의 정확 알람
/// 권한(SCHEDULE_EXACT_ALARM) 요청 단계를 생략할 수 있어 UX가 더 단순하다.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _channelId = 'calendar_reminders';
  static const _channelName = '학사일정 알림';
  static const _channelDescription = '캘린더에 등록한 일정의 알림 시각에 울린다.';

  static const _noticeChannelId = 'notice_updates';
  static const _noticeChannelName = '공지사항 알림';
  static const _noticeChannelDescription = '새 공지가 올라오면 울린다.';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// 앱 시작 시(main.dart) 한 번만 호출한다.
  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      ),
    );

    _initialized = true;
  }

  /// 알림 토글을 켤 때(Just-In-Time) 호출한다. 거부되면 false를 반환하고,
  /// 호출한 쪽에서 토글을 다시 꺼야 한다.
  Future<bool> requestPermission() async {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl != null) {
      return await androidImpl.requestNotificationsPermission() ?? false;
    }

    final iosImpl = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosImpl != null) {
      return await iosImpl.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    // Android/iOS가 아닌 플랫폼(데스크톱 등)에서는 권한 개념이 없어 통과시킨다.
    return true;
  }

  /// [scheduledAt]에 일정 제목으로 알림을 한 번 울리도록 예약한다.
  /// 이미 같은 [eventId]로 걸린 예약이 있으면 먼저 취소하고 다시 건다.
  Future<void> scheduleReminder({
    required String eventId,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    final id = _notificationIdFor(eventId);
    await _plugin.cancel(id: id);

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledAt, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// 새 공지 알림을 예약 없이 즉시 띄운다. [scheduleReminder]와 달리 미래
  /// 시각 예약이 아니라 호출 즉시 표시되는 알림이라 전용 채널을 따로 쓴다.
  Future<void> showNoticeAlert({
    required String id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id: _notificationIdFor(id),
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _noticeChannelId,
          _noticeChannelName,
          channelDescription: _noticeChannelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> cancelReminder(String eventId) {
    return _plugin.cancel(id: _notificationIdFor(eventId));
  }

  /// `flutter_local_notifications`는 32비트 정수 id가 필요한데
  /// [CalendarEvent.id]는 문자열이라 변환이 필요하다. Dart 내장
  /// `String.hashCode`는 Dart/Flutter 버전 간 동일 값을 보장하지 않아서
  /// (앱 업데이트 후 같은 일정인데 다른 id가 나와 cancel이 안 먹는 버그로
  /// 이어질 수 있음) 직접 구현한 FNV-1a 해시로 31비트 양의 정수를 만든다.
  int _notificationIdFor(String id) {
    const fnvPrime = 0x01000193;
    var hash = 0x811c9dc5;
    for (final codeUnit in id.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }
    return hash & 0x7FFFFFFF;
  }
}
