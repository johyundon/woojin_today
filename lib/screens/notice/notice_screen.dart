import 'package:flutter/material.dart';

import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import 'models/notice_item.dart';
import 'services/notice_mock_data.dart';
import 'widgets/notice_list_card.dart';

/// "공지사항" 화면 (Figma node 6:47 학사공지 / 6:50 종합강의시간표 / 6:54
/// 마일리지, 전부 스크린샷 평탄화 상태 — calendar_screen.dart 등과 같은
/// 선례를 따라 눈으로 보고 근사 구현했다).
///
/// 학사공지/종합강의시간표/마일리지 세 카테고리 모두 공지사항 API가
/// 명세서에 없어 [NoticeMockData]의 목데이터로만 동작한다.
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

  NoticeCategory _category = NoticeCategory.academic;
  bool _notifyEnabled = true;

  @override
  Widget build(BuildContext context) {
    final notices = NoticeMockData.noticesFor(_category);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 20, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  const Text(
                    '새 글 알림 받기',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  Switch(
                    value: _notifyEnabled,
                    activeTrackColor: AppColors.accent,
                    onChanged: _onNotifyToggled,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildCategoryTabs(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: notices.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) =>
                    NoticeListCard(notice: notices[index]),
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

    for (final category in NoticeCategory.values) {
      for (final notice in NoticeMockData.noticesFor(category)) {
        if (!notice.isNew) continue;
        await _notifications.showNoticeAlert(
          id: '${category.name}-${notice.title}',
          title: '새 공지가 올라왔어요',
          body: notice.title,
        );
      }
    }
  }

  Widget _buildCategoryTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          for (final category in NoticeCategory.values)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _category = category),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: category == _category
                        ? AppColors.accent
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    category.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: category == _category
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
