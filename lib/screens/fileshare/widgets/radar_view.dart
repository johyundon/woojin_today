import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nsd/nsd.dart' as nsd;

import '../../../theme/app_colors.dart';
import '../fileshare_colors.dart';

/// 발견된 사람들을 가운데 원 바깥 타원 둘레에 배치한 레이더 시각화(v7).
/// 가운데는 파란 원 안의 마스코트.
class RadarView extends StatelessWidget {
  const RadarView({super.key, required this.peers});

  final List<nsd.Service> peers;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        // 시안처럼 사람 아바타는 두 고리(150·104) 바깥 양옆으로 퍼진다.
        final orbitX = min(width / 2 - 26, 125.0);
        final orbitY = height / 2 - 22;

        return SizedBox.expand(
          child: Stack(
            alignment: Alignment.center,
            children: [
              _ring(150, 0.06),
              _ring(104, 0.1),
              Container(
                width: 60,
                height: 60,
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.bottomCenter,
                decoration: const BoxDecoration(
                  color: AppColors.blue,
                  shape: BoxShape.circle,
                  boxShadow: AppColors.cardShadow,
                ),
                child: Transform.translate(
                  offset: const Offset(0, 8),
                  child: SvgPicture.asset(
                    'assets/images/mascot_wave.svg',
                    width: 50,
                    height: 62,
                  ),
                ),
              ),
              for (var i = 0; i < peers.length; i++)
                _peerBubble(
                  peer: peers[i],
                  color: avatarColors[i % avatarColors.length],
                  angle: _angleFor(i),
                  centerX: width / 2,
                  centerY: height / 2,
                  orbitX: orbitX,
                  orbitY: orbitY,
                ),
            ],
          ),
        );
      },
    );
  }

  /// 시안처럼 사람은 고리 양옆(왼쪽·오른쪽 번갈아)에 놓고, 같은 쪽에 여럿이면
  /// 위아래로 조금씩 비껴 둔다 — 고리 위·아래는 높이가 모자라 겹치기 때문.
  static double _angleFor(int index) {
    const tilts = [-0.25, 0.45, -0.7, 0.9];
    final tilt = tilts[(index ~/ 2) % tilts.length];
    return index.isEven ? pi - tilt : tilt;
  }

  Widget _ring(double diameter, double alpha) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.blue.withValues(alpha: alpha),
      ),
    );
  }

  Widget _peerBubble({
    required nsd.Service peer,
    required Color color,
    required double angle,
    required double centerX,
    required double centerY,
    required double orbitX,
    required double orbitY,
  }) {
    final dx = centerX + orbitX * cos(angle) - 17;
    final dy = centerY + orbitY * sin(angle) - 17;
    final label = (peer.name ?? '?').characters.firstOrNull ?? '?';

    return Positioned(
      left: dx,
      top: dy,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(9),
          boxShadow: AppColors.cardShadow,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: avatarForeground(color),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
