import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Import all providers
import 'package:kasuwa/providers/auth_provider.dart';
import 'package:kasuwa/providers/cart_provider.dart';
import 'package:kasuwa/providers/home_provider.dart';
import 'package:kasuwa/providers/wishlist_provider.dart';
import 'package:kasuwa/providers/category_provider.dart';
import 'package:kasuwa/providers/product_provider.dart';
import 'package:kasuwa/providers/notification_provider.dart';
import 'package:kasuwa/providers/dashboard_provider.dart';
import 'package:kasuwa/providers/order_provider.dart';
import 'package:kasuwa/providers/checkout_provider.dart';
import 'package:kasuwa/providers/add_product_provider.dart';
import 'package:kasuwa/providers/edit_product_provider.dart';
import 'package:kasuwa/providers/password_reset_provider.dart';
// Import the main screens
import 'package:kasuwa/screens/splash_screen.dart';
import 'package:kasuwa/theme/app_theme.dart';
import 'package:kasuwa/screens/shop_profile.dart';
import 'package:kasuwa/screens/product_details.dart';
import 'package:kasuwa/screens/home_screen.dart';

import 'package:kasuwa/services/deep_link_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider(
            create: (_) => DeepLinkService(),
            dispose: (_, service) => service.dispose()),
        // Independent Providers
        ChangeNotifierProvider(create: (context) => AuthProvider()),

        // Other independent providers
        ChangeNotifierProvider(create: (context) => HomeProvider()),
        ChangeNotifierProvider(create: (context) => PasswordResetProvider()),
        ChangeNotifierProvider(create: (context) => CategoryProvider()),
        ChangeNotifierProvider(create: (context) => EditProductProvider()),
        ChangeNotifierProxyProvider2<AuthProvider, CheckoutProvider,
            ProductProvider>(
          create: (context) => ProductProvider(
            Provider.of<AuthProvider>(context, listen: false),
            Provider.of<CheckoutProvider>(context, listen: false),
          ),
          update: (context, auth, checkout, previous) =>
              previous!..update(auth, checkout),
        ),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (context) => NotificationProvider(
              Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, previous) => previous!..update(auth),
        ),

        // Dependent providers that use the AuthProvider's state
        // The 'create' factory is used here, reading the AuthProvider once.
        ChangeNotifierProvider(
          create: (context) => CartProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => WishlistProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
        ),
        ChangeNotifierProxyProvider2<AuthProvider, NotificationProvider,
            DashboardProvider>(
          create: (context) => DashboardProvider(
            Provider.of<AuthProvider>(context, listen: false),
            Provider.of<NotificationProvider>(context, listen: false),
          ),
          update: (context, auth, notifications, previous) =>
              previous!..update(auth, notifications),
        ),
        ChangeNotifierProvider(
          create: (context) => OrderProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
        ),

        // THE FIX: Replaced ChangeNotifierProxyProvider with ChangeNotifierProvider.
        // This creates the CheckoutProvider instance and passes the AuthProvider
        // to its constructor without needing an 'update' method.
        ChangeNotifierProvider(
          create: (context) => CheckoutProvider(
            Provider.of<AuthProvider>(context, listen: false),
          ),
        ),

        // This provider depends on CategoryProvider, not AuthProvider
        ChangeNotifierProxyProvider<CategoryProvider, AddProductProvider>(
          create: (context) => AddProductProvider(
              Provider.of<CategoryProvider>(context, listen: false)),
          update: (context, category, previous) => previous!,
        ),
      ],
      child: const KasuwaApp(),
    ),
  );
}

class KasuwaApp extends StatelessWidget {
  const KasuwaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // It now returns our new Initializer widget.
    return const _KasuwaAppInitializer();
  }
}

// A new StatefulWidget to handle the lifecycle of the DeepLinkService.
class _KasuwaAppInitializer extends StatefulWidget {
  const _KasuwaAppInitializer();

  @override
  __KasuwaAppInitializerState createState() => __KasuwaAppInitializerState();
}

class __KasuwaAppInitializerState extends State<_KasuwaAppInitializer> {
  late final DeepLinkService _deepLinkService;
  StreamSubscription? _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    // Initialize the service.
    _deepLinkService = Provider.of<DeepLinkService>(context, listen: false);
    _deepLinkService.init();

    // Listen to the stream of navigation events for links that come in while the app is running.
    _deepLinkSubscription = _deepLinkService.navigationEvents.listen((event) {
      _handleNavigationEvent(event);
    });

    // Handle the initial link after the first frame is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deepLinkService.getInitialLink().then((event) {
        if (event != null) {
          _handleNavigationEvent(event);
        }
      });
    });
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    super.dispose();
  }

  void _handleNavigationEvent(NavigationEvent event) {
    // We use the context from this widget, which is guaranteed to be valid.
    if (event is ProductNavigationEvent) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ProductDetailsPage(productId: event.productId)));
    } else if (event is ShopNavigationEvent) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ShopProfileScreen(shopSlug: event.shopSlug)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kasuwa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppTheme.primaryColor,
        colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.primaryColor),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        fontFamily: 'Poppins',
        appBarTheme: const AppBarTheme(
          elevation: 1,
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins'),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        // THE FIX: The AuthWrapper no longer decides between Login and Home.
        // It now only shows the splash screen while the app initializes.
        if (auth.isInitializing) {
          return const SplashScreen();
        }

        // After initializing, it ALWAYS shows the main home screen.
        // The home screen itself will decide what to show based on the auth state.
        return const EnhancedHomeScreen();
      },
    );
  }
}
