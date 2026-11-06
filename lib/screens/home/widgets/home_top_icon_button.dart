import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
import '../home_colors.dart';

/// 홈 화면 상단의 원형 아이콘 버튼(검색/알림). [dot]이 true면 오른쪽 위에 작은
/// 점(읽지 않은 알림 등 표시)을 겹쳐 보여준다. 누르면 살짝 작아졌다 튕기듯
/// 돌아오고 가볍게 진동한다([Pressable.icon]).
class HomeTopIconButton extends StatelessWidget {
  const HomeTopIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.dot = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Pressable.icon(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.cobaltDeep,
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            if (dot)
              Positioned(
                top: 9,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.blushPink,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// v7 홈 화면 상단의 흰 네모 아이콘 버튼(검색/알림). [HomeTopIconButton]은 아직
/// v7로 바꾸지 않은 졸업학점·셔틀 화면의 뒤로가기 버튼으로도 쓰여서, 그 화면들
/// 모양이 같이 바뀌지 않도록 v7 모양은 따로 둔다. [dot]이 true면 오른쪽 위에
/// 빨간 점(읽지 않은 새 공지)을 겹쳐 보여준다.
class HomeV7IconButton extends StatelessWidget {
  const HomeV7IconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.dot = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Pressable.icon(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppColors.cardShadow,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: AppColors.textStrong, size: 19),
            if (dot)
              Positioned(
                top: 9,
                left: 18,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: HomeV7Colors.alertDot,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
