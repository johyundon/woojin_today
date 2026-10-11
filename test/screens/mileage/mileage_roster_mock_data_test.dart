// MileageRosterMockData가 800개 고유 학번을 만들고, 스크린샷에서 그대로 읽은
// 앞 27개 순서를 보존하는지 확인한다.

import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/screens/mileage/services/mileage_roster_mock_data.dart';

void main() {
  test('총 800개, 중복 없음', () {
    final ids = MileageRosterMockData.studentIds;
    expect(ids.length, 800);
    expect(ids.toSet().length, 800);
  });

  test('앞 27개는 스크린샷에서 읽은 값 그대로 순서 보존', () {
    const expectedSeed = [
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
    expect(MileageRosterMockData.studentIds.take(27).toList(), expectedSeed);
  });
}
