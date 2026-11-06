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
  });

  final Widget searchFilterBar;
  final Widget results;
  final VoidCallback onClose;

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
            onVerticalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0) > 0) onClose();
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
