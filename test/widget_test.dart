import 'package:flutter_test/flutter_test.dart';
import 'package:kasuwa/main.dart';
import 'package:kasuwa/screens/login_screen.dart';
import 'package:kasuwa/screens/home_screen.dart';
import 'package:kasuwa/screens/shop_profile.dart';

void main() {
  testWidgets('Login screen loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const KasuwaApp(initialRoute: AppRoutes.login));

    // Verify the presence of login screen elements
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Login'),
        findsOneWidget); // Replace with actual button or title text
  });

  testWidgets('Home screen loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const KasuwaApp(initialRoute: AppRoutes.home));

    // Verify the presence of home screen elements
    expect(find.byType(EnhancedHomeScreen), findsOneWidget);
    expect(find.text('Welcome to Kasuwa'), findsOneWidget); // Adjust this
  });

  testWidgets('Shop profile loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const KasuwaApp(initialRoute: AppRoutes.shop));

    // Verify the presence of shop profile elements
    expect(find.byType(ShopProfileScreen), findsOneWidget);
    expect(
        find.text('Shop Profile'), findsOneWidget); // Adjust based on your UI
  });
}
