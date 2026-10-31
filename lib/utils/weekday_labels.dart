// 요일 한 글자 라벨(월/화/수/목/금/토/일) 상수. 화면마다 index 기준이 달라서
// 섞어 쓰면 안 되니, 아래 구분대로 맞는 것만 가져다 쓸 것.

/// 월요일부터 시작하는 7일(index 0=월 ~ 6=일). `DateTime.weekday`(월=1~일=7)를
/// 쓸 때는 `weekdayLabelsMonFirst[date.weekday - 1]`로 매핑한다.
const List<String> weekdayLabelsMonFirst = ['월', '화', '수', '목', '금', '토', '일'];

/// 일요일부터 시작하는 7일(index 0=일 ~ 6=토). `DateTime.weekday`(월=1~일=7)를
/// 쓸 때는 `weekdayLabelsSunFirst[date.weekday % 7]`로 매핑한다.
const List<String> weekdayLabelsSunFirst = ['일', '월', '화', '수', '목', '금', '토'];

/// 월~금 평일 5일만(index 0=월 ~ 4=금). 시간표/학식처럼 주말이 없는 화면에서
/// 쓴다.
const List<String> weekdayLabelsWeekdaysOnly = ['월', '화', '수', '목', '금'];
