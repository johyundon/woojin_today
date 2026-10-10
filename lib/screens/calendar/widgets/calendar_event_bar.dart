import 'package:flutter/material.dart';

import '../models/calendar_event.dart';

/// 여러 날짜 칸을 가로지르는 일정 막대 하나. 칸 너비보다 제목이 길면
/// 말줄임(...)된다(구글 캘린더 월간뷰 방식). 탭하면 이 막대가 걸쳐있는
/// 날짜가 선택되어, 날짜 칸을 탭했을 때와 똑같이 하단 일정 목록에 뜬다.
class CalendarEventBar extends StatelessWidget {
  const CalendarEventBar({required this.event, required this.onTap, super.key});

  final CalendarEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 20,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: event.color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          event.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
