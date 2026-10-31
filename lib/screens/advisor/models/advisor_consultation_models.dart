/// "지도교수 상담" 신청 방식. 스크린샷에 "온라인 상담"/"방문 상담" 버튼
/// 2개만 보였다.
enum ConsultationMethod {
  online('온라인 상담'),
  visit('방문 상담');

  const ConsultationMethod(this.label);

  final String label;
}

/// 상담 이력 상세 — "상세보기" 다이얼로그에 쓰는 라벨-값 쌍.
///
/// [answeredAt]/[answerContent]는 학생이 상담을 취소한 경우처럼 아직(또는
/// 끝내) 답변이 없는 상태를 표현하기 위해 nullable이다.
class ConsultationDetail {
  const ConsultationDetail({
    required this.appliedAt,
    required this.status,
    required this.content,
    this.answeredAt,
    this.answerContent,
  });

  final String appliedAt;
  final String status;
  final String content;
  final String? answeredAt;
  final String? answerContent;
}

/// "지도교수 상담 현황" 탭 이력 리스트 한 줄. 지금은 목데이터
/// ([AdvisorConsultationMockData])에서만 쓴다 — 화면은 T-WIN 이력
/// (`ConsultationRecord`)을 쓴다.
class ConsultationHistory {
  const ConsultationHistory({
    required this.date,
    required this.method,
    required this.status,
    required this.detail,
  });

  final String date;
  final String method;
  final String status;
  final ConsultationDetail detail;
}

/// 학기별 상담 인정 횟수 표의 한 행("학기" 라벨 + 학년별 셀 값).
///
/// [label]이 '합계'인 행은 셀 값이 "N회" 형식(주황 강조)이고, 그 외 행은
/// "N/M" 형식(흰/회색)이다 — 렌더링 쪽에서 이 라벨로 구분한다.
class SemesterStatRow {
  const SemesterStatRow({required this.label, required this.values});

  final String label;
  final List<String> values;
}

/// 상담 신청 대상 교수 한 명. [isAdvisor]가 true면 본인의 지도교수(검색
/// 패널 첫 줄에 항상 고정)이고, 그 외에는 T-WIN 교수 검색 결과다.
class ProfessorOption {
  const ProfessorOption({
    required this.name,
    required this.department,
    this.staffNo,
    this.isAdvisor = false,
  });

  final String name;
  final String department;

  /// T-WIN 직번. 방문 시간 조회와 신청에 쓴다. 지도교수는 상담 현황을 다
  /// 불러오기 전까지 null일 수 있다.
  final String? staffNo;
  final bool isAdvisor;
}
