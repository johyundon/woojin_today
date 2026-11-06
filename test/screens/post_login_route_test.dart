// 로그인 후 약관 → 온보딩 → 로그인 완료 순서가 학번별 기록에 따라 정해지고,
// 한 번 본 사람은 다시 보지 않는지 확인한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:daejin_app/screens/onboarding_screen.dart';
import 'package:daejin_app/screens/post_login_route.dart';
import 'package:daejin_app/screens/student_id_login_complete_screen.dart';
import 'package:daejin_app/screens/terms_agreement_screen.dart';
import 'package:daejin_app/services/terms_acceptance_storage.dart';

const _id = '20211476';

void main() {
  late TermsAcceptanceStorage storage;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    storage = TermsAcceptanceStorage(prefs: SharedPreferencesAsync());
  });

  group('postLoginScreen', () {
    test('처음 로그인하면 약관 화면', () async {
      final next = await postLoginScreen(userId: _id, storage: storage);
      expect(next, isA<TermsAgreementScreen>());
    });

    test('약관만 동의했으면 온보딩 화면', () async {
      await storage.markAccepted(_id);
      final next = await postLoginScreen(userId: _id, storage: storage);
      expect(next, isA<OnboardingScreen>());
    });

    test('둘 다 했으면 바로 로그인 완료 화면', () async {
      await storage.markAccepted(_id);
      await storage.markOnboardingCompleted(_id);
      final next = await postLoginScreen(userId: _id, storage: storage);
      expect(next, isA<StudentIdLoginCompleteScreen>());
    });

    test('온보딩은 끝냈지만 약관 버전이 바뀌었으면 약관 화면', () async {
      await storage.markOnboardingCompleted(_id);
      final next = await postLoginScreen(userId: _id, storage: storage);
      expect(next, isA<TermsAgreementScreen>());
    });
  });

  testWidgets('약관에 동의하면 저장하고 온보딩, 온보딩을 끝내면 저장하고 로그인 완료로 간다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TermsAgreementScreen(userId: _id)),
    );

    await tester.tap(find.text('전체 동의합니다'));
    await tester.pump();
    await tester.tap(find.text('동의하고 시작하기'));
    await tester.pumpAndSettle();

    expect(await storage.hasAccepted(_id), isTrue);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(await storage.hasCompletedOnboarding(_id), isFalse);

    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('시작하기'));
    await tester.pump();
    await tester.pump();

    expect(await storage.hasCompletedOnboarding(_id), isTrue);
    expect(find.byType(StudentIdLoginCompleteScreen), findsOneWidget);

    // 로그인 완료 화면의 홈 이동 타이머가 테스트 뒤에 남지 않게 화면을 내린다.
    await tester.pumpWidget(const SizedBox());
  });
}
