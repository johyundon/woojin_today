import 'dart:convert';

import 'package:daejin_app/screens/notice/models/notice_item.dart';
import 'package:daejin_app/services/notice_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 2026-10-31 실제 응답(www.daejin.ac.kr)의 구조를 본떠 만든 HTML이다. 값은 지어낸 것.

String _row({
  required String title,
  String cls = '',
  bool isNew = false,
  bool file = false,
  bool strong = true,
  String path = '/bbs/daejin/188/1/artclView.do',
}) =>
    '''
<tr class="$cls">
  <td class="td-num">1</td>
  <td class="td-subject">
    <a href="$path" onclick="jf_viewArtcl('daejin', '188', '1')">
      ${strong ? '<strong>$title</strong>' : '$title <em>무시</em>'}
      ${isNew ? '<span class="new">새글</span>' : ''}
    </a>
  </td>
  <td class="td-write"> 학사팀 </td>
  <td class="td-date">2026.10.29</td>
  <td class="td-access"> 1,204 </td>
  <td class="td-file ${file ? 'file' : ''}"><p class="${file ? 'file-y' : 'file-n'}">${file ? '파일첨부' : '0'}</p></td>
</tr>''';

String _list(List<String> rows) => '''
<html><body><table class="board-table horizon1"><thead><tr>
<th class="th-num">NO</th><th class="th-subject">제목</th></tr></thead>
<tbody>${rows.join()}<tr><td colspan="6">링크 없는 행</td></tr></tbody></table></body></html>''';

const _detail = '''
<html><body>
<div class="view-info"><dl class="view-num"><dt>글번호</dt><dd>463279</dd></dl>
<h2 class="view-title"> 2학기 이수신청 안내 </h2></div>
<div class="view-detail"><div class="view-util">
  <dl class="write"><dt>작성일</dt><dd>2026.10.29</dd></dl>
  <dl class="modify"><dt>수정일</dt><dd>2026.10.30</dd></dl>
  <dl class="writer"><dt>작성자</dt><dd> 학사팀 </dd></dl>
  <dl class="count"><dt>조회수</dt><dd>95</dd></dl>
</div></div>
<div class="view-con">
  <p><span>1. 관련 : 학칙</span></p>
  <p><span><br></span></p>
  <p><span><br></span></p>
  <p><span>&nbsp; 가. 대상 :&nbsp;<b>재학생</b></span></p>
  <table><tr><th>구분</th><th>기간</th></tr><tr><td>신청</td><td>11.1~11.30</td></tr></table>
  <ul><li>첫째</li><li>둘째</li></ul>
  <script>ignored()</script>
</div>
<div class="view-file"><ul>
  <li><a href="/bbs/daejin/188/1/download.do" class="file-download"> 붙임 1 안내문.xlsx </a>
      <a href="/bbs/daejin/188/1/synapView.do" class="file-view">미리보기</a></li>
  <li><a href="/bbs/daejin/188/2/download.do" class="file-download"> 붙임 2 서식.hwp </a></li>
</ul></div>
</body></html>''';

