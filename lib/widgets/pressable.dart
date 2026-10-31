import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 버튼·칩·카드에 "눌렀다"는 느낌을 주는 공통 부품. 새 버튼은 이걸로 감싼다.
///
/// 누르는 동안 살짝 작아졌다가(카드는 옅어지기도 한다) 손을 떼면 돌아오는 효과, 그리고
/// 가벼운 진동으로 "눌렀다"는 느낌을 준다. 아주 짧게 톡 쳐도 효과가 보이도록
/// 손을 뗀 뒤 잠깐 눌린 모양을 유지한다.
///
/// 쓰는 법:
/// - 직접 만든 버튼(GestureDetector·InkWell 자리): [Pressable] / [Pressable.icon]으로
///   감싸고 `onTap`을 넘긴다.
/// - 이미 탭을 처리하는 버튼(ElevatedButton·TextButton·IconButton 등): 탭은 그 버튼에
///   두고 [Pressable.effect]로 감싸 눌리는 모양만 더한다.
/// - 눌러도 아무 일이 없는 상태(비활성)면 `enabled: false`로 효과를 끈다.
///
/// 카드 안의 종 버튼처럼 [Pressable] 안에 또 [Pressable]이 있으면, 안쪽을 누르는
/// 동안 바깥쪽은 눌린 모양이 되지 않는다(두 탭 인식기가 모두 눌림 신호를 받기 때문).
class Pressable extends StatefulWidget {
  /// 카드·칩처럼 넓은 영역용. 살짝(95%) 작아지고 바로 돌아온다.
  const Pressable({
    required this.onTap,
    required this.child,
    this.pressedScale = 0.95,
    this.pressedOpacity = 1,
    this.haptic = HapticFeedback.selectionClick,
    this.releaseCurve = Curves.easeOut,
    this.releaseDuration = const Duration(milliseconds: 110),
    this.enabled = true,
    super.key,
  });

  /// 탭은 안쪽 버튼(ElevatedButton·IconButton 등)이 처리하고, 이건 눌리는 모양과
  /// 진동만 더한다. 버튼이 비활성이면 [enabled]를 false로 넘긴다.
  const Pressable.effect({
    required this.child,
    this.pressedScale = 0.95,
    this.enabled = true,
    super.key,
  }) : onTap = null,
       pressedOpacity = 1,
       haptic = HapticFeedback.selectionClick,
       releaseCurve = Curves.easeOut,
       releaseDuration = const Duration(milliseconds: 110);

  /// 원형 아이콘 버튼(뒤로가기·종·검색 등)용. 더 많이(82%) 작아지며 살짝 옅어지고, 손을 떼면
  /// 살짝 커졌다가 제자리로 튕기듯 돌아오며, 조금 더 또렷한 진동을 준다.
  const Pressable.icon({
    required this.onTap,
    required this.child,
    this.pressedScale = 0.82,
    this.pressedOpacity = 0.8,
    this.haptic = HapticFeedback.lightImpact,
    this.releaseCurve = Curves.easeOutBack,
    this.releaseDuration = const Duration(milliseconds: 260),
    this.enabled = true,
    super.key,
  });

  /// null이면 탭은 안쪽 위젯이 처리한다([Pressable.effect]).
  final VoidCallback? onTap;

  /// false면 눌림 효과·진동·탭을 모두 끈다.
  final bool enabled;
  final Widget child;
  final double pressedScale;
  final double pressedOpacity;
  final Future<void> Function() haptic;
  final Curve releaseCurve;
  final Duration releaseDuration;

  @override
  State<Pressable> createState() => PressableState();
}

class PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  static const _pressDuration = Duration(milliseconds: 90);

  /// 아주 짧게 톡 쳐도 눌린 모양이 보이도록 최소한 이만큼은 눌린 채로 둔다.
  static const _minPressed = Duration(milliseconds: 150);

  bool _pressed = false;

  /// 이번 누름의 번호. 손을 떼기 전에 다시 누르면 앞선 누름의 해제는 무시한다.
  int _press = 0;

  // 시계 대신 화면 애니메이션으로 최소 유지 시간을 잰다(테스트에서도 그대로 흐른다).
  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: _minPressed,
  );

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  /// 안쪽 [Pressable]이 이번 손가락을 가져갔으면 true(손을 떼면 풀린다).
  bool _blockedByInner = false;

  void _setPressed(bool value) {
    if (_pressed != value && mounted) setState(() => _pressed = value);
  }

  // 탭으로 확정될 때(손을 뗀 뒤)가 아니라 손가락이 닿는 즉시 눌린 모양을 보여준다.
  void _down() {
    context.findAncestorStateOfType<PressableState>()?._blockedByInner = true;
    if (_blockedByInner) return;
    _press++;
    _hold.forward(from: 0);
    _setPressed(true);
  }

  Future<void> _up() async {
    _blockedByInner = false;
    if (!_pressed) return;
    final press = _press;
    try {
      await _hold.forward().orCancel;
    } on TickerCanceled {
      return;
    }
    if (press == _press) _setPressed(false);
  }

  // 스크롤 등으로 탭이 취소되면 바로 푼다.
  void _cancel() {
    _blockedByInner = false;
    _press++;
    _hold.stop();
    _setPressed(false);
  }

  @override
  Widget build(BuildContext context) {
    final duration = _pressed ? _pressDuration : widget.releaseDuration;
    final curve = _pressed ? Curves.easeOut : widget.releaseCurve;
    final onTap = widget.onTap;
    final visual = AnimatedScale(
      scale: _pressed ? widget.pressedScale : 1,
      duration: duration,
      curve: curve,
      child: AnimatedOpacity(
        opacity: _pressed ? widget.pressedOpacity : 1,
        duration: duration,
        curve: curve,
        child: widget.child,
      ),
    );
    if (!widget.enabled) return visual;
    return Listener(
      onPointerDown: (_) {
        _down();
        // 탭을 안쪽 버튼이 처리하는 경우엔 탭이 끝났는지 알 수 없어 닿는 순간 진동한다.
        if (onTap == null && _pressed) widget.haptic();
      },
      onPointerUp: (_) => _up(),
      onPointerCancel: (_) => _cancel(),
      child: onTap == null
          ? visual
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapCancel: _cancel,
              onTap: () {
                widget.haptic();
                onTap();
              },
              child: visual,
            ),
    );
  }
}
