import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/mascot_sticker.dart';
import '../../widgets/pressable.dart';
import '../home/widgets/home_top_icon_button.dart';
import '../../services/graduation_credit_service.dart';
import 'models/graduation_credit.dart';

/// 보조 텍스트(잉크 60%)와 도넛 트랙에 쓰는 연한 파랑. 홈 화면 흰 카드의
/// 보조 글자(ink 0.6)와 같은 규칙이다.
const Color _mutedText = Color(0x99121212);
const Color _donutTrack = Color(0xFFE3EBFF);

/// "N개 남음" 경고 빨강.
const Color _remainingRed = Color(0xFFE5484D);

/// 홈 화면 카드(next_class_card.dart 등)와 같은 남색 그림자.
final List<BoxShadow> _cardShadow = [
  BoxShadow(
    color: const Color(0xFF030A7F).withValues(alpha: 0.22),
    offset: const Offset(0, 10),
    blurRadius: 24,
  ),
];

/// "졸업학점" 화면.
///
/// 홈 화면과 같은 톤이다 — 화면 전체가 코발트 배경이고, 라임 배지 + 흰 큰
/// 제목 + 마스코트 스티커 아래에 흰 카드(남색 그림자), 잉크색 강조 카드가
/// 쌓인다. 숫자와 과목은 학교 "이수구분표"([GraduationCreditService])에서
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

    return Scaffold(
      backgroundColor: AppColors.cobalt,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: AppColors.cobalt,
              backgroundColor: Colors.white,
              onRefresh: () => _load(forceRefresh: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 32),
                children: summary == null || _isEmpty(summary)
                    ? [
                        const _Header(title: '졸업학점'),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                          child: _StatusCard(
                            loading: _loading,
                            message:
                                _error ??
                                (summary == null
                                    ? null
                                    : '이수구분표에 표시할 학점이 아직 없어요.'),
                            onRetry: () => _load(forceRefresh: true),
                          ),
                        ),
                      ]
                    : _content(summary),
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
    );
  }

  static bool _isEmpty(GraduationCreditSummary s) =>
      s.categories.isEmpty && s.totalEarned == null;

  List<Widget> _content(GraduationCreditSummary summary) {
    final categories = summary.categories;
    final totalRequired = summary.totalRequired;
    final totalEarned =
        summary.totalEarned ??
        categories.fold<int>(0, (sum, c) => sum + c.earned);
    final remaining = totalRequired == null
        ? null
        : math.max(0, totalRequired - totalEarned);
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
      _Header(
        title: remaining == null
            ? '졸업학점\n현황이에요'
            : remaining == 0
            ? '졸업학점을\n모두 채웠어요'
            : '졸업까지\n$remaining학점 남았어요',
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: _SummaryCard(
          totalRequired: totalRequired,
          totalEarned: totalEarned,
          gpa: summary.gpa,
          gpaMinimum: summary.gpaMinimum,
          categories: categories,
        ),
      ),
      const SizedBox(height: 12),
      // 칩 줄도 위 카드와 같은 좌우 20 폭 안에서만 보이게 하고, 그 선에서
      // 칩이 잘리게 한다(오른쪽 교양필수 칩이 화면 끝까지 번지지 않게).
      // 그림자가 위아래로는 잘리면 안 돼서 가로만 자른다.
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          height: 112,
          child: ClipRect(
            clipper: _HorizontalOnlyClipper(),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _CategoryChip(
                category: categories[index],
                onTap: _openDetail,
              ),
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Column(
          children: [
            if (areasWithRule.isNotEmpty) ...[
              _AreaProgressCard(title: '교양 영역별 이수현황', items: areasWithRule),
              const SizedBox(height: 12),
            ],
            _GraduationRuleNotice(rules: summary.rules),
            if (otherAreas.isNotEmpty) ...[
              const SizedBox(height: 12),
              _AreaProgressCard(title: '그 밖의 교양 영역', items: otherAreas),
            ],
          ],
        ),
      ),
    ];
  }
}

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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: _cardShadow,
      ),
      child: loading || message == null
          ? const Column(
              children: [
                CircularProgressIndicator(color: AppColors.cobalt),
                SizedBox(height: 16),
                Text(
                  '학교에서 이수구분표를 불러오고 있어요',
                  style: TextStyle(color: _mutedText, fontSize: 13),
                ),
              ],
            )
          : Column(
              children: [
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Pressable.effect(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.cobalt,
                    ),
                    onPressed: onRetry,
                    child: const Text('다시 시도'),
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

/// 홈 화면과 같은 헤더: 뒤로가기 원형 버튼, 라임 배지, 큰 흰 제목, 마스코트
/// 스티커. 코발트 배경 위에 바로 올라간다.
class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: HomeTopIconButton(
            icon: Icons.arrow_back_ios_new,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lime,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '졸업학점',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.only(right: 70),
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          height: 1.22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Positioned(
                right: -20,
                top: 10,
                child: MascotSticker(width: 100, angle: 0.1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 카테고리 칩/상세 카드에서 공통으로 쓰는 값 색 규칙 — 기준 학점이 아직
/// 0이면 회색, 아니면 잉크색.
Color _categoryValueColor(GraduationCreditCategory category) =>
    category.earned == 0 ? _mutedText : AppColors.ink;

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.totalRequired,
    required this.totalEarned,
    required this.gpa,
    required this.gpaMinimum,
    required this.categories,
  });

  /// 졸업학점 기준. 학교 표에 없으면 null(비율·기준을 숨긴다).
  final int? totalRequired;
  final int totalEarned;
  final double? gpa;
  final double? gpaMinimum;
  final List<GraduationCreditCategory> categories;

  GraduationCreditCategory? _find(String label) {
    for (final category in categories) {
      if (category.label == label) return category;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final totalRequired = this.totalRequired;
    final ratio = totalRequired == null || totalRequired == 0
        ? 0.0
        : totalEarned / totalRequired;
    // 학교 이수구분표에는 "주전공"·"복수전공" 이름이 없어(전필·전선·복전으로
    // 나옴) 지금은 두 배지가 숨는다. 해당 이름이 오면 다시 보인다.
    final major = _find('주전공');
    final doubleMajor = _find('복수전공');
    final gpa = this.gpa;
    final gpaMinimum = this.gpaMinimum;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: _cardShadow,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (major != null)
                _CreditBadge(category: major)
              else
                const SizedBox(width: 60),
              SizedBox(
                width: 128,
                height: 128,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(128, 128),
                      painter: _DonutPainter(ratio: ratio.clamp(0.0, 1.0)),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '총 이수학점',
                          style: TextStyle(color: _mutedText, fontSize: 11),
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '$totalEarned',
                                style: const TextStyle(
                                  color: AppColors.cobalt,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (totalRequired != null)
                                TextSpan(
                                  text: '/$totalRequired',
                                  style: const TextStyle(
                                    color: _mutedText,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (totalRequired != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.lime,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${(ratio * 100).round()}%',
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (doubleMajor != null)
                _CreditBadge(category: doubleMajor)
              else
                const SizedBox(width: 60),
            ],
          ),
          if (gpa != null) ...[
            const SizedBox(height: 16),
            CustomPaint(
              size: const Size(double.infinity, 1),
              painter: _DashedLinePainter(),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '졸업평점',
                  style: TextStyle(
                    color: _mutedText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  gpa.toStringAsFixed(2),
                  style: const TextStyle(
                    color: AppColors.cobalt,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (gpaMinimum != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    '/ ${gpaMinimum.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: _mutedText,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.lime,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      gpa >= gpaMinimum ? '충족' : '미충족',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 11,
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
/// 둥근 코발트색 호를 12시 방향부터 시계방향으로 그린다.
class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.ratio, this.strokeWidth = 11});

  final double ratio;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = _donutTrack
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (ratio <= 0) return;

    final progressPaint = Paint()
      ..color = AppColors.cobalt
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
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
      oldDelegate.ratio != ratio || oldDelegate.strokeWidth != strokeWidth;
}

/// 요약 카드의 도넛과 평점 줄 사이를 가르는 연한 점선.
class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _donutTrack
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

/// 도넛 좌/우에 놓이는 "주전공 27/60" / "복수전공 0/36" 작은 도넛 배지.
/// 기준 학점 대비 이수 비율만큼 링을 채운다(기준이 없으면 꽉 채움).
class _CreditBadge extends StatelessWidget {
  const _CreditBadge({required this.category});

  final GraduationCreditCategory category;

  @override
  Widget build(BuildContext context) {
    final required = category.required;
    final ratio = required == null
        ? 1.0
        : (required == 0 ? 0.0 : (category.earned / required).clamp(0.0, 1.0));
    final hasCredit = category.earned > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(60, 60),
                painter: _DonutPainter(ratio: ratio, strokeWidth: 6),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${category.earned}',
                    style: TextStyle(
                      color: hasCredit ? AppColors.cobalt : _mutedText,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const Text(
                    '학점',
                    style: TextStyle(color: _mutedText, fontSize: 9),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          category.label,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// 가로 스크롤 줄의 카테고리 칩 하나. 누르면 그 영역에서 들은 과목 상세
/// 목록을 화면 위에 오버레이 카드로 보여준다(과목이 없으면 — 예: 복수전공
/// 0과목 — 열지 않는다). 주전공 칩만 홈의 "학과 등수" 카드처럼 잉크색
/// 바탕 + 라임 숫자로 강조한다(코발트 배경 위라 코발트로는 안 보인다).
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category, required this.onTap});

  final GraduationCreditCategory category;
  final ValueChanged<GraduationCreditCategory> onTap;

  @override
  Widget build(BuildContext context) {
    final isMajor = category.label == '주전공';
    final valueColor = isMajor ? AppColors.lime : _categoryValueColor(category);
    final subColor = isMajor ? Colors.white.withValues(alpha: 0.7) : _mutedText;

    return Pressable(
      onTap: () => onTap(category),
      enabled: category.courses.isNotEmpty,
      child: Container(
        decoration: BoxDecoration(
          color: isMajor ? AppColors.ink : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: _cardShadow,
        ),
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category.label,
                style: TextStyle(
                  color: isMajor ? Colors.white : _mutedText,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${category.earned}',
                      style: TextStyle(
                        color: valueColor,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (category.required != null)
                      TextSpan(
                        text: '/${category.required}',
                        style: TextStyle(
                          color: subColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '${category.courseCount}과목',
                style: TextStyle(color: subColor, fontSize: 11),
              ),
            ],
          ),
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
        borderRadius: BorderRadius.circular(24),
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
                  color: AppColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: _mutedText,
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
                              color: AppColors.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${course.semester} · ${course.credit}학점',
                            style: const TextStyle(
                              color: _mutedText,
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
                            ? _mutedText
                            : AppColors.cobalt,
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
/// 채우면 코발트 칸 + "완료", 모자라면 연회색 칸 + 빨간 "N개 남음"을 보여준다.
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
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
                  if (i > 0) const SizedBox(width: 8),
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
            color: _mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: required == null
                ? _donutTrack
                : done
                ? AppColors.cobalt
                : AppColors.blushPink,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            required == null ? '${area.earned}' : '${area.earned}/$required',
            style: TextStyle(
              color: done ? Colors.white : AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
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
          style: TextStyle(
            color: required == null
                ? _mutedText
                : done
                ? AppColors.cobalt
                : _remainingRed,
            fontSize: 11,
            fontWeight: FontWeight.w700,
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (rules.isNotEmpty) ...[
            Text(
              rules.join('\n'),
              style: const TextStyle(
                color: _mutedText,
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
              color: _mutedText,
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
