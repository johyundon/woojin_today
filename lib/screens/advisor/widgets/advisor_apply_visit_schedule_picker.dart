import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
import '../services/advisor_consultation_mock_data.dart';
import 'advisor_load_states.dart';
import 'advisor_visit_calendar.dart';

const Color _mutedText = Color(0xFF7C7B88);
const Color _chipBackground = Color(0xFFF1F0F7);

/// 방문 상담의 날짜·시간 선택 영역(캘린더 + 날짜를 고르면 나타나는 시간
/// 칩 목록). [AdvisorMethodAndScheduleStep]에서 쓴다. [times]는 고른 날짜에
/// T-WIN이 "상담 가능"으로 알려준 시간이다(날짜를 고를 때 그 주를 조회).
class AdvisorVisitSchedulePicker extends StatelessWidget {
  const AdvisorVisitSchedulePicker({
    super.key,
    required this.times,
    required this.timesLoading,
    required this.timesError,
    required this.onRetryTimes,
    required this.selectedVisitDate,
    required this.selectedVisitTime,
    required this.onSelectVisitDate,
    required this.onSelectVisitTime,
  });

  final List<String> times;
  final bool timesLoading;
  final String? timesError;
  final VoidCallback onRetryTimes;
  final DateTime? selectedVisitDate;
  final String? selectedVisitTime;
  final ValueChanged<DateTime> onSelectVisitDate;
  final ValueChanged<String> onSelectVisitTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _chipBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: AdvisorVisitCalendar(
            selectedDate: selectedVisitDate,
            onDateSelected: onSelectVisitDate,
            minDate: AdvisorConsultationMockData.visitBookingWindowStart(),
            maxDate: AdvisorConsultationMockData.visitBookingWindowEnd(),
          ),
        ),
        const SizedBox(height: 10),
        if (selectedVisitDate == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '날짜를 먼저 선택해주세요',
              style: TextStyle(
                color: _mutedText,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else if (timesLoading)
          const AdvisorLoadingBox(label: '상담 가능한 시간을 확인하는 중...')
        else if (timesError != null)
          AdvisorErrorBox(message: timesError!, onRetry: onRetryTimes)
        else if (times.isEmpty)
          const AdvisorEmptyText('이 날은 상담 가능한 시간이 없어요.\n다른 날짜를 골라 주세요.')
        else
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.2,
            children: [
              for (final t in times)
                _TimeChip(
                  time: t,
                  selected: selectedVisitTime == t,
                  onTap: () => onSelectVisitTime(t),
                ),
            ],
          ),
      ],
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.time,
    required this.selected,
    required this.onTap,
  });

  final String time;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      key: ValueKey('visit-time-$time'),
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.cobalt : _chipBackground,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          time,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.ink,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// 앞으로 3개월 안에 예약 가능한 방문 시간이 없을 때 보여주는 안내 영역.
/// 학교는 한 주씩만 알려줘서 3개월치를 다 확인하려면 요청이 13번 넘게
/// 나가므로, 지금은 쓰지 않고(날짜별 "이 날은 없어요" 안내로 대신) 코드만
/// 남겨 둔다.
class AdvisorNoVisitSlotsNotice extends StatelessWidget {
  const AdvisorNoVisitSlotsNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: _chipBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.event_busy_rounded, size: 28, color: _mutedText),
          SizedBox(height: 6),
          Text(
            '앞으로 3개월 안에 상담 가능한 시간이 없어요',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _mutedText,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
