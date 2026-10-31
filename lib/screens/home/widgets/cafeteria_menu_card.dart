import 'package:flutter/material.dart';

import '../../../services/cafeteria_menu_service.dart';
import '../../../services/service_factory.dart';
import '../../../theme/app_colors.dart';
import '../../cafeteria/models/cafeteria_menu.dart';
import 'home_mini_card.dart';

/// 분홍색 "오늘 학식" 카드. 오늘 점심 메뉴가 있으면 첫 번째 식당의 메뉴 두 가지와
/// 가격을, 없거나 아직 불러오는 중이거나 불러오지 못했으면 안내 문구를 보여준다.
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

  @override
  State<CafeteriaMenuCard> createState() => _CafeteriaMenuCardState();
}

class _CafeteriaMenuCardState extends State<CafeteriaMenuCard> {
  CafeteriaMenuItem? _item;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = widget.service ?? ServiceFactory.cafeteriaMenu();
    try {
      final menu = await service.fetchMenu(widget.now);
      if (!mounted) return;
      setState(() => _item = menu.lunch.isEmpty ? null : menu.lunch.first);
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
    return HomeMiniCard(
      icon: Icons.restaurant,
      iconBackground: Colors.white,
      iconColor: AppColors.ink,
      label: '오늘 점심',
      title: title,
      footer: item == null
          ? Text(
              '학식을 조회할 수 있어요',
              style: TextStyle(
                color: AppColors.ink.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: Text(
                    item.restaurant,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.ink.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    item.priceText,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
      backgroundColor: AppColors.blushPink,
      textColor: AppColors.ink,
      onTap: widget.onTap,
    );
  }
}
