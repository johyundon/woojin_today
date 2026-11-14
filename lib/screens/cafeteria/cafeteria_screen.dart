import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/cafeteria_menu_service.dart';
import '../../services/service_factory.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pressable.dart';
import 'models/cafeteria_menu.dart';
import 'widgets/cafeteria_date_picker_dialog.dart';
import 'widgets/cafeteria_venue_tabs.dart';
import 'widgets/cafeteria_week_row.dart';
import 'widgets/small_menu_card.dart';

/// "오늘 뭐 먹지?" 화면(디자인 "07 학식"). 위쪽에서 요일(월~금 한 주)과 식당 탭
/// (전체/학생식당/교직원식당/카페)을 고르면, 메뉴가 같은 크기의 카드로 두 칸씩
/// 나온다. 아침/점심/저녁은 위쪽 파란 배지를 눌러 바꾼다.
///
/// 메뉴는 학교 사이트에서 받아 오며([CafeteriaMenuService]), 날짜가 바뀌면 그 날의
/// 메뉴를 다시 조회한다. 서버는 학생식당/교직원식당을 구분해 주지 않아 받은 메뉴는
/// 모두 학생식당으로 보여준다.
class CafeteriaScreen extends StatefulWidget {
  const CafeteriaScreen({this.now, this.service, super.key});

  /// 학식을 조회하는 서비스. 테스트에서 가짜로 바꿔 끼우려고 주입할 수 있다.
  final CafeteriaMenuServiceBase? service;

  /// "지금" 기준 시각(오늘 표시와 기본 끼니 고르기에 쓴다). 테스트에서 고정하려고
  /// 주입할 수 있다.
  final DateTime? now;

  @override
  State<CafeteriaScreen> createState() => _CafeteriaScreenState();
}

class _CafeteriaScreenState extends State<CafeteriaScreen> {
  late final DateTime _now = widget.now ?? DateTime.now();
  late DateTime _selectedDate = _dateOnly(_now);

  /// 고른 식당 탭. null이면 "전체".
  CafeteriaVenue? _venue;
  late CafeteriaMeal _meal = _defaultMeal();

  late final CafeteriaMenuServiceBase _service =
      widget.service ?? ServiceFactory.cafeteriaMenu();

  DailyCafeteriaMenu? _menu;
  bool _loading = true;
  bool _loadFailed = false;

