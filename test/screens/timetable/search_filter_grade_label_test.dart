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
}
