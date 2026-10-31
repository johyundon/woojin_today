# API 명세 정리

노션 "Flutter 기록" 페이지의 `API 명세서` 표(34개)를 기능별로 정리한 문서입니다.

- 출처: https://app.notion.com/p/3ef3c48d630d80b29960faf81550df69
- 정리 시점: 2026-10-28
- 이 문서에 **없는 것**: 각 API의 요청 파라미터·응답 예시. 노션의 `Request/Response` 표(34개 행)에 따로 있고, 이 문서에는 옮기지 않았습니다.

## 1. 호스트별 구분

| 호스트                  | 용도                                           | 로그인 방식                                    |
| ----------------------- | ---------------------------------------------- | ---------------------------------------------- |
| `www.daejin.ac.kr`      | 포털 (로그인, 공지, 학사일정, 학식, 학번 찾기) | 일부만 로그인 필요                             |
| `dreams2.daejin.ac.kr`  | 수강·시간표·졸업학점·지도교수 이름             | 포털 로그인 후 얻은 쿠키                       |
| `together.daejin.ac.kr` | T-WIN (학과 순위, 마일리지, 지도교수 상담)     | `loginProc.do`로 별도 로그인 (JSESSIONID 쿠키) |
| `api.open-meteo.com`    | 날씨                                           | 불필요                                         |

## 2. 기능별 API

요청 타입 약어: **form** = `application/x-www-form-urlencoded; charset=UTF-8`, **multipart** = `multipart/form-data`, **없음** = 본문 없음.

### 2-1. 로그인 / 계정

| 기능                                 | 메서드 | 경로                                                           | 요청 타입  | 설명                                                                                                                   |
| ------------------------------------ | ------ | -------------------------------------------------------------- | ---------- | ---------------------------------------------------------------------------------------------------------------------- |
| 로그인 (userId)                      | POST   | `https://www.daejin.ac.kr/subLogin/daejin/login.do`            | form       | 리다이렉트 헤더에서 암호화된 userId를 조회. 비밀번호를 6개월 넘게 바꾸지 않은 경우 가능                                |
| 로그인 폴백 (비밀번호를 변경한 경우) | GET    | `https://dreams2.daejin.ac.kr/sugang/LinkPortal.jsp?dvd=P`     | 리다이렉트 | 헤더에서 암호화된 userId를 찾지 못하면 SSO 흐름을 타서 쿠키값을 가져옴. 6개월 안에 비밀번호를 바꾼 경우 추가 호출 필요 |
| 학번 찾기                            | POST   | `https://www.daejin.ac.kr/userInfoSearch/daejin/1/idSearch.do` | form       | 비로그인. 이름·생년월일·휴대폰번호로 학번 조회                                                                         |

### 2-2. 날씨 / 학식 / 학사일정

| 기능        | 메서드 | 경로                                                                                                                                                                                                                                                                                                                                                                                                                  | 요청 타입 | 설명                                                                                                        |
| ----------- | ------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ----------------------------------------------------------------------------------------------------------- |
| 대진대 날씨 | GET    | `https://api.open-meteo.com/v1/forecast?latitude=37.8708627&longitude=127.1568845&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m&hourly=temperature_2m,precipitation,precipitation_probability,weather_code&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max,weather_code&timezone=Asia/Seoul&forecast_days=7` | json      | 좌표 기반 일주일치 날씨                                                                                     |
| 오늘의 학식 | POST   | `https://www.daejin.ac.kr/diet/daejin/2/view.do`                                                                                                                                                                                                                                                                                                                                                                      | form      | 조회 대상 주의 월요일 날짜 기준 일주일치를 가져옴. 받아오면 캐시하므로 일주일이 지나기 전엔 재요청하지 않음 |
| 학사일정    | POST   | `https://www.daejin.ac.kr/schdulmanage/daejin/19/monthSchdul.do`                                                                                                                                                                                                                                                                                                                                                      | form      | 월별 학사일정                                                                                               |

