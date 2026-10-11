import 'package:flutter/material.dart';

import 'cafeteria_colors.dart';
import 'models/cafeteria_menu.dart';
import 'services/cafeteria_menu_mock_data.dart';
import 'widgets/cafeteria_date_picker_dialog.dart';
import 'widgets/meal_section.dart';

const List<String> _weekdayKorLabels = ['일', '월', '화', '수', '목', '금', '토'];

/// "오늘의 학식" 화면 (Figma node 6:70 "학식").
///
/// 이 노드는 실제 Figma 벡터 레이어가 아니라 다른 앱을 캡처한 스크린샷 4장
/// (6:71~6:74)이 평탄화된 상태라 `get_design_context`로 쓸만한 코드를 뽑을 수
/// 없었다(calendar_screen.dart, timetable_colors.dart와 같은 상황). 스크린샷을
/// 눈으로 보고 레이아웃/색상/간격을 근사해 재현했다.
///
/// 학생식당 메뉴 API 연동이 없어(명세서에 대응 엔드포인트 없음) 메뉴는
/// [CafeteriaMenuMockData]의 하드코딩된 목데이터로만 조회한다 — 날짜가
/// 바뀌면 그 함수를 다시 호출해 본문을 갱신한다.
class CafeteriaScreen extends StatefulWidget {
  const CafeteriaScreen({super.key});

  @override
  State<CafeteriaScreen> createState() => _CafeteriaScreenState();
}

class _CafeteriaScreenState extends State<CafeteriaScreen> {
  DateTime _selectedDate = _dateOnly(DateTime.now());

  // 아코디언 섹션별 펼침 상태(독립 토글). 스크린샷에 보이는 기본 상태(점심만
  // 펼쳐진 상태)를 그대로 초깃값으로 쓴다.
  bool _breakfastExpanded = false;
  bool _lunchExpanded = true;
  bool _dinnerExpanded = false;

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  void _goToPreviousDay() {
    setState(
      () => _selectedDate = _selectedDate.subtract(const Duration(days: 1)),
    );
  }

  void _goToNextDay() {
    setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
  }

  Future<void> _openDatePicker() async {
    final picked = await showCafeteriaDatePickerDialog(
      context,
      initialDate: _selectedDate,
    );
    if (picked == null) return;
    setState(() => _selectedDate = _dateOnly(picked));
  }

  @override
  Widget build(BuildContext context) {
    final menu = CafeteriaMenuMockData.menuFor(_selectedDate);

    return Scaffold(
      backgroundColor: CafeteriaColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: CafeteriaColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Text(
                '오늘의 학식',
                style: TextStyle(
                  color: CafeteriaColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _goToPreviousDay,
                  icon: const Icon(
                    Icons.chevron_left,
                    color: CafeteriaColors.accent,
                  ),
                ),
                Text(
                  '${_selectedDate.month}월 ${_selectedDate.day}일 '
                  '(${_weekdayKorLabels[_selectedDate.weekday % 7]})',
                  style: const TextStyle(
                    color: CafeteriaColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  onPressed: _goToNextDay,
                  icon: const Icon(
                    Icons.chevron_right,
                    color: CafeteriaColors.accent,
                  ),
                ),
              ],
            ),
            Center(
              child: TextButton(
                onPressed: _openDatePicker,
                child: const Text(
                  '날짜 직접 선택',
                  style: TextStyle(
                    color: CafeteriaColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: menu == null || menu.isEmpty
                    ? _buildEmptyCard()
                    : _buildMenuCard(menu),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: CafeteriaColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Text(
          '이 날은 등록된 학식 정보가 없어요',
          style: TextStyle(color: CafeteriaColors.textSecondary, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildMenuCard(DailyCafeteriaMenu menu) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: CafeteriaColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          MealSection(
            title: '아침',
            items: menu.breakfast,
            expanded: _breakfastExpanded,
            onToggle: () =>
                setState(() => _breakfastExpanded = !_breakfastExpanded),
          ),
          const Divider(color: CafeteriaColors.border, height: 1),
          MealSection(
            title: '점심',
            items: menu.lunch,
            expanded: _lunchExpanded,
            onToggle: () => setState(() => _lunchExpanded = !_lunchExpanded),
          ),
          const Divider(color: CafeteriaColors.border, height: 1),
          MealSection(
            title: '저녁',
            items: menu.dinner,
            expanded: _dinnerExpanded,
            onToggle: () => setState(() => _dinnerExpanded = !_dinnerExpanded),
          ),
        ],
      ),
    );
  }
}
