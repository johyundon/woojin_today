// 실제 2026-2 개설과목(과목명은 가짜, 교수·강의실 없음)으로 자동 생성이
// 목표 학점을 채우고, 내 학과·학년을 반영하는지 확인한다. 예전 코드는 학교
// 이수구분("전선"·"전필")에 "전공" 글자가 없어 전공을 못 세서, 전공 비율을
// 50~100%로 고르면 항상 6학점만 담았다.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/screens/timetable/models/ai_recommend_answers.dart';
import 'package:daejin_app/screens/timetable/models/planned_course.dart';
import 'package:daejin_app/screens/timetable/services/ai_recommend_service.dart';
import 'package:daejin_app/services/class_schedule_parser.dart';
import 'package:daejin_app/services/course_catalog_service.dart';

final _json = jsonDecode(
  File('test/screens/timetable/fixtures/ai_catalog_2026_2.json')
      .readAsStringSync(),
) as Map<String, dynamic>;

CourseCatalogItem _item(dynamic r) => CourseCatalogItem(
  seq: 0,
  courseCode: r['courseCode'] as String,
  section: r['section'] as String,
  courseName: r['courseName'] as String,
  courseType: r['courseType'] as String,
  credit: (r['credit'] as num).toDouble(),
  targetGrade: r['targetGrade'] as String,
  professor: '',
  rawSchedule: r['rawSchedule'] as String,
  room: '',
  isClosed: r['isClosed'] as bool,
  capacity: (r['capacity'] as num).toInt(),
  waitlistCount: (r['enrolled'] as num).toInt(),
  enrollmentRatio: r['enrollmentRatio'] as String,
);

final _all = [for (final r in _json['all'] as List) _item(r)];

/// 학과별 조회(컴퓨터공학전공) 결과 = 내 학과 전공 과목코드.
final _myMajors = {
  for (final r in _json['dept'] as List) r['courseCode'] as String,
};

final _profile = AiRecommendProfile(myMajorCourseCodes: _myMajors, myGrade: 3);

/// 타전공 학과 대신 쓰는 다른 학과 전공 묶음(과목코드 앞자리 "86").
final _secondMajors = {
  for (final i in _all)
    if (isMajorCourseType(i.courseType) && i.courseCode.startsWith('86'))
      i.courseCode,
};

double _fill(PlannedCourse p) =>
    double.tryParse(p.enrollmentRatio.replaceAll('%', '')) ?? 0;

double _credit(List<PlannedCourse> c) => c.fold(0.0, (s, p) => s + p.credit);

double _majorCredit(List<PlannedCourse> c) => c
    .where((p) => isMajorCourseType(p.courseType))
    .fold(0.0, (s, p) => s + p.credit);

List<List<PlannedCourse>> _generate(
  AiRecommendAnswers answers, {
  AiRecommendProfile profile = const AiRecommendProfile(),
}) => generateTimetableCandidates(
  catalog: _all,
  answers: answers,
  profile: profile,
  random: Random(7),
);

