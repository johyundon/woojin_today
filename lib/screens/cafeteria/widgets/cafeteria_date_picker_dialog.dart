import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../widgets/pressable.dart';
import '../cafeteria_colors.dart';

/// "날짜 선택" 팝업 (Figma node 6:71). 년/월/일 3열 휠 — 전부 숫자 뒤에
/// 한글 단위("2026년", "9월", "7일")를 직접 붙인다. 앱 전체에 한국어
/// 로케일(`flutter_localizations`)이 설정돼 있지 않아 `CupertinoDatePicker`를
/// 쓰면 영어로 나오고 월/일/년 순서가 돼버려서(이전 구현의 문제), 로케일에
/// 기대지 않는 커스텀 휠로 직접 그린다.
/// "확인"을 누르면 선택된 날짜를, "취소"면 null을 돌려준다.
Future<DateTime?> showCafeteriaDatePickerDialog(
  BuildContext context, {
  required DateTime initialDate,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (_) => _CafeteriaDatePickerDialog(initialDate: initialDate),
  );
}

/// 연도 휠에 보여줄 범위(선택된 연도 기준 앞뒤 몇 년).
const int _yearsBefore = 3;
const int _yearsAfter = 3;

class _CafeteriaDatePickerDialog extends StatefulWidget {
  const _CafeteriaDatePickerDialog({required this.initialDate});

  final DateTime initialDate;

  @override
  State<_CafeteriaDatePickerDialog> createState() =>
      _CafeteriaDatePickerDialogState();
}

class _CafeteriaDatePickerDialogState
    extends State<_CafeteriaDatePickerDialog> {
  late int _year;
  late int _month;
  late int _day;
  late List<int> _years;

  late final FixedExtentScrollController _yearController;
  late final FixedExtentScrollController _monthController;
  late final FixedExtentScrollController _dayController;

  @override
  void initState() {
    super.initState();
    _year = widget.initialDate.year;
    _month = widget.initialDate.month;
    _day = widget.initialDate.day;
    _years = [
      for (var y = _year - _yearsBefore; y <= _year + _yearsAfter; y++) y,
    ];

    _yearController = FixedExtentScrollController(
      initialItem: _years.indexOf(_year),
    );
    _monthController = FixedExtentScrollController(initialItem: _month - 1);
    _dayController = FixedExtentScrollController(initialItem: _day - 1);
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  int get _daysInSelectedMonth => DateUtils.getDaysInMonth(_year, _month);

  /// 월/연도가 바뀌어 지금 선택된 일(day)이 그 달에 없으면(예: 31일 →
  /// 2월) 그 달의 마지막 날로 당겨서 휠도 같이 넘겨준다.
  void _clampDayIfNeeded() {
    final maxDay = _daysInSelectedMonth;
    if (_day <= maxDay) return;
    _day = maxDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_dayController.hasClients) _dayController.jumpToItem(_day - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: CafeteriaColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '날짜 선택',
              style: TextStyle(
                color: CafeteriaColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    child: _WheelColumn(
                      controller: _yearController,
                      itemCount: _years.length,
                      labelBuilder: (i) => '${_years[i]}년',
                      isSelected: (i) => _years[i] == _year,
                      onChanged: (i) => setState(() {
                        _year = _years[i];
                        _clampDayIfNeeded();
                      }),
                    ),
                  ),
                  Expanded(
                    child: _WheelColumn(
                      controller: _monthController,
                      itemCount: 12,
                      labelBuilder: (i) => '${i + 1}월',
                      isSelected: (i) => i + 1 == _month,
                      onChanged: (i) => setState(() {
                        _month = i + 1;
                        _clampDayIfNeeded();
                      }),
                    ),
                  ),
                  Expanded(
                    child: _WheelColumn(
                      controller: _dayController,
                      itemCount: _daysInSelectedMonth,
                      labelBuilder: (i) => '${i + 1}일',
                      isSelected: (i) => i + 1 == _day,
                      onChanged: (i) => setState(() => _day = i + 1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Pressable.effect(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CafeteriaColors.textPrimary,
                      side: const BorderSide(color: CafeteriaColors.border),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 13,
                      ),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Pressable.effect(
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.of(context)
                            .pop(DateTime(_year, _month, _day)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CafeteriaColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 13,
                      ),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 휠 한 열. 가운데(선택된) 값만 크고 굵은 흰 글씨, 나머지는 작고 흐린
/// 회색 — Figma의 "가운데 값이 강조되는 숫자 휠" 느낌을 낸다.
class _WheelColumn extends StatelessWidget {
  const _WheelColumn({
    required this.controller,
    required this.itemCount,
    required this.labelBuilder,
    required this.isSelected,
    required this.onChanged,
  });

  final FixedExtentScrollController controller;
  final int itemCount;
  final String Function(int index) labelBuilder;
  final bool Function(int index) isSelected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return CupertinoPicker(
      scrollController: controller,
      itemExtent: 36,
      selectionOverlay: const SizedBox.shrink(),
      onSelectedItemChanged: onChanged,
      children: [
        for (var i = 0; i < itemCount; i++)
          Center(
            child: Text(
              labelBuilder(i),
              style: isSelected(i)
                  ? const TextStyle(
                      color: CafeteriaColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    )
                  : const TextStyle(
                      color: CafeteriaColors.textSecondary,
                      fontSize: 20,
                    ),
            ),
          ),
      ],
    );
  }
}
