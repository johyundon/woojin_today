import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// 같은 와이파이 기기끼리 파일을 직접 주고받는 전송 계층(서버 없음).
///
/// 받는 쪽은 기기 안에 작은 HTTP 창구([FileTransferServer])를 열고, 그
/// 번호(포트)를 nsd로 광고한다. 보내는 쪽([sendFile])은 탐색으로 알아낸
/// 주소·포트로 두 번 요청한다:
///
/// 1. `POST /v1/offers` — 파일 이름·크기·보낸 사람만 먼저 보낸다. 받는 쪽이
///    [FileTransferServer.onOffer]로 받을지 정하고, 받으면 1회용 토큰을 준다.
/// 2. `PUT /v1/files/<토큰>` — 실제 파일 내용을 보낸다.
///
/// 내용을 보내기 전에 먼저 묻는 이유: 같은 와이파이의 누구나 이 창구에
/// 요청할 수 있으므로, 받는 사람이 수락하기 전에는 내용을 한 바이트도
/// 저장하지 않기 위해서다. 전송은 암호화하지 않는다(같은 와이파이의 다른
/// 사람이 엿볼 수 있음 — 알려진 한계).

/// 받을지 묻는 요청 한 건(내용은 아직 안 받은 상태).
class FileOffer {
  const FileOffer({
    required this.fileName,
    required this.sizeBytes,
    required this.senderName,
    required this.remoteAddress,
  });

  /// 안전하게 정리된 파일 이름(경로 문자 없음).
  final String fileName;
  final int sizeBytes;
  final String senderName;
  final String remoteAddress;
}

/// 다 받은 파일 한 건.
class ReceivedTransfer {
  const ReceivedTransfer({required this.file, required this.offer});

  final File file;
  final FileOffer offer;
}

/// 받는 창구. [start] 후 [port]를 nsd 광고에 쓴다.
class FileTransferServer {
  FileTransferServer({
    required this.saveDirectory,
    required this.onOffer,
    this.onReceived,
    this.maxBytes = defaultMaxBytes,
    this.tokenLifetime = const Duration(minutes: 2),
  });

  static const int defaultMaxBytes = 200 * 1024 * 1024;

  final Directory saveDirectory;

  /// 받을지 정한다. false면 보낸 쪽에 거절로 알린다.
  final Future<bool> Function(FileOffer offer) onOffer;
  final void Function(ReceivedTransfer transfer)? onReceived;
  final int maxBytes;

  /// 수락 후 내용이 이 시간 안에 시작되지 않으면 토큰을 버린다.
  final Duration tokenLifetime;

  HttpServer? _server;
  final Map<String, _PendingUpload> _pending = {};
  final Random _random = Random.secure();

  /// 열린 창구 번호. [start] 전에는 null.
  int? get port => _server?.port;

  /// 운영체제가 비어 있는 번호를 골라 창구를 연다(번호 0 = 아무거나).
  Future<void> start() async {
    if (_server != null) return;
    final server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    _server = server;
    server.listen((request) {
      unawaited(_handle(request));
    });
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    _pending.clear();
    await server?.close(force: true);
  }

  Future<void> _handle(HttpRequest request) async {
    try {
      final segments = request.uri.pathSegments;
      if (request.method == 'POST' &&
          segments.length == 2 &&
          segments[0] == 'v1' &&
          segments[1] == 'offers') {
        await _handleOffer(request);
      } else if (request.method == 'PUT' &&
          segments.length == 3 &&
          segments[0] == 'v1' &&
          segments[1] == 'files') {
        await _handleUpload(request, segments[2]);
      } else {
        await _reply(request, HttpStatus.notFound, 'not_found');
      }
    } catch (_) {
      try {
        await _reply(request, HttpStatus.internalServerError, 'error');
      } catch (_) {
        // 이미 응답이 나갔거나 연결이 끊긴 경우 — 더 할 수 있는 게 없다.
      }
    }
  }

