import 'package:flutter/material.dart';

import '../models/mileage_models.dart';

/// "모은 마일리지" 화면 목데이터.
///
/// 마일리지 화면은 이제 실제 서버(`MileageService`)의 점수·지급 내역을 쓴다.
/// 이 목데이터는 화면에서 숨긴 값(다음 등급·진행 바, 장학 기준 점수)의 자리로
/// 남겨 두었다. 학교 API에는 등급·장학 기준 점수가 없다.
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
