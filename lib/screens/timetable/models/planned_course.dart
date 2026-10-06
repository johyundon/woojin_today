import '../../../services/course_catalog_service.dart';

/// 시간표 짜기 화면(이 feature) 전용 과목 모델.
///
/// [CourseCatalogService]가 돌려주는 [CourseCatalogItem]을 그대로 화면에 써도
/// 되지만, 이 화면은 "저장한 시간표"를 로컬(SharedPreferences)에 JSON으로
/// 직렬화해야 한다. [CourseCatalogItem]에는 JSON 직렬화 메서드가 없고(서비스
/// 레이어 책임이 아님), 서비스 파일에 화면 전용 직렬화 로직을 추가하는 건
/// 책임 분리를 어기는 것 같아 이 화면 전용으로 얇은 래퍼를 둔다.
class PlannedCourse {
  const PlannedCourse({
    required this.courseCode,
    required this.section,
    required this.courseName,
    required this.courseType,
    required this.credit,
    required this.targetGrade,
    required this.professor,
    required this.rawSchedule,
    required this.room,
    required this.enrollmentRatio,
    this.note,
  });

  final String courseCode;
  final String section;
  final String courseName;
  final String courseType;
  final double credit;
  final String targetGrade;
  final String professor;
  final String rawSchedule;
  final String room;
  final String enrollmentRatio;
  final String? note;

  /// "과목코드-분반" — 시간표 안에서 과목을 구분/중복 제거하는 키.
  String get key => '$courseCode-$section';

  factory PlannedCourse.fromCatalogItem(CourseCatalogItem item) {
    return PlannedCourse(
      courseCode: item.courseCode,
      section: item.section,
      courseName: item.courseName,
      courseType: item.courseType,
      credit: item.credit,
      targetGrade: item.targetGrade,
      professor: item.professor,
      rawSchedule: item.rawSchedule,
      room: item.room,
      enrollmentRatio: item.enrollmentRatio,
      note: item.note,
    );
  }

  Map<String, dynamic> toJson() => {
    'courseCode': courseCode,
    'section': section,
    'courseName': courseName,
    'courseType': courseType,
    'credit': credit,
    'targetGrade': targetGrade,
    'professor': professor,
    'rawSchedule': rawSchedule,
    'room': room,
    'enrollmentRatio': enrollmentRatio,
    'note': note,
  };

  factory PlannedCourse.fromJson(Map<String, dynamic> json) {
    return PlannedCourse(
      courseCode: json['courseCode'] as String,
      section: json['section'] as String,
      courseName: json['courseName'] as String,
      courseType: json['courseType'] as String,
      credit: (json['credit'] as num).toDouble(),
      targetGrade: json['targetGrade'] as String,
      professor: json['professor'] as String,
      rawSchedule: json['rawSchedule'] as String,
      room: json['room'] as String,
      enrollmentRatio: json['enrollmentRatio'] as String,
      note: json['note'] as String?,
    );
  }
}
