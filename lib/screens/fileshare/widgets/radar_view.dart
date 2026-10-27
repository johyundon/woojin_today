import 'dart:math';

import 'package:flutter/material.dart';
import 'package:nsd/nsd.dart' as nsd;

import '../../../theme/app_colors.dart';
import '../fileshare_colors.dart';

/// 발견된 사람들을 원 둘레에 배치한 레이더 시각화. 가운데는 내 마스코트.
class RadarView extends StatelessWidget {
  const RadarView({super.key, required this.peers});

  final List<nsd.Service> peers;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide;
        final center = size / 2;
        final orbitRadius = size * 0.34;

        return SizedBox.expand(
          child: Stack(
            alignment: Alignment.center,
            children: [
              _ring(size * 0.82),
              _ring(size * 0.58),
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.lime,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school, color: AppColors.ink, size: 28),
              ),
              for (var i = 0; i < peers.length; i++)
                _peerBubble(
                  peer: peers[i],
                  color: avatarColors[i % avatarColors.length],
                  angle: (2 * pi * i) / peers.length - pi / 2,
                  center: center,
                  orbitRadius: orbitRadius,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _ring(double diameter) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.cobalt.withValues(alpha: 0.06),
      ),
    );
  }

  Widget _peerBubble({
    required nsd.Service peer,
    required Color color,
    required double angle,
    required double center,
    required double orbitRadius,
  }) {
    final dx = center + orbitRadius * cos(angle) - 18;
    final dy = center + orbitRadius * sin(angle) - 18;
    final label = (peer.name ?? '?').characters.firstOrNull ?? '?';

    return Positioned(
      left: dx,
      top: dy,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
