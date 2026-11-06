import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/notice/models/notice_item.dart';
import '../screens/notice/services/notice_read_storage.dart';
import 'notice_background.dart';
import 'notice_service.dart';
import 'notification_service.dart';
import 'service_factory.dart';

/// 새 공지 알림을 띄우는 함수. 테스트에서 가짜로 바꾼다.
typedef NoticeAlert = Future<void> Function({
  required String id,
  required String title,
  required String body,
});

/// 앱을 열거나 다시 돌아올 때 새 공지가 올라왔는지 확인한다.
///
/// 알림이 켜져 있으면 앱이 꺼져 있을 때도 몇 시간마다 OS가 앱을 깨워 확인한다
/// ([NoticeBackground]). 학교 페이지의 "새글"
/// 표시는 며칠 동안 붙어 있어 같은 공지로 알림이 여러 번 갈 수 있으므로, 대신
/// 지난번에 본 공지 목록을 기기에 저장해 두고 그 목록에 없던 공지만 새 공지로 본다.
/// 처음 실행할 때는 지금 있는 공지를 모두 본 것으로 저장하고 알림을 보내지 않는다.
///
/// 목록은 [NoticeService]의 1시간 캐시를 그대로 써서, 앱을 자주 열어도 학교에는
/// 한 시간에 최대 한 번만 요청한다. 로그아웃하면 `logout_cleaner`가 기기 저장소를
/// 지우므로 여기 저장한 값도 함께 지워진다.
class NoticeWatcher {
  NoticeWatcher({
    NoticeServiceBase? service,
    SharedPreferencesAsync? prefs,
    NoticeAlert? alert,
    NoticeBackground? background,
    NoticeReadStorage? readStorage,
  }) : _service = service ?? ServiceFactory.notice(),
       _readStorageArg = readStorage,
       _prefsArg = prefs,
       _alert = alert ?? NotificationService.instance.showNoticeAlert,
       _background = background ?? const NoticeBackground();

  /// 지금까지 확인한 공지([NoticeItem.key]).
  static const _seenKey = 'notice_watch_seen';

  /// 새로 들어왔지만 아직 공지사항 화면에서 보지 않은 공지. 홈 종 아이콘의 점.
  static const _pendingKey = 'notice_watch_pending';

  /// "새 글 알림 받기" 켜짐 여부. 기본은 꺼짐(켤 때 알림 권한을 묻기 때문).
  static const _enabledKey = 'notice_watch_enabled';

  /// 본 공지 목록을 이 개수까지만 남긴다(오래된 것부터 버림).
  static const _maxSeen = 300;

  /// 한 번에 개별 알림으로 띄우는 최대 개수. 넘으면 한 건으로 묶는다.
  static const _maxAlerts = 3;

  final NoticeServiceBase _service;
  final SharedPreferencesAsync? _prefsArg;

  /// 처음 쓸 때 만든다. 저장소가 없는 환경(위젯 테스트 등)에서는 만들 때 예외가
  /// 나는데, 쓰는 곳이 모두 try 안이라 조용히 넘어간다.
  late final SharedPreferencesAsync _prefs =
      _prefsArg ?? SharedPreferencesAsync();
  final NoticeAlert _alert;
  final NoticeBackground _background;
  final NoticeReadStorage? _readStorageArg;

