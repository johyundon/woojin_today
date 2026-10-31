import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/mascot_sticker.dart';

const _mutedText = Color(0xFF6B6B70);
const _fieldBackground = Color(0xFFF1F1F5);

/// "학과 변경" 화면(v4 리디자인). 학과를 고르고 "변경하기"를 누르면 한 번 더
/// 확인 시트를 띄우고, 확인하면 고른 학과 이름을 반환하며 닫힌다
/// ([Navigator.pop]). 취소하거나 뒤로 가면 null.
class DepartmentPickerScreen extends StatefulWidget {
  const DepartmentPickerScreen({
    required this.currentDepartment,
    required this.departmentNames,
    required this.colleges,
    super.key,
  });

  final String currentDepartment;
  final List<String> departmentNames;

  /// 학과 이름 → 단과대학. 없는 학과는 부제를 생략한다.
  final Map<String, String> colleges;

  @override
  State<DepartmentPickerScreen> createState() => _DepartmentPickerScreenState();
}

class _DepartmentPickerScreenState extends State<DepartmentPickerScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _selected;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _canChange =>
      _selected != null && _selected != widget.currentDepartment;

  Future<void> _confirm() async {
    final target = _selected!;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ConfirmSheet(departmentName: target),
    );
    if (ok == true && mounted) Navigator.of(context).pop(target);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.departmentNames
        : widget.departmentNames.where((n) => n.contains(_query)).toList();

    return Scaffold(
      // 키보드 양옆 둥근 모서리 틈으로 Scaffold 바탕이 비쳐 파랑이 보이지
      // 않도록, 바탕은 흰색으로 두고 파랑은 body 영역에만 깐다.
      backgroundColor: Colors.white,
      body: ColoredBox(
        color: AppColors.cobalt,
        child: SafeArea(
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
                              '학과 변경',
                              style: TextStyle(
                                color: AppColors.ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            '어느 학과로\n바꿀까?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              letterSpacing: -0.04,
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
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                          child: Row(
                            children: [
                              const Text(
                                '현재 학과',
                                style: TextStyle(
                                  color: _mutedText,
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.ink,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  widget.currentDepartment,
                                  style: const TextStyle(
                                    color: AppColors.lime,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _fieldBackground,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (v) => setState(() => _query = v),
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 14,
                              ),
                              decoration: const InputDecoration(
                                icon: Padding(
                                  padding: EdgeInsets.only(left: 14),
                                  child: Icon(Icons.search, color: _mutedText),
                                ),
                                hintText: '학과 이름 검색',
                                hintStyle: TextStyle(color: _mutedText),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 6,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final name = filtered[index];
                              return _DepartmentRow(
                                name: name,
                                college: widget.colleges[name],
                                selected: name == _selected,
                                onTap: () => setState(() => _selected = name),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            4,
                            20,
                            16 + MediaQuery.of(context).padding.bottom,
                          ),
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: _canChange
                                  ? [
                                      BoxShadow(
                                        color: AppColors.cobalt.withValues(
                                          alpha: 0.35,
                                        ),
                                        offset: const Offset(0, 6),
                                        blurRadius: 14,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: SizedBox.expand(
                              child: ElevatedButton(
                                onPressed: _canChange ? _confirm : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.cobalt,
                                  disabledBackgroundColor: const Color(
                                    0xFFC9D3F2,
                                  ),
                                  elevation: 0,
                                  shape: const StadiumBorder(),
                                ),
                                child: const Text(
                                  '변경하기',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DepartmentRow extends StatelessWidget {
  const _DepartmentRow({
    required this.name,
    required this.college,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String? college;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFDCE6FB) : _fieldBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.cobalt : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected ? AppColors.cobalt : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.school,
                size: 20,
                color: selected ? Colors.white : AppColors.cobalt,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (college != null)
                    Text(
                      college!,
                      style: const TextStyle(color: _mutedText, fontSize: 11),
                    ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.cobalt : Colors.transparent,
                border: selected
                    ? null
                    : Border.all(color: const Color(0xFFC4C4CC), width: 1.5),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// "OO학과로 바꿀까요?" 확인 시트. 변경하면 true, 취소하면 false를 반환한다.
class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({required this.departmentName});

  final String departmentName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE1E1E6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 22),
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFDCE6FB),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.swap_horiz, color: AppColors.cobalt),
          ),
          const SizedBox(height: 14),
          Text(
            '$departmentName로 바꿀까요?',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '학과 등수와 평점 비교 기준이\n새 학과로 바뀌어요',
            textAlign: TextAlign.center,
            style: TextStyle(color: _mutedText, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _fieldBackground,
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cobalt,
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      '변경',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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
