import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/mascot_sticker.dart';
import 'models/notice_item.dart';
import 'widgets/notice_tag_chips.dart';

const _mutedText = Color(0xFF6B6B70);

/// 공지 상세 화면(v4 스타일) — 코발트 헤더에 제목/발행처·날짜, 흰 패널에
/// 분류 칩 + 작성일/작성자/조회수 + 본문 + (있으면) 첨부파일.
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
      backgroundColor: AppColors.cobalt,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lime,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Text(
                            '공지사항',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.only(right: 90),
                          child: Text(
                            notice.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                              letterSpacing: -0.04,
                            ),
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
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                child: ColoredBox(
                  color: Colors.white,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      20,
                      20,
                      24 + MediaQuery.of(context).padding.bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        NoticeTagChips(notice: notice),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F1F5),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              _MetaCell('작성일', notice.date),
                              _MetaCell('작성자', notice.author),
                              _MetaCell('조회수', '${notice.viewCount}'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          notice.body ?? '',
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 14,
                            height: 1.7,
                          ),
                        ),
                        if (notice.attachmentFileName != null) ...[
                          const SizedBox(height: 24),
                          const Text(
                            '첨부파일',
                            style: TextStyle(
                              color: _mutedText,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _AttachmentRow(fileName: notice.attachmentFileName!),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaCell extends StatelessWidget {
  const _MetaCell(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: _mutedText, fontSize: 11)),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({required this.fileName});

  final String fileName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFDCE6FB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.description, color: AppColors.cobalt, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              fileName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () => ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('미리보기는 지원하지 않아요'))),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cobalt,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: const StadiumBorder(),
            ),
            child: const Text(
              '미리보기',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
