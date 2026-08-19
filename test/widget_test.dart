// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ccm_melodies/main.dart';

void main() {
  testWidgets('shows the welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(const CCMMelodiesApp());

    expect(find.text('WELCOME\nTO\nCONNECTING CHRIST MELODIES'), findsOneWidget);
    expect(find.textContaining('CONNECTING CHRIST'), findsOneWidget);
    expect(find.text('CCM Admin'), findsOneWidget);
    expect(find.text('CCM Member'), findsOneWidget);
  });

  testWidgets('member does not see Add Song', (WidgetTester tester) async {
    await tester.pumpWidget(const CCMMelodiesApp());

    await tester.tap(find.text('CCM Member'));
    await tester.pumpAndSettle();
    expect(find.text('Add Song'), findsNothing);
  });

  testWidgets('admin can log in and see Add Song', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SongListScreen(isAdmin: true)),
    );
    expect(find.text('Add Song'), findsOneWidget);
  });
}
