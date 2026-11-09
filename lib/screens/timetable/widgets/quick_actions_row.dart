import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';

/// 헤더 바로 아래 줄(v7 디자인 23): "내 시간표 불러오기" 연파랑 버튼 +
/// "강의시간 알림" 토글.
class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({
    super.key,
    required this.loading,
    required this.onLoadMyTimetable,
    required this.notificationsEnabled,
    required this.onNotificationsChanged,
    this.showLoadButton = true,
    this.showNotificationToggle = true,
  });

  final bool loading;
  final VoidCallback onLoadMyTimetable;
  final bool notificationsEnabled;
  final ValueChanged<bool> onNotificationsChanged;

  /// "내 시간표 불러오기"를 보일지. 시간표가 아직 안 나온 학기에서는 숨긴다.
  final bool showLoadButton;

  /// "강의시간 알림" 스위치를 보일지. 이번 학기가 아니면 숨긴다(알림은 이번
  /// 학기 수업에만 의미가 있다).
  final bool showNotificationToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showLoadButton)
          Pressable(
            enabled: !loading,
            pressedScale: 0.93,
            onTap: loading ? null : onLoadMyTimetable,
            child: Container(
              height: 33,
              padding: const EdgeInsets.symmetric(horizontal: 14),
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
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                      ),
                    ),
            ),
          )
        else
          // 버튼이 없어도 줄 높이(33)는 그대로 둬서 아래 시간표가 들썩이지 않게 한다.
          const SizedBox(height: 33),
        const Spacer(),
        if (showNotificationToggle) ...[
          const Text(
            '강의시간 알림',
            style: TextStyle(
              color: AppColors.textStrong,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(width: 8),
          // 디자인 토글은 46x26(손잡이 20). 머티리얼 Switch(52x32)를 그 크기로
          // 줄여 쓴다 — 켜짐: 연파랑 바탕 + 파란 손잡이.
          SizedBox(
            width: 46,
            height: 26,
            child: FittedBox(
              child: Switch(
                value: notificationsEnabled,
                onChanged: onNotificationsChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeThumbColor: AppColors.blue,
                activeTrackColor: AppColors.blueSoft,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: AppColors.fillDisabled,
                trackOutlineColor: const WidgetStatePropertyAll(
                  Colors.transparent,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
