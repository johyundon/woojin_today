// 강의계획서 서비스: 분류 고르기 → 목록에서 상세 링크 찾기 → 상세 읽기를
// 익명 fixture로 검증한다. 상세 fixture는 Notion 명세의 실제 응답 예시에서
// 교수 이름·연락처·연구실·강의실·교수번호를 가짜 값으로 바꾸고, 읽지 않는
// 표(수업방법)와 일부 주차를 줄인 것이다(EUC-KR 저장).
import 'dart:io';

import 'package:daejin_app/services/course_catalog_service.dart';
import 'package:daejin_app/services/syllabus_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _dir = 'test/services/fixtures/syllabus';

CourseCatalogItem _course({
  String code = '922601',
  String section = '01',
  String type = '교필',
  String? department,
}) => CourseCatalogItem(
  seq: 1,
  courseCode: code,
  section: section,
  courseName: 'AI시대의컴퓨팅사고',
  courseType: type,
  credit: 2,
  targetGrade: '',
  professor: '김가상',
  rawSchedule: '수11:30-13:30',
  room: '',
  isClosed: false,
  capacity: 0,
  waitlistCount: 0,
  enrollmentRatio: '',
  department: department,
);

http.Response _euckr(String file) => http.Response.bytes(
  File('$_dir/$file').readAsBytesSync(),
  200,
  headers: {'content-type': 'text/html; charset=euc-kr'},
);

