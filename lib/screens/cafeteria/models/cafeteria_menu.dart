/// 학식 메뉴 한 건 — 식당/코너 이름 + 메뉴 구성 + 가격.
class CafeteriaMenuItem {
  const CafeteriaMenuItem({
    required this.restaurant,
    required this.dishes,
    required this.price,
  });

  /// 식당/코너 이름 (예: "데일리밥").
  final String restaurant;

  /// 메뉴 구성. 화면에서는 " · "로 이어붙여 보여준다.
  final List<String> dishes;

  /// 원 단위 가격.
  final int price;

  String get dishesText => dishes.join(' · ');

  String get priceText => '${_formatWon(price)}원';
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

  /// 세 끼 전부 메뉴가 없으면(= 이 날은 학식 정보가 등록되지 않음) true.
  bool get isEmpty => breakfast.isEmpty && lunch.isEmpty && dinner.isEmpty;
}
