import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 알림 종 아이콘. [active]가 꺼짐에서 켜짐으로 바뀌는 순간(또는 [playOnStart]면
/// 처음 나타날 때) 종이 위쪽 고리를 축으로 좌우로 흔들리며 점점 잦아드는 "울리는"
/// 애니메이션을 한 번 재생한다. 켜져 있는 채로 화면이 다시 그려지기만 할 때는
/// 울리지 않고, 도중에 꺼지면 바로 멈춘다.
class RingingBell extends StatefulWidget {
  const RingingBell({
    required this.active,
    required this.size,
    required this.activeColor,
    required this.inactiveColor,
    this.playOnStart = false,
    super.key,
  });

  final bool active;
  final double size;
  final Color activeColor;
  final Color inactiveColor;

  /// true면 처음 나타날 때도(켜져 있다면) 한 번 울린다. 안내 팝업의 큰 종처럼
  /// "방금 켜졌다"는 걸 보여줄 때 쓴다.
  final bool playOnStart;

  @override
  State<RingingBell> createState() => _RingingBellState();
}

class _RingingBellState extends State<RingingBell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active && widget.playOnStart) _controller.forward();
  }

  @override
  void didUpdateWidget(RingingBell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _controller.forward(from: 0);
    } else if (!widget.active && oldWidget.active) {
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 흔들림 각도(라디안). 4번 왕복하면서 점점 작아진다.
  static double _angle(double t) =>
      math.sin(t * 2 * math.pi * 4) * 0.5 * (1 - t);

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      widget.active ? Icons.notifications_active : Icons.notifications_none,
      size: widget.size,
      color: widget.active ? widget.activeColor : widget.inactiveColor,
    );
    return AnimatedBuilder(
      animation: _controller,
      child: icon,
      builder: (context, child) => Transform.rotate(
        angle: _angle(_controller.value),
        alignment: Alignment.topCenter,
        child: child,
      ),
    );
  }
}
