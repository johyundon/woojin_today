import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../services/advisor_consultation_mock_data.dart';
import 'advisor_visit_calendar.dart';

const Color _mutedText = Color(0xFF7C7B88);
const Color _chipBackground = Color(0xFFF1F0F7);

/// 방문 상담의 날짜·시간 선택 영역(캘린더 + 날짜를 고르면 나타나는 시간
/// 칩 목록). [AdvisorMethodAndScheduleStep]에서 쓴다.
class AdvisorVisitSchedulePicker extends StatelessWidget {
  const AdvisorVisitSchedulePicker({
    super.key,
    required this.times,
    required this.selectedVisitDate,
    required this.selectedVisitTime,
    required this.onSelectVisitDate,
    required this.onSelectVisitTime,
  });

  final List<String> times;
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
    return GestureDetector(
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

/// 앞으로 예약 가능한 방문 시간이 없을 때(= [AdvisorConsultationMockData]의
/// 목데이터가 비었을 때) 보여주는 안내 영역.
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
