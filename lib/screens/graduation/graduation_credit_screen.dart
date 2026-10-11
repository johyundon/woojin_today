import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'models/graduation_credit.dart';
import 'services/graduation_credit_mock_data.dart';

/// "주전공" 배지에 쓰는 포인트 블루 — 앱 전체에서 랭킹 카드(rank_card.dart)가
/// 쓰는 블루와 같은 톤이라 그걸 재사용한다.
const Color _majorBlue = Color(0xFF3D6CFF);

/// "졸업학점" 화면.
///
/// Figma(node 93:21)가 실기기 스크린샷을 그대로 붙여넣은 자료라 벡터
/// 레이어가 없다 — 색상·비율은 스크린샷을 픽셀 단위로 측정해 맞췄다.
/// 과목별 성적까지 보여주는 화면인데 그에 대응하는 서버 API가 없어서
/// ([GraduationCreditMockData] 참고) 과목명/학점/성적은 전부 가상으로 지어낸
/// 예시다.
class GraduationCreditScreen extends StatefulWidget {
  const GraduationCreditScreen({super.key});

  @override
  State<GraduationCreditScreen> createState() => _GraduationCreditScreenState();
}

class _GraduationCreditScreenState extends State<GraduationCreditScreen> {
  // 칩을 누르면 바텀시트가 아니라, 화면 전체를 어둡게 깔고 그 위에 상세
  // 카드가 같은 자리(총 이수학점 카드 아래)에 뜨는 형태다(Figma 93:32).
  GraduationCreditCategory? _selected;

  void _openDetail(GraduationCreditCategory category) {
    if (category.courses.isEmpty) return;
    setState(() => _selected = category);
  }

  void _closeDetail() => setState(() => _selected = null);

