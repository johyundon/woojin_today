// Firebase 연결 정보(Firebase 콘솔 woojintoday-a7430 프로젝트에서 받은 값).
//
// 원래 `flutterfire configure`가 만들어 주는 파일인데, 같은 내용을 콘솔에서
// 받은 설정 파일(google-services.json, GoogleService-Info.plist)에서 옮겨 적었다.
// 이 값들은 앱이 어느 Firebase 프로젝트로 통계를 보낼지 가리키는 주소일 뿐
// 비밀번호가 아니다(앱 안에 그대로 들어가는 값).

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  /// 지금 기기에 맞는 연결 정보. 아직 등록하지 않은 플랫폼이면 null.
  static FirebaseOptions? get currentPlatform {
    if (kIsWeb) return null;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => null,
    };
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAn7ZzxVnqjk759qasJ8e-B0x7qC5wrdNM',
    appId: '1:837676341149:android:6ca879db6f6df479c8c174',
    messagingSenderId: '837676341149',
    projectId: 'woojintoday-a7430',
    storageBucket: 'woojintoday-a7430.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBDEsAdmY91wwgBm-S8rXS0sbqXBb6ZLzw',
    appId: '1:837676341149:ios:92e5b492ea44c0cfc8c174',
    messagingSenderId: '837676341149',
    projectId: 'woojintoday-a7430',
    storageBucket: 'woojintoday-a7430.firebasestorage.app',
    iosBundleId: 'com.johyundon.woojintoday',
  );
}
