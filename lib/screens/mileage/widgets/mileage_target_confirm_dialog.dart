import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../models/mileage_models.dart';
import 'mileage_roster_dialog.dart';

/// "{공지 제목} 공지" 다이얼로그 — 전부 목데이터라 실제 대상자 판별 로직이
/// 없어서 항상 "아쉽게도 대상자 명단에 없어요.."로 고정된다. "명단보기"를
/// 누르면 전체 명단 다이얼로그([showMileageRosterDialog])로 이어진다.
Future<void> showMileageTargetConfirmDialog(
  BuildContext context, {
  required MileageNotice notice,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _MileageTargetConfirmDialog(notice: notice),
  );
}

class _MileageTargetConfirmDialog extends StatelessWidget {
  const _MileageTargetConfirmDialog({required this.notice});

  final MileageNotice notice;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${notice.title} 공지',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '아쉽게도 대상자 명단에 없어요..',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => showMileageRosterDialog(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      '명단보기',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
