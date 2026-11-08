import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';

/// 홈 화면 하단 탭 바 ("우진이의 하루" v7).
/// 화면 아래에 떠 있는 흰색 바이며, 시간표 / 모아보기 / [가운데 홈 버튼] /
/// 캘린더 / MY 순서다. 가운데 홈 버튼은 바 위로 살짝 솟아 있다. 탭을 눌렀을 때
/// 어디로 이동할지는 [onTap]이 인덱스로 받아 처리한다.
///
/// 아이콘은 Figma "03 홈"에서 받은 SVG(Material Symbols Rounded, 굵기 600)를
/// 쓴다. Flutter 기본 아이콘은 선 굵기와 모양이 달라서다. 선택된 탭은 안이
/// 채워진 아이콘(FILL 1)을 파란색으로 칠한다. 달력은 Figma 아이콘 모음에서,
/// 나머지 채운 아이콘(apps·event·person)은 같은 세트의 Google 공식 저장소
/// (material-design-icons, wght600 fill1)에서 받았다.
class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({super.key, required this.selectedIndex, this.onTap});

  /// 지금 선택된 탭(0~4). 홈(가운데)은 2번이라 홈 화면에서는 항상 2.
  final int selectedIndex;
  final ValueChanged<int>? onTap;

  static const _items = [
    (
      asset: 'assets/icons/calendar_month_outline.svg',
      selectedAsset: 'assets/icons/calendar_month.svg',
      label: '시간표',
    ),
    (
      asset: 'assets/icons/apps_outline.svg',
      selectedAsset: 'assets/icons/apps.svg',
      label: '모아보기',
    ),
    null, // 가운데 홈 버튼 자리
    (
      asset: 'assets/icons/event_outline.svg',
      selectedAsset: 'assets/icons/event.svg',
      label: '캘린더',
    ),
    (
      asset: 'assets/icons/person_outline.svg',
      selectedAsset: 'assets/icons/person.svg',
      label: 'MY',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // 디자인(390x844)에서 바 아랫변은 화면 맨 아래에서 26 위, 즉 홈 인디케이터
    // 영역(34)에 8만큼 걸쳐 있다. 아래 안전 영역이 없는 기기는 12를 띄운다.
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        safeBottom - 8 > 12 ? safeBottom - 8 : 12,
      ),
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.line),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              offset: Offset(0, 4),
              blurRadius: 16,
            ),
          ],
        ),
        child: Row(
          children: [
            // 디자인에서 가운데 홈 칸이 양옆 칸보다 넓다(약 80 : 66).
            for (var i = 0; i < _items.length; i++)
              Expanded(
                flex: _items[i] == null ? 80 : 66,
                child: _items[i] == null
                    ? _CenterButton(
                        selected: i == selectedIndex,
                        onTap: () => onTap?.call(i),
                      )
                    : _NavItem(
                        asset: i == selectedIndex
                            ? _items[i]!.selectedAsset
                            : _items[i]!.asset,
                        label: _items[i]!.label,
                        selected: i == selectedIndex,
                        onTap: () => onTap?.call(i),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.asset,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String asset;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.blueText : AppColors.textSub;
    return Pressable.icon(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            asset,
            width: 21,
            height: 21,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 가운데 홈 버튼. 연한 파랑 바탕에 흰 테두리를 두르고, 바 위로 11 솟아 있다.
/// 디자인처럼 바깥 테두리 선은 없다(흰 테두리가 바와 이어져 보인다).
///
/// 홈 화면일 때만 파랗게 칠한다. 다른 탭에서도 파라면 어느 탭에 있는지
/// 헷갈려서, 그때는 회색 바탕·회색 아이콘으로 둔다(시안에는 홈 상태만 있다).
class _CenterButton extends StatelessWidget {
  const _CenterButton({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.translate(
        offset: const Offset(0, -12),
        child: Pressable.icon(
          onTap: onTap,
          child: Container(
            width: 68,
            height: 68,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.blueSoft : AppColors.fill,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: SvgPicture.asset(
              'assets/icons/home.svg',
              width: 30,
              height: 30,
              colorFilter: ColorFilter.mode(
                selected ? AppColors.blueText : AppColors.textSub,
                BlendMode.srcIn,
              ),
              semanticsLabel: '홈',
            ),
          ),
        ),
      ),
    );
  }
}
