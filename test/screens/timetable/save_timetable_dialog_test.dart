// 시간표 저장 창: 이름은 선택이고, 비워 두면 기존 저장분과 겹치지 않는
// "시간표N"으로 저장한다.

import 'package:daejin_app/screens/timetable/widgets/save_timetable_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 저장 창을 띄우고, 닫힐 때 돌려준 값을 [onResult]로 넘긴다.
Future<void> _open(
  WidgetTester tester, {
  required String defaultName,
  required ValueChanged<String?> onResult,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => onResult(
            await showDialog<String>(
              context: context,
              builder: (_) => SaveTimetableDialog(defaultName: defaultName),
            ),
          ),
          child: const Text('열기'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
}

void main() {
  group('nextDefaultTimetableName', () {
    test('저장된 게 없으면 시간표1', () {
      expect(nextDefaultTimetableName(const []), '시간표1');
    });

    test('겹치지 않는 가장 작은 번호를 쓴다', () {
      expect(nextDefaultTimetableName(['시간표1', '시간표2']), '시간표3');
      expect(nextDefaultTimetableName(['시간표1', '시간표3']), '시간표2');
      expect(nextDefaultTimetableName(['1학기 계획', '시간표1']), '시간표2');
    });
  });

  test('번호에 맞는 조사를 붙인다', () {
    expect(directionParticle('시간표1'), '로');
    expect(directionParticle('시간표2'), '로');
    expect(directionParticle('시간표3'), '으로');
    expect(directionParticle('시간표10'), '으로');
  });

  testWidgets('이름이 선택임을 보여주고, 비워 두고 확인하면 기본 이름으로 저장한다', (tester) async {
    String? result = 'unset';
    await _open(tester, defaultName: '시간표3', onResult: (r) => result = r);

    expect(find.text('이름 (선택)'), findsOneWidget);
    expect(find.text("비워 두면 '시간표3'으로 저장돼요"), findsOneWidget);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(result, '시간표3');
  });

  testWidgets('이름을 입력하면 그 이름으로 저장한다(앞뒤 공백 제거)', (tester) async {
    String? result;
    await _open(tester, defaultName: '시간표1', onResult: (r) => result = r);

    await tester.enterText(find.byType(TextField), '  2학기 계획  ');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(result, '2학기 계획');
  });

  testWidgets('취소하면 저장하지 않는다', (tester) async {
    String? result = 'unset';
    await _open(tester, defaultName: '시간표1', onResult: (r) => result = r);

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });
}