### 2-3. 공지사항

| 기능                | 메서드 | 경로                                                    | 요청 타입 | 설명                                                                    |
| ------------------- | ------ | ------------------------------------------------------- | --------- | ----------------------------------------------------------------------- |
| 학사공지            | GET    | `https://www.daejin.ac.kr/daejin/1003/subview.do`       | 없음      | 학사공지 조회                                                           |
| 마일리지 공지       | GET    | `https://www.daejin.ac.kr/daejin/1002/subview.do?enc=…` | 없음      | 마일리지 관련 공지글 조회 (`enc` 값은 노션 원문 참고)                   |
| 종합강의시간표 공지 | GET    | `https://www.daejin.ac.kr/daejin/7482/subview.do?enc=…` | 없음      | 조회 전에 로그인을 한 번 하도록 설계돼 있음 (`enc` 값은 노션 원문 참고) |

### 2-4. 시간표

| 기능               | 메서드 | 경로                                                                                                     | 요청 타입 | 설명                                                                    |
| ------------------ | ------ | -------------------------------------------------------------------------------------------------------- | --------- | ----------------------------------------------------------------------- |
| 개설과목 조회      | GET    | `https://dreams2.daejin.ac.kr/sugang/center/ProLsnAply06.jsp`                                            | 없음      | 연도·학기별 개설 과목                                                   |
| 강의계획서 목록    | GET    | `https://dreams2.daejin.ac.kr/sugang/center/ProLsnAply06.jsp`                                            | 없음      | 강의계획서 목록                                                         |
| 강의계획서 상세    | GET    | `https://dreams2.daejin.ac.kr/sugang/center/Blsn020303.jsp?fhd_00=…&fhd_01=…&fhd_02=…&fhd_03=…&fhd_04=…` | 없음      | 목록 응답 HTML의 각 과목 `<a href="Blsn020303.jsp?…">` 링크로 상세 조회 |
| 내 시간표 불러오기 | POST   | `https://dreams2.daejin.ac.kr/sugang/center/BlsnTotalTimeTableLst.jsp`                                   | form      | 내 시간표를 불러와 로컬에서 과목마다 매칭                               |

- 개설과목·강의계획서 조회 시 학과는 `ic_kwa_1` 필드에 학과코드를 넣음 (4장 참고).

### 2-5. 학과 순위 (T-WIN)

| 기능                    | 메서드 | 경로                                                                    | 요청 타입 | 설명                                                                                         |
| ----------------------- | ------ | ----------------------------------------------------------------------- | --------- | -------------------------------------------------------------------------------------------- |
| 로그인                  | POST   | `https://together.daejin.ac.kr/login/a/n/loginProc.do`                  | form      | 로그인 요청 후 JSESSIONID를 쿠키로 가져옴                                                    |
| 평균성적 불러오기       | POST   | `https://together.daejin.ac.kr/myFuture/a/n/getResultDivInfoPage.do`    | form      | 응답이 페이지(HTML)라서 평균 성적만 추출. iOS는 정규식 파싱이 필요할 수 있음. 누적 평균 학점 |
| 같은 학과·학년 성적정보 | POST   | `https://together.daejin.ac.kr/myFuture/r/n/getGrStdCompareListAjax.do` | form      | 페이지네이션 있음                                                                            |

### 2-6. 마일리지 (T-WIN + 포털)

