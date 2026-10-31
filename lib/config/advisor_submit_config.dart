/// 지도교수 상담 신청을 실제 학교 서버로 보낼지.
///
/// 신청을 보내면 교수님께 진짜 상담 요청이 간다. 개발 중에는 반드시 false로
/// 둔다. false면 앱의 신청 버튼은 요청 없이 안내 배너만 띄우고, 서비스도
/// 테스트용 가짜 서버(MockClient)가 아니면 신청을 거부한다.
/// 사용자가 직접 허락하기 전에는 true로 바꾸지 않는다.
const bool kAllowRealAdvisorSubmit = false;
