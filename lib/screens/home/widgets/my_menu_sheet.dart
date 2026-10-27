import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../home_enums.dart';

/// MY 탭: 아바타 메뉴와 같은 항목(내 정보/이용약관/로그아웃)을 보여주는 바텀시트 본문.
/// 항목마다 연한 회색 칸 + 아이콘 칸 + 화살표로 보여주고, 로그아웃만 빨간색으로
/// 구분한다.
class MyMenuSheet extends StatelessWidget {
  const MyMenuSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE3E3EA),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const _MenuTile(
              icon: Icons.person_rounded,
              label: '내 정보',
              action: AvatarMenuAction.myInfo,
            ),
            const SizedBox(height: 10),
            const _MenuTile(
              icon: Icons.description_rounded,
              label: '이용약관',
              action: AvatarMenuAction.terms,
            ),
            const SizedBox(height: 10),
            const _MenuTile(
              icon: Icons.logout_rounded,
              label: '로그아웃',
              action: AvatarMenuAction.logout,
              danger: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.action,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final AvatarMenuAction action;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF0F0F8),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).pop(action),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: danger ? AppColors.blushPink : AppColors.lime,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: danger ? _accentRed : AppColors.ink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: danger ? _accentRed : AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: danger ? _accentRed : const Color(0x99121212),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Figma 스크린샷(node 6:16)의 "로그아웃" 텍스트를 스포이드로 찍어 확인한 값.
const Color _accentRed = Color(0xFFFF4D4F);
