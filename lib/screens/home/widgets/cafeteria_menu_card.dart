import 'dart:async';

import 'package:flutter/material.dart';

import '../../../services/cafeteria_menu_service.dart';
import '../../../services/service_factory.dart';
import '../../../theme/app_colors.dart';
import '../../cafeteria/models/cafeteria_menu.dart';
import '../home_colors.dart';
import 'home_mini_card.dart';

/// 연한 파랑 "오늘 점심" 카드(v7). 지금 시각의 끼니([mealAt]: 아침·점심·저녁)
/// 메뉴를 두 가지씩 묶어([menuPages])
/// 보여 주고, 묶음이 둘 이상이면 [autoSlide]마다 다음 묶음으로 넘겨 계속 돈다
/// (식당이 하나여도 메뉴가 많으면 넘어간다). 없거나 아직 불러오는 중이거나 불러오지 못했으면 안내 문구를 보여준다.
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

/// 카드 한 장에 보여 줄 것: 식당과 그 식당 메뉴 중 두 가지.
typedef LunchPage = ({CafeteriaMenuItem item, List<String> dishes});

/// 식당마다 메뉴를 앞에서부터 두 개씩 묶는다. 메뉴가 없는 식당은 이름만 한 장.
List<LunchPage> menuPages(List<CafeteriaMenuItem> items) => [
  for (final item in items)
    if (item.dishes.isEmpty)
      (item: item, dishes: const <String>[])
    else
      for (var i = 0; i < item.dishes.length; i += 2)
        (item: item, dishes: item.dishes.skip(i).take(2).toList()),
];

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
