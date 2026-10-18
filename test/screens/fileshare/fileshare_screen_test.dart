// FileShareScreen이 꺼짐/켜짐/받은 파일 있음 세 상태를 오버플로우 없이
// 보여주는지 확인한다.
//
// "받은 파일"/"주변 사람" 데모는 둘 다 꺼져 있다(_FileShareScreenState의
// TEMP _kShowReceivedFilesDemo/_kShowNearbyPeersDemo 스위치) — 가짜 사람
// 없이 실제 mDNS 탐색 결과만 보여주기로 함.
//
// 토글을 켜면 실제 mDNS 플러그인(nsd)을 호출하는데 테스트 환경엔 플랫폼
// 채널 목이 없어 완료되지 않는 Future가 남는다 — pumpAndSettle() 대신
// pump(duration)으로 몇 프레임만 진행시킨다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'package:daejin_app/screens/fileshare/fileshare_screen.dart';

void main() {
  testWidgets('기본은 "사용 안 함" 상태로 열리고, 받은 파일이 없다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: FileShareScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('사용 안 함'), findsOneWidget);
    expect(find.text('아직 받은 파일이 없어요'), findsOneWidget);
  });

  testWidgets('토글을 켜면 "사용 중"으로 바뀌고, 실제로 찾은 사람이 없으면 빈 안내가 보인다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: FileShareScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('사용 중'), findsOneWidget);
    expect(find.text('주변 사람 0명이 발견됐어요.'), findsOneWidget);
    expect(
      find.text('아직 발견된 사람이 없어요.\n상대방도 파일공유 기능을 활성화해야 보여요!'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    // 꺼서 애니메이션을 멈추고 테스트를 깔끔히 끝낸다.
    await tester.tap(find.byType(Switch));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('사용 안 함'), findsOneWidget);
  });

  // ReceiveSharingIntent.setMockValues는 instance를 전역으로 바꿔치기해서
  // 되돌릴 방법이 없다 — 이 파일의 다른 테스트에 영향 없도록 마지막에 둔다.
  testWidgets('다른 앱에서 공유로 받은 파일이 있으면 목록에 보여준다', (tester) async {
    ReceiveSharingIntent.setMockValues(
      initialMedia: [
        SharedMediaFile(
          path: '/storage/emulated/0/Download/report.pdf',
          type: SharedMediaType.file,
        ),
      ],
      mediaStream: const Stream.empty(),
    );

    await tester.pumpWidget(const MaterialApp(home: FileShareScreen()));
    await tester.pumpAndSettle();

    expect(find.text('report.pdf'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
