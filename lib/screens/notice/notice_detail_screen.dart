import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'models/notice_item.dart';

/// 공지 상세 화면 — 제목 + 작성일/작성자/조회수 + 본문 + (있으면) 첨부파일.
///
/// Figma 스크린샷에 보인 첨부파일 "미리보기"는 SYNAP이라는 외부 PDF 뷰어
/// SDK를 쓰고 있었다 — 실제 PDF 파일도 없고 그 SDK를 연동하는 건 이 화면의
/// 범위를 크게 벗어나서, 탭하면 "미리보기는 지원하지 않아요"라는 스낵바만
/// 보여주는 것으로 범위를 줄였다.
class NoticeDetailScreen extends StatelessWidget {
  const NoticeDetailScreen({super.key, required this.notice});

  final NoticeItem notice;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
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
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notice.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildLabelRow('작성일', notice.date),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildLabelRow('작성자', notice.author),
                          const SizedBox(width: 16),
                          _buildLabelRow('조회수', '${notice.viewCount}'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: AppColors.border, height: 1),
                      const SizedBox(height: 20),
                      Text(
                        notice.body ?? '',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                      if (notice.attachmentFileName != null) ...[
                        const SizedBox(height: 24),
                        const Divider(color: AppColors.border, height: 1),
                        const SizedBox(height: 16),
                        const Text(
                          '첨부파일',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildAttachmentRow(
                          context,
                          notice.attachmentFileName!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelRow(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentRow(BuildContext context, String fileName) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.disabledButton,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.description_outlined,
            color: AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              fileName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: () => ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('미리보기는 지원하지 않아요'))),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: const StadiumBorder(),
            ),
            child: const Text(
              '미리보기',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
