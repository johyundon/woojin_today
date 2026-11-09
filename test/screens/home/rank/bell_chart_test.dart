// 학과 점수 분포 그래프: 양옆이 대칭인 종 모양, "나"는 등수로 위치를 정한다.

import 'package:daejin_app/screens/home/rank/widgets/rank_hero_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('막대 높이는 가운데가 가장 높고 양옆이 대칭이다', () {
    final h = bellHeights(20);
    expect(h, hasLength(20));
    for (var i = 0; i < 10; i++) {
      expect(h[i], closeTo(h[19 - i], 1e-9));
      if (i > 0) expect(h[i], greaterThan(h[i - 1]));
    }
  });

  test('1등은 맨 오른쪽, 꼴등은 맨 왼쪽, 중간 등수는 가운데 칸', () {
    expect(myBellBin(1, 70, 20), 19);
    expect(myBellBin(70, 70, 20), 0);
    expect(myBellBin(35, 70, 20), anyOf(9, 10));
    expect(myBellBin(12, 84, 20), greaterThan(10));
  });
}
