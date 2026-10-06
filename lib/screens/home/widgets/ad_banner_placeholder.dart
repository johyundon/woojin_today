import 'package:flutter/material.dart';

import '../home_colors.dart';

/// 광고 SDK 연동 전 자리만 잡아두는 placeholder.
class AdBannerPlaceholder extends StatelessWidget {
  const AdBannerPlaceholder({required this.colors});

  final HomeColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.adBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '광고 영역',
        style: TextStyle(color: colors.textSecondary, fontSize: 13),
      ),
    );
  }
}
