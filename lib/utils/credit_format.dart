/// 학점(credit) 숫자를 표시용 문자열로 변환한다.
/// 정수 학점(예: 3.0)은 소수점 없이 "3"으로, 그 외(예: 1.5)는 그대로 "1.5"로 표시한다.
String formatCredit(double credit) {
  return credit == credit.roundToDouble()
      ? credit.toInt().toString()
      : credit.toString();
}
