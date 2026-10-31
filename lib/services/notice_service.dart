import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/notice/models/notice_item.dart';
import 'host_cookie_jar.dart';

/// 실제 데이터로 연결된 게시판(명세: 상세_2 "공지" 5·7번).
enum NoticeBoard {
  /// 학사공지(게시판 188). 로그인 불필요.
  academic('/daejin/1003/subview.do', NoticeTag.academic),

  /// 마일리지장학 공지(게시판 189를 검색어 "마일리지장학"으로 거른 목록).
  /// enc는 명세의 고정값이다. 명세의 조립 규칙으로 다시 만들면 인코딩 차이로 값이
  /// 달라질 수 있어 고정값을 그대로 쓴다.
  mileage(
    '/daejin/1002/subview.do?enc=Zm5jdDF8QEB8JTJGYmJzJTJGZGFlamluJTJGMTg5JTJGYXJ0Y2xMaXN0LmRvJTNGYmJzQ2xTZXElM0QlMjZiYnNPcGVuV3JkU2VxJTNEJTI2aXNWaWV3TWluZSUzRGZhbHNlJTI2c3JjaENvbHVtbiUzRHNqJTI2c3JjaFdyZCUzRCVFQiVBNyU4OCVFQyU5RCVCQyVFQiVBNiVBQyVFQyVBNyU4MCVFQyU5RSVBNSVFRCU5NSU5OSUyNg==',
    NoticeTag.scholarship,
  );

  const NoticeBoard(this.path, this.tag);

  final String path;
  final NoticeTag tag;
}

class NoticeException implements Exception {
  const NoticeException(this.message, {this.isNetwork = false});

  final String message;

  /// 타임아웃 등 통신 자체의 실패인지(명세: 네트워크 실패는 따로 구분).
  final bool isNetwork;

  @override
  String toString() => message;
}

/// 첨부파일 하나(`a.file-download`).
class NoticeAttachment {
  const NoticeAttachment({required this.name, required this.url});

  final String name;

  /// 전체 다운로드 주소(`https://www.daejin.ac.kr` + href).
  final String url;
}

/// 공지 상세 페이지에서 뽑은 내용.
class NoticeDetail {
  const NoticeDetail({
    required this.title,
    required this.author,
    required this.date,
    required this.viewCount,
    required this.body,
    required this.attachments,
  });

  final String title;
  final String author;
  final String date;
  final int viewCount;

  /// 본문 글자. 문단은 줄바꿈으로, 표는 한 행씩 "칸 | 칸"으로 바꾼 것이다.
  final String body;

  final List<NoticeAttachment> attachments;
}

/// [NoticeService]의 공개 API. 화면은 이 타입으로 받아 테스트에서 가짜를 끼운다.
abstract class NoticeServiceBase {
  /// [forceRefresh]가 true면 캐시를 무시하고 새로 받는다.
  Future<List<NoticeItem>> fetchNotices(
    NoticeBoard board, {
    bool forceRefresh = false,
  });

  /// [detailPath]는 목록의 [NoticeItem.detailPath].
  Future<NoticeDetail> fetchDetail(String detailPath);
}

/// 학교 홈페이지(www.daejin.ac.kr)의 공지 목록과 상세를 가져온다.
///
/// 목록 페이지는 로그인이 필요 없지만 내부 인증 확인으로 리다이렉트를 4번
/// 거친다. 홉마다 받은 쿠키를 다음 요청에 실어야 하고, 그러지 않으면 같은 곳을
/// 맴돈다(명세). 셀렉터는 2026-10-31 실제 응답으로 확인했다.
///
/// 목록은 게시판별로 1시간 동안 기기에 저장해 두고 다시 요청하지 않는다. 상세는
/// 앱이 켜져 있는 동안만 기억한다. 실패한 결과는 저장하지 않는다.
class NoticeService implements NoticeServiceBase {
  NoticeService({http.Client? client, DateTime Function()? now})
    : _client = client ?? http.Client(),
      _now = now ?? DateTime.now;

  static const _base = 'https://www.daejin.ac.kr';
  static const _userAgent =
      'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36';
  static const cacheDuration = Duration(hours: 1);
  static const _prefsKeyPrefix = 'notice_list_';
  static const _maxRedirects = 10;

