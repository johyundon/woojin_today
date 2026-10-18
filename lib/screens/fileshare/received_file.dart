import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// 받은 파일 한 건 + 화면에 보여줄 부가 정보(실제로 읽은 값만 담는다).
/// [sizeBytes]는 파일이 목록에 바로 뜬 뒤 따로 비동기로 채워지므로
/// final이 아니다(용량 조회가 느리거나 실패해도 목록 표시 자체는 막지
/// 않기 위함).
class ReceivedFile {
  ReceivedFile({required this.file, required this.receivedAt});

  final SharedMediaFile file;
  final DateTime receivedAt;

  /// 실제 파일 크기(바이트). 받은 직후엔 null이고 [_fillSize]가 채운다.
  /// 못 읽으면 null로 남아 용량이 숨겨진다.
  int? sizeBytes;
}
