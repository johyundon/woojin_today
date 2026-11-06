import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../widgets/mascot_sticker.dart';
import '../../widgets/pressable.dart';
import '../../services/graduation_credit_service.dart';
import 'models/graduation_credit.dart';

// v7 디자인(46 graduation)에만 있는 색. 나머지는 AppColors의 v7 값을 쓴다.
/// 회색 배지 바탕 rgb(238, 240, 243)과 글자색 rgb(63, 69, 88).
const Color _badgeBackground = Color(0xFFEEF0F3);
const Color _badgeText = Color(0xFF3F4558);

/// 도넛과 졸업평점 줄 사이 점선 rgb(221, 224, 228).
const Color _dashedLine = Color(0xFFDDE0E4);

/// 아래 시트 위쪽 그림자(검정 6%, 위로 4, 번짐 20).
const List<BoxShadow> _sheetShadow = [
  BoxShadow(color: Color(0x0F000000), offset: Offset(0, -4), blurRadius: 20),
];

/// "졸업학점" 화면.
///
/// v7 디자인 — 거의 흰 바탕 위에 회색 배지 + 큰 제목 + 마스코트, 그 아래
/// 연회색 시트 안에 흰 카드(옅은 그림자)가 쌓인다. 숫자와 과목은 학교 "이수구분표"([GraduationCreditService])에서
/// 읽은 실제 값이고, 응답에 없는 칸은 숨긴다.
class GraduationCreditScreen extends StatefulWidget {
  const GraduationCreditScreen({super.key, this.userId2, this.service});

  /// 포털 로그인으로 얻은 본인 SSO uid. 없으면 조회하지 않고 안내만 보여준다.
  final String? userId2;

  /// 테스트에서 가짜 서비스를 넣을 때 쓴다. 없으면 실제 서비스.
  final GraduationCreditServiceBase? service;

  @override
  State<GraduationCreditScreen> createState() => _GraduationCreditScreenState();
}

class _GraduationCreditScreenState extends State<GraduationCreditScreen> {
  // 칩을 누르면 바텀시트가 아니라, 화면 전체를 어둡게 깔고 그 위에 상세
  // 카드가 화면 가운데에 뜨는 형태다.
  GraduationCreditCategory? _selected;

