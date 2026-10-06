import 'package:flutter/material.dart';

import 'models/saved_timetable.dart';
import 'services/saved_timetable_storage.dart';
import 'timetable_colors.dart';

/// "저장한 시간표" 목록 화면(상태 9). 전부 로컬(SharedPreferences) 저장분이다.
///
/// 항목의 "시간표로 보기"를 누르면 그 저장분을 [Navigator.pop]으로 돌려줘서
/// 호출한 쪽(TimetableScreen)이 현재 그리드에 반영하게 한다.
class SavedTimetablesScreen extends StatefulWidget {
  const SavedTimetablesScreen({required this.storage});

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
      backgroundColor: TimetableColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
              child: Row(
                children: [
                  const Text(
                    '저장한 시간표',
                    style: TextStyle(
                      color: TimetableColors.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: TimetableColors.textPrimary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: TimetableColors.accent,
                      ),
                    )
                  : _items.isEmpty
                  ? const Center(
                      child: Text(
                        '저장한 시간표가 없어요',
                        style: TextStyle(color: TimetableColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final expanded = _expandedIndex == index;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: TimetableColors.surface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () => _delete(item),
                                    child: const Padding(
                                      padding: EdgeInsets.only(
                                        right: 8,
                                        top: 2,
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        color: TimetableColors.danger,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            color: TimetableColors.textPrimary,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${item.year}년 ${item.semester}학기 · '
                                          '${item.courses.length}개 과목 · '
                                          '${_formatSavedAt(item.savedAt)}',
                                          style: const TextStyle(
                                            color:
                                                TimetableColors.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Spacer(),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(item),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: TimetableColors.accent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: const Text(
                                      '시간표로 보기',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      expanded
                                          ? Icons.expand_less
                                          : Icons.expand_more,
                                      color: TimetableColors.textSecondary,
                                    ),
                                    onPressed: () => setState(() {
                                      _expandedIndex = expanded ? null : index;
                                    }),
                                  ),
                                ],
                              ),
                              if (expanded) ...[
                                const Divider(color: TimetableColors.border),
                                for (final course in item.courses)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 3,
                                    ),
                                    child: Text(
                                      '${course.courseName} · ${course.professor} · '
                                      '${course.rawSchedule}',
                                      style: const TextStyle(
                                        color: TimetableColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
