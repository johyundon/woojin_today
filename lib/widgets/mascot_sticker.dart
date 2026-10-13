import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 마스코트("우진이")를 다이컷 스티커처럼 보여주는 위젯.
///
/// 그림자(아래쪽으로 은은하게) → 흰 테두리(실루엣을 8방향으로 살짝씩 겹쳐
/// 찍어 두께가 일정하게) → 본 이미지 순으로 쌓는다. 블러만으로 흰 테두리를
/// 만들면 뿌연 후광처럼 보여서(스플래시 화면에서 확인된 문제) 대신 이 방식을
/// 쓴다. 오프셋은 [width] 190을 기준으로 잡은 값이라, 다른 크기로 쓸 때도
/// 비례해서 자동으로 맞춰진다.
class MascotSticker extends StatelessWidget {
  const MascotSticker({super.key, this.width = 190, this.angle = -0.12});

  /// 이미지 폭. 그림자/테두리 두께가 이 값에 비례해서 커지거나 작아진다.
  final double width;

  /// 라디안 단위 기울기. 음수면 왼쪽, 양수면 오른쪽으로 기운다.
  final double angle;

  static const _referenceWidth = 190.0;
  static const _borderOffsets = [
    Offset(4, 0),
    Offset(2.8, 2.8),
    Offset(0, 4),
    Offset(-2.8, 2.8),
    Offset(-4, 0),
    Offset(-2.8, -2.8),
    Offset(0, -4),
    Offset(2.8, -2.8),
  ];

  @override
  Widget build(BuildContext context) {
    final scale = width / _referenceWidth;

    return Transform.rotate(
      angle: angle,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: 2 * scale,
            top: 18 * scale,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.22),
                BlendMode.srcIn,
              ),
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(
                  sigmaX: 9 * scale,
                  sigmaY: 9 * scale,
                ),
                child: Image.asset(
                  'assets/images/mascot_wave.png',
                  width: width,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          for (final offset in _borderOffsets)
            Transform.translate(
              offset: offset * scale,
              child: ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
                child: Image.asset(
                  'assets/images/mascot_wave.png',
                  width: width,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          Image.asset(
            'assets/images/mascot_wave.png',
            width: width,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}
