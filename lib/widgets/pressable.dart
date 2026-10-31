import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 버튼·칩·카드에 "눌렀다"는 느낌을 주는 공통 부품. 새 버튼은 이걸로 감싼다.
///
/// 누르는 동안 살짝 작아졌다가(카드는 옅어지기도 한다) 손을 떼면 돌아오는 효과, 그리고
/// 가벼운 진동으로 "눌렀다"는 느낌을 준다. 아주 짧게 톡 쳐도 효과가 보이도록
/// 손을 뗀 뒤 잠깐 눌린 모양을 유지한다.
///
/// 카드 안의 종 버튼처럼 [Pressable] 안에 또 [Pressable]이 있으면, 안쪽을 누르는
/// 동안 바깥쪽은 눌린 모양이 되지 않는다(두 탭 인식기가 모두 눌림 신호를 받기 때문).
class Pressable extends StatefulWidget {
  /// 카드·칩처럼 넓은 영역용. 살짝(97%) 작아지고 바로 돌아온다.
  const Pressable({
    required this.onTap,
    required this.child,
    this.pressedScale = 0.97,
    this.pressedOpacity = 1,
    this.haptic = HapticFeedback.selectionClick,
    this.releaseCurve = Curves.easeOut,
    this.releaseDuration = const Duration(milliseconds: 110),
    super.key,
  });

  /// 원형 아이콘 버튼(뒤로가기·종·검색 등)용. 더 많이(88%) 작아지고, 손을 떼면
  /// 살짝 커졌다가 제자리로 튕기듯 돌아오며, 조금 더 또렷한 진동을 준다.
  const Pressable.icon({
    required this.onTap,
    required this.child,
    this.pressedScale = 0.88,
    this.pressedOpacity = 1,
    this.haptic = HapticFeedback.lightImpact,
    this.releaseCurve = Curves.easeOutBack,
    this.releaseDuration = const Duration(milliseconds: 260),
    super.key,
  });

  final VoidCallback onTap;
  final Widget child;
  final double pressedScale;
  final double pressedOpacity;
  final Future<void> Function() haptic;
  final Curve releaseCurve;
  final Duration releaseDuration;

  @override
  State<Pressable> createState() => PressableState();
}

class PressableState extends State<Pressable> {
  static const _pressDuration = Duration(milliseconds: 110);

  bool _pressed = false;

  /// 안쪽 [Pressable]이 이번 손가락을 가져갔으면 true(손을 떼면 풀린다).
  bool _blockedByInner = false;

  void _setPressed(bool value) {
    if (_pressed != value && mounted) setState(() => _pressed = value);
  }

  Future<void> _release() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    _setPressed(false);
  }

  void _blockOuter() =>
      context.findAncestorStateOfType<PressableState>()?._blockedByInner = true;

  void _unblock() => _blockedByInner = false;

  @override
  Widget build(BuildContext context) {
    final duration = _pressed ? _pressDuration : widget.releaseDuration;
    final curve = _pressed ? Curves.easeOut : widget.releaseCurve;
    return Listener(
      onPointerDown: (_) => _blockOuter(),
      onPointerUp: (_) => _unblock(),
      onPointerCancel: (_) => _unblock(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          if (!_blockedByInner) _setPressed(true);
        },
        onTapUp: (_) => _release(),
        onTapCancel: () => _setPressed(false),
        onTap: () {
          widget.haptic();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? widget.pressedScale : 1,
          duration: duration,
          curve: curve,
          child: AnimatedOpacity(
            opacity: _pressed ? widget.pressedOpacity : 1,
            duration: duration,
            curve: curve,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
