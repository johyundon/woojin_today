// 파일공유 직접 전송에 쓰는 화면 조각: "받기/거절" 확인 창과 사람별
// "보내기" 버튼의 진행 표시.

import 'package:daejin_app/screens/fileshare/widgets/incoming_offer_dialog.dart';
import 'package:daejin_app/screens/fileshare/widgets/peer_row.dart';
import 'package:daejin_app/services/file_transfer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsd/nsd.dart' as nsd;

const _offer = FileOffer(
  fileName: '자료구조_3주차.pdf',
  sizeBytes: 2516582,
  senderName: '우진이의 하루 - 1234',
  remoteAddress: '192.168.0.10',
);

Future<void> _openDialog(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => showIncomingOfferDialog(context, _offer),
          child: const Text('열기'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
}

void main() {
  group('받기/거절 확인 창', () {
    testWidgets('보낸 사람, 파일 이름, 크기를 보여준다', (tester) async {
      await _openDialog(tester);
      expect(find.text('파일을 받을까요?'), findsOneWidget);
      expect(find.text('우진이의 하루 - 1234에서 보내려고 해요.'), findsOneWidget);
      expect(find.text('자료구조_3주차.pdf'), findsOneWidget);
      expect(find.text('2.4MB'), findsOneWidget);
      expect(tester.takeException(), isNull);
      // 닫아서 시간 초과 타이머를 정리한다.
      await tester.tap(find.text('거절'));
      await tester.pumpAndSettle();
    });

    testWidgets('받기를 누르면 true', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  result = await showIncomingOfferDialog(context, _offer),
              child: const Text('열기'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('받기'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
      expect(find.text('파일을 받을까요?'), findsNothing);
    });

    testWidgets('거절을 누르면 false', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  result = await showIncomingOfferDialog(context, _offer),
              child: const Text('열기'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('거절'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });

    testWidgets('시간 안에 답하지 않으면 창이 닫히고 false', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await showIncomingOfferDialog(
                context,
                _offer,
                timeout: const Duration(seconds: 5),
              ),
              child: const Text('열기'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      expect(result, isFalse);
      expect(find.text('파일을 받을까요?'), findsNothing);
    });
  });

  group('사람별 보내기 버튼', () {
    final peer = nsd.Service(name: '김지아', type: '_daejinshare._tcp', port: 1);

    Future<int> pumpRow(WidgetTester tester, double? progress) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PeerRow(
              peer: peer,
              color: Colors.amber,
              onSend: () => taps++,
              progress: progress,
            ),
          ),
        ),
      );
      final label = progress == null
          ? '보내기'
          : progress <= 0
          ? '수락 대기'
          : '${(progress * 100).round()}%';
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      return taps;
    }

    testWidgets('평소엔 "보내기"이고 누를 수 있다', (tester) async {
      expect(await pumpRow(tester, null), 1);
    });

    testWidgets('수락 대기 중엔 "수락 대기"이고 눌리지 않는다', (tester) async {
      expect(await pumpRow(tester, 0), 0);
    });

    testWidgets('보내는 중엔 퍼센트가 보이고 눌리지 않는다', (tester) async {
      expect(await pumpRow(tester, 0.42), 0);
    });
  });
}
