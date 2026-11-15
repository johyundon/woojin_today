import 'package:flutter/cupertino.dart';

/// 화면을 넘길 때 밀려 들어오는 움직임 없이 바로 바꾸는 전환(사용자 요청,
/// 2026-11-15). 열기·닫기는 0초라 즉시 바뀐다.
///
/// iOS 기본 전환([CupertinoPageTransitionsBuilder])을 그대로 쓰되 걸리는
/// 시간만 0으로 만든다. 그래서 화면 왼쪽 끝을 쓸어서 뒤로 가는 동작은
/// 남는다(쓰는 동안만 화면이 손가락을 따라 밀린다).
class InstantPageTransitionsBuilder extends CupertinoPageTransitionsBuilder {
  const InstantPageTransitionsBuilder();

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;
}
