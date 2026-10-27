import 'package:flutter/material.dart';

import '../../../services/student_info_service.dart';
import '../../../theme/app_colors.dart';
import '../home_colors.dart';
import '../home_enums.dart';
import 'my_info_row.dart';

/// "내 정보" 모달 (Figma node 6:17). 홈 화면 진입 시 미리 불러온(또는
/// 로딩/에러 중인) 학생 정보를 그대로 보여준다. 데이터/로딩/에러 상태는 전부
/// 홈 화면([State])이 들고 있고, 이 위젯은 그 상태를 받아 그리기만 한다.
class MyInfoDialog extends StatelessWidget {
  const MyInfoDialog({
    super.key,
    required this.colors,
    required this.loading,
    required this.data,
    required this.error,
    required this.onRetry,
    required this.onGoToLogin,
  });

  final HomeColors colors;
  final bool loading;
  final StudentInfoResponse? data;
  final StudentInfoErrorKind? error;

  /// "다시 시도" 버튼(네트워크/서버 오류일 때)을 눌렀을 때.
  final VoidCallback onRetry;

  /// "로그인 화면으로 이동" 버튼(세션 만료일 때)을 눌렀을 때. 이 다이얼로그를
  /// 닫는 것은 이 위젯이 직접 하고, 로그인 화면으로의 실제 이동은 호출부(홈
  /// 화면)에 맡긴다.
  final VoidCallback onGoToLogin;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: colors.cardSurface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.lime,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '내 정보',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ..._buildContent(context),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Text(
                      '확인',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 로딩/에러/성공 상태에 따른 "내 정보" 본문을 만든다.
  List<Widget> _buildContent(BuildContext context) {
    if (loading) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ),
      ];
    }

    final error = this.error;
    if (error != null) {
      return _buildError(context, error);
    }

    final info = data;
    final name = info?.name?.trim();
    final hasName = name != null && name.isNotEmpty;
    return [
      Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.cobalt,
              shape: BoxShape.circle,
            ),
            child: hasName
                ? Text(
                    String.fromCharCode(name.runes.first),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : const Icon(Icons.person, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              hasName ? name : '정보 없음',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),
      MyInfoRow(
        colors: colors,
        icon: Icons.school_rounded,
        label: '학과',
        value: info?.department ?? '정보 없음',
      ),
      const SizedBox(height: 10),
      MyInfoRow(
        colors: colors,
        icon: Icons.badge_rounded,
        label: '학년',
        value: info?.grade ?? '정보 없음',
      ),
    ];
  }

  /// 에러 원인별 안내 문구 + 복구 행동(재로그인 유도/재시도)을 구성한다.
  List<Widget> _buildError(BuildContext context, StudentInfoErrorKind error) {
    final (icon, message) = switch (error) {
      StudentInfoErrorKind.sessionExpired => (
        Icons.login,
        '로그인 정보를 찾을 수 없어요.\n다시 로그인해주세요.',
      ),
      StudentInfoErrorKind.network => (Icons.wifi_off, '네트워크 연결을 확인해주세요.'),
      StudentInfoErrorKind.server => (
        Icons.error_outline,
        '서버에 문제가 발생했어요.\n잠시 후 다시 시도해주세요.',
      ),
      StudentInfoErrorKind.parse => (
        Icons.error_outline,
        '정보를 불러오지 못했어요.\n(알 수 없는 오류)',
      ),
    };

    return [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F8),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.blushPink,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.ink, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
      if (error == StudentInfoErrorKind.sessionExpired) ...[
        const SizedBox(height: 12),
        _ActionButton(
          label: '로그인 화면으로 이동',
          onTap: () {
            Navigator.of(context).pop();
            onGoToLogin();
          },
        ),
      ] else if (error == StudentInfoErrorKind.network ||
          error == StudentInfoErrorKind.server) ...[
        const SizedBox(height: 12),
        _ActionButton(label: '다시 시도', onTap: onRetry),
      ],
    ];
  }
}

/// 오류 안내 아래의 복구 버튼(라임). 텍스트 버튼 대신 눈에 띄게 보여준다.
class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: AppColors.lime,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
