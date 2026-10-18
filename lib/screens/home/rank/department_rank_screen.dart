import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import 'department_picker_screen.dart';
import 'models/department_rank.dart';
import 'services/fake_department_rank_service.dart';
import 'widgets/rank_hero_card.dart';
import 'widgets/rank_summary_cards.dart';
import 'widgets/subject_rank_card.dart';

/// "학과등수" 결과 화면("나 몇 등이야?" v4 리디자인 — 학과가 다르면 숫자만
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
          currentDepartment: _departmentName,
          departmentNames: FakeDepartmentRankService.departmentNames,
          colleges: FakeDepartmentRankService.departmentColleges,
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
    final data = _data;

    return Scaffold(
      backgroundColor: AppColors.cobalt,
      body: SafeArea(
        child: data == null
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
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
                  ),
                  const SizedBox(height: 14),
                  // 누르면 학과를 바꾼다(기존 "학과 변경" 버튼 자리).
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: _changeDepartment,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lime,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${data.semester}학기 · ${data.shortName} ${data.grade}학년',
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              size: 16,
                              color: AppColors.ink,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '나 몇 등이야?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.04,
                    ),
                  ),
                  const SizedBox(height: 18),
                  RankHeroCard(data: data),
                  const SizedBox(height: 12),
                  RankSummaryCards(data: data),
                  const SizedBox(height: 12),
                  SubjectRankCard(subjects: data.subjects),
                ],
              ),
      ),
    );
  }
}