  @override
  Widget build(BuildContext context) {
    final categories = GraduationCreditMockData.categories;
    final totalRequired = GraduationCreditMockData.totalRequired;
    final totalEarned = GraduationCreditMockData.totalEarned;
    final selected = _selected;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 20, 4),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      _SummaryCard(
                        totalRequired: totalRequired,
                        totalEarned: totalEarned,
                        categories: categories,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 116,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 16),
                          itemBuilder: (context, index) => _CategoryChip(
                            category: categories[index],
                            onTap: _openDetail,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _DividerStatCard(
                        title: '영역별 이수현황',
                        items: GraduationCreditMockData.areas,
                      ),
                      const SizedBox(height: 20),
                      const _GraduationRuleNotice(),
                      const SizedBox(height: 20),
                      _DividerStatCard(
                        items: GraduationCreditMockData.detailAreas,
                        centered: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (selected != null) ...[
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _closeDetail,
                  child: Container(color: Colors.black.withValues(alpha: 0.6)),
                ),
              ),
              Positioned(
                top: 96,
                left: 20,
                right: 20,
                child: _CourseDetailCard(category: selected),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 카테고리 칩/상세 카드에서 공통으로 쓰는 값 색 규칙 — 주전공은 포인트
/// 블루, 기준 학점이 없으면 흰색, 기준을 채웠으면 주황, 아니면 흰색.
Color _categoryValueColor(GraduationCreditCategory category) {
  if (category.label == '주전공') return _majorBlue;
  if (category.required == null) return AppColors.textPrimary;
  return category.isDone ? AppColors.accent : AppColors.textPrimary;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.totalRequired,
    required this.totalEarned,
    required this.categories,
  });

  final int totalRequired;
  final int totalEarned;
  final List<GraduationCreditCategory> categories;

  GraduationCreditCategory? _find(String label) {
    for (final category in categories) {
      if (category.label == label) return category;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ratio = totalRequired == 0 ? 0.0 : totalEarned / totalRequired;
    final major = _find('주전공');
    final doubleMajor = _find('복수전공');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            '총 이수학점',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 170,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 170,
                  height: 170,
                  child: CustomPaint(
                    painter: _DonutPainter(ratio: ratio.clamp(0.0, 1.0)),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$totalEarned/$totalRequired',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      '학점',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (major != null)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _CreditBadge(
                        category: major,
                        numberColor: _majorBlue,
                      ),
                    ),
                  ),
                if (doubleMajor != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _CreditBadge(
                        category: doubleMajor,
                        numberColor: doubleMajor.earned > 0
                            ? AppColors.accent
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              children: [
                const TextSpan(text: '졸업평점 '),
                TextSpan(
                  text: GraduationCreditMockData.gpa.toStringAsFixed(2),
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text:
                      '/${GraduationCreditMockData.gpaMinimum.toStringAsFixed(2)}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 도넛 링(총 이수학점 진행률)을 그리는 페인터. 배경 트랙 위에 끝이 둥근
/// 주황색 호를 12시 방향부터 시계방향으로 그린다.
class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.ratio,
    this.strokeWidth = 18,
    this.color = AppColors.accent,
  });

  final double ratio;
  final double strokeWidth;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = AppColors.disabledButton
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (ratio <= 0) return;

    final progressPaint = Paint()
      ..color = color
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
      oldDelegate.ratio != ratio ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.color != color;
}

/// 도넛 링 좌/우에 얹히는 "주전공 54학점" / "복수전공 0/36학점" 원형 배지.
class _CreditBadge extends StatelessWidget {
  const _CreditBadge({required this.category, required this.numberColor});

  final GraduationCreditCategory category;
  final Color numberColor;

  @override
  Widget build(BuildContext context) {
    final valueText = category.required == null
        ? '${category.earned}'
        : '${category.earned}/${category.required}';
    // required가 없는(주전공) 배지는 비교할 기준이 없어 링을 꽉 채워
    // 보여주고, 있는 배지는 실제 달성 비율만큼만 채운다.
    final ratio = category.required == null
        ? 1.0
        : (category.required == 0
              ? 0.0
              : (category.earned / category.required!).clamp(0.0, 1.0));

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
                painter: _DonutPainter(
                  ratio: ratio,
                  strokeWidth: 6,
                  color: numberColor,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    valueText,
                    style: TextStyle(
                      color: numberColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    '학점',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                    ),
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
            color: AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// 가로 스크롤 줄의 카테고리 칩 하나. 누르면 그 영역에서 들은 과목 상세
/// 목록을 화면 위에 오버레이 카드로 보여준다(과목이 없으면 — 예: 복수전공
/// 0과목 — 열지 않는다).
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category, required this.onTap});

  final GraduationCreditCategory category;
  final ValueChanged<GraduationCreditCategory> onTap;

  @override
  Widget build(BuildContext context) {
    final valueText = category.required == null
        ? '${category.earned}학점'
        : '${category.earned}/${category.required}학점';
    final valueColor = _categoryValueColor(category);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: category.courses.isEmpty ? null : () => onTap(category),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              category.label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    valueText,
                    style: TextStyle(
                      color: valueColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              '${category.courseCount}과목',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 칩을 누르면 뜨는 상세 카드(Figma 93:32) — 바텀시트가 아니라 요약 카드
/// 바로 아래, 같은 자리에 떠 있는 오버레이 카드다. 과목 행 사이엔 구분선
/// 없이 여백만 둔다.
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
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
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: AppColors.textSecondary,
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
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${course.semester} · ${course.credit}학점',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      course.grade,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 14,
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

/// "영역별 이수현황" / 하단 세부영역 줄 — 카드 하나 안에 항목들을 얇은 세로
/// 구분선으로 나눠 가로로 쭉 늘어놓는다(Figma에 각 항목이 따로 둥근 박스가
/// 아니라 구분선으로만 나뉜 한 장짜리 카드로 되어 있었다). 폭이 넘치면 카드
/// 안에서만 가로 스크롤된다.
class _DividerStatCard extends StatelessWidget {
  const _DividerStatCard({
    this.title,
    required this.items,
    this.centered = false,
  });

  final String? title;
  final List<GraduationAreaProgress> items;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final row = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 36,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                color: AppColors.disabledButton,
              ),
            _StatColumn(area: items[i]),
          ],
        ],
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
          ],
          centered ? Center(child: row) : row,
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.area});

  final GraduationAreaProgress area;

  @override
  Widget build(BuildContext context) {
    final done = area.earned >= area.required;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          area.label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${area.earned}/${area.required}',
          style: TextStyle(
            color: done ? AppColors.accent : AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _GraduationRuleNotice extends StatelessWidget {
  const _GraduationRuleNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '① 학생의 졸업사정 적용 교육과정 기준년도와 영역별 세부 기준은 '
            '학번/학과에 따라 다릅니다.\n'
            '② 교양학점 이수: 교필과 교선에 대한 최대 인정학점이 있고, 이를 '
            '초과한 교양 취득학점은 졸업심사 시 불인정됩니다.\n'
            '③ 전공학점 이수: 주전공/복수전공 각각 기준학점 이상을 '
            '이수해야 합니다.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.6,
            ),
          ),
          SizedBox(height: 10),
          Text(
            '이 화면의 숫자와 과목은 전부 예시이며 실제 본인 요건이 '
            '아니에요. 정확한 사정 결과는 학사정보시스템에서 확인해주세요.',
            style: TextStyle(
              color: AppColors.textSecondary,
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
