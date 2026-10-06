import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/student_id_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';
import 'student_id_result_screen.dart';

/// 학번 찾기 입력 화면 (Figma node 6:10).
/// 이름 / 휴대폰 번호 / 생년월일(휠 피커)을 입력받아 학번 찾기를 요청한다.
class StudentIdFindScreen extends StatefulWidget {
  const StudentIdFindScreen({super.key});

  @override
  State<StudentIdFindScreen> createState() => _StudentIdFindScreenState();
}

class _StudentIdFindScreenState extends State<StudentIdFindScreen> {
  final _nameController = TextEditingController();
  final _phonePrefixController = TextEditingController(text: '010');
  final _phoneMiddleController = TextEditingController();
  final _phoneLastController = TextEditingController();

  static final List<int> _years = List.generate(30, (i) => 2015 - i);
  static final List<int> _months = List.generate(12, (i) => i + 1);

  int _selectedYear = 2006;
  int _selectedMonth = 1;
  int _selectedDay = 1;

  /// 해당 연/월의 실제 마지막 날짜(윤년 2월 포함). day 0은 "전월의 마지막 날"을
  /// 돌려주는 [DateTime] 특성을 이용한 트릭이다.
  int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  /// 선택된 연/월에 맞춘 "일" 목록. 2월에 30일이 남아있는 식의 존재하지 않는
  /// 날짜를 애초에 고를 수 없게 한다.
  List<int> get _days =>
      List.generate(_daysInMonth(_selectedYear, _selectedMonth), (i) => i + 1);

