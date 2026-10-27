import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/mascot_sticker.dart';

/// 상단 헤더("우진이의 하루" v4 리디자인). 코발트 배경 위에 뒤로가기/저장/
/// 저장목록 유틸 줄, 학기·학점 배지, "내 시간표" 제목, "자동 생성"/"과목
/// 추가" 버튼을 둔다. 디자인 시안엔 없지만 기존에 쓰이던 뒤로가기·학기
/// 선택·저장·저장목록 기능은 위치만 재배치하고 그대로 유지한다.
class TimetableHeader extends StatelessWidget {
  const TimetableHeader({
    super.key,
    required this.semesterLabel,
    required this.totalCredits,
    required this.savedCount,
    required this.headerKey,
    required this.onBack,
    required this.onSemesterTap,
    required this.onSave,
    required this.onOpenSavedList,
    required this.onAutoFill,
    required this.onAddCourse,
  });

  final String semesterLabel;
  final double totalCredits;
  final int savedCount;

  /// 학기 드롭다운 위치 계산용 — 배지를 기준점으로 쓴다.
  final GlobalKey headerKey;
  final VoidCallback onBack;
  final VoidCallback onSemesterTap;
  final VoidCallback onSave;
  final VoidCallback onOpenSavedList;
  final VoidCallback onAutoFill;
  final VoidCallback onAddCourse;

  String get _creditsLabel {
    final trimmed = totalCredits == totalCredits.roundToDouble()
        ? totalCredits.toInt().toString()
        : totalCredits.toString();
    return '$trimmed학점';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildContent(),
        const Positioned(
          right: -20,
          top: 56,
          child: MascotSticker(width: 120, angle: 0.08),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _circleIconButton(Icons.arrow_back_ios_new, onBack),
            const Spacer(),
            GestureDetector(
              onTap: onSave,
              child: const Text(
                '저장',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            GestureDetector(
              onTap: onOpenSavedList,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.menu, color: Colors.white),
                  if (savedCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF4D4F),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          '$savedCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          key: headerKey,
          onTap: onSemesterTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.lime,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$semesterLabel · $_creditsLabel',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.ink,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          '내 시간표',
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.04,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _pillButton(
              icon: Icons.auto_awesome,
              label: '자동 생성',
              background: AppColors.cobaltDeep,
              foreground: Colors.white,
              onTap: onAutoFill,
            ),
            const SizedBox(width: 8),
            _pillButton(
              icon: Icons.add,
              label: '과목 추가',
              background: Colors.white,
              foreground: AppColors.ink,
              onTap: onAddCourse,
            ),
          ],
        ),
      ],
    );
  }

  Widget _circleIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.cobaltDeep,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _pillButton({
    required IconData icon,
    required String label,
    required Color background,
    required Color foreground,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: foreground, size: 18),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
