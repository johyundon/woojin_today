import 'planned_course.dart';

/// "시간표 저장" 한 건. 로컬(SharedPreferences)에만 저장된다 — API
/// 명세서에 "저장한 시간표"에 대응하는 서버 엔드포인트가 없기 때문이다
/// (lib/screens/timetable/services/saved_timetable_storage.dart 참고).
class SavedTimetable {
  const SavedTimetable({
    required this.id,
    required this.name,
    required this.year,
    required this.semester,
    required this.savedAt,
    required this.courses,
  });

  /// 저장 시각(밀리초 epoch)을 문자열로 쓴 고유 id. 같은 밀리초에 두 번
  /// 저장될 일은 사실상 없어 간단히 이걸로 충분하다.
  final String id;
  final String name;
  final int year;
  final int semester;
  final DateTime savedAt;
  final List<PlannedCourse> courses;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'year': year,
    'semester': semester,
    'savedAt': savedAt.toIso8601String(),
    'courses': courses.map((c) => c.toJson()).toList(),
  };

  factory SavedTimetable.fromJson(Map<String, dynamic> json) {
    return SavedTimetable(
      id: json['id'] as String,
      name: json['name'] as String,
      year: json['year'] as int,
      semester: json['semester'] as int,
      savedAt: DateTime.parse(json['savedAt'] as String),
      courses: (json['courses'] as List<dynamic>)
          .map((c) => PlannedCourse.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}
