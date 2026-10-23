/// 영역(주전공/복수전공/교양필수 등) 하나의 이수 현황과, 그 영역에서 들은
/// 과목 상세 목록.
class GraduationCreditCategory {
  const GraduationCreditCategory({
    required this.label,
    required this.earned,
    this.required,
    this.courses = const [],
  });

  final String label;
  final int earned;

  /// null이면 이 영역엔 비교할 기준 학점을 보여주지 않는다(칩에 "54학점"처럼
  /// 총량만 보여주고 기준치와 비교하지 않음).
  final int? required;
  final List<GraduationCourseRecord> courses;

  int get courseCount => courses.length;

  int get remaining =>
      required == null ? 0 : (required! - earned).clamp(0, required!);

  bool get isDone => required != null && remaining == 0;
}

/// 과목 하나의 이수 기록(과목명 · 이수학기 · 학점 · 성적).
class GraduationCourseRecord {
  const GraduationCourseRecord({
    required this.name,
    required this.semester,
    required this.credit,
    required this.grade,
  });

  final String name;
  final String semester;
  final int credit;
  final String grade;
}

/// "영역별 이수현황"에 쓰이는 작은 항목(예: 교양 1영역) 하나.
class GraduationAreaProgress {
  const GraduationAreaProgress({
    required this.label,
    required this.earned,
    required this.required,
  });

  final String label;
  final int earned;
  final int required;
}
