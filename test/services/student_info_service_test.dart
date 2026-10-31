import 'package:cp949_codec/cp949_codec.dart';
import 'package:daejin_app/services/student_info_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// 2026-10-31 실제 응답에서 본 "학적 변동 내역" 표 구조를 따라 만든 가짜 HTML이다.
// 값은 실제 학생 정보가 아니다.
String _page(List<List<String>> history) =>
    '''
<html><body>
<table>
<tr><td class="tr_chrm1_n">학번</td><td>20200000</td>
    <td class="tr_chrm1_n">이름</td><td>김대진</td></tr>
<tr><td class="tr_chrm1_n">지도교수</td><td>이교수</td>
    <td class="tr_chrm1_n">학과</td><td>컴퓨터공학전공</td></tr>
</table>
<table>
<tr><th>년도(학기)</th><th>변동 일자</th><th>변동
  사항</th><th>학년</th><th>복학예정년도(학기)</th></tr>
${history.map((r) => '<tr>${r.map((c) => '<td>$c</td>').join()}</tr>').join('\n')}
</table>
</body></html>
''';

int? _grade(List<List<String>> history, DateTime now) =>
    StudentInfoService.gradeFromHistory(html_parser.parse(_page(history)), now);

void main() {
  final returned = [
    ['2021 (1)', '2021년 03월 01일', '신입학', '1', '( )'],
    ['2021 (2)', '2021년 10월 22일', '군휴학', '1', '2023( 2 )'],
    ['2023 (2)', '2023년 08월 01일', '군복학', '1', '( )'],
    ['2025 (1)', '2025년 02월 21일', '일반휴학', '3', '2026( 1 )'],
    ['2026 (1)', '2026년 01월 07일', '일반복학', '3', '( )'],
  ];

  group('gradeFromHistory', () {
    test('마지막 기록(복학)의 학년을 쓴다', () {
      expect(_grade(returned, DateTime(2026, 10, 31)), 3);
    });

    test('복학 뒤 3월이 지나면 1학년 올린다', () {
      expect(_grade(returned, DateTime(2027, 2, 28)), 3);
      expect(_grade(returned, DateTime(2027, 3, 2)), 4);
    });

    test('마지막 기록이 휴학이면 올리지 않는다', () {
      final onLeave = returned.sublist(0, 4);
      expect(_grade(onLeave, DateTime(2026, 10, 31)), 3);
    });

    test('4학년을 넘지 않는다', () {
      expect(_grade(returned, DateTime(2030, 10, 31)), 4);
    });

    test('표가 없으면 null', () {
      expect(
        StudentInfoService.gradeFromHistory(
          html_parser.parse('<table><tr><td>x</td></tr></table>'),
          DateTime(2026, 10, 31),
        ),
        isNull,
      );
    });
  });

  test('응답에서 학과와 함께 학년("3학년")을 채운다', () async {
    final service = StudentInfoService(
      client: MockClient(
        (_) async => http.Response.bytes(cp949.encode(_page(returned)), 200),
      ),
      now: () => DateTime(2026, 10, 31),
    );

    final info = await service.fetchStudentInfo(userId2: 'uid');
    expect(info.department, '컴퓨터공학전공');
    expect(info.advisorName, '이교수');
    expect(info.grade, '3학년');
  });
}
