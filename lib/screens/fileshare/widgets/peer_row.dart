import 'package:flutter/material.dart';
import 'package:nsd/nsd.dart' as nsd;

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';

/// "주변 사람" 목록 한 줄 — 아바타 이니셜 + 광고된 이름 + "보내기".
class PeerRow extends StatelessWidget {
  const PeerRow({
    super.key,
    required this.peer,
    required this.color,
    required this.onSend,
    this.progress,
  });

  final nsd.Service peer;
  final Color color;
  final VoidCallback onSend;

  /// 이 사람에게 보내는 중이면 0~1(0은 상대 수락을 기다리는 중), 아니면
  /// null. 보내는 중엔 버튼을 막아 같은 사람에게 겹쳐 보내지 않게 한다.
  final double? progress;

  String get _buttonLabel {
    final p = progress;
    if (p == null) return '보내기';
    if (p <= 0) return '수락 대기';
    return '${(p * 100).round()}%';
  }

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
          Pressable(
            onTap: onSend,
            enabled: progress == null,
            pressedScale: 0.93,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Text(
                  _buttonLabel,
                  style: const TextStyle(
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
