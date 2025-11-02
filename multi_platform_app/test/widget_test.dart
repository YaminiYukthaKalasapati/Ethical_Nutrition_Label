import 'package:flutter_test/flutter_test.dart';
import 'package:multi_platform_app/main.dart';

void main() {
  testWidgets('Welcome screen shows Login button', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('Navigates to Login screen on button tap', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MyApp());
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    expect(find.text('Sign In'), findsOneWidget);
  });
}
