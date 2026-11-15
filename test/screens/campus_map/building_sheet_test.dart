// 지도 아래쪽 건물 시트가 값이 있을 때만 걷는 거리·배지·안내 문구를 그리는지 확인한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/screens/campus_map/widgets/building_sheet.dart';

Widget _sheet({
  int? walkMinutes,
  double? distanceMeters,
  String? badge,
  String? note,
  VoidCallback? onDirections,
}) => MaterialApp(
  home: Scaffold(
    body: BuildingSheet(
      buildingName: '인문학관',
      walkMinutes: walkMinutes,
      distanceMeters: distanceMeters,
      badge: badge,
      note: note,
      onFloorGuide: () {},
      onDirections: onDirections ?? () {},
    ),
  ),
);

void main() {
  testWidgets('값이 없으면 건물 이름과 버튼만 보인다', (tester) async {
    await tester.pumpWidget(_sheet());

    expect(find.text('인문학관'), findsOneWidget);
    expect(find.text('층별 안내'), findsOneWidget);
    expect(find.text('길 알려줘'), findsOneWidget);
    expect(find.textContaining('걸어서'), findsNothing);
    expect(find.byType(Divider), findsNothing);
  });

  testWidgets('걷는 시간·거리, 배지, 안내 문구가 있으면 보인다', (tester) async {
    await tester.pumpWidget(
      _sheet(
        walkMinutes: 6,
        distanceMeters: 419.6,
        badge: '오늘 수업 2개',
        note: '3층 엘베 내려서 오른쪽 끝',
      ),
    );

    expect(find.text('걸어서 6분 · 420m'), findsOneWidget);
    expect(find.text('오늘 수업 2개'), findsOneWidget);
    expect(find.text('3층 엘베 내려서 오른쪽 끝'), findsOneWidget);
  });

  testWidgets('길 알려줘를 누르면 알려 준다', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_sheet(onDirections: () => taps++));

    await tester.tap(find.text('길 알려줘'));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });
}