  late final GraduationCreditServiceBase _service =
      widget.service ?? GraduationCreditService();
  GraduationCreditSummary? _summary;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// [forceRefresh]가 false면 7일 안에 저장해 둔 값을 쓴다. 이미 화면에 값이
  /// 있을 때 새로고침이 실패하면 값은 그대로 두고 알림만 띄운다.
  Future<void> _load({bool forceRefresh = false}) async {
    final userId2 = widget.userId2;
    if (userId2 == null || userId2.isEmpty) {
      setState(() => _error = '로그인 정보가 없어 졸업학점을 불러올 수 없어요.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await _service.fetchSummary(
        userId2: userId2,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _loading = false;
      });
    } on GraduationCreditException catch (e) {
      if (!mounted) return;
      final message = switch (e) {
        GraduationCreditNetworkException() => '인터넷 연결을 확인해주세요.',
        GraduationCreditServerException() => '학교 서버가 응답하지 않아요. 잠시 후 다시 시도해주세요.',
        GraduationCreditParseException() => '학교 이수구분표를 읽지 못했어요.',
      };
      setState(() {
        _loading = false;
        if (_summary == null) _error = message;
      });
      if (_summary != null) {
        ScaffoldMessenger.maybeOf(context)
            ?.showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  void _openDetail(GraduationCreditCategory category) {
    if (category.courses.isEmpty) return;
    setState(() => _selected = category);
  }

  void _closeDetail() => setState(() => _selected = null);

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    final selected = _selected;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    // 밝은 바탕이라 상태 표시줄 글자를 어둡게 한다.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: RefreshIndicator(
                color: AppColors.blue,
                backgroundColor: Colors.white,
                onRefresh: () => _load(forceRefresh: true),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _Header(title: _title(summary))),
                    // 연회색 시트는 내용이 짧아도 화면 아래 끝까지 깔린다.
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Container(
                        margin: const EdgeInsets.only(top: 18),
                        padding: EdgeInsets.fromLTRB(
                          18,
                          20,
                          18,
                          32 + bottomInset,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.fill,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(36),
                          ),
                          boxShadow: _sheetShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: summary == null || _isEmpty(summary)
                              ? [
                                  _StatusCard(
                                    loading: _loading,
                                    message:
                                        _error ??
                                        (summary == null
                                            ? null
                                            : '이수구분표에 표시할 학점이 아직 없어요.'),
                                    onRetry: () => _load(forceRefresh: true),
                                  ),
                                ]
                              : _content(summary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (selected != null) ...[
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _closeDetail,
                  child: Container(color: Colors.black.withValues(alpha: 0.6)),
                ),
              ),
              Positioned.fill(
                child: SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _CourseDetailCard(category: selected),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 남은 학점을 알면 "졸업까지 N학점 남았어요", 모르면 "졸업학점".
  static String _title(GraduationCreditSummary? summary) {
    if (summary == null || _isEmpty(summary)) return '졸업학점';
    final totalRequired = summary.totalRequired;
    if (totalRequired == null) return '졸업학점\n현황이에요';
    final remaining = math.max(0, totalRequired - _totalEarned(summary));
    return remaining == 0 ? '졸업학점을\n모두 채웠어요' : '졸업까지\n$remaining학점 남았어요';
  }

  static int _totalEarned(GraduationCreditSummary summary) =>
      summary.totalEarned ??
      summary.categories.fold<int>(0, (sum, c) => sum + c.earned);

  static bool _isEmpty(GraduationCreditSummary s) =>
      s.categories.isEmpty && s.totalEarned == null;

  List<Widget> _content(GraduationCreditSummary summary) {
    final categories = summary.categories;
    // 기준이 있는 영역과 기준 칸이 빈 영역을 나눠 각각 카드로 보여준다.
    final areasWithRule = [
      for (final a in summary.areas)
        if (a.required != null) a,
    ];
    final otherAreas = [
      for (final a in summary.areas)
        if (a.required == null) a,
    ];

    return [
      _SummaryCard(
        totalRequired: summary.totalRequired,
        totalEarned: _totalEarned(summary),
        gpa: summary.gpa,
        gpaMinimum: summary.gpaMinimum,
      ),
      const SizedBox(height: 12),
      // 칩 줄은 시트 좌우 여백 안에서만 보이게 하고, 그 선에서 칩이 잘리게
      // 한다. 그림자가 위아래로는 잘리면 안 돼서 가로만 자른다.
      SizedBox(
        height: 108,
        child: ClipRect(
          clipper: _HorizontalOnlyClipper(),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) =>
                _CategoryChip(category: categories[index], onTap: _openDetail),
          ),
        ),
      ),
      const SizedBox(height: 12),
      if (areasWithRule.isNotEmpty) ...[
        _AreaProgressCard(title: '교양 영역별 이수현황', items: areasWithRule),
        const SizedBox(height: 12),
      ],
      _GraduationRuleNotice(rules: summary.rules),
      if (otherAreas.isNotEmpty) ...[
        const SizedBox(height: 12),
        _AreaProgressCard(title: '그 밖의 교양 영역', items: otherAreas),
      ],
    ];
  }
}

/// 흰 카드 공통 모양(v7: 둥글기 16, 옅은 그림자).
BoxDecoration _cardDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  boxShadow: AppColors.cardShadow,
);