  /// 연/월 변경으로 선택된 일(day)이 더 이상 유효하지 않으면(예: 31일 선택 중
  /// 2월로 변경) 그 달의 마지막 날로 보정하고, 휠 스크롤 위치도 함께 맞춘다.
  void _clampSelectedDay() {
    final maxDay = _daysInMonth(_selectedYear, _selectedMonth);
    if (_selectedDay <= maxDay) return;
    _selectedDay = maxDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_dayController.hasClients) {
        _dayController.jumpToItem(maxDay - 1);
      }
    });
  }

  final _studentIdService = StudentIdService();
  bool _isLoading = false;

  late final _yearController = FixedExtentScrollController(
    initialItem: _years.indexOf(_selectedYear),
  );
  late final _monthController = FixedExtentScrollController(
    initialItem: _months.indexOf(_selectedMonth),
  );
  late final _dayController = FixedExtentScrollController(
    initialItem: _days.indexOf(_selectedDay),
  );

  @override
  void dispose() {
    _nameController.dispose();
    _phonePrefixController.dispose();
    _phoneMiddleController.dispose();
    _phoneLastController.dispose();
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  Future<void> _showMessage(String message) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.info_outline,
                color: AppColors.accent,
                size: 26,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: '확인',
                enabled: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 한글/영문 이름만 허용(유학생 등 영문 이름 고려), 숫자·특수문자는 거른다.
  static final _namePattern = RegExp(r'^[가-힣a-zA-Z\s]{2,30}$');
  // 명세서(idSearch.do) 기준 자릿수: 앞 3자리 / 중간 3~4자리(옛 번호 호환) / 뒤 4자리.
  static final _mobile1Pattern = RegExp(r'^\d{3}$');
  static final _mobile2Pattern = RegExp(r'^\d{3,4}$');
  static final _mobile3Pattern = RegExp(r'^\d{4}$');

  Future<void> _onSubmit() async {
    final name = _nameController.text.trim();
    final mobile1 = _phonePrefixController.text.trim();
    final mobile2 = _phoneMiddleController.text.trim();
    final mobile3 = _phoneLastController.text.trim();

    if (name.isEmpty) {
      _showMessage('이름을 입력해주세요.');
      return;
    }
    if (!_namePattern.hasMatch(name)) {
      _showMessage('이름을 올바르게 입력해주세요.');
      return;
    }
    if (mobile1.isEmpty || mobile2.isEmpty || mobile3.isEmpty) {
      _showMessage('휴대폰 번호를 모두 입력해주세요.');
      return;
    }
    if (!_mobile1Pattern.hasMatch(mobile1)) {
      _showMessage('휴대폰 앞자리 3자리를 확인해주세요.');
      return;
    }
    if (!_mobile2Pattern.hasMatch(mobile2)) {
      _showMessage('휴대폰 중간자리를 확인해주세요.');
      return;
    }
    if (!_mobile3Pattern.hasMatch(mobile3)) {
      _showMessage('휴대폰 뒷자리 4자리를 확인해주세요.');
      return;
    }

    setState(() => _isLoading = true);

    final birthday6 =
        '${(_selectedYear % 100).toString().padLeft(2, '0')}'
        '${_selectedMonth.toString().padLeft(2, '0')}'
        '${_selectedDay.toString().padLeft(2, '0')}';

    final result = await _studentIdService.findStudentId(
      name: name,
      birthday6: birthday6,
      mobile1: mobile1,
      mobile2: mobile2,
      mobile3: mobile3,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    switch (result) {
      case StudentIdFound(studentNo: final studentNo):
        final confirmedStudentId = await Navigator.of(context).push<String>(
          MaterialPageRoute(
            builder: (_) => StudentIdResultScreen(studentId: studentNo),
          ),
        );
        if (!mounted) return;
        if (confirmedStudentId != null) {
          Navigator.of(context).pop(confirmedStudentId);
        }
      case StudentIdNotFound():
        _showMessage('일치하는 학번을 찾지 못했어요.');
      case StudentIdSearchError():
        _showMessage('조회 중 오류가 발생했어요. 잠시 후 다시 시도해주세요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 8),
                const Text(
                  '학번을 찾아드릴게요!',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                AppTextField(controller: _nameController, hintText: '이름'),
                const SizedBox(height: 20),
                const Text(
                  '휴대폰 번호',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _PhoneSegmentField(
                        controller: _phonePrefixController,
                        maxLength: 3,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '-',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    Expanded(
                      child: _PhoneSegmentField(
                        controller: _phoneMiddleController,
                        maxLength: 4,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '-',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    Expanded(
                      child: _PhoneSegmentField(
                        controller: _phoneLastController,
                        maxLength: 4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  '생년월일',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _WheelColumn(
                        controller: _yearController,
                        values: _years,
                        suffix: '년',
                        selectedValue: _selectedYear,
                        onChanged: (v) => setState(() {
                          _selectedYear = v;
                          _clampSelectedDay();
                        }),
                      ),
                    ),
                    Expanded(
                      child: _WheelColumn(
                        controller: _monthController,
                        values: _months,
                        suffix: '월',
                        selectedValue: _selectedMonth,
                        onChanged: (v) => setState(() {
                          _selectedMonth = v;
                          _clampSelectedDay();
                        }),
                      ),
                    ),
                    Expanded(
                      child: _WheelColumn(
                        controller: _dayController,
                        values: _days,
                        suffix: '일',
                        selectedValue: _selectedDay,
                        onChanged: (v) => setState(() => _selectedDay = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                PrimaryButton(
                  label: _isLoading ? '조회 중...' : '학번 찾기',
                  enabled: !_isLoading,
                  onPressed: _onSubmit,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 휴대폰 번호 3분할 입력 칸 하나.
class _PhoneSegmentField extends StatelessWidget {
  const _PhoneSegmentField({required this.controller, required this.maxLength});

  final TextEditingController controller;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        // keyboardType은 힌트일 뿐이라 물리 키보드/붙여넣기로 숫자 외 문자가
        // 들어올 수 있어, 입력 자체를 숫자로 제한하고 자릿수를 넘기지 못하게 막는다.
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(maxLength),
        ],
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        decoration: const InputDecoration(
          hintText: '0000',
          hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 16),
          counterText: '',
        ),
      ),
    );
  }
}

/// 생년월일(년/월/일) 휠 피커의 한 열.
/// 선택된 값만 굵게 강조해 디자인의 "가운데 값 강조" 느낌을 표현한다.
class _WheelColumn extends StatelessWidget {
  const _WheelColumn({
    required this.controller,
    required this.values,
    required this.suffix,
    required this.selectedValue,
    required this.onChanged,
  });

  final FixedExtentScrollController controller;
  final List<int> values;
  final String suffix;
  final int selectedValue;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 54,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: 46,
            diameterRatio: 1.8,
            onSelectedItemChanged: (index) => onChanged(values[index]),
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: values.length,
              builder: (context, index) {
                final value = values[index];
                final isSelected = value == selectedValue;
                return Center(
                  child: Text(
                    '$value$suffix',
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: isSelected ? 20 : 18,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w400,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
