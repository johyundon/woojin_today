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
    return AlertDialog(
      backgroundColor: colors.cardSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '내 정보',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          ..._buildContent(context),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cobalt,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                '확인',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
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
    return [
      MyInfoRow(colors: colors, label: '이름', value: info?.name ?? '정보 없음'),
      const SizedBox(height: 14),
      MyInfoRow(
        colors: colors,
        label: '학과',
        value: info?.department ?? '정보 없음',
      ),
      const SizedBox(height: 14),
      MyInfoRow(colors: colors, label: '학년', value: info?.grade ?? '정보 없음'),
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
      Row(
        children: [
          Icon(icon, color: colors.textSecondary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
      if (error == StudentInfoErrorKind.sessionExpired) ...[
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onGoToLogin();
          },
          child: const Text('로그인 화면으로 이동'),
        ),
      ] else if (error == StudentInfoErrorKind.network ||
          error == StudentInfoErrorKind.server) ...[
        const SizedBox(height: 12),
        TextButton(onPressed: onRetry, child: const Text('다시 시도')),
      ],
    ];
  }
}
