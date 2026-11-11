import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/notice_service.dart';

/// 공지 검색용 본문 저장소. 공지 본문을 [NoticeServiceBase.fetchDetail]로 받아
/// 글자만 하루 동안 기기에 저장해 두고, 같은 공지는 다시 요청하지 않는다.
///
/// 검색은 앱이 받아 둔 공지 안에서만 한다(사용자 결정, 2026-11-11). 처음 검색할
/// 때 목록의 공지 수만큼 학교에 요청이 나가므로, 한 번에 [_parallel]개씩만 받는다.
/// 로그아웃하면 `logout_cleaner`가 기기 저장소를 통째로 지운다.
class NoticeBodyCache {
  NoticeBodyCache(this._service, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const cacheDuration = Duration(days: 1);
  static const _prefsKeyPrefix = 'notice_body_';
  static const _parallel = 3;

  final NoticeServiceBase _service;
  final DateTime Function() _now;

  /// 공지 상세 경로 → 본문. 받지 못한 공지는 들어 있지 않다.
  final Map<String, String> bodies = {};

  /// [paths] 중 아직 본문이 없는 공지를 받아 [bodies]에 채운다. 하나 받을
  /// 때마다 [onProgress]를 부른다. 실패한 공지는 건너뛴다(제목으로는 여전히
  /// 찾을 수 있다).
  Future<void> load(List<String> paths, {VoidCallback? onProgress}) async {
    final prefs = await SharedPreferences.getInstance();
    final missing = <String>[];
    for (final path in paths) {
      if (bodies.containsKey(path)) continue;
      final stored = _read(prefs, path);
      if (stored != null) {
        bodies[path] = stored;
      } else {
        missing.add(path);
      }
    }
    onProgress?.call();

    for (var i = 0; i < missing.length; i += _parallel) {
      final batch = missing.skip(i).take(_parallel);
      await Future.wait(
        batch.map((path) async {
          try {
            final detail = await _service.fetchDetail(path);
            bodies[path] = detail.body;
            await prefs.setString(
              '$_prefsKeyPrefix$path',
              jsonEncode({
                'savedAt': _now().toIso8601String(),
                'body': detail.body,
              }),
            );
          } catch (e) {
            debugPrint('[NoticeSearch] 본문을 받지 못함($path): $e');
          }
          onProgress?.call();
        }),
      );
    }
  }

  String? _read(SharedPreferences prefs, String path) {
    try {
      final raw = prefs.getString('$_prefsKeyPrefix$path');
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = DateTime.parse(json['savedAt'] as String);
      if (_now().difference(savedAt) >= cacheDuration) return null;
      return json['body'] as String;
    } catch (_) {
      return null;
    }
  }
}

/// [query]가 [text]에 들어 있으면 그 주변 글자를 한 줄로 잘라 돌려준다(카드에
/// "본문에서 찾은 문장"으로 보여준다). 없으면 null. 대소문자는 구분하지 않는다.
String? noticeSnippet(String text, String query, {int around = 24}) {
  final index = text.toLowerCase().indexOf(query.toLowerCase());
  if (index < 0) return null;
  final start = (index - around).clamp(0, text.length);
  final end = (index + query.length + around).clamp(0, text.length);
  final body = text
      .substring(start, end)
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return '${start > 0 ? '…' : ''}$body${end < text.length ? '…' : ''}';
}
