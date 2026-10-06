import 'package:flutter/material.dart';

import '../home_colors.dart';

const List<String> _koreanWeekdays = ['월', '화', '수', '목', '금', '토', '일'];

/// "9월 5일 토요일" 형식의 날짜 문자열. [DateTime.weekday]는 월=1~일=7.
String _formatKoreanDate(DateTime date) {
  return '${date.month}월 ${date.day}일 ${_koreanWeekdays[date.weekday - 1]}요일';
}

/// 좌측 아바타 + 날짜/인사말 + 우측 라이트⇄다크 토글 스위치.
class Header extends StatelessWidget {
  const Header({
    required this.isDark,
    required this.colors,
    required this.avatarKey,
    required this.onAvatarTap,
    required this.onToggle,
    required this.greeting,
  });

  final bool isDark;
  final HomeColors colors;
  final GlobalKey avatarKey;
  final VoidCallback onAvatarTap;
  final ValueChanged<bool> onToggle;

  /// 날짜 아래 인사말. 기본값("오늘 하루도 화이팅!")은 지금이 사용자의 실제
  /// 수업 시간이면 "{과목명} 수업 화이팅!"으로 바뀐다(_HomeScreenState 참고).
  final String greeting;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onAvatarTap,
          child: ClipOval(
            child: Container(
              key: avatarKey,
              width: 52,
              height: 52,
              color: colors.avatarBackground,
              alignment: Alignment.center,
              // home_avatar.png는 원본 캔버스(230x230) 바닥 라인에 다리가
              // 그대로 걸쳐 잘려 있는 애셋이라(마진 0px), 어떤 레이아웃으로
              // 그려도 다리가 안 보였다. splash_character.png(전신, 다리까지
              // 포함)에서 배경색(#0A0A0B 단색, 투명 아님)만 크로마키로 제거해
              // assets/images/header_avatar.png를 새로 만들어 교체했다.
              child: FractionallySizedBox(
                widthFactor: 0.8,
                heightFactor: 0.8,
                child: Image.asset(
                  'assets/images/header_avatar.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatKoreanDate(DateTime.now()),
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                greeting,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Text(
          isDark ? '다크' : '화이트',
          style: TextStyle(color: colors.textSecondary, fontSize: 13),
        ),
        Switch(
          // Flutter Switch 기본 동작은 value=true일 때 썸이 오른쪽이다.
          // Figma 디자인상 라이트 모드일 때 썸이 오른쪽이므로 value는 '라이트 모드 여부'.
          value: !isDark,
          onChanged: (isLight) => onToggle(!isLight),
          activeThumbColor: accentOrange,
          activeTrackColor: colors.switchTrackLight,
          inactiveThumbColor: accentOrange,
          inactiveTrackColor: colors.switchTrackDark,
          trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ],
    );
  }
}
