import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

import 'config/kakao_map_config.dart';
import 'screens/splash_screen.dart';
import 'services/notice_background.dart';
import 'services/notice_watcher.dart';
import 'services/notification_service.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AuthRepository.initialize(
    appKey: kakaoMapJavaScriptKey,
    baseUrl: 'http://localhost',
  );
  await NotificationService.instance.initialize();
  await NoticeBackground.initialize();
  NoticeWatcher().restoreBackground();
  runApp(const MyApp());
}

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
      ),
      home: const SplashScreen(),
    );
  }
}
