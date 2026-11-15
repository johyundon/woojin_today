import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
import '../campus_map_colors.dart';

/// 지도 기본 화면에서 건물을 고르면 아래에서 올라오는 시트(시안 "해당 건물
/// 선택 시") — 건물 이름, 닫기(X), "출발" · "도착" 버튼.
class BuildingEndpointSheet extends StatelessWidget {
  const BuildingEndpointSheet({
    super.key,
    required this.buildingName,
    required this.onClose,
    required this.onSetOrigin,
    required this.onSetDestination,
  });

  final String buildingName;
  final VoidCallback onClose;

  /// "출발" — 이 건물에서 출발.
  final VoidCallback onSetOrigin;

  /// "도착" — 이 건물로 가는 길.
  final VoidCallback onSetDestination;

  @override
  Widget build(BuildContext context) {
    return _CampusBottomSheet(
      title: buildingName,
      onClose: onClose,
      left: _SheetButton(
        label: '출발',
        background: AppColors.blueSoft,
        foreground: AppColors.blue,
        onTap: onSetOrigin,
      ),
      right: _SheetButton(
        label: '도착',
        background: AppColors.blue,
        foreground: Colors.white,
        onTap: onSetDestination,
      ),
    );
  }
}

/// 길안내 화면 아래 시트 — 도착(없으면 출발) 이름, 둘 다 있을 때만
/// "걸어서 N분 · Nm", "초기화" · "길 안내" 버튼. 도착이 없으면 길 안내는
/// 회색으로 눌리지 않는다.
class RouteSummarySheet extends StatelessWidget {
  const RouteSummarySheet({
    super.key,
    required this.title,
    required this.onClose,
    required this.onReset,
    required this.onStart,
    this.walkMinutes,
    this.distanceMeters,
  });

  final String title;
  final int? walkMinutes;
  final double? distanceMeters;
  final VoidCallback onClose;
  final VoidCallback onReset;

  /// null이면 "길 안내"를 회색으로 막는다(도착이 아직 없을 때).
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final walk = walkMinutes;
    final distance = distanceMeters;
    final start = onStart;
    return _CampusBottomSheet(
      title: title,
      subtitle: walk != null && distance != null
          ? '걸어서 $walk분 · ${distance.round()}m'
          : null,
      onClose: onClose,
      leftFlex: 1,
      rightFlex: 2,
      left: _SheetButton(
        label: '초기화',
        background: AppColors.fill,
        foreground: CampusMapColors.secondaryButtonText,
        onTap: onReset,
      ),
      right: _SheetButton(
        label: '길 안내',
        background: start == null ? AppColors.fillDisabled : AppColors.blue,
        foreground: start == null ? AppColors.textMuted : Colors.white,
        onTap: start,
      ),
    );
  }
}

/// 화면 아래 끝까지 붙는 흰 시트 틀 — 손잡이, 제목 + X, (있으면) 회색 한 줄,
/// 버튼 두 개. 홈 바(아래 안전 영역)만큼 아래 여백을 준다.
class _CampusBottomSheet extends StatelessWidget {
  const _CampusBottomSheet({
    required this.title,
    required this.onClose,
    required this.left,
    required this.right,
    this.subtitle,
    this.leftFlex = 1,
    this.rightFlex = 1,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onClose;
  final Widget left;
  final Widget right;
  final int leftFlex;
  final int rightFlex;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final subtitle = this.subtitle;
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        bottomInset > 16 ? bottomInset : 16,
      ),
      decoration: const BoxDecoration(
        color: CampusMapColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: CampusMapColors.sheetShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.fillDisabled,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CampusMapColors.buildingName,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              Pressable.icon(
                onTap: onClose,
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Icon(
                      Icons.close_rounded,
                      color: AppColors.textMuted,
                      size: 24,
                      semanticLabel: '닫기',
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSub,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(flex: leftFlex, child: left),
              const SizedBox(width: 10),
              Expanded(flex: rightFlex, child: right),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;

  /// null이면 눌러도 아무 일 없다(회색 버튼).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
    );
    final tap = onTap;
    if (tap == null) return box;
    return Pressable(onTap: tap, child: box);
  }
}
