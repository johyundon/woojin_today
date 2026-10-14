import 'package:flutter/material.dart';

import '../services/terms_acceptance_storage.dart';
import '../theme/app_colors.dart';
import '../widgets/app_checkbox_row.dart';
import '../widgets/mascot_sticker.dart';
import '../widgets/primary_button.dart';
import 'onboarding_screen.dart';
import 'terms_detail_screen.dart';

/// 이용약관 동의 화면 (Figma node 6:4).
///
/// v4 리디자인부터 로그인 "이후"에 최초 1회만 보여주는 화면으로 옮겨졌다
/// (관련 결정: onboarding_screen.dart, login_screen.dart). 그래서 로그인에서
/// 받은 세션 쿠키를 그대로 들고 있다가, 동의가 끝나면 온보딩 화면으로
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
        builder: (_) => OnboardingScreen(
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
      backgroundColor: AppColors.cobalt,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 210,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 원 → 마스코트 → 글자 순서로 겹친다.
                  Positioned(
                    right: -70,
                    top: 20,
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: const BoxDecoration(
                        color: AppColors.cobaltDeep,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const Positioned(
                    right: 28,
                    top: 20,
                    child: MascotSticker(width: 130, angle: 0.08),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lime,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '시작하기',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          '이용약관에\n동의해 주세요',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  20,
                  24,
                  20,
                  24 + MediaQuery.of(context).padding.bottom,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      offset: const Offset(0, -12),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '서비스 이용을 위해 아래 약관을 확인하고 모두 동의해주세요',
                      style: TextStyle(color: Color(0xFF5A5852), fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9EEFC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: AppCheckboxRow(
                        label: '전체 동의합니다',
                        checked: _allChecked,
                        onChanged: _toggleAll,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        labelStyle: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Color(0xFFEDEBE6), height: 1),
                    AppCheckboxRow(
                      label: '이용약관 동의 (필수)',
                      checked: _termsChecked,
                      onChanged: (v) => setState(() => _termsChecked = v),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      onViewPressed: () => _openDetail(
                        '이용약관',
                        TermsDetailScreen.termsOfServiceBody,
                      ),
                    ),
                    AppCheckboxRow(
                      label: '개인정보 처리방침 동의 (필수)',
                      checked: _privacyChecked,
                      onChanged: (v) => setState(() => _privacyChecked = v),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
