import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/service_factory.dart';
import '../services/student_id_service.dart';
import '../theme/app_colors.dart';
import '../widgets/pressable.dart';
import 'student_id_header.dart';
import 'student_id_result_screen.dart';

/// 학번 찾기 입력 화면 (v7 디자인 05·06·07).
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

  final _studentIdService = ServiceFactory.studentId();
  bool _isLoading = false;

  /// 조회 결과(일치하는 학번 없음·조회 오류)를 버튼 위에 글자로 보여준다(디자인 07).
  /// 입력값 검증 안내는 예전처럼 알림창으로 보여준다.
  String? _resultError;

  /// 이름과 휴대폰 번호 칸이 모두 채워졌는지. 버튼을 파랑/회색으로 보여주는 데만
  /// 쓰고, 회색이어도 누르면 예전처럼 어떤 칸이 비었는지 알림창으로 알려준다.
  bool get _inputFilled =>
      _nameController.text.trim().isNotEmpty &&
      _phonePrefixController.text.trim().isNotEmpty &&
      _phoneMiddleController.text.trim().isNotEmpty &&
      _phoneLastController.text.trim().isNotEmpty;

  void _onInputChanged() => setState(() {});

  @override
  void initState() {
    super.initState();
    for (final c in [
      _nameController,
      _phonePrefixController,
      _phoneMiddleController,
      _phoneLastController,
    ]) {
      c.addListener(_onInputChanged);
    }
  }

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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.blueSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: AppColors.blue,
                size: 26,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textStrong,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: Pressable.effect(
                pressedScale: 0.96,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    '확인',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
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

    setState(() {
      _isLoading = true;
      _resultError = null;
    });

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
            builder: (_) =>
                StudentIdResultScreen(studentId: studentNo, name: name),
          ),
        );
        if (!mounted) return;
        if (confirmedStudentId != null) {
          Navigator.of(context).pop(confirmedStudentId);
        }
      case StudentIdNotFound():
        setState(() => _resultError = '입력하신 정보와 일치하는 학번이 없어요');
      case StudentIdSearchError():
        setState(() => _resultError = '조회 중 오류가 발생했어요. 잠시 후 다시 시도해주세요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      // 키보드 양옆 둥근 모서리 틈으로 Scaffold 바탕이 비쳐 파랑이 보이지
      // 않도록, 바탕은 흰색으로 두고 파랑은 body 영역에만 깐다.
      backgroundColor: Colors.white,
      body: ColoredBox(
        color: AppColors.blue,
        child: SafeArea(
          bottom: false,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => FocusScope.of(context).unfocus(),
            // 파란 제목 영역과 흰 카드를 한 스크롤 안에 둔다. 키보드가 올라와
            // 화면이 줄어도 버튼까지 스크롤해서 닿을 수 있고, 화면이 충분히
            // 크면 minHeight 덕에 카드가 화면 맨 아래에 붙는다.
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const StudentIdHeader(
                        badge: '학번 찾기',
                        title: '학번을\n찾아드릴게요!',
                      ),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(
                          22,
                          28,
                          22,
                          bottomInset + 10 > 44 ? bottomInset + 10 : 44,
                        ),
                        decoration: studentIdCardDecoration,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _FieldLabel(
                              icon: Icons.person_rounded,
                              text: '이름',
                            ),
                            const SizedBox(height: 8),
                            _FindTextField(
                              controller: _nameController,
                              hintText: '이름을 입력해 주세요',
                            ),
                            const SizedBox(height: 18),
                            const _FieldLabel(
                              icon: Icons.smartphone_rounded,
                              text: '휴대폰 번호',
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                SizedBox(
                                  width: 86,
                                  child: _PhoneSegmentField(
                                    controller: _phonePrefixController,
                                    maxLength: 3,
                                  ),
                                ),
                                const _PhoneDash(),
                                Expanded(
                                  child: _PhoneSegmentField(
                                    controller: _phoneMiddleController,
                                    maxLength: 4,
                                  ),
                                ),
                                const _PhoneDash(),
                                Expanded(
                                  child: _PhoneSegmentField(
                                    controller: _phoneLastController,
                                    maxLength: 4,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            const _FieldLabel(
                              icon: Icons.cake_rounded,
                              text: '생년월일',
                            ),
                            const SizedBox(height: 7),
                            _BirthdayWheel(
                              children: [
                                _WheelColumn(
                                  controller: _yearController,
                                  values: _years,
                                  suffix: '년',
                                  selectedValue: _selectedYear,
                                  onChanged: (v) => setState(() {
                                    _selectedYear = v;
                                    _clampSelectedDay();
                                  }),
                                ),
                                _WheelColumn(
                                  controller: _monthController,
                                  values: _months,
                                  suffix: '월',
                                  selectedValue: _selectedMonth,
                                  onChanged: (v) => setState(() {
                                    _selectedMonth = v;
                                    _clampSelectedDay();
                                  }),
                                ),
                                _WheelColumn(
                                  controller: _dayController,
                                  values: _days,
                                  suffix: '일',
                                  selectedValue: _selectedDay,
                                  onChanged: (v) =>
                                      setState(() => _selectedDay = v),
                                ),
                              ],
                            ),
                            if (_resultError != null) ...[
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_rounded,
                                    size: 15,
                                    color: studentIdErrorRed,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      _resultError!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: studentIdErrorRed,
                                        fontSize: 12,
                                        height: 1.4,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 26),
                            ] else
                              const SizedBox(height: 9),
                            StudentIdBlueButton(
                              label: _isLoading ? '조회 중...' : '학번 찾기',
                              showArrow: !_isLoading,
                              looksEnabled: _inputFilled && !_isLoading,
                              onPressed: _isLoading ? null : _onSubmit,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 흰 카드 안 입력 칸 위에 붙는 아이콘 + 라벨 한 줄.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: SizedBox(
        height: 20,
        child: Row(
          children: [
            Icon(icon, size: 15, color: AppColors.blue),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(
                color: AppColors.textSub,
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 입력 칸 힌트 글자색(디자인 05 값).
const _hintColor = Color(0xFFB8B7C4);

const _inputTextStyle = TextStyle(
  color: AppColors.textStrong,
  fontSize: 15,
  height: 1.4,
  letterSpacing: -0.15,
  fontWeight: FontWeight.w700,
);

/// 회색 입력 칸 바탕. 입력 중에는 파란 테두리를 두른다(두께 2는 항상 유지해
/// 글자가 움직이지 않게 한다).
class _InputBox extends StatelessWidget {
  const _InputBox({
    required this.focused,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.alignment = Alignment.center,
  });

  final bool focused;
  final Widget child;
  final EdgeInsets padding;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 54,
      padding: padding,
      alignment: alignment,
      decoration: BoxDecoration(
        color: AppColors.fill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: focused ? AppColors.blue : Colors.transparent,
          width: 2,
        ),
      ),
      child: child,
    );
  }
}

/// 이름 입력 칸.
class _FindTextField extends StatefulWidget {
  const _FindTextField({required this.controller, required this.hintText});

  final TextEditingController controller;
  final String hintText;

  @override
  State<_FindTextField> createState() => _FindTextFieldState();
}

class _FindTextFieldState extends State<_FindTextField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InputBox(
      focused: _focusNode.hasFocus,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        cursorColor: AppColors.blue,
        style: _inputTextStyle,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: _inputTextStyle.copyWith(color: _hintColor),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

/// 휴대폰 번호 칸 사이의 짧은 가로줄.
class _PhoneDash extends StatelessWidget {
  const _PhoneDash();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.checkLine,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}

/// 휴대폰 번호 3분할 입력 칸 하나.
class _PhoneSegmentField extends StatefulWidget {
  const _PhoneSegmentField({required this.controller, required this.maxLength});

  final TextEditingController controller;
  final int maxLength;

  @override
  State<_PhoneSegmentField> createState() => _PhoneSegmentFieldState();
}

class _PhoneSegmentFieldState extends State<_PhoneSegmentField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InputBox(
      focused: _focusNode.hasFocus,
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        keyboardType: TextInputType.number,
        // keyboardType은 힌트일 뿐이라 물리 키보드/붙여넣기로 숫자 외 문자가
        // 들어올 수 있어, 입력 자체를 숫자로 제한하고 자릿수를 넘기지 못하게 막는다.
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(widget.maxLength),
        ],
        textAlign: TextAlign.center,
        cursorColor: AppColors.blue,
        style: _inputTextStyle,
        decoration: InputDecoration(
          hintText: '0000',
          hintStyle: _inputTextStyle.copyWith(color: _hintColor),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
          counterText: '',
        ),
      ),
    );
  }
}

/// 생년월일 휠 세 열을 담는 회색 상자. 가운데 흰 선택 막대 하나가 세 열에
/// 걸쳐 있고, 위아래 끝은 바탕색으로 흐려진다(디자인 05).
class _BirthdayWheel extends StatelessWidget {
  const _BirthdayWheel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.fill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: AppColors.cardShadow,
                  ),
                ),
                Row(children: [for (final c in children) Expanded(child: c)]),
              ],
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.fill,
                      AppColors.fill.withValues(alpha: 0),
                      AppColors.fill.withValues(alpha: 0),
                      AppColors.fill,
                    ],
                    stops: const [0, 0.3, 0.7, 1],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 생년월일(년/월/일) 휠 피커의 한 열.
/// 가운데(선택된) 값은 파랗고 크게, 멀어질수록 작고 옅게 보인다.
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
    final selectedIndex = values.indexOf(selectedValue);
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: 36,
      // 쓸어내리다 멈추면 가장 가까운 값이 선택 박스 정중앙에 딱 맞도록
      // 한 칸 단위로 붙여준다(기본 물리 효과는 걸쳐진 채로 멈춘다).
      physics: const FixedExtentScrollPhysics(),
      diameterRatio: 1.8,
      onSelectedItemChanged: (index) => onChanged(values[index]),
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: values.length,
        builder: (context, index) {
          final value = values[index];
          final distance = (index - selectedIndex).abs();
          final TextStyle style;
          if (distance == 0) {
            style = const TextStyle(
              color: AppColors.blue,
              fontSize: 17,
              letterSpacing: -0.34,
              fontWeight: FontWeight.w800,
            );
          } else if (distance == 1) {
            style = TextStyle(
              color: AppColors.textStrong.withValues(alpha: 0.45),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            );
          } else {
            style = TextStyle(
              color: AppColors.textStrong.withValues(alpha: 0.18),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            );
          }
          // 한글 글꼴은 줄 가운데보다 글자가 살짝 위에 그려져 선택 박스
          // 위로 걸쳐 보이므로, 위쪽 여백을 줘서 약 1.5px 내린다.
          // 누른 값이 그 자리에 머물지 않고 선택 박스(정중앙)로 오도록 한다.
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => controller.animateToItem(
              index,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text('$value$suffix', style: style),
              ),
            ),
          );
        },
      ),
    );
  }
}
