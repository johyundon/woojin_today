import 'package:flutter/material.dart';
import 'package:nsd/nsd.dart' as nsd;

import '../../../theme/app_colors.dart';

/// "주변 사람" 목록 한 줄 — 아바타 이니셜 + 광고된 이름 + "보내기".
class PeerRow extends StatelessWidget {
  const PeerRow({
    super.key,
    required this.peer,
    required this.color,
    required this.onSend,
  });

  final nsd.Service peer;
  final Color color;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final name = peer.name ?? '이름 없는 기기';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F0F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Text(
              name.characters.firstOrNull ?? '?',
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onSend,
              borderRadius: BorderRadius.circular(12),
              highlightColor: AppColors.cobalt.withValues(alpha: 0.12),
              splashColor: AppColors.cobalt.withValues(alpha: 0.12),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Text(
                  '보내기',
                  style: TextStyle(
                    color: AppColors.cobalt,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
