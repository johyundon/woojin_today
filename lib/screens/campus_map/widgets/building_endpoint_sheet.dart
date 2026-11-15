import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
import '../campus_map_colors.dart';

/// 지도 기본 화면에서 건물을 고르면 아래에서 올라오는 시트(시안 "해당 건물
/// 선택 시") — 건물 이름, 닫기(X), "출발" · "도착" 버튼.
///
/// 화면 아래 끝까지 붙는 시트라 홈 바(아래 안전 영역)만큼 아래 여백을 준다.
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;
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
                  buildingName,
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
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _EndpointButton(
                  label: '출발',
                  background: AppColors.blueSoft,
                  foreground: AppColors.blue,
                  onTap: onSetOrigin,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _EndpointButton(
                  label: '도착',
                  background: AppColors.blue,
                  foreground: Colors.white,
                  onTap: onSetDestination,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EndpointButton extends StatelessWidget {
  const _EndpointButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }
}
