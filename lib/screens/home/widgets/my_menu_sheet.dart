import 'package:flutter/material.dart';

import '../home_enums.dart';

/// MY 탭: 아바타 메뉴와 같은 항목(내 정보/이용약관/로그아웃)을 보여주는 바텀시트 본문.
class MyMenuSheet extends StatelessWidget {
  const MyMenuSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ListTile(
            title: const Text('내 정보'),
            onTap: () => Navigator.of(context).pop(AvatarMenuAction.myInfo),
          ),
          ListTile(
            title: const Text('이용약관'),
            onTap: () => Navigator.of(context).pop(AvatarMenuAction.terms),
          ),
          ListTile(
            title: const Text('로그아웃', style: TextStyle(color: _accentRed)),
            onTap: () => Navigator.of(context).pop(AvatarMenuAction.logout),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// Figma 스크린샷(node 6:16)의 "로그아웃" 텍스트를 스포이드로 찍어 확인한 값.
const Color _accentRed = Color(0xFFFF4D4F);