  Future<bool> isEnabled() async {
    try {
      return await _prefs.getBool(_enabledKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// 켜면 앱이 꺼져 있을 때의 확인 작업도 등록하고, 끄면 취소한다.
  Future<void> setEnabled(bool enabled) async {
    try {
      await _prefs.setBool(_enabledKey, enabled);
    } catch (e) {
      debugPrint('[NoticeWatcher] 알림 설정 저장 실패: $e');
    }
    try {
      enabled ? await _background.start() : await _background.stop();
    } catch (e) {
      debugPrint('[NoticeWatcher] 백그라운드 확인 등록/취소 실패: $e');
    }
  }

  /// 앱 시작 시 부른다. 알림이 켜져 있으면 백그라운드 확인 작업이 등록돼 있게
  /// 한다(이 기능이 생기기 전에 알림을 켜 둔 사용자도 등록되도록).
  Future<void> restoreBackground() async {
    if (!await isEnabled()) return;
    try {
      await _background.start();
    } catch (e) {
      debugPrint('[NoticeWatcher] 백그라운드 확인 등록 실패: $e');
    }
  }

  /// 공지사항 화면에서 아직 보지 않은 새 공지가 있는지(홈 종 아이콘의 점).
  Future<bool> hasPending() async {
    try {
      return (await _prefs.getStringList(_pendingKey))?.isNotEmpty ?? false;
    } catch (_) {
      return false;
    }
  }

  /// 공지사항 화면을 열었을 때 부른다. 종 아이콘의 점을 끈다.
  Future<void> clearPending() async {
    try {
      await _prefs.remove(_pendingKey);
    } catch (e) {
      debugPrint('[NoticeWatcher] 새 공지 표시 지우기 실패: $e');
    }
  }

  /// 새 공지를 확인하고, 알림이 켜져 있으면 알림을 띄운다. 새 공지 목록을 돌려준다.
  /// 어떤 실패도 밖으로 던지지 않는다(홈 화면을 막지 않기 위해).
  /// 공지사항 화면과 같은 기준의 "안 읽은 새 글"이 있는지. 게시판이 새 글
  /// 표시([NoticeItem.isNew])를 붙였고 아직 열어 보지 않은 공지가 하나라도 있으면
  /// true. 홈 종 아이콘의 점에 쓴다. 공지 목록은 저장분(1시간)을 써서 보통 학교에
  /// 새로 묻지 않는다. 로그인이 필요한 게시판은 건너뛰고, 실패하면 false.
  Future<bool> hasUnread() async {
    try {
      final read = await (_readStorageArg ?? NoticeReadStorage()).load();
      for (final board in NoticeBoard.values) {
        if (board.requiresLogin) continue;
        try {
          final items = await _service.fetchNotices(board);
          if (items.any((n) => n.isNew && !read.contains(n.key))) return true;
        } catch (e) {
          debugPrint('[NoticeWatcher] ${board.name} 안 읽은 공지 확인 실패: $e');
        }
      }
    } catch (e) {
      debugPrint('[NoticeWatcher] 안 읽은 공지 확인 실패: $e');
    }
    return false;
  }

  Future<List<NoticeItem>> check() async {
    try {
      final current = <NoticeItem>[];
      var anyFailed = false;
      for (final board in NoticeBoard.values) {
        // 로그인이 필요한 게시판은 로그인 정보 없이 읽을 수 없어 건너뛴다.
        if (board.requiresLogin) continue;
        try {
          current.addAll(await _service.fetchNotices(board));
        } catch (e) {
          anyFailed = true;
          // 한 게시판이 실패하면 그 게시판은 이번에 건너뛴다(본 목록은 그대로).
          debugPrint('[NoticeWatcher] ${board.name} 공지 확인 실패: $e');
        }
      }
      if (current.isEmpty) return const [];

      final stored = await _prefs.getStringList(_seenKey);
      // 처음 기록은 모든 게시판을 받았을 때만 남긴다. 한쪽만 남기면 다음에 나머지
      // 게시판의 공지가 전부 새 공지로 잡혀 알림이 몰린다.
      if (stored == null && anyFailed) return const [];
      final seen = [...?stored];
      final seenSet = seen.toSet();
      final fresh = stored == null
          ? const <NoticeItem>[]
          : [
              for (final n in current)
                if (!seenSet.contains(n.key)) n,
            ];

      for (final n in current) {
        if (seenSet.add(n.key)) seen.add(n.key);
      }
      await _prefs.setStringList(
        _seenKey,
        seen.length > _maxSeen ? seen.sublist(seen.length - _maxSeen) : seen,
      );
      if (fresh.isEmpty) return const [];

      final pending = {
        ...?await _prefs.getStringList(_pendingKey),
        for (final n in fresh) n.key,
      };
      await _prefs.setStringList(_pendingKey, pending.toList());

      if (await isEnabled()) await _notify(fresh);
      return fresh;
    } catch (e) {
      debugPrint('[NoticeWatcher] 새 공지 확인 실패: $e');
      return const [];
    }
  }

  Future<void> _notify(List<NoticeItem> fresh) async {
    if (fresh.length > _maxAlerts) {
      await _alert(
        id: 'notice_watch_summary',
        title: '새 공지가 ${fresh.length}개 올라왔어요',
        body: fresh.first.title,
      );
      return;
    }
    for (final n in fresh) {
      await _alert(id: n.key, title: '새 공지가 올라왔어요', body: n.title);
    }
  }
}
