import 'package:flutter_test/flutter_test.dart';
import 'package:sa_benefits/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App load smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: SABenefitsApp(),
      ),
    );

    // Verify that the title is present
    expect(find.text('SA Benefits'), findsOneWidget);
  });
}
