/// 식당 종류 — 화면 위쪽 탭(전체 다음의 학생식당/교직원식당/카페).
///
/// 학교 서버는 식당을 구분해 주지 않고 카페 메뉴도 주지 않아, 실제 데이터는
/// 모두 학생식당으로 들어온다. 교직원식당·카페 탭은 데이터가 없으면 비어 있다.
enum CafeteriaVenue {
  student('학생식당'),
  staff('교직원식당'),
  cafe('카페');

  const CafeteriaVenue(this.label);

  final String label;
}

/// 하루의 끼니 — 아침/점심/저녁.
enum CafeteriaMeal {
  breakfast('아침'),
  lunch('점심'),
  dinner('저녁');

  const CafeteriaMeal(this.label);

  final String label;
}

/// 학식 메뉴 한 건 — 식당/코너 이름 + 메뉴 구성 + 가격.
class CafeteriaMenuItem {
  const CafeteriaMenuItem({
    required this.restaurant,
    required this.dishes,
    required this.price,
    this.venue = CafeteriaVenue.student,
    this.category,
  });

  /// 식당/코너 이름 (예: "데일리밥").
  final String restaurant;

  /// 메뉴 구성. 첫 두 개가 대표 메뉴(큰 글씨), 나머지는 곁들임으로 보여준다.
  final List<String> dishes;

  /// 원 단위 가격. 서버 응답에 가격이 없으면 null.
  final int? price;

  /// 어느 식당(탭)의 메뉴인지.
  final CafeteriaVenue venue;

  /// "한식", "일품" 같은 분류 칩(없으면 칩을 그리지 않는다).
  final String? category;

  String get dishesText => dishes.join(' · ');

  String get priceText => price == null ? '가격 정보 없음' : '${_formatWon(price!)}원';
}

/// 1000 단위마다 쉼표를 넣는다 (예: 4300 -> "4,300").
String _formatWon(int price) {
  final digits = price.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i != 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// 하루치 학식 메뉴 — 아침/점심/저녁 각각 메뉴 리스트(비어있을 수 있음).
class DailyCafeteriaMenu {
  const DailyCafeteriaMenu({
    this.breakfast = const [],
    this.lunch = const [],
    this.dinner = const [],
  });

  final List<CafeteriaMenuItem> breakfast;
  final List<CafeteriaMenuItem> lunch;
  final List<CafeteriaMenuItem> dinner;

  List<CafeteriaMenuItem> itemsFor(CafeteriaMeal meal) => switch (meal) {
    CafeteriaMeal.breakfast => breakfast,
    CafeteriaMeal.lunch => lunch,
    CafeteriaMeal.dinner => dinner,
  };

  /// 세 끼 전부 메뉴가 없으면(= 이 날은 학식 정보가 등록되지 않음) true.
  bool get isEmpty => breakfast.isEmpty && lunch.isEmpty && dinner.isEmpty;
}
