/// 자정(00:00)부터 [minutes]분 지난 시각을 "HH:MM" 형태로 변환한다.
/// 예: 90 -> "01:30".
String formatMinutesAsTime(int minutes) {
  final h = (minutes ~/ 60).toString().padLeft(2, '0');
  final m = (minutes % 60).toString().padLeft(2, '0');
  return '$h:$m';
}
