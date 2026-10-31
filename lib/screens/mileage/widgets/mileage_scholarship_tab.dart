import 'package:flutter/material.dart';

import '../../../services/mileage_service.dart';
import '../../../theme/app_colors.dart';
import '../../notice/models/notice_item.dart';
import '../models/mileage_models.dart';
import 'mileage_notice_card.dart';
import 'mileage_target_confirm_dialog.dart';

/// "장학 대상자 확인" 화면 본문 — 학교 홈페이지의 마일리지장학 "대상자" 공지
/// 최신 5개. 각 공지의 "대상자 확인"을 누르면 첨부 명단에서 내 학번을 찾는다.
class MileageScholarshipTab extends StatefulWidget {
  const MileageScholarshipTab({
    required this.service,
    required this.studentId,
    super.key,
  });

  final MileageServiceBase service;

  /// 명단에서 찾을 내 학번.
  final String studentId;

  @override
  State<MileageScholarshipTab> createState() => _MileageScholarshipTabState();
}

class _MileageScholarshipTabState extends State<MileageScholarshipTab> {
  late Future<List<NoticeItem>> _notices = widget.service.fetchTargetNotices();

  Future<void> _refresh() async {
    final next = widget.service.fetchTargetNotices(forceRefresh: true);
    setState(() => _notices = next);
    try {
      await next;
    } catch (_) {
      // 오류는 FutureBuilder가 보여준다.
    }
  }

  void _check(NoticeItem notice) {
    showMileageTargetResultDialog(
      context,
      title: notice.title,
      result: widget.service.checkTarget(
        detailPath: notice.detailPath!,
        studentId: widget.studentId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<NoticeItem>>(
        future: _notices,
        builder: (context, snapshot) {
          final Widget child;
          if (snapshot.connectionState != ConnectionState.done) {
            child = const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            child = _CenteredText('공지를 불러오지 못했어요.\n당겨서 다시 시도해 주세요.');
          } else if (snapshot.data!.isEmpty) {
            child = _CenteredText('대상자 공지가 아직 없어요.');
          } else {
            final notices = snapshot.data!;
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: notices.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final n = notices[index];
                return MileageNoticeCard(
                  notice: MileageNotice(
                    title: n.title,
                    author: n.author,
                    date: n.date,
                    viewCount: n.viewCount,
                  ),
                  onCheck: () => _check(n),
                );
              },
            );
          }
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [child],
          );
        },
      ),
    );
  }
}

class _CenteredText extends StatelessWidget {
  const _CenteredText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
    );
  }
}
