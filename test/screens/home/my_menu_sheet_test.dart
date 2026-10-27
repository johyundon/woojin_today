// MY 탭 메뉴 시트의 글자가 앱 기본(다크) 테마의 흰색을 물려받아 흰 바탕에
// 묻히지 않고, 색이 명시돼 있는지 확인한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/screens/home/home_enums.dart';
import 'package:daejin_app/screens/home/widgets/my_menu_sheet.dart';
import 'package:daejin_app/theme/app_colors.dart';

void main() {
  testWidgets('다크 테마에서도 메뉴 글자가 흰색이 아니라 잉크색이다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: const Scaffold(
          backgroundColor: Colors.white,
          body: MyMenuSheet(),
        ),
      ),
    );

    for (final label in ['내 정보', '이용약관']) {
      final text = tester.widget<Text>(find.text(label));
      expect(text.style?.color, AppColors.ink, reason: label);
    }
    expect(
      tester.widget<Text>(find.text('로그아웃')).style?.color,
      isNot(Colors.white),
    );
  });

  testWidgets('항목을 누르면 해당 동작을 돌려주며 닫힌다', (tester) async {
    AvatarMenuAction? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                picked = await showModalBottomSheet<AvatarMenuAction>(
                  context: context,
                  builder: (_) => const MyMenuSheet(),
                );
              },
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('이용약관'));
    await tester.pumpAndSettle();

    expect(picked, AvatarMenuAction.terms);
  });
}
