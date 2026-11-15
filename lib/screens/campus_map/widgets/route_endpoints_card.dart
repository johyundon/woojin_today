import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
import '../campus_map_colors.dart';

/// 길안내 화면 위쪽 카드(시안 3번) — 출발점·도착점 두 줄과 오른쪽 바꾸기
/// 버튼. 각 줄을 누르면 그 칸의 건물을 다시 고른다.
class RouteEndpointsCard extends StatelessWidget {
  const RouteEndpointsCard({
    super.key,
    required this.originTitle,
    required this.destinationTitle,
    required this.onTapOrigin,
    required this.onTapDestination,
    required this.onSwap,
    this.originTime,
    this.destinationTime,
  });

  /// 비어 있으면 "건물 선택"을 흐리게 보여 준다.
  final String? originTitle;
  final String? destinationTitle;

  /// 오른쪽 작은 시각 글자(예: "12:15 끝"). 없으면 숨긴다.
  final String? originTime;
  final String? destinationTime;

  final VoidCallback onTapOrigin;
  final VoidCallback onTapDestination;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _EndpointRow(
                label: '출발점',
                title: originTitle,
                time: originTime,
                icon: const _OriginDot(),
                onTap: onTapOrigin,
              ),
              const Divider(height: 1, color: AppColors.line),
              _EndpointRow(
                label: '도착점',
                title: destinationTitle,
                time: destinationTime,
                icon: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.blue,
                  size: 24,
                ),
                onTap: onTapDestination,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Pressable.icon(
          onTap: onSwap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.fill,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.swap_vert_rounded,
              color: AppColors.textStrong,
              size: 26,
              semanticLabel: '출발점과 도착점 바꾸기',
            ),
          ),
        ),
      ],
    );
  }
}

class _EndpointRow extends StatelessWidget {
  const _EndpointRow({
    required this.label,
    required this.title,
    required this.time,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String? title;
  final String? time;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    final time = this.time;
    return Pressable(
      onTap: onTap,
      pressedScale: 0.98,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SizedBox(width: 28, child: Center(child: icon)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textSub,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title ?? '건물 선택',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: title == null
                          ? AppColors.textMuted
                          : CampusMapColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            if (time != null) ...[
              const SizedBox(width: 8),
              Text(
                time,
                style: const TextStyle(
                  color: AppColors.textSub,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 출발점 아이콘: 옅은 원 안의 파란 점.
class _OriginDot extends StatelessWidget {
  const _OriginDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: AppColors.blueSoft,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: AppColors.blue,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
