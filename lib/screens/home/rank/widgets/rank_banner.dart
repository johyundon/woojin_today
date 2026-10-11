import 'package:flutter/material.dart';

import '../rank_colors.dart';

/// 전체 폭 주황색 알약 배너 "{N}명 중 {M}등".
class RankBanner extends StatelessWidget {
  const RankBanner({
    required this.colors,
    required this.totalCount,
    required this.myRank,
  });

  final RankColors colors;
  final int totalCount;
  final int myRank;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: colors.highlight,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        '$totalCount명 중 $myRank등',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
