import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:body_tracker/main.dart';
import 'package:body_tracker/providers/app_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: const MyApp(),
      ),
    );

    // Verify that the splash screen title is present.
    expect(find.text('Body Tracker'), findsOneWidget);
    expect(find.byIcon(Icons.straighten), findsOneWidget);
  });
}
