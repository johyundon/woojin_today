import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// shot4/shot6/shot7 스타일 iOS풍 시/분 휠 피커.
///
/// 가운데 값만 굵고 크게, 위아래 값은 흐린 회색으로 보이는 걸 재현하기 위해
/// [ListWheelScrollView]를 쓰되 기본 선택 하이라이트 박스는 쓰지 않고
/// (스크린샷에 그런 배경 박스가 없다) 텍스트 스타일만 가운데 기준 거리로 바꾼다.
class TimeWheelPicker extends StatefulWidget {
  const TimeWheelPicker({
    required this.initialTime,
    required this.onChanged,
    super.key,
  });

  final TimeOfDay initialTime;
  final ValueChanged<TimeOfDay> onChanged;

  @override
  State<TimeWheelPicker> createState() => _TimeWheelPickerState();
}

class _TimeWheelPickerState extends State<TimeWheelPicker> {
  late int _hour = widget.initialTime.hour;
  late int _minute = widget.initialTime.minute;

  void _emitChange() {
    widget.onChanged(TimeOfDay(hour: _hour, minute: _minute));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Row(
        children: [
          Expanded(
            child: _WheelColumn(
              itemCount: 24,
              initialIndex: _hour,
              labelBuilder: (i) => '${i.toString().padLeft(2, '0')}시',
              onSelectedItemChanged: (i) {
                setState(() => _hour = i);
                _emitChange();
              },
            ),
          ),
          Expanded(
            child: _WheelColumn(
              itemCount: 60,
              initialIndex: _minute,
              labelBuilder: (i) => '${i.toString().padLeft(2, '0')}분',
              onSelectedItemChanged: (i) {
                setState(() => _minute = i);
                _emitChange();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WheelColumn extends StatefulWidget {
  const _WheelColumn({
    required this.itemCount,
    required this.initialIndex,
    required this.labelBuilder,
    required this.onSelectedItemChanged,
  });

  final int itemCount;
  final int initialIndex;
  final String Function(int index) labelBuilder;
  final ValueChanged<int> onSelectedItemChanged;

  @override
  State<_WheelColumn> createState() => _WheelColumnState();
}

class _WheelColumnState extends State<_WheelColumn> {
  late int _selectedIndex = widget.initialIndex;
  late final FixedExtentScrollController _controller =
      FixedExtentScrollController(initialItem: widget.initialIndex);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView.useDelegate(
      controller: _controller,
      itemExtent: 36,
      diameterRatio: 2.2,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (i) {
        setState(() => _selectedIndex = i);
        widget.onSelectedItemChanged(i);
      },
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: widget.itemCount,
        builder: (context, index) {
          final distance = (index - _selectedIndex).abs();
          final isSelected = distance == 0;
          return Center(
            child: Text(
              widget.labelBuilder(index),
              style: TextStyle(
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontSize: isSelected ? 22 : 16,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w400,
              ),
            ),
          );
        },
      ),
    );
  }
}
