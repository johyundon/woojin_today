import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../fileshare_colors.dart';
import '../received_file.dart';
import '../received_file_format.dart';

/// 받은 파일 한 줄 — 형식별 색 배지 + 파일명 + "용량 · 받은 시각" + 다운로드.
class ReceivedFileRow extends StatelessWidget {
  const ReceivedFileRow({super.key, required this.entry, required this.onDownload});

  final ReceivedFile entry;
  final VoidCallback onDownload;

  String get _name => fileNameFromPath(entry.file.path);

  String get _extension => fileExtension(_name);

  Color get _badgeColor => badgeColorForExtension(_extension);

  IconData get _icon => iconForExtension(_extension);

  String get _subtitle {
    final parts = <String>[
      if (entry.sizeBytes != null) formatBytes(entry.sizeBytes!),
      relativeTime(entry.receivedAt),
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F0F7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _badgeColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_icon, color: AppColors.ink, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle,
                  style: const TextStyle(color: mutedText, fontSize: 12),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDownload,
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.download_rounded,
                color: AppColors.cobalt,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