/// 명세대로: 첫 요청은 인증 확인으로 보내고, 쿠키를 다시 실어 와야 원래 주소로
/// 돌려보낸다(쿠키가 없으면 같은 곳을 맴돈다). 중간에 nsso 서버를 한 번 거친다.
MockClient _server(
  List<http.Request> log, {
  required String listBody,
}) => MockClient((request) async {
  log.add(request);
  final cookie = request.headers['Cookie'] ?? '';
  switch (request.url.path) {
    case '/daejin/1003/subview.do' || '/daejin/1002/subview.do':
      if (!cookie.contains('JSESSIONID=www-1')) {
        return http.Response(
          '',
          302,
          headers: {
            'location':
                'https://nsso.daejin.ac.kr/sso/checkToken.do?return=${Uri.encodeComponent(request.url.toString())}',
            'set-cookie': 'JSESSIONID=www-1; Path=/',
          },
        );
      }
      return http.Response.bytes(utf8.encode(listBody), 200);
    case '/sso/checkToken.do':
      return http.Response(
        '',
        302,
        headers: {
          'location': request.url.queryParameters['return']!,
          'set-cookie': 'JSESSIONID=nsso-1; Path=/',
        },
      );
    case '/bbs/daejin/188/1/artclView.do':
      return http.Response.bytes(utf8.encode(_detail), 200);
  }
  return http.Response('not found', 404);
});

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    NoticeService.clearMemoryCache();
  });

  group('parseList', () {
    test('학사공지 행에서 제목·작성자·날짜·조회수·새글·첨부·경로를 읽는다', () {
      final items = NoticeService.parseList(
        _list([
          _row(title: '수강 정정 안내', isNew: true, file: true),
          _row(title: '직접 텍스트 제목', strong: false),
          _row(title: '  '),
        ]),
        NoticeBoard.academic,
      );

      expect(items.length, 2);
      final first = items.first;
      expect(first.title, '수강 정정 안내');
      expect(first.author, '학사팀');
      expect(first.date, '2026.10.29');
      expect(first.viewCount, 1204);
      expect(first.isNew, isTrue);
      expect(first.hasAttachment, isTrue);
      expect(first.isRequired, isFalse);
      expect(first.tag, NoticeTag.academic);
      expect(first.detailPath, '/bbs/daejin/188/1/artclView.do');
      // strong이 없으면 a의 직접 텍스트만(안쪽 태그 제외).
      expect(items[1].title, '직접 텍스트 제목');
      expect(items[1].isNew, isFalse);
      expect(items[1].hasAttachment, isFalse);
    });

    test('마일리지 게시판은 제목에 "마일리지"가 없는 행을 버린다', () {
      final items = NoticeService.parseList(
        _list([
          _row(title: '천원의 아침밥 안내', cls: 'notice '),
          _row(title: '마일리지 제도 변경 안내', cls: 'notice '),
          _row(title: '2026학년도 1학기 마일리지장학 대상자 공지', file: true),
        ]),
        NoticeBoard.mileage,
      );

      expect(items.map((n) => n.title), [
        '마일리지 제도 변경 안내',
        '2026학년도 1학기 마일리지장학 대상자 공지',
      ]);
      expect(items.first.isRequired, isTrue);
      expect(items.last.isRequired, isFalse);
      expect(items.every((n) => n.tag == NoticeTag.scholarship), isTrue);
    });
  });

  group('parseDetail', () {
    test('정보·본문·첨부를 뽑는다', () {
      final d = NoticeService.parseDetail(_detail);

      expect(d.title, '2학기 이수신청 안내');
      expect(d.author, '학사팀');
      expect(d.date, '2026.10.29');
      expect(d.viewCount, 95);
      // 빈 문단이 이어져도 빈 줄은 하나만, 표는 "칸 | 칸", 목록은 "•".
      expect(
        d.body,
        '1. 관련 : 학칙\n'
        '\n'
        '가. 대상 : 재학생\n'
        '\n'
        '구분 | 기간\n'
        '신청 | 11.1~11.30\n'
        '\n'
        '• 첫째\n'
        '\n'
        '• 둘째',
      );
      expect(d.attachments.map((a) => a.name), [
        '붙임 1 안내문.xlsx',
        '붙임 2 서식.hwp',
      ]);
      expect(
        d.attachments.first.url,
        'https://www.daejin.ac.kr/bbs/daejin/188/1/download.do',
      );
    });

    test('본문 영역이 없으면 실패로 본다', () {
      expect(
        () => NoticeService.parseDetail('<html><body>접근 권한</body></html>'),
        throwsA(isA<NoticeException>()),
      );
    });
  });

  group('fetchNotices', () {
    test('리다이렉트마다 쿠키를 서버별로 이어 보내 목록을 받는다', () async {
      final log = <http.Request>[];
      final service = NoticeService(
        client: _server(log, listBody: _list([_row(title: '공지 A')])),
      );

      final items = await service.fetchNotices(NoticeBoard.academic);

      expect(items.single.title, '공지 A');
      expect(log.length, 3);
      // nsso 쿠키는 www에 보내지 않는다.
      expect(log.last.headers['Cookie'], 'JSESSIONID=www-1');
      expect(log.last.headers['User-Agent'], contains('Mobile'));
    });

    test('1시간 안에는 다시 요청하지 않고, 지나면 새로 받는다', () async {
      final log = <http.Request>[];
      var now = DateTime(2026, 10, 31, 10);
      final service = NoticeService(
        client: _server(
          log,
          listBody: _list([_row(title: '공지 A', isNew: true)]),
        ),
        now: () => now,
      );

      await service.fetchNotices(NoticeBoard.academic);
      final first = log.length;

      now = now.add(const Duration(minutes: 59));
      final cached = await service.fetchNotices(NoticeBoard.academic);
      expect(log.length, first);
      expect(cached.single.title, '공지 A');
      expect(cached.single.isNew, isTrue);
      expect(cached.single.detailPath, '/bbs/daejin/188/1/artclView.do');

      // 다른 게시판은 따로 저장한다.
      await service.fetchNotices(NoticeBoard.mileage);
      expect(log.length, greaterThan(first));
      final afterMileage = log.length;

      now = now.add(const Duration(minutes: 1));
      await service.fetchNotices(NoticeBoard.academic);
      expect(log.length, greaterThan(afterMileage));
    });

    test('forceRefresh면 기한 안이라도 새로 받는다', () async {
      final log = <http.Request>[];
      final service = NoticeService(
        client: _server(log, listBody: _list([_row(title: '공지 A')])),
      );

      await service.fetchNotices(NoticeBoard.academic);
      final first = log.length;
      await service.fetchNotices(NoticeBoard.academic, forceRefresh: true);
      expect(log.length, first * 2);
    });

    test('통신 실패와 서버 오류를 구분하고, 실패는 저장하지 않는다', () async {
      await expectLater(
        NoticeService(
          client: MockClient((_) async => throw Exception('offline')),
        ).fetchNotices(NoticeBoard.academic),
        throwsA(
          isA<NoticeException>().having((e) => e.isNetwork, 'isNetwork', true),
        ),
      );
      await expectLater(
        NoticeService(
          client: MockClient((_) async => http.Response('err', 500)),
        ).fetchNotices(NoticeBoard.academic),
        throwsA(
          isA<NoticeException>().having((e) => e.isNetwork, 'isNetwork', false),
        ),
      );

      final log = <http.Request>[];
      await NoticeService(
        client: _server(log, listBody: _list([_row(title: '공지 A')])),
      ).fetchNotices(NoticeBoard.academic);
      expect(log, isNotEmpty);
    });
  });

  test('상세는 한 번 받으면 다시 요청하지 않는다', () async {
    final log = <http.Request>[];
    final service = NoticeService(client: _server(log, listBody: ''));

    final d = await service.fetchDetail('/bbs/daejin/188/1/artclView.do');
    await service.fetchDetail('/bbs/daejin/188/1/artclView.do');

    expect(d.title, '2학기 이수신청 안내');
    expect(log.length, 1);
  });
}