  Future<void> _handleOffer(HttpRequest request) async {
    // 메타데이터는 작아야 정상이다. 큰 본문으로 메모리를 채우는 걸 막는다.
    final body = await _readSmallBody(request, 16 * 1024);
    if (body == null) {
      return _reply(request, HttpStatus.badRequest, 'bad_request');
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      return _reply(request, HttpStatus.badRequest, 'bad_request');
    }
    if (decoded is! Map) {
      return _reply(request, HttpStatus.badRequest, 'bad_request');
    }
    final name = sanitizeFileName(decoded['name']);
    final size = decoded['size'];
    final sender = decoded['sender'];
    if (name == null || size is! int || size < 0) {
      return _reply(request, HttpStatus.badRequest, 'bad_request');
    }
    if (size > maxBytes) {
      return _reply(request, HttpStatus.requestEntityTooLarge, 'too_large');
    }
    final offer = FileOffer(
      fileName: name,
      sizeBytes: size,
      senderName: sender is String && sender.trim().isNotEmpty
          ? sender.trim()
          : '알 수 없음',
      remoteAddress: request.connectionInfo?.remoteAddress.address ?? '',
    );

    final accepted = await onOffer(offer);
    if (!accepted) {
      return _reply(request, HttpStatus.forbidden, 'declined');
    }
    final token = _newToken();
    _pending[token] = _PendingUpload(
      offer,
      Timer(tokenLifetime, () => _pending.remove(token)),
    );
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'token': token}));
    await request.response.close();
  }

  Future<void> _handleUpload(HttpRequest request, String token) async {
    final pending = _pending.remove(token);
    if (pending == null) {
      return _reply(request, HttpStatus.notFound, 'unknown_token');
    }
    pending.expiry.cancel();
    final offer = pending.offer;
    if (request.contentLength != offer.sizeBytes) {
      return _reply(request, HttpStatus.badRequest, 'size_mismatch');
    }

    await saveDirectory.create(recursive: true);
    final partial = File(
      '${saveDirectory.path}${Platform.pathSeparator}.$token.part',
    );
    final sink = partial.openWrite();
    var received = 0;
    var ok = true;
    try {
      await for (final chunk in request) {
        received += chunk.length;
        if (received > offer.sizeBytes) {
          ok = false;
          break;
        }
        sink.add(chunk);
      }
    } catch (_) {
      ok = false;
    } finally {
      await sink.close();
    }
    if (!ok || received != offer.sizeBytes) {
      await _deleteQuietly(partial);
      return _reply(request, HttpStatus.badRequest, 'incomplete');
    }

    final target = await _uniqueTarget(offer.fileName);
    final saved = await partial.rename(target.path);
    await _reply(request, HttpStatus.ok, 'ok');
    onReceived?.call(ReceivedTransfer(file: saved, offer: offer));
  }

  /// 같은 이름이 있으면 "이름 (1).pdf"처럼 번호를 붙여 덮어쓰지 않는다.
  Future<File> _uniqueTarget(String name) async {
    final dot = name.lastIndexOf('.');
    final base = dot > 0 ? name.substring(0, dot) : name;
    final ext = dot > 0 ? name.substring(dot) : '';
    var candidate = File('${saveDirectory.path}${Platform.pathSeparator}$name');
    for (var i = 1; await candidate.exists(); i++) {
      candidate = File(
        '${saveDirectory.path}${Platform.pathSeparator}$base ($i)$ext',
      );
    }
    return candidate;
  }

  String _newToken() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static Future<String?> _readSmallBody(HttpRequest request, int limit) async {
    final buffer = BytesBuilder(copy: false);
    await for (final chunk in request) {
      buffer.add(chunk);
      if (buffer.length > limit) return null;
    }
    try {
      return utf8.decode(buffer.takeBytes());
    } on FormatException {
      return null;
    }
  }

  static Future<void> _reply(HttpRequest request, int status, String code) {
    request.response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'result': code}));
    return request.response.close();
  }

  static Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // 임시 조각 파일 정리 실패는 무시(앱 임시 폴더라 OS가 언젠가 지운다).
    }
  }
}

class _PendingUpload {
  _PendingUpload(this.offer, this.expiry);

