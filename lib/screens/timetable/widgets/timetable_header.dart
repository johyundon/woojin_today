import 'package:flutter/material.dart';

import '../timetable_colors.dart';

/// 상단 헤더: 뒤로가기 / 학기 선택기 / 총 학점 / 저장 / 저장한 시간표 목록.
class TimetableHeader extends StatelessWidget {
  const TimetableHeader({
    required this.semesterLabel,
    required this.totalCredits,
    required this.savedCount,
    required this.headerKey,
    required this.onBack,
    required this.onSemesterTap,
    required this.onSave,
    required this.onOpenSavedList,
  });

  final String semesterLabel;
  final double totalCredits;
  final int savedCount;

  /// 학기 드롭다운 위치 계산용 — 헤더 줄(뒤로가기 포함) 전체의 왼쪽 끝을
  /// 기준점으로 쓴다(Figma 시안에서 드롭다운이 "학기" 필이 아니라 헤더
  /// 왼쪽 끝에 맞춰 뜨기 때문).
  final GlobalKey headerKey;
  final VoidCallback onBack;
  final VoidCallback onSemesterTap;
  final VoidCallback onSave;
  final VoidCallback onOpenSavedList;

  String get _creditsLabel {
    final trimmed = totalCredits == totalCredits.roundToDouble()
        ? totalCredits.toInt().toString()
        : totalCredits.toString();
    return '$trimmed학점';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      key: headerKey,
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: const Icon(
            Icons.arrow_back,
            color: TimetableColors.textPrimary,
          ),
          onPressed: onBack,
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onSemesterTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                semesterLabel,
                style: const TextStyle(
                  color: TimetableColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                color: TimetableColors.textSecondary,
                size: 18,
              ),
            ],
          ),
        ),
        const Spacer(),
        Text(
          _creditsLabel,
          style: const TextStyle(
            color: TimetableColors.accent,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 14),
        GestureDetector(
          onTap: onSave,
          child: const Text(
            '저장',
            style: TextStyle(
              color: TimetableColors.accent,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onOpenSavedList,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.menu, color: TimetableColors.textPrimary),
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
                      color: TimetableColors.danger,
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
    );
  }
}
