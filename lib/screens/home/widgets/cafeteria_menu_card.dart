import 'dart:async';

import 'package:flutter/material.dart';

import '../../../services/cafeteria_menu_service.dart';
import '../../../services/service_factory.dart';
import '../../../theme/app_colors.dart';
import '../../cafeteria/models/cafeteria_menu.dart';
import '../home_colors.dart';
import 'home_mini_card.dart';

/// 연한 파랑 "오늘 점심" 카드(v7). 오늘 점심 메뉴가 있으면 식당별 메뉴 두 가지를
/// 보여 주고, 식당이 둘 이상이면 [autoSlide]마다 다음 식당으로 넘긴다. 없거나 아직 불러오는 중이거나 불러오지 못했으면 안내 문구를 보여준다.
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

  /// 다음 식당 메뉴로 넘어가는 간격(공지 배너와 같다).
  static const autoSlide = Duration(seconds: 4);

  @override
  State<CafeteriaMenuCard> createState() => _CafeteriaMenuCardState();
}

class _CafeteriaMenuCardState extends State<CafeteriaMenuCard> {
  /// 식당 이름 옆 가격 칩(숨김). 다시 보이려면 true로 바꾼다.
  static const _showPrice = false;

  List<CafeteriaMenuItem> _items = const [];
  int _index = 0;
  Timer? _timer;

  CafeteriaMenuItem? get _item => _items.isEmpty ? null : _items[_index];

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
        _items = menu.lunch;
        _index = 0;
      });
      _timer?.cancel();
      if (_items.length > 1) {
        _timer = Timer.periodic(CafeteriaMenuCard.autoSlide, (_) {
          if (mounted) setState(() => _index = (_index + 1) % _items.length);
        });
      }
    } on CafeteriaMenuException catch (e) {
      // 홈 카드는 조용히 안내 문구로 남기고, 원인만 로그로 남긴다.
      debugPrint('[Cafeteria] 홈 카드 학식 조회 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final title = item == null
        ? '오늘의 메뉴는\n무엇일까?'
        : item.dishes.take(2).join('\n');
    const footerLabel = TextStyle(
      color: HomeV7Colors.label,
      fontSize: 12,
      height: 1.4,
      fontWeight: FontWeight.w700,
    );
    // 식당이 바뀔 때 카드 내용을 서서히 바꿔 보여 준다.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: HomeMiniCard(
        key: ValueKey(_index),
        icon: Icons.restaurant_rounded,
        iconColor: AppColors.blueText,
        label: '오늘 점심',
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
