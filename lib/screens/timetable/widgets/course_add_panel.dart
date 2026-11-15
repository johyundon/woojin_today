import 'package:flutter/material.dart';

import '../timetable_colors.dart';

/// "과목 추가"를 눌렀을 때 시간표 아래에서 올라오는 패널의 틀.
///
/// 맨 위 손잡이(아래로 쓸어내리면 [onClose]) → [searchFilterBar] → [results]
/// 순서로 쌓기만 한다. 검색/필터/결과 목록의 실제 내용은 화면 상태를 읽어야
/// 해서 호출부가 만들어 넘긴다.
class CourseAddPanel extends StatelessWidget {
  const CourseAddPanel({
    super.key,
    required this.searchFilterBar,
    required this.results,
    required this.onClose,
    this.onHandleDragUpdate,
    this.onHandleDragEnd,
    this.headerScrollable = false,
  });

  final Widget searchFilterBar;
  final Widget results;
  final VoidCallback onClose;

  /// 손잡이를 끄는 동안의 세로 이동량(아래가 +). 있으면 손잡이로 시트 높이를
  /// 바꾸고(시안: 최소~최대), 없으면 예전처럼 아래로 쓸어내릴 때 [onClose].
  final ValueChanged<double>? onHandleDragUpdate;

  /// 손잡이 끌기를 놓았을 때의 세로 속도(아래가 +).
  final ValueChanged<double>? onHandleDragEnd;

  /// 필터를 펼쳐 [searchFilterBar]가 길어졌을 때 true. 그때만 그 부분을 스크롤되는
  /// 칸에 담아, 시트가 낮아도 넘치지 않고 밀어서 볼 수 있게 한다(평소엔 목록이
  /// 남는 높이를 다 쓴다).
  final bool headerScrollable;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: TimetableColors.panelBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: TimetableColors.sheetShadow,
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: onHandleDragUpdate == null
                ? null
                : (details) => onHandleDragUpdate!(details.primaryDelta ?? 0),
            onVerticalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              final onEnd = onHandleDragEnd;
              if (onEnd != null) {
                onEnd(velocity);
              } else if (velocity > 0) {
                onClose();
              }
            },
            child: const SizedBox(
              width: double.infinity,
              height: 27,
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: SizedBox(
                    width: 44,
                    height: 5,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: TimetableColors.handle,
                        borderRadius: BorderRadius.all(Radius.circular(3)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (headerScrollable)
            // 필터를 펼치면 이 부분이 길어진다. 시트가 낮을 때도 넘치지 않고 밀어서
            // 볼 수 있게 스크롤되는 칸에 담는다(사용자 지적, 2026-11-16).
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: searchFilterBar,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: searchFilterBar,
            ),
          const SizedBox(height: 12),
          Expanded(child: results),
        ],
      ),
    );
  }
}