  final FileOffer offer;
  final Timer expiry;
}

/// 보낸 쪽이 준 파일 이름에서 경로를 떼고 위험한 글자를 없앤다.
/// 쓸 수 있는 이름이 안 남으면 null.
String? sanitizeFileName(Object? raw) {
  if (raw is! String) return null;
  // "../../x"나 "C:\\x" 같은 경로가 와도 마지막 이름만 쓴다.
  var name = raw.split(RegExp(r'[/\\]')).last;
  name = name.replaceAll(RegExp(r'[\x00-\x1f:*?"<>|]'), '').trim();
  // 맨 앞 점은 숨김 파일이 되거나 "."/".."이 되므로 뗀다.
  name = name.replaceFirst(RegExp(r'^\.+'), '').trim();
  if (name.isEmpty) return null;
  if (name.length > 200) name = name.substring(name.length - 200);
  return name;
}

/// 전송 실패 이유.
enum FileTransferFailure {
  /// 받는 사람이 거절함.
  declined,

  /// 받는 쪽 제한보다 큰 파일.
  tooLarge,

  /// 연결이 안 되거나 끊김(다른 와이파이, 학교 와이파이가 기기 간 통신을
  /// 막는 경우 등).
  network,

  /// 그 밖에 받는 쪽이 이해 못 한 응답.
  rejected,
}

class FileTransferException implements Exception {
  const FileTransferException(this.failure, [this.detail]);

  final FileTransferFailure failure;
  final Object? detail;

  @override
  String toString() => 'FileTransferException($failure, $detail)';
}

/// [file]을 [host]:[port]의 받는 창구로 보낸다. 성공하면 정상 종료,
/// 실패하면 [FileTransferException]을 던진다.
///
/// [acceptTimeout]은 상대가 받기/거절을 누를 때까지 기다리는 시간이다.
Future<void> sendFile({
  required String host,
  required int port,
  required File file,
  required String senderName,
  String? fileName,
  void Function(int sentBytes, int totalBytes)? onProgress,
  Duration connectTimeout = const Duration(seconds: 5),
  Duration acceptTimeout = const Duration(seconds: 60),
}) async {
  final client = HttpClient()..connectionTimeout = connectTimeout;
  try {
    final size = await file.length();
    final name = fileName ?? file.uri.pathSegments.last;

    final offerRequest = await client.post(host, port, '/v1/offers');
    offerRequest.headers.contentType = ContentType.json;
    offerRequest.write(
      jsonEncode({'name': name, 'size': size, 'sender': senderName}),
    );
    final offerResponse = await offerRequest.close().timeout(acceptTimeout);
    final offerBody = await utf8.decodeStream(offerResponse);
    switch (offerResponse.statusCode) {
      case HttpStatus.ok:
        break;
      case HttpStatus.forbidden:
        throw const FileTransferException(FileTransferFailure.declined);
      case HttpStatus.requestEntityTooLarge:
        throw const FileTransferException(FileTransferFailure.tooLarge);
      default:
        throw FileTransferException(FileTransferFailure.rejected, offerBody);
    }
    final token = (jsonDecode(offerBody) as Map)['token'] as String;

    final upload = await client.put(host, port, '/v1/files/$token');
    upload.contentLength = size;
    var sent = 0;
    await upload.addStream(
      file.openRead().map((chunk) {
        sent += chunk.length;
        onProgress?.call(sent, size);
        return chunk;
      }),
    );
    final uploadResponse = await upload.close();
    final uploadBody = await utf8.decodeStream(uploadResponse);
    if (uploadResponse.statusCode != HttpStatus.ok) {
      throw FileTransferException(FileTransferFailure.rejected, uploadBody);
    }
  } on FileTransferException {
    rethrow;
  } on SocketException catch (e) {
    throw FileTransferException(FileTransferFailure.network, e);
  } on HttpException catch (e) {
    throw FileTransferException(FileTransferFailure.network, e);
  } on TimeoutException catch (e) {
    throw FileTransferException(FileTransferFailure.network, e);
  } finally {
    client.close(force: true);
  }
}