  static final Map<String, NoticeDetail> _detailCache = {};

  final http.Client _client;
  final DateTime Function() _now;

  /// 테스트에서 상세 캐시를 비우려고 쓴다.
  @visibleForTesting
  static void clearMemoryCache() => _detailCache.clear();

  @override
  Future<List<NoticeItem>> fetchNotices(
    NoticeBoard board, {
    bool forceRefresh = false,
  }) async {
    final key = '$_prefsKeyPrefix${board.name}';
    if (!forceRefresh) {
      final cached = await _readStored(key, board);
      if (cached != null) return cached;
    }
    final body = await _get('$_base${board.path}');
    final items = parseList(body, board);
    await _writeStored(key, items);
    return items;
  }

  @override
  Future<NoticeDetail> fetchDetail(String detailPath) async {
    final cached = _detailCache[detailPath];
    if (cached != null) return cached;
    final detail = parseDetail(await _get('$_base$detailPath'));
    _detailCache[detailPath] = detail;
    return detail;
  }

  /// 명세의 목록 파싱 규칙. 마일리지 게시판은 제목에 "마일리지"가 없는 행
  /// (상단 고정 공지 등)을 버린다. 상단 고정(`tr.notice`)은 [NoticeItem.isRequired].
  @visibleForTesting
  static List<NoticeItem> parseList(String body, NoticeBoard board) {
    final rows = html_parser
        .parse(body)
        .querySelectorAll('table.board-table tbody tr');
    final items = <NoticeItem>[];
    for (final row in rows) {
      final link = row.querySelector('td.td-subject a');
      if (link == null) continue;
      final strong = link.querySelector('strong');
      final title = _collapse(
        strong != null
            ? strong.text
            : link.nodes.whereType<Text>().map((t) => t.text).join(),
      );
      if (title.isEmpty) continue;
      if (board == NoticeBoard.mileage && !title.contains('마일리지')) continue;

      String cell(String selector) =>
          _collapse(row.querySelector(selector)?.text ?? '');
      items.add(
        NoticeItem(
          title: title,
          author: cell('td.td-write'),
          date: cell('td.td-date'),
          viewCount:
              int.tryParse(cell('td.td-access').replaceAll(',', '')) ?? 0,
          tag: board.tag,
          isNew: link.querySelector('span.new') != null,
          isRequired: row.classes.contains('notice'),
          detailPath: link.attributes['href'],
          hasAttachment: row.querySelector('td.td-file p.file-y') != null,
        ),
      );
    }
    return items;
  }

  /// 상세 페이지: 제목 `h2.view-title`, 작성일·작성자·조회수 `div.view-util dl`,
  /// 본문 `div.view-con`, 첨부 `a.file-download`.
  @visibleForTesting
  static NoticeDetail parseDetail(String body) {
    final doc = html_parser.parse(body);
    final content = doc.querySelector('div.view-con');
    if (content == null) {
      throw const NoticeException('공지 내용을 찾지 못했어요');
    }
    String info(String cls) =>
        _collapse(doc.querySelector('div.view-util dl.$cls dd')?.text ?? '');
    return NoticeDetail(
      title: _collapse(doc.querySelector('h2.view-title')?.text ?? ''),
      author: info('writer'),
      date: info('write'),
      viewCount: int.tryParse(info('count').replaceAll(',', '')) ?? 0,
      body: _bodyText(content),
      attachments: [
        for (final a in doc.querySelectorAll('a.file-download'))
          if (a.attributes['href'] case final href?)
            NoticeAttachment(name: _collapse(a.text), url: '$_base$href'),
      ],
    );
  }

