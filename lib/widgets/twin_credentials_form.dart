import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 자동 로그인을 끄고 로그인해 기기에 학번·비밀번호가 없을 때 받는 입력 폼.
/// 입력한 값은 이 화면에서만 쓰고 저장하지 않는다. 학과 등수·마일리지 화면이 같이 쓴다.
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
    InputDecoration decoration(String hint) => InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF1F1F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '학번과 비밀번호가 필요해요',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(color: Color(0xFF6B6B70), fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: idController,
            keyboardType: TextInputType.number,
            decoration: decoration('학번'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: pwController,
            obscureText: true,
            decoration: decoration('비밀번호'),
            onSubmitted: (_) => onSubmit(),
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(
              error!,
              style: const TextStyle(color: Color(0xFFE5484D), fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.cobalt,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              buttonLabel,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
