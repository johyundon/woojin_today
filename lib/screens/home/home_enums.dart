// 홈 화면 전용 enum. [AvatarMenuAction]은 `widgets/my_menu_sheet.dart`,
// [StudentInfoErrorKind]는 `widgets/my_info_dialog.dart`에서 함께 쓰므로
// 화면 레벨 공용 파일로 분리했다.

/// 좌상단 아바타를 눌렀을 때 뜨는 드롭다운 메뉴 항목 (Figma node 6:16).
enum AvatarMenuAction { myInfo, terms, logout }

/// "내 정보" 조회 실패 원인. 원인마다 사용자에게 보여줄 안내/행동이 다르므로
/// (세션 만료 → 재로그인 유도, 네트워크/서버 오류 → 재시도, 파싱 실패 →
/// 알 수 없는 오류) 하나의 뭉뚱그린 에러 상태로 합치지 않는다.
enum StudentInfoErrorKind { sessionExpired, network, server, parse }
