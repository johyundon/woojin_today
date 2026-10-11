// FileShareScreen이 꺼짐/켜짐 상태를 오버플로우 없이 보여주고, "저장위치
// 열기"는 실제 파일 탐색기 대신 스낵바로 안내하는지 확인한다.
//
// 켜짐 상태는 계속 도는 회전 애니메이션(RotationTransition)이 있어
// pumpAndSettle()을 쓰면 타임아웃난다 — pump(duration)으로 몇 프레임만
// 진행시킨다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'package:daejin_app/screens/fileshare/fileshare_screen.dart';

void main() {
  testWidgets('기본은 "사용 안 함" 상태로 열린다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: FileShareScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('사용 안 함'), findsOneWidget);
    expect(find.text('파일공유 기능을 활성화하면 발견된 사람이 여기 떠요.'), findsOneWidget);
    expect(find.text('아직 받은 파일이 없어요.'), findsOneWidget);
  });

  testWidgets('토글을 켜면 "사용중"과 고정 안내 문구로 바뀐다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: FileShareScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('사용중'), findsOneWidget);
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

  testWidgets('"저장위치 열기"는 스낵바로 안내한다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: FileShareScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('저장위치 열기'));
    await tester.pump();

    expect(find.text('저장위치 열기는 지원하지 않아요'), findsOneWidget);
    expect(tester.takeException(), isNull);
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

    expect(find.text('아직 받은 파일이 없어요.'), findsNothing);
    expect(find.text('report.pdf'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
