import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/terms_acceptance_storage.dart';
import '../theme/app_colors.dart';
import '../widgets/app_checkbox_row.dart';
import '../widgets/mascot_sticker.dart';
import '../widgets/primary_button.dart';
import 'post_login_route.dart';
import 'terms_detail_screen.dart';

/// 이용약관 동의 화면 (Figma node 6:4).
///
/// v4 리디자인부터 로그인 "이후"에 학번별로 최초 1회만 보여주는 화면으로
/// 옮겨졌다(언제 보여줄지는 post_login_route.dart). 그래서 로그인에서 받은
/// 세션 쿠키를 그대로 들고 있다가, 동의가 끝나면 다음 화면(보통 온보딩)으로
/// 넘겨준다.
class TermsAgreementScreen extends StatefulWidget {
  const TermsAgreementScreen({
    super.key,
    required this.userId,
    this.jsessionId,
    this.wmonid,
    this.userId2,
  });

  /// 동의 기록을 저장할 학번.
  final String userId;
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
    await TermsAcceptanceStorage().markAccepted(widget.userId);
    // 온보딩을 이미 끝낸 사람(약관 버전이 바뀌어 다시 동의한 경우)은 온보딩
    // 없이 바로 넘어가도록, 다음 화면은 로그인 후 공통 규칙으로 고른다.
    final next = await postLoginScreen(
      userId: widget.userId,
      jsessionId: widget.jsessionId,
      wmonid: widget.wmonid,
      userId2: widget.userId2,
    );
    if (!mounted) return;
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => next));
  }

  /// 전체 동의 아래 구분선(디자인 값, 팔레트의 line보다 조금 옅다).
  static const _dividerColor = Color(0xFFE8EAEE);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    // 파란 머리 화면이라 상태 표시줄 글자(시계·배터리)를 흰색으로 그린다.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.blue,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 242,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 마스코트 → 글자 순서로 겹친다.
                    const Positioned(
                      right: 6,
                      top: 8,
                      child: MascotSticker(width: 156, angle: 0.1222),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 42, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.blueSoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '시작하기',
                              style: TextStyle(
                                color: AppColors.blue,
                                fontSize: 12,
                                height: 1.4,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '이용약관에\n동의해 주세요',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 29,
                              height: 1.4,
                              letterSpacing: -1.16,
                              fontWeight: FontWeight.w700,
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
                    22,
                    28,
                    22,
                    bottomInset + 10 > 44 ? bottomInset + 10 : 44,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(36),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x0F000000),
                        offset: Offset(0, -4),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '서비스 이용을 위해 아래 약관을 확인하고 모두 동의해주세요',
                          style: TextStyle(
                            color: AppColors.textSub,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: _allChecked
                              ? AppColors.blue.withValues(alpha: 0.1)
                              : AppColors.fill,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: AppCheckboxRow(
                          label: '전체 동의합니다',
                          checked: _allChecked,
                          onChanged: _toggleAll,
                          padding: const EdgeInsets.all(18),
                          labelStyle: TextStyle(
                            color: _allChecked
                                ? AppColors.textStrong
                                : AppColors.textBody,
                            fontSize: 15,
                            height: 1.4,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: _dividerColor, height: 1),
                      const SizedBox(height: 10),
                      AppCheckboxRow(
                        label: '이용약관 동의 (필수)',
                        checked: _termsChecked,
                        onChanged: (v) => setState(() => _termsChecked = v),
                        padding: _itemPadding,
                        labelStyle: _itemLabelStyle,
                        onViewPressed: () => _openDetail(
                          '이용약관',
                          TermsDetailScreen.termsOfServiceBody,
                        ),
                      ),
                      AppCheckboxRow(
                        label: '개인정보 처리방침 동의 (필수)',
                        checked: _privacyChecked,
                        onChanged: (v) => setState(() => _privacyChecked = v),
                        padding: _itemPadding,
                        labelStyle: _itemLabelStyle,
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
      ),
    );
  }

  static const _itemPadding = EdgeInsets.symmetric(horizontal: 4, vertical: 6);
  static const _itemLabelStyle = TextStyle(
    color: AppColors.textStrong,
    fontSize: 15,
    height: 1.4,
    fontWeight: FontWeight.w600,
  );
}