/// 불러오는 중 / 실패(다시 시도) / 표시할 값 없음을 보여주는 흰 카드.
class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.loading,
    required this.message,
    required this.onRetry,
  });

  final bool loading;
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: _cardDecoration(),
      child: loading || message == null
          ? const Column(
              children: [
                CircularProgressIndicator(color: AppColors.blue),
                SizedBox(height: 16),
                Text(
                  '학교에서 이수구분표를 불러오고 있어요',
                  style: TextStyle(color: AppColors.textSub, fontSize: 13),
                ),
              ],
            )
          : Column(
              children: [
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textStrong,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Pressable.effect(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onRetry,
                    child: const Text(
                      '다시 시도',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// 좌우만 자르고 위아래는 넉넉히 열어 두는 클리퍼 — 칩 그림자가 잘리지 않게.
class _HorizontalOnlyClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, -48, size.width, size.height + 48);

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}

/// 헤더: 흰 네모 뒤로가기 버튼, 회색 "졸업학점" 배지, 큰 제목, 오른쪽 위
/// 마스코트 스티커.
class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned(
          right: 9,
          top: 25,
          child: IgnorePointer(child: MascotSticker(width: 97, angle: 0.14)),
        ),
        Column(
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppColors.cardShadow,
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
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: _badgeBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '졸업학점',
                      style: TextStyle(
                        color: _badgeText,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    // 오른쪽 마스코트와 겹치지 않게 비워 둔다.
                    padding: const EdgeInsets.only(right: 80),
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textStrong,
                        fontSize: 26,
                        height: 1.4,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.04,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 상세 카드에서 쓰는 값 색 규칙 — 이수 학점이 0이면 회색, 아니면 진한 남색.
Color _categoryValueColor(GraduationCreditCategory category) =>
    category.earned == 0 ? AppColors.textMuted : AppColors.inkNavy;

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.totalRequired,
    required this.totalEarned,
    required this.gpa,
    required this.gpaMinimum,
  });

  /// 졸업학점 기준. 학교 표에 없으면 null(비율·기준을 숨긴다).
  final int? totalRequired;
  final int totalEarned;
  final double? gpa;
  final double? gpaMinimum;

  @override
  Widget build(BuildContext context) {
    final totalRequired = this.totalRequired;
    final ratio = totalRequired == null || totalRequired == 0
        ? 0.0
        : totalEarned / totalRequired;
    final gpa = this.gpa;
    final gpaMinimum = this.gpaMinimum;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          SizedBox(
            width: 176,
            height: 176,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(176, 176),
                  painter: _DonutPainter(ratio: ratio.clamp(0.0, 1.0)),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '총 이수학점',
                      style: TextStyle(
                        color: AppColors.textSub,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '$totalEarned',
                            style: const TextStyle(
                              color: AppColors.blue,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.5,
                            ),
                          ),
                          if (totalRequired != null)
                            TextSpan(
                              text: '/$totalRequired',
                              style: const TextStyle(
                                color: AppColors.textSub,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (totalRequired != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.blueSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(ratio * 100).round()}%',
                          style: const TextStyle(
                            color: AppColors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (gpa != null) ...[
            const SizedBox(height: 14),
            CustomPaint(
              size: const Size(double.infinity, 1),
              painter: _DashedLinePainter(),
            ),
            const SizedBox(height: 11),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                const Text(
                  '졸업평점',
                  style: TextStyle(
                    color: AppColors.textBody,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  gpa.toStringAsFixed(2),
                  style: const TextStyle(
                    color: AppColors.blue,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.51,
                  ),
                ),
                if (gpaMinimum != null) ...[
                  Text(
                    '/ ${gpaMinimum.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.textSub,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _badgeBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      gpa >= gpaMinimum ? '충족' : '미충족',
                      style: const TextStyle(
                        color: AppColors.inkNavy,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// 도넛 링(총 이수학점 진행률)을 그리는 페인터. 연한 파랑 트랙 위에 끝이
/// 둥근 파란 호를 12시 방향부터 시계방향으로 그린다.
class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.ratio});

  final double ratio;
  static const double _strokeWidth = 11;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - _strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = AppColors.blueSoft
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (ratio <= 0) return;

    final progressPaint = Paint()
      ..color = AppColors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * ratio,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.ratio != ratio;
}

/// 요약 카드의 도넛과 평점 줄 사이를 가르는 연한 점선.
class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _dashedLine
      ..strokeWidth = 1;
    const dash = 4.0;
    const gap = 3.0;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(math.min(x + dash, size.width), 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => false;
}

/// 가로 스크롤 줄의 이수구분 칩 하나("전선 48/30 · 9과목"). 누르면 그
/// 구분에서 들은 과목 목록을 화면 위에 오버레이 카드로 보여준다(과목이
/// 없으면 — 예: 복수전공 0과목 — 열지 않는다).
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category, required this.onTap});

  final GraduationCreditCategory category;
  final ValueChanged<GraduationCreditCategory> onTap;

  @override
  Widget build(BuildContext context) {
    final faded = AppColors.textStrong.withValues(alpha: 0.65);

    return Pressable(
      onTap: () => onTap(category),
      enabled: category.courses.isNotEmpty,
      child: Container(
        width: 111,
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              category.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textStrong.withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${category.earned}',
                      style: const TextStyle(
                        color: AppColors.inkNavy,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.88,
                      ),
                    ),
                    if (category.required != null) ...[
                      const WidgetSpan(child: SizedBox(width: 2)),
                      TextSpan(
                        text: '/${category.required}',
                        style: TextStyle(
                          color: faded,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Text(
              '${category.courseCount}과목',
              style: TextStyle(
                color: faded,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 칩을 누르면 뜨는 상세 카드 — 바텀시트가 아니라 화면 가운데에 떠 있는
/// 오버레이 카드다. 과목 행 사이엔 구분선 없이 여백만 둔다.
class _CourseDetailCard extends StatelessWidget {
  const _CourseDetailCard({required this.category});

  final GraduationCreditCategory category;

  @override
  Widget build(BuildContext context) {
    final restText = category.required == null
        ? '학점'
        : '/${category.required}학점';
    final valueColor = _categoryValueColor(category);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.6;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                category.label,
                style: const TextStyle(
                  color: AppColors.textStrong,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: AppColors.textSub,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  children: [
                    TextSpan(
                      text: '${category.earned}',
                      style: TextStyle(color: valueColor),
                    ),
                    TextSpan(text: '$restText · ${category.courseCount}과목'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: category.courses.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final course = category.courses[index];
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textStrong,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${course.semester} · ${course.credit}학점',
                            style: const TextStyle(
                              color: AppColors.textSub,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 이번 학기 수강 중인 과목은 성적 칸이 비어 있다.
                    Text(
                      course.grade.isEmpty ? '수강중' : course.grade,
                      style: TextStyle(
                        color: course.grade.isEmpty
                            ? AppColors.textMuted
                            : AppColors.blue,
                        fontSize: course.grade.isEmpty ? 12 : 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// "영역별 이수현황" / 하단 세부영역 줄 — 항목마다 둥근 칸 하나씩, 기준을
/// 채우면 회색 글자 + "완료", 모자라면 진한 글자 + 파란 "N 남음"을 보여준다.
/// 칸은 카드 폭을 균등하게 나눠 쓴다.
class _AreaProgressCard extends StatelessWidget {
  const _AreaProgressCard({this.title, required this.items});

  final String? title;
  final List<GraduationAreaProgress> items;

  static List<List<GraduationAreaProgress>> _rows(
    List<GraduationAreaProgress> items,
  ) {
    if (items.isEmpty) return [];
    final rowCount = (items.length / 5).ceil();
    final perRow = (items.length / rowCount).ceil();
    return [
      for (var i = 0; i < items.length; i += perRow)
        items.sublist(i, math.min(i + perRow, items.length)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                title!,
                style: const TextStyle(
                  color: AppColors.textStrong,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          // 한 줄에 5칸까지. 넘치면 줄 수를 늘리고 칸을 줄마다 고르게 나눈다.
          for (final (index, row) in _rows(items).indexed) ...[
            if (index > 0) const SizedBox(height: 12),
            Row(
              children: [
                for (var i = 0; i < row.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(child: _AreaTile(area: row[i])),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AreaTile extends StatelessWidget {
  const _AreaTile({required this.area});

  final GraduationAreaProgress area;

  @override
  Widget build(BuildContext context) {
    // 학교 표의 영역 이름은 "1"~"9", "A"처럼 짧아서 숫자만 "N영역"으로 늘린다.
    final label = RegExp(r'^\d+$').hasMatch(area.label)
        ? '${area.label}영역'
        : area.label;
    final required = area.required;
    final remaining = required == null ? 0 : required - area.earned;
    final done = required != null && remaining <= 0;

    return Column(
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textSub,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.fill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              required == null ? '${area.earned}' : '${area.earned}/$required',
              style: TextStyle(
                color: done ? AppColors.textMuted : AppColors.textStrong,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.45,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          required == null
              ? '학점'
              : done
              ? '완료'
              : '$remaining 남음',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: required == null || done
                ? AppColors.textMuted
                : AppColors.blue,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

/// 학교 이수구분표 아래의 안내문(① ② ③ …)을 그대로 보여주고, 숫자가 어디서
/// 왔는지 짧게 덧붙인다.
class _GraduationRuleNotice extends StatelessWidget {
  const _GraduationRuleNotice({required this.rules});

  final List<String> rules;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (rules.isNotEmpty) ...[
            Text(
              rules.join('\n'),
              style: const TextStyle(
                color: AppColors.textSub,
                fontSize: 12,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 10),
          ],
          const Text(
            '학교 이수구분표 기준이며, 취득 학점에는 이번 학기 수강 중인 과목도 '
            '들어 있어요. 정확한 사정 결과는 학사정보시스템에서 확인해주세요.',
            style: TextStyle(
              color: AppColors.textSub,
              fontSize: 12,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
