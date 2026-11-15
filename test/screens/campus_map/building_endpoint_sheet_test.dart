// 건물을 고르면 뜨는 아래 시트가 건물 이름과 출발·도착·닫기를 알려 주는지 확인한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/screens/campus_map/widgets/building_endpoint_sheet.dart';

void main() {
  testWidgets('건물 이름이 보이고 출발·도착·닫기를 누르면 알려 준다', (tester) async {
    final taps = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BuildingEndpointSheet(
            buildingName: '인문관',
            onClose: () => taps.add('close'),
            onSetOrigin: () => taps.add('origin'),
            onSetDestination: () => taps.add('destination'),
          ),
        ),
      ),
    );

    expect(find.text('인문관'), findsOneWidget);

    await tester.tap(find.text('출발'));
    await tester.tap(find.text('도착'));
    await tester.tap(find.bySemanticsLabel('닫기'));
    await tester.pumpAndSettle();
    expect(taps, ['origin', 'destination', 'close']);
  });

  testWidgets('길안내 시트: 도착 전엔 걸어서 문구 없고 길 안내가 눌리지 않는다', (tester) async {
    final taps = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RouteSummarySheet(
            title: '중앙도서관',
            onClose: () => taps.add('close'),
            onReset: () => taps.add('reset'),
            onStart: null,
          ),
        ),
      ),
    );

    expect(find.textContaining('걸어서'), findsNothing);
    await tester.tap(find.text('길 안내'));
    await tester.tap(find.text('초기화'));
    await tester.pumpAndSettle();
    expect(taps, ['reset']);
  });

  testWidgets('길안내 시트: 도착까지 있으면 걸어서 N분 · Nm와 길 안내', (tester) async {
    final taps = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RouteSummarySheet(
            title: '인문학관',
            walkMinutes: 6,
            distanceMeters: 420.4,
            onClose: () {},
            onReset: () {},
            onStart: () => taps.add('start'),
          ),
        ),
      ),
    );

    expect(find.text('걸어서 6분 · 420m'), findsOneWidget);
    await tester.tap(find.text('길 안내'));
    await tester.pumpAndSettle();
    expect(taps, ['start']);
  });
}
