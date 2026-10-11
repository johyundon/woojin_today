import '../models/graduation_credit.dart';

/// "졸업학점" 화면 목데이터.
///
/// *** 중요: 서버 API 없음 ***
/// API 명세서(daejin-api-spec-reference)에 이수학점/졸업사정 조회에
/// 대응하는 엔드포인트가 없다. 그래서 이 화면은 전부 하드코딩된 목데이터로
/// 동작한다 — 추측으로 서버 API를 만들어 호출하지 않는다. 나중에 실제
/// API가 생기면 이 파일만 교체하면 된다.
///
/// 학과/입학년도마다 실제 졸업 요건(필요 학점·영역 구성)이 다 달라서, 이
/// 숫자는 "화면이 어떻게 보일지" 보여주는 예시일 뿐 실제 본인 요건이 아니다
/// — 화면에도 안내 문구를 넣어 혼동하지 않게 한다.
class GraduationCreditMockData {
  GraduationCreditMockData._();

  static const List<GraduationCreditCategory> categories = [
    GraduationCreditCategory(label: '전공필수', required: 30, earned: 24),
    GraduationCreditCategory(label: '전공선택', required: 36, earned: 21),
    GraduationCreditCategory(label: '교양필수', required: 14, earned: 14),
    GraduationCreditCategory(label: '교양선택', required: 24, earned: 15),
    GraduationCreditCategory(label: '일반선택', required: 26, earned: 12),
  ];

  static int get totalRequired =>
      categories.fold(0, (sum, c) => sum + c.required);

  static int get totalEarned => categories.fold(0, (sum, c) => sum + c.earned);
}
