import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:panopticon/data/providers.dart';
import 'package:panopticon/ui/screens/today_screen.dart';

void main() {
  testWidgets('TodayScreen renders empty state when no events captured', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          totalEventCountProvider.overrideWith((ref) => Stream.value(0)),
          recentEventsProvider().overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(home: Scaffold(body: TodayScreen())),
      ),
    );
    await tester.pump();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('No events captured yet.'), findsOneWidget);
  });
}
