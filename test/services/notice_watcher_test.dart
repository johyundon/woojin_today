import 'package:daejin_app/screens/notice/models/notice_item.dart';
import 'package:daejin_app/services/notice_service.dart';
import 'package:daejin_app/services/notice_watcher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

NoticeItem _n(String title, {NoticeTag tag = NoticeTag.academic}) => NoticeItem(
  title: title,
  author: '학사팀',
  date: '2026.10.31',
  viewCount: 0,
  tag: tag,
);

class _FakeNotices implements NoticeServiceBase {
  List<NoticeItem> academic = [_n('학사 1'), _n('학사 2')];
  List<NoticeItem> mileage = [_n('마일리지 1', tag: NoticeTag.scholarship)];
  bool failMileage = false;

  @override
  Future<List<NoticeItem>> fetchNotices(
    NoticeBoard board, {
    bool forceRefresh = false,
  }) async {
    if (board == NoticeBoard.academic) return academic;
    if (failMileage) throw const NoticeException('fail');
    return mileage;
  }

  @override
  Future<NoticeDetail> fetchDetail(String detailPath) =>
      throw UnimplementedError();
}

void main() {
  late _FakeNotices service;
  late List<String> alerts;
  late NoticeWatcher watcher;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    service = _FakeNotices();
    alerts = [];
    watcher = NoticeWatcher(
      service: service,
      prefs: SharedPreferencesAsync(),
      alert: ({required id, required title, required body}) async =>
          alerts.add('$title|$body'),
    );
  });

  test('처음 확인할 때는 지금 공지를 모두 본 것으로 두고 알리지 않는다', () async {
    await watcher.setEnabled(true);
    expect(await watcher.check(), isEmpty);
    expect(alerts, isEmpty);
    expect(await watcher.hasPending(), isFalse);
  });

  test('다음 확인에서 처음 보는 공지만 새 공지로 잡고 점을 켠다', () async {
    await watcher.check();
    service.academic = [_n('학사 3'), ...service.academic];

    final fresh = await watcher.check();
    expect(fresh.map((n) => n.title), ['학사 3']);
    expect(await watcher.hasPending(), isTrue);
    expect(alerts, isEmpty, reason: '알림은 기본 꺼짐');

    expect(await watcher.check(), isEmpty, reason: '같은 공지는 한 번만');
  });

  test('알림을 켜 두면 새 공지마다 알리고, 3개를 넘으면 한 번으로 묶는다', () async {
    await watcher.setEnabled(true);
    await watcher.check();

    service.academic = [_n('학사 3'), ...service.academic];
    await watcher.check();
    expect(alerts, ['새 공지가 올라왔어요|학사 3']);

    alerts.clear();
    service.academic = [
      for (var i = 4; i <= 7; i++) _n('학사 $i'),
      ...service.academic,
    ];
    await watcher.check();
    expect(alerts, ['새 공지가 4개 올라왔어요|학사 4']);
  });

  test('처음 확인 때 게시판 하나가 실패하면 기록을 남기지 않는다', () async {
    await watcher.setEnabled(true);
    service.failMileage = true;
    await watcher.check();

    service.failMileage = false;
    expect(await watcher.check(), isEmpty, reason: '이때가 처음 기록');
    expect(alerts, isEmpty);
  });

  test('clearPending으로 점을 끈다', () async {
    await watcher.check();
    service.academic = [_n('학사 3'), ...service.academic];
    await watcher.check();
    await watcher.clearPending();
    expect(await watcher.hasPending(), isFalse);
  });
}
