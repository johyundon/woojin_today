import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
import '../services/mileage_roster_mock_data.dart';

/// "명단 (800명)" 다이얼로그 — 학번 검색 + 전체 학번 그리드.
/// 800개를 한 번에 렌더링하면 느려질 수 있어 `GridView.builder`로
/// 화면에 보이는 영역만 그린다.
Future<void> showMileageRosterDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _MileageRosterDialog(),
  );
}

class _MileageRosterDialog extends StatefulWidget {
  const _MileageRosterDialog();

  @override
  State<_MileageRosterDialog> createState() => _MileageRosterDialogState();
}

class _MileageRosterDialogState extends State<_MileageRosterDialog> {
  final _searchController = TextEditingController();
  List<String> _filtered = MileageRosterMockData.studentIds;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filtered = query.isEmpty
          ? MileageRosterMockData.studentIds
          : MileageRosterMockData.studentIds
                .where((id) => id.contains(query))
                .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                '명단 (${MileageRosterMockData.studentIds.length}명)',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: '학번 검색',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.disabledButton,
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
                            color: AppColors.textSecondary,
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
                        itemBuilder: (context, index) => Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.disabledButton,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _filtered[index],
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
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
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: const StadiumBorder(),
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
