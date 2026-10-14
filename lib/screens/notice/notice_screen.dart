import 'package:flutter/material.dart';

import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/mascot_sticker.dart';
import 'models/notice_item.dart';
import 'services/notice_mock_data.dart';
import 'services/notice_read_storage.dart';
import 'widgets/notice_list_card.dart';

/// "공지사항" 화면("놓치면 안 되는 공지" v4 리디자인). 전체/학사/장학/학과/행사
/// 칩으로 거르고, 카드의 북마크로 중요한 공지를 표시해 둘 수 있다(북마크는
/// 저장하지 않고 화면이 열려 있는 동안만 유지된다).
///
/// 공지사항 API가 명세서에 없어 [NoticeMockData]의 목데이터로만 동작한다.
///
/// "새 글 알림 받기" 토글은 서버가 없어 "새 공지가 올라왔는지" 실시간으로
/// 구독할 방법은 없지만([NotificationService]와 같은 이유, 캘린더 알림
/// 참고), 토글을 켤 때 지금 목데이터에서 `isNew`로 표시된 공지들에 대해
/// 실제 로컬 알림을 즉시 띄워준다([NotificationService.showNoticeAlert]).
/// 켜짐/꺼짐 상태 자체는 저장하지 않는다(화면을 나갔다 들어오면 기본값
/// true로 초기화됨).
class NoticeScreen extends StatefulWidget {
  const NoticeScreen({super.key});

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  final _notifications = NotificationService.instance;
  final _readStorage = NoticeReadStorage();

  /// null이면 "전체".
  NoticeTag? _filter;
  bool _notifyEnabled = true;
  final Set<String> _bookmarked = {};
  final Set<String> _read = {};

  @override
  void initState() {
    super.initState();
    _loadRead();
  }

  Future<void> _loadRead() async {
    final read = await _readStorage.load();
    if (!mounted) return;
    setState(() => _read.addAll(read));
  }

  void _markRead(NoticeItem notice) {
    if (!_read.add(notice.key)) return;
    setState(() {});
    _readStorage.save(_read);
  }

  bool _isUnread(NoticeItem n) => n.isNew && !_read.contains(n.key);

  @override
  Widget build(BuildContext context) {
    final filtered = NoticeMockData.noticesFor(_filter);
    // 북마크한 공지를 맨 위로(각 묶음 안의 순서는 최신순 그대로).
    final notices = [
      ...filtered.where((n) => _bookmarked.contains(n.key)),
      ...filtered.where((n) => !_bookmarked.contains(n.key)),
    ];
    final newCount = NoticeMockData.all.where(_isUnread).length;

    return Scaffold(
      backgroundColor: AppColors.cobalt,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: AppColors.cobaltDeep,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.lime,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.campaign,
                                    size: 14,
                                    color: AppColors.ink,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '새 글 $newCount개',
                                    style: const TextStyle(
                                      color: AppColors.ink,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 시안에는 없지만 기존 "새 글 알림 받기" 기능을 남긴
                            // 작은 종 버튼.
                            GestureDetector(
                              onTap: () => _onNotifyToggled(!_notifyEnabled),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: const BoxDecoration(
                                  color: AppColors.cobaltDeep,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _notifyEnabled
                                      ? Icons.notifications_active
                                      : Icons.notifications_off,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '놓치면 안 되는 공지',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.04,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Positioned(
                    right: 0,
                    top: 0,
                    child: MascotSticker(width: 76, angle: 0.08),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _FilterChip(
                    label: '전체',
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  for (final tag in NoticeTag.values) ...[
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: tag.label,
                      selected: _filter == tag,
                      onTap: () => setState(() => _filter = tag),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: notices.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final notice = notices[index];
                  final key = notice.key;
                  return NoticeListCard(
                    notice: notice,
                    bookmarked: _bookmarked.contains(key),
                    unread: _isUnread(notice),
                    onBookmarkTap: () => setState(() {
                      if (!_bookmarked.remove(key)) _bookmarked.add(key);
                    }),
                    onOpened: () => _markRead(notice),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onNotifyToggled(bool turnOn) async {
    if (!turnOn) {
      setState(() => _notifyEnabled = false);
      return;
    }

    final granted = await _notifications.requestPermission();
    if (!mounted) return;
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('알림을 받으려면 설정에서 알림 권한을 허용해주세요')),
      );
      return;
    }

    setState(() => _notifyEnabled = true);

    for (final notice in NoticeMockData.all.where(_isUnread)) {
      await _notifications.showNoticeAlert(
        id: notice.key,
        title: '새 공지가 올라왔어요',
        body: notice.title,
      );
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.lime : AppColors.cobaltDeep,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.ink : Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
