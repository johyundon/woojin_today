import 'package:flutter/material.dart';

/// 화면이 보통 아이폰보다 훨씬 넓으면(아이폰 듀오를 펼친 큰 화면 등) 앱을
/// 아이폰 폭으로 가운데에 세워 보여 준다(사용자 요청, 2026-11-28).
///
/// 화면들은 아이폰 세로 폭(최대 440pt)에 맞춰 만들어져 있어서, 넓은 화면에
/// 그대로 늘리면 카드·격자가 어색하게 퍼진다. 안쪽 화면에는 폭을 [maxWidth]로
/// 알려 주어(MediaQuery) 레이아웃이 아이폰과 똑같이 계산되게 하고, 양옆
/// 여백은 [sideColor]로 채운다. 보통 아이폰 세로 화면에서는 아무것도 바꾸지
/// 않는다.
class PhoneWidthFrame extends StatelessWidget {
  const PhoneWidthFrame({super.key, required this.child});

  final Widget child;

  /// 가운데에 세울 폭. 가장 큰 아이폰(Pro Max) 세로 폭과 같다.
  static const double maxWidth = 440;

  /// 이 폭을 넘을 때만 가운데로 모은다. 아이폰 세로 화면은 모두 이보다 좁다.
  static const double wideThreshold = 600;

  /// 양옆 여백 색.
  static const Color sideColor = Color(0xFFE9EBEF);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.width <= wideThreshold) return child;
    // 가운데 칸 안에서는 양옆 안전 영역(노치 등)이 없으므로 좌우 여백은 0으로 둔다.
    EdgeInsets noSides(EdgeInsets e) => e.copyWith(left: 0, right: 0);
    return ColoredBox(
      color: sideColor,
      child: Center(
        child: SizedBox(
          width: maxWidth,
          child: MediaQuery(
            data: media.copyWith(
              size: Size(maxWidth, media.size.height),
              padding: noSides(media.padding),
              viewPadding: noSides(media.viewPadding),
              viewInsets: noSides(media.viewInsets),
            ),
            child: ClipRect(child: child),
          ),
        ),
      ),
    );
  }
}
