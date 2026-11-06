import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

/// v7 홈 위쪽의 흰 네모 아이콘 버튼(검색/알림). Figma "03 홈"의 Box(40×40,
/// 모서리 12, 그림자 0·2·7 검정 6%)와 아이콘(Material Symbols Rounded, FILL 1,
/// 굵기 600, 19×19)을 그대로 옮겼다. 아이콘은 Figma에서 받은 SVG 파일을 쓴다
/// (Flutter 기본 아이콘은 선 굵기와 모양이 달라서). [dot]이 true면 오른쪽 위에
/// 빨간 둥근 네모(12×12, 흰 테두리 2)를 겹친다. [HomeTopIconButton]은 아직 v7로
/// 바꾸지 않은 셔틀 화면 뒤로가기로도 쓰여서 따로 둔다.
class HomeV7IconButton extends StatelessWidget {
  const HomeV7IconButton({
    super.key,
    required this.asset,
    required this.onTap,
    this.dot = false,
    this.semanticLabel,
  });

  static const searchAsset = 'assets/icons/search.svg';
  static const notificationsAsset = 'assets/icons/notifications.svg';

  final String asset;
  final VoidCallback onTap;
  final bool dot;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Pressable.icon(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                offset: Offset(0, 2),
                blurRadius: 7,
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: 10.5,
                top: 10.5,
                child: SvgPicture.asset(asset, width: 19, height: 19),
              ),
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
      ),
    );
  }
}
