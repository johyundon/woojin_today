import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// 받은 파일의 경로/바이트/받은 시각을 화면에 보여줄 문자열·색상·아이콘으로
/// 바꾸는 순수 변환 함수들 — UI를 그리지 않고 입력값만으로 결과가 정해진다.

String fileNameFromPath(String path) {
  final idx = path.lastIndexOf('/');
  return idx == -1 ? path : path.substring(idx + 1);
}

String fileExtension(String fileName) {
  final dot = fileName.lastIndexOf('.');
  return dot == -1 ? '' : fileName.substring(dot + 1).toUpperCase();
}

Color badgeColorForExtension(String extension) => switch (extension) {
  'PDF' => AppColors.blushPink,
  'DOC' || 'DOCX' => AppColors.lime,
  _ => const Color(0xFFE4E3EC),
};

IconData iconForExtension(String extension) => switch (extension) {
  'PDF' => Icons.picture_as_pdf,
  'DOC' || 'DOCX' => Icons.description,
  'PPT' || 'PPTX' => Icons.slideshow,
  'ZIP' => Icons.folder_zip,
  _ => Icons.insert_drive_file,
};

String formatBytes(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
  if (bytes >= 1024) return '${(bytes / 1024).round()}KB';
  return '${bytes}B';
}

String relativeTime(DateTime at) {
  final diff = DateTime.now().difference(at);
  if (diff.inMinutes < 1) return '방금';
  if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
  if (diff.inHours < 24) return '${diff.inHours}시간 전';
  return '${diff.inDays}일 전';
}
