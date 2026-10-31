import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';

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
