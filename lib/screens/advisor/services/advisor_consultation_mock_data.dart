import '../models/advisor_consultation_models.dart';

/// "지도교수 상담" 화면의 예전 목데이터(v4 시안에서 읽은 값).
///
/// 이제 화면은 T-WIN 실제 데이터(`AdvisorConsultationService`)를 쓴다. 이
/// 파일에서 화면이 아직 쓰는 것은 방문 예약 가능 기간
/// ([visitBookingWindowStart]/[visitBookingWindowEnd])뿐이고, 나머지 값은
/// 시안 비교·디자인 확인용으로 남겨 둔다(지우지 않음).
class AdvisorConsultationMockData {
  AdvisorConsultationMockData._();

  // "우진이의 하루 v4" 시안(standalone.html, 13-1 화면)에서 그대로 읽은 값.
  static const int approvedCount = 10;
  static const int requiredCount = 12;

  static const List<String> semesterStatHeader = [
    '학기',
    '1학년',
    '2학년',
    '3학년',
    '4학년',
    '합계',
  ];

  // v4 시안에서 그대로 읽은 값(마지막 칸은 그 학기/전체 합계). 지어낸
  // 숫자 아님.
  static const List<SemesterStatRow> semesterStatRows = [
    SemesterStatRow(label: '1학기', values: ['3/2', '2/2', '1/1', '0/1', '6회']),
    SemesterStatRow(label: '2학기', values: ['2/2', '2/2', '0/1', '0/1', '4회']),
    SemesterStatRow(label: '합계', values: ['5회', '4회', '1회', '0회', '10회']),
  ];

  // 스크린샷(Figma node 6:121)에서 그대로 읽은 이력 2건.
  static const List<ConsultationHistory> history = [
    ConsultationHistory(
      date: '2026-08-17',
      method: '온라인상담',
      status: '학생 취소',
      detail: ConsultationDetail(
        appliedAt: '2026-08-17',
        status: '학생 취소',
        // 스크린샷엔 이 이력의 상세 내용이 보이지 않아, 학생 취소 상태에
        // 맞게 적당히 채운 값(지어낸 값, 실제 신청 내용 아님).
        content: '교수님 상담 신청드립니다.',
        // 학생이 취소한 상담이라 답변이 없는 상태.
        answeredAt: null,
        answerContent: null,
      ),
    ),
    ConsultationHistory(
      date: '2026-06-01',
      method: '온라인상담',
      status: '상담 완료',
      detail: ConsultationDetail(
        appliedAt: '2026-06-01',
        status: '상담 완료',
        content: '교수님 사랑합니다!',
        answeredAt: '2026-06-10',
        answerContent: '확인완료',
      ),
    ),
  ];

  // v4 시안의 검색 패널 예시(이시진/신완섭/정종진/김정민)를 그대로 쓴
  // 목데이터.
  static const List<ProfessorOption> otherProfessors = [
    ProfessorOption(name: '이시진', department: 'AI융합학부'),
    ProfessorOption(name: '신완섭', department: 'AI융합학부'),
    ProfessorOption(name: '정종진', department: 'AI융합학부'),
    ProfessorOption(name: '김정민', department: 'AI융합학부'),
  ];

  // 방문 상담 예약 가능 기간 — "오늘 ~ 오늘로부터 3개월"을 달력에서 고를 수
  // 있게 연다. 고른 날짜의 실제 가능 시간은 그때 T-WIN에 묻는다.
  static DateTime visitBookingWindowStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime visitBookingWindowEnd() =>
      visitBookingWindowStart().add(const Duration(days: 90));

  // 시안의 하루 상담 가능 시간대 예시(10~17시). 화면은 쓰지 않는다.
  static const List<String> visitAvailableTimes = [
    '10:00',
    '11:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
  ];
}
