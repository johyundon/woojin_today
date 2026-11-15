// "자주 찾는 메뉴" 고르기: 많이 연 기능이 앞, 횟수가 같으면 원래 순서, 기록이
// 없으면 기본 3개. 연 횟수는 휴대폰 저장소에 쌓인다.

import 'package:daejin_app/screens/search/feature_usage_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const candidates = ['시간표', '학식', '캘린더', '공지사항', '마일리지'];
  String self(String s) => s;

  test('기록이 없으면 앞의 3개(기본값)를 고른다', () {
    expect(pickFrequent(candidates, self, {}), ['시간표', '학식', '캘린더']);
  });

  test('많이 연 기능이 앞에 오고, 같은 횟수는 원래 순서를 따른다', () {
    final picked = pickFrequent(candidates, self, {'마일리지': 3, '공지사항': 1});
    expect(picked, ['마일리지', '공지사항', '시간표']);
  });

  test('record는 기능별 횟수를 1씩 올려 저장한다', () async {
    SharedPreferences.setMockInitialValues({});
    const store = FeatureUsageStore();
    await store.record('학식');
    await store.record('학식');
    await store.record('공지사항');
    expect(await store.load(), {'학식': 2, '공지사항': 1});
  });
}
