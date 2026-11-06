import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'pressable.dart';

/// 오류 안내 글자색(v7 디자인 07의 빨강).
const _errorRed = Color(0xFFCC272E);

/// 버튼 그라데이션 시작색 rgb(43, 140, 240)(v7 디자인 04 로그인 버튼).
const _gradientStart = Color(0xFF2B8CF0);

/// 자동 로그인을 끄고 로그인해 기기에 학번·비밀번호가 없을 때 받는 입력 폼.
/// 입력한 값은 이 화면에서만 쓰고 저장하지 않는다. 학과 등수·마일리지 화면이 같이 쓴다.
///
/// 모양은 v7 로그인 화면(디자인 04)의 입력칸·버튼과 같다. 앱 테마가 아직 어두운
/// 테마라 글자색은 모두 직접 정해 둔다(안 정하면 흰 바탕에 흰 글자가 된다).
class TwinCredentialsForm extends StatelessWidget {
  const TwinCredentialsForm({
    required this.idController,
    required this.pwController,
    required this.error,
    required this.description,
    required this.buttonLabel,
    required this.onSubmit,
    super.key,
  });

  final TextEditingController idController;
  final TextEditingController pwController;
  final String? error;

  /// 제목 아래 안내 문구(무엇을 가져오는지).
  final String description;

  /// 버튼 글자(예: "등수 보기").
  final String buttonLabel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '학번과 비밀번호가 필요해요',
            style: TextStyle(
              color: AppColors.textStrong,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.textSub,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          _CredentialField(
            icon: Icons.badge_rounded,
            label: '학번',
            controller: idController,
            keyboardType: TextInputType.number,
            valueStyle: const TextStyle(
              color: AppColors.textStrong,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.48,
            ),
          ),
          const SizedBox(height: 12),
          _CredentialField(
            icon: Icons.lock_rounded,
            label: '비밀번호',
            controller: pwController,
            obscureText: true,
            onSubmitted: (_) => onSubmit(),
            valueStyle: const TextStyle(
              color: AppColors.textStrong,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: 3.4,
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(
              error!,
              style: const TextStyle(
                color: _errorRed,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Pressable.effect(
            pressedScale: 0.96,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_gradientStart, AppColors.blue],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppColors.cardShadow,
              ),
              child: ElevatedButton(
                onPressed: onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  buttonLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 아이콘 상자 + 라벨 + 입력창 한 칸(디자인 04). 입력 중(포커스)에는 파란
/// 테두리와 파란 아이콘 상자로 바뀐다.
class _CredentialField extends StatefulWidget {
  const _CredentialField({
    required this.icon,
    required this.label,
    required this.controller,
    required this.valueStyle,
    this.obscureText = false,
    this.keyboardType,
    this.onSubmitted,
  });

  final IconData icon;
  final String label;
  final TextEditingController controller;
  final TextStyle valueStyle;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_CredentialField> createState() => _CredentialFieldState();
}

class _CredentialFieldState extends State<_CredentialField> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 라벨을 눌러도 입력창에 포커스가 가도록 칸 전체를 탭 영역으로 둔다.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _focusNode.requestFocus,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(16),
          border: _focused
              ? Border.all(color: AppColors.blue, width: 2)
              : Border.all(color: AppColors.fillDisabled),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _focused ? AppColors.blue : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                widget.icon,
                size: 19,
                color: _focused ? Colors.white : AppColors.blue,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: AppColors.textBody,
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 어두운 앱 테마의 주황 선택 손잡이 대신 파랑을 쓴다.
                  TextSelectionTheme(
                    data: const TextSelectionThemeData(
                      cursorColor: AppColors.blue,
                      selectionColor: AppColors.blueSoftLine,
                      selectionHandleColor: AppColors.blue,
                    ),
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      keyboardType: widget.keyboardType,
                      obscureText: widget.obscureText,
                      obscuringCharacter: '•',
                      onSubmitted: widget.onSubmitted,
                      cursorColor: AppColors.blue,
                      cursorWidth: 2,
                      style: widget.valueStyle,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
