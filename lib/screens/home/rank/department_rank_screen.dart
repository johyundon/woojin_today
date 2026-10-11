import 'package:flutter/material.dart';

import 'department_picker_screen.dart';
import 'models/department_rank.dart';
import 'rank_colors.dart';
import 'services/fake_department_rank_service.dart';
import 'widgets/rank_banner.dart';
import 'widgets/rank_distribution_row.dart';
import 'widgets/rank_stat_card.dart';

/// "학과등수" 결과 화면 (Figma node 6:67 / 6:69 — 학과가 다르면 숫자만
/// 달라지는 같은 레이아웃).
///
/// 학과 전체 성적 분포를 조회하는 실제 API가 없어, [FakeDepartmentRankService]가
/// 돌려주는 목업 데이터로만 채워진다.
class DepartmentRankScreen extends StatefulWidget {
  const DepartmentRankScreen({
    required this.isDark,
    this.initialDepartmentName = '컴퓨터공학전공',
    this.service,
    super.key,
  });

  final bool isDark;
  final String initialDepartmentName;
  final FakeDepartmentRankService? service;

  @override
  State<DepartmentRankScreen> createState() => _DepartmentRankScreenState();
}

class _DepartmentRankScreenState extends State<DepartmentRankScreen> {
  late final FakeDepartmentRankService _service =
      widget.service ?? FakeDepartmentRankService();

  late String _departmentName = widget.initialDepartmentName;
  DepartmentRank? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _service.fetchDepartmentRank(
      departmentName: _departmentName,
    );
    if (!mounted) return;
    setState(() => _data = data);
  }

  Future<void> _changeDepartment() async {
    final selected = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => DepartmentPickerScreen(
          isDark: widget.isDark,
          departmentNames: FakeDepartmentRankService.departmentNames,
        ),
      ),
    );
    if (selected == null || selected == _departmentName) return;
    setState(() {
      _departmentName = selected;
      _data = null;
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final colors = RankColors(widget.isDark);
    final data = _data;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: data == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                    icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '나는 학과에서\n몇등일까요?',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data.departmentName,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _ChangeDepartmentButton(
                        colors: colors,
                        onTap: _changeDepartment,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: RankStatCard(
                          colors: colors,
                          label: '내 성적',
                          gpa: data.myGpa,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RankStatCard(
                          colors: colors,
                          label: '${data.departmentName} 평균',
                          gpa: data.departmentAverageGpa,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  RankBanner(
                    colors: colors,
                    totalCount: data.totalCount,
                    myRank: data.myRank,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '${data.departmentName}(${data.grade}학년) 성적 분포',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final entry in data.distribution)
                    RankDistributionRow(
                      colors: colors,
                      entry: entry,
                      myGpa: data.myGpa,
                      maxGpa: data.distribution.first.gpa,
                    ),
                ],
              ),
      ),
    );
  }
}

class _ChangeDepartmentButton extends StatelessWidget {
  const _ChangeDepartmentButton({required this.colors, required this.onTap});

  final RankColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: colors.border),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      child: Text(
        '학과 변경',
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
