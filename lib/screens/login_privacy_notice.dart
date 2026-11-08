import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/pressable.dart';

/// 로그인 버튼 아래의 개인정보 안심 안내 한 줄. "자세히"를 누르면 [onDetails].
class PrivacyNotice extends StatelessWidget {
  const PrivacyNotice({super.key, required this.onDetails});

  final VoidCallback onDetails;

  static const _style = TextStyle(
    color: AppColors.textSub,
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w600,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.lock_rounded, size: 14, color: AppColors.blue),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text.rich(
              TextSpan(
                text:
                    '학번·비밀번호와 학교 정보는 이 휴대폰에만 저장돼요. '
                    '별도 서버 없이 학교와 직접 연결해요. ',
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: Pressable(
                      onTap: onDetails,
                      child: const Text(
                        '자세히',
                        style: TextStyle(
                          color: AppColors.blueText,
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w800,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.blueText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              style: _style,
            ),
          ),
        ],
      ),
    );
  }
}

/// 개인정보를 어디에 두고 어디로 보내는지 알려주는 바텀시트.
///
/// 내용은 실제 코드와 맞춰 쓴다. 바꿀 때 함께 볼 곳:
/// 자격증명 저장 `credential_storage.dart`, 로그아웃 삭제 `logout_cleaner.dart`,
/// 학번 찾기(저장 안 함) `student_id_find_screen.dart`.
Future<void> showPrivacyDetailsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const PrivacyDetailsSheet(),
  );
}

class PrivacyDetailsSheet extends StatelessWidget {
  const PrivacyDetailsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.fillDisabled,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '내 정보는 이 휴대폰에만 있어요',
                      style: TextStyle(
                        color: AppColors.textStrong,
                        fontSize: 18,
                        height: 1.4,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '이 앱에는 운영자의 서버가 없어요. 휴대폰이 학교 사이트와 직접 연결해요.',
                      style: TextStyle(
                        color: AppColors.textSub,
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 18),
                    _Section(
                      icon: Icons.inventory_2_rounded,
                      title: '저장하는 정보',
                      lines: [
                        '학번·비밀번호 (자동 로그인을 켰을 때만)',
                        '이름·학과·학년, 성적·등수 등 학교에서 불러온 정보',
                        '시간표·캘린더 일정·공지 읽음 표시 등 내가 만든 정보',
                        '학번 찾기에 입력한 이름·생년월일·휴대폰 번호는 학교에 조회할 때만 쓰고 저장하지 않아요',
                      ],
                    ),
                    _Section(
                      icon: Icons.smartphone_rounded,
                      title: '저장 위치',
                      lines: [
                        '모두 이 휴대폰 안에만 저장돼요',
                        '학번·비밀번호는 휴대폰의 암호화 보관함(아이폰 키체인, 안드로이드 키스토어)에 보관해요',
                      ],
                    ),
                    _Section(
                      icon: Icons.swap_horiz_rounded,
                      title: '보내는 곳',
                      lines: [
                        '로그인과 조회는 휴대폰에서 대진대학교 공식 사이트(dreams2·www·together.daejin.ac.kr)로만 직접 보내요',
                        '앱 운영자의 서버가 없어서 운영자는 내 정보를 볼 수 없어요',
                        '날씨·미세먼지는 학교 위치만으로 날씨 서비스(open-meteo)에 물어봐요. 내 정보는 보내지 않아요',
                      ],
                    ),
                    _Section(
                      icon: Icons.delete_outline_rounded,
                      title: '지우는 법',
                      lines: [
                        '로그아웃하면 학번·비밀번호, 학교에서 불러온 정보, 시간표·캘린더 일정, 예약 알림이 이 휴대폰에서 지워져요',
                        '다시 로그인할 때 약관·첫 안내를 또 보지 않도록 "봤다"는 기록만 학번별로 남아요',
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
              child: SizedBox(
                height: 52,
                child: Pressable.effect(
                  pressedScale: 0.96,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
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
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.lines,
  });

  final IconData icon;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.blueSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: AppColors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textStrong,
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '· $line',
                      style: const TextStyle(
                        color: AppColors.textBody,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
