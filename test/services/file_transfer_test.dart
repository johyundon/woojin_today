import 'dart:convert';
import 'dart:io';

import 'package:daejin_app/services/file_transfer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tmp;
  late Directory saveDir;
  late File source;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('file_transfer_test');
    saveDir = Directory('${tmp.path}/inbox');
    source = File('${tmp.path}/자료구조_3주차.pdf');
    // 여러 조각으로 나뉘어 오도록 충분히 큰 내용(약 300KB).
    await source.writeAsBytes(
      List<int>.generate(300 * 1024, (i) => i % 251),
    );
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  Future<FileTransferServer> startServer({
    required Future<bool> Function(FileOffer) onOffer,
    void Function(ReceivedTransfer)? onReceived,
    int maxBytes = FileTransferServer.defaultMaxBytes,
  }) async {
    final server = FileTransferServer(
      saveDirectory: saveDir,
      onOffer: onOffer,
      onReceived: onReceived,
      maxBytes: maxBytes,
    );
    await server.start();
    addTearDown(server.stop);
    return server;
  }

  test('수락하면 파일 내용이 바이트 그대로 저장된다', () async {
    FileOffer? seenOffer;
    ReceivedTransfer? received;
    final server = await startServer(
      onOffer: (offer) async {
        seenOffer = offer;
        return true;
      },
      onReceived: (t) => received = t,
    );
    expect(server.port, isNotNull);
    expect(server.port, isNot(0));

    var lastProgress = 0;
    await sendFile(
      host: '127.0.0.1',
      port: server.port!,
      file: source,
      senderName: '테스트 보낸이',
      onProgress: (sent, total) => lastProgress = sent,
    );

    expect(seenOffer!.fileName, '자료구조_3주차.pdf');
    expect(seenOffer!.sizeBytes, 300 * 1024);
    expect(seenOffer!.senderName, '테스트 보낸이');
    expect(lastProgress, 300 * 1024);
    expect(received, isNotNull);
    expect(received!.file.path, '${saveDir.path}/자료구조_3주차.pdf');
    expect(
      await received!.file.readAsBytes(),
      await source.readAsBytes(),
    );
    // 임시 조각 파일이 남지 않는다.
    final leftovers = saveDir
        .listSync()
        .where((e) => e.path.endsWith('.part'))
        .toList();
    expect(leftovers, isEmpty);
  });

  test('거절하면 declined로 실패하고 아무것도 저장하지 않는다', () async {
    final server = await startServer(onOffer: (_) async => false);

    await expectLater(
      sendFile(
        host: '127.0.0.1',
        port: server.port!,
        file: source,
        senderName: 'a',
      ),
      throwsA(
        isA<FileTransferException>().having(
          (e) => e.failure,
          'failure',
          FileTransferFailure.declined,
        ),
      ),
    );
    expect(saveDir.existsSync(), isFalse);
  });

  test('제한보다 큰 파일은 묻지도 않고 tooLarge로 실패한다', () async {
    var asked = false;
    final server = await startServer(
      onOffer: (_) async => asked = true,
      maxBytes: 1024,
    );

    await expectLater(
      sendFile(
        host: '127.0.0.1',
        port: server.port!,
        file: source,
        senderName: 'a',
      ),
      throwsA(
        isA<FileTransferException>().having(
          (e) => e.failure,
          'failure',
          FileTransferFailure.tooLarge,
        ),
      ),
    );
    expect(asked, isFalse);
  });

  test('같은 이름을 두 번 받으면 덮어쓰지 않고 번호를 붙인다', () async {
    final received = <ReceivedTransfer>[];
    final server = await startServer(
      onOffer: (_) async => true,
      onReceived: received.add,
    );
    for (var i = 0; i < 2; i++) {
      await sendFile(
        host: '127.0.0.1',
        port: server.port!,
        file: source,
        senderName: 'a',
      );
    }
    expect(received.map((t) => t.file.path), [
      '${saveDir.path}/자료구조_3주차.pdf',
      '${saveDir.path}/자료구조_3주차 (1).pdf',
    ]);
  });

  test('경로가 섞인 이름("../")은 받는 폴더 밖으로 나가지 못한다', () async {
    ReceivedTransfer? received;
    final server = await startServer(
      onOffer: (_) async => true,
      onReceived: (t) => received = t,
    );
    await sendFile(
      host: '127.0.0.1',
      port: server.port!,
      file: source,
      senderName: 'a',
      fileName: '../../evil.sh',
    );
    expect(received!.file.path, '${saveDir.path}/evil.sh');
    expect(File('${tmp.path}/evil.sh').existsSync(), isFalse);
  });

  test('수락 없이 내용부터 보내면(모르는 토큰) 저장하지 않는다', () async {
    final server = await startServer(onOffer: (_) async => true);
    final client = HttpClient();
    addTearDown(client.close);
    final request = await client.put(
      '127.0.0.1',
      server.port!,
      '/v1/files/deadbeef',
    );
    request.contentLength = 3;
    request.add([1, 2, 3]);
    final response = await request.close();
    await response.drain<void>();
    expect(response.statusCode, HttpStatus.notFound);
    expect(saveDir.existsSync(), isFalse);
  });

  test('수락 토큰은 한 번만 쓸 수 있다', () async {
    final server = await startServer(onOffer: (_) async => true);
    final client = HttpClient();
    addTearDown(client.close);

    final offer = await client.post('127.0.0.1', server.port!, '/v1/offers');
    offer.headers.contentType = ContentType.json;
    offer.write(jsonEncode({'name': 'a.txt', 'size': 3, 'sender': 'x'}));
    final offerRes = await offer.close();
    final token =
        (jsonDecode(await utf8.decodeStream(offerRes)) as Map)['token'];

    Future<int> upload() async {
      final req = await client.put(
        '127.0.0.1',
        server.port!,
        '/v1/files/$token',
      );
      req.contentLength = 3;
      req.add([1, 2, 3]);
      final res = await req.close();
      await res.drain<void>();
      return res.statusCode;
    }

    expect(await upload(), HttpStatus.ok);
    expect(await upload(), HttpStatus.notFound);
  });

  test('창구가 없는 곳으로 보내면 network로 실패한다', () async {
    // 잠깐 열었다 닫아 "지금은 아무도 안 듣는 번호"를 얻는다.
    final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final deadPort = probe.port;
    await probe.close();

    await expectLater(
      sendFile(
        host: '127.0.0.1',
        port: deadPort,
        file: source,
        senderName: 'a',
      ),
      throwsA(
        isA<FileTransferException>().having(
          (e) => e.failure,
          'failure',
          FileTransferFailure.network,
        ),
      ),
    );
  });

  group('sanitizeFileName', () {
    test('경로와 위험 문자를 없앤다', () {
      expect(sanitizeFileName('a/b/c.pdf'), 'c.pdf');
      expect(sanitizeFileName(r'C:\x\y.txt'), 'y.txt');
      expect(sanitizeFileName('..'), isNull);
      expect(sanitizeFileName('.hidden'), 'hidden');
      expect(sanitizeFileName('a<b>?.txt'), 'ab.txt');
      expect(sanitizeFileName('   '), isNull);
      expect(sanitizeFileName(3), isNull);
    });
  });
}
