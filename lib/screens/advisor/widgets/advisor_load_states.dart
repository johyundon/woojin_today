import 'package:flutter/material.dart';

import '../../../services/twin_client.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';

const Color _mutedText = Color(0xFF7C7B88);
const Color _chipBackground = Color(0xFFF1F0F7);

/// T-WIN 실패를 사용자에게 보여줄 문장으로 바꾼다.
String advisorErrorMessage(Object error) {
  if (error is TwinException) {
    return switch (error.failure) {
      TwinFailure.loginFailed => 'T-WIN 로그인에 실패했어요. 다시 로그인해 주세요.',
      TwinFailure.noData => '상담 정보를 불러오지 못했어요. 잠시 후 다시 시도해 주세요.',
      TwinFailure.network => '네트워크 연결을 확인해 주세요.',
    };
  }
  return '상담 정보를 불러오지 못했어요. 잠시 후 다시 시도해 주세요.';
}

/// 카드 안에서 쓰는 작은 로딩 표시.
class AdvisorLoadingBox extends StatelessWidget {
  const AdvisorLoadingBox({super.key, this.label = '불러오는 중...'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.cobalt,
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: _mutedText, fontSize: 13)),
        ],
      ),
    );
  }
}

/// 카드 안에서 쓰는 오류 안내 + "다시 시도" 버튼.
class AdvisorErrorBox extends StatelessWidget {
  const AdvisorErrorBox({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: _chipBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _mutedText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Pressable(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '다시 시도',
                style: TextStyle(
                  color: AppColors.cobalt,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 카드 안에서 쓰는 "내용 없음" 안내.
class AdvisorEmptyText extends StatelessWidget {
  const AdvisorEmptyText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _mutedText, fontSize: 13),
        ),
      ),
    );
  }
}
