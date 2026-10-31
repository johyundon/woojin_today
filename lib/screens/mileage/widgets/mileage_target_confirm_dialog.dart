import 'package:flutter/material.dart';

import '../../../services/mileage_service.dart';
import '../../../theme/app_colors.dart';
import '../models/mileage_models.dart';
import 'mileage_roster_dialog.dart';

/// "{공지 제목} 공지" 다이얼로그(목데이터용) — 실제 대상자 판별 로직이 없어서
/// 항상 "아쉽게도 대상자 명단에 없어요.."로 고정된다. "명단보기"를 누르면 전체
/// 명단 다이얼로그([showMileageRosterDialog])로 이어진다.
///
/// 마일리지 화면은 이제 [showMileageTargetResultDialog]로 실제 명단을 확인하고,
/// 다른 학생 학번 명단은 보여주지 않는다. 이 다이얼로그는 공지 목데이터
/// (`notice_mock_data.dart`)가 아직 참조해서 남겨 두었다.
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

/// 실제 명단 대조 결과 다이얼로그. [result]가 끝날 때까지 로딩을 보여주고,
/// 대상자인지만 알려준다. 다른 학생 학번 명단은 보여주지 않는다.
Future<void> showMileageTargetResultDialog(
  BuildContext context, {
  required String title,
  required Future<MileageTargetResult> result,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _MileageTargetResultDialog(title: title, result: result),
  );
}

class _MileageTargetResultDialog extends StatelessWidget {
  const _MileageTargetResultDialog({required this.title, required this.result});

  final String title;
  final Future<MileageTargetResult> result;

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
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            FutureBuilder<MileageTargetResult>(
              future: result,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text(
                        '명단에서 내 학번을 찾는 중이에요',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  );
                }
                final message = snapshot.hasError
                    ? '명단을 확인하지 못했어요.\n잠시 후 다시 시도해 주세요.'
                    : switch (snapshot.data!) {
                        MileageTargetResult.target => '축하해요! 대상자 명단에 있어요',
                        MileageTargetResult.notTarget => '아쉽게도 대상자 명단에 없어요..',
                        MileageTargetResult.noRoster => '이 공지에는 확인할 명단 파일이 없어요',
                      };
                return Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
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
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
