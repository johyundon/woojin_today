import 'package:flutter/material.dart';

import '../../../widgets/pressable.dart';
import '../timetable_colors.dart';

/// "내 시간표 불러오기" 결과 중 그리드 위에 따로 알려야 하는 상태.
/// 불러오는 중에는 버튼 안 스피너로 보여주므로 여기엔 없다.
enum MyTimetableStatus { idle, empty, failed }

/// 버튼 줄 바로 아래에 붙는 한 줄 안내. [MyTimetableStatus.idle]이면 아무것도
/// 그리지 않는다.
class MyTimetableStatusBar extends StatelessWidget {
  const MyTimetableStatusBar({
    super.key,
    required this.status,
    required this.onRetry,
    this.semesterWord = '이번 학기',
  });

  final MyTimetableStatus status;
  final VoidCallback onRetry;

  /// 빈 상태 안내에 쓸 학기 이름("이번 학기"/"지난 학기"/"다음 학기").
  final String semesterWord;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MyTimetableStatus.idle:
        return const SizedBox.shrink();
      case MyTimetableStatus.empty:
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              const Icon(
                Icons.event_busy_outlined,
                size: 16,
                color: TimetableColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$semesterWord에 수강신청한 과목이 없어요.',
                  style: const TextStyle(
                    color: TimetableColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
      case MyTimetableStatus.failed:
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              const Icon(
                Icons.error_outline,
                size: 16,
                color: TimetableColors.textSecondary,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  '내 시간표를 불러오지 못했어요.',
                  style: TextStyle(
                    color: TimetableColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              Pressable.effect(
                child: TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    foregroundColor: TimetableColors.accent,
                  ),
                  child: const Text('다시 시도'),
                ),
              ),
            ],
          ),
        );
    }
  }
}
