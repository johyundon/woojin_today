import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/saved_timetable.dart';
import 'services/saved_timetable_storage.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pressable.dart';

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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
                child: Pressable.icon(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textStrong,
                      size: 15,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blueSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '내 시간표 ${_items.length}개',
                        style: const TextStyle(
                          color: AppColors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '저장한 시간표',
                      style: TextStyle(
                        color: AppColors.textStrong,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.04,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.blue),
                      )
                    : _items.isEmpty
                    ? const Center(
                        child: Text(
                          '저장한 시간표가 없어요',
                          style: TextStyle(
                            color: AppColors.textSub,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                        itemCount: _items.length,
                        itemBuilder: (context, index) =>
                            _buildCard(_items[index], index),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(SavedTimetable item, int index) {
    final expanded = _expandedIndex == index;
    const subStyle = TextStyle(
      color: AppColors.textSub,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.4,
    );
    return GestureDetector(
      onTap: () => setState(() => _expandedIndex = expanded ? null : index),
      onLongPress: () => _delete(item),
      child: Pressable.effect(
        pressedScale: 0.98,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.cardShadow,
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
                            color: AppColors.textStrong,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.year}년 ${item.semester}학기 · '
                          '${item.courses.length}개 과목',
                          style: subStyle,
                        ),
                        Text(_formatSavedAt(item.savedAt), style: subStyle),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Pressable(
                    pressedScale: 0.93,
                    onTap: () => Navigator.of(context).pop(item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '시간표로 보기',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (expanded) ...[
                const SizedBox(height: 10),
                const Divider(color: AppColors.line, height: 17),
                for (final course in item.courses)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(
                      '${course.courseName} · ${course.professor} · '
                      '${course.rawSchedule}',
                      style: subStyle,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
