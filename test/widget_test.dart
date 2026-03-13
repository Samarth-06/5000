import 'package:flutter_test/flutter_test.dart';
import 'package:smart_farm/main.dart';

void main() {
  testWidgets('SmartFarmApp renders smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SmartFarmApp());

    // Wait for splash screen or assert that something renders
    expect(find.byType(SmartFarmApp), findsOneWidget);
  });
}
