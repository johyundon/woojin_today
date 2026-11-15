import 'package:flutter/material.dart';

import '../../../services/mileage_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
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
                  child: Pressable.effect(
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
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Pressable.effect(
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
/// 대상자인지와 명단 인원수를 알려준다. "명단 보기"는 학교 공지에 첨부된 실제
/// 학번 목록을 검색과 함께 보여주고(기기에 저장하지 않음), "공지 원문 보기"
/// ([onOpenNotice])는 학교 공지 상세 화면으로 간다.
Future<void> showMileageTargetResultDialog(
  BuildContext context, {
  required String title,
  required Future<MileageTargetCheck> result,
  VoidCallback? onOpenNotice,
  String? myId,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _MileageTargetResultDialog(
      title: title,
      result: result,
      onOpenNotice: onOpenNotice,
      myId: myId,
    ),
  );
}

class _MileageTargetResultDialog extends StatelessWidget {
  const _MileageTargetResultDialog({
    required this.title,
    required this.result,
    this.onOpenNotice,
    this.myId,
  });

  final String title;
  final Future<MileageTargetCheck> result;

  /// 누르면 다이얼로그를 닫고 부른다. null이면 버튼을 그리지 않는다.
  final VoidCallback? onOpenNotice;

  /// 명단 창에서 강조할 내 학번.
  final String? myId;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                color: AppColors.textSub,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            FutureBuilder<MileageTargetCheck>(
              future: result,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Column(
                    children: [
                      CircularProgressIndicator(color: AppColors.blue),
                      SizedBox(height: 12),
                      Text(
                        '명단에서 내 학번을 찾는 중이에요',
                        style: TextStyle(
                          color: AppColors.textSub,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 24),
                    ],
                  );
                }
                final check = snapshot.hasError ? null : snapshot.data!;
                final message = check == null
                    ? '명단을 확인하지 못했어요.\n잠시 후 다시 시도해 주세요.'
                    : switch (check.result) {
                        MileageTargetResult.target => '축하해요! 대상자 명단에 있어요',
                        MileageTargetResult.notTarget => '아쉽게도 대상자 명단에 없어요..',
                        MileageTargetResult.noRoster => '이 공지에는 확인할 명단 파일이 없어요',
                      };
                final ids = check?.rosterIds;
                final hasRoster = ids != null && ids.isNotEmpty;
                return Column(
                  children: [
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textStrong,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (ids != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '이번 대상자는 모두 ${_formatCount(ids.length)}명이에요',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSub,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (hasRoster || onOpenNotice != null) ...[
                      Row(
                        children: [
                          if (hasRoster)
                            Expanded(
                              child: _OutlineAction(
                                label: '명단 보기',
                                onPressed: () => showMileageRosterDialog(
                                  context,
                                  studentIds: ids,
                                  myId: myId,
                                ),
                              ),
                            ),
                          if (hasRoster && onOpenNotice != null)
                            const SizedBox(width: 8),
                          if (onOpenNotice != null)
                            Expanded(
                              child: _OutlineAction(
                                label: '공지 원문 보기',
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  onOpenNotice!();
                                },
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                );
              },
            ),
            SizedBox(
              width: double.infinity,
              child: Pressable.effect(
                pressedScale: 0.96,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '확인',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 결과 창의 테두리 버튼(명단 보기 · 공지 원문 보기).
class _OutlineAction extends StatelessWidget {
  const _OutlineAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Pressable.effect(
      pressedScale: 0.96,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.blue,
          side: const BorderSide(color: AppColors.blueSoftLine),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// 1,200처럼 천 단위 쉼표를 넣는다.
String _formatCount(int value) => value.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => ',',
);
