/// "명단 (800명)" 목데이터.
///
/// 마일리지 화면은 이제 실제 명단(xlsx)에서 내 학번이 있는지만 확인하고,
/// 다른 학생 학번 명단은 보여주지도 저장하지도 않는다. 이 목데이터와 명단
/// 다이얼로그는 목데이터용 대상자 다이얼로그에서만 쓰여 남겨 두었다.
class MileageRosterMockData {
  MileageRosterMockData._();

  /// 스크린샷(Figma node 6:109)에서 그대로 읽은 처음 27개 학번(순서 보존).
  /// 지어낸 값이 아니라 스크린샷에 실제로 보인 값이라, 목록 맨 앞에
  /// 정확히 이 순서로 둔다.
  static const List<String> _seedStudentIds = [
    '20181760',
    '20210665',
    '20211771',
    '20220694',
    '20221501',
    '20230271',
    '20230957',
    '20231576',
    '20240079',
    '20240656',
    '20241290',
    '20242427',
    '20250386',
    '20250846',
    '20251405',
    '20252064',
    '20260269',
    '20260613',
    '20260980',
    '20261411',
    '20191312',
    '20210727',
    '20211785',
    '20220699',
    '20221516',
    '20230273',
    '20230962',
  ];

  static const int totalCount = 800;

  /// 나머지는 스크린샷 학번 패턴("20{학번 연도 2자리}{4자리 일련번호}",
  /// 2018~2026학번)에 맞춰 총 [totalCount]개가 되도록 채워 넣은 값 —
  /// 실제 명단이 아니라 데모용으로 생성한 값이다.
  static final List<String> studentIds = _buildStudentIds();

  static List<String> _buildStudentIds() {
    final result = <String>[..._seedStudentIds];
    final seen = result.toSet();
    const years = [18, 19, 20, 21, 22, 23, 24, 25, 26];
    var serial = 1;
    var yearPos = 0;
    while (result.length < totalCount) {
      final year = years[yearPos % years.length];
      final id = '20$year${serial.toString().padLeft(4, '0')}';
      yearPos++;
      if (yearPos % years.length == 0) serial++;
      if (seen.add(id)) result.add(id);
    }
    return result;
  }
}
