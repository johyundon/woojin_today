// 홈 위쪽 검색·알림 버튼이 Figma v7(03 홈 Box) 값과 같은지 확인한다:
// 40×40, 모서리 12, 그림자 0·2·7, Figma에서 받은 19×19 아이콘, 알림 점 12×12.

import 'package:daejin_app/screens/home/widgets/home_top_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Figma 크기·그림자·아이콘·알림 점을 그대로 쓴다', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: HomeV7IconButton(
              asset: HomeV7IconButton.notificationsAsset,
              dot: true,
              onTap: () => taps++,
            ),
          ),
        ),
      ),
    );

    final box = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(HomeV7IconButton),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = box.decoration! as BoxDecoration;
    expect(tester.getSize(find.byWidget(box)), const Size(40, 40));
    expect(decoration.borderRadius, BorderRadius.circular(12));
    expect(decoration.boxShadow!.single.blurRadius, 7);
    expect(decoration.boxShadow!.single.offset, const Offset(0, 2));

    final icon = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect(icon.width, 19);
    expect(icon.height, 19);

    final dot = find.byWidgetPredicate(
      (w) =>
          w is Container &&
          (w.decoration as BoxDecoration?)?.border != null &&
          (w.decoration as BoxDecoration?)?.color == const Color(0xFFEE343B),
    );
    expect(tester.getSize(dot), const Size(12, 12));

    await tester.tap(find.byType(HomeV7IconButton));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('알림이 없으면 빨간 점이 없다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeV7IconButton(
          asset: HomeV7IconButton.searchAsset,
          onTap: () {},
        ),
      ),
    );
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Container &&
            (w.decoration as BoxDecoration?)?.color == const Color(0xFFEE343B),
      ),
      findsNothing,
    );
  });
}
