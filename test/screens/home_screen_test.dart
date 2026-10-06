// 홈 화면 헤드라인의 날씨 표시 상태(로딩/성공/에러)와, 날짜 아래 인사말이
// 실제 수업 시간 여부에 따라 바뀌는 로직을 검증한다.
// 실제 네트워크 호출 없이 WeatherService/CourseCatalogService/
// MyTimetableService에 http.testing.MockClient를 주입해서 각 상태로 분기시킨다.

import 'dart:async';
import 'dart:io';

import 'package:cp949_codec/cp949_codec.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:daejin_app/screens/home/widgets/header.dart';
import 'package:daejin_app/screens/home_screen.dart';
import 'package:daejin_app/services/course_catalog_service.dart';
import 'package:daejin_app/services/my_timetable_service.dart';
import 'package:daejin_app/services/student_info_service.dart';
import 'package:daejin_app/services/weather_service.dart';

const _fixtureJson = '''
{
  "current": {
    "temperature_2m": 21.3,
    "relative_humidity_2m": 55,
    "apparent_temperature": 20.9,
    "precipitation": 0.0,
    "weather_code": 0,
    "wind_speed_10m": 4.2
  },
  "hourly": {
    "time": ["2026-10-06T00:00"],
    "temperature_2m": [15.0],
    "precipitation": [0.0],
    "precipitation_probability": [10],
    "weather_code": [1]
  },
  "daily": {
    "time": ["2026-10-06"],
    "temperature_2m_max": [20.1],
    "temperature_2m_min": [10.2],
    "precipitation_sum": [0.0],
    "precipitation_probability_max": [10],
    "weather_code": [3]
  }
}
''';

