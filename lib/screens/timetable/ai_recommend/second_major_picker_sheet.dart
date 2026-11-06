import 'package:flutter/material.dart';

import '../../../services/department_codes.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';

/// 자동 생성 설문 4단계에서 타전공(복수전공) 학과를 고르는 아래 시트.
///
/// 고른 학과 이름을 돌려준다. "선택 안 함"을 누르면 빈 문자열을, 그냥 닫으면
/// null을 돌려준다(호출부가 둘을 구분해 처리한다).
Future<String?> showSecondMajorPickerSheet(
  BuildContext context, {
  String? current,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _SecondMajorPickerSheet(current: current),
  );
}

class _SecondMajorPickerSheet extends StatefulWidget {
  const _SecondMajorPickerSheet({this.current});

  final String? current;

  @override
  State<_SecondMajorPickerSheet> createState() =>
      _SecondMajorPickerSheetState();
}

class _SecondMajorPickerSheetState extends State<_SecondMajorPickerSheet> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final names =
        kDepartmentCodes.keys
            .where((n) => _query.isEmpty || n.contains(_query))
            .toList()
          ..sort();
    final height = MediaQuery.of(context).size.height * 0.75;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE0E4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 20, 22, 4),
              child: Text(
                '타전공(복수전공) 학과',
                style: TextStyle(
                  color: AppColors.textStrong,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 0, 22, 14),
              child: Text(
                '고른 학과 전공을 타전공으로 담아요',
                style: TextStyle(color: AppColors.textSub, fontSize: 13),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _controller,
                onChanged: (v) => setState(() => _query = v.trim()),
                style: const TextStyle(
                  color: AppColors.textStrong,
                  fontSize: 15,
                ),
                cursorColor: AppColors.blue,
                decoration: InputDecoration(
                  hintText: '학과 이름 검색',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textSub,
                  ),
                  filled: true,
                  fillColor: AppColors.fill,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                children: [
                  _Row(
                    label: '선택 안 함',
                    selected: widget.current == null || widget.current!.isEmpty,
                    muted: true,
                    onTap: () => Navigator.of(context).pop(''),
                  ),
                  for (final name in names)
                    _Row(
                      label: name,
                      selected: widget.current == name,
                      onTap: () => Navigator.of(context).pop(name),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.selected,
    required this.onTap,
    this.muted = false,
  });

  final String label;
  final bool selected;
  final bool muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Pressable(
        pressedScale: 0.98,
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? AppColors.blueSoft : AppColors.fill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.blue : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? AppColors.blueText
                        : muted
                        ? AppColors.textSub
                        : AppColors.textStrong,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_rounded,
                  color: AppColors.blue,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
