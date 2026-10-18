import 'package:flutter/material.dart';

import '../../../services/class_schedule_parser.dart';
import '../../../utils/time_format.dart';
import '../../../utils/weekday_labels.dart';
import '../course_filters.dart';
import '../timetable_colors.dart';
import 'timetable_grid.dart' show PendingSlot;

const List<Weekday> _weekdayChipValues = [
  Weekday.mon,
  Weekday.tue,
  Weekday.wed,
  Weekday.thu,
  Weekday.fri,
];

/// 검색창 + 필터 토글 + (펼쳤을 때) 필터 패널 + 활성 필터 칩 로우.
class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({
    required this.controller,
    this.focusNode,
    required this.onQueryChanged,
    required this.filters,
    required this.filterPanelOpen,
    required this.onToggleFilterPanel,
    required this.onFiltersChanged,
    required this.availableGrades,
    required this.availableCourseTypes,
    required this.availableCredits,
    required this.availableAreas,
    required this.pendingSlot,
    required this.onClearPendingSlot,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String> onQueryChanged;
  final CourseFilters filters;
  final bool filterPanelOpen;
  final VoidCallback onToggleFilterPanel;
  final VoidCallback onFiltersChanged;
  final List<String> availableGrades;
  final List<String> availableCourseTypes;
  final List<double> availableCredits;

  /// 이수구분 문자열에서 뽑아낸 "N영역" 값 목록(예: ['1','2','3','4']).
  /// [CourseFilters.extractArea] 참고 — 추정 로직이라 실제 데이터에 없는
  /// 값은 여기도 안 나온다.
  final List<String> availableAreas;
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
                  focusNode: focusNode,
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
                  color: filterPanelOpen
                      ? TimetableColors.accent
                      : TimetableColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.tune,
                  color: filterPanelOpen
                      ? Colors.white
                      : TimetableColors.textSecondary,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        if (filterPanelOpen) ...[
          const SizedBox(height: 10),
          _buildFilterOptionsRow(),
        ],
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
          weekdayLabelsWeekdaysOnly[_weekdayChipValues.indexOf(pendingSlot!.day)];
      chips.add(
        _ActiveChip(
          label:
              '$label ${formatMinutesAsTime(pendingSlot!.startMinutes)}'
              '~${formatMinutesAsTime(pendingSlot!.endMinutes)}',
          onClear: onClearPendingSlot,
        ),
      );
    }
    if (filters.day != null) {
      final label =
          weekdayLabelsWeekdaysOnly[_weekdayChipValues.indexOf(filters.day!)];
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
          label: filters.grade!,
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
    for (final area in filters.areas) {
      chips.add(
        _ActiveChip(
          label: '$area영역',
          onClear: () {
            filters.areas.remove(area);
            onFiltersChanged();
          },
        ),
      );
    }
    if (filters.onlineOnly) {
      chips.add(
        _ActiveChip(
          label: '온라인',
          onClear: () {
            filters.onlineOnly = false;
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
          _FilterDropdownChip<Weekday?>(
            label: '요일',
            selectedLabel: filters.day == null
                ? null
                : weekdayLabelsWeekdaysOnly[_weekdayChipValues.indexOf(filters.day!)],
            options: [
              const _DropdownOption(null, '전체'),
              for (var i = 0; i < _weekdayChipValues.length; i++)
                _DropdownOption(_weekdayChipValues[i], weekdayLabelsWeekdaysOnly[i]),
            ],
            onSelected: (value) {
              filters.day = value;
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
          const SizedBox(width: 8),
          _AreaFilterChip(
            selectedAreas: filters.areas,
            availableAreas: availableAreas,
            onChanged: (areas) {
              filters.areas = areas;
              onFiltersChanged();
            },
          ),
          const SizedBox(width: 8),
          _ToggleFilterChip(
            label: '온라인',
            selected: filters.onlineOnly,
            onTap: () {
              filters.onlineOnly = !filters.onlineOnly;
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
          '${formatMinutesAsTime(filters.timeRange.start.toInt())}~'
          '${formatMinutesAsTime(filters.timeRange.end.toInt())}',
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

/// 단순 켜짐/꺼짐 토글 칩(온라인) — 드롭다운 없이 탭할 때마다 뒤집힌다.
class _ToggleFilterChip extends StatelessWidget {
  const _ToggleFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? TimetableColors.accent : TimetableColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : TimetableColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// "영역" 필터 칩 — Figma 시안(node-id=6-33)처럼 체크박스 여러 개를 동시에
/// 켤 수 있는 팝업을 띄운다. 체크박스를 눌러도 팝업이 바로 닫히지 않도록
/// (한 번에 여러 영역을 고를 수 있어야 하므로) [StatefulBuilder]로 팝업
/// 내부에서만 다시 그린다.
class _AreaFilterChip extends StatelessWidget {
  const _AreaFilterChip({
    required this.selectedAreas,
    required this.availableAreas,
    required this.onChanged,
  });

  final Set<String> selectedAreas;
  final List<String> availableAreas;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final isActive = selectedAreas.isNotEmpty;
    return PopupMenuButton<void>(
      color: TimetableColors.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) {
        // 메뉴가 열려 있는 동안엔 바깥(StatelessWidget)이 다시 그려져도 이미
        // 띄운 팝업엔 반영이 안 된다 — 팝업이 열릴 때 한 번만 복사해서, 그
        // 안에서는 이 로컬 복사본만 계속 고쳐 쓴다.
        final selected = {...selectedAreas};
        return [
          PopupMenuItem<void>(
            padding: EdgeInsets.zero,
            child: StatefulBuilder(
              builder: (context, setMenuState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final area in availableAreas)
                      CheckboxListTile(
                        value: selected.contains(area),
                        title: Text(
                          '$area영역',
                          style: const TextStyle(
                            color: TimetableColors.textPrimary,
                          ),
                        ),
                        activeColor: TimetableColors.accent,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (checked) {
                          if (checked == true) {
                            selected.add(area);
                          } else {
                            selected.remove(area);
                          }
                          setMenuState(() {});
                          onChanged({...selected});
                        },
                      ),
                  ],
                );
              },
            ),
          ),
        ];
      },
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
              '영역',
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
