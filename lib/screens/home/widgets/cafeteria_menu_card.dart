import 'dart:async';

import 'package:flutter/material.dart';

import '../../../services/cafeteria_menu_service.dart';
import '../../../services/service_factory.dart';
import '../../../theme/app_colors.dart';
import '../../cafeteria/models/cafeteria_menu.dart';
import '../home_colors.dart';
import 'home_mini_card.dart';

/// 연한 파랑 "오늘 점심" 카드(v7). 지금 시각의 끼니([mealAt]: 아침·점심·저녁)
/// 메뉴를 곁들이(음료·김치 등)를 빼고 한 장에 하나씩([menuPages]) 보여 주고,
/// 장이 둘 이상이면 [autoSlide]마다 다음 장으로 넘겨 계속 돈다. 없거나 아직 불러오는 중이거나 불러오지 못했으면 안내 문구를 보여준다.
class CafeteriaMenuCard extends StatefulWidget {
  const CafeteriaMenuCard({
    super.key,
    required this.now,
    required this.onTap,
    this.service,
  });

  final DateTime now;
  final VoidCallback onTap;

  /// 학식을 조회하는 서비스. 테스트에서 가짜로 바꿔 끼우려고 주입할 수 있다.
  final CafeteriaMenuServiceBase? service;

  /// 다음 메뉴 묶음으로 넘어가는 간격.
  static const autoSlide = Duration(seconds: 3);

  @override
  State<CafeteriaMenuCard> createState() => _CafeteriaMenuCardState();
}

/// 카드 한 장에 보여 줄 것: 식당과 그 식당 대표 메뉴 하나.
/// 작은 카드에 두 줄로 두 메뉴를 넣으면 긴 이름이 잘려서(…) 한 장에 하나만 둔다.
typedef LunchPage = ({CafeteriaMenuItem item, List<String> dishes});

/// 실제 학식 응답에 늘 끼어 있는 음료·김치·장아찌·밥 같은 곁들이.
/// 홈 카드에서는 빼고 학식 화면에서는 그대로 보여 준다.
const _sideSuffixes = [
  '우유',
  '콜라',
  '사이다',
  '아이스티',
  '수염차',
  '귤피차',
  '수정과',
  '식혜',
  '김치',
  '깍두기',
  '단무지',
  '피클',
  '치킨무',
  '장아찌',
  '절임',
  '고추지',
  '오복채',
  '쌀밥',
];
const _sideContains = ['요플레', '요구르트', '주스'];
const _sideExact = {'밥', '사과', '귤', '배', '바나나'};

/// 홈 카드에서 뺄 곁들이 반찬·음료인지.
bool isSideDish(String dish) {
  final d = dish.trim();
  return _sideExact.contains(d) ||
      _sideSuffixes.any(d.endsWith) ||
      _sideContains.any(d.contains);
}

/// 식당마다 곁들이를 뺀 메뉴를 한 장에 하나씩 둔다. 다 곁들이면 원래 메뉴를 쓰고,
/// 메뉴가 없는 식당은 이름만 한 장.
List<LunchPage> menuPages(List<CafeteriaMenuItem> items) => [
  for (final item in items)
    if (item.dishes.isEmpty)
      (item: item, dishes: const <String>[])
    else
      for (final dish in _mainDishes(item.dishes)) (item: item, dishes: [dish]),
];

List<String> _mainDishes(List<String> dishes) {
  final mains = dishes.where((d) => !isSideDish(d)).toList();
  return mains.isEmpty ? dishes : mains;
}

class _CafeteriaMenuCardState extends State<CafeteriaMenuCard> {
  /// 식당 이름 옆 가격 칩(숨김). 다시 보이려면 true로 바꾼다.
  static const _showPrice = false;

  DailyCafeteriaMenu? _menu;
  int _index = 0;
  Timer? _timer;

  /// 지금 끼니. 홈이 다시 그려질 때 [CafeteriaMenuCard.now]가 바뀌면 따라간다.
  CafeteriaMeal get _meal => mealAt(widget.now);

  List<LunchPage> get _pages => menuPages(_menu?.itemsFor(_meal) ?? const []);

  LunchPage? get _page {
    final pages = _pages;
    return pages.isEmpty ? null : pages[_index % pages.length];
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// 홈은 매 분 새 시각을 넘겨준다. 날짜가 바뀌었으면(자정을 넘김) 그날 메뉴를
  /// 새로 받는다. 같은 날이면 끼니만 [_meal]이 따라 바뀌고 다시 받지 않는다.
  @override
  void didUpdateWidget(CafeteriaMenuCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = oldWidget.now;
    final now = widget.now;
    if (before.year != now.year ||
        before.month != now.month ||
        before.day != now.day) {
      _load();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final service = widget.service ?? ServiceFactory.cafeteriaMenu();
    try {
      final menu = await service.fetchMenu(widget.now);
      if (!mounted) return;
      setState(() {
        _menu = menu;
        _index = 0;
      });
      _timer?.cancel();
      _timer = Timer.periodic(CafeteriaMenuCard.autoSlide, (_) {
        // 묶음이 하나뿐이면 다시 그릴 필요가 없다.
        if (mounted && _pages.length > 1) setState(() => _index++);
      });
    } on CafeteriaMenuException catch (e) {
      // 홈 카드는 조용히 안내 문구로 남기고, 원인만 로그로 남긴다.
      debugPrint('[Cafeteria] 홈 카드 학식 조회 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _page;
    final item = page?.item;
    final title = page == null ? '오늘의 메뉴는\n무엇일까?' : page.dishes.join('\n');
    const footerLabel = TextStyle(
      color: HomeV7Colors.label,
      fontSize: 12,
      height: 1.4,
      fontWeight: FontWeight.w700,
    );
    // 메뉴 묶음이 바뀔 때 카드 내용을 서서히 바꿔 보여 준다.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: HomeMiniCard(
        key: ValueKey(
          '${_meal.name}-${_pages.isEmpty ? 0 : _index % _pages.length}',
        ),
        icon: Icons.restaurant_rounded,
        iconColor: AppColors.blueText,
        label: '오늘 ${_meal.label}',
        labelColor: AppColors.textStrong.withValues(alpha: 0.75),
        title: title,
        titleColor: HomeV7Colors.lunchTitle,
        titleFontSize: 20,
        titleMaxLines: 2,
        footer: item == null
            ? const Text('학식을 조회할 수 있어요', style: footerLabel)
            : Row(
                children: [
                  Expanded(
                    child: Text(
                      item.restaurant,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: footerLabel,
                    ),
                  ),
                  // 가격 칩은 Figma "03 홈"에 없어 숨겼다.
                  if (_showPrice) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.priceText,
                        style: const TextStyle(
                          color: HomeV7Colors.cardTitle,
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
        backgroundColor: AppColors.blueSoft,
        borderColor: AppColors.blueSoftLine,
        onTap: widget.onTap,
      ),
    );
  }
}
