import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safekids/main.dart';

void main() {
  testWidgets('SafeKids smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SafeKidsApp(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}