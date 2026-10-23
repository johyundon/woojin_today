import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'models/graduation_credit.dart';
import 'services/graduation_credit_mock_data.dart';

/// 파란 헤더 아래 깔리는 밝은 라벤더 배경(스크린샷 측정값).
const Color _panelBackground = Color(0xFFEDEDF8);

/// 보조 텍스트 회색과, 비활성 원/칸·도넛 트랙에 쓰는 연한 색.
const Color _mutedText = Color(0xFF8E8E9A);
const Color _softFill = Color(0xFFF0F0F8);
const Color _donutTrack = Color(0xFFE3EBFF);

/// "N개 남음" 경고 빨강.
const Color _remainingRed = Color(0xFFE5484D);

/// "졸업학점" 화면.
///
/// 파란 헤더("졸업까지 N학점 남았어요") 아래에 흰 카드들이 올라오는 디자인이다.
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
  // 카드가 화면 가운데에 뜨는 형태다.
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
    final remaining = math.max(0, totalRequired - totalEarned);
    final selected = _selected;

    return Scaffold(
      backgroundColor: AppColors.cobalt,
      body: Stack(
        children: [
          Column(
            children: [
              _Header(remaining: remaining),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  child: ColoredBox(
                    color: _panelBackground,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _SummaryCard(
                            totalRequired: totalRequired,
                            totalEarned: totalEarned,
                            categories: categories,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 104,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: categories.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) => _CategoryChip(
                              category: categories[index],
                              onTap: _openDetail,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              _AreaProgressCard(
                                title: '영역별 이수현황',
                                items: GraduationCreditMockData.areas,
                              ),
                              const SizedBox(height: 16),
                              const _GraduationRuleNotice(),
                              const SizedBox(height: 16),
                              _AreaProgressCard(
                                items: GraduationCreditMockData.detailAreas,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
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
}

/// 파란 헤더: 뒤로가기 원형 버튼, "졸업학점" 라임 배지, 남은 학점 문구, 마스코트.
class _Header extends StatelessWidget {
  const _Header({required this.remaining});

  final int remaining;

  @override
  Widget build(BuildContext context) {
    final title = remaining == 0 ? '졸업학점을\n모두 채웠어요' : '졸업까지\n$remaining학점 남았어요';

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: SizedBox(
          width: double.infinity,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    color: AppColors.cobaltDeep,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).pop(),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.lime,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      '졸업학점',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 4,
                top: 24,
                child: Image.asset(
                  'assets/images/graduation_mascot.png',
                  height: 96,
                ),
              ),
            ],
          ),
        ),
      ),
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
    final gpa = GraduationCreditMockData.gpa;
    final gpaMinimum = GraduationCreditMockData.gpaMinimum;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
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
          ),
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
/// 0과목 — 열지 않는다). 주전공 칩만 코발트로 채워 강조한다.
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category, required this.onTap});

  final GraduationCreditCategory category;
  final ValueChanged<GraduationCreditCategory> onTap;

  @override
  Widget build(BuildContext context) {
    final isMajor = category.label == '주전공';
    final valueColor = isMajor ? AppColors.lime : _categoryValueColor(category);
    final subColor = isMajor ? Colors.white.withValues(alpha: 0.7) : _mutedText;

    return Material(
      color: isMajor ? AppColors.cobalt : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: category.courses.isEmpty ? null : () => onTap(category),
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(14),
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
                        fontWeight: FontWeight.w800,
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
                    Text(
                      course.grade,
                      style: const TextStyle(
                        color: AppColors.cobalt,
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

/// "영역별 이수현황" / 하단 세부영역 줄 — 항목마다 둥근 칸 하나씩, 기준을
/// 채우면 코발트 칸 + "완료", 모자라면 연회색 칸 + 빨간 "N개 남음"을 보여준다.
/// 칸은 카드 폭을 균등하게 나눠 쓴다.
class _AreaProgressCard extends StatelessWidget {
  const _AreaProgressCard({this.title, required this.items});

  final String? title;
  final List<GraduationAreaProgress> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
          Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _AreaTile(area: items[i])),
              ],
            ],
          ),
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
    final remaining = area.required - area.earned;
    final done = remaining <= 0;

    return Column(
      children: [
        Text(
          area.label,
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
            color: done ? AppColors.cobalt : _softFill,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '${area.earned}/${area.required}',
            style: TextStyle(
              color: done ? Colors.white : AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          done ? '완료' : '$remaining개 남음',
          style: TextStyle(
            color: done ? AppColors.cobalt : _remainingRed,
            fontSize: 11,
            fontWeight: FontWeight.w700,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
            style: TextStyle(color: _mutedText, fontSize: 12, height: 1.6),
          ),
          SizedBox(height: 10),
          Text(
            '이 화면의 숫자와 과목은 전부 예시이며 실제 본인 요건이 '
            '아니에요. 정확한 사정 결과는 학사정보시스템에서 확인해주세요.',
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
