import 'package:flutter/widgets.dart';

/// 화면 폭이 이보다 넓으면 "넓은 화면"으로 보고 배치를 바꾼다(아이폰 듀오를
/// 펼친 화면 등). 아이폰 세로 화면은 모두 이보다 좁다(최대 440).
const double wideLayoutBreakpoint = 600;

/// 지금 화면이 넓은 화면인지(사용자 요청 2026-11-28: 펼친 듀오에서 양옆 공백
/// 없이 꽉 채우기).
bool isWideLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).width > wideLayoutBreakpoint;
