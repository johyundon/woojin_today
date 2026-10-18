import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// 홈 화면 하단 탭 바 ("우진이의 하루" v4 리디자인).
/// 화면 아래에 떠 있는 검은색 알약 모양이며, 시간표 / 모아보기 / [가운데
/// 라임색 마스코트 버튼 = 홈] / 캘린더 / MY 순서다. 탭을 눌렀을 때 어디로 이동할지는
/// [onTap]이 인덱스로 받아 처리한다.
class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({super.key, required this.selectedIndex, this.onTap});

  /// 지금 선택된 탭(0~4). 홈(가운데)은 2번이라 홈 화면에서는 항상 2.
  final int selectedIndex;
  final ValueChanged<int>? onTap;

  static const _items = [
    (icon: Icons.schedule_rounded, label: '시간표'),
    (icon: Icons.apps_rounded, label: '모아보기'),
    null, // 가운데 라임색 홈 버튼 자리
    (icon: Icons.event_rounded, label: '캘린더'),
    (icon: Icons.person_rounded, label: 'MY'),
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
        height: 68,
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              offset: const Offset(0, 8),
              blurRadius: 20,
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
                        icon: _items[i]!.icon,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(34),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 24,
            color: selected ? AppColors.lime : const Color(0xFF8A877F),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF8A877F),
              fontSize: 11,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 가운데 라임색 동그란 마스코트 버튼. 라임색 테두리 링이 한 겹 더 둘러져 있다.
class _CenterButton extends StatelessWidget {
  const _CenterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 64,
          height: 64,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.lime, width: 2),
          ),
          child: Container(
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.lime,
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/images/mascot_wave.png',
              width: 40,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
