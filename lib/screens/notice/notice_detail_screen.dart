import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/file_transfer.dart' show sanitizeFileName;
import '../../services/notice_service.dart';
import '../../services/service_factory.dart';
import '../../theme/app_colors.dart';
import '../../widgets/mascot_sticker.dart';
import '../../widgets/pressable.dart';
import '../../widgets/top_banner.dart';
import 'models/notice_item.dart';
import 'widgets/notice_tag_chips.dart';

const _mutedText = Color(0xFF6B6B70);

/// 공지 상세 화면(v4 스타일) — 코발트 헤더에 제목/발행처·날짜, 흰 패널에
/// 분류 칩 + 작성일/작성자/조회수 + 본문 + (있으면) 첨부파일.
///
/// 첨부파일 "미리보기"는 파일을 받아 앱 임시 폴더에 둔 뒤 휴대폰의 "공유하기"
/// 창으로 넘긴다([SharePlus]) — 아이폰은 그 창 위에 문서 미리보기와 "파일에
/// 저장"이, 안드로이드는 PDF·한글 보기 앱 목록이 뜬다. 학교 사이트의 미리보기
/// (SYNAP 외부 뷰어)는 연동하지 않았다. 주소가 없는 목업 첨부는 안내만 띄운다.
///
/// 실제 공지([NoticeItem.detailPath]가 있음)는 학교 홈페이지 상세 페이지에서 본문과
/// 첨부파일 이름을 받아 보여준다([NoticeService.fetchDetail]). 목업 공지는
/// [NoticeItem.body]를 그대로 쓴다.
class NoticeDetailScreen extends StatefulWidget {
  const NoticeDetailScreen({
    super.key,
    required this.notice,
    this.service,
    this.openFile,
  });

  final NoticeItem notice;

  /// 테스트용 주입 지점.
  final NoticeServiceBase? service;

  /// 받은 첨부파일을 여는 방법. 없으면 휴대폰 "공유하기" 창으로 넘긴다
  /// (테스트에서 바꿔 끼운다).
  final Future<void> Function(File file)? openFile;

  @override
  State<NoticeDetailScreen> createState() => _NoticeDetailScreenState();
}

class _NoticeDetailScreenState extends State<NoticeDetailScreen> {
  NoticeDetail? _detail;
  bool _loading = false;
  String? _error;

  NoticeItem get notice => widget.notice;

  late final NoticeServiceBase _service =
      widget.service ?? ServiceFactory.notice();

  /// 지금 받는 중인 첨부 주소(한 번에 하나만 받는다).
  String? _downloadingUrl;

  Future<void> _preview(NoticeAttachment attachment) async {
    if (_downloadingUrl != null) return;
    setState(() => _downloadingUrl = attachment.url);
    try {
      final bytes = await _service.downloadAttachment(attachment.url);
      final dir = Directory(
        '${Directory.systemTemp.path}${Platform.pathSeparator}notice_attachments',
      );
      await dir.create(recursive: true);
      final name = sanitizeFileName(attachment.name) ?? '첨부파일';
      final file = File('${dir.path}${Platform.pathSeparator}$name');
      await file.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      await (widget.openFile ?? _shareFile)(file);
    } on NoticeLoginRequiredException {
      _showError('로그인이 필요해요. 다시 로그인해 주세요.');
    } on NoticeException catch (e) {
      _showError(
        e.isNetwork ? '네트워크 연결을 확인해 주세요.' : '첨부파일을 받지 못했어요.',
      );
    } catch (e) {
      debugPrint('[NoticeDetail] 첨부 열기 실패: $e');
      _showError('첨부파일을 열지 못했어요.');
    } finally {
      if (mounted) setState(() => _downloadingUrl = null);
    }
  }

  static Future<void> _shareFile(File file) =>
      SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));

  void _showError(String message) {
    if (!mounted) return;
    showTopBanner(context, title: '미리보기 실패', message: message);
  }

  @override
  void initState() {
    super.initState();
    if (notice.detailPath != null) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await _service.fetchDetail(notice.detailPath!);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _detail = detail;
      });
    } on NoticeException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.isNetwork ? '네트워크 연결을 확인해 주세요.' : '공지 내용을 불러오지 못했어요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
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
                        Pressable.icon(
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
                              _MetaCell('작성일', detail?.date ?? notice.date),
                              _MetaCell('작성자', detail?.author ?? notice.author),
                              _MetaCell(
                                '조회수',
                                '${detail?.viewCount ?? notice.viewCount}',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        ..._content(detail),
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

  /// 본문 + 첨부파일. 실제 공지는 받는 중/실패/성공을, 목업은 저장된 본문을 보여준다.
  List<Widget> _content(NoticeDetail? detail) {
    if (_loading) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.cobalt),
          ),
        ),
      ];
    }
    final error = _error;
    if (error != null) {
      return [
        Text(
          error,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Pressable.effect(
          child: FilledButton(
            onPressed: _load,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.lime,
              foregroundColor: AppColors.ink,
              shape: const StadiumBorder(),
            ),
            child: const Text(
              '다시 시도',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ];
    }
    final body = detail?.body ?? notice.body ?? '';
    // 실제 공지는 주소가 있는 첨부, 목업 공지는 이름만 있는 첨부(url 빈 값).
    final attachments = detail != null
        ? detail.attachments
        : [
            if (notice.attachmentFileName case final name?)
              NoticeAttachment(name: name, url: ''),
          ];
    return [
      SelectableText(
        body,
        style: const TextStyle(color: AppColors.ink, fontSize: 14, height: 1.7),
      ),
      if (attachments.isNotEmpty) ...[
        const SizedBox(height: 24),
        const Text(
          '첨부파일',
          style: TextStyle(
            color: _mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        for (final a in attachments) ...[
          const SizedBox(height: 10),
          _AttachmentRow(
            fileName: a.name,
            downloading: _downloadingUrl == a.url,
            onPreview: a.url.isEmpty
                ? () => showTopBanner(
                    context,
                    title: '미리보기',
                    message: '이 첨부파일은 열 수 없어요.',
                  )
                : () => _preview(a),
          ),
        ],
      ],
    ];
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
  const _AttachmentRow({
    required this.fileName,
    required this.downloading,
    required this.onPreview,
  });

  final String fileName;

  /// 받는 중이면 버튼을 "받는 중"으로 바꾸고 막는다.
  final bool downloading;
  final VoidCallback onPreview;

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
          Pressable.effect(
            enabled: !downloading,
            child: ElevatedButton(
              onPressed: downloading ? null : onPreview,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cobalt,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.cobalt.withValues(
                  alpha: 0.5,
                ),
                disabledForegroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: const StadiumBorder(),
              ),
              child: Text(
                downloading ? '받는 중' : '미리보기',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
