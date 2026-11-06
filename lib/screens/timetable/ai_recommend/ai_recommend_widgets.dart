import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
import '../timetable_colors.dart';

/// AI 설문·결과 화면 왼쪽 위의 흰 네모 닫기(X) 버튼(v7 디자인 17~22).
class AiCloseButton extends StatelessWidget {
  const AiCloseButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Pressable.icon(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppColors.cardShadow,
        ),
        child: const Icon(Icons.close, color: AppColors.textStrong, size: 15),
      ),
    );
  }
}

/// 하단 왼쪽 "< 이전" 흰 버튼(92x60).
class AiBackButton extends StatelessWidget {
  const AiBackButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      pressedScale: 0.96,
      onTap: onTap,
      child: Container(
        width: 92,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chevron_left_rounded,
              color: AppColors.textStrong,
              size: 17,
            ),
            SizedBox(width: 2),
            Text(
              '이전',
              style: TextStyle(
                color: AppColors.textStrong,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// v7 슬라이더 모양: 높이 8 연파랑 트랙 + 흰 바탕에 파란 5px 테두리의 둥근
/// 네모 손잡이(28x28). 트랙은 슬라이더 폭을 꽉 채운다.
SliderThemeData aiSliderTheme(BuildContext context) {
  return SliderTheme.of(context).copyWith(
    trackHeight: 8,
    activeTrackColor: AppColors.blue,
    inactiveTrackColor: AppColors.blueSoft,
    thumbColor: Colors.white,
    overlayShape: SliderComponentShape.noOverlay,
    thumbShape: const _SquareThumbShape(),
    trackShape: const _FlatTrackShape(),
    // 1학점 단위로 멈추는(divisions) 슬라이더도 트랙에 눈금 점은 그리지 않는다.
    tickMarkShape: SliderTickMarkShape.noTickMark,
    padding: EdgeInsets.zero,
  );
}

/// [aiSliderTheme]을 씌운 28 높이 슬라이더.
class AiSlider extends StatelessWidget {
  const AiSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
  });

  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: aiSliderTheme(context),
      child: SizedBox(
        height: 28,
        child: Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// 활성 쪽 트랙을 더 두껍게 그리지 않는 트랙(디자인은 양쪽 모두 8).
class _FlatTrackShape extends RoundedRectSliderTrackShape {
  const _FlatTrackShape();

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    super.paint(
      context,
      offset,
      parentBox: parentBox,
      sliderTheme: sliderTheme,
      enableAnimation: enableAnimation,
      textDirection: textDirection,
      thumbCenter: thumbCenter,
      secondaryOffset: secondaryOffset,
      isDiscrete: isDiscrete,
      isEnabled: isEnabled,
      additionalActiveTrackHeight: 0,
    );
  }
}

class _SquareThumbShape extends SliderComponentShape {
  const _SquareThumbShape();

  static const double _size = 28;
  static const double _radius = 8;
  static const double _border = 5;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size(_size, _size);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final rect = Rect.fromCenter(center: center, width: _size, height: _size);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(_radius));
    for (final shadow in AiRecommendColors.thumbShadow) {
      canvas.drawRRect(rrect.shift(shadow.offset), shadow.toPaint());
    }
    canvas.drawRRect(rrect, Paint()..color = AppColors.blue);
    canvas.drawRRect(rrect.deflate(_border), Paint()..color = Colors.white);
  }
}
