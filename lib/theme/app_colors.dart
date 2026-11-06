import 'package:flutter/material.dart';

/// Figma 노드(6:3, 6:4, 6:5)가 스크린샷으로 평탄화되어 있어 정확한 hex 값을
/// 추출할 수 없었다. 스크린샷을 눈으로 보고 근사한 다크 테마 + 오렌지 포인트
/// 컬러 팔레트.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0B0B0D);
  static const Color surface = Color(0xFF1C1C1F);
  static const Color border = Color(0xFF4A4A4E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9A9A9E);
  static const Color accent = Color(0xFFFF7A29);
  static const Color disabledButton = Color(0xFF2A2A2D);
  static const Color disabledButtonText = Color(0xFF7A7A7E);
  static const Color error = Color(0xFFFF5C5C);

  // "우진이의 하루 v4" 리디자인 팔레트. 디자인 캔버스 export(standalone.html)의
  // 스와치 범례를 브라우저에서 oklch -> canvas 2d(sRGB)로 변환해 얻은 정확한
  // hex 값이며, 섹션별로 화면을 새로 만들 때 이 쪽을 쓴다(기존 토큰은 아직
  // 리디자인되지 않은 화면을 위해 그대로 둔다).
  static const Color cobalt = Color(0xFF2857E5);
  static const Color cobaltDeep = Color(0xFF173EBB);
  static const Color lime = Color(0xFFD2F66B);
  static const Color blushPink = Color(0xFFFFACBE);
  static const Color ink = Color(0xFF121212);

  // "우진이의 하루 v7" 팔레트. 연한 배경에 파랑은 핵심 정보에만 쓰고 그림자는
  // 옅게 둔다. 디자인 보드(v7 standalone.html)를 브라우저에서 열어 계산된
  // 스타일 값을 그대로 옮겼다. 화면을 v7로 바꿀 때 이 쪽을 쓴다(위 값은 아직
  // 바꾸지 않은 화면을 위해 그대로 둔다).
  static const Color blue = Color(0xFF0A78E6);
  static const Color blueDeep = Color(0xFF0A5FC0);
  static const Color blueSoft = Color(0xFFEAF1FD);
  static const Color blueSoftLine = Color(0xFFD3E2F8);

  /// 선택된 탭 같은 파란 글자·아이콘.
  static const Color blueText = Color(0xFF0A66C8);

  /// 화면 바탕.
  static const Color canvas = Color(0xFFFCFCFD);

  /// 남색 섞인 진한 색(스와치 "잉크"). 어두운 카드 바탕 등에 쓴다.
  static const Color inkNavy = Color(0xFF3E4057);

  static const Color textStrong = Color(0xFF1F2024);
  static const Color textBody = Color(0xFF4B5056);
  static const Color textSub = Color(0xFF5F6368);
  static const Color textMuted = Color(0xFFA0A4AB);

  /// 입력칸·옅은 상자 바탕.
  static const Color fill = Color(0xFFF3F4F6);

  /// 비활성 버튼 바탕.
  static const Color fillDisabled = Color(0xFFE5E7EB);

  static const Color line = Color(0xFFE3E6EB);
  static const Color checkLine = Color(0xFFCFD3D9);

  /// 카드 그림자(검정 6%, 아래로 2, 번짐 14).
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x0F000000), offset: Offset(0, 2), blurRadius: 14),
  ];
}
