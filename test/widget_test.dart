import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:escon_led_app/main.dart';

void main() {
  testWidgets('App renders correctly and shows search button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: EsconLedApp(),
      ),
    );

    await tester.pump();

    expect(find.text('ESCON LED CONTROLLER'), findsOneWidget);
    expect(find.text('Search for LED'), findsOneWidget);
  });
}
