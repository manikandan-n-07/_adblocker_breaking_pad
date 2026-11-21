import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:browser/features/browser/models/browser_tab.dart';
import 'package:browser/features/browser/widgets/browser_bottom_bar.dart';
import 'package:browser/features/browser/widgets/browser_tab_card.dart';
import 'package:browser/features/browser/widgets/loading_indicator.dart';

void main() {
  testWidgets('BrowserBottomBar renders navigation controls', (WidgetTester tester) async {
    final tab = BrowserTab(id: 'test_tab', url: 'https://www.google.com');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BrowserBottomBar(
            tab: tab,
            tabCount: 3,
            onBack: () {},
            onForward: () {},
            onHome: () {},
            onTabs: () {},
            onMenu: () {},
          ),
        ),
      ),
    );

    // Verify Tab count badge renders '3'
    expect(find.text('3'), findsOneWidget);

    // Verify Home and Menu icons render
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
  });

  testWidgets('BrowserTabCard displays title and close button', (WidgetTester tester) async {
    final tab = BrowserTab(
      id: 'tab_1',
      title: 'Google Search',
      url: 'https://www.google.com',
      blockedCount: 5,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BrowserTabCard(
            tab: tab,
            isSelected: true,
            onTap: () {},
            onClose: () {},
          ),
        ),
      ),
    );

    expect(find.text('Google Search'), findsOneWidget);
    expect(find.text('5 blocked'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('LoadingIndicator renders linear progress when loading', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LoadingIndicator(
            progress: 0.5,
            isLoading: true,
          ),
        ),
      ),
    );

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}
