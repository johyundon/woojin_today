import '../models/advisor_consultation_models.dart';

/// "지도교수 상담" 화면의 상담 현황/신청 목데이터.
///
/// *** 중요: 서버 API 없음 ***
/// API 명세서(daejin-api-spec-reference)에 상담 인정 횟수/이력 조회나 상담
/// 신청에 대응하는 엔드포인트가 없다. 그래서 지도교수 성함을 제외한 이
/// 화면의 데이터는 전부 하드코딩된 목데이터로만 동작한다 — 추측으로 서버
/// API를 만들어 호출하지 않는다. 나중에 실제 API가 생기면 이 파일만
/// 교체하면 된다.
class AdvisorConsultationMockData {
  AdvisorConsultationMockData._();

  // 스크린샷(Figma node 6:120)에서 그대로 읽은 값.
  static const int approvedCount = 10;
  static const int requiredCount = 12;

  static const List<String> semesterStatHeader = [
    '학기',
    '1학년',
    '2학년',
    '3학년',
    '4학년',
  ];

  // 스크린샷(Figma node 6:120)에서 그대로 읽은 값. 지어낸 숫자 아님.
  static const List<SemesterStatRow> semesterStatRows = [
    SemesterStatRow(label: '1학기', values: ['3/2', '2/2', '1/1', '0/1']),
    SemesterStatRow(label: '2학기', values: ['2/2', '2/2', '0/1', '0/1']),
    SemesterStatRow(label: '합계', values: ['5회', '4회', '1회', '0회']),
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

  // 스크린샷(Figma node 6:122)의 검색 패널 예시(이시진/신판섭/정종진/김정민,
  // 전부 "AI융합학부")를 그대로 쓴 목데이터.
  static const List<ProfessorOption> otherProfessors = [
    ProfessorOption(name: '이시진', department: 'AI융합학부'),
    ProfessorOption(name: '신판섭', department: 'AI융합학부'),
    ProfessorOption(name: '정종진', department: 'AI융합학부'),
    ProfessorOption(name: '김정민', department: 'AI융합학부'),
  ];
}
