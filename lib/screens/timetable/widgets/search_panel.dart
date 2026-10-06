import 'package:flutter/material.dart';

import '../../../services/class_schedule_parser.dart';
import '../course_filters.dart';
import '../timetable_colors.dart';
import 'timetable_grid.dart' show PendingSlot;

const List<String> _weekdayChipLabels = ['월', '화', '수', '목', '금'];
const List<Weekday> _weekdayChipValues = [
  Weekday.mon,
  Weekday.tue,
  Weekday.wed,
  Weekday.thu,
  Weekday.fri,
];

String _formatMinutes(double minutes) {
  final h = (minutes ~/ 60).toString().padLeft(2, '0');
  final m = (minutes % 60).toInt().toString().padLeft(2, '0');
  return '$h:$m';
}

/// 검색창 + 필터 토글 + (펼쳤을 때) 필터 패널 + 활성 필터 칩 로우.
class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({
    required this.controller,
    required this.onQueryChanged,
    required this.filters,
    required this.filterPanelOpen,
    required this.onToggleFilterPanel,
    required this.onFiltersChanged,
    required this.availableGrades,
    required this.availableCourseTypes,
    required this.availableCredits,
    required this.pendingSlot,
    required this.onClearPendingSlot,
  });

  final TextEditingController controller;
  final ValueChanged<String> onQueryChanged;
  final CourseFilters filters;
  final bool filterPanelOpen;
  final VoidCallback onToggleFilterPanel;
  final VoidCallback onFiltersChanged;
  final List<String> availableGrades;
  final List<String> availableCourseTypes;
  final List<double> availableCredits;
  final PendingSlot? pendingSlot;
  final VoidCallback onClearPendingSlot;

  @override
  Widget build(BuildContext context) {
    final activeChips = _buildActiveFilterChips();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: TimetableColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: controller,
                  onChanged: onQueryChanged,
                  style: const TextStyle(color: TimetableColors.textPrimary),
                  decoration: const InputDecoration(
                    icon: Padding(
                      padding: EdgeInsets.only(left: 14),
                      child: Icon(
                        Icons.search,
                        color: TimetableColors.textSecondary,
                      ),
                    ),
                    hintText: '과목코드, 교수명, 과목명 검색',
                    hintStyle: TextStyle(color: TimetableColors.textSecondary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onToggleFilterPanel,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: TimetableColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.tune, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
        if (activeChips.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: activeChips,
            ),
          ),
        ],
        if (filterPanelOpen) ...[
          const SizedBox(height: 10),
          _buildFilterOptionsRow(),
          const SizedBox(height: 14),
          _buildTimeRangeSlider(),
        ],
      ],
    );
  }

  List<Widget> _buildActiveFilterChips() {
    final chips = <Widget>[];

    if (pendingSlot != null) {
      final label =
          _weekdayChipLabels[_weekdayChipValues.indexOf(pendingSlot!.day)];
      chips.add(
        _ActiveChip(
          label:
              '$label ${_formatMinutes(pendingSlot!.startMinutes.toDouble())}'
              '~${_formatMinutes(pendingSlot!.endMinutes.toDouble())}',
          onClear: onClearPendingSlot,
        ),
      );
    }
    if (filters.day != null) {
      final label =
          _weekdayChipLabels[_weekdayChipValues.indexOf(filters.day!)];
      chips.add(
        _ActiveChip(
          label: '$label요일',
          onClear: () {
            filters.day = null;
            onFiltersChanged();
          },
        ),
      );
    }
    if (filters.grade != null) {
      chips.add(
        _ActiveChip(
          label: '${filters.grade}학년',
          onClear: () {
            filters.grade = null;
            onFiltersChanged();
          },
        ),
      );
    }
    if (filters.courseType != null) {
      chips.add(
        _ActiveChip(
          label: filters.courseType!,
          onClear: () {
            filters.courseType = null;
            onFiltersChanged();
          },
        ),
      );
    }
    if (filters.credit != null) {
      chips.add(
        _ActiveChip(
          label: '${filters.credit}학점',
          onClear: () {
            filters.credit = null;
            onFiltersChanged();
          },
        ),
      );
    }

    return chips;
  }

  Widget _buildFilterOptionsRow() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterDropdownChip<Weekday?>(
            label: '요일',
            selectedLabel: filters.day == null
                ? null
                : _weekdayChipLabels[_weekdayChipValues.indexOf(filters.day!)],
            options: [
              const _DropdownOption(null, '전체'),
              for (var i = 0; i < _weekdayChipValues.length; i++)
                _DropdownOption(_weekdayChipValues[i], _weekdayChipLabels[i]),
            ],
            onSelected: (value) {
              filters.day = value;
              onFiltersChanged();
            },
          ),
          const SizedBox(width: 8),
          _FilterDropdownChip<String?>(
            label: '학년',
            selectedLabel: filters.grade,
            options: [
              const _DropdownOption(null, '전체'),
              for (final g in availableGrades) _DropdownOption(g, g),
            ],
            onSelected: (value) {
              filters.grade = value;
              onFiltersChanged();
            },
          ),
          const SizedBox(width: 8),
          _FilterDropdownChip<String?>(
            label: '이수구분',
            selectedLabel: filters.courseType,
            options: [
              const _DropdownOption(null, '전체'),
              for (final t in availableCourseTypes) _DropdownOption(t, t),
            ],
            onSelected: (value) {
              filters.courseType = value;
              onFiltersChanged();
            },
          ),
          const SizedBox(width: 8),
          _FilterDropdownChip<double?>(
            label: '학점',
            selectedLabel: filters.credit == null ? null : '${filters.credit}',
            options: [
              const _DropdownOption(null, '전체'),
              for (final c in availableCredits) _DropdownOption(c, '$c'),
            ],
            onSelected: (value) {
              filters.credit = value;
              onFiltersChanged();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSlider() {
    return Row(
      children: [
        const Text(
          '시간',
          style: TextStyle(color: TimetableColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RangeSlider(
            values: filters.timeRange,
            min: 8 * 60,
            max: 22 * 60,
            activeColor: TimetableColors.accent,
            inactiveColor: TimetableColors.surfaceElevated,
            onChanged: (values) {
              filters.timeRange = values;
              onFiltersChanged();
            },
          ),
        ),
        Text(
          '${_formatMinutes(filters.timeRange.start)}~${_formatMinutes(filters.timeRange.end)}',
          style: const TextStyle(
            color: TimetableColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({required this.label, required this.onClear});

  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: TimetableColors.accent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close, color: Colors.white, size: 14),
          ),
        ],
      ),
    );
  }
}

class _DropdownOption<T> {
  const _DropdownOption(this.value, this.label);
  final T value;
  final String label;
}

class _FilterDropdownChip<T> extends StatelessWidget {
  const _FilterDropdownChip({
    required this.label,
    required this.selectedLabel,
    required this.options,
    required this.onSelected,
  });

  final String label;
  final String? selectedLabel;
  final List<_DropdownOption<T>> options;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final isActive = selectedLabel != null;
    return PopupMenuButton<T>(
      color: TimetableColors.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final option in options)
          PopupMenuItem<T>(
            value: option.value,
            child: Text(
              option.label,
              style: const TextStyle(color: TimetableColors.textPrimary),
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? TimetableColors.accent : TimetableColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isActive ? selectedLabel! : label,
              style: TextStyle(
                color: isActive ? Colors.white : TimetableColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: isActive ? Colors.white : TimetableColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
