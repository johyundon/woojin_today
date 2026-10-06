import 'package:flutter/material.dart';

/// 그라데이션 배경 + 장식용 원형 2개를 공통으로 그리는 카드 베이스.
class GradientCard extends StatelessWidget {
  const GradientCard({
    required this.colors,
    required this.onTap,
    required this.child,
    this.height,
  });

  final List<Color> colors;
  final VoidCallback onTap;
  final Widget child;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: _DecoCircle(size: 140, opacity: 0.08),
            ),
            Positioned(
              right: -10,
              top: 44,
              child: _DecoCircle(size: 90, opacity: 0.06),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _DecoCircle extends StatelessWidget {
  const _DecoCircle({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}
