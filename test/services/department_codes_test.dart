// 학생 정보의 학과 이름을 학과 코드표 이름으로 맞추는 규칙을 확인한다.

import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/services/department_codes.dart';

void main() {
  test('글자가 같으면 그대로', () {
    expect(matchDepartmentName('컴퓨터공학전공'), '컴퓨터공학전공');
    expect(matchDepartmentName(' 경영학과 '), '경영학과');
  });

  test('끝말(학과/전공)만 다르면 코드표 이름으로 맞춘다', () {
    expect(matchDepartmentName('컴퓨터공학과'), '컴퓨터공학전공');
    expect(matchDepartmentName('미국학과'), '미국학전공');
  });

  test('뗀 이름이 같은 학과가 둘이면 고르지 않는다', () {
    // 코드표에 건축공학과와 건축공학전공이 둘 다 있다.
    expect(matchDepartmentName('건축공학'), isNull);
  });

  test('없거나 모르는 학과는 null', () {
    expect(matchDepartmentName(null), isNull);
    expect(matchDepartmentName(''), isNull);
    expect(matchDepartmentName('없는학과'), isNull);
  });
}
