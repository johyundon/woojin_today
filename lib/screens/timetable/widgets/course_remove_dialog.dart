import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
import '../timetable_colors.dart';

/// 시간표 블록의 "×"를 눌렀을 때 뜨는 "삭제하시겠습니까?" 확인창(사용자가 보낸
/// 시안 캡처, 2026-11-16). 삭제하면 true, 취소하거나 바깥을 눌러 닫으면 false.
Future<bool> showCourseRemoveDialog(BuildContext context) {
  return showAppConfirmModal(
    context,
    title: '삭제하시겠습니까?',
    cancelLabel: '취소',
    confirmLabel: '삭제',
    cancelKey: const ValueKey('course-remove-cancel'),
    confirmKey: const ValueKey('course-remove-confirm'),
  );
}

/// "시간표 만들기"에서 고른 과목이 이미 담은 과목과 시간이 겹칠 때 뜨는
/// 확인창(사용자 요청, 2026-11-26). "확인"이면 true — 기존 과목을 빼고 새
/// 과목을 담는다. "취소"나 바깥을 누르면 false.
Future<bool> showCourseConflictDialog(
  BuildContext context, {
  required String existingNames,
  required String newName,
}) {
  return showAppConfirmModal(
    context,
    title: '시간이 겹치는 과목이 있어요',
    message: '$existingNames 과목을 빼고\n$newName 과목을 담을까요?',
    cancelLabel: '취소',
    confirmLabel: '확인',
    cancelKey: const ValueKey('course-conflict-cancel'),
    confirmKey: const ValueKey('course-conflict-confirm'),
  );
}

/// 시안의 "AppConfirmModal": 연분홍 원 안의 빨간 "!", 제목, (있으면) 회색 설명,
/// 아래 두 버튼(왼쪽 연한 버튼·오른쪽 빨간 버튼). 오른쪽을 누르면 true,
/// 왼쪽을 누르거나 바깥을 눌러 닫으면 false.
Future<bool> showAppConfirmModal(
  BuildContext context, {
  required String title,
  String? message,
  required String cancelLabel,
  required String confirmLabel,
  Key? cancelKey,
  Key? confirmKey,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: TimetableColors.barrier,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 46),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: _RemoveDialogColors.alertSoft,
                shape: BoxShape.circle,
              ),
              child: const Text(
                '!',
                style: TextStyle(
                  color: _RemoveDialogColors.alertRed,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textStrong,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSub,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _RemoveDialogButton(
                    key: cancelKey,
                    label: cancelLabel,
                    background: _RemoveDialogColors.cancelFill,
                    foreground: _RemoveDialogColors.cancelText,
                    onTap: () => Navigator.of(dialogContext).pop(false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _RemoveDialogButton(
                    key: confirmKey,
                    label: confirmLabel,
                    background: _RemoveDialogColors.alertRed,
                    foreground: Colors.white,
                    onTap: () => Navigator.of(dialogContext).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}

/// 캡처에서 눈으로 옮긴 색.
abstract final class _RemoveDialogColors {
  static const Color alertRed = Color(0xFFEC615A);
  static const Color alertSoft = Color(0xFFFCEAE9);
  static const Color cancelFill = Color(0xFFEAD9DD);
  static const Color cancelText = Color(0xFF6B5560);
}

class _RemoveDialogButton extends StatelessWidget {
  const _RemoveDialogButton({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: foreground,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
