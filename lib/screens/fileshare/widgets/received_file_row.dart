import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
import '../received_file.dart';
import '../received_file_format.dart';

/// 받은 파일 한 줄(v7) — 형식별 배지 + 파일명 + 용량 + 받은 시각 + 다운로드.
class ReceivedFileRow extends StatelessWidget {
  const ReceivedFileRow({
    super.key,
    required this.entry,
    required this.onDownload,
  });

  final ReceivedFile entry;
  final VoidCallback onDownload;

  String get _name => fileNameFromPath(entry.file.path);

  String get _extension => fileExtension(_name);

  Color get _badgeColor => badgeColorForExtension(_extension);

  IconData get _icon => iconForExtension(_extension);

  Color get _iconColor => iconColorForExtension(_extension);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.fill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _badgeColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, color: _iconColor, size: 19),
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
                    color: AppColors.textStrong,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.28,
                  ),
                ),
                if (entry.sizeBytes != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    formatBytes(entry.sizeBytes!),
                    style: const TextStyle(
                      color: AppColors.textSub,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            relativeTime(entry.receivedAt),
            style: const TextStyle(
              color: AppColors.textSub,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Pressable.icon(
            onTap: onDownload,
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.download_rounded,
                color: AppColors.blue,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
