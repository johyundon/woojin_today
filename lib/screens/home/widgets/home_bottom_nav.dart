import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';

/// 홈 화면 하단 탭 바 ("우진이의 하루" v7).
/// 화면 아래에 떠 있는 흰색 바이며, 시간표 / 모아보기 / [가운데 홈 버튼] /
/// 캘린더 / MY 순서다. 가운데 홈 버튼은 바 위로 살짝 솟아 있다. 탭을 눌렀을 때
/// 어디로 이동할지는 [onTap]이 인덱스로 받아 처리한다.
class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({super.key, required this.selectedIndex, this.onTap});

  /// 지금 선택된 탭(0~4). 홈(가운데)은 2번이라 홈 화면에서는 항상 2.
  final int selectedIndex;
  final ValueChanged<int>? onTap;

  static const _items = [
    (
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month_rounded,
      label: '시간표',
    ),
    (
      icon: Icons.apps_outlined,
      selectedIcon: Icons.apps_rounded,
      label: '모아보기',
    ),
    null, // 가운데 홈 버튼 자리
    (
      icon: Icons.event_outlined,
      selectedIcon: Icons.event_rounded,
      label: '캘린더',
    ),
    (
      icon: Icons.person_outline,
      selectedIcon: Icons.person_rounded,
      label: 'MY',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 6),
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
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: _items[i] == null
                    ? _CenterButton(onTap: () => onTap?.call(i))
                    : _NavItem(
                        icon: i == selectedIndex
                            ? _items[i]!.selectedIcon
                            : _items[i]!.icon,
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
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
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
          Icon(icon, size: 22, color: color),
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

/// 가운데 홈 버튼. 연한 파랑 바탕에 흰 테두리를 두르고, 바 위로 10 솟아 있다.
class _CenterButton extends StatelessWidget {
  const _CenterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.translate(
        offset: const Offset(0, -10),
        child: Pressable.icon(
          onTap: onTap,
          child: Container(
            width: 68,
            height: 68,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.blueSoft,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: const [
                BoxShadow(color: AppColors.line, spreadRadius: 1),
              ],
            ),
            child: const Icon(
              Icons.home_rounded,
              size: 30,
              color: AppColors.blueText,
            ),
          ),
        ),
      ),
    );
  }
}
