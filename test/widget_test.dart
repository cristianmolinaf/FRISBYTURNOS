import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frisbyturnos/login_page.dart';

void main() {
  testWidgets('LoginPage smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    // Verify LoginPage builds without throwing exceptions
    expect(find.byType(LoginPage), findsOneWidget);
  });
}
