import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
import '../services/mileage_roster_mock_data.dart';

/// "명단 (800명)" 다이얼로그 — 학번 검색 + 전체 학번 그리드.
/// 800개를 한 번에 렌더링하면 느려질 수 있어 `GridView.builder`로
/// 화면에 보이는 영역만 그린다.
///
/// [studentIds]는 학교 공지에 첨부된 실제 명단의 학번이다(기기에 저장하지
/// 않는다). 없으면 목데이터를 쓴다. [myId]가 명단에 있으면 그 칸을 강조한다.
Future<void> showMileageRosterDialog(
  BuildContext context, {
  List<String>? studentIds,
  String? myId,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _MileageRosterDialog(
      studentIds: studentIds ?? MileageRosterMockData.studentIds,
      myId: myId,
    ),
  );
}

class _MileageRosterDialog extends StatefulWidget {
  const _MileageRosterDialog({required this.studentIds, this.myId});

  final List<String> studentIds;
  final String? myId;

  @override
  State<_MileageRosterDialog> createState() => _MileageRosterDialogState();
}

class _MileageRosterDialogState extends State<_MileageRosterDialog> {
  final _searchController = TextEditingController();
  late List<String> _filtered = widget.studentIds;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      final q = query.trim();
      _filtered = q.isEmpty
          ? widget.studentIds
          : widget.studentIds.where((id) => id.contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        // 그리드를 고정 높이(360)로 두면 화면이 낮을 때(작은 기기, 테스트
        // 환경 등) 다이얼로그가 넘친다 — 다이얼로그 전체 높이를 화면의
        // 80%로 제한하고, 그리드만 Expanded로 남는 공간을 쓰게 한다.
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '명단 (${widget.studentIds.length}명)',
                style: const TextStyle(
                  color: AppColors.textStrong,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: AppColors.textStrong,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: '학번 검색',
                  hintStyle: const TextStyle(color: AppColors.textSub),
                  filled: true,
                  fillColor: const Color(0xFFF3F4F6),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: _filtered.isEmpty
                    ? const Center(
                        child: Text(
                          '검색 결과가 없어요',
                          style: TextStyle(
                            color: AppColors.textSub,
                            fontSize: 13,
                          ),
                        ),
                      )
                    : GridView.builder(
                        itemCount: _filtered.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 2.4,
                            ),
                        itemBuilder: (context, index) {
                          final id = _filtered[index];
                          final mine = id == widget.myId;
                          return Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: mine
                                  ? AppColors.blue
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              id,
                              style: TextStyle(
                                color: mine
                                    ? Colors.white
                                    : AppColors.textStrong,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: Pressable.effect(
                  pressedScale: 0.96,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.blue,
                      side: const BorderSide(color: AppColors.blueSoftLine),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '닫기',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
