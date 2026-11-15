import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
import 'timetable_header.dart';

/// "시간표 만들기" 편집 화면의 상단(Figma 2272-18343, 2026-11-16).
/// 뒤로가기 · "시간표 만들기" · 학점 · 오른쪽 "저장", 그 아래 "내 시간표
/// 불러오기"·"자동 생성" 두 버튼.
class TimetableEditBar extends StatelessWidget {
  const TimetableEditBar({
    super.key,
    required this.creditsLabel,
    required this.onBack,
    required this.onSave,
  });

  /// 예: "15학점".
  final String creditsLabel;
  final VoidCallback onBack;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Pressable.icon(
            key: const ValueKey('timetable-edit-back'),
            onTap: onBack,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: AppColors.textStrong,
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            '시간표 만들기',
            style: TextStyle(
              color: AppColors.textStrong,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            creditsLabel,
            style: const TextStyle(
              color: AppColors.textSub,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Pressable(
            key: const ValueKey('timetable-edit-save'),
            pressedScale: 0.92,
            onTap: onSave,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '저장',
                style: TextStyle(
                  color: AppColors.blue,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 편집 화면 상단 아래 버튼 줄: "내 시간표 불러오기"(연파랑) + "자동 생성"
/// (그라데이션 테두리).
class TimetableEditActions extends StatelessWidget {
  const TimetableEditActions({
    super.key,
    required this.showLoadMine,
    required this.loading,
    required this.onLoadMine,
    required this.onAutoFill,
  });

  final bool showLoadMine;
  final bool loading;
  final VoidCallback onLoadMine;
  final VoidCallback onAutoFill;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showLoadMine) ...[
          Pressable(
            enabled: !loading,
            pressedScale: 0.93,
            onTap: loading ? null : onLoadMine,
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.blueSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: loading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.blue,
                      ),
                    )
                  : const Text(
                      '내 시간표 불러오기',
                      style: TextStyle(
                        color: AppColors.blue,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        TimetableAutoFillButton(onTap: onAutoFill),
      ],
    );
  }
}
