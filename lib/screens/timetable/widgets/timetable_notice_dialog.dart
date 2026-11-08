import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
import '../timetable_colors.dart';

/// 시간표 화면의 안내 팝업(아이콘 + 제목 + 설명 + "확인"). 모양은 캘린더의
/// 안내 팝업(reminder_past_dialog.dart)과 같다.
Future<void> showTimetableNoticeDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: TimetableColors.barrier,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.blueSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.blue),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textStrong,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.51,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textBody,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: Pressable.effect(
                pressedScale: 0.97,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    '확인',
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
      ),
    ),
  );
}

/// 담은 과목이 하나도 없는데 "저장"을 눌렀을 때. 빈 시간표는 저장하지 않는다.
Future<void> showEmptySaveDialog(BuildContext context) =>
    showTimetableNoticeDialog(
      context,
      icon: Icons.event_busy_rounded,
      title: '담은 과목이 없어요',
      message: '과목 추가나 자동 생성으로\n과목을 담은 뒤 저장해 주세요.',
    );

/// 학교가 그 학기 개설과목(시간표)을 아직 올리지 않았을 때.
Future<void> showCatalogNotReadyDialog(
  BuildContext context, {
  required int year,
  required int semester,
}) => showTimetableNoticeDialog(
  context,
  icon: Icons.hourglass_empty_rounded,
  title: '아직 시간표가 나오지 않았어요',
  message:
      '$year년 $semester학기 시간표가 아직 나오지 않아서\n'
      '개설 과목을 알 수 없어요.',
);
