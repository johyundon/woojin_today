import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';

/// 흰 시트 위쪽 그림자(검정 6%, 위로 4, 번짐 20, v7 디자인 30).
const List<BoxShadow> _sheetShadow = [
  BoxShadow(color: Color(0x0F000000), offset: Offset(0, -4), blurRadius: 20),
];

/// 확인 시트 손잡이 rgb(221, 224, 228)(v7 디자인 31).
const _handle = Color(0xFFDDE0E4);

/// 확인 시트 뒤 어둡게 까는 색 rgba(20, 22, 30, 0.55)(v7 디자인 31).
const _barrier = Color(0x8C14161E);

/// "학과 변경" 화면(v7 디자인). 학과를 고르고 "변경하기"를 누르면 한 번 더
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
      barrierColor: _barrier,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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

    // 밝은 바탕이라 상태 표시줄 글자를 어둡게 한다.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          bottom: false,
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
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 35),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blueSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '학과 변경',
                        style: TextStyle(
                          color: AppColors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '어느 학과로 바꿀까?',
                      style: TextStyle(
                        color: AppColors.textStrong,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                        letterSpacing: -1.04,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(36),
                    ),
                    boxShadow: _sheetShadow,
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
                        child: Row(
                          children: [
                            const Text(
                              '현재 학과',
                              style: TextStyle(
                                color: AppColors.textSub,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.blue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    widget.currentDepartment,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Container(
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.fill,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (v) => setState(() => _query = v),
                            cursorColor: AppColors.blue,
                            style: const TextStyle(
                              color: AppColors.textStrong,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: const InputDecoration(
                              prefixIcon: Padding(
                                padding: EdgeInsets.only(left: 16, right: 8),
                                child: Icon(
                                  Icons.search_rounded,
                                  size: 19,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              prefixIconConstraints: BoxConstraints(),
                              hintText: '학과 이름 검색',
                              hintStyle: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
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
                          24,
                          4,
                          24,
                          16 + MediaQuery.of(context).padding.bottom,
                        ),
                        child: Pressable.effect(
                          enabled: _canChange,
                          pressedScale: 0.96,
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: _canChange
                                  ? AppColors.cardShadow
                                  : null,
                            ),
                            child: SizedBox.expand(
                              child: ElevatedButton(
                                onPressed: _canChange ? _confirm : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.blue,
                                  disabledBackgroundColor:
                                      AppColors.fillDisabled,
                                  foregroundColor: Colors.white,
                                  disabledForegroundColor: AppColors.textMuted,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  '변경하기',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
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
    return Pressable(
      onTap: onTap,
      pressedScale: 0.97,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? AppColors.blueSoft : AppColors.fill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.blue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected ? AppColors.blue : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.school_rounded,
                size: 17,
                color: selected ? Colors.white : AppColors.blue,
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
                      color: AppColors.textStrong,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (college != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      college!,
                      style: const TextStyle(
                        color: AppColors.textSub,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                color: selected ? AppColors.blue : Colors.transparent,
                border: selected
                    ? null
                    : Border.all(color: AppColors.checkLine, width: 2),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: Colors.white,
                    )
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
        22,
        12,
        22,
        40 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: _handle,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 22),
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.blueSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.swap_horiz_rounded,
              size: 24,
              color: AppColors.blue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$departmentName로 바꿀까요?',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textStrong,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.54,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '학과 등수와 평점 비교 기준이\n새 학과로 바뀌어요',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textBody,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: Pressable.effect(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.fill,
                        foregroundColor: AppColors.textStrong,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Pressable.effect(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        '변경',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
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
