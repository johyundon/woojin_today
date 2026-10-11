import '../../../services/class_schedule_parser.dart';

/// 공강 요일을 고르는 방식 — Figma 2/5 화면의 세 가지 입력 모드.
enum FreeDayMode {
  /// 월~금 중 특정 요일 하나를 공강으로 지정.
  specificDay,

  /// "아무 요일이나 N일이면 돼요" — 요일은 안 가리고 개수만 지정.
  anyDaysCount,

  /// 상관없어요.
  any,
}

/// 3/5 화면의 오전/오후 선호.
enum TimePreference { morning, afternoon, mixed, any }

/// 5/5 화면의 추가 옵션.
enum ExtraOption { honeyLecturesPreferred, any }

/// AI 시간표 추천 5단계 설문 답변.
///
/// [majorSubRatio]는 어떤 과목이 "내 주전공"인지 "타전공"인지 구분할 데이터가
/// 앱에 없어 화면에만 보여주고 추천 로직에는 반영하지 않는다(값만 들고
/// 있다가, 나중에 그런 데이터가 생기면 연결할 수 있게). [extraOption]의
/// [ExtraOption.honeyLecturesPreferred]도 강의 평점/후기 데이터가 없어 같은
/// 이유로 로직에는 반영하지 않는다.
class AiRecommendAnswers {
  AiRecommendAnswers({
    this.credit = 15,
    this.freeDayMode = FreeDayMode.any,
    this.specificFreeDay,
    this.anyFreeDaysCount = 1,
    this.timePreference = TimePreference.any,
    this.majorRatio = 100,
    this.majorRatioAny = false,
    this.majorSubRatio = 60,
    this.extraOption = ExtraOption.any,
  });

  /// 5~22 범위(0.5학점 단위 없이 정수로 다룬다 — Figma 슬라이더가 정수 라벨만
  /// 보여줌).
  double credit;

  FreeDayMode freeDayMode;

  /// [freeDayMode]가 [FreeDayMode.specificDay]일 때만 쓰인다.
  Weekday? specificFreeDay;

  /// [freeDayMode]가 [FreeDayMode.anyDaysCount]일 때만 쓰인다(1~4일).
  int anyFreeDaysCount;

  TimePreference timePreference;

  /// 전공 비율(0~100). 교양 비율은 100 - majorRatio로 계산한다.
  /// [majorRatioAny]가 true면 이 값은 무시한다.
  double majorRatio;

  /// 4/5 화면의 "상관없어요" — true면 [majorRatio]/[majorSubRatio] 둘 다
  /// 추천 로직에서 무시한다.
  bool majorRatioAny;

  /// 전공 비중 중 주전공 비율(0~100, 타전공은 100 - majorSubRatio) — UI
  /// 전용, 추천 로직 미반영.
  double majorSubRatio;

  ExtraOption extraOption;
}
