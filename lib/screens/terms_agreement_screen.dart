import 'package:flutter/material.dart';

import '../services/terms_acceptance_storage.dart';
import '../theme/app_colors.dart';
import '../widgets/app_checkbox_row.dart';
import '../widgets/primary_button.dart';
import 'student_id_login_complete_screen.dart';
import 'terms_detail_screen.dart';

/// 이용약관 동의 화면 (Figma node 6:4).
///
/// v4 리디자인부터 로그인 "이후"에 최초 1회만 보여주는 화면으로 옮겨졌다
/// (관련 결정: onboarding_screen.dart, login_screen.dart). 그래서 로그인에서
/// 받은 세션 쿠키를 그대로 들고 있다가, 동의가 끝나면 로그인 완료 화면으로
/// 넘겨준다.
class TermsAgreementScreen extends StatefulWidget {
  const TermsAgreementScreen({
    super.key,
    this.jsessionId,
    this.wmonid,
    this.userId2,
  });

  final String? jsessionId;
  final String? wmonid;
  final String? userId2;

  @override
  State<TermsAgreementScreen> createState() => _TermsAgreementScreenState();
}

class _TermsAgreementScreenState extends State<TermsAgreementScreen> {
  bool _termsChecked = false;
  bool _privacyChecked = false;

  bool get _allChecked => _termsChecked && _privacyChecked;

  void _toggleAll(bool value) {
    setState(() {
      _termsChecked = value;
      _privacyChecked = value;
    });
  }

  void _openDetail(String title, String body) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TermsDetailScreen(title: title, body: body),
      ),
    );
  }

  Future<void> _onSubmit() async {
    await TermsAcceptanceStorage().markAccepted();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => StudentIdLoginCompleteScreen(
          jsessionId: widget.jsessionId,
          wmonid: widget.wmonid,
          userId2: widget.userId2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                '이용약관 동의',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '서비스 이용을 위해 아래 약관을 확인하고 모두 동의해주세요',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: AppCheckboxRow(
                  label: '전체 동의합니다',
                  checked: _allChecked,
                  onChanged: _toggleAll,
                  labelStyle: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Divider(color: AppColors.border, height: 1),
              AppCheckboxRow(
                label: '이용약관 동의 (필수)',
                checked: _termsChecked,
                onChanged: (v) => setState(() => _termsChecked = v),
                onViewPressed: () =>
                    _openDetail('이용약관', TermsDetailScreen.termsOfServiceBody),
              ),
              AppCheckboxRow(
                label: '개인정보 처리방침 동의 (필수)',
                checked: _privacyChecked,
                onChanged: (v) => setState(() => _privacyChecked = v),
                onViewPressed: () => _openDetail(
                  '개인정보 처리방침',
                  TermsDetailScreen.privacyPolicyBody,
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: '동의하고 시작하기',
                enabled: _allChecked,
                onPressed: _onSubmit,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
