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
}
