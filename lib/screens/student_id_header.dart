import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/mascot_sticker.dart';
import '../widgets/pressable.dart';

// 학번 찾기 입력 화면(student_id_find_screen.dart)과 결과 화면
// (student_id_result_screen.dart)이 함께 쓰는 v7 부품(디자인 05~08).

/// 오류 안내 글자색(v7 디자인 07의 빨강).
const studentIdErrorRed = Color(0xFFCC272E);

/// 파란 바탕 위로 올라오는 흰 카드 모양(위쪽 모서리만 둥글다).
const studentIdCardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
  boxShadow: [
    BoxShadow(color: Color(0x0F000000), offset: Offset(0, -4), blurRadius: 20),
  ],
);

/// 파란 영역의 뒤로가기 버튼 + 작은 이름표 + 큰 제목 + 마스코트.
/// 높이는 디자인처럼 242로 고정한다(흰 카드가 그 아래에서 시작한다).
class StudentIdHeader extends StatelessWidget {
  const StudentIdHeader({super.key, required this.badge, required this.title});

  final String badge;
  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 242,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            right: 3,
            top: 7,
            child: IgnorePointer(
              child: MascotSticker(width: 174, angle: 0.1222),
            ),
          ),
          Positioned(
            left: 22,
            top: 8,
            child: Pressable.icon(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 15,
                  color: Colors.white,
                  semanticLabel: '뒤로',
                ),
              ),
            ),
          ),
          Positioned(
            left: 28,
            top: 74,
            right: 150,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.blueSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: AppColors.blue,
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    height: 1.4,
                    letterSpacing: -1.16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 큰 파란 버튼(높이 60, 글자 + 화살표). [looksEnabled]가 false면 회색으로
/// 보이지만, [onPressed]가 있으면 여전히 눌린다(입력 확인 알림을 띄우기 위해).
class StudentIdBlueButton extends StatelessWidget {
  const StudentIdBlueButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.looksEnabled = true,
    this.showArrow = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool looksEnabled;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    final foreground = looksEnabled ? Colors.white : AppColors.textMuted;
    return Pressable.effect(
      enabled: onPressed != null,
      pressedScale: 0.96,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: looksEnabled
              ? const [
                  BoxShadow(
                    color: Color(0x240A78E6),
                    offset: Offset(0, 4),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: looksEnabled
                ? AppColors.blue
                : AppColors.fillDisabled,
            disabledBackgroundColor: looksEnabled
                ? AppColors.blue
                : AppColors.fillDisabled,
            foregroundColor: foreground,
            disabledForegroundColor: foreground,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (showArrow) ...[
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_rounded, size: 17),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