| 기능        | 메서드 | 경로                                                                               | 요청 타입 | 설명                                                                                                                                        |
| ----------- | ------ | ---------------------------------------------------------------------------------- | --------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| 로그인      | POST   | `https://together.daejin.ac.kr/login/a/n/loginProc.do`                             | form      | 내 마일리지 조회를 위해 T-WIN에 로그인                                                                                                      |
| 내 현황     | POST   | `https://together.daejin.ac.kr/myStatus/a/n/getMyStatusListAjax.do`                | form      | 내 점수, 전체순위, TOP 5                                                                                                                    |
| 지급내역    | POST   | `https://together.daejin.ac.kr/myStatus/a/n/getMileageStatusInfoAjax.do`           | form      | 페이지네이션 있음. 내 마일리지 지급 내역                                                                                                    |
| 공지글 조회 | GET    | `https://www.daejin.ac.kr/daejin/1002/subview.do?enc=…`                            | 없음      | 제목 필터를 통과한 것 중 상위 5개를 먼저 뽑고, 그 5개의 첨부파일 유무를 확인. `{detailPath}`는 이 응답 HTML에 포함돼 있음                   |
| 상세조회    | GET    | `https://www.daejin.ac.kr{detailPath}` (예: `/bbs/daejin/189/461951/artclView.do`) | 없음      | 응답을 웹뷰로 렌더링. 이 시점에 `{downloadUrl}`이 이미 만들어져 있어야 함                                                                   |
| 대상자 확인 | GET    | `https://www.daejin.ac.kr{downloadUrl}` (예: `/bbs/daejin/189/331328/download.do`) | 없음      | 상세조회 응답 HTML의 `<a class="file-download" href="...">`에서 downloadUrl을 파싱. `.xlsx`로 끝나지 않으면 버림. 응답은 xlsx 바이너리(zip) |

### 2-7. 지도교수 상담

| 기능                  | 메서드 | 경로                                                                    | 요청 타입  | 설명                                |
| --------------------- | ------ | ----------------------------------------------------------------------- | ---------- | ----------------------------------- |
| 로그인                | POST   | `https://together.daejin.ac.kr/login/a/n/loginProc.do`                  | form       | 상담 API 호출을 위해 T-WIN에 로그인 |
| 내 지도교수 이름      | GET    | `https://dreams2.daejin.ac.kr/sugang/center/Bshr020101.jsp`             | form(표기) | 나의 지도교수 이름 조회             |
| 상담 인정 현황        | POST   | `https://together.daejin.ac.kr/myStatus/a/n/getMyStatusListAjax.do`     | form       | 학기별·학년별 상담 인정 현황        |
| 상담 신청 이력        | POST   | `https://together.daejin.ac.kr/cnsHis/a/n/getCnsHisListAjax.do`         | form       | 페이지네이션 있음                   |
| 상세보기              | POST   | `https://together.daejin.ac.kr/cnsHis/a/n/getCnsDetailInfoPop.do`       | form       | 신청 이력의 신청 내용·답변 조회     |
| 상담교수 검색         | POST   | `https://together.daejin.ac.kr/careerCns/a/n/getProfSearchListPop.do`   | form       | 상담 교수 목록 검색                 |
| 방문상담 가능 시간대  | POST   | `https://together.daejin.ac.kr/cmm/fms/getCnsSchedulCalAjax.do`         | form       | 방문상담 선택 시 가능한 시간대      |
| 방문 상담 신청 제출   | POST   | `https://together.daejin.ac.kr/careerCns/w/n/getCnsOfflineApplyAjax.do` | multipart  | 방문 상담 신청                      |
| 온라인 상담 신청 제출 | POST   | `https://together.daejin.ac.kr/careerCns/w/n/getCnsOnlineApplyAjax.do`  | multipart  | 온라인 상담 신청                    |

### 2-8. 졸업학점

| 기능           | 메서드 | 경로                                                      | 요청 타입 | 설명                                                                                                          |
| -------------- | ------ | --------------------------------------------------------- | --------- | ------------------------------------------------------------------------------------------------------------- |
| 이수구분표 (1) | GET    | `https://dreams2.daejin.ac.kr/sugang/sugang_wlsn0555.jsp` | 없음      | `mrd_path`·`mrd_param`을 얻기 위한 호출. 응답에서 `openFile\("([^"]+)"\s*,\s*"([^"]+)"\)` 정규식으로 추출     |
| 이수구분표 (2) | POST   | `https://dreams2.daejin.ac.kr/ReportingServer/service`    | form      | (1)에서 얻은 값으로 실제 이수구분표 데이터 조회. 응답은 Crownix/InfoTalk 리포트 엔진의 MML(XML 비슷한 마크업) |

