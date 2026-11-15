import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';

/// 시간표 상단 한 줄(Figma 2152-1429 "05 시간표", 2026-11-16).
/// 왼쪽 "시간표" 제목과 연한 파란 학기 칩, 오른쪽 연필(과목 추가)과 햄버거 메뉴.
/// 예전 [TimetableHeader](뒤로가기·"내 시간표" 제목·마스코트·버튼 줄)를
/// 대신한다.
class TimetableTopBar extends StatelessWidget {
  const TimetableTopBar({
    super.key,
    required this.semesterLabel,
    required this.semesterKey,
    required this.onSemesterTap,
    required this.onMoreTap,
    this.onEditTap,
  });

  final String semesterLabel;

  /// 학기 메뉴 위치 계산용 — 학기 칩을 기준점으로 쓴다.
  final GlobalKey semesterKey;
  final VoidCallback onSemesterTap;
  final VoidCallback onMoreTap;

  /// 연필 버튼(과목 추가 창 열기). null이면 연필을 숨긴다(시안: 시간표가 비어
  /// 있을 때는 "시간표 만들기" 버튼이 대신한다).
  final VoidCallback? onEditTap;

  @override
  Widget build(BuildContext context) {
    final onEdit = onEditTap;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 10, 4),
      child: Row(
        children: [
          // 시안 캡처 비율(제목 약 18, 학기 칩 글자 약 12.5)에 맞춰 줄임
          // (사용자 요청, 2026-11-16).
          const Text(
            '시간표',
            style: TextStyle(
              color: AppColors.textStrong,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(width: 10),
          Pressable(
            key: semesterKey,
            onTap: onSemesterTap,
            child: Container(
              height: 32,
              padding: const EdgeInsets.only(left: 12, right: 8),
              decoration: BoxDecoration(
                color: AppColors.blueSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    semesterLabel,
                    style: const TextStyle(
                      color: AppColors.blueText,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.expand_more_rounded,
                    size: 16,
                    color: AppColors.blueText,
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          if (onEdit != null)
            Pressable.icon(
              key: const ValueKey('timetable-edit'),
              onTap: onEdit,
              // 시안(2152-1429 "만든 후 상태")의 연필: 테두리만 있는 둥근 네모 위에
              // 꽉 찬 연필이 걸친 모양, 짙은 회색(2026-11-16). 누르는 범위는 40.
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: Icon(
                    Icons.edit_square,
                    size: 22,
                    color: AppColors.textBody,
                  ),
                ),
              ),
            ),
          Pressable.icon(
            key: const ValueKey('timetable-more'),
            onTap: onMoreTap,
            child: const Padding(
              padding: EdgeInsets.all(8),
              // ⋮ 대신 햄버거(줄 세 개) 아이콘(사용자 요청, 2026-11-16).
              child: Icon(
                Icons.menu_rounded,
                size: 24,
                color: AppColors.textStrong,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ⋮ 메뉴에서 고를 수 있는 일.
enum TimetableMoreAction { loadMine, autoFill, save, savedList }

/// ⋮ 메뉴 시트. 예전 상단에 흩어져 있던 "내 시간표 불러오기"·"자동 생성"·
/// "저장"·"저장한 시간표"를 한곳에 모았다. 고른 일을 돌려주고, 닫으면 null.
Future<TimetableMoreAction?> showTimetableMoreSheet(
  BuildContext context, {
  required bool showLoadMine,
  required int savedCount,
}) {
  Widget item(
    BuildContext sheetContext,
    TimetableMoreAction action,
    IconData icon,
    String label,
  ) {
    return Pressable(
      onTap: () => Navigator.of(sheetContext).pop(action),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.transparent,
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textStrong),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textStrong,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  return showModalBottomSheet<TimetableMoreAction>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showLoadMine)
              item(
                sheetContext,
                TimetableMoreAction.loadMine,
                Icons.download_rounded,
                '내 시간표 불러오기',
              ),
            item(
              sheetContext,
              TimetableMoreAction.autoFill,
              Icons.auto_awesome_rounded,
              '자동 생성',
            ),
            item(
              sheetContext,
              TimetableMoreAction.save,
              Icons.bookmark_add_outlined,
              '저장',
            ),
            item(
              sheetContext,
              TimetableMoreAction.savedList,
              Icons.folder_open_rounded,
              savedCount > 0 ? '저장한 시간표 ($savedCount)' : '저장한 시간표',
            ),
          ],
        ),
      ),
    ),
  );
}
