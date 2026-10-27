import 'package:flutter/material.dart';

import 'models/saved_timetable.dart';
import 'services/saved_timetable_storage.dart';
import '../../theme/app_colors.dart';
import '../../widgets/mascot_sticker.dart';

/// "저장한 시간표" 목록 화면(상태 9). 전부 로컬(SharedPreferences) 저장분이다.
///
/// 항목의 "시간표로 보기"를 누르면 그 저장분을 [Navigator.pop]으로 돌려줘서
/// 호출한 쪽(TimetableScreen)이 현재 그리드에 반영하게 한다.
class SavedTimetablesScreen extends StatefulWidget {
  const SavedTimetablesScreen({super.key, required this.storage});

  final SavedTimetableStorage storage;

  @override
  State<SavedTimetablesScreen> createState() => _SavedTimetablesScreenState();
}

class _SavedTimetablesScreenState extends State<SavedTimetablesScreen> {
  List<SavedTimetable> _items = [];
  bool _loading = true;
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await widget.storage.loadAll();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _delete(SavedTimetable item) async {
    await widget.storage.delete(item.id);
    await _load();
  }

  String _formatSavedAt(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}.${two(dt.month)}.${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cobalt,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppColors.cobaltDeep,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lime,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '내 시간표 ${_items.length}개',
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '저장한 시간표',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.04,
                        ),
                      ),
                    ],
                  ),
                  const Positioned(
                    right: -180,
                    top: 40,
                    child: MascotSticker(width: 100, angle: 0.08),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : _items.isEmpty
                  ? const Center(
                      child: Text(
                        '저장한 시간표가 없어요',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: _items.length,
                      itemBuilder: (context, index) =>
                          _buildCard(_items[index], index),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(SavedTimetable item, int index) {
    final expanded = _expandedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _expandedIndex = expanded ? null : index),
      onLongPress: () => _delete(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.2),
              offset: const Offset(0, 6),
              blurRadius: 14,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.year}년 ${item.semester}학기 · '
                        '${item.courses.length}개 과목',
                        style: const TextStyle(
                          color: Color(0xFF6B6B70),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _formatSavedAt(item.savedAt),
                        style: const TextStyle(
                          color: Color(0xFF6B6B70),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cobalt,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    '시간표로 보기',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            if (expanded) ...[
              const SizedBox(height: 10),
              const Divider(color: Color(0xFFE5E5EA)),
              for (final course in item.courses)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    '${course.courseName} · ${course.professor} · '
                    '${course.rawSchedule}',
                    style: const TextStyle(
                      color: Color(0xFF6B6B70),
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
