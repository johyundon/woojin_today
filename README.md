# daejin_app

대진대학교 학생을 위한 Flutter 앱. 포털/T-WIN 로그인부터 시간표, 학식,
캠퍼스 지도, 졸업학점, 파일공유까지 학교생활에 필요한 기능을 한 앱에
모았다.

## 주요 기능

- **로그인 / 학번 찾기** — 포털 계정으로 로그인, 학번을 모를 때 찾기
- **시간표** — 수강신청 시스템에서 개설과목을 조회해 담고, 연강 사이
  건물이 다르면 "이동하기" 칩으로 도보 이동 정보를 바로 보여준다
- **캠퍼스 지도(연강 이동)** — 카카오맵 위에서 출발지/목적지 건물을 골라
  도보 경로와 소요 시간을 확인
- **오늘의 학식** — 날짜별 학식 메뉴 조회
- **캘린더** — 학사일정 확인, 다중일자 일정과 로컬 알림
- **마일리지** — 비교과 마일리지 현황
- **지도교수 상담 신청** — 상담 신청 4단계 마법사
- **공지사항** — 장학 공지 등, 새 글 알림(로컬 푸시)
- **졸업학점** — 이수구분별 취득/필요 학점 확인
- **파일공유** — 기기 간 파일 보내기/받기, 같은 와이파이 사용자 탐색

## ⚠️ 서버 API 없음 (Mock 모드)

학교로부터 API 사용 관련 제재를 받은 뒤, `lib/config/mock_mode.dart`의
`kUseMockApi` 스위치로 학교 서버(포털/T-WIN) 호출을 전부 꺼두고
`lib/services/fakes/`의 가짜 데이터로 대체한 상태다. 로그인, 개설과목
조회, 내 시간표, 지도교수 정보, 학번 찾기 등 실제 서버 연동이 필요한
기능은 현재 전부 mock으로 동작한다. 실제 서버로 다시 연동하려면 이
값을 `false`로 바꾸면 된다.

반대로 캠퍼스 지도, 졸업학점, 파일공유처럼 애초에 학교 서버 API가 없는
기능들은 `*_mock_data.dart` 파일에 미리 정리해 둔 가짜 데이터를 쓴다.

## 시작하기

```bash
flutter pub get
```

### 카카오맵 키 설정 (캠퍼스 지도 화면에 필요)

1. [카카오 개발자 콘솔](https://developers.kakao.com)에서 애플리케이션을
   만들고 JavaScript 키를 발급받는다.
2. `lib/config/kakao_map_config.example.dart`를 같은 폴더에
   `kakao_map_config.dart`로 복사한다.
3. 그 안의 `kakaoMapJavaScriptKey` 값을 발급받은 키로 바꾼다.

`kakao_map_config.dart`는 `.gitignore`에 등록돼 있어 실제 키가 저장소에
올라가지 않는다.

### 실행

```bash
flutter run
```

### 테스트

```bash
flutter test
```

## 프로젝트 구조

```
lib/
  screens/        화면별 UI (advisor, cafeteria, calendar, campus_map,
                   collection_screen, fileshare, graduation, home,
                   mileage, notice, timetable 등)
  services/        네트워크 클라이언트 + fakes/ 안의 mock 구현
  config/          mock 모드 스위치, 카카오맵 키 설정
  theme/           앱 공통 색상 팔레트
test/
  screens/, services/   화면·서비스별 단위/위젯 테스트
```

새 네이티브 플러그인을 추가한 뒤에는 `flutter clean && flutter pub get`
후 `flutter run`으로 다시 실행해야 한다(hot reload/restart로는
플랫폼 채널이 재등록되지 않는다).
