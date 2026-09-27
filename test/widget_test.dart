import 'package:flutter_test/flutter_test.dart';
import 'package:skinsafe/main.dart';

void main() {
  testWidgets('shows login for preview mode when onboarding is complete', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      SkinSafeApp(
        authController: FrontendAuthController.preview(
          hasCompletedOnboarding: true,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Welcome Back.'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