void main() {
  setUp(SyllabusService.clearCache);

  group('분류 고르기(categoryQuery)', () {
    test('교필/교직/일선은 고정 코드', () {
      expect(SyllabusService.categoryQuery(_course(type: '교필')), 'ic_kwa=B41001');
      expect(SyllabusService.categoryQuery(_course(type: '교직')), 'ic_kwa=B41004');
      expect(SyllabusService.categoryQuery(_course(type: '일선')), 'ic_kwa=B41020');
    });

    test('전공은 개설학과 이름을 학과 코드로 바꾼다(뒤 공백 포함)', () {
      expect(
        SyllabusService.categoryQuery(
          _course(type: '전필', department: '컴퓨터공학전공'),
        ),
        'ic_kwa=B41005&ic_kwa_1=AA0194%20',
      );
      expect(
        SyllabusService.categoryQuery(
          _course(type: '전선', department: 'AI빅데이터전공'),
        ),
        'ic_kwa=B41005&ic_kwa_1=AA0816%20',
      );
    });

    test('교양선택, 모르는 학과, 학과 없는 전공은 null', () {
      expect(SyllabusService.categoryQuery(_course(type: '교선')), isNull);
      expect(
        SyllabusService.categoryQuery(_course(type: '전필', department: '없는학과')),
        isNull,
      );
      expect(SyllabusService.categoryQuery(_course(type: '전필')), isNull);
    });
  });

  test('찾을 수 없는 이유를 과목 상태별로 알려준다', () {
    expect(
      SyllabusService.unavailableReason(_course(type: '교선')),
      '교양선택 과목은 아직 강의계획서를 불러올 수 없어요.',
    );
    expect(
      SyllabusService.unavailableReason(_course(type: '전필')),
      contains('내 시간표 불러오기'),
    );
    expect(
      SyllabusService.unavailableReason(_course(type: '전필', department: '없는학과')),
      '없는학과의 강의계획서 목록을 찾을 수 없어요.',
    );
  });

  test('목록에서 링크 주소의 과목코드-분반으로 상세 링크를 찾는다', () {
    final bytes = File('$_dir/syllabus_list_anonymized.html').readAsBytesSync();
    final html = String.fromCharCodes(bytes); // 링크 주소는 ASCII라 충분.
    final links = SyllabusService.parseList(html);

    expect(links.keys, {'922601-01', '922601-02', '927381-21'});
    expect(
      links['922601-02'],
      'Blsn020303.jsp?fhd_00=922601&fhd_01=02&fhd_02=2026&fhd_03=2&fhd_04=7654321',
    );
  });

  group('fetchSyllabus', () {
    test('목록 1번 → 상세 1번을 부르고, 상세 주소에 교수번호가 들어간다', () async {
      final requested = <Uri>[];
      final service = SyllabusService(
        client: MockClient((request) async {
          requested.add(request.url);
          return request.url.path.endsWith('Blsn020302.jsp')
              ? _euckr('syllabus_list_anonymized.html')
              : _euckr('syllabus_detail_anonymized.html');
        }),
      );

      final detail = await service.fetchSyllabus(
        course: _course(),
        year: 2026,
        semester: 2,
        jsessionId: 'J',
        wmonid: 'W',
        userId2: 'U',
      );

      expect(requested, hasLength(2));
      expect(
        requested[0].toString(),
        'https://dreams2.daejin.ac.kr/sugang/center/Blsn020302.jsp'
        '?fhd_yyyy=2026&fhd_shtm=2&ic_kwa=B41001',
      );
      expect(
        requested[1].toString(),
        'https://dreams2.daejin.ac.kr/sugang/center/Blsn020303.jsp'
        '?fhd_00=922601&fhd_01=01&fhd_02=2026&fhd_03=2&fhd_04=1234567',
      );
      expect(detail.info('담당교수'), '김가상');
    });

    test('같은 학기·분류 목록과 같은 상세는 다시 요청하지 않는다', () async {
      var calls = 0;
      final service = SyllabusService(
        client: MockClient((request) async {
          calls++;
          return request.url.path.endsWith('Blsn020302.jsp')
              ? _euckr('syllabus_list_anonymized.html')
              : _euckr('syllabus_detail_anonymized.html');
        }),
      );
      Future<void> open(String section) => service.fetchSyllabus(
        course: _course(section: section),
        year: 2026,
        semester: 2,
        jsessionId: 'J',
        wmonid: 'W',
        userId2: 'U',
      );

      await open('01');
      await open('01');
      await open('02');

      expect(calls, 3); // 목록 1 + 상세(01) 1 + 상세(02) 1
    });

    test('교양선택처럼 분류를 모르는 과목은 요청 없이 Unavailable', () async {
      var calls = 0;
      final service = SyllabusService(
        client: MockClient((request) async {
          calls++;
          return http.Response('', 200);
        }),
      );

      await expectLater(
        service.fetchSyllabus(
          course: _course(type: '교선'),
          year: 2026,
          semester: 2,
          jsessionId: 'J',
          wmonid: 'W',
          userId2: 'U',
        ),
        throwsA(isA<SyllabusUnavailableException>()),
      );
      expect(calls, 0);
    });

    test('목록에 과목이 없으면 Unavailable', () async {
      final service = SyllabusService(
        client: MockClient(
          (request) async => _euckr('syllabus_list_anonymized.html'),
        ),
      );

      await expectLater(
        service.fetchSyllabus(
          course: _course(code: '999999'),
          year: 2026,
          semester: 2,
          jsessionId: 'J',
          wmonid: 'W',
          userId2: 'U',
        ),
        throwsA(isA<SyllabusUnavailableException>()),
      );
    });

    test('서버 오류와 네트워크 오류를 구분한다', () async {
      Future<void> run(MockClient client) => SyllabusService(client: client)
          .fetchSyllabus(
            course: _course(),
            year: 2026,
            semester: 2,
            jsessionId: 'J',
            wmonid: 'W',
            userId2: 'U',
          );

      await expectLater(
        run(MockClient((_) async => http.Response('err', 500))),
        throwsA(isA<SyllabusServerException>()),
      );
      await expectLater(
        run(MockClient((_) async => throw Exception('끊김'))),
        throwsA(isA<SyllabusNetworkException>()),
      );
    });
  });

  group('상세 읽기(parseDetail)', () {
    late SyllabusDetail detail;
    setUpAll(() async {
      final service = SyllabusService(
        client: MockClient(
          (request) async => request.url.path.endsWith('Blsn020302.jsp')
              ? _euckr('syllabus_list_anonymized.html')
              : _euckr('syllabus_detail_anonymized.html'),
        ),
      );
      SyllabusService.clearCache();
      detail = await service.fetchSyllabus(
        course: _course(),
        year: 2026,
        semester: 2,
        jsessionId: 'J',
        wmonid: 'W',
        userId2: 'U',
      );
    });

    test('상단 정보: 첫 table1의 라벨-값 쌍(줄바꿈은 공백으로)', () {
      expect(detail.info('교과목명(국문)'), 'AI시대의컴퓨팅사고');
      expect(detail.info('교과번호-분반'), '922601-01');
      expect(detail.info('수업장소'), '가상관 310 강의실');
      expect(detail.info('수강대상'), '1학년');
      expect(detail.info('학점/강의/실습'), '2/4/0');
      expect(detail.info('연구실'), '가상관 101 호');
    });

    test('번호 매겨진 절 제목을 순서대로 읽는다', () {
      expect(detail.sections.map((s) => s.title), [
        '1. 수업의 개요와 유용성',
        '2. 선행학습 및 선수과목 요건',
        '3-1) 핵심역량 및 수업목표',
        '4. 수업형태',
        '5. 수업방법',
        '7. 학습 평가방법',
        '10. 주별 수업계획',
        '11. 연계 비교과 프로그램',
      ]);
      expect(detail.section('2.')!.bodyText, '해당사항 없음');
      expect(detail.section('1.')!.bodyText, startsWith('본 교과목은'));
    });

    test('핵심역량: %가 있는 행만(6대 역량 정의 표는 제외)', () {
      expect(detail.section('3-1)')!.competencies, [
        (
          name: '창의융합역량',
          ratio: '70%(주역량)',
          goal: 'AI 기술을 활용해 다양한 정보를 효과적으로 처리하고 창의적으로 문제를 해결하는 역량을 함양',
        ),
        (
          name: '혁신역량',
          ratio: '30%(부역량)',
          goal: '주어진 문제를 해결하는 과정을 통해 도전과 비판적 사고력을 함양',
        ),
      ]);
    });

    test('평가방법: rowspan 묶음 이름을 이어받는다', () {
      final evaluations = detail.section('7.')!.evaluations!;
      expect(evaluations.map((e) => '${e.name}=${e.ratio}'), [
        '출석=20%',
        '중간시험=20%',
        '기말시험=20%',
        '과제=20%',
        '학습태도 (루브릭평가 포함) · 발표=20%',
        '학습태도 (루브릭평가 포함) · 토의/토론=0%',
        '학습태도 (루브릭평가 포함) · 팀활동 참여도=0%',
        '학습태도 (루브릭평가 포함) · 수시시험=0%',
        '학습태도 (루브릭평가 포함) · 실무현장평가=0%',
        '기타=0%',
      ]);
    });

    test('주별 수업계획: 주차·주제·내용(줄바꿈 유지)·방법', () {
      final weeks = detail.section('10.')!.weeks!;
      expect(weeks.map((w) => w.week), ['1', '2', '8', '15']);
      expect(weeks.first.topic, '강의 소개');
      expect(weeks.first.content, '■ 수업 개요 및 학습 목표 소개\n■ AI 개념과 발전 과정 소개');
      expect(weeks.first.method, '강의,실습');
    });

    test('table1이 없으면 ParseException', () {
      expect(
        () => SyllabusService.parseDetail('<html><body>없음</body></html>'),
        throwsA(isA<SyllabusParseException>()),
      );
    });
  });
}
