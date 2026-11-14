import 'dart:async';

import 'package:flutter/material.dart';

import '../services/session_cache.dart';
import '../services/terms_acceptance_storage.dart';
import 'calendar/services/calendar_reminder_restore.dart';
import 'onboarding_screen.dart';
import 'student_id_login_complete_screen.dart';
import 'terms_agreement_screen.dart';

/// 로그인에 성공한 뒤 보여줄 화면을 고른다. 로그인 화면, 자동 로그인
/// (스플래시), 약관 동의 직후가 모두 이 규칙을 따른다.
///
/// 이 학번이 지금 버전 약관에 동의하지 않았으면 약관 화면, 온보딩을 끝내지
/// 않았으면 온보딩 화면, 둘 다 했으면 바로 로그인 완료 화면이다.
Future<Widget> postLoginScreen({
  required String userId,
  String? jsessionId,
  String? wmonid,
  String? userId2,
  TermsAcceptanceStorage? storage,
}) async {
  // 학번별로 저장하는 캘린더 일정이 이 학생의 칸을 읽도록 기억하고, 로그아웃 때
  // 지워졌던 일정 알림을 다시 건다(기다리지 않음).
  SessionCache.userId = userId;
  unawaited(restoreCalendarReminders());
  final s = storage ?? TermsAcceptanceStorage();
  if (!await s.hasAccepted(userId)) {
    return TermsAgreementScreen(
      userId: userId,
      jsessionId: jsessionId,
      wmonid: wmonid,
      userId2: userId2,
    );
  }
  if (!await s.hasCompletedOnboarding(userId)) {
    return OnboardingScreen(
      userId: userId,
      jsessionId: jsessionId,
      wmonid: wmonid,
      userId2: userId2,
    );
  }
  return StudentIdLoginCompleteScreen(
    jsessionId: jsessionId,
    wmonid: wmonid,
    userId2: userId2,
  );
}
