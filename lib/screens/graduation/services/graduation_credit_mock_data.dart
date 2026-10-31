import '../models/graduation_credit.dart';

/// "졸업학점" 화면 예시 데이터(지금 화면은 쓰지 않는다).
///
/// 화면은 학교 수강신청 시스템의 "이수구분표"(`GraduationCreditService`)에서
/// 실제 값을 받아 그린다(2026-10-31 연결). 이 파일은 디자인을 확인하거나 나중에
/// 예시가 필요할 때를 위해 남겨 둔 것이다.
///
/// 과목명·학점·성적은 전부 가상으로 지어낸 예시이고(실제 누군가의 성적표가
/// 아니다), 이수구분 이름도 학교 표(교필·교선·전필·전선 등)와 다르다.
class GraduationCreditMockData {
  GraduationCreditMockData._();

  static const int totalRequired = 130;
  static const double gpa = 4.21;
  static const double gpaMinimum = 2.00;

  static const List<GraduationCreditCategory> categories = [
    GraduationCreditCategory(
      label: '주전공',
      earned: 27,
      required: 60,
      courses: [
        GraduationCourseRecord(
          name: '자료구조',
          semester: '2022-1',
          credit: 3,
          grade: 'A+',
        ),
        GraduationCourseRecord(
          name: '컴퓨터구조',
          semester: '2022-2',
          credit: 3,
          grade: 'A',
        ),
        GraduationCourseRecord(
          name: '운영체제',
          semester: '2023-1',
          credit: 3,
          grade: 'A+',
        ),
        GraduationCourseRecord(
          name: '데이터베이스',
          semester: '2023-1',
          credit: 3,
          grade: 'B+',
        ),
        GraduationCourseRecord(
          name: '알고리즘',
          semester: '2023-2',
          credit: 3,
          grade: 'A',
        ),
        GraduationCourseRecord(
          name: '소프트웨어공학',
          semester: '2023-2',
          credit: 3,
          grade: 'A+',
        ),
        GraduationCourseRecord(
          name: '컴퓨터네트워크',
          semester: '2024-1',
          credit: 3,
          grade: 'A',
        ),
        GraduationCourseRecord(
          name: '인공지능개론',
          semester: '2024-1',
          credit: 3,
          grade: 'A+',
        ),
        GraduationCourseRecord(
          name: '캡스톤디자인1',
          semester: '2024-2',
          credit: 3,
          grade: 'A',
        ),
      ],
    ),
    GraduationCreditCategory(label: '복수전공', earned: 0, required: 36),
    GraduationCreditCategory(
      label: '교양필수',
      earned: 13,
      required: 12,
      courses: [
        GraduationCourseRecord(
          name: '글쓰기와표현',
          semester: '2021-1',
          credit: 2,
          grade: 'A',
        ),
        GraduationCourseRecord(
          name: '대학생활과진로',
          semester: '2021-1',
          credit: 2,
          grade: 'P',
        ),
        GraduationCourseRecord(
          name: '영어회화',
          semester: '2021-2',
          credit: 2,
          grade: 'B+',
        ),
        GraduationCourseRecord(
          name: '컴퓨팅사고와문제해결',
          semester: '2021-2',
          credit: 2,
          grade: 'A+',
        ),
        GraduationCourseRecord(
          name: '창의적사고와표현',
          semester: '2022-1',
          credit: 2,
          grade: 'A',
        ),
        GraduationCourseRecord(
          name: '진로와취업설계',
          semester: '2022-2',
          credit: 3,
          grade: 'P',
        ),
      ],
    ),
    GraduationCreditCategory(
      label: '교양선택',
      earned: 19,
      required: 18,
      courses: [
        GraduationCourseRecord(
          name: '역사의이해',
          semester: '2021-1',
          credit: 3,
          grade: 'A',
        ),
        GraduationCourseRecord(
          name: '심리학의이해',
          semester: '2021-2',
          credit: 3,
          grade: 'A+',
        ),
        GraduationCourseRecord(
          name: '예술과문화',
          semester: '2022-1',
          credit: 3,
          grade: 'B+',
        ),
        GraduationCourseRecord(
          name: '스포츠과학',
          semester: '2022-1',
          credit: 2,
          grade: 'A',
        ),
        GraduationCourseRecord(
          name: '경제의이해',
          semester: '2022-2',
          credit: 3,
          grade: 'A',
        ),
        GraduationCourseRecord(
          name: '환경과생태',
          semester: '2023-1',
          credit: 2,
          grade: 'B+',
        ),
        GraduationCourseRecord(
          name: '세계문화의이해',
          semester: '2023-2',
          credit: 3,
          grade: 'A+',
        ),
      ],
    ),
    GraduationCreditCategory(
      label: '일반선택',
      earned: 9,
      required: 15,
      courses: [
        GraduationCourseRecord(
          name: '교양체육',
          semester: '2021-1',
          credit: 3,
          grade: 'P',
        ),
        GraduationCourseRecord(
          name: '봉사활동',
          semester: '2021-2',
          credit: 3,
          grade: 'P',
        ),
        GraduationCourseRecord(
          name: '진로탐색세미나',
          semester: '2022-1',
          credit: 3,
          grade: 'B+',
        ),
      ],
    ),
    GraduationCreditCategory(
      label: '전공선택',
      earned: 27,
      required: 24,
      courses: [
        GraduationCourseRecord(
          name: '모바일프로그래밍',
          semester: '2022-2',
          credit: 3,
          grade: 'A+',
        ),
        GraduationCourseRecord(
          name: '웹프로그래밍',
          semester: '2023-1',
          credit: 3,
          grade: 'A',
        ),
        GraduationCourseRecord(
          name: '정보보안개론',
          semester: '2023-1',
          credit: 3,
          grade: 'A+',
        ),
        GraduationCourseRecord(
          name: '클라우드컴퓨팅',
          semester: '2023-2',
          credit: 3,
          grade: 'B+',
        ),
        GraduationCourseRecord(
          name: '모바일앱개발',
          semester: '2023-2',
          credit: 3,
          grade: 'A',
        ),
        GraduationCourseRecord(
          name: '객체지향프로그래밍',
          semester: '2024-1',
          credit: 3,
          grade: 'A+',
        ),
        GraduationCourseRecord(
          name: '머신러닝기초',
          semester: '2024-1',
          credit: 3,
          grade: 'A',
        ),
        GraduationCourseRecord(
          name: '임베디드시스템',
          semester: '2024-2',
          credit: 3,
          grade: 'A',
        ),
        GraduationCourseRecord(
          name: '캡스톤디자인2',
          semester: '2024-2',
          credit: 3,
          grade: 'A+',
        ),
      ],
    ),
  ];

  static const List<GraduationAreaProgress> areas = [
    GraduationAreaProgress(label: '1영역', earned: 2, required: 1),
    GraduationAreaProgress(label: '2영역', earned: 2, required: 1),
    GraduationAreaProgress(label: '3영역', earned: 1, required: 1),
    GraduationAreaProgress(label: '4영역', earned: 3, required: 2),
    GraduationAreaProgress(label: '5영역', earned: 1, required: 2),
  ];

  static const List<GraduationAreaProgress> detailAreas = [
    GraduationAreaProgress(label: 'B', earned: 0, required: 0),
    GraduationAreaProgress(label: 'C', earned: 0, required: 0),
    GraduationAreaProgress(label: '실용', earned: 2, required: 2),
    GraduationAreaProgress(label: '외국어', earned: 3, required: 2),
    GraduationAreaProgress(label: '심화', earned: 1, required: 2),
  ];

  static int get totalEarned => categories.fold(0, (sum, c) => sum + c.earned);
}