void main() {
  test('학교 이수구분 줄임말(전선·전필·전기)을 전공으로 센다', () {
    expect(isMajorCourseType('전선'), isTrue);
    expect(isMajorCourseType('전필'), isTrue);
    expect(isMajorCourseType('전기'), isTrue);
    expect(isMajorCourseType('교선'), isFalse);
    expect(isMajorCourseType('교필'), isFalse);
    expect(isMajorCourseType('일선'), isFalse);
  });

  test('전공 100%여도 학과를 모를 때 목표 학점(15)을 채운다', () {
    for (final c in _generate(AiRecommendAnswers(majorRatio: 100))) {
      expect(_credit(c), greaterThanOrEqualTo(15));
      expect(_majorCredit(c), _credit(c));
    }
  });

  test('내 학과를 알면 다른 학과 전공은 담지 않는다', () {
    for (final ratio in [100.0, 60.0]) {
      final candidates = _generate(
        AiRecommendAnswers(majorRatio: ratio),
        profile: _profile,
      );
      for (final c in candidates) {
        expect(_credit(c), greaterThanOrEqualTo(15), reason: '전공 $ratio%');
        for (final p in c.where((p) => isMajorCourseType(p.courseType))) {
          expect(_myMajors, contains(p.courseCode));
        }
      }
    }
  });

  test('내 학년 전공을 우선해서 담는다', () {
    final candidates = _generate(
      AiRecommendAnswers(majorRatio: 100),
      profile: _profile,
    );
    for (final c in candidates) {
      final majors = c.where((p) => isMajorCourseType(p.courseType)).toList();
      final myGrade = majors.where((p) => p.targetGrade == '3').length;
      expect(myGrade * 2, greaterThanOrEqualTo(majors.length));
    }
  });

  test('전공 비율을 목표에 가깝게 맞춘다', () {
    for (final c in _generate(AiRecommendAnswers(majorRatio: 0))) {
      expect(_majorCredit(c), 0);
    }
    for (final c in _generate(
      AiRecommendAnswers(majorRatio: 60),
      profile: _profile,
    )) {
      final ratio = _majorCredit(c) / _credit(c) * 100;
      expect((ratio - 60).abs(), lessThanOrEqualTo(30));
    }
  });

  test('교직 과목은 담지 않는다', () {
    for (final c in _generate(AiRecommendAnswers(majorRatio: 0))) {
      expect(c.where((p) => p.courseType == '교직'), isEmpty);
    }
  });

  test('후보 3개는 서로 다른 조합이다', () {
    final keys = _generate(
      AiRecommendAnswers(majorRatio: 60),
      profile: _profile,
    ).map((c) => (c.map((p) => p.courseCode).toList()..sort()).join(','));
    expect(keys.toSet(), hasLength(3));
  });

  test('"적당히 섞어주세요"면 오전·오후 수업이 한쪽으로 쏠리지 않는다', () {
    final candidates = _generate(
      AiRecommendAnswers(majorRatio: 0, timePreference: TimePreference.mixed),
    );
    for (final c in candidates) {
      var morning = 0;
      var afternoon = 0;
      for (final p in c) {
        for (final s in parseRawSchedule(p.rawSchedule)) {
          s.startMinutes < 13 * 60 ? morning++ : afternoon++;
        }
      }
      expect((morning - afternoon).abs(), lessThanOrEqualTo(2));
    }
  });

  test('약 1,500과목에서도 한 번 만드는 데 1초 안에 끝난다', () {
    final sw = Stopwatch()..start();
    _generate(AiRecommendAnswers(majorRatio: 60));
    sw.stop();
    expect(sw.elapsedMilliseconds, lessThan(1000));
  });

  test('꿀강의를 고르면 담은 인원 비율이 높은 과목을 담는다', () {
    double avgFill(ExtraOption option) {
      final all = _generate(
        AiRecommendAnswers(majorRatio: 0, extraOption: option),
      ).expand((c) => c).toList();
      return all.fold(0.0, (s, p) => s + _fill(p)) / all.length;
    }

    final plain = avgFill(ExtraOption.any);
    final honey = avgFill(ExtraOption.honeyLecturesPreferred);
    expect(honey, greaterThan(plain + 20), reason: '보통 $plain% → 꿀강의 $honey%');
  });

  test('전공 100%에서도 꿀강의를 고르면 내 학과에서 경쟁률 높은 과목을 담는다', () {
    double avgFill(ExtraOption option) {
      final all = _generate(
        AiRecommendAnswers(majorRatio: 100, extraOption: option),
        profile: _profile,
      ).expand((c) => c).toList();
      return all.fold(0.0, (s, p) => s + _fill(p)) / all.length;
    }

    final plain = avgFill(ExtraOption.any);
    final honey = avgFill(ExtraOption.honeyLecturesPreferred);
    expect(honey, greaterThan(plain + 10), reason: '보통 $plain% → 꿀강의 $honey%');
    // 내 학과에서 경쟁률이 가장 높은 과목(128.1%)은 후보마다 들어간다.
    for (final c in _generate(
      AiRecommendAnswers(
        majorRatio: 100,
        extraOption: ExtraOption.honeyLecturesPreferred,
      ),
      profile: _profile,
    )) {
      expect(c.map(_fill), contains(128.1));
    }
  });

  test('타전공 학과를 고르면 주전공/타전공 비율을 맞춰 담는다', () {
    final profile = AiRecommendProfile(
      myMajorCourseCodes: _myMajors,
      secondMajorCourseCodes: _secondMajors,
      myGrade: 3,
    );
    final candidates = _generate(
      AiRecommendAnswers(majorRatio: 100, majorSubRatio: 50),
      profile: profile,
    );
    for (final c in candidates) {
      final mine = c.where((p) => _myMajors.contains(p.courseCode));
      final second = c.where((p) => _secondMajors.contains(p.courseCode));
      // 고른 두 학과 말고 다른 학과 전공은 없다.
      expect(mine.length + second.length, c.length);
      final mainShare =
          mine.fold(0.0, (s, p) => s + p.credit) / _credit(c) * 100;
      expect((mainShare - 50).abs(), lessThanOrEqualTo(30));
      expect(_credit(c), greaterThanOrEqualTo(15));
    }
  });

  test('타전공 학과를 안 고르면 다른 학과 전공은 담지 않는다', () {
    for (final c in _generate(
      AiRecommendAnswers(majorRatio: 100, majorSubRatio: 50),
      profile: _profile,
    )) {
      expect(c.where((p) => _secondMajors.contains(p.courseCode)), isEmpty);
    }
  });
}
