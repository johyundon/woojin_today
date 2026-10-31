import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/mascot_sticker.dart';
import '../widgets/pressable.dart';

/// 학번 찾기 결과 화면 (Figma node 6:12).
/// 조회된 학번을 보여주고, 그 학번으로 바로 로그인하도록 안내한다.
class StudentIdResultScreen extends StatelessWidget {
  const StudentIdResultScreen({
    super.key,
    required this.studentId,
    required this.name,
  });

  final String studentId;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cobalt,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Pressable.effect(
                        pressedScale: 0.85,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.15,
                            ),
                            shape: const CircleBorder(),
                          ),
                          icon: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // 원은 글자보다 뒤로 간다(원 → 글자 순서).
                            Positioned(
                              left: 150,
                              top: 30,
                              child: Container(
                                width: 210,
                                height: 210,
                                decoration: const BoxDecoration(
                                  color: AppColors.cobaltDeep,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Column(
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
                                    '완료',
                                    style: TextStyle(
                                      color: AppColors.ink,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  '학번을\n찾았어요!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    height: 1.25,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 70),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(
                      20,
                      28,
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F3EF),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: AppColors.lime,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: AppColors.ink,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                '$name님의 학번은',
                                style: const TextStyle(
                                  color: Color(0xFF5A5852),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                studentId,
                                style: const TextStyle(
                                  color: AppColors.cobalt,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Pressable.effect(
                          pressedScale: 0.96,
                          child: Container(
                            height: 62,
                            decoration: BoxDecoration(
                              shape: BoxShape.rectangle,
                              borderRadius: BorderRadius.circular(31),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.cobalt.withValues(
                                    alpha: 0.4,
                                  ),
                                  offset: const Offset(0, 12),
                                  blurRadius: 26,
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(studentId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.cobalt,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: const StadiumBorder(),
                              ),
                              child: const Text(
                                '로그인하러 가기 →',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
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
          Positioned(
            left: 205,
            top: 150,
            child: const MascotSticker(width: 155, angle: -0.08),
          ),
        ],
      ),
    );
  }
}
