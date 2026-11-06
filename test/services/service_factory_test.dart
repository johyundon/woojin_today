// 개설과목 조회가 가짜 데이터가 아니라 실제 학교 서버 서비스를 쓰는지 확인한다.

import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/services/course_catalog_service.dart';
import 'package:daejin_app/services/service_factory.dart';

void main() {
  test('개설과목 조회는 실제 서버 서비스를 쓴다', () {
    expect(ServiceFactory.courseCatalog(), isA<CourseCatalogService>());
  });
}
