import 'dart:async';

import '../student_info_service.dart';

/// 실제 지도교수/학생 정보 조회 API(`Bshr020101.jsp`)를 호출하지 않고 가짜
/// 학생 정보를 돌려주는 서비스. `kUseMockApi`가 true인 동안만 쓰인다.
class FakeStudentInfoService extends StudentInfoService {
  @override
  Future<StudentInfoResponse> fetchStudentInfo({
    required String userId2,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const StudentInfoResponse(
      advisorName: '김민준',
      name: '홍길동',
      department: '컴퓨터공학과',
      grade: '3학년',
    );
  }
}
