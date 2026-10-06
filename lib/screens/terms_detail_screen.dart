import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 약관 상세/전체보기 화면 (Figma node 6:5).
/// "이용약관 동의" 화면의 두 "보기" 링크(이용약관 / 개인정보 처리방침)가
/// 공통으로 사용하는 화면이라 title/body를 파라미터로 받는다.
class TermsDetailScreen extends StatelessWidget {
  const TermsDetailScreen({
    super.key,
    required this.title,
    required this.body,
    this.agreedAt,
  });

  final String title;
  final String body;
  final String? agreedAt;

  static const String termsOfServiceBody = '''
제1조 (목적)
본 약관은 "우진이의 하루" 애플리케이션(이하 "본 앱")의 개발자(이하 "운영자")가 제공하는 서비스의 이용조건 및 절차, 이용자와 운영자의 권리·의무·책임사항, 기타 필요한 사항을 규정함을 목적으로 합니다.

제2조 (용어의 정의)
본 약관에서 사용하는 용어의 정의는 다음과 같습니다.
1. "본 앱": 운영자가 개발·배포하는 안드로이드 애플리케이션 "우진이의 하루"를 말합니다.
2. "서비스": 운영자가 본 앱을 통해 이용자에게 제공하는 대진대학교 학사 관련 정보 연동 조회, 시간표 관리, 캘린더 알림, 광고 등 일체의 기능을 말합니다.
3. "이용자": 본 약관에 동의하고 본 앱을 다운로드하여 서비스를 이용하는 자를 말합니다.
4. "대진대학교 시스템": 대진대학교가 운영하는 dreams2.daejin.ac.kr, www.daejin.ac.kr, together.daejin.ac.kr 등 공식 웹 시스템을 말합니다.

제3조 (약관의 효력 및 변경)
1. 본 약관은 본 앱을 다운로드하여 최초 실행 시 이용자가 동의한 시점부터 효력이 발생합니다.
2. 운영자는 「약관의 규제에 관한 법률」, 「전기통신사업법」 등 관련 법령을 위배하지 않는 범위에서 본 약관을 개정할 수 있습니다.
3. 약관을 개정하는 경우 운영자는 개정 사유와 적용 일자를 명시하여 적용 일자 7일 전부터(이용자에게 불리하거나 중대한 변경의 경우 30일 전부터) 앱 내 공지사항 및 앱 실행 화면을 통해 공지합니다.
4. 이용자는 개정된 약관에 동의하지 않을 권리가 있으며, 이 경우 본 앱의 이용을 중단하고 앱을 삭제할 수 있습니다. 개정 약관 시행일 이후에도 서비스를 계속 이용하는 경우에는 개정 약관에 동의한 것으로 봅니다.

제4조 (약관 외 준칙)
[TODO: Figma 참고 스크린샷이 제4조 제목까지만 보이고 본문은 잘려서 확인 불가. 실제 약관 원문 확보 후 교체 필요. 아래는 임시 문구.]
본 약관에 명시되지 않은 사항은 관계 법령 및 운영자가 정한 서비스 운영정책에 따릅니다.

제5조 (이용자의 의무)
[TODO: 미확인 — 실제 약관 원문 확보 후 교체]
이용자는 본 약관 및 관계 법령에서 규정한 사항을 준수하여야 하며, 서비스를 본래의 이용 목적 이외의 용도로 사용해서는 안 됩니다.

제6조 (면책조항)
[TODO: 미확인 — 실제 약관 원문 확보 후 교체]
운영자는 천재지변 또는 이에 준하는 불가항력으로 인하여 서비스를 제공할 수 없는 경우 책임이 면제됩니다.
''';

  static const String privacyPolicyBody = '''
제1조 (개인정보의 수집 및 이용 목적)
"우진이의 하루"(이하 "본 앱")는 회원 식별, 학사 정보 연동 조회, 시간표·캘린더 알림 제공 등 서비스 운영을 위해 필요한 최소한의 개인정보를 수집·이용합니다.

제2조 (수집하는 개인정보 항목)
1. 필수 항목: 학번, 이름, 연동 계정 식별 정보
2. 서비스 이용 과정에서 자동 생성되는 정보: 기기 정보, 접속 로그, 앱 사용 기록

제3조 (개인정보의 보유 및 이용 기간)
운영자는 이용자가 서비스 탈퇴를 요청하거나 수집·이용 목적이 달성된 경우 지체 없이 해당 개인정보를 파기합니다. 단, 관계 법령에 따라 보존할 필요가 있는 경우 해당 기간 동안 보관합니다.

제4조 (개인정보의 제3자 제공)
운영자는 이용자의 개인정보를 본 약관에서 고지한 범위를 초과하여 이용하거나 제3자에게 제공하지 않습니다. 다만 법령에 근거가 있거나 수사 목적으로 법령에 정해진 절차와 방법에 따라 수사기관의 요구가 있는 경우는 예외로 합니다.

제5조 (이용자의 권리와 행사 방법)
이용자는 언제든지 자신의 개인정보를 조회하거나 수정할 수 있으며, 수집 및 이용에 대한 동의를 철회할 수 있습니다.

제6조 (개인정보의 안전성 확보 조치)
운영자는 개인정보의 분실, 도난, 유출, 변조 또는 훼손을 방지하기 위해 기술적·관리적 보호조치를 취하고 있습니다.
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (agreedAt != null) ...[
                      Text(
                        '동의 일시: $agreedAt',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    ..._buildBodyWidgets(body),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "제N조 (...)" 소제목과 본문을 분리해 소제목만 굵고 크게 렌더링한다.
  /// 각 조항은 빈 줄로 구분되어 있고, 조항 블록의 첫 줄이 소제목이다.
  List<Widget> _buildBodyWidgets(String body) {
    final blocks = body.trim().split('\n\n');
    final widgets = <Widget>[];
    for (var i = 0; i < blocks.length; i++) {
      final lines = blocks[i].split('\n');
      final heading = lines.first;
      final rest = lines.skip(1).join('\n');
      widgets.add(
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 24, bottom: 8),
          child: Text(
            heading,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.6,
            ),
          ),
        ),
      );
      if (rest.isNotEmpty) {
        widgets.add(
          Text(
            rest,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.6,
              fontWeight: FontWeight.w300,
            ),
          ),
        );
      }
    }
    return widgets;
  }
}