void main() {
  testWidgets('날씨 조회가 끝나기 전에는 로딩 인디케이터를 보여준다', (tester) async {
    // 응답을 completer로 보류해서 로딩 상태를 고정시킨 뒤, 테스트 종료 전에
    // 완료시켜 pending timer가 남지 않게 한다.
    final responseCompleter = Completer<http.Response>();
    final mockClient = MockClient((request) => responseCompleter.future);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(weatherService: WeatherService(client: mockClient)),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    responseCompleter.complete(http.Response(_fixtureJson, 200));
    await tester.pumpAndSettle();
  });

  testWidgets('날씨 조회 성공 시 현재 온도와 날씨 아이콘을 보여준다', (tester) async {
    final mockClient = MockClient((request) async {
      return http.Response(_fixtureJson, 200);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(weatherService: WeatherService(client: mockClient)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('21°C'), findsOneWidget);
    expect(find.text('맑음'), findsOneWidget);
    expect(find.byIcon(Icons.wb_sunny), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('날씨 조회 실패 시 cloud_off 아이콘만 조용히 보여준다', (tester) async {
    final mockClient = MockClient((request) async {
      return http.Response('Internal Server Error', 500);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(weatherService: WeatherService(client: mockClient)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    // 에러 시 스낵바/다이얼로그 같은 방해 UI는 뜨지 않아야 한다.
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byType(Dialog), findsNothing);
  });

  group('인사말(오늘 하루도 화이팅!/{과목명} 수업 화이팅!)', () {
    // 날씨 조회는 이 그룹의 관심사가 아니므로, 전부 같은 성공 응답으로 고정해
    // 실제 네트워크 호출 없이 끝내고 greeting 로직만 분리해서 본다.
    WeatherService fakeWeatherService() => WeatherService(
      client: MockClient((request) async => http.Response(_fixtureJson, 200)),
    );

    // "내 정보"는 이 그룹의 관심사가 아니므로, userId2를 쓰는 테스트마다
    // 실제 네트워크를 타지 않도록 항상 mock StudentInfoService를 주입한다.
    StudentInfoService fakeStudentInfoService() => StudentInfoService(
      client: MockClient((request) async => http.Response('Not Found', 404)),
    );

    // 화요일(weekday=2) 10:00 — _estimateCurrentSemester/findCurrentClass가
    // 쓰는 "지금 시각"을 테스트에서 고정하기 위한 값. assumedPeriodTimes상
    // 2교시(10:00~10:50) 안에 들어가는 시각이라 "화2" 시간표와 매칭된다.
    final matchingNow = DateTime(2026, 10, 6, 10, 0);
    // 같은 화요일이지만 교시 사이 공강 시간(10:50~11:00)이라 어떤 교시에도
    // 매칭되지 않는다 — "현재 수업 없음" 상황을 고정하기 위한 값.
    final gapNow = DateTime(2026, 10, 6, 10, 55);

    List<int> catalogFixtureBytes() {
      final tds = [
        '1', // 일련번호
        'CSE301-01', // 과목코드-분반
        '자료구조', // 과목명
        '전공필수', // 이수구분
        '3.0', // 학점
        '2', // 학년
        '홍길동', // 교수
        '화2', // 시간표(요일+교시)
        '공학관201', // 강의실
        '', // 폐강
        '40', // 정원
        '0', // 대기
        '30/40', // 신청비율
        '', // 비고
      ].map((c) => '<td>$c</td>').join();
      final html =
          '<html><body><table>'
          '<tr class="tr_a0_chrm">$tds</tr>'
          '</table></body></html>';
      return cp949.encode(html);
    }

    List<int> timetableFixtureBytes() {
      final headerRow = '<tr><td>과목코드</td><td>과목명</td><td>분반</td></tr>';
      final dataRow = '<tr><td>CSE301</td><td>자료구조</td><td>01</td></tr>';
      final html =
          '<html><body><table id="tTbl">$headerRow$dataRow</table>'
          '</body></html>';
      return cp949.encode(html);
    }

    testWidgets('세션이 있고 현재 수업이 매칭되면 "{과목명} 수업 화이팅!"으로 바뀐다', (tester) async {
      final catalogClient = MockClient(
        (request) async => http.Response.bytes(catalogFixtureBytes(), 200),
      );
      final timetableClient = MockClient(
        (request) async => http.Response.bytes(timetableFixtureBytes(), 200),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            weatherService: fakeWeatherService(),
            jsessionId: 'JSESSION123',
            wmonid: 'WMONID123',
            userId2: 'REAL_USER_UID',
            courseCatalogService: CourseCatalogService(client: catalogClient),
            myTimetableService: MyTimetableService(client: timetableClient),
            studentInfoService: fakeStudentInfoService(),
            now: () => matchingNow,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('자료구조 수업 화이팅!'), findsOneWidget);
      expect(find.text('오늘 하루도 화이팅!'), findsNothing);
    });

    testWidgets('세션이 없으면(jsessionId/wmonid/userId2 중 하나라도 null) 원래 문구 그대로다', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: HomeScreen(weatherService: fakeWeatherService())),
      );
      await tester.pumpAndSettle();

      expect(find.text('오늘 하루도 화이팅!'), findsOneWidget);
    });

    testWidgets('세션은 있지만 지금이 수업 시간이 아니면 원래 문구 그대로다', (tester) async {
      final catalogClient = MockClient(
        (request) async => http.Response.bytes(catalogFixtureBytes(), 200),
      );
      final timetableClient = MockClient(
        (request) async => http.Response.bytes(timetableFixtureBytes(), 200),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            weatherService: fakeWeatherService(),
            jsessionId: 'JSESSION123',
            wmonid: 'WMONID123',
            userId2: 'REAL_USER_UID',
            courseCatalogService: CourseCatalogService(client: catalogClient),
            myTimetableService: MyTimetableService(client: timetableClient),
            studentInfoService: fakeStudentInfoService(),
            now: () => gapNow,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('오늘 하루도 화이팅!'), findsOneWidget);
    });

    testWidgets('서비스 호출 중 예외가 발생해도 앱이 죽지 않고 원래 문구로 폴백한다', (tester) async {
      final catalogClient = MockClient(
        (request) async => http.Response('Internal Server Error', 500),
      );
      final timetableClient = MockClient(
        (request) async => http.Response.bytes(timetableFixtureBytes(), 200),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            weatherService: fakeWeatherService(),
            jsessionId: 'JSESSION123',
            wmonid: 'WMONID123',
            userId2: 'REAL_USER_UID',
            courseCatalogService: CourseCatalogService(client: catalogClient),
            myTimetableService: MyTimetableService(client: timetableClient),
            studentInfoService: fakeStudentInfoService(),
            now: () => matchingNow,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('오늘 하루도 화이팅!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('내 정보 다이얼로그', () {
    WeatherService fakeWeatherService() => WeatherService(
      client: MockClient((request) async => http.Response(_fixtureJson, 200)),
    );

    // StudentInfoService._parse가 찾는 라벨-값 쌍(`td.tr_chrm1_n` 다음
    // 형제 요소)만 최소로 갖춘 고정 응답. department row를 생략해 "일부
    // 필드가 null인 정상 케이스"도 같이 검증한다.
    List<int> studentInfoFixtureBytes({bool includeDepartment = true}) {
      final departmentRow = includeDepartment
          ? '<tr><td class="tr_chrm1_n">학과</td><td>컴퓨터공학과</td></tr>'
          : '';
      final html =
          '<html><body><table>'
          '<tr><td class="tr_chrm1_n">이름</td><td>테스트학생</td></tr>'
          '$departmentRow'
          '<tr><td class="tr_chrm1_n">학년</td><td>2학년</td></tr>'
          '</table></body></html>';
      return cp949.encode(html);
    }

    // 아바타를 탭해 메뉴를 띄우고 "내 정보"를 눌러 다이얼로그를 연다.
    // 아바타는 Header 안에서 유일한 ClipOval(아바타 원형 썸네일)로 찾는다 —
    // 이를 감싼 GestureDetector는 Header의 다른 자손(Switch 등)이 내부적으로
    // 쓰는 GestureDetector와 섞여 타입만으로는 특정할 수 없기 때문이다.
    // [settleAfterOpen]은 기본 true. 로딩 중(스피너가 떠 있는) 상태를
    // 검증하는 테스트에서는 false로 넘겨야 한다 — CircularProgressIndicator는
    // 계속 애니메이션 프레임을 요청해서 pumpAndSettle이 끝나지 않는다.
    Future<void> openMyInfoDialog(
      WidgetTester tester, {
      bool settleAfterOpen = true,
    }) async {
      await tester.tap(
        find.descendant(
          of: find.byType(Header),
          matching: find.byType(ClipOval),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('내 정보'));
      if (settleAfterOpen) {
        await tester.pumpAndSettle();
      } else {
        await tester.pump();
      }
    }

    testWidgets('조회가 끝나기 전에는 로딩 인디케이터를 보여준다', (tester) async {
      final responseCompleter = Completer<http.Response>();
      final mockClient = MockClient((request) => responseCompleter.future);

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            weatherService: fakeWeatherService(),
            userId2: 'REAL_USER_UID',
            studentInfoService: StudentInfoService(client: mockClient),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await openMyInfoDialog(tester, settleAfterOpen: false);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      responseCompleter.complete(
        http.Response.bytes(studentInfoFixtureBytes(), 200),
      );
      await tester.pumpAndSettle();

      expect(find.text('테스트학생'), findsOneWidget);
    });

    testWidgets('조회 성공 시 실제 이름/학과/학년을 보여주고, 없는 필드는 "정보 없음"으로 보여준다', (
      tester,
    ) async {
      final mockClient = MockClient(
        (request) async => http.Response.bytes(
          studentInfoFixtureBytes(includeDepartment: false),
          200,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            weatherService: fakeWeatherService(),
            userId2: 'REAL_USER_UID',
            studentInfoService: StudentInfoService(client: mockClient),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await openMyInfoDialog(tester);

      expect(find.text('테스트학생'), findsOneWidget);
      expect(find.text('2학년'), findsOneWidget);
      expect(find.text('정보 없음'), findsOneWidget);
    });

    testWidgets('userId2가 없으면(세션 정보 없음) 재로그인 안내를 보여준다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: HomeScreen(weatherService: fakeWeatherService())),
      );
      await tester.pumpAndSettle();

      await openMyInfoDialog(tester);

      expect(find.text('로그인 정보를 찾을 수 없어요.\n다시 로그인해주세요.'), findsOneWidget);
      expect(find.text('로그인 화면으로 이동'), findsOneWidget);
    });

    testWidgets('네트워크 오류 시 재시도 버튼을 보여주고, 재시도가 성공하면 값을 보여준다', (tester) async {
      var callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        if (callCount == 1) {
          throw const SocketException('연결 실패');
        }
        return http.Response.bytes(studentInfoFixtureBytes(), 200);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            weatherService: fakeWeatherService(),
            userId2: 'REAL_USER_UID',
            studentInfoService: StudentInfoService(client: mockClient),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await openMyInfoDialog(tester);

      expect(find.text('네트워크 연결을 확인해주세요.'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);

      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();

      expect(find.text('테스트학생'), findsOneWidget);
      expect(find.text('네트워크 연결을 확인해주세요.'), findsNothing);
    });
  });

  group('날씨 상세 모달', () {
    // daily 2일치 + 모달이 쓰는 시간대(오늘 18시, 내일 6/9/15/18시)만 채운
    // hourly 응답. 날짜를 넘겨보는 테스트까지 커버하려면 _fixtureJson(1일치)
    // 로는 부족해서 이 그룹 전용으로 따로 둔다.
    const detailFixtureJson = '''
{
  "current": {
    "temperature_2m": 21.3,
    "relative_humidity_2m": 55,
    "apparent_temperature": 20.9,
    "precipitation": 0.0,
    "weather_code": 0,
    "wind_speed_10m": 4.2
  },
  "hourly": {
    "time": [
      "2026-10-06T18:00",
      "2026-10-07T06:00",
      "2026-10-07T09:00",
      "2026-10-07T15:00",
      "2026-10-07T18:00"
    ],
    "temperature_2m": [19.5, 16.9, 15.3, 25.9, 23.9],
    "precipitation": [0.0, 0.0, 0.0, 0.0, 0.0],
    "precipitation_probability": [10, 0, 0, 0, 0],
    "weather_code": [0, 0, 0, 0, 0]
  },
  "daily": {
    "time": ["2026-10-06", "2026-10-07"],
    "temperature_2m_max": [20.1, 27.2],
    "temperature_2m_min": [10.2, 15.3],
    "precipitation_sum": [0.0, 0.0],
    "precipitation_probability_max": [10, 0],
    "weather_code": [0, 0]
  }
}
''';

    WeatherService fakeDetailWeatherService() => WeatherService(
      client: MockClient(
        (request) async => http.Response(detailFixtureJson, 200),
      ),
    );

    testWidgets('날씨 아이콘을 누르면 상세 모달이 뜨고 오늘 날씨를 보여준다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(weatherService: fakeDetailWeatherService()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('21°C'));
      await tester.pumpAndSettle();

      expect(find.text('우리 학교 날씨는?!'), findsOneWidget);
      expect(find.text('오늘'), findsOneWidget);
      expect(find.text('21.3°'), findsOneWidget);
      expect(find.text('강수확률 10%'), findsOneWidget);
      expect(find.text('지금'), findsOneWidget);
      expect(find.text('저녁'), findsOneWidget);
      expect(find.text('20°'), findsOneWidget); // 저녁 19.5°를 반올림한 값

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('우리 학교 날씨는?!'), findsNothing);
    });

    testWidgets('오른쪽 화살표를 누르면 다음 날짜의 날씨로 넘어간다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(weatherService: fakeDetailWeatherService()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('21°C'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      expect(find.text('오늘'), findsNothing);
      expect(find.text('15.3° / 27.2°'), findsOneWidget);
      expect(find.text('강수확률 0%'), findsOneWidget);
      expect(find.text('새벽'), findsOneWidget);
      expect(find.text('아침'), findsOneWidget);
      expect(find.text('낮'), findsOneWidget);
      expect(find.text('저녁'), findsOneWidget);
    });

    testWidgets('날씨 조회 실패 상태에서는 날씨 아이콘을 눌러도 모달이 뜨지 않는다', (tester) async {
      final mockClient = MockClient(
        (request) async => http.Response('Internal Server Error', 500),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(weatherService: WeatherService(client: mockClient)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.cloud_off));
      await tester.pumpAndSettle();

      expect(find.text('우리 학교 날씨는?!'), findsNothing);
    });
  });
}