  /// 날짜를 빠르게 바꿨을 때 늦게 도착한 이전 응답이 화면을 덮어쓰지 않게 한다.
  int _loadId = 0;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    final id = ++_loadId;
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final menu = await _service.fetchMenu(_selectedDate);
      if (!mounted || id != _loadId) return;
      setState(() {
        _menu = menu;
        _loading = false;
      });
    } on CafeteriaMenuException catch (e) {
      debugPrint('[Cafeteria] 학식 조회 실패: $e');
      if (!mounted || id != _loadId) return;
      setState(() {
        _menu = null;
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// 지금 시각에 맞는 끼니(오전 10시 전 아침, 오후 3시 전 점심, 그 뒤 저녁).
  CafeteriaMeal _defaultMeal() {
    if (_now.hour < 10) return CafeteriaMeal.breakfast;
    if (_now.hour < 15) return CafeteriaMeal.lunch;
    return CafeteriaMeal.dinner;
  }

  void _selectDate(DateTime date) {
    setState(() => _selectedDate = _dateOnly(date));
    _loadMenu();
  }

  void _moveWeek(int delta) =>
      _selectDate(_selectedDate.add(Duration(days: 7 * delta)));

  Future<void> _openDatePicker() async {
    final picked = await showCafeteriaDatePickerDialog(
      context,
      initialDate: _selectedDate,
    );
    if (picked != null) _selectDate(picked);
  }

  void _cycleMeal() {
    final values = CafeteriaMeal.values;
    setState(() => _meal = values[(_meal.index + 1) % values.length]);
  }

  /// 지금 탭/끼니에 보여줄 메뉴.
  List<CafeteriaMenuItem> _itemsToShow(DailyCafeteriaMenu? menu) {
    if (menu == null) return const [];
    final items = menu.itemsFor(_meal);
    if (_venue == null) return items;
    return items.where((item) => item.venue == _venue).toList();
  }

  /// 위쪽 알약 문구 — 식당/끼니/시간. 전체 탭은 학생식당 기준으로 쓴다.
  String get _pillText {
    switch (_venue) {
      case null:
      case CafeteriaVenue.student:
        final time = _meal == CafeteriaMeal.lunch ? ' 11:30 - 13:30' : '';
        return '학생회관 1층 · ${_meal.label}$time';
      case CafeteriaVenue.staff:
      case CafeteriaVenue.cafe:
        return '${_venue!.label} · ${_meal.label}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _itemsToShow(_menu);

    // 밝은 바탕이라 상태 표시줄 글자를 어둡게 한다.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _squareButton(
                          Icons.arrow_back_ios_new_rounded,
                          15,
                          '뒤로',
                          () => Navigator.of(context).pop(),
                        ),
                        const Spacer(),
                        _squareButton(
                          Icons.calendar_month_rounded,
                          19,
                          '날짜 선택',
                          _openDatePicker,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Pressable(
                      onTap: _cycleMeal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.blueSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.restaurant_rounded,
                              size: 13,
                              color: AppColors.blue,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                _pillText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.blue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(width: 3),
                            // 누르면 끼니가 바뀐다는 표시(디자인에는 없음).
                            const Icon(
                              Icons.swap_horiz_rounded,
                              size: 14,
                              color: AppColors.blue,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '오늘 뭐 먹지?',
                      style: TextStyle(
                        color: AppColors.textStrong,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                        letterSpacing: -1.04,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: CafeteriaWeekRow(
                  selectedDate: _selectedDate,
                  today: _dateOnly(_now),
                  onDaySelected: _selectDate,
                  onWeekChanged: _moveWeek,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: CafeteriaVenueTabs(
                  selected: _venue,
                  onChanged: (v) => setState(() => _venue = v),
                ),
              ),
              const SizedBox(height: 13),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.blue),
                      )
                    : _loadFailed
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '학식을 불러오지 못했어요',
                              style: TextStyle(
                                color: AppColors.textSub,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Pressable.effect(
                              child: TextButton(
                                onPressed: _loadMenu,
                                child: const Text(
                                  '다시 시도',
                                  style: TextStyle(
                                    color: AppColors.blue,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : items.isEmpty
                    ? const Center(
                        child: Text(
                          '등록된 메뉴가 없어요',
                          style: TextStyle(
                            color: AppColors.textSub,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : _buildMenus(items),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 메뉴 카드를 두 장씩 한 줄로 놓는다. 한 줄 안의 두 카드는 높이를 같게 맞춘다.
  Widget _buildMenus(List<CafeteriaMenuItem> items) {
    // 전체 탭에서는 학생식당이 아닌 메뉴에 식당 이름 배지를 단다.
    Widget card(CafeteriaMenuItem item) => SmallMenuCard(
      item: item,
      showVenue: _venue == null && item.venue != CafeteriaVenue.student,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: card(items[i])),
                  const SizedBox(width: 10),
                  Expanded(
                    child: i + 1 < items.length
                        ? card(items[i + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 흰 네모 버튼(뒤로가기·날짜 선택). 디자인 42x42, 모서리 12, 옅은 그림자.
  Widget _squareButton(
    IconData icon,
    double iconSize,
    String label,
    VoidCallback onTap,
  ) {
    return Pressable.icon(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppColors.cardShadow,
        ),
        child: Icon(
          icon,
          color: AppColors.textStrong,
          size: iconSize,
          semanticLabel: label,
        ),
      ),
    );
  }
}
