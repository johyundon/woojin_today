import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/mascot_sticker.dart';
import '../../widgets/pressable.dart';
import '../home/widgets/home_top_icon_button.dart';

/// "셔틀버스" 화면. 셔틀 운행 정보를 가져올 API가 아직 없어서 "서비스 준비
/// 중" 안내만 보여준다. 홈 화면과 같은 틀(코발트 배경 + 라임 배지 + 큰 흰
/// 제목 + 마스코트 스티커 + 흰 카드)이다.
class ShuttleScreen extends StatelessWidget {
  const ShuttleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cobalt,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: HomeTopIconButton(
                  icon: Icons.arrow_back_ios_new,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lime,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '셔틀버스',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Padding(
                          padding: EdgeInsets.only(right: 70),
                          child: Text(
                            '서비스\n준비 중입니다',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              height: 1.22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Positioned(
                    right: -20,
                    top: 10,
                    child: MascotSticker(width: 100, angle: 0.1),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF030A7F).withValues(alpha: 0.22),
                      offset: const Offset(0, 10),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.lime,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.directions_bus_rounded,
                        size: 32,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '셔틀버스 정보를 준비하고 있어요',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '운행 시간표와 도착 정보는\n곧 만나볼 수 있어요. 조금만 기다려 주세요!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0x99121212),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: Pressable(
                        onTap: () => Navigator.of(context).pop(),
                        pressedScale: 0.97,
                        child: Material(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(16),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              '돌아가기',
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
            ),
          ],
        ),
      ),
    );
  }
}
