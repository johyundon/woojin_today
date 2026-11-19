import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// 기능 사용 통계(Firebase Analytics).
///
/// 어떤 기능을 얼마나 쓰는지만 Google Firebase로 보낸다. 학번·이름·성적 같은
/// 개인정보는 넣지 않는다. 광고 식별자도 모으지 않는다(iOS Podfile의
/// `$FirebaseAnalyticsWithoutAdIdSupport`, Android 매니페스트 meta-data).
///
/// 개발 중(debug 빌드)에는 통계를 보내지 않아 실제 사용자 수치가 섞이지 않게 한다.
/// 초기화에 실패해도 앱 실행은 막지 않는다.
class AnalyticsService {
  AnalyticsService._();

  static final instance = AnalyticsService._();

  Future<void> initialize() async {
    final options = DefaultFirebaseOptions.currentPlatform;
    if (options == null) return;
    try {
      await Firebase.initializeApp(options: options);
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(
        !kDebugMode,
      );
    } catch (e) {
      debugPrint('[Analytics] 초기화 실패: $e');
    }
  }
}
