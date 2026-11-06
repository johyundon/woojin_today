import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import 'student_id_header.dart';

/// 학번 찾기 결과 화면 (v7 디자인 08).
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
              const StudentIdHeader(badge: '완료', title: '학번을\n찾았어요!'),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    22,
                    28,
                    22,
                    bottomInset + 10 > 44 ? bottomInset + 10 : 44,
                  ),
                  decoration: studentIdCardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 34,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.fill,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: AppColors.blue,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x240A78E6),
                                    offset: Offset(0, 4),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              '$name님의 학번은',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textSub,
                                fontSize: 13,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                studentId,
                                style: const TextStyle(
                                  color: AppColors.blue,
                                  fontSize: 35,
                                  height: 1.4,
                                  letterSpacing: -0.7,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      StudentIdBlueButton(
                        label: '로그인하러 가기',
                        onPressed: () => Navigator.of(context).pop(studentId),
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
}
