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
    this.required,
  });

  final String label;
  final int earned;

  /// 학교 표에서 기준 칸이 비어 있으면 null(기준과 비교하지 않는다).
  final int? required;
}

/// 학교 "이수구분표" 한 장에서 읽은 졸업학점 전체 현황.
///
/// 응답에 없는 값은 지어내지 않고 null로 둔다.
class GraduationCreditSummary {
  const GraduationCreditSummary({
    this.totalRequired,
    this.totalEarned,
    this.gpa,
    this.gpaMinimum,
    this.categories = const [],
    this.areas = const [],
    this.rules = const [],
    required this.fetchedAt,
  });

  /// 졸업학점 기준(예: 126)과 지금까지 취득 학점(이번 학기 수강 중 과목 포함).
  final int? totalRequired;
  final int? totalEarned;

  /// 졸업평점평균(취득)과 그 기준(예: 2.00).
  final double? gpa;
  final double? gpaMinimum;

  /// 이수구분(교필·교선·전필 등, 학교 소계 단위)별 학점과 과목.
  final List<GraduationCreditCategory> categories;

  /// 교양영역(1~9, A, B, C, 실용, 외국어, 심화)별 학점. 라벨은 학교 표 그대로다.
  final List<GraduationAreaProgress> areas;

  /// 표 아래 안내문(① ② ③ …) 문단들.
  final List<String> rules;

  final DateTime fetchedAt;

  Map<String, dynamic> toJson() => {
    'totalRequired': totalRequired,
    'totalEarned': totalEarned,
    'gpa': gpa,
    'gpaMinimum': gpaMinimum,
    'categories': [
      for (final c in categories)
        {
          'label': c.label,
          'earned': c.earned,
          'required': c.required,
          'courses': [
            for (final r in c.courses)
              {
                'name': r.name,
                'semester': r.semester,
                'credit': r.credit,
                'grade': r.grade,
              },
          ],
        },
    ],
    'areas': [
      for (final a in areas)
        {'label': a.label, 'earned': a.earned, 'required': a.required},
    ],
    'rules': rules,
    'fetchedAt': fetchedAt.toIso8601String(),
  };

  factory GraduationCreditSummary.fromJson(Map<String, dynamic> json) =>
      GraduationCreditSummary(
        totalRequired: json['totalRequired'] as int?,
        totalEarned: json['totalEarned'] as int?,
        gpa: (json['gpa'] as num?)?.toDouble(),
        gpaMinimum: (json['gpaMinimum'] as num?)?.toDouble(),
        categories: [
          for (final c in json['categories'] as List)
            GraduationCreditCategory(
              label: c['label'] as String,
              earned: c['earned'] as int,
              required: c['required'] as int?,
              courses: [
                for (final r in c['courses'] as List)
                  GraduationCourseRecord(
                    name: r['name'] as String,
                    semester: r['semester'] as String,
                    credit: r['credit'] as int,
                    grade: r['grade'] as String,
                  ),
              ],
            ),
        ],
        areas: [
          for (final a in json['areas'] as List)
            GraduationAreaProgress(
              label: a['label'] as String,
              earned: a['earned'] as int,
              required: a['required'] as int?,
            ),
        ],
        rules: [for (final r in json['rules'] as List) r as String],
        fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      );
}
