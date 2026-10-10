import 'dart:async';

import '../student_id_service.dart';

/// 실제 학번 찾기 API(`idSearch.do`)를 호출하지 않고 항상 같은 학번을
/// 찾은 것으로 처리하는 가짜 서비스. `kUseMockApi`가 true인 동안만 쓰인다.
class FakeStudentIdService extends StudentIdService {
  @override
  Future<StudentIdSearchResult> findStudentId({
    required String name,
    required String birthday6,
    required String mobile1,
    required String mobile2,
    required String mobile3,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const StudentIdFound('20211476');
  }
}
