// 홈 화면의 날씨 표시 상태(로딩/성공/에러)와, 인사말/다음 수업 카드가
// 오늘 남은 수업 여부에 따라 바뀌는 로직을 검증한다.
// 실제 네트워크 호출 없이 WeatherService/MyTimetableService에 http.testing.MockClient를 주입해서 각 상태로 분기시킨다.

import 'dart:async';
import 'dart:io';

import 'package:cp949_codec/cp949_codec.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:daejin_app/screens/home/widgets/home_top_icon_button.dart';
import 'package:daejin_app/screens/home_screen.dart';
import 'package:daejin_app/screens/notice/models/notice_item.dart';
import 'package:daejin_app/services/notice_service.dart';
import 'package:daejin_app/services/notice_watcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:daejin_app/services/my_timetable_service.dart';
import 'package:daejin_app/services/session_cache.dart';
import 'package:daejin_app/services/student_info_service.dart';
import 'package:daejin_app/services/fakes/fake_cafeteria_menu_service.dart';
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
  // 여러 테스트가 같은 jsessionId/wmonid/userId2 값을 재사용하면서 서로 다른
  // mock 응답을 기대한다 — SessionCache는 이 식별자로 캐싱하므로, 테스트마다
  // 비워주지 않으면 앞 테스트의 캐시가 뒤 테스트로 새어 들어간다.
  setUp(SessionCache.clear);

  group('인사말(오늘 수업 N개 남았어/오늘 하루도 화이팅!)', () {
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
    // 쓰는 "지금 시각"을 테스트에서 고정하기 위한 값. "화10:00-10:50" 시간표와
    // 매칭된다.
    final matchingNow = DateTime(2026, 10, 6, 10, 0);
    // 같은 화요일이지만 수업 시간(10:00~10:50) 밖이라 매칭되지 않는다 —
    // "현재 수업 없음" 상황을 고정하기 위한 값.
    final gapNow = DateTime(2026, 10, 6, 10, 55);

    List<int> timetableFixtureBytes() {
      // 실제 응답(table#tTbl)과 같은 10칸: 교과번호/교과목명/분반/이수구분/
      // 학점/담당교수/강의시간/강의실/개설학과/비고.
      final headerRow =
          '<tr><td>교과번호</td><td>교과목명</td><td>분반</td><td>이수구분</td>'
          '<td>학점</td><td>담당교수</td><td>강의시간</td><td>강의실</td>'
          '<td>개설학과</td><td>비고</td></tr>';
      final dataRow =
          '<tr><td>CSE301</td><td>자료구조</td><td>01</td><td>전필</td>'
          '<td>3</td><td>홍길동</td><td>화10:00-10:50</td><td>공학관201</td>'
          '<td>컴퓨터공학과</td><td></td></tr>';
      final html =
          '<html><body><table id="tTbl">$headerRow$dataRow</table>'
          '</body></html>';
      return cp949.encode(html);
    }

    testWidgets('세션이 있고 오늘 남은 수업이 있으면 "오늘 수업 N개 남았어"와 다음 수업 카드를 보여준다', (
      tester,
    ) async {
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
            myTimetableService: MyTimetableService(client: timetableClient),
            studentInfoService: fakeStudentInfoService(),
            now: () => matchingNow,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('오늘 수업 1개 남았어'), findsOneWidget);
      expect(find.text('자료구조'), findsOneWidget);
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

    testWidgets('세션은 있지만 오늘 수업이 모두 끝났으면 그 안내 문구를 보여준다', (tester) async {
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
            myTimetableService: MyTimetableService(client: timetableClient),
            studentInfoService: fakeStudentInfoService(),
            now: () => gapNow,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('오늘도 수고했어!'), findsOneWidget);
    });

    testWidgets('서비스 호출 중 예외가 발생해도 앱이 죽지 않고 원래 문구로 폴백한다', (tester) async {
      final timetableClient = MockClient(
        (request) async => http.Response('Internal Server Error', 500),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            weatherService: fakeWeatherService(),
            jsessionId: 'JSESSION123',
            wmonid: 'WMONID123',
            userId2: 'REAL_USER_UID',
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

    // 하단 탭 바의 MY 탭을 눌러 메뉴를 띄우고 "내 정보"를 눌러 다이얼로그를 연다.
    // [settleAfterOpen]은 기본 true. 로딩 중(스피너가 떠 있는) 상태를
    // 검증하는 테스트에서는 false로 넘겨야 한다 — CircularProgressIndicator는
    // 계속 애니메이션 프레임을 요청해서 pumpAndSettle이 끝나지 않는다.
    Future<void> openMyInfoDialog(
      WidgetTester tester, {
      bool settleAfterOpen = true,
    }) async {
      await tester.tap(find.text('MY'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('내 정보'));
      if (settleAfterOpen) {
        await tester.pumpAndSettle();
      } else {
        // 메뉴 칸이 눌린 모습을 잠깐 보여준 뒤 닫히므로(0.12초), 그만큼 시간을
        // 흘려보낸 다음 다이얼로그가 막 열린 프레임을 본다.
        await tester.pump(const Duration(milliseconds: 150));
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
            cafeteriaMenuService: FakeCafeteriaMenuService(),
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

  testWidgets('종 아이콘 점은 새 공지가 있을 때만 켜지고, 공지사항을 열면 꺼진다', (tester) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final notices = _FakeNotices();
    final watcher = NoticeWatcher(
      service: notices,
      prefs: SharedPreferencesAsync(),
      alert: ({required id, required title, required body}) async {},
    );
    bool bellDot() => tester
        .widget<HomeTopIconButton>(
          find.byWidgetPredicate(
            (w) => w is HomeTopIconButton && w.icon == Icons.notifications_none,
          ),
        )
        .dot;

    await watcher.check(); // 처음 기록: 지금 공지는 모두 본 것
    notices.items = [_notice('새 학사공지'), ...notices.items];

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          weatherService: WeatherService(
            client: MockClient((_) async => http.Response(_fixtureJson, 200)),
          ),
          noticeWatcher: watcher,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(bellDot(), isTrue);

    // 공지사항 화면 안의 목록 조회는 이 테스트의 관심사가 아니라, 화면 전환만
    // 짧게 기다린다(실제 서버를 기다리지 않도록).
    await tester.tap(find.byIcon(Icons.notifications_none));
    await tester.pump(const Duration(milliseconds: 500));
    expect(bellDot(), isFalse);
    expect(await watcher.hasPending(), isFalse);
  });
}

NoticeItem _notice(String title) => NoticeItem(
  title: title,
  author: '학사팀',
  date: '2026.10.31',
  viewCount: 0,
  tag: NoticeTag.academic,
);

class _FakeNotices implements NoticeServiceBase {
  List<NoticeItem> items = [_notice('기존 공지')];

  @override
  Future<List<NoticeItem>> fetchNotices(
    NoticeBoard board, {
    bool forceRefresh = false,
  }) async => board == NoticeBoard.academic ? items : const [];

  @override
  Future<NoticeDetail> fetchDetail(String detailPath) =>
      throw UnimplementedError();
}
