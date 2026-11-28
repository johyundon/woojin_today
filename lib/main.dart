import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

import 'config/kakao_map_config.dart';
import 'screens/splash_screen.dart';
import 'services/analytics_service.dart';
import 'services/notice_background.dart';
import 'services/notice_watcher.dart';
import 'services/notification_service.dart';
import 'theme/app_colors.dart';
import 'theme/instant_page_transitions.dart';
import 'widgets/phone_width_frame.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AuthRepository.initialize(
    appKey: kakaoMapJavaScriptKey,
    baseUrl: 'http://localhost',
  );
  await AnalyticsService.instance.initialize();
  await NotificationService.instance.initialize();
  await NoticeBackground.initialize();
  NoticeWatcher().restoreBackground();
  runApp(const MyApp());
}

/// 넓은 화면에서 앱을 아이폰 폭으로 가운데에 세울지([PhoneWidthFrame]).
/// 꽉 채우기로 바꾸면서 꺼 두었다(지우지 않고 남겨 둠).
const bool _centerOnWideScreen = false;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '우진이의 하루',
      debugShowCheckedModeBanner: false,
      // v7: 밝은 바탕에 파랑 포인트. 화면마다 색을 직접 정해 두었고, 테마는
      // 따로 정하지 않은 글자·입력칸·팝업·글자 선택 손잡이의 기본값을 맞춘다.
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: 'Pretendard',
        scaffoldBackgroundColor: AppColors.canvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.blue,
          brightness: Brightness.light,
          primary: AppColors.blue,
          surface: Colors.white,
          onSurface: AppColors.textStrong,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: AppColors.blue,
          selectionHandleColor: AppColors.blue,
        ),
        dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
        ),
        // 화면 전환 애니메이션 없이 바로 넘긴다(iOS 뒤로 쓸기는 유지).
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.iOS: InstantPageTransitionsBuilder(),
            TargetPlatform.android: InstantPageTransitionsBuilder(),
          },
        ),
      ),
      // 아이폰 듀오를 펼친 넓은 화면에서 아이폰 폭으로 가운데에 보여 줄지.
      // 지금은 꽉 채워 쓰도록 꺼 두었다(사용자 요청, 2026-11-28).
      builder: (context, child) =>
          _centerOnWideScreen ? PhoneWidthFrame(child: child!) : child!,
      home: const SplashScreen(),
    );
  }
}
