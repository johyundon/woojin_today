import '../models/cafeteria_menu.dart';

/// "오늘의 학식" 목데이터.
///
/// *** 중요: 서버 API 없음 ***
/// API 명세서(daejin-api-spec-reference)에 학생식당 메뉴 조회에 대응하는
/// 엔드포인트가 없다. 그래서 이 기능은 전부 하드코딩된 목데이터로만 동작한다
/// — 추측으로 서버 API를 만들어 호출하지 않는다. 화면은 [menuFor] 하나만
/// 호출하도록 분리해 둬서, 나중에 실제 API가 생기면 이 파일만 교체하면 된다.
class CafeteriaMenuMockData {
  CafeteriaMenuMockData._();

  /// [date]의 메뉴. 등록된 데이터가 없으면 null(= 이 날은 등록된 학식 정보가
  /// 없는 상태로 화면에 표시된다).
  static DailyCafeteriaMenu? menuFor(DateTime date) => _menus[_dateKey(date)];

  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static final Map<String, DailyCafeteriaMenu> _menus = _buildMenus();

  static Map<String, DailyCafeteriaMenu> _buildMenus() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dayAfterTomorrow = today.add(const Duration(days: 2));

    return {
      // 스크린샷(Figma node 6:71~6:74)에 실제로 보인 날짜 하나. "오늘"과 무관한
      // 스크린샷 당시의 고정된 날짜라 DateTime.now()에 얽매이지 않는 상수로
      // 둔다. 아래 메뉴 구성/가격은 스크린샷에서 그대로 읽은 값(지어낸 것 아님).
      _dateKey(DateTime(2026, 9, 10)): const DailyCafeteriaMenu(
        breakfast: [
          CafeteriaMenuItem(
            restaurant: '천원의밥상',
            dishes: ['쇠고기무국', '쌀밥', '두부양념조림', '느타리호박볶음', '배추김치', '바이오플레사과'],
            price: 1000,
          ),
        ],
        lunch: [
          CafeteriaMenuItem(
            restaurant: '데일리밥',
            dishes: ['나주곰탕', '비엔나볶음', '무말랭이무침', '쌀밥', '깍두기'],
            price: 4300,
          ),
          CafeteriaMenuItem(
            restaurant: '누들송',
            dishes: ['홍게살로제파스타', '소금버터롤', '오이피클'],
            price: 5200,
          ),
          CafeteriaMenuItem(
            restaurant: '크레이지팬',
            dishes: ['부타동', '카레사모사', '유부장국', '깍두기'],
            price: 5500,
          ),
          CafeteriaMenuItem(
            restaurant: '돈카츠락',
            dishes: ['왕등심돈까스', '쌀밥', '우동국', '샐러드', '단무지'],
            price: 5700,
          ),
        ],
        // 저녁은 스크린샷에 실제 데이터가 보이지 않아 빈 리스트로 둔다(지어내지
        // 않음).
      ),

      // 데모용 — 오늘/내일/모레는 앱을 바로 켰을 때도 빈 화면만 보이지 않게
      // 적당히 지어낸 한식/분식 메뉴(실제 학식 데이터 아님).
      _dateKey(today): const DailyCafeteriaMenu(
        breakfast: [
          CafeteriaMenuItem(
            restaurant: '천원의밥상',
            dishes: ['콩나물국', '쌀밥', '계란말이', '어묵볶음', '배추김치'],
            price: 1000,
            category: '한식',
          ),
        ],
        lunch: [
          CafeteriaMenuItem(
            restaurant: '데일리밥',
            dishes: ['제육볶음', '된장찌개', '잡곡밥', '콩나물무침', '깍두기'],
            price: 5000,
            category: '한식',
            popularRank: 1,
          ),
          CafeteriaMenuItem(
            restaurant: '일품',
            dishes: ['돈까스', '우동'],
            price: 5500,
            category: '일식',
          ),
          CafeteriaMenuItem(
            restaurant: '누들송',
            dishes: ['짜장면', '군만두', '단무지'],
            price: 4800,
            category: '중식',
          ),
          CafeteriaMenuItem(
            restaurant: '파스타랩',
            dishes: ['토마토크림파스타', '마늘빵'],
            price: 5400,
            category: '양식',
          ),
          CafeteriaMenuItem(
            restaurant: '분식당',
            dishes: ['떡볶이', '튀김모둠'],
            price: 4500,
            category: '분식',
          ),
          CafeteriaMenuItem(
            restaurant: '덮밥집',
            dishes: ['치킨마요덮밥', '미소된장국'],
            price: 5200,
            category: '일식',
          ),
          CafeteriaMenuItem(
            restaurant: '샐러드바',
            dishes: ['닭가슴살샐러드', '요거트'],
            price: 5000,
            category: '샐러드',
          ),
          CafeteriaMenuItem(
            restaurant: '교직원식당',
            dishes: ['소불고기', '미역국', '쌀밥', '시금치나물', '배추김치'],
            price: 6500,
            venue: CafeteriaVenue.staff,
            category: '한식',
          ),
          CafeteriaMenuItem(
            restaurant: '교직원 일품',
            dishes: ['연어덮밥', '유부장국'],
            price: 7000,
            venue: CafeteriaVenue.staff,
            category: '일식',
          ),
        ],
        dinner: [
          CafeteriaMenuItem(
            restaurant: '크레이지팬',
            dishes: ['치킨가라아게', '쌀밥', '미소장국', '샐러드'],
            price: 5300,
            category: '일식',
          ),
        ],
      ),
      _dateKey(tomorrow): const DailyCafeteriaMenu(
        lunch: [
          CafeteriaMenuItem(
            restaurant: '돈카츠락',
            dishes: ['치즈돈까스', '쌀밥', '우동국', '양배추샐러드'],
            price: 5700,
            category: '일식',
          ),
          CafeteriaMenuItem(
            restaurant: '데일리밥',
            dishes: ['닭갈비', '쌀밥', '된장국', '콩나물무침', '배추김치'],
            price: 4600,
            category: '한식',
          ),
        ],
      ),
      _dateKey(dayAfterTomorrow): const DailyCafeteriaMenu(
        lunch: [
          CafeteriaMenuItem(
            restaurant: '누들송',
            dishes: ['토마토크림파스타', '마늘바게트', '오이피클'],
            price: 5400,
            category: '양식',
          ),
        ],
      ),
    };
  }
}
