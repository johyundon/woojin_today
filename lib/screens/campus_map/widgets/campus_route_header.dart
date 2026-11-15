import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
import 'campus_map_top_bar.dart';

/// 길안내 화면의 위쪽 흰 카드 — 맨 윗줄은 기본 화면과 같은 뒤로가기 +
/// "캠퍼스 지도", 그 아래 왼쪽에 출발·도착 바꾸기 버튼, 오른쪽에 출발·도착
/// 입력칸 두 개. 칸을 누르면 건물 고르기, 칸 끝 X를 누르면 그 칸을 비운다.
class CampusRouteHeader extends StatelessWidget {
  const CampusRouteHeader({
    super.key,
    required this.onBack,
    required this.originName,
    required this.destinationName,
    required this.onTapOrigin,
    required this.onTapDestination,
    required this.onClearOrigin,
    required this.onClearDestination,
    required this.onSwap,
  });

  final VoidCallback onBack;

  /// 출발·도착 이름. 아직 안 골랐으면 null(안내 문구를 보여 준다).
  final String? originName;
  final String? destinationName;

  final VoidCallback onTapOrigin;
  final VoidCallback onTapDestination;
  final VoidCallback onClearOrigin;
  final VoidCallback onClearDestination;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CampusMapTitleRow(onBack: onBack),
        const SizedBox(height: 10),
        Row(
          children: [
            Pressable.icon(
              onTap: onSwap,
              child: const SizedBox(
                width: 32,
                height: 88,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Icon(
                    Icons.swap_vert_rounded,
                    color: AppColors.textSub,
                    size: 24,
                    semanticLabel: '출발·도착 바꾸기',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                children: [
                  _EndpointField(
                    name: originName,
                    icon: const _OriginDot(),
                    clearLabel: '출발 지우기',
                    onTap: onTapOrigin,
                    onClear: onClearOrigin,
                  ),
                  const SizedBox(height: 8),
                  _EndpointField(
                    name: destinationName,
                    icon: const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.blue,
                      size: 22,
                    ),
                    clearLabel: '도착 지우기',
                    onTap: onTapDestination,
                    onClear: onClearDestination,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EndpointField extends StatelessWidget {
  const _EndpointField({
    required this.name,
    required this.icon,
    required this.clearLabel,
    required this.onTap,
    required this.onClear,
  });

  final String? name;

  /// 왼쪽 아이콘(예전 출발·도착 카드와 같은 출발 점 · 도착 핀).
  final Widget icon;
  final String clearLabel;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final name = this.name;
    return Pressable(
      onTap: onTap,
      pressedScale: 0.98,
      child: Container(
        height: 40,
        padding: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: AppColors.fill,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            SizedBox(width: 24, child: Center(child: icon)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name ?? CampusMapTopBar.searchHint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: name == null
                      ? AppColors.textMuted
                      : AppColors.textStrong,
                  fontSize: 14,
                  fontWeight: name == null ? FontWeight.w400 : FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            if (name != null)
              Pressable.icon(
                onTap: onClear,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.cancel_rounded,
                    color: AppColors.checkLine,
                    size: 18,
                    semanticLabel: clearLabel,
                  ),
                ),
              )
            else
              const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

/// 출발 칸 아이콘: 옅은 원 안의 파란 점(예전 출발·도착 카드와 같다).
class _OriginDot extends StatelessWidget {
  const _OriginDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        color: AppColors.blueSoft,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: AppColors.blue,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
