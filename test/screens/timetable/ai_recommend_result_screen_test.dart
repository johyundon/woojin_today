// AiRecommendResultScreen이 후보 그리드를 레이아웃 오버플로우 없이 그리는지,
// 스와이프/다시 추천/이 시간표 할래요가 콜백으로 올바르게 위임되는지,
// 설문 답변이 조건 요약 칩/공강 요일 강조로 제대로 반영되는지 확인한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/screens/timetable/ai_recommend/ai_recommend_result_screen.dart';
import 'package:daejin_app/screens/timetable/models/ai_recommend_answers.dart';
import 'package:daejin_app/screens/timetable/models/planned_course.dart';
import 'package:daejin_app/services/class_schedule_parser.dart';

PlannedCourse _course({
  required String courseCode,
  required String courseName,
  required String rawSchedule,
  double credit = 3,
}) {
  return PlannedCourse(
    courseCode: courseCode,
    section: '01',
    courseName: courseName,
    courseType: '전공선택',
    credit: credit,
    targetGrade: '3',
    professor: '홍길동',
    rawSchedule: rawSchedule,
    room: '1호관 101',
    enrollmentRatio: '10/30',
  );
}

final _candidateA = [
  _course(courseCode: 'A101', courseName: '자료구조', rawSchedule: '월09:00-10:30'),
  _course(courseCode: 'A102', courseName: '운영체제', rawSchedule: '화13:00-14:30'),
];

final _candidateB = [
  _course(courseCode: 'B201', courseName: '데이터베이스', rawSchedule: '수09:00-11:30'),
];

void main() {
  testWidgets('후보 목록을 오버플로우 없이 그린다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AiRecommendResultScreen(
          candidates: [_candidateA, _candidateB],
          answers: AiRecommendAnswers(),
          onRegenerate: () async => [_candidateA, _candidateB],
          onConfirm: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('다시 추천'), findsOneWidget);
    expect(find.text('총 6학점 · 2과목'), findsOneWidget);
  });

  testWidgets('"이 시간표 할래요"는 현재 페이지의 후보를 넘긴다', (tester) async {
    List<PlannedCourse>? confirmed;

    await tester.pumpWidget(
      MaterialApp(
        home: AiRecommendResultScreen(
          candidates: [_candidateA, _candidateB],
          answers: AiRecommendAnswers(),
          onRegenerate: () async => [_candidateA, _candidateB],
          onConfirm: (chosen) => confirmed = chosen,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('이 시간표 할래요'));
    await tester.pump();

    expect(confirmed, _candidateA);
  });

  testWidgets('"다시 추천"을 누르면 onRegenerate 결과로 교체한다', (tester) async {
    var regenerateCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: AiRecommendResultScreen(
          candidates: [_candidateA],
          answers: AiRecommendAnswers(),
          onRegenerate: () async {
            regenerateCalls++;
            return [_candidateB, _candidateB];
          },
          onConfirm: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('다시 추천'), findsOneWidget);

    await tester.tap(find.text('다시 추천'));
    await tester.pumpAndSettle();

    expect(regenerateCalls, 1);
    expect(find.text('다시 추천'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('후보가 비어있으면 빈 상태 문구를 보여준다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AiRecommendResultScreen(
          candidates: const [],
          answers: AiRecommendAnswers(),
          onRegenerate: () async => const [],
          onConfirm: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('조건에 맞는 시간표를 찾지 못했어요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('공강 요일/시간 선호/전공 비율 답변이 조건 요약 칩으로 보인다', (tester) async {
    final answers = AiRecommendAnswers()
      ..freeDayMode = FreeDayMode.specificDay
      ..specificFreeDay = Weekday.fri
      ..timePreference = TimePreference.afternoon
      ..majorRatioAny = false
      ..majorRatio = 100;

    await tester.pumpWidget(
      MaterialApp(
        home: AiRecommendResultScreen(
          candidates: [_candidateA],
          answers: answers,
          onRegenerate: () async => [_candidateA],
          onConfirm: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('금요일 공강'), findsOneWidget);
    expect(find.text('오후 위주'), findsOneWidget);
    expect(find.text('전공 100%'), findsOneWidget);
    expect(find.text('공강'), findsOneWidget); // 그리드 "금" 칼럼 아래 강조 라벨
  });

  testWidgets('공강 요일을 상관없어요로 답하면 요일 조건 칩이 없다', (tester) async {
    final answers = AiRecommendAnswers()..freeDayMode = FreeDayMode.any;

    await tester.pumpWidget(
      MaterialApp(
        home: AiRecommendResultScreen(
          candidates: [_candidateA],
          answers: answers,
          onRegenerate: () async => [_candidateA],
          onConfirm: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('공강'), findsNothing);
  });
}