### 2-9. 연강 (캠퍼스 지도)

- 서버 API 없음. 카카오맵 SDK 사용.
- 건물 좌표·길 벡터 파일(`campus_paths.geojson`, `CampusBuildingCatalog.kt`)이 노션 페이지에 첨부돼 있음.

## 3. 구현 시 유의점

- T-WIN 로그인(`loginProc.do`)이 학과 순위·마일리지·상담에 각각 따로 적혀 있으나 같은 주소임. 세션 공유 가능 여부는 이 문서만으로는 알 수 없음(확인 필요).
- HTML을 받아 직접 파싱하는 API가 많음: 평균성적, 시간표/강의계획서, 마일리지 공지·상세, 이수구분표(1).
- 페이지네이션이 있는 API: 같은 학과·학년 성적정보, 마일리지 지급내역, 상담 신청 이력.
- 파일 업로드(multipart)는 상담 신청 제출 2개뿐이고 나머지는 form 또는 GET.
- (노션이 아닌 개발 중 확인한 내용) dreams2 엔드포인트는 인코딩이 제각각이라 EUC-KR로 일괄 가정하면 안 됨. 예: 내 시간표는 실제 UTF-8.

## 4. 학과코드

시간표(개설과목/강의계획서) 조회 시 `ic_kwa_1` 필드, 랭킹/마일리지 조회 시 `sustCd` 파라미터에 들어감.

| 코드   | 학과                   | 코드   | 학과                     |
| ------ | ---------------------- | ------ | ------------------------ |
| AA0002 | 대순종학과             | AA0293 | 시각디자인학과           |
| AA0035 | 사학과                 | AA0294 | 산업디자인학과           |
| AA0049 | 전기공학과             | AA0315 | 식품영양학과             |
| AA0055 | IT기계공학과           | AA0317 | 영화영상학과             |
| AA0058 | 화학공학과             | AA0318 | 연기예술학과             |
| AA0059 | 데이터경영산업공학과   | AA0326 | 문예콘텐츠창작학과       |
| AA0060 | 토목공학전공           | AA0364 | 스포츠건강과학과         |
| AA0071 | 건축공학과             | AA0469 | 간호학과                 |
| AA0072 | 건축공학전공           | AA0479 | 미국학전공               |
| AA0101 | 영어영문학과           | AA0480 | 국제지역학전공           |
| AA0116 | 신소재공학과           | AA0481 | 중국학전공               |
| AA0131 | 한국어문학과           | AA0488 | 의생명과학과             |
| AA0194 | 컴퓨터공학전공         | AA0489 | 에코응용화학전공         |
| AA0196 | 환경에너지공학전공     | AA0514 | 휴면케어평생교육학과(야) |
| AA0234 | 문헌정보학과           | AA0723 | 역사,문화콘텐츠학과      |
| AA0235 | 아동학과               | AA0726 | 전자공학과               |
| AA0239 | 공공인재법학과         | AA0769 | 현대미술전공             |
| AA0240 | 행정정보학과           | AA0770 | 만화게임그래픽전공       |
| AA0241 | 글로벌경제학과         | AA0773 | 스마트모빌리티전공       |
| AA0242 | 경영학과               | AA0813 | 실용음악학과             |
| AA0243 | 국제통상학과           | AA0816 | AI빅데이터전공           |
| AA0244 | 사회복지학과           | AA0819 | 스마트시티전공           |
| AA0245 | 미디어커뮤니케이션학과 | AA0827 | 사회복지상담학과(야)     |
| CC0871 | 한국학과               | AA0828 | 보건경영학과             |
| CC0872 | 국제경영학과           | AA0829 | 스마트융합보안학과       |
