import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// "일정 이름으로 검색" 검색바. 검색 로직은 아직 없고(TODO) UI만 둔다.
class CalendarSearchBar extends StatelessWidget {
  const CalendarSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        // TODO: 일정 검색 로직 연동 (현재는 UI만).
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: const InputDecoration(
          icon: Padding(
            padding: EdgeInsets.only(left: 14),
            child: Icon(Icons.search, color: AppColors.textSecondary),
          ),
          hintText: '일정 이름으로 검색',
          hintStyle: TextStyle(color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        ),
      ),
    );
  }
}
