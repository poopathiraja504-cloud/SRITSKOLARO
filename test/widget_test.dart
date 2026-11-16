import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skolaro/main.dart';
import 'package:skolaro/providers/auth_provider.dart';
import 'package:skolaro/providers/theme_provider.dart';

void main() {
  testWidgets('app builds successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      SritSkolaroApp(
        authProvider: AuthProvider(),
        themeProvider: ThemeProvider(),
        startupError: null,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
