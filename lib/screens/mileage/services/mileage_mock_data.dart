import 'package:flutter/material.dart';

import '../models/mileage_models.dart';

/// "모은 마일리지" 화면 목데이터.
///
/// *** 중요: 서버 API 없음 ***
/// API 명세서(daejin-api-spec-reference)에 마일리지 조회에 대응하는
/// 엔드포인트가 없다. 그래서 이 기능은 전부 하드코딩된 목데이터로만 동작한다
/// — 추측으로 서버 API를 만들어 호출하지 않는다. 나중에 실제 API가 생기면
/// 이 파일만 교체하면 된다.
class MileageMockData {
  MileageMockData._();

  static const int totalPoints = 1240;

  /// 다음 등급 이름과 그 등급에 필요한 누적 포인트.
  static const String nextTierName = '실버';
  static const int nextTierPoints = 1500;

  /// 이번 학기에 적립한 포인트.
  static const int termPoints = 620;

  /// 마일리지 장학 기준 포인트.
  static const int scholarshipPoints = 2000;

  static const List<MileageActivity> activities = [
    MileageActivity(
      title: '신입생 멘토링 참여',
      date: '10.08',
      points: 200,
      icon: Icons.groups,
    ),
    MileageActivity(
      title: '진로 특강 출석',
      date: '10.02',
      points: 100,
      icon: Icons.mic,
    ),
    MileageActivity(
      title: '지도교수 상담 완료',
      date: '09.25',
      points: 150,
      icon: Icons.school,
    ),
  ];
}