  static String _collapse(String s) =>
      s.replaceAll(' ', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  static const _blockTags = {
    'p', 'div', 'li', 'ul', 'ol', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', //
    'blockquote', 'pre',
  };

  /// 본문 HTML을 글자로 바꾼다. 문단은 줄바꿈, 표는 행마다 "칸 | 칸".
  /// 빈 줄은 하나까지만 남긴다.
  static String _bodyText(Element content) {
    final buf = StringBuffer();
    void walk(Node node) {
      if (node is Text) {
        buf.write(node.text);
        return;
      }
      if (node is! Element) return;
      final tag = node.localName;
      if (tag == 'script' || tag == 'style') return;
      if (tag == 'br') {
        buf.write('\n');
        return;
      }
      if (tag == 'table') {
        buf.write('\n');
        for (final tr in node.querySelectorAll('tr')) {
          final cells = tr.children
              .map((c) => _collapse(c.text))
              .where((t) => t.isNotEmpty);
          if (cells.isNotEmpty) buf.write('${cells.join(' | ')}\n');
        }
        buf.write('\n');
        return;
      }
      final block = _blockTags.contains(tag);
      if (block) buf.write('\n');
      if (tag == 'li') buf.write('• ');
      node.nodes.forEach(walk);
      if (block) buf.write('\n');
    }

    content.nodes.forEach(walk);
    final lines = <String>[];
    for (final raw in buf.toString().split('\n')) {
      final line = raw
          .replaceAll(' ', ' ')
          .replaceAll(RegExp(r'[ \t]+'), ' ')
          .trim();
      if (line.isEmpty && (lines.isEmpty || lines.last.isEmpty)) continue;
      lines.add(line);
    }
    while (lines.isNotEmpty && lines.last.isEmpty) {
      lines.removeLast();
    }
    return lines.join('\n');
  }

  /// GET을 보내고 리다이렉트를 직접 따라가며 홉마다 쿠키를 주고받는다.
  Future<String> _get(String url) async {
    final cookies = HostCookieJar();
    var uri = Uri.parse(url);
    for (var hop = 0; hop <= _maxRedirects; hop++) {
      final request = http.Request('GET', uri)
        ..followRedirects = false
        ..headers['User-Agent'] = _userAgent;
      final cookieHeader = cookies.headerFor(uri);
      if (cookieHeader.isNotEmpty) request.headers['Cookie'] = cookieHeader;

      final http.Response response;
      try {
        response = await http.Response.fromStream(
          await _client.send(request).timeout(const Duration(seconds: 15)),
        );
      } catch (e) {
        throw NoticeException('네트워크 오류: $e', isNetwork: true);
      }
      cookies.store(uri, response.headersSplitValues['set-cookie'] ?? const []);

      final location = response.headers['location'];
      if (response.statusCode >= 300 &&
          response.statusCode < 400 &&
          location != null) {
        uri = uri.resolve(location);
        continue;
      }
      if (response.statusCode != 200) {
        throw NoticeException('서버 오류 (${response.statusCode})');
      }
      return utf8.decode(response.bodyBytes, allowMalformed: true);
    }
    throw const NoticeException('리다이렉트가 너무 많아요');
  }

  Future<List<NoticeItem>?> _readStored(String key, NoticeBoard board) async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(key);
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = DateTime.parse(json['savedAt'] as String);
      if (_now().difference(savedAt) >= cacheDuration) return null;
      return [
        for (final e in json['items'] as List<dynamic>)
          NoticeItem(
            title: e['title'] as String,
            author: e['author'] as String,
            date: e['date'] as String,
            viewCount: e['viewCount'] as int,
            tag: board.tag,
            isNew: e['isNew'] as bool,
            isRequired: e['isRequired'] as bool,
            detailPath: e['detailPath'] as String?,
            hasAttachment: e['hasAttachment'] as bool,
          ),
      ];
    } catch (e) {
      // 저장된 값을 못 읽어도 서버에서 새로 받으면 되므로 조회를 막지 않는다.
      debugPrint('[Notice] 저장된 공지 읽기 실패: $e');
      return null;
    }
  }

  Future<void> _writeStored(String key, List<NoticeItem> items) async {
    try {
      await (await SharedPreferences.getInstance()).setString(
        key,
        jsonEncode({
          'savedAt': _now().toIso8601String(),
          'items': [
            for (final n in items)
              {
                'title': n.title,
                'author': n.author,
                'date': n.date,
                'viewCount': n.viewCount,
                'isNew': n.isNew,
                'isRequired': n.isRequired,
                'detailPath': n.detailPath,
                'hasAttachment': n.hasAttachment,
              },
          ],
        }),
      );
    } catch (e) {
      debugPrint('[Notice] 공지 저장 실패: $e');
    }
  }
}
