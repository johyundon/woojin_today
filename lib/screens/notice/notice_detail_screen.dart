import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/file_transfer.dart' show sanitizeFileName;
import '../../services/notice_service.dart';
import '../../services/service_factory.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pressable.dart';
import '../../widgets/top_banner.dart';
import 'models/notice_item.dart';

/// v7 시안의 본문 글자색과 구분선 색.
const _bodyText = Color(0xFF35343F);
const _divider = Color(0xFFEAECEF);

/// 공지 상세 화면(v7) — 흰 바탕에 회색 네모 뒤로가기, "학사 공지" 배지(필독이면
/// "필독" 배지도), 제목, 작성일·작성 부서·조회수 한 줄, 구분선, 본문, (있으면)
/// 첨부파일 카드.
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
      _showError(e.isNetwork ? '네트워크 연결을 확인해 주세요.' : '첨부파일을 받지 못했어요.');
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
    // 흰 바탕이라 상태 표시줄 글자를 어둡게 한다.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: 24 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
                  child: Pressable.icon(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.fill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textStrong,
                        size: 15,
                        semanticLabel: '뒤로',
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (notice.isRequired)
                            const _Badge(
                              label: '필독',
                              background: AppColors.blue,
                              foreground: Colors.white,
                            ),
                          _Badge(
                            label: '${notice.tag.label} 공지',
                            background: AppColors.blueSoft,
                            foreground: AppColors.blue,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        notice.title,
                        style: const TextStyle(
                          color: AppColors.textStrong,
                          fontSize: 22,
                          height: 1.4,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.88,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 14,
                        runSpacing: 6,
                        children: [
                          _MetaItem(
                            icon: Icons.calendar_today_rounded,
                            text: detail?.date ?? notice.date,
                          ),
                          _MetaItem(
                            icon: Icons.apartment_rounded,
                            text: detail?.author ?? notice.author,
                          ),
                          _MetaItem(
                            icon: Icons.visibility_rounded,
                            text: _withCommas(
                              detail?.viewCount ?? notice.viewCount,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 17),
                      const Divider(height: 1, thickness: 1, color: _divider),
                      const SizedBox(height: 16),
                      ..._content(detail),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 1284 → "1,284".
  static String _withCommas(int n) => n.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );

  /// 본문 + 첨부파일. 실제 공지는 받는 중/실패/성공을, 목업은 저장된 본문을 보여준다.
  List<Widget> _content(NoticeDetail? detail) {
    if (_loading) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.blue),
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
            color: AppColors.textStrong,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Pressable.effect(
          child: FilledButton(
            onPressed: _load,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '다시 시도',
              style: TextStyle(fontWeight: FontWeight.w700),
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
        style: const TextStyle(
          color: _bodyText,
          fontSize: 14,
          height: 1.4,
          letterSpacing: -0.14,
        ),
      ),
      for (final a in attachments) ...[
        const SizedBox(height: 12),
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
    ];
  }
}

/// 분류 배지("학사 공지", "필독").
class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          height: 1.4,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// 아이콘 + 글자 한 칸(작성일·작성 부서·조회수).
class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSub),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textSub,
            fontSize: 12,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// 첨부파일 한 건 — 파란 클립 네모, 파일 이름, 오른쪽 받기 아이콘. 카드 전체를
/// 누르면 받아서 연다(받는 중이면 아이콘 자리에 작은 원이 돈다).
class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({
    required this.fileName,
    required this.downloading,
    required this.onPreview,
  });

  final String fileName;

  /// 받는 중이면 아이콘을 도는 원으로 바꾸고 누르기를 막는다.
  final bool downloading;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: downloading ? null : onPreview,
      pressedScale: 0.98,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.blueSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.blue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.attach_file_rounded,
                color: Colors.white,
                size: 17,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                fileName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textStrong,
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 19,
              height: 19,
              child: downloading
                  ? const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.blue,
                    )
                  : const Icon(
                      Icons.download_rounded,
                      color: AppColors.blue,
                      size: 19,
                      semanticLabel: '미리보기',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
