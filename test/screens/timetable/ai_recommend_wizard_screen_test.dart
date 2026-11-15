// AiRecommendWizardScreen이 5단계를 전부 렌더/전환할 때 레이아웃 오버플로우
// 같은 런타임 예외 없이 동작하는지, 마지막 단계에서 onSubmit이 입력한
// 답변을 그대로 넘기는지 확인한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/screens/timetable/ai_recommend/ai_recommend_wizard_screen.dart';
import 'package:daejin_app/screens/timetable/models/ai_recommend_answers.dart';

void main() {
  testWidgets('5단계를 전부 다음으로 넘기면 onSubmit이 호출된다', (tester) async {
    AiRecommendAnswers? submitted;

    await tester.pumpWidget(
      MaterialApp(
        home: AiRecommendWizardScreen(
          onSubmit: (context, answers) async {
            submitted = answers;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // 1/5 → 2/5
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('공강은 언제로\n할까요?'), findsOneWidget);

    // 2/5에서 "금" 선택 후 → 3/5
    await tester.tap(find.text('금'));
    await tester.pump();
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('오전 수업, 오후 수업 중\n언제가 좋으세요?'), findsOneWidget);

    // 3/5에서 "오후 수업이 좋아요" 선택 후 → 4/5
    await tester.tap(find.text('오후 수업이 좋아요'));
    await tester.pump();
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('전공과 교양 비율을\n정해주세요'), findsOneWidget);

    // 4/5 → 5/5
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('추가로 원하는\n옵션이 있나요?'), findsOneWidget);

    // 5/5에서 제출.
    await tester.tap(find.text('시간표 만들기'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(submitted, isNotNull);
    expect(submitted!.freeDayMode, FreeDayMode.specificDay);
    expect(submitted!.specificFreeDay, isNotNull);
    expect(submitted!.timePreference, TimePreference.afternoon);
  });

  testWidgets('X를 누르면 화면이 닫힌다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        AiRecommendWizardScreen(onSubmit: (_, _) async {}),
                  ),
                ),
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.text('이번학기 몇학점\n들으실건가요?'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('이번학기 몇학점\n들으실건가요?'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('1/5 학점 슬라이더는 1학점 단위로 멈추지만 트랙에 눈금 점은 없다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AiRecommendWizardScreen(onSubmit: (context, answers) async {}),
      ),
    );
    await tester.pumpAndSettle();

    final slider = find.byType(Slider).first;
    expect(tester.widget<Slider>(slider).divisions, 17); // 5~22학점, 1학점 단위
    final theme = SliderTheme.of(tester.element(slider));
    expect(theme.tickMarkShape, SliderTickMarkShape.noTickMark);
  });

  group('4/5 전공·교양 비율은 학년에 따라 보이는 게 다르다', () {
    Future<void> goToRatioStep(WidgetTester tester, {int? grade}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AiRecommendWizardScreen(
            onSubmit: (_, _) async {},
            loadMyGrade: grade == null ? null : () async => grade,
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('다음'));
        await tester.pumpAndSettle();
      }
      expect(find.text('전공과 교양 비율을\n정해주세요'), findsOneWidget);
    }

    final secondMajorSwitch = find.byKey(
      const ValueKey('ai-second-major-switch'),
    );

    testWidgets('1학년이면 전공·교양 비율만 보인다', (tester) async {
      await goToRatioStep(tester, grade: 1);
      expect(find.text('교양 0%'), findsOneWidget);
      expect(secondMajorSwitch, findsNothing);
      expect(find.textContaining('타전공'), findsNothing);
      expect(find.textContaining('주전공'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('학년을 모르면 1학년처럼 보인다', (tester) async {
      await goToRatioStep(tester);
      expect(secondMajorSwitch, findsNothing);
    });

    testWidgets('2학년 이상이면 복수전공 스위치가 있고, 켜면 학과 고르기가 나온다', (tester) async {
      await goToRatioStep(tester, grade: 2);
      expect(secondMajorSwitch, findsOneWidget);
      expect(find.text('복수전공을 하고 있어요'), findsOneWidget);
      expect(find.text('학과 고르기'), findsNothing);

      await tester.tap(secondMajorSwitch);
      await tester.pumpAndSettle();
      expect(find.text('학과 고르기'), findsOneWidget);

      await tester.tap(secondMajorSwitch);
      await tester.pumpAndSettle();
      expect(find.text('학과 고르기'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
