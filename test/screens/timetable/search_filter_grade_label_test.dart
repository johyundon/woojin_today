// 과목 검색 필터에서 학년이 "2"가 아니라 "2학년"으로 보이는지 확인한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/screens/timetable/course_filters.dart';
import 'package:daejin_app/screens/timetable/widgets/search_panel.dart';

Widget _bar(CourseFilters filters, {bool panelOpen = false}) => MaterialApp(
  home: Scaffold(
    body: SearchFilterBar(
      controller: TextEditingController(),
      onQueryChanged: (_) {},
      filters: filters,
      filterPanelOpen: panelOpen,
      onToggleFilterPanel: () {},
      onFiltersChanged: () {},
      availableGrades: const ['1', '2', '3'],
      availableCourseTypes: const [],
      availableCredits: const [],
      availableAreas: const [],
      pendingSlot: null,
      onClearPendingSlot: () {},
    ),
  ),
);

void main() {
  testWidgets('고른 학년 칩은 "2학년"으로 보인다', (tester) async {
    await tester.pumpWidget(_bar(CourseFilters(grade: '2')));
    expect(find.text('2학년'), findsWidgets);
    expect(find.text('2'), findsNothing);
  });

  testWidgets('필터를 펼쳐 두면 고른 값이 위 칩에만 한 번 보이고 아래 칩은 없다', (tester) async {
    await tester.pumpWidget(_bar(CourseFilters(grade: '2'), panelOpen: true));
    expect(find.text('2학년'), findsOneWidget);
  });

  testWidgets('필터를 접으면 무엇이 걸려 있는지 아래 칩으로 보인다', (tester) async {
    await tester.pumpWidget(_bar(CourseFilters(grade: '2')));
    expect(find.text('2학년'), findsOneWidget);
  });
}
