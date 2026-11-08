import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/mascot_sticker.dart';
import '../../../widgets/pressable.dart';
import '../timetable_colors.dart';

/// 상단 헤더("우진이의 하루" v7 디자인 16·23). 거의 흰 바탕 위에
/// 뒤로가기·학기 고르기·학점·저장·저장목록 줄(23), 그 아래 "내 시간표" 제목과
/// "자동 생성"/"과목 추가" 버튼(16)을 둔다. 16의 "학기 · 학점" 배지는 윗줄과
/// 내용이 겹쳐 빼고, 학기·학점은 윗줄에서 보여준다.
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
    this.showSave = true,
  });

  final String semesterLabel;
  final double totalCredits;
  final int savedCount;

  /// 학기 메뉴 위치 계산용 — 학기 버튼을 기준점으로 쓴다.
  final GlobalKey headerKey;
  final VoidCallback onBack;
  final VoidCallback onSemesterTap;
  final VoidCallback onSave;
  final VoidCallback onOpenSavedList;
  final VoidCallback onAutoFill;
  final VoidCallback onAddCourse;

  /// "저장" 버튼을 보일지. 지금 학기는 학교에 등록된 내 시간표 그대로라
  /// 저장할 이유가 없어 숨긴다.
  final bool showSave;

  String get _creditsLabel {
    final trimmed = totalCredits == totalCredits.roundToDouble()
        ? totalCredits.toInt().toString()
        : totalCredits.toString();
    return '$trimmed학점';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
          child: _buildTopRow(),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: _buildTitleBlock(),
            ),
            const Positioned(
              right: 8,
              top: -4,
              child: IgnorePointer(
                child: MascotSticker(width: 90, angle: 0.14),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopRow() {
    return Row(
      children: [
        Pressable.icon(
          onTap: onBack,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppColors.cardShadow,
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textStrong,
              size: 15,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Pressable(
          key: headerKey,
          onTap: onSemesterTap,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: AppColors.cardShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  semesterLabel,
                  style: const TextStyle(
                    color: AppColors.textStrong,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.4,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.expand_more_rounded,
                  color: AppColors.textStrong,
                  size: 17,
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        Text(
          _creditsLabel,
          style: const TextStyle(
            color: AppColors.textStrong,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
        if (showSave) ...[
          const SizedBox(width: 10),
          Pressable(
            pressedScale: 0.92,
            onTap: onSave,
            child: const Text(
              '저장',
              style: TextStyle(
                color: AppColors.blue,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                height: 1.4,
              ),
            ),
          ),
        ],
        const SizedBox(width: 10),
        Pressable.icon(
          onTap: onOpenSavedList,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.menu_rounded,
                color: AppColors.textStrong,
                size: 21,
              ),
              if (savedCount > 0)
                Positioned(
                  right: -5,
                  top: -5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.blue,
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

  Widget _buildTitleBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '내 시간표',
          style: TextStyle(
            color: AppColors.textStrong,
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.08,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _AutoFillButton(onTap: onAutoFill),
            const SizedBox(width: 8),
            Pressable(
              pressedScale: 0.93,
              onTap: onAddCourse,
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: AppColors.cardShadow,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      color: TimetableColors.headerButtonText,
                      size: 15,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '과목 추가',
                      style: TextStyle(
                        color: TimetableColors.headerButtonText,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// "자동 생성" 버튼. 파랑→보라→분홍 그라데이션 테두리(1.5) 안에 흰 바탕,
/// 반짝이 아이콘도 같은 그라데이션으로 칠한다.
class _AutoFillButton extends StatelessWidget {
  const _AutoFillButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      pressedScale: 0.93,
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          gradient: TimetableColors.aiGradient,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13.5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: TimetableColors.aiGradient.createShader,
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 15,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '자동 생성',
                style: TextStyle(
                  color: TimetableColors.headerButtonText,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
